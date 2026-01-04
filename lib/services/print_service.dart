import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/print_history.dart';
import 'print_cache_service.dart';
import 'file_upload_service.dart';
import 'print_notification_service.dart';

/// Service for managing print jobs in Firebase
class PrintService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PrintCacheService _cacheService = PrintCacheService();
  final PrintNotificationService _notificationService = PrintNotificationService();
  bool _isListening = false;
  String? _lastCacheUpdate; // Track last cache update to prevent duplicates

  /// Start listening to print jobs changes in Firebase
  void startListeningToPrintJobs() {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _isListening) return;
    _isListening = true;
    
    _database.child('users').child(userId).child('printJobs').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          print('Print job data changed, processing for status notifications...');
          _processJobChanges(event.snapshot.value as Map<dynamic, dynamic>);
        } catch (e) {
          print('Error processing print jobs update: $e');
        }
      } else {
        // No jobs exist, clear cache
        if (_lastCacheUpdate != 'empty') {
          _lastCacheUpdate = 'empty';
          _cacheService.cachePrintJobs([]);
          print('Print jobs cache cleared - no jobs found');
        }
      }
    });
    
    print('Started listening to print job changes for user: $userId');
  }

  /// Process print job changes and trigger notifications for status updates
  Future<void> _processJobChanges(Map<dynamic, dynamic> jobsMap) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get cached jobs for comparison
      final cachedJobs = await _cacheService.getCachedPrintJobs();
      final cachedJobsMap = <String, PrintJob>{};
      
      if (cachedJobs != null) {
        for (final job in cachedJobs) {
          cachedJobsMap[job.id] = job;
        }
      }

      // Convert Firebase data to PrintJob objects
      final currentJobs = <PrintJob>[];
      jobsMap.forEach((key, value) {
        if (value is Map) {
          try {
            final job = PrintJob.fromMap(value);
            currentJobs.add(job);
            
            // Check for status changes
            final cachedJob = cachedJobsMap[job.id];
            if (cachedJob != null && cachedJob.status != job.status) {
              // Status changed - send immediate notification
              print('Print job status changed: ${job.code} - ${cachedJob.status.displayText} -> ${job.status.displayText}');
              _triggerStatusChangeNotification(job, cachedJob.status);
            } else if (cachedJob == null) {
              // New job - notification already sent in addPrintJob
              print('New print job detected: ${job.code}');
            }
          } catch (e) {
            print('Error parsing print job $key: $e');
          }
        }
      });

      // Sort by date descending
      currentJobs.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      // Update cache with current jobs
      await _cacheService.cachePrintJobs(currentJobs);
      _lastCacheUpdate = currentJobs.map((job) => job.id).join(',');
      print('Print jobs cache updated with status change detection (${currentJobs.length} jobs)');
      
    } catch (e) {
      print('Error in _processJobChanges: $e');
    }
  }

  /// Trigger immediate notification for status change
  Future<void> _triggerStatusChangeNotification(PrintJob job, PrintStatus previousStatus) async {
    try {
      switch (job.status) {
        case PrintStatus.finished:
          await _notificationService.notifyPrintJobCompleted(job);
          break;
        case PrintStatus.cancelled:
          await _notificationService.notifyPrintJobCancelled(job);
          break;
        case PrintStatus.pending:
          // Only notify if it was changed back to pending (rare case)
          if (previousStatus != PrintStatus.pending) {
            await _notificationService.notifyPrintJobStatusChanged(job);
          }
          break;
      }
    } catch (e) {
      print('Error triggering status change notification: $e');
    }
  }

  /// Get current user's print jobs from cache first, then Firebase if needed
  Future<List<PrintJob>> getUserPrintJobs({bool forceRefresh = false}) async {
    try {
      final userId = _auth.currentUser?.uid;
      print('Getting print jobs for user: $userId');
      
      if (userId == null) {
        print('No user logged in');
        return [];
      }

      // Start listening for real-time updates
      startListeningToPrintJobs();

      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedJobs = await _cacheService.getCachedPrintJobs();
        if (cachedJobs != null && cachedJobs.isNotEmpty) {
          print('Returning ${cachedJobs.length} print jobs from cache');
          // Refresh in background if stale
          _refreshPrintDataIfStale();
          return cachedJobs;
        }
      }

      DatabaseEvent event = await _database
          .child('users')
          .child(userId)
          .child('printJobs')
          .once();

      print('Database snapshot exists: ${event.snapshot.exists}');
      
      if (!event.snapshot.exists) {
        print('No print jobs found in database');
        return [];
      }

      final snapshotValue = event.snapshot.value;
      print('Snapshot value type: ${snapshotValue.runtimeType}');
      print('Snapshot value: $snapshotValue');
      
      if (snapshotValue == null) {
        print('Snapshot value is null');
        return [];
      }

      Map<dynamic, dynamic> jobsMap = snapshotValue as Map<dynamic, dynamic>;
      print('Found ${jobsMap.length} print jobs in database');
      
      List<PrintJob> jobs = [];

      jobsMap.forEach((key, value) {
        try {
          print('Processing job $key with value: $value');
          if (value is Map) {
            jobs.add(PrintJob.fromMap(value));
          } else {
            print('Value is not a Map: ${value.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('Error parsing job $key: $e');
          print('Stack trace: $stackTrace');
        }
      });

      // Sort by date descending (newest first)
      jobs.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      print('Returning ${jobs.length} parsed print jobs');
      
      // Cache the fresh data
      await _cacheService.cachePrintJobs(jobs);
      
      return jobs;
    } catch (e) {
      print('Error fetching print jobs: $e');
      // Fallback to cache if Firebase fails
      final cachedJobs = await _cacheService.getCachedPrintJobs();
      return cachedJobs ?? [];
    }
  }

  /// Refresh print data in background if cache is stale
  void _refreshPrintDataIfStale() async {
    try {
      final isStale = await _cacheService.isCacheStale(
        maxAge: const Duration(minutes: 30),
      );
      
      if (isStale) {
        print('Print cache is stale, refreshing in background');
        getUserPrintJobs(forceRefresh: true);
      }
    } catch (e) {
      print('Error checking print cache staleness: $e');
    }
  }

  /// Add a new print job
  Future<bool> addPrintJob(PrintJob job) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Add to Firebase Database - the listener will update the cache
      await _database
          .child('users')
          .child(userId)
          .child('printJobs')
          .child(job.id)
          .set(job.toMap());

      print('Print job added to Firebase: ${job.id}');
      
      // Send notification for new print job
      await _notificationService.notifyPrintJobAdded(job);
      
      return true;
    } catch (e) {
      print('Error adding print job: $e');
      return false;
    }
  }

  /// Update print job status
  Future<bool> updatePrintJobStatus(String jobId, PrintStatus status) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _database
          .child('users')
          .child(userId)
          .child('printJobs')
          .child(jobId)
          .update({'status': status.displayText.toLowerCase()});

      // Get job details for notification
      final cachedJobs = await _cacheService.getCachedPrintJobs();
      PrintJob? updatedJob;
      
      if (cachedJobs != null) {
        final jobIndex = cachedJobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          updatedJob = PrintJob(
            id: cachedJobs[jobIndex].id,
            code: cachedJobs[jobIndex].code,
            fileName: cachedJobs[jobIndex].fileName,
            pageCount: cachedJobs[jobIndex].pageCount,
            dateTime: cachedJobs[jobIndex].dateTime,
            fileUrl: cachedJobs[jobIndex].fileUrl,
            status: status,
          );
          await _cacheService.updateCachedJob(updatedJob);
        }
      }

      // Send notification for status update (especially for 'finished' status)
      if (updatedJob != null && status == PrintStatus.finished) {
        await _notificationService.notifyPrintJobCompleted(updatedJob);
      } else if (updatedJob != null && status == PrintStatus.cancelled) {
        await _notificationService.notifyPrintJobCancelled(updatedJob);
      } else if (updatedJob != null) {
        await _notificationService.notifyPrintJobStatusChanged(updatedJob);
      }

      return true;
    } catch (e) {
      print('Error updating print job: $e');
      return false;
    }
  }

/// Delete a print job and associated file
Future<bool> deletePrintJob(String jobId, {String? fileName}) async {
  try {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    // Delete file from Supabase if fileName provided
    if (fileName != null && fileName.isNotEmpty) {
      final fileUploadService = FileUploadService();
      await fileUploadService.deleteFile(jobId, fileName);
    }

    await _database
        .child('users')
        .child(userId)
        .child('printJobs')
        .child(jobId)
        .remove();

    // Remove from cache
    await _cacheService.removeJobFromCache(jobId);

    return true;
  } catch (e) {
    print('Error deleting print job: $e');
    return false;
  }
}
}

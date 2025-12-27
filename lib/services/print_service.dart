import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/print_history.dart';
import 'print_cache_service.dart';

/// Service for managing print jobs in Firebase
class PrintService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PrintCacheService _cacheService = PrintCacheService();
  bool _isListening = false;

  /// Start listening to print jobs changes in Firebase
  void startListeningToPrintJobs() {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _isListening) return;
    _isListening = true;
    
    _database.child('printJobs').child(userId).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          Map<dynamic, dynamic> jobsMap = event.snapshot.value as Map<dynamic, dynamic>;
          List<PrintJob> jobs = [];
          
          jobsMap.forEach((key, value) {
            if (value is Map) {
              jobs.add(PrintJob.fromMap(value));
            }
          });
          
          // Sort by date descending
          jobs.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          
          // Update cache with fresh data
          _cacheService.cachePrintJobs(jobs);
          print('Print jobs cache updated from Firebase listener (${jobs.length} jobs)');
        } catch (e) {
          print('Error processing print jobs update: $e');
        }
      }
    });
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
          .child('printJobs')
          .child(userId)
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

      await _database
          .child('printJobs')
          .child(userId)
          .child(job.id)
          .set(job.toMap());

      // Add to cache immediately
      await _cacheService.addJobToCache(job);

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
          .child('printJobs')
          .child(userId)
          .child(jobId)
          .update({'status': status.displayText.toLowerCase()});

      // Update in cache
      final cachedJobs = await _cacheService.getCachedPrintJobs();
      if (cachedJobs != null) {
        final jobIndex = cachedJobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          final updatedJob = PrintJob(
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

      return true;
    } catch (e) {
      print('Error updating print job: $e');
      return false;
    }
  }

  /// Delete a print job
  Future<bool> deletePrintJob(String jobId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _database
          .child('printJobs')
          .child(userId)
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

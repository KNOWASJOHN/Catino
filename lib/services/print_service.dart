import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/print_history.dart';

/// Service for managing print jobs in Firebase
class PrintService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's print jobs
  Future<List<PrintJob>> getUserPrintJobs() async {
    try {
      final userId = _auth.currentUser?.uid;
      print('Getting print jobs for user: $userId');
      
      if (userId == null) {
        print('No user logged in');
        return [];
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
      return jobs;
    } catch (e) {
      print('Error fetching print jobs: $e');
      return [];
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

      return true;
    } catch (e) {
      print('Error deleting print job: $e');
      return false;
    }
  }
}

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/print_job.dart';

/// Service for managing print jobs using Supabase
class PrintService {
  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _printJobsSubscription;

  /// Start listening to print jobs for the current user
  void startListeningToPrintJobs() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _printJobsSubscription?.cancel();
    
    // Listen to changes in print_jobs table
    _printJobsSubscription = _supabase
        .from('print_jobs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
      print('Print jobs updated: ${data.length} jobs');
    });
  }

  /// Stop listening to print jobs
  void stopListeningToPrintJobs() {
    _printJobsSubscription?.cancel();
    _printJobsSubscription = null;
  }

  /// Get all print jobs for the current user
  Future<List<PrintJob>> getUserPrintJobs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _supabase
          .from('print_jobs')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => PrintJob.fromSupabaseMap(json))
          .toList();
    } catch (e) {
      print('Error getting user print jobs: $e');
      rethrow;
    }
  }

  /// Add a new print job
  Future<bool> addPrintJob(PrintJob job) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase.from('print_jobs').insert({
        'id': job.id,
        'user_id': userId,
        'code': job.code,
        'file_name': job.fileName,
        'timestamp': job.dateTime.millisecondsSinceEpoch,
        'status': job.status.displayText.toLowerCase(),
        'page_count': job.pageCount,
        'file_url': job.fileUrl,
      });

      return true;
    } catch (e) {
      print('Error adding print job: $e');
      return false;
    }
  }

  /// Update print job status
  Future<void> updatePrintJobStatus(String jobId, PrintStatus status) async {
    try {
      await _supabase
          .from('print_jobs')
          .update({'status': status.displayText.toLowerCase()})
          .eq('id', jobId);
    } catch (e) {
      print('Error updating print job status: $e');
      rethrow;
    }
  }

  /// Delete a print job
  Future<bool> deletePrintJob(String jobId) async {
    try {
      await _supabase.from('print_jobs').delete().eq('id', jobId);
      return true;
    } catch (e) {
      print('Error deleting print job: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopListeningToPrintJobs();
  }
}

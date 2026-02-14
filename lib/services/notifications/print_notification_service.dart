import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantino/services/log.dart';
import '../../models/print_job.dart';
import '../../models/notification_model.dart';

/// Service specifically for handling print-related notifications
/// Integrated with OneSignal via Supabase Edge Function
/// When a notification is inserted into Supabase, the Edge Function automatically sends a push via OneSignal
class PrintNotificationService {
  static final PrintNotificationService _instance =
      PrintNotificationService._internal();
  factory PrintNotificationService() => _instance;
  PrintNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send notification when a new print job is added
  Future<void> notifyPrintJobAdded(PrintJob job) async {
    await _createNotification(
      title: 'Print Job Submitted',
      message:
          '${job.fileName} (${job.pageCount} pages) has been submitted successfully',
      type: 'print',
      data: {
        'printJobId': job.id,
        'printJobCode': job.code,
        'fileName': job.fileName,
        'status': job.status.displayText.toLowerCase(),
        'pageCount': job.pageCount,
        'price': job.price,
      },
    );
  }

  /// Send notification when print job status changes
  Future<void> notifyPrintJobStatusChanged(PrintJob job) async {
    String title = 'Print Job Update';
    String message = '${job.fileName}';

    switch (job.status) {
      case PrintStatus.finished:
        title = 'Print Job Complete!';
        message = '${job.fileName} is ready for pickup';
        break;
      case PrintStatus.cancelled:
        title = 'Print Job Cancelled';
        message = '${job.fileName} has been cancelled';
        break;
      case PrintStatus.pending:
        title = 'Print Job Pending';
        message = '${job.fileName} is being processed';
        break;
    }

    await _createNotification(
      title: title,
      message: message,
      type: 'print',
      data: {
        'printJobId': job.id,
        'printJobCode': job.code,
        'fileName': job.fileName,
        'status': job.status.displayText.toLowerCase(),
        'pageCount': job.pageCount,
        'price': job.price,
      },
    );
  }

  /// Send notification when print job is completed
  Future<void> notifyPrintJobCompleted(PrintJob job) async {
    await _createNotification(
      title: 'Print Job Complete!',
      message: '${job.fileName} (${job.pageCount} pages) is ready for pickup',
      type: 'print',
      data: {
        'printJobId': job.id,
        'printJobCode': job.code,
        'fileName': job.fileName,
        'status': 'finished',
        'pageCount': job.pageCount,
        'price': job.price,
      },
    );
  }

  /// Send notification when print job is cancelled
  Future<void> notifyPrintJobCancelled(PrintJob job) async {
    await _createNotification(
      title: 'Print Job Cancelled',
      message: '${job.fileName} has been cancelled',
      type: 'print',
      data: {
        'printJobId': job.id,
        'printJobCode': job.code,
        'fileName': job.fileName,
        'status': 'cancelled',
        'pageCount': job.pageCount,
        'price': job.price,
      },
    );
  }

  /// Create and store notification in Supabase
  /// The Supabase webhook will trigger the Edge Function, which sends the push via OneSignal
  Future<void> _createNotification({
    required String title,
    required String message,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        logWarning('Cannot create notification: User not logged in');
        return;
      }

      final notification = NotificationModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_print',
        title: title,
        message: message,
        type: type,
        userId: userId,
        createdAt: DateTime.now(),
        data: data,
      );

      // Store in Supabase notifications table
      // This INSERT triggers the webhook → Edge Function → OneSignal API call
      await _supabase.from('notifications').insert({
        'id': notification.id,
        'user_id': notification.userId,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type,
        'created_at_timestamp': notification.createdAt.millisecondsSinceEpoch,
        'is_read': false,
        'data': notification.data,
      });

      logInfo(
        'Print notification created in Supabase (will be sent via OneSignal): $title',
      );
    } catch (e) {
      logError('Error creating print notification: $e', e);
    }
  }

  /// Test method to show sample print notification
  Future<void> testPrintNotification() async {
    await _createNotification(
      title: 'Test Print Complete!',
      message: 'TestDocument.pdf (5 pages) is ready for pickup',
      type: 'print',
      data: {
        'printJobId': 'test_print_123',
        'printJobCode': 'P001',
        'fileName': 'TestDocument.pdf',
        'status': 'finished',
        'pageCount': 5,
        'price': 25.0,
      },
    );
  }
}

// NOTE: FCM Service not migrated to Supabase - This service is temporarily disabled
// import 'fcm_service.dart';
import '../../models/print_job.dart';

/// Service specifically for handling print-related notifications
/// This provides a clean interface for print notification operations
class PrintNotificationService {
  static final PrintNotificationService _instance = PrintNotificationService._internal();
  factory PrintNotificationService() => _instance;
  PrintNotificationService._internal();

  // final FCMService _fcmService = FCMService();

  /// Initialize the notification service
  /// Should be called when the app starts
  Future<void> initialize() async {
    // FCM notifications disabled
  }

  /// Send notification when a new print job is added
  Future<void> notifyPrintJobAdded(PrintJob job) async {
    // FCM notifications disabled
  }

  /// Send notification when print job status changes
  Future<void> notifyPrintJobStatusChanged(PrintJob job) async {
    // FCM notifications disabled
  }

  /// Send notification when print job is completed
  Future<void> notifyPrintJobCompleted(PrintJob job) async {
    // FCM notifications disabled
  }

  /// Send notification when print job is cancelled
  Future<void> notifyPrintJobCancelled(PrintJob job) async {
    // FCM notifications disabled
  }

  /// Show immediate local notification only (no Firebase record)
  Future<void> showLocalPrintNotification({
    required String printJobId,
    required String fileName,
    required String status,
    required String message,
  }) async {
    // FCM notifications disabled
  }

  /// Test method to show sample print notification
  Future<void> testPrintNotification() async {
    // FCM notifications disabled
  }
}
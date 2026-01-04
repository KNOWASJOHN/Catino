import 'fcm_service.dart';
import '../components/print_history.dart';

/// Service specifically for handling print-related notifications
/// This provides a clean interface for print notification operations
class PrintNotificationService {
  static final PrintNotificationService _instance = PrintNotificationService._internal();
  factory PrintNotificationService() => _instance;
  PrintNotificationService._internal();

  final FCMService _fcmService = FCMService();

  /// Initialize the notification service
  /// Should be called when the app starts
  Future<void> initialize() async {
    try {
      await _fcmService.initialize();
      print('Print notification service initialized');
    } catch (e) {
      print('Error initializing print notification service: $e');
    }
  }

  /// Send notification when a new print job is added
  Future<void> notifyPrintJobAdded(PrintJob job) async {
    await _fcmService.createPrintJobNotification(
      printJobId: job.id,
      fileName: job.fileName,
      status: job.status.displayText,
      code: job.code,
    );
  }

  /// Send notification when print job status changes
  Future<void> notifyPrintJobStatusChanged(PrintJob job) async {
    await _fcmService.createPrintJobNotification(
      printJobId: job.id,
      fileName: job.fileName,
      status: job.status.displayText,
      code: job.code,
    );
  }

  /// Send notification when print job is completed
  Future<void> notifyPrintJobCompleted(PrintJob job) async {
    await _fcmService.createPrintJobNotification(
      printJobId: job.id,
      fileName: job.fileName,
      status: 'finished',
      code: job.code,
    );
  }

  /// Send notification when print job is cancelled
  Future<void> notifyPrintJobCancelled(PrintJob job) async {
    await _fcmService.createPrintJobNotification(
      printJobId: job.id,
      fileName: job.fileName,
      status: 'cancelled',
      code: job.code,
    );
  }

  /// Show immediate local notification only (no Firebase record)
  Future<void> showLocalPrintNotification({
    required String printJobId,
    required String fileName,
    required String status,
    required String message,
  }) async {
    await _fcmService.showPrintNotification(
      printJobId: printJobId,
      fileName: fileName,
      status: status,
      message: message,
    );
  }

  /// Test method to show sample print notification
  Future<void> testPrintNotification() async {
    await showLocalPrintNotification(
      printJobId: 'test_123',
      fileName: 'sample_document.pdf',
      status: 'finished',
      message: 'Your test print job is complete!',
    );
  }
}
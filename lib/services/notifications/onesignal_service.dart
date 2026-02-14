import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cantino/services/log.dart';

/// Service for managing OneSignal push notifications
/// Handles initialization, user linking, and notification event handling
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _initialized = false;

  /// Initialize OneSignal SDK with the given App ID
  /// Should be called once during app startup in main.dart
  Future<void> initialize(String appId) async {
    if (_initialized || appId.isEmpty) return;

    try {
      // Enable verbose logging for debugging (remove in production)
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize with App ID
      OneSignal.initialize(appId);

      // Set up notification event listeners
      _setupNotificationListeners();

      _initialized = true;
      logInfo('OneSignal initialized successfully');
    } catch (e) {
      logError('Error initializing OneSignal: $e', e);
    }
  }

  /// Request push notification permission from the user
  /// [fallbackToSettings] - If true, opens app settings when permission was previously denied
  Future<void> requestPermission({bool fallbackToSettings = false}) async {
    try {
      final accepted = await OneSignal.Notifications.requestPermission(
        fallbackToSettings,
      );
      logInfo(
        'Push notification permission ${accepted ? 'granted' : 'denied'}',
      );
    } catch (e) {
      logError('Error requesting notification permission: $e', e);
    }
  }

  /// Link a Supabase user to OneSignal using External ID
  /// Call this after successful login
  void loginUser(String userId) {
    try {
      logInfo('🔗 Attempting to link OneSignal device to user: $userId');
      OneSignal.login(userId);
      logInfo('✅ OneSignal.login() called successfully for userId: $userId');
      logInfo('📱 Device should now be linked to External ID: $userId');
    } catch (e) {
      logError('❌ Error linking OneSignal user: $e', e);
    }
  }

  /// Unlink the current user from OneSignal
  /// Call this on logout
  void logoutUser() {
    try {
      OneSignal.logout();
      logInfo('OneSignal user unlinked');
    } catch (e) {
      logError('Error unlinking OneSignal user: $e', e);
    }
  }

  /// Add data tags for user segmentation
  void addTags(Map<String, String> tags) {
    try {
      OneSignal.User.addTags(tags);
      logInfo('OneSignal tags added: $tags');
    } catch (e) {
      logError('Error adding OneSignal tags: $e', e);
    }
  }

  /// Set up notification click and foreground display listeners
  void _setupNotificationListeners() {
    // Handle notification tap (when user opens app from notification)
    OneSignal.Notifications.addClickListener((event) {
      logInfo('Notification clicked: ${event.notification.title}');
      final data = event.notification.additionalData;
      if (data != null) {
        _handleNotificationTap(data);
      }
    });

    // Control foreground notification display
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      logInfo('Foreground notification: ${event.notification.title}');
      // Display the notification even when app is in foreground
      event.notification.display();
    });

    logInfo('OneSignal notification listeners set up');
  }

  /// Handle notification tap data — route to appropriate screen
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'order':
        logInfo('Order notification tapped - orderId: ${data['orderId']}');
        // TODO: Navigate to order details screen
        break;
      case 'print':
        logInfo(
          'Print notification tapped - printJobId: ${data['printJobId']}',
        );
        // TODO: Navigate to print job details screen
        break;
      default:
        logInfo('Unknown notification type tapped: $type');
    }
  }
}

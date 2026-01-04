import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'notification_cache_service.dart';

/// Firebase Cloud Messaging Service for Spark Plan (No Cloud Functions)
/// Handles client-side notifications and FCM topic subscriptions
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationCacheService _cacheService = NotificationCacheService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM Service for Spark Plan
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _getAndStoreFCMToken();
    await _subscribeToAnnouncementTopic();
    _setupMessageHandlers();
  }

  /// Initialize local notifications for order confirmations
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'catino_notifications',
      'Catino Notifications',
      description: 'Local notifications for orders and FCM for announcements',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('FCM Permission granted: ${settings.authorizationStatus}');
  }

  /// Get FCM token and store in Firestore for manual messaging
  Future<void> _getAndStoreFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      if (_fcmToken != null && _auth.currentUser != null) {
        await _storeFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (_auth.currentUser != null) {
          _storeFCMToken(newToken);
        }
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Store FCM token in Realtime Database user document
  Future<void> _storeFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _database.ref('users/${user.uid}').update({
        'fcmToken': token,
        'tokenUpdatedAt': ServerValue.timestamp,
      });

      print('FCM Token stored successfully for manual messaging');
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  /// Subscribe to announcement topic for manual broadcasts from Firebase Console
  Future<void> _subscribeToAnnouncementTopic() async {
    try {
      await _messaging.subscribeToTopic('all_users');
      print('Subscribed to all_users topic for announcements');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Setup message handlers for FCM announcements
  void _setupMessageHandlers() {
    // Handle foreground FCM messages (announcements)
    FirebaseMessaging.onMessage.listen(_handleAnnouncementMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle terminated app message taps
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessageTap(message);
      }
    });
  }

  /// Handle FCM announcement messages when app is in foreground
  Future<void> _handleAnnouncementMessage(RemoteMessage message) async {
    print('Announcement message received: ${message.messageId}');
    
    // Store announcement notification in Realtime Database for history
    await _storeAnnouncementNotification(message);
    
    // Show local notification for the announcement
    await _showLocalNotification(
      message.notification?.title ?? 'Announcement',
      message.notification?.body ?? '',
      'announcement',
    );
  }

  /// Handle notification taps when app is in background
  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('Background message tapped: ${message.messageId}');
    // Handle navigation if needed
  }

  /// Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.id}');
    // Handle navigation based on payload
  }

  /// Show local notification (used for both orders and announcements)
  Future<void> _showLocalNotification(
    String title,
    String body,
    String type,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'catino_notifications',
      'Catino Notifications',
      channelDescription: 'Local notifications for orders and announcements',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: type,
    );
  }

  /// Client-side order notification (no server trigger needed)
  Future<void> showOrderConfirmationNotification(String orderCode) async {
    try {
      final title = '🍽️ Order Confirmed!';
      final message = 'Your order #${orderCode} has been placed successfully. We\'ll prepare it shortly!';
      
      // Show local notification immediately
      await _showLocalNotification(title, message, 'order');
      
      // Store in Realtime Database for notification history
      await _storeOrderNotification(orderCode);
      
      print('Order confirmation notification shown for: $orderCode');
    } catch (e) {
      print('Error showing order notification: $e');
    }
  }

  /// Store order notification in Realtime Database for history
  Future<void> _storeOrderNotification(String orderCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final notificationRef = _database.ref('users/${user.uid}/notifications').push();
      
      final notification = NotificationModel(
        id: notificationRef.key ?? '',
        title: '🍽️ Order Confirmed!',
        message: 'Your order #$orderCode has been placed successfully. We\'ll prepare it shortly!',
        type: 'order',
        userId: user.uid,
        createdAt: DateTime.now(),
        data: {'orderCode': orderCode},
      );

      await notificationRef.set(notification.toMap());
      
      // Add to cache and increment unread count
      final cachedNotifications = await _cacheService.getCachedNotifications() ?? [];
      cachedNotifications.add(notification);
      await _cacheService.cacheNotifications(cachedNotifications);
      await _cacheService.incrementUnreadCount();
    } catch (e) {
      print('Error storing order notification: $e');
    }
  }

  /// Store announcement notification in Realtime Database for history
  Future<void> _storeAnnouncementNotification(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final notificationRef = _database.ref('users/${user.uid}/notifications').push();
      
      final notification = NotificationModel(
        id: notificationRef.key ?? '',
        title: message.notification?.title ?? 'Announcement',
        message: message.notification?.body ?? '',
        type: 'announcement',
        userId: user.uid,
        createdAt: DateTime.now(),
        data: message.data,
      );

      await notificationRef.set(notification.toMap());
      
      // Add to cache and increment unread count
      final cachedNotifications = await _cacheService.getCachedNotifications() ?? [];
      cachedNotifications.add(notification);
      await _cacheService.cacheNotifications(cachedNotifications);
      await _cacheService.incrementUnreadCount();
    } catch (e) {
      print('Error storing announcement notification: $e');
    }
  }

  /// Get notifications for current user with cache-first strategy
  Stream<List<NotificationModel>> getUserNotifications() async* {
    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in for notifications');
      yield [];
      return;
    }

    print('Fetching notifications for user: ${user.uid}');

    // Step 1: Check cache first and yield immediately if available
    final cachedNotifications = await _cacheService.getCachedNotifications();
    if (cachedNotifications != null) {
      print('Yielding cached notifications: ${cachedNotifications.length}');
      yield cachedNotifications;
      
      // If cache is fresh, we can skip Firebase for now
      final isCacheStale = await _cacheService.isCacheStale();
      if (!isCacheStale) {
        print('Cache is fresh, continuing with Firebase stream for updates');
      }
    }

    // Step 2: Stream from Firebase and update cache on changes
    await for (final event in _database.ref('users/${user.uid}/notifications').onValue) {
      try {
        if (event.snapshot.value == null) {
          print('No notifications found in database for user: ${user.uid}');
          await _cacheService.cacheNotifications([]);
          yield [];
          continue;
        }
        
        print('Notifications snapshot received: ${event.snapshot.value}');
        
        final notificationsData = event.snapshot.value;
        final notificationsMap = Map<String, dynamic>.from(notificationsData as Map);
        
        final notifications = <NotificationModel>[];
        for (var entry in notificationsMap.entries) {
          try {
            final notificationData = Map<String, dynamic>.from(entry.value as Map);
            notificationData['id'] = entry.key;
            
            // Convert nested data map if it exists
            if (notificationData['data'] != null) {
              notificationData['data'] = Map<String, dynamic>.from(notificationData['data'] as Map);
            }
            
            final notification = NotificationModel.fromMap(notificationData);
            notifications.add(notification);
          } catch (e) {
            print('Error parsing notification ${entry.key}: $e');
          }
        }
        
        // Sort by createdAt descending (newest first)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('Loaded ${notifications.length} notifications from Firebase');
        
        // Update cache with fresh data
        await _cacheService.cacheNotifications(notifications);
        
        yield notifications;
      } catch (e) {
        print('Error loading notifications: $e');
        // Fallback to cache on error
        final fallbackCache = await _cacheService.getCachedNotifications();
        if (fallbackCache != null) {
          print('Using cached notifications as fallback');
          yield fallbackCache;
        } else {
          yield [];
        }
      }
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Update Firebase
      await _database
          .ref('users/${user.uid}/notifications/$notificationId')
          .update({'isRead': true});
      
      // Update cache: find notification and update it
      final cachedNotifications = await _cacheService.getCachedNotifications();
      if (cachedNotifications != null) {
        final notificationIndex = cachedNotifications.indexWhere((n) => n.id == notificationId);
        if (notificationIndex != -1) {
          final notification = cachedNotifications[notificationIndex];
          if (!notification.isRead) {
            // Only decrement if it was unread
            final updatedNotification = notification.copyWith(isRead: true);
            cachedNotifications[notificationIndex] = updatedNotification;
            await _cacheService.cacheNotifications(cachedNotifications);
            await _cacheService.decrementUnreadCount();
          }
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Clear all notifications for user
  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _database.ref('users/${user.uid}/notifications').remove();
      await _cacheService.clearCache();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Unsubscribe from topic and cleanup
  Future<void> dispose() async {
    try {
      await _messaging.unsubscribeFromTopic('all_users');
      print('Unsubscribed from all_users topic');
    } catch (e) {
      print('Error during FCM cleanup: $e');
    }
  }
}

/// Handle background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background announcement message: ${message.messageId}');
  // Handle background message processing here if needed
}
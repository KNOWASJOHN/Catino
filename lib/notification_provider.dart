import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/fcm_service.dart';
import 'services/notification_cache_service.dart';
import 'models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  final FCMService _fcmService = FCMService();
  final NotificationCacheService _cacheService = NotificationCacheService();
  String? _currentUserId;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _listenToAuthChanges();
  }

  /// Listen to authentication state changes and manage notification count accordingly
  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.uid != _currentUserId) {
        // User logged in or switched - load their notification count
        _currentUserId = user.uid;
        _loadUnreadCount();
        _listenToNotifications();
      } else if (user == null) {
        // User logged out - clear everything
        _currentUserId = null;
        _unreadCount = 0;
        _cancelNotificationSubscription();
        notifyListeners();
      }
    });
  }

  /// Load unread count from cache (fast) with Firebase stream for updates
  Future<void> _loadUnreadCount() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load cached count immediately for fast UI response
      final cachedCount = await _cacheService.getUnreadCount();
      if (_unreadCount != cachedCount) {
        _unreadCount = cachedCount;
        notifyListeners();
      }

      print('Loaded unread count from cache: $_unreadCount');
    } catch (e) {
      print('Error loading unread count: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to notification changes and update unread count
  void _listenToNotifications() {
    _cancelNotificationSubscription();
    
    _notificationSubscription = _fcmService.getUserNotifications().listen(
      (notifications) {
        // Calculate unread count from notifications
        final newUnreadCount = notifications.where((n) => !n.isRead).length;
        if (_unreadCount != newUnreadCount) {
          _unreadCount = newUnreadCount;
          notifyListeners();
        }
      },
      onError: (error) {
        print('Error listening to notifications: $error');
      },
    );
  }

  /// Cancel notification subscription
  void _cancelNotificationSubscription() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  /// Refresh unread count (can be called manually if needed)
  Future<void> refreshUnreadCount() async {
    await _loadUnreadCount();
  }

  /// Called when notification panel is opened to mark notifications as read
  void onNotificationPanelOpened() {
    // The notification panel handles marking notifications as read
    // This method can be used for any additional logic when panel opens
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelNotificationSubscription();
    super.dispose();
  }
}

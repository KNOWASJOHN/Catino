import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache/notification_cache_service.dart';
import '../models/notification_model.dart';
import '../utils/logger_config.dart';
import '../services/notifications/onesignal_service.dart';

final _logger = AppLogger.getLogger('NotificationProvider');

class NotificationProvider with ChangeNotifier {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  final _supabase = Supabase.instance.client;
  final NotificationCacheService _cacheService = NotificationCacheService();
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _listenToAuthChanges();
  }

  /// Listen to authentication state changes and manage notification count accordingly
  void _listenToAuthChanges() {
    _logger.info('Setting up auth state listener');

    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      _logger.info('Auth state changed - User: ${user?.id}');

      if (user != null && user.id != _currentUserId) {
        _logger.info('New user logged in: ${user.id}');
        _currentUserId = user.id;

        // Link OneSignal device to this Supabase user
        OneSignalService().loginUser(user.id);

        _loadUnreadCount();
        _listenToNotifications();
      } else if (user == null) {
        _logger.info('User logged out');
        _currentUserId = null;
        _unreadCount = 0;

        // Unlink OneSignal on logout
        OneSignalService().logoutUser();

        _cancelNotificationSubscription();
        notifyListeners();
      } else {
        _logger.fine('Same user, no action needed');
      }
    });

    // Check if user is already logged in on initialization
    final currentUser = _supabase.auth.currentUser;
    _logger.info('Initial user check: ${currentUser?.id}');
    if (currentUser != null) {
      _logger.info('User already logged in on init: ${currentUser.id}');
      _currentUserId = currentUser.id;

      // CRITICAL FIX: Link OneSignal device to this user's External ID
      _logger.info('🔗 Linking OneSignal to existing user on app start');
      OneSignalService().loginUser(currentUser.id);

      _loadUnreadCount();
      _listenToNotifications();
    } else {
      _logger.info('No user logged in on init');
    }
  }

  /// Load unread count from cache (fast) with database fallback and Supabase stream for updates
  Future<void> _loadUnreadCount() async {
    try {
      _logger.fine('_loadUnreadCount called - currentUserId: $_currentUserId');
      _isLoading = true;
      notifyListeners();

      // Check if cache exists and is fresh
      final hasCachedData = await _cacheService.hasCachedData();
      final isCacheStale = await _cacheService.isCacheStale();

      _logger.fine(
        'hasCachedData: $hasCachedData, isCacheStale: $isCacheStale',
      );

      if (hasCachedData && !isCacheStale) {
        // Load cached count immediately for fast UI response
        final cachedCount = await _cacheService.getUnreadCount();
        if (_unreadCount != cachedCount) {
          _unreadCount = cachedCount;
          notifyListeners();
        }
        _logger.info('Loaded unread count from fresh cache: $_unreadCount');
      } else {
        // Cache is empty or stale - fetch from database
        _logger.fine('Cache empty or stale - checking userId');
        if (_currentUserId != null) {
          _logger.info(
            'UserId exists: $_currentUserId - fetching from database',
          );
          final dbCount = await _cacheService.syncUnreadCountFromDatabase(
            _currentUserId!,
          );
          if (_unreadCount != dbCount) {
            _unreadCount = dbCount;
            notifyListeners();
          }
          _logger.info('Loaded unread count from database: $_unreadCount');
        } else {
          _logger.warning('UserId is NULL - cannot fetch from database');
        }
      }
    } catch (e) {
      _logger.severe('Error loading unread count', e, StackTrace.current);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to notification changes and update unread count (stream always takes precedence)
  void _listenToNotifications() {
    _cancelNotificationSubscription();

    if (_currentUserId == null) return;

    _logger.info('Starting notification stream for user: $_currentUserId');

    _notificationSubscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId!)
        .listen(
          (data) {
            _logger.fine('Stream received ${data.length} notifications');
            _logger.finest('Stream data: $data');

            // Convert stream data to NotificationModel objects
            final notificationModels = data
                .map(
                  (item) => NotificationModel.fromSupabaseMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList();

            // Sort by createdAt descending (newest first)
            notificationModels.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            );

            // Cache the full notification list from stream
            _cacheService.cacheNotifications(notificationModels);
            _logger.fine(
              'Cached ${notificationModels.length} notification objects from stream',
            );

            // Calculate unread count from notifications (stream takes precedence)
            final unreadNotifications = data
                .where((n) => n['is_read'] == false)
                .toList();
            final newUnreadCount = unreadNotifications.length;

            _logger.info('Unread notifications from stream: $newUnreadCount');
            _logger.finest('Unread items: $unreadNotifications');

            if (_unreadCount != newUnreadCount) {
              _unreadCount = newUnreadCount;
              _logger.info(
                'Stream updated unread count: $_unreadCount (stream takes precedence)',
              );
              notifyListeners();

              // Update cache with the stream data
              _cacheService.getUnreadCountKey().then((key) async {
                if (key != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt(key, newUnreadCount);
                  _logger.fine('Cache count updated from stream');
                }
              });
            } else {
              _logger.fine('Unread count unchanged: $_unreadCount');
            }
          },
          onError: (error) {
            _logger.severe('Error listening to notifications', error);
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

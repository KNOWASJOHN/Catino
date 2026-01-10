import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cache/notification_cache_service.dart';
import '../models/notification_model.dart';

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
    print('═══════════════════════════════════════════════════');
    print('🎧 Setting up auth state listener');
    
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      print('👤 Auth state changed - User: ${user?.id}');
      
      if (user != null && user.id != _currentUserId) {
        print('✅ New user logged in: ${user.id}');
        _currentUserId = user.id;
        _loadUnreadCount();
        _listenToNotifications();
      } else if (user == null) {
        print('❌ User logged out');
        _currentUserId = null;
        _unreadCount = 0;
        _cancelNotificationSubscription();
        notifyListeners();
      } else {
        print('ℹ️ Same user, no action needed');
      }
    });
    
    // Check if user is already logged in on initialization
    final currentUser = _supabase.auth.currentUser;
    print('🔍 Initial user check: ${currentUser?.id}');
    if (currentUser != null) {
      print('✅ User already logged in on init: ${currentUser.id}');
      _currentUserId = currentUser.id;
      _loadUnreadCount();
      _listenToNotifications();
    } else {
      print('❌ No user logged in on init');
    }
    print('═══════════════════════════════════════════════════');
  }

  /// Load unread count from cache (fast) with database fallback and Supabase stream for updates
  Future<void> _loadUnreadCount() async {
    try {
      print('═══════════════════════════════════════════════════');
      print('🔍 _loadUnreadCount called - currentUserId: $_currentUserId');
      _isLoading = true;
      notifyListeners();

      // Check if cache exists and is fresh
      final hasCachedData = await _cacheService.hasCachedData();
      final isCacheStale = await _cacheService.isCacheStale();
      
      print('📦 hasCachedData: $hasCachedData, isCacheStale: $isCacheStale');
      
      if (hasCachedData && !isCacheStale) {
        // Load cached count immediately for fast UI response
        final cachedCount = await _cacheService.getUnreadCount();
        if (_unreadCount != cachedCount) {
          _unreadCount = cachedCount;
          notifyListeners();
        }
        print('✅ Loaded unread count from fresh cache: $_unreadCount');
      } else {
        // Cache is empty or stale - fetch from database
        print('⚠️ Cache empty or stale - checking userId');
        if (_currentUserId != null) {
          print('✅ UserId exists: $_currentUserId - fetching from database');
          final dbCount = await _cacheService.syncUnreadCountFromDatabase(_currentUserId!);
          if (_unreadCount != dbCount) {
            _unreadCount = dbCount;
            notifyListeners();
          }
          print('✅ Loaded unread count from database: $_unreadCount');
        } else {
          print('❌ UserId is NULL - cannot fetch from database');
        }
      }
      print('═══════════════════════════════════════════════════');
    } catch (e) {
      print('❌ Error loading unread count: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to notification changes and update unread count (stream always takes precedence)
  void _listenToNotifications() {
    _cancelNotificationSubscription();
    
    if (_currentUserId == null) return;
    
    print('🎧 Starting notification stream for user: $_currentUserId');
    
    _notificationSubscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId!)
        .listen((data) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('📡 Stream received ${data.length} notifications');
          print('📝 Stream data: $data');
          
          // Convert stream data to NotificationModel objects
          final notificationModels = data
              .map((item) => NotificationModel.fromSupabaseMap(Map<String, dynamic>.from(item)))
              .toList();
          
          // Sort by createdAt descending (newest first)
          notificationModels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Cache the full notification list from stream
          _cacheService.cacheNotifications(notificationModels);
          print('💾 Cached ${notificationModels.length} notification objects from stream');
          
          // Calculate unread count from notifications (stream takes precedence)
          final unreadNotifications = data.where((n) => n['is_read'] == false).toList();
          final newUnreadCount = unreadNotifications.length;
          
          print('🔔 Unread notifications from stream: $newUnreadCount');
          print('📋 Unread items: $unreadNotifications');
          
          if (_unreadCount != newUnreadCount) {
            _unreadCount = newUnreadCount;
            print('✅ Stream updated unread count: $_unreadCount (stream takes precedence)');
            notifyListeners();
            
            // Update cache with the stream data
            _cacheService.getUnreadCountKey().then((key) async {
              if (key != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(key, newUnreadCount);
                print('💾 Cache count updated from stream');
              }
            });
          } else {
            print('ℹ️ Unread count unchanged: $_unreadCount');
          }
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }, onError: (error) {
          print('❌ Error listening to notifications: $error');
        });
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

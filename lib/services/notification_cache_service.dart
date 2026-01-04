import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import 'user_session_cache.dart';

/// Cache service for notifications to reduce Firebase reads and enable offline access (user-specific)
/// Follows the established caching pattern from FoodCacheService and PrintCacheService
class NotificationCacheService {
  // Base cache keys
  static const String _baseCacheKey = 'cached_notifications';
  static const String _baseLastUpdateKey = 'notifications_last_update';
  static const String _baseUnreadCountKey = 'notifications_unread_count';
  static const String _userIdKey = 'notification_cache_user_id';
  
  final UserSessionCache _userSession = UserSessionCache();
  
  // Cache configuration
  static const int _maxCachedNotifications = 50; // Prune to last 50 notifications
  static const Duration _defaultMaxAge = Duration(minutes: 10); // 10-min staleness

  /// Get user-specific cache key
  Future<String?> _getCacheKey() async {
    final userId = await _userSession.getCurrentUserId();
    return userId != null ? '${_baseCacheKey}_$userId' : null;
  }

  /// Get user-specific last update key
  Future<String?> _getLastUpdateKey() async {
    final userId = await _userSession.getCurrentUserId();
    return userId != null ? '${_baseLastUpdateKey}_$userId' : null;
  }

  /// Get user-specific unread count key
  Future<String?> _getUnreadCountKey() async {
    final userId = await _userSession.getCurrentUserId();
    return userId != null ? '${_baseUnreadCountKey}_$userId' : null;
  }

  /// Remove individual notification from cache
  Future<void> removeNotificationFromCache(String notificationId) async {
    try {
      await _validateUserCache();
      
      final cachedNotifications = await getCachedNotifications();
      if (cachedNotifications != null) {
        final notificationIndex = cachedNotifications.indexWhere((n) => n.id == notificationId);
        if (notificationIndex != -1) {
          final notification = cachedNotifications[notificationIndex];
          // If removing an unread notification, decrement unread count
          if (!notification.isRead) {
            await decrementUnreadCount();
          }
          cachedNotifications.removeAt(notificationIndex);
          await cacheNotifications(cachedNotifications);
        }
      }
    } catch (e) {
      print('Error removing notification from cache: $e');
    }
  }

  /// Validate and clear cache if user has changed
  Future<void> _validateUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = await _userSession.getCurrentUserId();
      final cachedUserId = prefs.getString(_userIdKey);
      
      if (currentUserId != cachedUserId) {
        // User changed - clear old cache
        await _clearAllUserCaches();
        if (currentUserId != null) {
          await prefs.setString(_userIdKey, currentUserId);
        }
      }
    } catch (e) {
      print('Error validating user cache: $e');
    }
  }

  /// Clear all user-specific cache data
  Future<void> _clearAllUserCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (String key in keys) {
        if (key.startsWith(_baseCacheKey) || 
            key.startsWith(_baseLastUpdateKey) ||
            key.startsWith(_baseUnreadCountKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing user caches: $e');
    }
  }

  /// Cache a list of notifications (overwrites existing cache)
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    try {
      await _validateUserCache();
      
      final cacheKey = await _getCacheKey();
      final lastUpdateKey = await _getLastUpdateKey();
      final unreadCountKey = await _getUnreadCountKey();
      
      if (cacheKey == null || lastUpdateKey == null || unreadCountKey == null) {
        print('User not authenticated - cannot cache notifications');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // Prune to last 50 notifications to keep cache size manageable
      final notificationsToCache = notifications.length > _maxCachedNotifications
          ? notifications.take(_maxCachedNotifications).toList()
          : notifications;
      
      // Convert to JSON array
      final jsonList = notificationsToCache.map((notification) {
        final map = notification.toMap();
        map['id'] = notification.id; // Include ID in the map
        return map;
      }).toList();
      
      final jsonString = jsonEncode(jsonList);
      
      // Store in SharedPreferences
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      // Update unread count
      final unreadCount = notificationsToCache.where((n) => !n.isRead).length;
      await prefs.setInt(unreadCountKey, unreadCount);
      
      print('Cached ${notificationsToCache.length} notifications (unread: $unreadCount)');
    } catch (e) {
      print('Error caching notifications: $e');
    }
  }

  /// Get cached notifications, returns null if no cache exists
  Future<List<NotificationModel>?> getCachedNotifications() async {
    try {
      await _validateUserCache();
      
      final cacheKey = await _getCacheKey();
      if (cacheKey == null) {
        print('User not authenticated - cannot retrieve cached notifications');
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      
      if (jsonString == null) {
        print('No cached notifications found');
        return null;
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final notifications = jsonList
          .map((json) => NotificationModel.fromMap(Map<String, dynamic>.from(json)))
          .toList();
      
      print('Retrieved ${notifications.length} notifications from cache');
      return notifications;
    } catch (e) {
      print('Error retrieving cached notifications: $e');
      return null;
    }
  }

  /// Check if cache is stale based on maxAge
  Future<bool> isCacheStale({Duration maxAge = _defaultMaxAge}) async {
    try {
      final lastUpdateKey = await _getLastUpdateKey();
      if (lastUpdateKey == null) return true;
      
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(lastUpdateKey);
      
      if (lastUpdate == null) {
        print('No cache timestamp found - cache is stale');
        return true;
      }
      
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();
      final age = now.difference(lastUpdateTime);
      final isStale = age > maxAge;
      
      print('Cache age: ${age.inMinutes} minutes, stale: $isStale');
      return isStale;
    } catch (e) {
      print('Error checking cache staleness: $e');
      return true; // Assume stale on error
    }
  }

  /// Check if cache has data for current user
  Future<bool> hasCachedData() async {
    try {
      final cacheKey = await _getCacheKey();
      if (cacheKey == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(cacheKey);
    } catch (e) {
      return false;
    }
  }

  /// Get cached unread count (fast badge display without Firebase query)
  Future<int> getUnreadCount() async {
    try {
      final unreadCountKey = await _getUnreadCountKey();
      if (unreadCountKey == null) return 0;
      
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(unreadCountKey) ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Increment unread count (called when new notification arrives)
  Future<void> incrementUnreadCount() async {
    try {
      final unreadCountKey = await _getUnreadCountKey();
      if (unreadCountKey == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(unreadCountKey) ?? 0;
      await prefs.setInt(unreadCountKey, currentCount + 1);
      print('Incremented unread count to ${currentCount + 1}');
    } catch (e) {
      print('Error incrementing unread count: $e');
    }
  }

  /// Decrement unread count (called when marking notification as read)
  Future<void> decrementUnreadCount() async {
    try {
      final unreadCountKey = await _getUnreadCountKey();
      if (unreadCountKey == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(unreadCountKey) ?? 0;
      if (currentCount > 0) {
        await prefs.setInt(unreadCountKey, currentCount - 1);
        print('Decremented unread count to ${currentCount - 1}');
      }
    } catch (e) {
      print('Error decrementing unread count: $e');
    }
  }

  /// Clear cached notifications for current user
  Future<void> clearCache() async {
    try {
      final cacheKey = await _getCacheKey();
      final lastUpdateKey = await _getLastUpdateKey();
      final unreadCountKey = await _getUnreadCountKey();
      
      if (cacheKey == null || lastUpdateKey == null || unreadCountKey == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(lastUpdateKey);
      await prefs.remove(unreadCountKey);
      print('Cleared notification cache');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear notification cache for all users (called on logout/app reset)
  Future<void> clearAllUsersCache() async {
    try {
      await _clearAllUserCaches();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      print('Cleared all users notification cache');
    } catch (e) {
      print('Error clearing all users notification cache: $e');
    }
  }

  /// Invalidate cache (forces refresh on next read)
  Future<void> invalidateCache() async {
    try {
      final lastUpdateKey = await _getLastUpdateKey();
      if (lastUpdateKey == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(lastUpdateKey);
      print('Invalidated notification cache');
    } catch (e) {
      print('Error invalidating cache: $e');
    }
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

/// Cache service for notifications to reduce Firebase reads and enable offline access
/// Follows the established caching pattern from FoodCacheService and PrintCacheService
class NotificationCacheService {
  // Cache keys
  static const String _cacheKey = 'cached_notifications';
  static const String _lastUpdateKey = 'notifications_last_update';
  static const String _unreadCountKey = 'notifications_unread_count';
  
  // Cache configuration
  static const int _maxCachedNotifications = 50; // Prune to last 50 notifications
  static const Duration _defaultMaxAge = Duration(minutes: 10); // 10-min staleness

  /// Cache a list of notifications (overwrites existing cache)
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    try {
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
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      // Update unread count
      final unreadCount = notificationsToCache.where((n) => !n.isRead).length;
      await prefs.setInt(_unreadCountKey, unreadCount);
      
      print('Cached ${notificationsToCache.length} notifications (unread: $unreadCount)');
    } catch (e) {
      print('Error caching notifications: $e');
    }
  }

  /// Get cached notifications, returns null if no cache exists
  Future<List<NotificationModel>?> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
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
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      
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

  /// Check if cache has data
  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cacheKey);
  }

  /// Add a single notification to cache (prepends to list)
  Future<void> addNotificationToCache(NotificationModel notification) async {
    try {
      final cachedNotifications = await getCachedNotifications() ?? [];
      
      // Prepend new notification (newest first)
      cachedNotifications.insert(0, notification);
      
      // Cache the updated list
      await cacheNotifications(cachedNotifications);
      
      print('Added notification to cache: ${notification.id}');
    } catch (e) {
      print('Error adding notification to cache: $e');
    }
  }

  /// Update a specific notification in cache (e.g., when marking as read)
  Future<void> updateCachedNotification(NotificationModel updatedNotification) async {
    try {
      final cachedNotifications = await getCachedNotifications();
      
      if (cachedNotifications == null) {
        print('No cache to update');
        return;
      }
      
      // Find and update the notification
      final index = cachedNotifications.indexWhere((n) => n.id == updatedNotification.id);
      
      if (index != -1) {
        cachedNotifications[index] = updatedNotification;
        await cacheNotifications(cachedNotifications);
        print('Updated notification in cache: ${updatedNotification.id}');
      } else {
        print('Notification not found in cache: ${updatedNotification.id}');
      }
    } catch (e) {
      print('Error updating notification in cache: $e');
    }
  }

  /// Get cached unread count (fast badge display without Firebase query)
  Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Increment unread count (called when new notification arrives)
  Future<void> incrementUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_unreadCountKey) ?? 0;
      await prefs.setInt(_unreadCountKey, currentCount + 1);
      print('Incremented unread count to ${currentCount + 1}');
    } catch (e) {
      print('Error incrementing unread count: $e');
    }
  }

  /// Decrement unread count (called when marking notification as read)
  Future<void> decrementUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_unreadCountKey) ?? 0;
      if (currentCount > 0) {
        await prefs.setInt(_unreadCountKey, currentCount - 1);
        print('Decremented unread count to ${currentCount - 1}');
      }
    } catch (e) {
      print('Error decrementing unread count: $e');
    }
  }

  /// Clear all cached notifications
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
      await prefs.remove(_unreadCountKey);
      print('Cleared notification cache');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Invalidate cache (forces refresh on next read)
  Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUpdateKey);
      print('Invalidated notification cache');
    } catch (e) {
      print('Error invalidating cache: $e');
    }
  }
}

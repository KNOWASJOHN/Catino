import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_session_cache.dart';

/// Service for caching profile data locally to improve performance (user-specific)
class ProfileCacheService {
  static const String _baseCacheKey = 'cached_profile_data';
  static const String _baseLastUpdateKey = 'profile_last_update';
  static const String _userIdKey = 'profile_cache_user_id';
  
  final UserSessionCache _userSession = UserSessionCache();

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
        if (key.startsWith(_baseCacheKey) || key.startsWith(_baseLastUpdateKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing user caches: $e');
    }
  }
  
  /// Save profile data to cache
  Future<void> cacheProfileData(Map<String, dynamic> profileData) async {
    try {
      await _validateUserCache();
      
      final cacheKey = await _getCacheKey();
      final lastUpdateKey = await _getLastUpdateKey();
      
      if (cacheKey == null || lastUpdateKey == null) {
        print('User not authenticated - cannot cache profile data');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(profileData));
      await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching profile data: $e');
    }
  }

  /// Get cached profile data
  Future<Map<String, dynamic>?> getCachedProfileData() async {
    try {
      await _validateUserCache();
      
      final cacheKey = await _getCacheKey();
      if (cacheKey == null) {
        print('User not authenticated - cannot retrieve cached profile data');
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        return Map<String, dynamic>.from(jsonDecode(cachedData));
      }
      return null;
    } catch (e) {
      print('Error retrieving cached profile data: $e');
      return null;
    }
  }

  /// Check if cache exists for current user
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

  /// Get last cache update time
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final lastUpdateKey = await _getLastUpdateKey();
      if (lastUpdateKey == null) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(lastUpdateKey);
      
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear cached profile data for current user
  Future<void> clearCache() async {
    try {
      final cacheKey = await _getCacheKey();
      final lastUpdateKey = await _getLastUpdateKey();
      
      if (cacheKey == null || lastUpdateKey == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(lastUpdateKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear profile cache for all users (called on logout/app reset)
  Future<void> clearAllUsersCache() async {
    try {
      await _clearAllUserCaches();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    } catch (e) {
      print('Error clearing all users profile cache: $e');
    }
  }

  /// Check if cache is stale (older than specified duration)
  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) async {
    final lastUpdate = await getLastUpdateTime();
    
    if (lastUpdate == null) return true;
    
    return DateTime.now().difference(lastUpdate) > maxAge;
  }
}

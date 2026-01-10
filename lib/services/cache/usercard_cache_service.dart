import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_session_cache.dart';

class UserCardCacheService {
  static const String _baseUserCardDataKey = 'usercard_data';
  static const String _userIdKey = 'usercard_cache_user_id';
  
  final UserSessionCache _userSession = UserSessionCache();

  /// Get user-specific cache key
  Future<String?> _getUserCardDataKey() async {
    final userId = await _userSession.getCurrentUserId();
    return userId != null ? '${_baseUserCardDataKey}_$userId' : null;
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
        if (key.startsWith(_baseUserCardDataKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing user caches: $e');
    }
  }

  // Save UserCard data to cache (no expiry - persists until updated)
  Future<void> saveUserCardData(Map<String, dynamic> data) async {
    try {
      await _validateUserCache();
      
      final userCardDataKey = await _getUserCardDataKey();
      if (userCardDataKey == null) {
        print('User not authenticated - cannot save UserCard data');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userCardDataKey, jsonEncode(data));
    } catch (e) {
      print('Error saving UserCard data to cache: $e');
    }
  }

  // Get cached UserCard data
  Future<Map<String, dynamic>?> getUserCardData() async {
    try {
      await _validateUserCache();
      
      final userCardDataKey = await _getUserCardDataKey();
      if (userCardDataKey == null) {
        print('User not authenticated - cannot retrieve UserCard data');
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(userCardDataKey);

      if (cachedData == null) {
        return null;
      }

      return jsonDecode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading UserCard data from cache: $e');
      return null;
    }
  }

  // Clear UserCard cache for current user
  Future<void> clearCache() async {
    try {
      final userCardDataKey = await _getUserCardDataKey();
      if (userCardDataKey == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userCardDataKey);
    } catch (e) {
      print('Error clearing UserCard cache: $e');
    }
  }

  // Clear UserCard cache for all users (called on logout/app reset)
  Future<void> clearAllUsersCache() async {
    try {
      await _clearAllUserCaches();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    } catch (e) {
      print('Error clearing all users UserCard cache: $e');
    }
  }

  // Check if cache exists for current user
  Future<bool> hasCache() async {
    try {
      final userCardDataKey = await _getUserCardDataKey();
      if (userCardDataKey == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(userCardDataKey);
    } catch (e) {
      print('Error checking cache existence: $e');
      return false;
    }
  }
}

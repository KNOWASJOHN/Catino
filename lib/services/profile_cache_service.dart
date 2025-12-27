import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching profile data locally to improve performance
class ProfileCacheService {
  static const String _cacheKey = 'cached_profile_data';
  static const String _lastUpdateKey = 'profile_last_update';
  
  /// Save profile data to cache
  Future<void> cacheProfileData(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(profileData));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching profile data: $e');
    }
  }

  /// Get cached profile data
  Future<Map<String, dynamic>?> getCachedProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData != null) {
        return Map<String, dynamic>.from(jsonDecode(cachedData));
      }
      return null;
    } catch (e) {
      print('Error retrieving cached profile data: $e');
      return null;
    }
  }

  /// Check if cache exists
  Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_cacheKey);
    } catch (e) {
      return false;
    }
  }

  /// Get last cache update time
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateKey);
      
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear cached profile data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Check if cache is stale (older than specified duration)
  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) async {
    final lastUpdate = await getLastUpdateTime();
    
    if (lastUpdate == null) return true;
    
    return DateTime.now().difference(lastUpdate) > maxAge;
  }
}

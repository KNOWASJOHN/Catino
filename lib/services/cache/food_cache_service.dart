import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/food_item.dart';
import 'user_session_cache.dart';

/// Service for caching food items locally (global data but user-session aware)
class FoodCacheService {
  static const String _allFoodCacheKey = 'cached_all_food_items';
  static const String _categoryPrefix = 'cached_food_category_';
  static const String _vegCacheKey = 'cached_vegetarian_items';
  static const String _lastUpdateKey = 'food_cache_last_update';
  static const String _userIdKey = 'food_cache_user_id';
  
  final UserSessionCache _userSession = UserSessionCache();

  /// Validate user session (food data is global but we track user sessions)
  Future<void> _validateUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = await _userSession.getCurrentUserId();
      final cachedUserId = prefs.getString(_userIdKey);
      
      // Update user session tracking without clearing global food data
      if (currentUserId != cachedUserId) {
        if (currentUserId != null) {
          await prefs.setString(_userIdKey, currentUserId);
        }
      }
    } catch (e) {
      // ...removed print statement...
    }
  }
  
  /// Cache all food items
  Future<void> cacheAllFoodItems(List<FoodItem> items) async {
    try {
      await _validateUserSession();
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toMap()).toList();
      await prefs.setString(_allFoodCacheKey, jsonEncode(jsonList));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Get cached all food items
  Future<List<FoodItem>?> getCachedAllFoodItems() async {
    try {
      await _validateUserSession();
      
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_allFoodCacheKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => FoodItem.fromMap(json)).toList();
      }
      return null;
    } catch (e) {
      // ...removed print statement...
      return null;
    }
  }

  /// Cache food items by category
  Future<void> cacheFoodItemsByCategory(String category, List<FoodItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toMap()).toList();
      await prefs.setString('$_categoryPrefix$category', jsonEncode(jsonList));
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Get cached food items by category
  Future<List<FoodItem>?> getCachedFoodItemsByCategory(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_categoryPrefix$category');
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => FoodItem.fromMap(json)).toList();
      }
      return null;
    } catch (e) {
      // ...removed print statement...
      return null;
    }
  }

  /// Cache vegetarian items
  Future<void> cacheVegetarianItems(List<FoodItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toMap()).toList();
      await prefs.setString(_vegCacheKey, jsonEncode(jsonList));
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Get cached vegetarian items
  Future<List<FoodItem>?> getCachedVegetarianItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_vegCacheKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => FoodItem.fromMap(json)).toList();
      }
      return null;
    } catch (e) {
      // ...removed print statement...
      return null;
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

  /// Clear all food cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_categoryPrefix) || 
            key == _allFoodCacheKey || 
            key == _vegCacheKey || 
            key == _lastUpdateKey) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Clear food cache for all users (called on logout/app reset)
  Future<void> clearAllUsersCache() async {
    try {
      await clearCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Check if cache is stale
  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 1)}) async {
    final lastUpdate = await getLastUpdateTime();
    
    if (lastUpdate == null) return true;
    
    return DateTime.now().difference(lastUpdate) > maxAge;
  }

  /// Invalidate cache (mark as stale without deleting)
  Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, 0);
    } catch (e) {
      // ...removed print statement...
    }
  }
}

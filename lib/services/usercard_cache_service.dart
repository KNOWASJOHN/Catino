import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserCardCacheService {
  static const String _userCardDataKey = 'usercard_data';

  // Save UserCard data to cache (no expiry - persists until updated)
  Future<void> saveUserCardData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCardDataKey, jsonEncode(data));
    } catch (e) {
      print('Error saving UserCard data to cache: $e');
    }
  }

  // Get cached UserCard data
  Future<Map<String, dynamic>?> getUserCardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_userCardDataKey);

      if (cachedData == null) {
        return null;
      }

      return jsonDecode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading UserCard data from cache: $e');
      return null;
    }
  }

  // Clear UserCard cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCardDataKey);
    } catch (e) {
      print('Error clearing UserCard cache: $e');
    }
  }

  // Check if cache exists
  Future<bool> hasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userCardDataKey);
    } catch (e) {
      print('Error checking cache existence: $e');
      return false;
    }
  }
}

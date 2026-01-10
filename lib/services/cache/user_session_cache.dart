import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for caching user session data to minimize Supabase Auth calls
class UserSessionCache {
  static final UserSessionCache _instance = UserSessionCache._internal();
  factory UserSessionCache() => _instance;
  UserSessionCache._internal();

  final _supabase = Supabase.instance.client;
  String? _cachedUserId;
  DateTime? _lastUserIdCheck;
  static const Duration _userIdCacheDuration = Duration(minutes: 5);

  /// Get current user ID with caching to minimize Supabase Auth calls
  Future<String?> getCurrentUserId({bool forceRefresh = false}) async {
    try {
      // Return cached UID if valid and not forcing refresh
      if (!forceRefresh && 
          _cachedUserId != null && 
          _lastUserIdCheck != null &&
          DateTime.now().difference(_lastUserIdCheck!) < _userIdCacheDuration) {
        return _cachedUserId;
      }

      // Get fresh UID from Supabase Auth
      final user = _supabase.auth.currentUser;
      _cachedUserId = user?.id;
      _lastUserIdCheck = DateTime.now();
      
      return _cachedUserId;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  /// Clear cached user session data (call on logout/user change)
  void clearUserSession() {
    _cachedUserId = null;
    _lastUserIdCheck = null;
  }

  /// Check if user has changed (for cache validation)
  Future<bool> hasUserChanged(String? previousUserId) async {
    final currentUserId = await getCurrentUserId();
    return currentUserId != previousUserId;
  }

  /// Get user-specific cache key
  String getUserCacheKey(String baseKey, {String? userId}) {
    final uid = userId ?? _cachedUserId;
    return uid != null ? '${baseKey}_$uid' : baseKey;
  }

  /// Check if current user is authenticated
  Future<bool> isUserAuthenticated() async {
    final userId = await getCurrentUserId();
    return userId != null;
  }
}
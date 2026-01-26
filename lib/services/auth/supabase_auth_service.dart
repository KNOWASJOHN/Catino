import 'package:supabase_flutter/supabase_flutter.dart';
import '../cache/profile_cache_service.dart';
import '../cache/print_cache_service.dart';
import '../cache/food_cache_service.dart';
import '../cache/notification_cache_service.dart';
import '../cache/usercard_cache_service.dart';
import '../cache/user_session_cache.dart';

/// Authentication Service for handling user login, signup, and session management with Supabase
class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileCacheService _profileCacheService = ProfileCacheService();
  final PrintCacheService _printCacheService = PrintCacheService();
  final FoodCacheService _foodCacheService = FoodCacheService();
  final NotificationCacheService _notificationCacheService = NotificationCacheService();
  final UserCardCacheService _userCardCacheService = UserCardCacheService();
  final UserSessionCache _userSessionCache = UserSessionCache();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Start listening to user data changes in Supabase
  void startListeningToUserData() {
    if (currentUserId == null) return;
    
    _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', currentUserId!)
        .listen((data) {
      if (data.isNotEmpty) {
        final userData = data.first;
        // Update cache with fresh data
        _profileCacheService.cacheProfileData(userData);
        // Dev-only marker: profile data updated. Avoid printing PII.
        // if (kDebugMode) { logInfo('Profile data updated from Supabase listener'); }
      }
    });
  }

  // Check if user is logged in
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create user with email and password
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Save user data to Supabase database
      if (response.user != null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'user_name': userData['name'],
          'phone': userData['phone'],
          'student_id': userData['studentId'],
          'branch': userData['branch'],
          'semester': userData['semester'],
          'hostel': userData['hostel'],
          'profile_pic_url': userData['profilePicUrl'] ?? '',
          'notifications_enabled': true,
          'dietary_preference': 'Both',
          'created_at_timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        return {'success': true, 'user': response.user};
      }

      return {'success': false, 'message': 'Failed to create user'};
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An internal error occurred',
      };
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Start listening to user data changes
      startListeningToUserData();

      return {'success': true, 'user': response.user};
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An internal error occurred',
      };
    }
  }

  /// Sign out and clear all cache services
  Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear all cache services for all users
      await Future.wait([
        _profileCacheService.clearAllUsersCache(),
        _printCacheService.clearAllUsersCache(),
        _foodCacheService.clearAllUsersCache(),
        _notificationCacheService.clearAllUsersCache(),
        _userCardCacheService.clearAllUsersCache(),
      ]);
      
      // Clear user session cache
      _userSessionCache.clearUserSession();
      
      // Dev-only: user signed out and caches cleared. Avoid printing PII in logs.
    } catch (e) {
      // Dev-only: error during sign out; avoid printing exception details.
      // Still sign out even if cache clearing fails
      await _supabase.auth.signOut();
      _userSessionCache.clearUserSession();
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return {
        'success': true,
        'message': 'Password reset link sent to your email',
      };
    } catch (e) {
      // Dev-only: error sending password reset; avoid printing exception details.
      return {
        'success': false,
        'message': 'Failed to send reset email',
      };
    }
  }

  /// Get user data from cache first, then from Supabase if needed
  Future<Map<String, dynamic>?> getUserData({bool forceRefresh = false}) async {
    try {
      if (currentUserId == null) return null;

      // If not forcing refresh, try to get cached data first
      if (!forceRefresh) {
        final cachedData = await _profileCacheService.getCachedProfileData();
        if (cachedData != null) {
          // Dev-only: returning user data from cache; avoid printing PII.
          return cachedData;
        }
      }
      // Dev-only: fetching user data from Supabase; avoid printing PII.
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUserId!)
          .single();

      // Cache the fresh data
      await _profileCacheService.cacheProfileData(response);
      return response;
    } catch (e) {
      // Dev-only: error fetching user data; avoid printing exception details.
      // Fallback to cache
      return await _profileCacheService.getCachedProfileData();
    }
  }

  /// Update user data in Supabase
  /// Call this when user changes notification or dietary preference in UI
  Future<bool> updateUserData(Map<String, dynamic> userData) async {
    try {
      if (currentUserId == null) return false;

      // Update user data in Supabase
      await _supabase
          .from('users')
          .update(userData)
          .eq('id', currentUserId!);

      // Update cache with fresh data
      final fullUserData = await getUserData(forceRefresh: true);
      if (fullUserData != null) {
        await _profileCacheService.cacheProfileData(fullUserData);
      }

      // Dev-only: user data updated; avoid printing PII.
      return true;
    } catch (e) {
      // Dev-only: error updating user data; avoid printing exception details.
      return false;
    }
  }

  /// Update FCM token in Supabase
  Future<void> updateFCMToken(String token) async {
    try {
      if (currentUserId == null) return;

      await _supabase.from('users').update({
        'fcm_token': token,
        'token_updated_at': DateTime.now().millisecondsSinceEpoch,
      }).eq('id', currentUserId!);

      // Dev-only: FCM token updated; avoid printing tokens to stdout.
    } catch (e) {
      // Dev-only: error updating FCM token; avoid printing exception details.
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      if (currentUserId == null) return false;

      // Delete user data from database (cascading deletes will handle related data)
      await _supabase
          .from('users')
          .delete()
          .eq('id', currentUserId!);

      // Sign out
      await signOut();

      // Dev-only: user account deleted; avoid printing PII.
      return true;
    } catch (e) {
      // Dev-only: error deleting account; avoid printing exception details.
      return false;
    }
  }
}

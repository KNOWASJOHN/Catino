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
        print('Profile data updated from Supabase listener');
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
        'message': 'An error occurred: ${e.toString()}',
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
        'message': 'An error occurred: ${e.toString()}',
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
      
      print('User signed out and all caches cleared');
    } catch (e) {
      print('Error during sign out: $e');
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
      print('Error sending password reset: $e');
      return {
        'success': false,
        'message': 'Failed to send reset email: ${e.toString()}',
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
          print('Returning user data from cache');
          return cachedData;
        }
      }

      print('Fetching user data from Supabase');
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUserId!)
          .single();

      // Cache the fresh data
      await _profileCacheService.cacheProfileData(response);
      return response;
    } catch (e) {
      print('Error fetching user data: $e');
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

      print('User data updated successfully');
      return true;
    } catch (e) {
      print('Error updating user data: $e');
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

      print('FCM token updated in Supabase');
    } catch (e) {
      print('Error updating FCM token: $e');
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

      print('User account deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}

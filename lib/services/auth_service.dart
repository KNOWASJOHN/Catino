import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profile_cache_service.dart';

/// Authentication Service for handling user login, signup, and session management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ProfileCacheService _cacheService = ProfileCacheService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Start listening to user data changes in Firebase
  void startListeningToUserData() {
    if (currentUser == null) return;
    
    _database.child('users').child(currentUser!.uid).onValue.listen((event) {
      if (event.snapshot.exists) {
        final userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        // Update cache with fresh data
        _cacheService.cacheProfileData(userData);
        print('Profile data updated from Firebase listener');
      }
    });
  }

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firebase Realtime Database
      if (userCredential.user != null) {
        await _database.child('users').child(userCredential.user!.uid).set({
          'email': email,
          'name': userData['name'],
          'phone': userData['phone'],
          'studentId': userData['studentId'],
          'branch': userData['branch'],
          'semester': userData['semester'],
          'hostel': userData['hostel'],
          'profilePicUrl': userData['profilePicUrl'] ?? '',
          'notificationsEnabled': true,
          'dietaryPreference': 'Both',
          'createdAt': ServerValue.timestamp,
        });

        return {'success': true, 'user': userCredential.user};
      }

      return {'success': false, 'message': 'Failed to create user'};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Start listening to user data changes
      startListeningToUserData();

      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Sign out and clear cache
  Future<void> signOut() async {
    await _auth.signOut();
    await _cacheService.clearCache();
  }

  /// Get user data from cache first, then from Firebase if needed
  Future<Map<String, dynamic>?> getUserData({bool forceRefresh = false}) async {
    try {
      if (currentUser == null) return null;

      // If not forcing refresh, try to get cached data first
      if (!forceRefresh) {
        final cachedData = await _cacheService.getCachedProfileData();
        if (cachedData != null) {
          // Return cached data immediately
          // Optionally fetch fresh data in background if cache is stale
          _refreshDataIfStale();
          return cachedData;
        }
      }

      // Fetch from Firebase
      DatabaseEvent event = await _database
          .child('users')
          .child(currentUser!.uid)
          .once();

      if (event.snapshot.exists) {
        final userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        // Cache the fresh data
        await _cacheService.cacheProfileData(userData);
        return userData;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      // If Firebase fails, try to return cached data as fallback
      return await _cacheService.getCachedProfileData();
    }
  }

  /// Refresh data in background if cache is stale
  void _refreshDataIfStale() async {
    try {
      final isStale = await _cacheService.isCacheStale(
        maxAge: const Duration(minutes: 30),
      );
      
      if (isStale) {
        // Fetch fresh data without waiting
        getUserData(forceRefresh: true);
      }
    } catch (e) {
      print('Error checking cache staleness: $e');
    }
  }

  /// Update user data in Firebase and cache
  Future<bool> updateUserData(Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) return false;

      // Update in Firebase
      await _database.child('users').child(currentUser!.uid).update(updates);
      
      // Update cache with the new data
      final cachedData = await _cacheService.getCachedProfileData();
      if (cachedData != null) {
        final updatedData = {...cachedData, ...updates};
        await _cacheService.cacheProfileData(updatedData);
      } else {
        // If no cache exists, fetch and cache all data
        await getUserData(forceRefresh: true);
      }
      
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred. Please try again';
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/user_session_cache.dart';
import '../lib/services/print_cache_service.dart';
import '../lib/services/profile_cache_service.dart';
import '../lib/components/print_history.dart';

/// Test file to verify user-specific cache functionality
void main() {
  group('User-Specific Cache Tests', () {
    late UserSessionCache userSessionCache;
    late PrintCacheService printCacheService;
    late ProfileCacheService profileCacheService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      userSessionCache = UserSessionCache();
      printCacheService = PrintCacheService();
      profileCacheService = ProfileCacheService();
    });

    test('UserSessionCache should cache user ID correctly', () async {
      // Mock user ID (normally would come from Firebase Auth)
      const testUserId = 'test_user_123';
      
      // Since we can't mock Firebase Auth easily in unit test,
      // we can test the cache key generation
      final cacheKey = userSessionCache.getUserCacheKey('test_key', userId: testUserId);
      
      expect(cacheKey, equals('test_key_$testUserId'));
    });

    test('PrintCacheService should handle user-specific cache keys', () async {
      // Test that cache methods handle authentication properly
      // This would fail gracefully when no user is authenticated
      final result = await printCacheService.getCachedPrintJobs();
      
      // Should return null when no user is authenticated
      expect(result, isNull);
    });

    test('ProfileCacheService should handle user-specific cache keys', () async {
      // Test that profile cache methods handle authentication properly
      final result = await profileCacheService.getCachedProfileData();
      
      // Should return null when no user is authenticated
      expect(result, isNull);
    });

    test('Cache services should have clearAllUsersCache methods', () {
      // Verify that all cache services have the clearAllUsersCache method
      expect(printCacheService.clearAllUsersCache, isA<Function>());
      expect(profileCacheService.clearAllUsersCache, isA<Function>());
    });

    test('PrintJob should serialize/deserialize correctly', () {
      final printJob = PrintJob(
        id: 'test_123',
        code: 'TEST001',
        fileName: 'test_document.pdf',
        pageCount: 5,
        dateTime: DateTime.now(),
        fileUrl: 'https://example.com/test.pdf',
        status: PrintStatus.pending,
      );

      final map = printJob.toMap();
      final recreated = PrintJob.fromMap(map);

      expect(recreated.id, equals(printJob.id));
      expect(recreated.code, equals(printJob.code));
      expect(recreated.fileName, equals(printJob.fileName));
      expect(recreated.pageCount, equals(printJob.pageCount));
      expect(recreated.status, equals(printJob.status));
    });
  });
}
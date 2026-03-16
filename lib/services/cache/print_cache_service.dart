import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/print_job.dart';
import 'user_session_cache.dart';

/// Service for caching print jobs locally (user-specific)
class PrintCacheService {
  static const String _baseCacheKey = 'cached_print_jobs';
  static const String _baseLastUpdateKey = 'print_cache_last_update';
  static const String _userIdKey = 'print_cache_user_id';
  
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
      // ...removed print statement...
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
      // ...removed print statement...
    }
  }
  
  /// Cache print jobs
  Future<void> cachePrintJobs(List<PrintJob> jobs) async {
    try {
      await _validateUserCache();
      
      final cacheKey = await _getCacheKey();
      final lastUpdateKey = await _getLastUpdateKey();
      
      if (cacheKey == null || lastUpdateKey == null) {
        // ...removed print statement...
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = jobs.map((job) => job.toMap()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
      await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Get cached print jobs
  Future<List<PrintJob>?> getCachedPrintJobs() async {
    try {
      await _validateUserCache();
      
      final cacheKey = await _getCacheKey();
      if (cacheKey == null) {
        // ...removed print statement...
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => PrintJob.fromMap(json)).toList();
      }
      return null;
    } catch (e) {
      // ...removed print statement...
      return null;
    }
  }

  /// Update a single print job in cache
  Future<void> updateCachedJob(PrintJob updatedJob) async {
    try {
      final cachedJobs = await getCachedPrintJobs();
      if (cachedJobs != null) {
        final index = cachedJobs.indexWhere((job) => job.id == updatedJob.id);
        if (index != -1) {
          cachedJobs[index] = updatedJob;
          await cachePrintJobs(cachedJobs);
        }
      }
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Add a new job to cache
  Future<void> addJobToCache(PrintJob newJob) async {
    try {
      final cachedJobs = await getCachedPrintJobs() ?? [];
      cachedJobs.insert(0, newJob); // Add at the beginning
      await cachePrintJobs(cachedJobs);
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Remove a job from cache
  Future<void> removeJobFromCache(String jobId) async {
    try {
      final cachedJobs = await getCachedPrintJobs();
      if (cachedJobs != null) {
        cachedJobs.removeWhere((job) => job.id == jobId);
        await cachePrintJobs(cachedJobs);
      }
    } catch (e) {
      // ...removed print statement...
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

  /// Clear print cache for current user
  Future<void> clearCache() async {
    try {
      final cacheKey = await _getCacheKey();
      final lastUpdateKey = await _getLastUpdateKey();
      
      if (cacheKey == null || lastUpdateKey == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(lastUpdateKey);
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Clear print cache for all users (called on logout/app reset)
  Future<void> clearAllUsersCache() async {
    try {
      await _clearAllUserCaches();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    } catch (e) {
      // ...removed print statement...
    }
  }

  /// Check if cache is stale
  Future<bool> isCacheStale({Duration maxAge = const Duration(minutes: 30)}) async {
    final lastUpdate = await getLastUpdateTime();
    
    if (lastUpdate == null) return true;
    
    return DateTime.now().difference(lastUpdate) > maxAge;
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
}

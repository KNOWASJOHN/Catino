import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/print_history.dart';

/// Service for caching print jobs locally
class PrintCacheService {
  static const String _cacheKey = 'cached_print_jobs';
  static const String _lastUpdateKey = 'print_cache_last_update';
  
  /// Cache print jobs
  Future<void> cachePrintJobs(List<PrintJob> jobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = jobs.map((job) => job.toMap()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching print jobs: $e');
    }
  }

  /// Get cached print jobs
  Future<List<PrintJob>?> getCachedPrintJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => PrintJob.fromMap(json)).toList();
      }
      return null;
    } catch (e) {
      print('Error retrieving cached print jobs: $e');
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
      print('Error updating cached job: $e');
    }
  }

  /// Add a new job to cache
  Future<void> addJobToCache(PrintJob newJob) async {
    try {
      final cachedJobs = await getCachedPrintJobs() ?? [];
      cachedJobs.insert(0, newJob); // Add at the beginning
      await cachePrintJobs(cachedJobs);
    } catch (e) {
      print('Error adding job to cache: $e');
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
      print('Error removing job from cache: $e');
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

  /// Clear all print cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      print('Error clearing print cache: $e');
    }
  }

  /// Check if cache is stale
  Future<bool> isCacheStale({Duration maxAge = const Duration(minutes: 30)}) async {
    final lastUpdate = await getLastUpdateTime();
    
    if (lastUpdate == null) return true;
    
    return DateTime.now().difference(lastUpdate) > maxAge;
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
}

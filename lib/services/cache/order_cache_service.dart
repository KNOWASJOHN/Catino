import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/order_model.dart';
import '../../utils/logger_config.dart';

final _logger = AppLogger.getLogger('OrderCacheService');

/// Service for caching orders locally to improve performance and offline support
class OrderCacheService {
  static const String _ordersKey = 'cached_orders';
  static const String _timestampKey = 'orders_cache_timestamp';

  /// Get cached orders from SharedPreferences
  Future<List<Order>?> getCachedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey);
      
      if (ordersJson == null || ordersJson.isEmpty) {
        return null;
      }

      final List<dynamic> ordersList = jsonDecode(ordersJson);
      return ordersList.map((orderData) => Order.fromMap(orderData)).toList();
    } catch (e) {
      _logger.warning('Error getting cached orders', e);
      return null;
    }
  }

  /// Cache orders in SharedPreferences
  Future<void> setCachedOrders(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = jsonEncode(orders.map((order) => order.toMap()).toList());
      
      await prefs.setString(_ordersKey, ordersJson);
      await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
      
      _logger.fine('Cached ${orders.length} orders successfully');
    } catch (e) {
      _logger.warning('Error caching orders', e);
    }
  }

  /// Update a specific cached order (useful for status updates)
  Future<void> updateCachedOrder(Order updatedOrder) async {
    try {
      final cachedOrders = await getCachedOrders();
      if (cachedOrders == null) return;

      final orderIndex = cachedOrders.indexWhere((order) => order.id == updatedOrder.id);
      if (orderIndex != -1) {
        cachedOrders[orderIndex] = updatedOrder;
        await setCachedOrders(cachedOrders);
        _logger.fine('Updated cached order: ${updatedOrder.code} - ${updatedOrder.status.displayText}');
      }
    } catch (e) {
      _logger.warning('Error updating cached order', e);
    }
  }

  /// Remove a specific order from cache
  Future<void> removeOrderFromCache(String orderId) async {
    try {
      final cachedOrders = await getCachedOrders();
      if (cachedOrders == null) return;

      final initialLength = cachedOrders.length;
      cachedOrders.removeWhere((order) => order.id == orderId);
      
      if (cachedOrders.length < initialLength) {
        // Order was found and removed, update cache with new list
        await setCachedOrders(cachedOrders);
        _logger.fine('Removed order $orderId from cache');
      } else {
        _logger.fine('Order $orderId not found in cache');
      }
    } catch (e) {
      _logger.warning('Error removing order from cache', e);
    }
  }

  /// Get cache timestamp
  Future<DateTime?> getCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_timestampKey);
      
      if (timestampStr != null) {
        return DateTime.parse(timestampStr);
      }
      return null;
    } catch (e) {
      _logger.warning('Error getting cache timestamp', e);
      return null;
    }
  }

  /// Clear all cached orders
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ordersKey);
      await prefs.remove(_timestampKey);
      _logger.info('Order cache cleared');
    } catch (e) {
      _logger.warning('Error clearing order cache', e);
    }
  }

  /// Check if cache is stale (older than specified minutes)
  Future<bool> isCacheStale({int maxAgeMinutes = 10}) async {
    try {
      final timestamp = await getCacheTimestamp();
      if (timestamp == null) return true;

      final age = DateTime.now().difference(timestamp);
      return age.inMinutes > maxAgeMinutes;
    } catch (e) {
      _logger.warning('Error checking cache staleness', e);
      return true;
    }
  }

  /// Get cache size information
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final orders = await getCachedOrders();
      final timestamp = await getCacheTimestamp();
      
      return {
        'orderCount': orders?.length ?? 0,
        'lastUpdated': timestamp?.toIso8601String(),
        'isStale': await isCacheStale(),
      };
    } catch (e) {
      _logger.warning('Error getting cache info', e);
      return {
        'orderCount': 0,
        'lastUpdated': null,
        'isStale': true,
      };
    }
  }
}
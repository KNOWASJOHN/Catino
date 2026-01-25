import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order_model.dart';
import '../cache/order_cache_service.dart';
import '../notifications/order_notification_service.dart';
import '../../utils/logger_config.dart';

final _logger = AppLogger.getLogger('SupabaseOrderService');

/// Service for managing orders in Supabase with real-time status change notifications
class SupabaseOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OrderCacheService _cacheService = OrderCacheService();
  final OrderNotificationService _notificationService =
      OrderNotificationService();
  bool _isListening = false;

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Start listening to order status changes in Supabase
  void startListeningToOrders() {
    if (currentUserId == null || _isListening) return;
    _isListening = true;

    _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .listen((data) {
          try {
            _logger.info('Order data changed, processing for notifications...');
            _processOrderChanges(data);
          } catch (e) {
            _logger.severe('Error processing order changes', e);
          }
        });

    _logger.info('Started listening to order changes for user: $currentUserId');
  }

  /// Stop listening to order changes
  void stopListeningToOrders() {
    _isListening = false;
    _logger.info('Stopped listening to order changes');
  }

  /// Process order changes and trigger notifications for status updates
  Future<void> _processOrderChanges(
    List<Map<String, dynamic>> ordersData,
  ) async {
    try {
      if (currentUserId == null) return;

      // Get cached orders for comparison
      final cachedOrders = await _cacheService.getCachedOrders();
      final cachedOrdersMap = <String, Order>{};

      if (cachedOrders != null) {
        for (final order in cachedOrders) {
          cachedOrdersMap[order.id] = order;
        }
      }

      // Convert Supabase data to Order objects
      final currentOrders = <Order>[];
      for (final orderData in ordersData) {
        try {
          // Fetch order items for this order
          final orderItems = await _getOrderItems(orderData['id']);
          final orderDataWithItems = Map<String, dynamic>.from(orderData);
          orderDataWithItems['items'] = orderItems;

          final order = Order.fromSupabaseMap(orderDataWithItems);
          currentOrders.add(order);

          // Check for status changes
          final cachedOrder = cachedOrdersMap[order.id];
          if (cachedOrder != null && cachedOrder.status != order.status) {
            // Status changed - send immediate notification
            _logger.info(
              'Order status changed: ${order.code} - ${cachedOrder.status.displayText} -> ${order.status.displayText}',
            );
            _notificationService.notifyOrderStatusChanged(
              order,
              cachedOrder.status,
            );
          } else if (cachedOrder == null) {
            // New order - send confirmation notification
            _logger.info('New order detected: ${order.code}');
          }
        } catch (e) {
          _logger.warning('Error parsing order ${orderData['id']}', e);
        }
      }

      // Update cache with current orders
      await _cacheService.setCachedOrders(currentOrders);
    } catch (e) {
      _logger.severe('Error in _processOrderChanges', e);
    }
  }

  /// Get order items for a specific order
  Future<List<Map<String, dynamic>>> _getOrderItems(String orderId) async {
    try {
      final response = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      return response
          .map<Map<String, dynamic>>(
            (item) => {'id': item['food_item_id'], 'qty': item['quantity']},
          )
          .toList();
    } catch (e) {
      _logger.warning('Error fetching order items for $orderId', e);
      return [];
    }
  }

  /// Get user's orders from Supabase or cache
  Future<List<Order>> getUserOrders() async {
    try {
      if (currentUserId == null) {
        _logger.warning('User not authenticated');
        return [];
      }

      // Try cache first for faster loading
      final cached = await _cacheService.getCachedOrders();
      if (cached != null && cached.isNotEmpty) {
        _logger.fine('Returning ${cached.length} cached orders');

        // Check if cache is stale (older than 10 minutes)
        final cacheTime = await _cacheService.getCacheTimestamp();
        final now = DateTime.now();
        if (cacheTime != null && now.difference(cacheTime).inMinutes < 10) {
          return cached;
        }
        _logger.info('Cache is stale, fetching fresh data...');
      }

      _logger.info('Fetching orders from Supabase for user: $currentUserId');

      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', currentUserId!)
          .order('timestamp', ascending: false);

      List<Order> orders = [];

      for (final orderData in response) {
        try {
          // Fetch order items for this order
          final orderItems = await _getOrderItems(orderData['id']);
          final orderDataWithItems = Map<String, dynamic>.from(orderData);
          orderDataWithItems['items'] = orderItems;

          orders.add(Order.fromSupabaseMap(orderDataWithItems));
        } catch (e) {
          _logger.warning('Error parsing order ${orderData['id']}', e);
        }
      }

      // Cache the results
      await _cacheService.setCachedOrders(orders);
      _logger.info('Successfully loaded and cached ${orders.length} orders');

      return orders;
    } catch (e, stackTrace) {
      _logger.severe('Error loading orders', e, stackTrace);

      // Try to return cached data as fallback
      final cached = await _cacheService.getCachedOrders();
      return cached ?? [];
    }
  }

  /// Add a new order (typically called from CartProvider)
  Future<bool> addOrder(Order order) async {
    try {
      if (currentUserId == null) return false;

      // Add to Supabase Database
      final orderData = {
        'id': order.id,
        'user_id': currentUserId,
        'code': order.code,
        'qr_code': order.qrCode,
        'status': order.status.value,
        'timestamp': order.dateTime.millisecondsSinceEpoch,
        'payment_id': order.paymentId,
        'order_id': order.orderId,
        'payment_status': order.paymentStatus,
      };

      _logger.info('Inserting order to Supabase: $orderData');

      await _supabase.from('orders').insert(orderData);

      // Add order items
      final orderItemsData = order.items
          .map(
            (item) => {
              'order_id': order.id,
              'food_item_id': item.id,
              'quantity': item.quantity,
            },
          )
          .toList();

      await _supabase.from('order_items').insert(orderItemsData);

      _logger.info('Order added to Supabase: ${order.id}');

      // Send notification for new order (confirmation)
      await _notificationService.notifyOrderPlaced(order);

      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error adding order', e, stackTrace);
      return false;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus.value})
          .eq('id', orderId);

      _logger.info(
        'Order status updated: $orderId -> ${newStatus.displayText}',
      );
      return true;
    } catch (e) {
      _logger.severe('Error updating order status', e);
      return false;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  /// Get a specific order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      // Fetch order items
      final orderItems = await _getOrderItems(orderId);
      final orderDataWithItems = Map<String, dynamic>.from(response);
      orderDataWithItems['items'] = orderItems;

      return Order.fromSupabaseMap(orderDataWithItems);
    } catch (e) {
      _logger.warning('Error fetching order by ID', e);
      return null;
    }
  }

  /// Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    try {
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', currentUserId!)
          .eq('status', status.value)
          .order('timestamp', ascending: false);

      List<Order> orders = [];

      for (final orderData in response) {
        try {
          final orderItems = await _getOrderItems(orderData['id']);
          final orderDataWithItems = Map<String, dynamic>.from(orderData);
          orderDataWithItems['items'] = orderItems;

          orders.add(Order.fromSupabaseMap(orderDataWithItems));
        } catch (e) {
          _logger.warning('Error parsing order ${orderData['id']}', e);
        }
      }

      return orders;
    } catch (e) {
      _logger.severe('Error fetching orders by status', e);
      return [];
    }
  }
}

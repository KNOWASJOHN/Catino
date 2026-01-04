import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import 'order_cache_service.dart';
import 'order_notification_service.dart';

/// Service for managing orders in Firebase with real-time status change notifications
class OrderService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OrderCacheService _cacheService = OrderCacheService();
  final OrderNotificationService _notificationService = OrderNotificationService();
  bool _isListening = false;
  String? _lastCacheUpdate; // Track last cache update to prevent duplicates

  /// Start listening to order status changes in Firebase
  void startListeningToOrders() {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _isListening) return;
    _isListening = true;
    
    _database.child('users').child(userId).child('orders').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          print('Order data changed, processing for notifications...');
          _processOrderChanges(event.snapshot.value as Map<dynamic, dynamic>);
        } catch (e) {
          print('Error processing order changes: $e');
        }
      }
    });
    
    print('Started listening to order changes for user: $userId');
  }

  /// Stop listening to order changes
  void stopListeningToOrders() {
    _isListening = false;
    print('Stopped listening to order changes');
  }

  /// Process order changes and trigger notifications for status updates
  Future<void> _processOrderChanges(Map<dynamic, dynamic> ordersData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get cached orders for comparison
      final cachedOrders = await _cacheService.getCachedOrders();
      final cachedOrdersMap = <String, Order>{};
      
      if (cachedOrders != null) {
        for (final order in cachedOrders) {
          cachedOrdersMap[order.id] = order;
        }
      }

      // Convert Firebase data to Order objects
      final currentOrders = <Order>[];
      ordersData.forEach((key, value) {
        if (value is Map) {
          try {
            // Add the Firebase key as the id if not present
            final orderData = Map<String, dynamic>.from(value);
            orderData['id'] = key.toString();
            
            final order = Order.fromMap(orderData);
            currentOrders.add(order);
            
            // Check for status changes
            final cachedOrder = cachedOrdersMap[order.id];
            if (cachedOrder != null && cachedOrder.status != order.status) {
              // Status changed - send immediate notification
              print('Order status changed: ${order.code} - ${cachedOrder.status.displayText} -> ${order.status.displayText}');
              _notificationService.notifyOrderStatusChanged(order, cachedOrder.status);
            } else if (cachedOrder == null) {
              // New order - send confirmation notification (this is usually handled by CartProvider)
              print('New order detected: ${order.code}');
            }
          } catch (e) {
            print('Error parsing order $key: $e');
          }
        }
      });

      // Update cache with current orders
      await _cacheService.setCachedOrders(currentOrders);
      _lastCacheUpdate = DateTime.now().toIso8601String();
      
    } catch (e) {
      print('Error in _processOrderChanges: $e');
    }
  }

  /// Get user's orders from Firebase or cache
  Future<List<Order>> getUserOrders() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('User not authenticated');
        return [];
      }

      // Try cache first for faster loading
      final cached = await _cacheService.getCachedOrders();
      if (cached != null && cached.isNotEmpty) {
        print('Returning ${cached.length} cached orders');
        
        // Check if cache is stale (older than 10 minutes)
        final cacheTime = await _cacheService.getCacheTimestamp();
        final now = DateTime.now();
        if (cacheTime != null && now.difference(cacheTime).inMinutes < 10) {
          return cached;
        }
        print('Cache is stale, fetching fresh data...');
      }

      print('Fetching orders from Firebase for user: $userId');
      final event = await _database
          .child('users')
          .child(userId)
          .child('orders')
          .once();

      print('Database snapshot exists: ${event.snapshot.exists}');
      
      if (!event.snapshot.exists) {
        print('No orders found in database');
        return [];
      }

      final snapshotValue = event.snapshot.value;
      print('Snapshot value type: ${snapshotValue.runtimeType}');
      
      if (snapshotValue == null) {
        print('Snapshot value is null');
        return [];
      }

      Map<dynamic, dynamic> ordersMap = snapshotValue as Map<dynamic, dynamic>;
      print('Found ${ordersMap.length} orders in database');
      
      List<Order> orders = [];

      ordersMap.forEach((key, value) {
        try {
          print('Processing order $key with value type: ${value.runtimeType}');
          if (value is Map) {
            // Add the Firebase key as the id if not present
            final orderData = Map<String, dynamic>.from(value);
            orderData['id'] = key.toString();
            
            orders.add(Order.fromMap(orderData));
          } else {
            print('Value is not a Map: ${value.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('Error parsing order $key: $e');
          print('Stack trace: $stackTrace');
        }
      });

      // Sort by timestamp (newest first)
      orders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      // Cache the results
      await _cacheService.setCachedOrders(orders);
      print('Successfully loaded and cached ${orders.length} orders');

      return orders;
    } catch (e, stackTrace) {
      print('Error loading orders: $e');
      print('Stack trace: $stackTrace');
      
      // Try to return cached data as fallback
      final cached = await _cacheService.getCachedOrders();
      return cached ?? [];
    }
  }

  /// Add a new order (typically called from CartProvider)
  Future<bool> addOrder(Order order) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Add to Firebase Database - the listener will update the cache
      await _database
          .child('users')
          .child(userId)
          .child('orders')
          .child(order.id)
          .set(order.toMap());

      print('Order added to Firebase: ${order.id}');
      
      // Send notification for new order (confirmation)
      await _notificationService.notifyOrderPlaced(order);
      
      return true;
    } catch (e) {
      print('Error adding order: $e');
      return false;
    }
  }

  /// Update order status - triggers immediate notification
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _database
          .child('users')
          .child(userId)
          .child('orders')
          .child(orderId)
          .update({'status': status.displayText.toLowerCase()});

      // Get order details for notification
      final cachedOrders = await _cacheService.getCachedOrders();
      Order? updatedOrder;
      
      if (cachedOrders != null) {
        final orderIndex = cachedOrders.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          updatedOrder = cachedOrders[orderIndex].copyWith(status: status);
          await _cacheService.updateCachedOrder(updatedOrder);
        }
      }

      // Send immediate notification for status update
      if (updatedOrder != null) {
        if (status == OrderStatus.completed) {
          await _notificationService.notifyOrderCompleted(updatedOrder);
        } else if (status == OrderStatus.cancelled) {
          await _notificationService.notifyOrderCancelled(updatedOrder);
        } else {
          await _notificationService.notifyOrderStatusChanged(updatedOrder, updatedOrder.status);
        }
      }

      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  /// Delete an order
  Future<bool> deleteOrder(String orderId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _database
          .child('users')
          .child(userId)
          .child('orders')
          .child(orderId)
          .remove();

      // Remove from cache
      await _cacheService.removeOrderFromCache(orderId);

      return true;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  /// Get specific order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final event = await _database
          .child('users')
          .child(userId)
          .child('orders')
          .child(orderId)
          .once();

      if (event.snapshot.exists && event.snapshot.value != null) {
        final orderData = Map<String, dynamic>.from(event.snapshot.value as Map);
        orderData['id'] = orderId;
        return Order.fromMap(orderData);
      }
      
      return null;
    } catch (e) {
      print('Error getting order $orderId: $e');
      return null;
    }
  }

  /// Check cache staleness to prevent unnecessary Firebase calls
  Future<void> checkCacheStaleness() async {
    try {
      if (_lastCacheUpdate == null) return;
      
      final lastUpdate = DateTime.parse(_lastCacheUpdate!);
      final now = DateTime.now();
      
      if (now.difference(lastUpdate).inMinutes > 5) {
        print('Order cache is stale, will refresh on next request');
        _lastCacheUpdate = null;
      }
    } catch (e) {
      print('Error checking order cache staleness: $e');
    }
  }
}
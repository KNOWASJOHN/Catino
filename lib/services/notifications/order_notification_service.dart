import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cantino/services/log.dart';
import '../../models/order_model.dart';
import '../../models/notification_model.dart';

/// Service specifically for handling order-related notifications
/// Now integrated with Supabase for notification storage
class OrderNotificationService {
  static final OrderNotificationService _instance = OrderNotificationService._internal();
  factory OrderNotificationService() => _instance;
  OrderNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  /// Should be called when the app starts
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          logInfo('Notification tapped: ${details.payload}');
        },
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'cantino_orders',
        'Order Notifications',
        description: 'Notifications for order status updates',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      
      _initialized = true;
      logInfo('Order notification service initialized successfully');
    } catch (e) {
      logError('Error initializing order notification service: $e', e);
    }
  }

  /// Send notification when a new order is placed
  Future<void> notifyOrderPlaced(Order order) async {
    await _createNotification(
      title: 'Order Placed',
      message: 'Order ${order.code} (${order.totalItems} items) has been placed successfully',
      type: 'order',
      data: {
        'orderId': order.id,
        'orderCode': order.code,
        'status': order.status.value,
        'itemCount': order.totalItems,
      },
    );
  }

  /// Send notification when order status changes
  Future<void> notifyOrderStatusChanged(Order order, OrderStatus previousStatus) async {
    String title = 'Order Update';
    String message = 'Order ${order.code}';
    
    switch (order.status) {
      case OrderStatus.completed:
        title = 'Order Complete!';
        message = 'Order ${order.code} is ready for pickup';
        break;
      case OrderStatus.cancelled:
        title = 'Order Cancelled';
        message = 'Order ${order.code} has been cancelled';
        break;
      case OrderStatus.ordered:
        title = 'Order Confirmed';
        message = 'Order ${order.code} has been confirmed';
        break;
      case OrderStatus.pending:
        title = 'Order Pending';
        message = 'Order ${order.code} is being processed';
        break;
    }

    await _createNotification(
      title: title,
      message: message,
      type: 'order',
      data: {
        'orderId': order.id,
        'orderCode': order.code,
        'status': order.status.value,
        'previousStatus': previousStatus.value,
        'itemCount': order.totalItems,
      },
    );
  }

  /// Send notification when order is completed
  Future<void> notifyOrderCompleted(Order order) async {
    await _createNotification(
      title: 'Order Complete!',
      message: 'Order ${order.code} (${order.totalItems} items) is ready for pickup',
      type: 'order',
      data: {
        'orderId': order.id,
        'orderCode': order.code,
        'status': 'completed',
        'itemCount': order.totalItems,
      },
    );
  }

  /// Send notification when order is cancelled
  Future<void> notifyOrderCancelled(Order order) async {
    await _createNotification(
      title: 'Order Cancelled',
      message: 'Order ${order.code} has been cancelled',
      type: 'order',
      data: {
        'orderId': order.id,
        'orderCode': order.code,
        'status': 'cancelled',
        'itemCount': order.totalItems,
      },
    );
  }

  /// Create and store notification in Supabase
  Future<void> _createNotification({
    required String title,
    required String message,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        logWarning('Cannot create notification: User not logged in');
        return;
      }

      final notification = NotificationModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_order',
        title: title,
        message: message,
        type: type,
        userId: userId,
        createdAt: DateTime.now(),
        data: data,
      );

      // Store in Supabase notifications table
      await _supabase.from('notifications').insert({
        'id': notification.id,
        'user_id': notification.userId,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type,
        'created_at_timestamp': notification.createdAt.millisecondsSinceEpoch,
        'is_read': false,
        'data': notification.data,
      });

      logInfo('Notification created in Supabase: $title');

      // Show local notification
      await _showLocalNotification(title, message, notification.id, data);
      
    } catch (e) {
      logError('Error creating notification: $e', e);
    }
  }

  /// Show local push notification
  Future<void> _showLocalNotification(
    String title,
    String message,
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _localNotifications.show(
        notificationId.hashCode,
        title,
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cantino_orders',
            'Order Notifications',
            channelDescription: 'Notifications for order status updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: data['orderId'],
      );
      
      logInfo('Local notification shown: $title');
    } catch (e) {
      logError('Error showing local notification: $e', e);
    }
  }

  /// Show immediate local notification only (for testing)
  Future<void> showLocalOrderNotification({
    required String orderId,
    required String orderCode,
    required String status,
    required String message,
  }) async {
    await _showLocalNotification(
      'Order Update',
      message,
      '${DateTime.now().millisecondsSinceEpoch}',
      {'orderId': orderId, 'orderCode': orderCode, 'status': status},
    );
  }

  /// Test method to show sample order notification
  Future<void> testOrderNotification() async {
    await _createNotification(
      title: 'Test Order Complete!',
      message: 'Order TEST001 is ready for pickup',
      type: 'order',
      data: {
        'orderId': 'test_order_123',
        'orderCode': 'TEST001',
        'status': 'completed',
        'itemCount': 3,
      },
    );
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantino/services/log.dart';
import '../../models/order_model.dart';
import '../../models/notification_model.dart';

/// Service specifically for handling order-related notifications
/// Integrated with OneSignal via Supabase Edge Function
/// When a notification is inserted into Supabase, the Edge Function automatically sends a push via OneSignal
class OrderNotificationService {
  static final OrderNotificationService _instance =
      OrderNotificationService._internal();
  factory OrderNotificationService() => _instance;
  OrderNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send notification when a new order is placed
  Future<void> notifyOrderPlaced(Order order) async {
    await _createNotification(
      title: 'Order Placed',
      message:
          'Order ${order.code} (${order.totalItems} items) has been placed successfully',
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
  Future<void> notifyOrderStatusChanged(
    Order order,
    OrderStatus previousStatus,
  ) async {
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
      message:
          'Order ${order.code} (${order.totalItems} items) is ready for pickup',
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
  /// The Supabase webhook will trigger the Edge Function, which sends the push via OneSignal
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
      // This INSERT triggers the webhook → Edge Function → OneSignal API call
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

      logInfo(
        'Notification created in Supabase (will be sent via OneSignal): $title',
      );
    } catch (e) {
      logError('Error creating notification: $e', e);
    }
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

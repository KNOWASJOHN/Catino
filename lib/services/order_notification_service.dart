import 'fcm_service.dart';
import '../models/order_model.dart';

/// Service specifically for handling order-related notifications
/// This provides a clean interface for order notification operations
class OrderNotificationService {
  static final OrderNotificationService _instance = OrderNotificationService._internal();
  factory OrderNotificationService() => _instance;
  OrderNotificationService._internal();

  final FCMService _fcmService = FCMService();

  /// Initialize the notification service
  /// Should be called when the app starts
  Future<void> initialize() async {
    try {
      await _fcmService.initialize();
      print('Order notification service initialized');
    } catch (e) {
      print('Error initializing order notification service: $e');
    }
  }

  /// Send notification when a new order is placed
  Future<void> notifyOrderPlaced(Order order) async {
    await _fcmService.createOrderNotification(
      orderId: order.id,
      orderCode: order.code,
      status: order.status.displayText,
      itemCount: order.totalItems,
    );
  }

  /// Send notification when order status changes
  Future<void> notifyOrderStatusChanged(Order order, OrderStatus previousStatus) async {
    await _fcmService.createOrderNotification(
      orderId: order.id,
      orderCode: order.code,
      status: order.status.displayText,
      itemCount: order.totalItems,
    );
  }

  /// Send notification when order is completed
  Future<void> notifyOrderCompleted(Order order) async {
    await _fcmService.createOrderNotification(
      orderId: order.id,
      orderCode: order.code,
      status: 'completed',
      itemCount: order.totalItems,
    );
  }

  /// Send notification when order is cancelled
  Future<void> notifyOrderCancelled(Order order) async {
    await _fcmService.createOrderNotification(
      orderId: order.id,
      orderCode: order.code,
      status: 'cancelled',
      itemCount: order.totalItems,
    );
  }

  /// Show immediate local notification only (no Firebase record)
  Future<void> showLocalOrderNotification({
    required String orderId,
    required String orderCode,
    required String status,
    required String message,
  }) async {
    await _fcmService.showOrderNotification(
      orderId: orderId,
      orderCode: orderCode,
      status: status,
      message: message,
    );
  }

  /// Test method to show sample order notification
  Future<void> testOrderNotification() async {
    await showLocalOrderNotification(
      orderId: 'test_order_123',
      orderCode: 'TEST001',
      status: 'completed',
      message: 'Your test order is ready for pickup!',
    );
  }
}
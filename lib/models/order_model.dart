import 'package:flutter/material.dart';

/// Enum for order status - following the same pattern as PrintStatus
enum OrderStatus {
  pending,
  completed,
  cancelled,
  ordered;  // Additional status from migration data

  /// Get string value for database storage
  String get value {
    return name;
  }

  /// Get display text for the status
  String get displayText {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.ordered:
        return 'Ordered';
    }
  }

  /// Get color for the status
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.ordered:
        return Colors.blue;
    }
  }

  /// Get icon for the status
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.ordered:
        return Icons.shopping_bag;
    }
  }

  /// Convert from string
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return OrderStatus.completed;
      case 'pending':
        return OrderStatus.pending;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'ordered':
        return OrderStatus.ordered;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Model class for an order - structured similar to PrintJob
class Order {
  final String id;
  final String code; // Shortened order ID for display
  final List<OrderItem> items;
  final String qrCode;
  final OrderStatus status;
  final DateTime dateTime;

  const Order({
    required this.id,
    required this.code,
    required this.items,
    required this.qrCode,
    required this.status,
    required this.dateTime,
  });

  /// Format date and time for display
  String get formattedDateTime {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get total item count in order
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'items': items.map((item) => item.toMap()).toList(),
      'qrCode': qrCode,
      'status': status.displayText.toLowerCase(),
      'timestamp': dateTime.millisecondsSinceEpoch,
    };
  }

  /// Create from Firebase Map
  factory Order.fromMap(Map<dynamic, dynamic> map) {
    final itemsList = map['items'] as List<dynamic>? ?? [];
    return Order(
      id: map['id'] ?? '',
      code: map['code'] ?? '00',
      items: itemsList.map((item) => OrderItem.fromMap(item as Map<dynamic, dynamic>)).toList(),
      qrCode: map['qrCode'] ?? '',
      status: OrderStatus.fromString(map['status'] ?? 'pending'),
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  /// Create from Supabase Map
  factory Order.fromSupabaseMap(Map<String, dynamic> map) {
    final itemsList = map['items'] as List<dynamic>? ?? [];
    return Order(
      id: map['id'] ?? '',
      code: map['code'] ?? '00',
      items: itemsList.map((item) => OrderItem.fromSupabaseMap(item as Map<String, dynamic>)).toList(),
      qrCode: map['qr_code'] ?? '',
      status: OrderStatus.fromString(map['status'] ?? 'pending'),
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  /// Create a copy with updated status
  Order copyWith({
    String? id,
    String? code,
    List<OrderItem>? items,
    String? qrCode,
    OrderStatus? status,
    DateTime? dateTime,
  }) {
    return Order(
      id: id ?? this.id,
      code: code ?? this.code,
      items: items ?? this.items,
      qrCode: qrCode ?? this.qrCode,
      status: status ?? this.status,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}

/// Model for individual items in an order
class OrderItem {
  final String id;
  final int quantity;

  const OrderItem({
    required this.id,
    required this.quantity,
  });

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qty': quantity,
    };
  }

  /// Create from Firebase Map
  factory OrderItem.fromMap(Map<dynamic, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      quantity: map['qty'] ?? 0,
    );
  }

  /// Create from Supabase Map
  factory OrderItem.fromSupabaseMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      quantity: map['qty'] ?? 0,
    );
  }
}
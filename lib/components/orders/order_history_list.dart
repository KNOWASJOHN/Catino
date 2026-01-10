import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantino/models/order_model.dart';
import 'package:cantino/services/data/order_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:ui';

// Design constants
const _kPrimaryAccent = Color(0xFFCDFF00);
const _kCardRadius = 18.0;
const _kDialogRadius = 24.0;
const _kQrCodeRadius = 16.0;
const _kStatusBadgeRadius = 8.0;
const _kPageSize = 20;
const _kScrollThreshold = 200.0;

/// Displays a scrollable list of user orders with real-time updates.
///
/// Features:
/// - Infinite scroll pagination
/// - Real-time order status updates via Supabase
/// - Swipe-to-delete functionality
/// - QR code display for each order
/// - Order status visualization
class OrderHistoryList extends StatefulWidget {
  const OrderHistoryList({super.key});

  @override
  State<OrderHistoryList> createState() => _OrderHistoryListState();
}

class _OrderHistoryListState extends State<OrderHistoryList> {
  // ========== Services ==========
  final OrderService _orderService = OrderService();
  final _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();

  // ========== State ==========
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  List<Order> _orders = [];
  Set<String> _deletingOrders = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreOrders = true;
  int _currentOffset = 0;

  // ========== Lifecycle Methods ==========

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startOrdersListener();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ========== Scroll Handling ==========

  /// Triggers loading more orders when approaching the bottom of the list
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _kScrollThreshold) {
      if (!_isLoadingMore && _hasMoreOrders) {
        _loadMoreOrders();
      }
    }
  }

  // ========== Data Loading Methods ==========

  /// Loads the initial page of orders
  /// Loads the initial page of orders
  Future<void> _loadOrders() async {
    try {
      _currentOffset = 0;
      final orders = await _orderService.getUserOrders(
        limit: _kPageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
          _orders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          _hasMoreOrders = orders.length == _kPageSize;
          _currentOffset = orders.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Loads the next page of orders for infinite scroll
  /// Loads the next page of orders for infinite scroll
  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreOrders) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreOrders = await _orderService.getUserOrders(
        limit: _kPageSize,
        offset: _currentOffset,
      );

      if (mounted) {
        setState(() {
          _orders.addAll(moreOrders);
          _orders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          _hasMoreOrders = moreOrders.length == _kPageSize;
          _currentOffset += moreOrders.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more orders: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // ========== Real-time Updates ==========

  /// Subscribes to real-time order updates from Supabase
  /// Subscribes to real-time order updates from Supabase
  void _startOrdersListener() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _ordersSubscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen(
          (data) {
            _loadOrders();
          },
          onError: (error) {
            debugPrint('Error in orders listener: $error');
          },
        );
  }

  // ========== Order Management ==========

  /// Deletes an order and provides user feedback
  Future<bool> _deleteOrder(String orderId) async {
    setState(() => _deletingOrders.add(orderId));

    try {
      debugPrint('Attempting to delete order: $orderId');
      final success = await _orderService.deleteOrder(orderId);

      debugPrint('Delete operation result: $success');
      
      if (success && mounted) {
        _showSuccessSnackBar('Order deleted successfully');
        await _loadOrders();
        return true;
      } else {
        if (mounted) {
          _showErrorSnackBar('Failed to delete order');
        }
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting order: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _deletingOrders.remove(orderId));
      }
    }
  }

  // ========== User Interaction Methods ==========

  /// Shows confirmation dialog before deleting an order
  /// Shows confirmation dialog before deleting an order
  Future<void> _showDeleteConfirmDialog(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(orderCode: order.code),
    );

    if (confirmed == true) {
      await _deleteOrder(order.id);
    }
  }

  /// Shows QR code dialog with order details
  void _showQrCodeDialog(Order order) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _QrCodeDialog(order: order),
    );
  }

  // ========== UI Helper Methods ==========

  /// Shows a success message to the user
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shows an error message to the user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== Build Methods ==========

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(_kDialogRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kDialogRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
              children: [
                // Heading
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    'Order History',
                    style: TextStyle(
                      color: Colors.black87,
                      backgroundColor: Colors.transparent,
                      fontFamily: 'Unbounded',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: Stack(
                    children: [
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _orders.isEmpty
                              ? const _EmptyOrdersState()
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                if (index == _orders.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final order = _orders[index];
                                return Dismissible(
                                  key: Key(order.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    await _showDeleteConfirmDialog(order);
                                    return false;
                                  },
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.withOpacity(0.1),
                                          Colors.red.withOpacity(0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(_kCardRadius),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.only(right: 24),
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.red.withOpacity(0.3),
                                            Colors.red.withOpacity(0.5),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  child: _OrderItemCard(
                                    order: order,
                                    isDeleting: _deletingOrders.contains(order.id),
                                    onTap: () => _showQrCodeDialog(order),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}

// ============================================================================
// Private Widget Classes
// ============================================================================

/// Displays an individual order item card with status, details, and QR indicator
class _OrderItemCard extends StatelessWidget {
  final Order order;
  final bool isDeleting;
  final VoidCallback onTap;

  const _OrderItemCard({
    required this.order,
    required this.isDeleting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Opacity(
        opacity: isDeleting ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF5F5F5),
                const Color(0xFFE8E8E8),
              ],
            ),
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(
              color: Colors.black.withOpacity(0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3)
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDeleting ? null : onTap,
              borderRadius: BorderRadius.circular(_kCardRadius),
              splashColor: order.status.color.withOpacity(0.1),
              highlightColor: order.status.color.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _buildStatusIcon(),
                    const SizedBox(width: 18),
                    Expanded(child: _buildOrderDetails()),
                    const SizedBox(width: 8),
                    _buildQrCodeIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            order.status.color.withOpacity(0.3),
            order.status.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.status.color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: order.status.color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        order.status.icon,
        color: order.status.color,
        size: 28,
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '#${order.code}',
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: 'Unbounded',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildStatusBadge(),
        const SizedBox(height: 8),
        Text(
          order.formattedDateTime,
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: 'Unbounded',
            fontSize: 12,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          height: 1,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildItemCount(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: order.status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(_kStatusBadgeRadius),
        border: Border.all(
          color: order.status.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            order.status.icon,
            color: order.status.color,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            order.status.displayText,
            style: TextStyle(
              color: order.status.color,
              fontFamily: 'Unbounded',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCount() {
    return Row(
      children: [
        const Icon(
          Icons.shopping_bag_outlined,
          size: 14,
          color: Colors.black54,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${order.totalItems} item${order.totalItems != 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.black54,
              fontFamily: 'Unbounded',
              fontSize: 12,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: order.status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: order.status.color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: order.status.color.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.qr_code_2_rounded,
            color: order.status.color.withValues(alpha: 0.5),
            size: 28,
          ),
        ),
        if (order.totalItems > 0) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            constraints: const BoxConstraints(minWidth: 24),
            decoration: BoxDecoration(
              color: order.status.color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: order.status.color.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              '${order.totalItems}',
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: 'Unbounded',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty state shown when user has no orders
class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kPrimaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _kPrimaryAccent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 50,
              color: _kPrimaryAccent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Orders Yet',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontFamily: 'Unbounded',
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for confirming order deletion
class _DeleteConfirmDialog extends StatelessWidget {
  final String orderCode;

  const _DeleteConfirmDialog({required this.orderCode});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Delete Order',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Unbounded',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete order #$orderCode? This action cannot be undone.',
        style: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Unbounded',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'Unbounded',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog displaying order QR code and details
class _QrCodeDialog extends StatelessWidget {
  final Order order;

  const _QrCodeDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kDialogRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            const SizedBox(height: 24),
            _buildQrCode(),
            const SizedBox(height: 12),
            _buildStatusBadge(),
            const SizedBox(height: 24),
            _buildDateTime(),
            const SizedBox(height: 28),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Order #${order.code}',
      style: const TextStyle(
        color: Colors.black87,
        fontFamily: 'Unbounded',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildQrCode() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(_kQrCodeRadius),
        boxShadow: [
          BoxShadow(
            color: order.status.color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: QrImageView(
        data: order.qrCode,
        version: QrVersions.auto,
        size: 180.0,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: order.status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: order.status.color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: order.status.color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            order.status.icon,
            color: order.status.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            order.status.displayText,
            style: TextStyle(
              color: order.status.color,
              fontFamily: 'Unbounded',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTime() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black87.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black87.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        order.formattedDateTime,
        style: const TextStyle(
          color: Colors.black87,
          fontFamily: 'Unbounded',
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimaryAccent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 16,
        ),
        elevation: 0,
      ),
      child: const Text(
        'Close',
        style: TextStyle(
          fontFamily: 'Unbounded',
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}


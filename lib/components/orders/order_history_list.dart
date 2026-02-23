import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantino/models/order_model.dart';
import 'package:cantino/services/data/order_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import '../../utils/toast_helper.dart';
import 'dart:async';
import 'dart:ui';
import '../common/skeleton_loader.dart';
import '../../theme/theme.dart';

// Design constants — numeric values kept local; colors/radii come from theme.
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
  Future<void> _loadOrders({bool forceRefresh = false}) async {
    try {
      _currentOffset = 0;
      final orders = await _orderService.getUserOrders(
        limit: _kPageSize,
        offset: 0,
        skipCache: forceRefresh,
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
      // Avoid printing error details which may contain sensitive data
      // Set loading to false so UI can update. Keep error handling internal.
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
      // Avoid printing error details which may contain sensitive data
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
            // Force refresh from network to ensure we get the latest data
            // Cache might be stale or in race condition with other listeners
            _loadOrders(forceRefresh: true);
          },
          onError: (error) {
            // Dev-only: orders listener error; avoid console prints of payloads
          },
        );
  }

  // ========== Order Management ==========

  /// Deletes an order and provides user feedback
  Future<bool> _deleteOrder(String orderId) async {
    setState(() => _deletingOrders.add(orderId));

    try {
      // Dev-only: attempting to delete order (do not log full order IDs in production)
      final success = await _orderService.deleteOrder(orderId);

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
    } catch (e) {
      // Log internally in development if needed; avoid exposing exception text to UI
      if (mounted) {
        _showErrorSnackBar('An error occurred while deleting the order');
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppColors.barrierMedium,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => _QrCodeDialog(order: order),
    );
  }

  // ========== UI Helper Methods ==========

  /// Shows a success message to the user
  void _showSuccessSnackBar(String message) {
    AppToast.show(context, message);
  }

  /// Shows an error message to the user
  void _showErrorSnackBar(String message) {
    AppToast.show(context, message, isError: true);
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.dialog,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        child: Column(
          children: [
            // Simple header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text('Order History', style: AppTextStyles.panelTitle),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Stack(
                children: [
                  _isLoading
                      ? const SkeletonList(
                          itemCount: 8,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        )
                      : _orders.isEmpty
                      ? const _EmptyOrdersState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          physics: const ClampingScrollPhysics(),
                          itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _orders.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
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
                                      AppColors.danger.withOpacity(0.2),
                                      AppColors.danger.withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xl,
                                  ),
                                  border: Border.all(
                                    color: AppColors.danger.withOpacity(0.7),
                                    width: 2,
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
                                        AppColors.danger.withOpacity(0.4),
                                        AppColors.danger.withOpacity(0.6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.danger,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      AppShadows.accentGlow(AppColors.danger),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.borderHighlight, width: 1),
            boxShadow: AppShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDeleting ? null : onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              splashColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.white.withOpacity(0.02),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildStatusIcon(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildOrderDetails()),
                    const SizedBox(width: 12),
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: order.status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: order.status.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Icon(order.status.icon, color: order.status.color, size: 26),
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '#${order.code}',
          style: AppTextStyles.orderCode,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildStatusBadge(),
        const SizedBox(height: 8),
        Text(
          order.formattedDateTime,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'Unbounded',
            fontSize: 12,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(height: 1, width: 50, color: AppColors.borderHighlight),
        const SizedBox(height: 6),
        _buildItemCount(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: order.status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: order.status.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(order.status.icon, color: order.status.color, size: 12),
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
        Icon(
          Icons.shopping_bag_outlined,
          size: 14,
          color: Colors.white.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${order.totalItems} item${order.totalItems != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                color: Colors.white,
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
              color: AppColors.primaryBright.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primaryBright.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 50,
              color: AppColors.primaryBright,
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
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      title: const Text(
        'Delete Order',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Unbounded',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete order #$orderCode? This action cannot be undone.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontFamily: 'Unbounded',
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Unbounded',
              fontSize: 14,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deleteConfirmButton,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
          child: const Text(
            'Delete',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 14,
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
    final paymentId = order.paymentId ?? '';
    final orderId = order.orderId ?? '';
    final hasPaymentIds = paymentId.isNotEmpty || orderId.isNotEmpty;
    final qrData = order.qrCode.isNotEmpty ? order.qrCode : order.id;

    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.dialogGradientStart,
                    AppColors.dialogGradientMid,
                    AppColors.dialogGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 80,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.03),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset('assets/logo/Catino.png', height: 26),
                            const Spacer(),
                            _buildStatusChip(order.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${order.code}',
                                  style: const TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${order.totalItems} item${order.totalItems != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.65),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (hasPaymentIds) ...[
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (paymentId.isNotEmpty)
                                          _buildCardCopyField(
                                            'PAY ID',
                                            paymentId,
                                            context,
                                          ),
                                        if (paymentId.isNotEmpty &&
                                            orderId.isNotEmpty)
                                          const SizedBox(height: 8),
                                        if (orderId.isNotEmpty)
                                          _buildCardCopyField(
                                            'ORDER ID',
                                            orderId,
                                            context,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 0.6,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'DATE',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 7,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  order.formattedDateTime,
                                  style: const TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'ITEMS',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 7,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${order.totalItems}',
                                  style: const TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'AMOUNT',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 7,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '₹${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 0.6,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  color: Colors.white,
                                  child: QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 100,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildCardPaymentBadge(
                                order.paymentStatus ?? 'pending',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 0.6,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCardButton(
                                label: 'Close',
                                icon: Icons.close_rounded,
                                solid: false,
                                onTap: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardCopyField(String label, String value, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 9,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        GestureDetector(
          // ...existing code...
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));

            final fToast = FToast()..init(context);
            fToast.showToast(
              toastDuration: const Duration(seconds: 1),
              gravity: ToastGravity.BOTTOM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  '$label copied',
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
          // ...existing code...
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.copy_rounded,
              size: 12,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPaymentBadge(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'paid':
        color = AppColors.statusSuccess;
        label = 'PAID';
        icon = Icons.check_circle_rounded;
        break;
      case 'failed':
        color = AppColors.statusError;
        label = 'FAILED';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColors.statusWarning;
        label = 'PENDING';
        icon = Icons.schedule_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            'PAYMENT',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 7,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton({
    required String label,
    required IconData icon,
    required bool solid,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: solid ? Colors.white.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    final chipColor = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.6), width: 1),
      ),
      child: Text(
        status.displayText,
        style: TextStyle(
          fontFamily: 'Unbounded',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}

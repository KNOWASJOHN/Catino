import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../utils/toast_helper.dart';
import 'package:provider/provider.dart';
import '../components/common/skeleton_loader.dart';
import '../providers/cart_provider.dart';
import '../services/data/supabase_food_service.dart';
import '../services/payment/payment_service.dart';
import '../models/food_item.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}

class _CartState extends State<Cart> {
  final SupabaseFoodService _foodService = SupabaseFoodService();
  late final Future<List<FoodItem>> _foodFuture;

  @override
  void initState() {
    super.initState();
    _foodFuture = _foodService.getAllFoodItems();
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    final muted = Colors.grey.shade500;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor ?? muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: muted,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cart = cartProvider.cart;
          return cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 38,
                          color: AppColors.primary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Cart is Empty',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Browse meals and add them to your cart.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<List<FoodItem>>(
                  future: _foodFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(12, 100, 12, 0),
                        child: SkeletonList(
                          itemCount: 4,
                          padding: EdgeInsets.zero,
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text(
                          'Error loading items',
                          style: TextStyle(fontFamily: 'Unbounded'),
                        ),
                      );
                    }
                    final foodItems = snapshot.data!;
                    final cartItems = cart.entries.map((e) {
                      final item = foodItems.firstWhere(
                        (i) => i.id == e.key,
                        orElse: () => foodItems.first,
                      );
                      return {'item': item, 'qty': e.value};
                    }).toList();

                    // Place the list below the app header by adding top padding
                    double subtotal = cartItems.fold(
                      0,
                      (sum, entry) =>
                          sum +
                          (entry['item'] as FoodItem).price *
                              (entry['qty'] as int),
                    );
                    const double deliveryFee = 25.0;
                    double discount = subtotal > 499 ? 50 : 0;
                    double total = subtotal + deliveryFee - discount;

                    return SafeArea(
                      top: false,
                      bottom: false,
                      child: Stack(
                        children: [
                          // Cart items list
                          ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              100,
                              12,
                              200,
                            ),
                            itemCount: cartItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = cartItems[index];
                              final item = entry['item'] as FoodItem;
                              final qty = entry['qty'] as int;

                              return Dismissible(
                                key: Key(item.id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                  ),
                                  child: Icon(
                                    Icons.delete_sweep_outlined,
                                    size: 26,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  cartProvider.removeItem(item.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        child: Image.network(
                                          item.imageUrl,
                                          width: 88,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 88,
                                            height: 80,
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.fastfood_outlined,
                                              color: Colors.grey.shade400,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontFamily: 'Unbounded',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${item.price.toStringAsFixed(0)} each',
                                              style: TextStyle(
                                                fontFamily: 'Unbounded',
                                                fontSize: 9,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    _QtyButton(
                                                      icon: Icons.remove,
                                                      onTap: () {
                                                        if (qty > 1) {
                                                          cartProvider.updateQuantity(item.id, qty - 1);
                                                        } else {
                                                          cartProvider.removeItem(item.id);
                                                        }
                                                      },
                                                    ),
                                                    AnimatedSwitcher(
                                                      duration: const Duration(milliseconds: 220),
                                                      transitionBuilder: (child, anim) =>
                                                          ScaleTransition(scale: anim, child: child),
                                                      child: Padding(
                                                        key: ValueKey<int>(qty),
                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                        child: Text(
                                                          '$qty',
                                                          style: const TextStyle(
                                                            fontFamily: 'Unbounded',
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w700,
                                                            color: Color(0xFF1A1A1A),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    _QtyButton(
                                                      icon: Icons.add,
                                                      onTap: () => cartProvider.addItem(item.id),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '₹${(item.price * qty).toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Unbounded',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
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
                              );
                            },
                          ),

                          // Draggable checkout card
                          DraggableScrollableSheet(
                            initialChildSize: 0.25,
                            minChildSize: 0.25,
                            maxChildSize: 0.65,
                            snap: false,
                            builder: (context, scrollController) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(AppRadius.xxxl),
                                    topRight: Radius.circular(AppRadius.xxxl),
                                  ),
                                ),
                                child: ListView(
                                  controller: scrollController,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    // Drag handle
                                    Center(
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        8,
                                        20,
                                        24,
                                      ),
                                      child: Column(
                                        children: [
                                          // Order Summary Section
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(AppRadius.lg),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                _summaryRow(
                                                  icon: Icons.receipt_long_rounded,
                                                  label: 'Subtotal',
                                                  value: '₹${subtotal.toStringAsFixed(0)}',
                                                ),
                                                const SizedBox(height: 10),
                                                _summaryRow(
                                                  icon: Icons.delivery_dining_rounded,
                                                  label: 'Delivery',
                                                  value: '₹${deliveryFee.toStringAsFixed(0)}',
                                                ),
                                                if (discount > 0) ...[
                                                  const SizedBox(height: 10),
                                                  _summaryRow(
                                                    icon: Icons.local_offer_rounded,
                                                    label: 'Discount',
                                                    value: '-₹${discount.toStringAsFixed(0)}',
                                                    valueColor: Colors.green.shade600,
                                                    iconColor: Colors.green.shade600,
                                                  ),
                                                ],
                                                const SizedBox(height: 14),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                                    border: Border.all(
                                                      color: Colors.grey.shade200,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 18),
                                                          const SizedBox(width: 8),
                                                          const Text(
                                                            'Total',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w700,
                                                              fontFamily: 'Unbounded',
                                                              color: Color(0xFF1A1A1A),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        '₹${total.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w800,
                                                          fontFamily: 'Unbounded',
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          // Checkout Button
                                          GestureDetector(
                                            onTap: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (context) => Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: const BorderRadius.vertical(
                                                          top: Radius.circular(AppRadius.xxxl),
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.fromLTRB(
                                                        24, 24, 24,
                                                        MediaQuery.of(context).viewInsets.bottom + 24,
                                                      ),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 36,
                                                                height: 36,
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.primary.withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                                                ),
                                                                child: const Icon(
                                                                  Icons.check_circle_outline_rounded,
                                                                  color: AppColors.primary,
                                                                  size: 20,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              const Text(
                                                                'Confirm Order',
                                                                style: TextStyle(
                                                                  fontFamily: 'Unbounded',
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: Color(0xFF1A1A1A),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 16),
                                                          Container(
                                                            padding: const EdgeInsets.all(16),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade50,
                                                              borderRadius: BorderRadius.circular(AppRadius.md),
                                                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Total to pay:',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontFamily: 'Unbounded',
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.grey.shade500,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '₹${total.toStringAsFixed(0)}',
                                                                  style: const TextStyle(
                                                                    fontSize: 20,
                                                                    fontFamily: 'Unbounded',
                                                                    fontWeight: FontWeight.w800,
                                                                    color: AppColors.primary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 20),
                                                          SizedBox(
                                                            width: double.infinity,
                                                            height: 52,
                                                            child: ElevatedButton.icon(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: AppColors.primary,
                                                                foregroundColor: Colors.white,
                                                                elevation: 0,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                                                ),
                                                              ),
                                                              icon: const Icon(Icons.payment_rounded, size: 18),
                                                              onPressed: () async {
                                                                // Start Razorpay payment
                                                                final paymentService =
                                                                    PaymentService();
                                                                final result = await paymentService
                                                                    .startPayment(
                                                                      amount:
                                                                          total,
                                                                      description:
                                                                          'Catino Food Order',
                                                                    );

                                                                if (result
                                                                    .isSuccess) {
                                                                  // Payment successful - place order
                                                                  try {
                                                                    await cartProvider
                                                                        .placeOrder(
                                                                          cartItems,
                                                                          paymentResult:
                                                                              result,
                                                                        );
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop();
                                                                    AppToast.show(
                                                                      context,
                                                                      'Payment successful! Order placed.',
                                                                    );
                                                                  } catch (_) {
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop();
                                                                    AppToast.show(
                                                                      context,
                                                                      'Payment successful, but order could not be saved. Please contact support.',
                                                                      isError:
                                                                          true,
                                                                    );
                                                                  }
                                                                } else {
                                                                  // Payment failed or cancelled
                                                                  final isCancelled =
                                                                      result
                                                                          .isCancelled;
                                                                  AppToast.show(
                                                                    context,
                                                                    isCancelled
                                                                        ? 'Payment Cancelled'
                                                                        : (result.errorMessage ??
                                                                              'Payment failed'),
                                                                    isError:
                                                                        !isCancelled,
                                                                    isWarning:
                                                                        isCancelled,
                                                                  );
                                                                }
                                                              },
                                                              label: const Text(
                                                                'Pay Bill',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Unbounded',
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          SizedBox(
                                                            width: double.infinity,
                                                            height: 48,
                                                            child: OutlinedButton(
                                                              style: OutlinedButton.styleFrom(
                                                                foregroundColor: Colors.grey.shade600,
                                                                side: BorderSide(
                                                                  color: Colors.grey.shade300,
                                                                  width: 1.5,
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                                                ),
                                                              ),
                                                              onPressed: () => Navigator.of(context).pop(),
                                                              child: const Text(
                                                                'Cancel',
                                                                style: TextStyle(
                                                                  fontFamily: 'Unbounded',
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppColors.primary, AppColors.primaryLight],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                                boxShadow: [AppShadows.accentGlow(AppColors.primary)],
                                              ),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.shopping_cart_checkout_rounded, size: 20, color: Colors.white),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Checkout',
                                                    style: TextStyle(
                                                      fontFamily: 'Unbounded',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}

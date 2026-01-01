import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/food.dart';  // For FoodItem and FoodService
import 'cart_provider.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}

class _CartState extends State<Cart> {
  final FoodService _foodService = FoodService();
  late final Stream<List<FoodItem>> _foodStream;

  @override
  void initState() {
    super.initState();
    _foodStream = _foodService.getFoodItems();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cart = cartProvider.cart;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 84,
                    color: Colors.lime.shade600,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Cart is Empty',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Browse delicious meals and add them to your cart.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<FoodItem>>(
              stream: _foodStream,  // Use the cached stream instead
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Error loading items', style: TextStyle(fontFamily: 'Unbounded')));
                }
                final foodItems = snapshot.data!;
                final cartItems = cart.entries.map((e) {
                  final item = foodItems.firstWhere((i) => i.id == e.key);
                  return {'item': item, 'qty': e.value};
                }).toList();

                double subtotal = cartItems.fold(0, (sum, entry) => sum + (entry['item'] as FoodItem).price * (entry['qty'] as int));
                const double deliveryFee = 25.0;
                double discount = subtotal > 499 ? 50 : 0;
                double total = subtotal + deliveryFee - discount;

                return SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          itemCount: cartItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                                decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              onDismissed: (_) => cartProvider.removeItem(item.id),
                              child: Material(
                                color: Colors.white,
                                elevation: 1,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(item.imageUrl, width: 84, height: 84, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.name, style: const TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 6),
                                            Text('₹${item.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 8),
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
                                                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                                      child: Padding(
                                                        key: ValueKey<int>(qty),
                                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                                        child: Text('$qty', style: const TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w600)),
                                                      ),
                                                    ),
                                                    _QtyButton(
                                                      icon: Icons.add,
                                                      onTap: () => cartProvider.addItem(item.id),
                                                    ),
                                                  ],
                                                ),
                                                Text('₹${(item.price * qty).toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)], borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                                child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Subtotal', style: TextStyle(fontFamily: 'Unbounded', color: Colors.grey.shade700)),
                                                Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Delivery', style: TextStyle(fontFamily: 'Unbounded', color: Colors.grey.shade700)),
                                Text('₹${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (discount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Discount', style: TextStyle(fontFamily: 'Unbounded', color: Colors.green.shade700)),
                                  Text('-₹${discount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', color: Colors.green, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Unbounded')),
                                Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Unbounded')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lime.shade300,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                                    builder: (context) => Padding(
                                      padding: MediaQuery.of(context).viewInsets,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Confirm Order', style: TextStyle(fontFamily: 'Unbounded', fontSize: 18, fontWeight: FontWeight.w800)),
                                            const SizedBox(height: 12),
                                            Text('Total to pay: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontFamily: 'Unbounded')),
                                            const SizedBox(height: 14),
                                            Column(
                                              children: [
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 52,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.lime.shade300,
                                                      foregroundColor: Colors.black87,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    onPressed: () async {
                                                      await cartProvider.placeOrder(cartItems);
                                                      Navigator.of(context).pop();
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed!', style: TextStyle(fontFamily: 'Unbounded'))));
                                                    },
                                                    child: const Text('Pay & Place Order', style: TextStyle(fontFamily: 'Unbounded')),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 52,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.grey.shade300,
                                                      foregroundColor: Colors.black87,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: const Text('Cancel', style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w300)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Checkout', style: TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w700)),
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
    );
  }
}

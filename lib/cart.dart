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
        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.white),
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

                // Place the list below the app header by adding top padding
                double subtotal = cartItems.fold(0, (sum, entry) => sum + (entry['item'] as FoodItem).price * (entry['qty'] as int));
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
                        padding: const EdgeInsets.fromLTRB(12, 100, 12, 200),
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
                            child: Card(
                              color: Colors.black87,
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(item.imageUrl, width: 95, height: 85, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name, style: const TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                          const SizedBox(height: 6),
                                          Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.limeAccent, fontWeight: FontWeight.w600, fontFamily: 'Unbounded')),
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
                                                        child: Text('$qty', style: const TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                                      ),
                                                  ),
                                                  _QtyButton(
                                                    icon: Icons.add,
                                                    onTap: () => cartProvider.addItem(item.id),
                                                  ),
                                                ],
                                              ),
                                                Text('₹${(item.price * qty).toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w700, color: Colors.white)),
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

                      // Draggable checkout card with ribbon effect
                      DraggableScrollableSheet(
                        initialChildSize: 0.25,
                        minChildSize: 0.25,
                        maxChildSize: 0.65,
                        snap: false,
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.lime.shade50,
                                  Colors.white,
                                  Colors.lime.shade50,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: ListView(
                              controller: scrollController,
                              padding: EdgeInsets.zero,
                              children: [
                                // Drag handle indicator
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                                    width: 50,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                  child: Column(
                                    children: [
                                      // Order Summary Section
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.lime.shade100, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.lime.withOpacity(0.1),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.receipt_long, size: 18, color: Colors.grey.shade700),
                                                    const SizedBox(width: 8),
                                                    Text('Subtotal', style: TextStyle(fontFamily: 'Unbounded', fontSize: 13, color: Colors.grey.shade700)),
                                                  ],
                                                ),
                                                Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', fontSize: 14, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.delivery_dining, size: 18, color: Colors.grey.shade700),
                                                    const SizedBox(width: 8),
                                                    Text('Delivery', style: TextStyle(fontFamily: 'Unbounded', fontSize: 13, color: Colors.grey.shade700)),
                                                  ],
                                                ),
                                                Text('₹${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', fontSize: 14, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                            if (discount > 0) ...[
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.local_offer, size: 18, color: Colors.green.shade700),
                                                      const SizedBox(width: 8),
                                                      Text('Discount', style: TextStyle(fontFamily: 'Unbounded', fontSize: 13, color: Colors.green.shade700)),
                                                    ],
                                                  ),
                                                  Text('-₹${discount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Unbounded', fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Colors.lime.shade100, Colors.lime.shade50],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.shopping_bag, color: Colors.lime.shade900),
                                                      const SizedBox(width: 8),
                                                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Unbounded')),
                                                    ],
                                                  ),
                                                  Text('₹${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Unbounded', color: Colors.lime.shade900)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Checkout Button
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.lime.withOpacity(0.4),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.lime.shade400,
                                              foregroundColor: Colors.black87,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.transparent,
                                                builder: (context) => Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [Colors.lime.shade50, Colors.white],
                                                    ),
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                                  ),
                                                  padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.check_circle, color: Colors.lime.shade700, size: 32),
                                                          const SizedBox(width: 12),
                                                          const Text('Confirm Order', style: TextStyle(fontFamily: 'Unbounded', fontSize: 20, fontWeight: FontWeight.w800)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Container(
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: Colors.lime.shade200),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            const Text('Total to pay:', style: TextStyle(fontSize: 16, fontFamily: 'Unbounded', fontWeight: FontWeight.w600)),
                                                            Text('₹${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontFamily: 'Unbounded', fontWeight: FontWeight.w900, color: Colors.lime.shade900)),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 20),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        height: 56,
                                                        child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.lime.shade400,
                                                            foregroundColor: Colors.black87,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          ),
                                                          icon: const Icon(Icons.payment),
                                                          onPressed: () async {
                                                            await cartProvider.placeOrder(cartItems);
                                                            Navigator.of(context).pop();
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: const Text('Order placed successfully!', style: TextStyle(fontFamily: 'Unbounded')),
                                                                backgroundColor: Colors.green.shade600,
                                                              ),
                                                            );
                                                          },
                                                          label: const Text('Pay & Place Order', style: TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w700)),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        height: 56,
                                                        child: OutlinedButton(
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: Colors.black87,
                                                            side: BorderSide(color: Colors.grey.shade300, width: 2),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          ),
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: const Text('Cancel', style: TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w600)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.shopping_cart_checkout, size: 24),
                                                const SizedBox(width: 10),
                                                const Text('Checkout', style: TextStyle(fontFamily: 'Unbounded', fontSize: 17, fontWeight: FontWeight.w800)),
                                              ],
                                            ),
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
            ),
    );
  }
}

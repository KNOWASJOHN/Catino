import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/food.dart';  // For FoodItem and FoodService
import 'cart_provider.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final FoodService _foodService = FoodService();

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cart = cartProvider.cart;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 2,
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_checkout_outlined,
                    size: 80,
                    color: Colors.lime.shade500,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cart is Empty',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add some items to your cart',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<FoodItem>>(
              stream: _foodService.getFoodItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Error loading items'));
                }
                final foodItems = snapshot.data!;
                final cartItems = cart.entries.map((e) {
                  final item = foodItems.firstWhere((i) => i.id == e.key);
                  return {'item': item, 'qty': e.value};
                }).toList();

                double total = cartItems.fold(0, (sum, entry) => sum + (entry['item'] as FoodItem).price * (entry['qty'] as int));

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final entry = cartItems[index];
                          final item = entry['item'] as FoodItem;
                          final qty = entry['qty'] as int;
                          return ListTile(
                            leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(item.name, style: const TextStyle(fontFamily: 'Unbounded')),
                            subtitle: Text('₹${item.price.toStringAsFixed(2)} x $qty = ₹${(item.price * qty).toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: qty > 1 ? () => cartProvider.updateQuantity(item.id, qty - 1) : () => cartProvider.removeItem(item.id),
                                ),
                                Text('$qty'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => cartProvider.addItem(item.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Unbounded')),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement order placement
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed!')));
                            },
                            child: const Text('Place Order'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

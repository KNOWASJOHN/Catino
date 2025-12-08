import 'package:flutter/material.dart';

class Cart extends StatelessWidget {
  const Cart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_checkout_outlined,
              size: 80,
              color: Colors.lime.shade500,
            ),
            SizedBox(height: 20),
            Text(
              'Cart',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Shopping Cart',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

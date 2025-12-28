import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:firebase_database/firebase_database.dart';
import 'package:cantino/components/usercard.dart';
import 'package:cantino/page_components/foodsection.dart';
import 'package:cantino/components/scroll_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    // Get the current user's UID
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<Map<String, dynamic>> fetchUserAndOrder() async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final db = FirebaseDatabase.instance.ref();

    // Fetch user data
    final userSnap = await db.child('users/$userId').get();
    if (!userSnap.exists) {
      debugPrint('No user data found');
      return {'userName': 'User', 'orderCode': 'N/A'};
    }
    final userData = Map<String, dynamic>.from(userSnap.value as Map);

    // Fetch orders
    final ordersSnap = await db.child('orders/$userId').get();
    if (!ordersSnap.exists) {
      debugPrint('No orders found');
      return {'userName': userData['name'] ?? 'User', 'orderCode': 'N/A'};
    }
    final orders = Map<String, dynamic>.from(ordersSnap.value as Map);

    if (orders.isEmpty) {
      debugPrint('Orders are empty');
      return {'userName': userData['name'] ?? 'User', 'orderCode': 'N/A'};
    }

    // Get the latest order
    final latestOrder = orders.entries.first.value;
    return {
      'userName': userData['name'] ?? 'User',
      'orderCode': latestOrder['code'] ?? 'N/A',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserAndOrder(),
        builder: (context, snapshot) {
          Widget userCardWidget;
          if (snapshot.connectionState == ConnectionState.waiting) {
            userCardWidget = const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData) {
            userCardWidget = const UserCard(userName: 'User', orderCode: 'N/A');
          } else {
            final userName = snapshot.data!['userName'];
            final orderCode = snapshot.data!['orderCode'];
            userCardWidget = UserCard(userName: userName, orderCode: orderCode);
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  userCardWidget,
                  const SizedBox(height: 20),
                  const FoodSection(),
                  const SizedBox(height: 20),
                  const Scrollcard(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

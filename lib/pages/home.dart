import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserId();
    });
  }

  void _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    } else {
      debugPrint('No user logged in');
    }
  }

  // Helper method to safely convert dynamic items to List<Map<String, dynamic>>
  List<Map<String, dynamic>> _convertItemsToList(dynamic itemsData) {
    if (itemsData == null) return [];
    
    if (itemsData is List) {
      return itemsData.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    }
    
    return [];
  }

  Future<Map<String, dynamic>> fetchUserAndOrder() async {
    if (userId == null) {
      debugPrint('User ID is null');
      return {
        'userName': 'User',
        'orderCode': 'N/A',
        'items': [],
        'status': 'N/A',
        'timestamp': 0,
      };
    }

    debugPrint('Fetching data for user: $userId');
    final db = FirebaseDatabase.instance.ref();

    try {
      // 1. Fetch user data
      final userSnap = await db.child('users/$userId').get();
      if (!userSnap.exists) {
        debugPrint('No user data found for $userId');
        return {
          'userName': 'User',
          'orderCode': 'N/A',
          'items': [],
          'status': 'N/A',
          'timestamp': 0,
        };
      }
      
      final userData = Map<String, dynamic>.from(userSnap.value as Map);
      debugPrint('User data: ${userData['name']}');

      // 2. Fetch orders
      final ordersSnap = await db.child('orders/$userId').get();
      
      if (!ordersSnap.exists || ordersSnap.value == null) {
        debugPrint('No orders found for $userId');
        return {
          'userName': userData['name'] ?? 'User',
          'orderCode': 'N/A',
          'items': [],
          'status': 'N/A',
          'timestamp': 0,
        };
      }

      final orders = Map<String, dynamic>.from(ordersSnap.value as Map);
      
      if (orders.isEmpty) {
        debugPrint('Orders map is empty');
        return {
          'userName': userData['name'] ?? 'User',
          'orderCode': 'N/A',
          'items': [],
          'status': 'N/A',
          'timestamp': 0,
        };
      }

      // Find the latest order by timestamp
      Map<String, dynamic>? latestOrder;
      int latestTimestamp = 0;
      
      orders.forEach((orderId, orderData) {
        if (orderData is Map) {
          final order = Map<String, dynamic>.from(orderData);
          final timestamp = order['timestamp'] is int ? order['timestamp'] as int : 0;
          debugPrint('Order $orderId: timestamp=$timestamp, status=${order['status']}');
          
          if (timestamp > latestTimestamp) {
            latestTimestamp = timestamp;
            latestOrder = order;
          }
        }
      });

      if (latestOrder == null) {
        debugPrint('No valid orders found in map');
        return {
          'userName': userData['name'] ?? 'User',
          'orderCode': 'N/A',
          'items': [],
          'status': 'N/A',
          'timestamp': 0,
        };
      }

      debugPrint('Latest order: ${latestOrder!['code']}');
      
      // SAFELY convert items to List<Map<String, dynamic>>
      final itemsList = _convertItemsToList(latestOrder!['items']);
      debugPrint('Converted items count: ${itemsList.length}');
      
      return {
        'userName': userData['name'] ?? 'User',
        'orderCode': latestOrder!['code']?.toString() ?? 'N/A',
        'items': itemsList,
        'status': latestOrder!['status']?.toString() ?? 'N/A',
        'timestamp': latestOrder!['timestamp'] is int ? latestOrder!['timestamp'] as int : 0,
      };
    } catch (e) {
      debugPrint('Error fetching data: $e');
      return {
        'userName': 'User',
        'orderCode': 'N/A',
        'items': [],
        'status': 'N/A',
        'timestamp': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserAndOrder(),
        builder: (context, snapshot) {
          // Add error handling
          if (snapshot.hasError) {
            debugPrint('FutureBuilder Error: ${snapshot.error}');
            debugPrint('Stack trace: ${snapshot.stackTrace}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          Widget userCardWidget;
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            userCardWidget = const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data == null) {
            userCardWidget = const UserCard(
              userName: 'User',
              orderCode: 'N/A',
              items: [],
              status: 'N/A',
              timestamp: 0,
            );
          } else {
            final data = snapshot.data!;
            debugPrint('Displaying data: ${data['userName']}, order: ${data['orderCode']}');
            debugPrint('Items type: ${data['items'].runtimeType}');
            debugPrint('Items: ${data['items']}');
            
            userCardWidget = UserCard(
              userName: data['userName']?.toString() ?? 'User',
              orderCode: data['orderCode']?.toString() ?? 'N/A',
              items: data['items'] is List<Map<String, dynamic>> 
                  ? data['items'] as List<Map<String, dynamic>>
                  : [],
              status: data['status']?.toString() ?? 'N/A',
              timestamp: data['timestamp'] is int ? data['timestamp'] as int : 0,
            );
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
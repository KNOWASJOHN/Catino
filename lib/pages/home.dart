import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cantino/components/usercard.dart';
import 'package:cantino/page_components/foodsection.dart';
import 'package:cantino/components/scroll_card.dart';
import 'package:cantino/services/usercard_cache_service.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserCardCacheService _cacheService = UserCardCacheService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  StreamSubscription? _userSubscription;
  StreamSubscription? _ordersSubscription;
  
  Map<String, dynamic>? _userCardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedDataAndStartListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedDataAndStartListeners() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _userCardData = _getDefaultData();
      });
      return;
    }

    // Load cached data immediately
    final cachedData = await _cacheService.getUserCardData();
    if (cachedData != null) {
      setState(() {
        _userCardData = cachedData;
        _isLoading = false;
      });
    }

    // Start real-time listeners
    _startFirebaseListeners(user.uid);
  }

  void _startFirebaseListeners(String userId) {
    // Listen to user data changes
    _userSubscription = _database.child('users/$userId').onValue.listen((event) {
      if (event.snapshot.exists) {
        _updateUserCardData(userId);
      }
    });

    // Listen to orders changes
    _ordersSubscription = _database.child('users/$userId/orders').onValue.listen((event) {
      _updateUserCardData(userId);
    });

    // Initial fetch if no cache
    if (_userCardData == null) {
      _updateUserCardData(userId);
    }
  }

  Future<void> _updateUserCardData(String userId) async {
    try {
      // Fetch user data
      final userSnap = await _database.child('users/$userId').get();
      if (!userSnap.exists) {
        final defaultData = _getDefaultData();
        await _cacheService.saveUserCardData(defaultData);
        setState(() {
          _userCardData = defaultData;
          _isLoading = false;
        });
        return;
      }

      final userData = Map<String, dynamic>.from(userSnap.value as Map);

      // Fetch orders
      final ordersSnap = await _database.child('users/$userId/orders').get();
      
      Map<String, dynamic> userCardData;
      
      if (!ordersSnap.exists || ordersSnap.value == null) {
        userCardData = {
          'userName': userData['name'] ?? 'User',
          'orderCode': 'N/A',
          'items': [],
          'status': 'N/A',
          'timestamp': 0,
        };
      } else {
        final orders = Map<String, dynamic>.from(ordersSnap.value as Map);
        
        if (orders.isEmpty) {
          userCardData = {
            'userName': userData['name'] ?? 'User',
            'orderCode': 'N/A',
            'items': [],
            'status': 'N/A',
            'timestamp': 0,
          };
        } else {
          // Find the latest order by timestamp
          Map<String, dynamic>? latestOrder;
          int latestTimestamp = 0;
          
          orders.forEach((orderId, orderData) {
            if (orderData is Map) {
              final order = Map<String, dynamic>.from(orderData);
              final timestamp = order['timestamp'] is int ? order['timestamp'] as int : 0;
              
              if (timestamp > latestTimestamp) {
                latestTimestamp = timestamp;
                latestOrder = order;
              }
            }
          });

          if (latestOrder != null) {
            final itemsList = _convertItemsToList(latestOrder!['items']);
            
            userCardData = {
              'userName': userData['name'] ?? 'User',
              'orderCode': latestOrder!['code']?.toString() ?? 'N/A',
              'items': itemsList,
              'status': latestOrder!['status']?.toString() ?? 'N/A',
              'timestamp': latestOrder!['timestamp'] is int ? latestOrder!['timestamp'] as int : 0,
            };
          } else {
            userCardData = {
              'userName': userData['name'] ?? 'User',
              'orderCode': 'N/A',
              'items': [],
              'status': 'N/A',
              'timestamp': 0,
            };
          }
        }
      }

      // Save to cache and update UI
      await _cacheService.saveUserCardData(userCardData);
      setState(() {
        _userCardData = userCardData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error updating UserCard data: $e');
      // On error, keep displaying cached data if available
      if (_userCardData == null) {
        setState(() {
          _userCardData = _getDefaultData();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getDefaultData() {
    return {
      'userName': 'User',
      'orderCode': 'N/A',
      'items': [],
      'status': 'N/A',
      'timestamp': 0,
    };
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



  @override
  Widget build(BuildContext context) {
    Widget userCardWidget;

    if (_isLoading && _userCardData == null) {
      userCardWidget = const Center(child: CircularProgressIndicator());
    } else if (_userCardData == null) {
      userCardWidget = const UserCard(
        userName: 'User',
        orderCode: 'N/A',
        items: [],
        status: 'N/A',
        timestamp: 0,
      );
    } else {
      final data = _userCardData!;
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

    return Scaffold(
      body: SingleChildScrollView(
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
      ),
    );
  }
}
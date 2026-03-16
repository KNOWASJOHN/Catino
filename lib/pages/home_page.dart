import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantino/components/home/usercard.dart';
import 'package:cantino/components/food/food_section.dart';
import 'package:cantino/components/home/scroll_card.dart';
import 'package:cantino/components/orders/order_history_list.dart';
import 'package:cantino/services/cache/usercard_cache_service.dart';
import 'package:cantino/services/log.dart';
import 'package:cantino/components/common/skeleton_loader.dart';
import 'package:cantino/components/common/table_calendar_component.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserCardCacheService _cacheService = UserCardCacheService();
  final _supabase = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>>? _userSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

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
    final user = _supabase.auth.currentUser;
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
    _startSupabaseListeners(user.id);
  }

  void _startSupabaseListeners(String userId) {
    // Listen to user data changes
    _userSubscription = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((data) {
          if (data.isNotEmpty) {
            _updateUserCardData(userId);
          }
        });

    // Listen to orders changes
    _ordersSubscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
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
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) {
        final defaultData = _getDefaultData();
        await _cacheService.saveUserCardData(defaultData);
        setState(() {
          _userCardData = defaultData;
          _isLoading = false;
        });
        return;
      }

      final userData = Map<String, dynamic>.from(userResponse);

      // Fetch orders
      final ordersResponse = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId);

      Map<String, dynamic> userCardData;

      if (ordersResponse.isEmpty) {
        userCardData = {
          'userName': userData['user_name'] ?? 'User',
          'orderCode': 'N/A',
          'items': [],
          'status': 'N/A',
          'timestamp': 0,
        };
      } else {
        final orders = ordersResponse as List<dynamic>;

        if (orders.isEmpty) {
          userCardData = {
            'userName': userData['user_name'] ?? 'User',
            'orderCode': 'N/A',
            'items': [],
            'status': 'N/A',
            'timestamp': 0,
          };
        } else {
          // Find the latest order by timestamp
          Map<String, dynamic>? latestOrder;
          int latestTimestamp = 0;

          for (var orderData in orders) {
            if (orderData is Map) {
              final order = Map<String, dynamic>.from(orderData);
              final timestamp = order['timestamp'] is int
                  ? order['timestamp'] as int
                  : 0;

              if (timestamp > latestTimestamp) {
                latestTimestamp = timestamp;
                latestOrder = order;
              }
            }
          }

          if (latestOrder != null) {
            // Fetch order items for this order
            final orderItems = await _supabase
                .from('order_items')
                .select()
                .eq('order_id', latestOrder['id']);

            final itemsList = orderItems
                .map(
                  (item) => {
                    'foodItemId': item['food_item_id'],
                    'quantity': item['quantity'],
                  },
                )
                .toList();

            userCardData = {
              'userName': userData['user_name'] ?? 'User',
              'orderCode': latestOrder['code']?.toString() ?? 'N/A',
              'items': itemsList,
              'status': latestOrder['status']?.toString() ?? 'N/A',
              'timestamp': latestOrder['timestamp'] is int
                  ? latestOrder['timestamp'] as int
                  : 0,
            };
          } else {
            userCardData = {
              'userName': userData['user_name'] ?? 'User',
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
      logError('Error updating UserCard data: $e', e);
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

  @override
  Widget build(BuildContext context) {
    // Show skeleton loading state when loading and no cached data
    if (_isLoading && _userCardData == null) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                const UserCardSkeleton(),
                const SizedBox(height: 20),
                const FoodSectionSkeleton(),
                const SizedBox(height: 20),
                const ScrollCardSkeleton(),
                const SizedBox(height: 20),
                const TableCalendarSkeleton(),
                const SizedBox(height: 20),
                const OrderHistorySkeleton(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              ],
            ),
          ),
        ),
      );
    }

    // Determine which UserCard to show
    Widget userCardWidget;
    if (_userCardData == null) {
      userCardWidget = const UserCard(
        userName: 'User',
      );
    } else {
      final data = _userCardData!;
      final rawOrderCode = data['orderCode']?.toString();
      final hasValidOrder = rawOrderCode != null &&
          rawOrderCode.isNotEmpty &&
          rawOrderCode != 'N/A';
      userCardWidget = UserCard(
        userName: data['userName']?.toString() ?? 'User',
        orderCode: hasValidOrder ? rawOrderCode : null,
        items: hasValidOrder && data['items'] is List<Map<String, dynamic>>
            ? data['items'] as List<Map<String, dynamic>>
            : [],
        status: hasValidOrder ? data['status']?.toString() : null,
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
              RepaintBoundary(child: userCardWidget),
              const SizedBox(height: 30),
              const RepaintBoundary(child: FoodSection()),
              const SizedBox(height: 30),
              const RepaintBoundary(child: Scrollcard()),
              const SizedBox(height: 50),
              const RepaintBoundary(child: TableCalendarComponent()),
              const SizedBox(height: 50),
              const RepaintBoundary(child: OrderHistoryList()),
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

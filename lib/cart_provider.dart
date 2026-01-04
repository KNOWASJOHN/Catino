import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'services/order_service.dart';
import 'models/order_model.dart';
import 'pages/food.dart'; // For FoodItem

class CartProvider with ChangeNotifier {
  Map<String, int> _cart = {};
  Map<String, int> get cart => _cart;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final OrderService _orderService = OrderService();
  String? _currentUserId;
  StreamSubscription<DatabaseEvent>? _cartSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  int get itemCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  CartProvider() {
    _listenToAuthChanges();
    _orderService.startListeningToOrders();
  }

  /// Listen to authentication state changes and manage cart accordingly
  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.uid != _currentUserId) {
        // User logged in or switched - load their cart
        _currentUserId = user.uid;
        _loadCart();
      } else if (user == null) {
        // User logged out - clear everything
        _currentUserId = null;
        _clearLocalCart();
        _cancelCartSubscription();
        _clearCache();
      }
    });
  }

  /// Load cart from Firebase with offline cache fallback
  Future<void> _loadCart() async {
    _cancelCartSubscription();
    
    final uid = _currentUserId;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    // Load from cache first for instant display
    await _loadFromCache(uid);

    try {
      _cartSubscription = _dbRef.child('users/$uid/cart').onValue.listen(
        (event) {
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            _cart = data.map((k, v) => MapEntry(k, v as int));
          } else {
            _cart = {};
          }
          _isLoading = false;
          notifyListeners();
          _saveToCache(uid, _cart);
        },
        onError: (error) {
          print('Error loading cart from Firebase: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Error setting up cart listener: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load cart from SharedPreferences cache
  Future<void> _loadFromCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('cart_user_id');
      
      // Only load cache if it belongs to the current user
      if (cachedUserId == uid) {
        final cartJson = prefs.getString('cart_data');
        if (cartJson != null) {
          final decoded = jsonDecode(cartJson) as Map<String, dynamic>;
          _cart = decoded.map((k, v) => MapEntry(k, v as int));
          notifyListeners();
        }
      } else {
        // Clear cache if it belongs to a different user
        await _clearCache();
      }
    } catch (e) {
      print('Error loading cart from cache: $e');
    }
  }

  /// Save cart to SharedPreferences cache
  Future<void> _saveToCache(String uid, Map<String, int> cartData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart_user_id', uid);
      await prefs.setString('cart_data', jsonEncode(cartData));
    } catch (e) {
      print('Error saving cart to cache: $e');
    }
  }

  /// Clear cached cart data
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_user_id');
      await prefs.remove('cart_data');
    } catch (e) {
      print('Error clearing cart cache: $e');
    }
  }

  /// Cancel cart subscription to prevent memory leaks
  void _cancelCartSubscription() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
  }

  /// Clear local cart state
  void _clearLocalCart() {
    _cart = {};
    notifyListeners();
  }

  void addItem(String id) {
    if (_cart.containsKey(id)) {
      _cart[id] = _cart[id]! + 1;
    } else {
      _cart[id] = 1;
    }
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String id, int qty) {
    if (qty <= 0) {
      _cart.remove(id);
    } else {
      _cart[id] = qty;
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String id) {
    _cart.remove(id);
    _saveCart();
    notifyListeners();
  }

  void clear() {
    _cart.clear();
    _saveCart();
    notifyListeners();
  }

  /// Save cart to Firebase and cache
  void _saveCart() {
    final uid = _currentUserId;
    if (uid == null) return;
    
    _dbRef.child('users/$uid/cart').set(_cart).catchError((error) {
      print('Error saving cart to Firebase: $error');
    });
    
    // Also save to cache for offline access
    _saveToCache(uid, _cart);
  }

  Future<void> placeOrder(List<Map<String, dynamic>> cartItems) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      final code = orderId.substring(6); // Shorter code for display

      // Convert cart items to OrderItem objects
      final orderItems = cartItems.map((e) => OrderItem(
        id: (e['item'] as FoodItem).id,
        quantity: e['qty'] as int,
      )).toList();

      // Create Order object with proper model structure
      final order = Order(
        id: orderId,
        code: code,
        items: orderItems,
        qrCode: 'https://api.qrserver.com/v1/create-qr-code/?data=$code',
        status: OrderStatus.pending,
        dateTime: DateTime.now(),
      );

      // Use OrderService for proper status management and automatic notifications
      final success = await _orderService.addOrder(order);
      
      if (success) {
        // Clear cart after successful order placement
        clear();
        print('Order placed successfully: $code');
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      print('Error placing order: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  @override
  void dispose() {
    _cancelCartSubscription();
    _authSubscription?.cancel();
    _orderService.stopListeningToOrders();
    super.dispose();
  }
}
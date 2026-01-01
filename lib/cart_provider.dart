import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pages/food.dart'; // For FoodItem

class CartProvider with ChangeNotifier {
  Map<String, int> _cart = {};
  Map<String, int> get cart => _cart;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  CartProvider() {
    _loadCart();
  }

  void _loadCart() {
    final uid = userId;
    if (uid == null) return;
    _dbRef.child('users/$uid/cart').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _cart = data.map((k, v) => MapEntry(k, v as int));
      } else {
        _cart = {};
      }
      notifyListeners();
    });
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

  void _saveCart() {
    final uid = userId;
    if (uid == null) return;
    _dbRef.child('users/$uid/cart').set(_cart);
  }

  Future<void> placeOrder(List<Map<String, dynamic>> cartItems) async {
    final uid = userId;
    if (uid == null) return;

    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final code = orderId; // Simple code, can be improved for uniqueness

    final items = cartItems.map((e) => {
      'id': (e['item'] as FoodItem).id,
      'qty': e['qty']
    }).toList();

    final orderData = {
      'code': code,
      'items': items,
      'qrCode': 'https://api.qrserver.com/v1/create-qr-code/?data=$code',
      'status': 'pending',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _dbRef.child('orders/$uid/$orderId').set(orderData);
    clear();
  }
}
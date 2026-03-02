import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/data/supabase_order_service.dart';
import '../models/order_model.dart';
import '../models/food_item.dart';
import '../models/payment_result.dart';
import '../utils/logger_config.dart';

final _logger = AppLogger.getLogger('CartProvider');

class CartProvider with ChangeNotifier {
  Map<String, int> _cart = {};
  Map<String, int> get cart => _cart;

  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseOrderService _orderService = SupabaseOrderService();
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription? _cartSubscription;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Track pending local updates to prevent stream-triggered rebuilds
  final Set<String> _pendingLocalUpdates = {};
  Timer? _debounceTimer;

  int get itemCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  CartProvider() {
    _listenToAuthChanges();
    _orderService.startListeningToOrders();
  }

  /// Listen to authentication state changes and manage cart accordingly
  void _listenToAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null && user.id != _currentUserId) {
        // User logged in or switched - load their cart
        _currentUserId = user.id;
        _loadCart();
        // Start listening for order status changes (needs authenticated user)
        _orderService.startListeningToOrders();
      } else if (user == null) {
        // User logged out - clear everything
        _currentUserId = null;
        _clearLocalCart();
        _cancelCartSubscription();
        _clearCache();
        _orderService.stopListeningToOrders();
      }
    });
  }

  /// Load cart from Supabase with offline cache fallback
  Future<void> _loadCart() async {
    _cancelCartSubscription();

    final uid = _currentUserId;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    // Load from cache first for instant display
    await _loadFromCache(uid);

    try {
      _cartSubscription = _supabase
          .from('user_cart')
          .stream(primaryKey: ['user_id', 'food_item_id'])
          .eq('user_id', uid)
          .listen(
            (data) {
              // Skip stream updates if we have pending local updates
              if (_pendingLocalUpdates.isNotEmpty) {
                _logger.fine(
                  'Skipping stream update - local update in progress',
                );
                return;
              }

              // Build new cart from stream data
              final newCart = <String, int>{};
              for (final item in data) {
                newCart[item['food_item_id'] as String] =
                    item['quantity'] as int;
              }

              // Only update and notify if cart actually changed
              if (!_areCartsEqual(_cart, newCart)) {
                _cart = newCart;
                _isLoading = false;
                notifyListeners();
                _saveToCache(uid, _cart);
              } else {
                _isLoading = false;
              }
            },
            onError: (error) {
              _logger.severe('Error loading cart from Supabase', error);
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _logger.severe('Error setting up cart listener', e);
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
          final newCart = decoded.map((k, v) => MapEntry(k, v as int));

          // Only update and notify if cart actually changed
          if (!_areCartsEqual(_cart, newCart)) {
            _cart = newCart;
            notifyListeners();
          }
        }
      } else {
        // Clear cache if it belongs to a different user
        await _clearCache();
      }
    } catch (e) {
      _logger.warning('Error loading cart from cache', e);
    }
  }

  /// Save cart to SharedPreferences cache
  Future<void> _saveToCache(String uid, Map<String, int> cartData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart_user_id', uid);
      await prefs.setString('cart_data', jsonEncode(cartData));
    } catch (e) {
      _logger.warning('Error saving cart to cache', e);
    }
  }

  /// Clear cached cart data
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_user_id');
      await prefs.remove('cart_data');
    } catch (e) {
      _logger.warning('Error clearing cart cache', e);
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
    _markLocalUpdate(id);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String id, int qty) {
    if (qty <= 0) {
      _cart.remove(id);
    } else {
      _cart[id] = qty;
    }
    _markLocalUpdate(id);
    _saveCart();
    notifyListeners();
  }

  void removeItem(String id) {
    _cart.remove(id);
    _markLocalUpdate(id);
    _saveCart();
    notifyListeners();
  }

  void clear() {
    _cart.clear();
    _markLocalUpdate('__all__');
    _saveCart();
    notifyListeners();
  }

  /// Save cart to Supabase and cache
  void _saveCart() async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      // First, delete all existing cart items for this user
      await _supabase.from('user_cart').delete().eq('user_id', uid);

      // Then insert the current cart items
      if (_cart.isNotEmpty) {
        final cartData = _cart.entries
            .map(
              (entry) => {
                'user_id': uid,
                'food_item_id': entry.key,
                'quantity': entry.value,
              },
            )
            .toList();

        await _supabase.from('user_cart').insert(cartData);
      }

      // Also save to cache for offline access
      _saveToCache(uid, _cart);
    } catch (e) {
      _logger.severe('Error saving cart to Supabase', e);
    }
  }

  Future<void> placeOrder(
    List<Map<String, dynamic>> cartItems, {
    PaymentResult? paymentResult,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;

    // Log payment details for debugging
    if (paymentResult != null) {
      _logger.info(
        'Placing order with payment: ID=${paymentResult.paymentId}, Status=${paymentResult.isSuccess}',
      );
    } else {
      _logger.warning('Placing order WITHOUT payment result');
    }

    try {
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      final code = orderId.substring(6); // Shorter code for display

      // Convert cart items to OrderItem objects
      final orderItems = cartItems
          .map(
            (e) => OrderItem(
              id: (e['item'] as FoodItem).id,
              quantity: e['qty'] as int,
            ),
          )
          .toList();

      // Calculate total amount
      double subtotal = cartItems.fold(
        0,
        (sum, entry) =>
            sum + (entry['item'] as FoodItem).price * (entry['qty'] as int),
      );
      const double deliveryFee = 25.0;
      double discount = subtotal > 499 ? 50 : 0;
      double totalAmount = subtotal + deliveryFee - discount;

      // Create Order object with proper model structure
      final order = Order(
        id: orderId,
        code: code,
        items: orderItems,
        qrCode: 'https://api.qrserver.com/v1/create-qr-code/?data=$code',
        status: OrderStatus.pending,
        dateTime: DateTime.now(),
        paymentId: paymentResult?.paymentId,
        orderId: paymentResult?.orderId,
        paymentStatus: paymentResult != null ? 'paid' : 'pending',
        totalAmount: totalAmount,
      );

      // Use OrderService for proper status management and automatic notifications
      final success = await _orderService.addOrder(order);

      // Always clear the cart after a confirmed payment, regardless of
      // whether the order DB write succeeded, so the user is never left
      // with a full cart after money has already been charged.
      if (paymentResult != null && paymentResult.isSuccess) {
        clear();
      }

      if (success) {
        _logger.info('Order placed successfully: $code');
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      _logger.severe('Error placing order', e);
      throw e; // Re-throw to handle in UI
    }
  }

  /// Mark a local update to prevent stream-triggered rebuilds
  void _markLocalUpdate(String id) {
    _pendingLocalUpdates.add(id);

    // Clear the pending update after a delay
    // This prevents the stream from triggering a rebuild during the save operation
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _pendingLocalUpdates.clear();
    });
  }

  /// Helper method to compare two carts for equality
  bool _areCartsEqual(Map<String, int> cart1, Map<String, int> cart2) {
    if (cart1.length != cart2.length) return false;
    for (final entry in cart1.entries) {
      if (cart2[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cancelCartSubscription();
    _authSubscription?.cancel();
    _orderService.stopListeningToOrders();
    super.dispose();
  }
}

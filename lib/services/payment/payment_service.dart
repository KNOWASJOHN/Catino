import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:cantino/models/payment_result.dart';
import 'package:cantino/services/log.dart';

/// ============================================================================
/// RAZORPAY PAYMENT SERVICE
/// ============================================================================
/// A production-ready payment service for handling Razorpay payments.
///
/// SECURITY NOTES (CRITICAL - DO NOT SKIP):
/// 1. NEVER create orders on the client side - always use backend
/// 2. NEVER trust client-side payment verification alone
/// 3. Always verify signature on your backend before unlocking features
/// 4. Use Test keys during development, switch to Live only after testing
///
/// BACKEND VERIFICATION (Node.js Example):
/// ```javascript
/// const crypto = require('crypto');
///
/// function verifyRazorpaySignature(orderId, paymentId, signature, secret) {
///   const expectedSignature = crypto
///     .createHmac('sha256', secret)
///     .update(orderId + '|' + paymentId)
///     .digest('hex');
///
///   return expectedSignature === signature;
/// }
/// ```
/// ============================================================================

class PaymentService {
  /// Singleton instance
  static PaymentService? _instance;

  /// Razorpay instance - manages the checkout UI
  late Razorpay _razorpay;

  /// Completer for async payment handling
  Completer<PaymentResult>? _paymentCompleter;

  /// Razorpay API Key (from environment)
  final String _razorpayKeyId;

  /// Backend URL for order creation and verification
  final String _backendUrl;

  /// Private constructor
  PaymentService._internal()
    : _razorpayKeyId = dotenv.env['RAZORPAY_TEST_KEY_ID'] ?? '',
      _backendUrl = dotenv.env['RAZORPAY_BACKEND_URL'] ?? '' {
    _initRazorpay();
  }

  /// Get singleton instance
  factory PaymentService() {
    _instance ??= PaymentService._internal();
    return _instance!;
  }

  /// Initialize Razorpay and attach event handlers
  void _initRazorpay() {
    _razorpay = Razorpay();

    // Attach event listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    logInfo('PaymentService: Razorpay initialized successfully');
  }

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  /// Start a payment flow
  ///
  /// This method:
  /// 1. Fetches an order ID from your backend
  /// 2. Opens Razorpay checkout
  /// 3. Handles the payment result
  /// 4. Verifies payment on backend
  ///
  /// Parameters:
  /// - [amount]: Amount in INR (will be converted to paise)
  /// - [description]: Payment description shown in checkout
  /// - [prefillEmail]: Pre-filled email for the user
  /// - [prefillContact]: Pre-filled phone number for the user
  /// - [metadata]: Additional metadata to pass to backend
  ///
  /// Returns a [PaymentResult] with payment details
  Future<PaymentResult> startPayment({
    required double amount,
    required String description,
    String? prefillEmail,
    String? prefillContact,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      logInfo('PaymentService: Starting payment for ₹$amount');

      // Step 1: Create order on backend
      final orderData = await _fetchOrderFromBackend(
        amount: amount,
        metadata: metadata,
      );

      if (orderData == null) {
        return PaymentResult.failure(
          message: 'Failed to create order. Please try again.',
        );
      }

      final orderId = orderData['id'] as String;
      final amountInPaise = orderData['amount'] as int;

      logInfo('PaymentService: Order created - $orderId');

      // Step 2: Open checkout
      final result = await _openCheckout(
        orderId: orderId,
        amountInPaise: amountInPaise,
        description: description,
        prefillEmail: prefillEmail,
        prefillContact: prefillContact,
      );

      // Step 3: If successful, verify on backend
      if (result.isSuccess) {
        final isVerified = await _verifyPaymentOnBackend(result);

        if (!isVerified) {
          return PaymentResult.failure(
            message: 'Payment verification failed. Please contact support.',
          );
        }

        logInfo('PaymentService: Payment verified successfully');
        _showToast('Payment successful! ✓', isSuccess: true);
      }

      return result;
    } catch (e, stackTrace) {
      logError('PaymentService: Payment failed - $e', stackTrace);
      return PaymentResult.failure(message: e.toString());
    }
  }

  /// Clean up resources - call this when disposing the service
  void dispose() {
    _razorpay.clear();
    _instance = null;
    logInfo('PaymentService: Disposed');
  }

  // ============================================================================
  // BACKEND COMMUNICATION (PLACEHOLDER - IMPLEMENT YOUR ENDPOINTS)
  // ============================================================================

  /// Fetch order ID from backend
  ///
  /// IMPORTANT: This is a placeholder. You MUST implement your own backend
  /// endpoint that creates Razorpay orders using the Orders API.
  ///
  /// Your backend should:
  /// 1. Receive amount and metadata
  /// 2. Call Razorpay Orders API to create an order
  /// 3. Store order details in your database
  /// 4. Return the order_id to the client
  ///
  /// Example backend endpoint (Node.js):
  /// ```javascript
  /// const Razorpay = require('razorpay');
  ///
  /// const instance = new Razorpay({
  ///   key_id: process.env.RAZORPAY_KEY_ID,
  ///   key_secret: process.env.RAZORPAY_KEY_SECRET
  /// });
  ///
  /// app.post('/api/create-order', async (req, res) => {
  ///   const { amount, metadata } = req.body;
  ///
  ///   const order = await instance.orders.create({
  ///     amount: amount * 100, // Convert to paise
  ///     currency: 'INR',
  ///     receipt: `receipt_${Date.now()}`,
  ///     notes: metadata
  ///   });
  ///
  ///   // Store in database...
  ///
  ///   res.json({ id: order.id, amount: order.amount });
  /// });
  /// ```
  Future<Map<String, dynamic>?> _fetchOrderFromBackend({
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // TODO: Replace with your actual backend endpoint
      final url = Uri.parse('$_backendUrl/create-order');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': 'INR',
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      logError(
        'PaymentService: Order creation failed - ${response.statusCode}',
        null,
      );
      return null;
    } catch (e, stackTrace) {
      logError('PaymentService: Order creation error - $e', stackTrace);

      // ========================================================================
      // DEVELOPMENT FALLBACK - REMOVE IN PRODUCTION
      // ========================================================================
      // This creates a mock order for testing. In production, orders MUST
      // be created on your backend for security.
      if (kDebugMode) {
        logInfo('PaymentService: Using mock order for development');
        return {
          'id': 'order_${DateTime.now().millisecondsSinceEpoch}',
          'amount': (amount * 100).toInt(), // Convert to paise
        };
      }
      // ========================================================================

      return null;
    }
  }

  /// Verify payment signature on backend
  ///
  /// IMPORTANT: This is a placeholder. You MUST implement your own backend
  /// endpoint that verifies the Razorpay signature.
  ///
  /// Your backend should:
  /// 1. Receive paymentId, orderId, and signature
  /// 2. Generate expected signature using HMAC SHA256
  /// 3. Compare signatures
  /// 4. Update order status in database
  /// 5. Unlock premium features if verified
  ///
  /// Example backend endpoint (Node.js):
  /// ```javascript
  /// const crypto = require('crypto');
  ///
  /// app.post('/api/verify-payment', (req, res) => {
  ///   const { payment_id, order_id, signature } = req.body;
  ///
  ///   const expectedSignature = crypto
  ///     .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
  ///     .update(order_id + '|' + payment_id)
  ///     .digest('hex');
  ///
  ///   if (expectedSignature === signature) {
  ///     // Update database, unlock features
  ///     res.json({ verified: true });
  ///   } else {
  ///     res.status(400).json({ verified: false, error: 'Invalid signature' });
  ///   }
  /// });
  /// ```
  Future<bool> _verifyPaymentOnBackend(PaymentResult result) async {
    try {
      // TODO: Replace with your actual backend endpoint
      final url = Uri.parse('$_backendUrl/verify-payment');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_id': result.paymentId,
          'order_id': result.orderId,
          'signature': result.signature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] == true;
      }

      return false;
    } catch (e, stackTrace) {
      logError('PaymentService: Verification error - $e', stackTrace);

      // ========================================================================
      // DEVELOPMENT FALLBACK - REMOVE IN PRODUCTION
      // ========================================================================
      // In development, assume verification passes. In production, always
      // verify on your backend!
      if (kDebugMode) {
        logInfo('PaymentService: Skipping verification in development');
        return true;
      }
      // ========================================================================

      return false;
    }
  }

  // ============================================================================
  // CHECKOUT
  // ============================================================================

  /// Open Razorpay checkout with the given options
  Future<PaymentResult> _openCheckout({
    required String orderId,
    required int amountInPaise,
    required String description,
    String? prefillEmail,
    String? prefillContact,
  }) async {
    // Create a completer to handle the async callback
    _paymentCompleter = Completer<PaymentResult>();

    // Build checkout options
    final options = {
      // API Key (use test key in development)
      'key': _razorpayKeyId,

      // Amount in paise (100 paise = ₹1)
      'amount': amountInPaise,

      // Currency
      'currency': 'INR',

      // Order ID from backend (REQUIRED for production)
      'order_id': orderId,

      // Business name shown in checkout
      'name': 'Catino',

      // Payment description
      'description': description,

      // Pre-fill user details
      'prefill': {'email': prefillEmail ?? '', 'contact': prefillContact ?? ''},

      // Theme customization
      'theme': {
        'color': '#6366F1', // Indigo color to match app theme
      },

      // Retry options
      'retry': {'enabled': true, 'max_count': 3},

      // External wallets (optional)
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe'],
      },
    };

    logInfo('PaymentService: Opening checkout for order $orderId');

    try {
      _razorpay.open(options);
    } catch (e, stackTrace) {
      logError('PaymentService: Checkout open failed - $e', stackTrace);
      _paymentCompleter?.complete(
        PaymentResult.failure(message: 'Failed to open payment screen'),
      );
    }

    // Wait for the payment result
    return _paymentCompleter!.future;
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    logInfo('PaymentService: Payment successful');
    logInfo('  Payment ID: ${response.paymentId}');
    logInfo('  Order ID: ${response.orderId}');
    logInfo('  Signature: ${response.signature?.substring(0, 20)}...');

    final result = PaymentResult.success(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId ?? '',
      signature: response.signature ?? '',
    );

    _paymentCompleter?.complete(result);
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    logError('PaymentService: Payment failed - ${response.message}', null);

    _showToast(
      response.message ?? 'Payment failed. Please try again.',
      isSuccess: false,
    );

    final result = PaymentResult.failure(
      message: response.message ?? 'Payment failed',
      code: response.code,
    );

    _paymentCompleter?.complete(result);
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    logInfo(
      'PaymentService: External wallet selected - ${response.walletName}',
    );

    _showToast('Redirecting to ${response.walletName}...', isSuccess: true);

    final result = PaymentResult.externalWallet(
      walletName: response.walletName ?? 'Unknown',
    );

    _paymentCompleter?.complete(result);
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Show a toast message
  void _showToast(String message, {required bool isSuccess}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isSuccess
          ? const Color(0xFF22C55E)
          : const Color(0xFFEF4444),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 14.0,
    );
  }
}

// ==============================================================================
// TESTING NOTES
// ==============================================================================
// Use these test credentials during development:
//
// TEST CARDS:
// - Card Number: 4111 1111 1111 1111
// - Expiry: Any future date (e.g., 12/25)
// - CVV: Any 3 digits (e.g., 123)
// - Name: Any name
//
// TEST UPI:
// - Success: success@razorpay
// - Failure: failure@razorpay
//
// TEST NET BANKING:
// - Bank: Any bank, will auto-succeed in test mode
//
// IMPORTANT:
// - Test mode payments don't deduct real money
// - Always test all scenarios before going live
// - Switch to live keys only after thorough testing
// ==============================================================================

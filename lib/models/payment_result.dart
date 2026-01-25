/// Model class representing the result of a Razorpay payment transaction.
///
/// Contains all necessary information for payment verification including
/// the payment ID, order ID, and signature from Razorpay.
class PaymentResult {
  /// Unique payment identifier from Razorpay
  final String? paymentId;

  /// Order ID created on the backend
  final String? orderId;

  /// HMAC signature for server-side verification
  final String? signature;

  /// Whether the payment was successful
  final bool isSuccess;

  /// Error message if payment failed
  final String? errorMessage;

  /// Error code from Razorpay (if payment failed)
  final int? errorCode;

  /// External wallet name (if user chose external wallet)
  final String? walletName;

  const PaymentResult({
    this.paymentId,
    this.orderId,
    this.signature,
    required this.isSuccess,
    this.errorMessage,
    this.errorCode,
    this.walletName,
  });

  /// Create a successful payment result
  factory PaymentResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) {
    return PaymentResult(
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
      isSuccess: true,
    );
  }

  /// Create a failed payment result
  factory PaymentResult.failure({required String message, int? code}) {
    return PaymentResult(
      isSuccess: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  /// Create an external wallet result
  factory PaymentResult.externalWallet({required String walletName}) {
    return PaymentResult(
      isSuccess: false,
      walletName: walletName,
      errorMessage: 'User selected external wallet: $walletName',
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'PaymentResult(success: paymentId=$paymentId, orderId=$orderId)';
    } else if (walletName != null) {
      return 'PaymentResult(externalWallet: $walletName)';
    } else {
      return 'PaymentResult(failed: $errorMessage, code=$errorCode)';
    }
  }

  /// Convert to JSON for sending to backend
  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'order_id': orderId,
      'signature': signature,
      'is_success': isSuccess,
      'error_message': errorMessage,
      'error_code': errorCode,
      'wallet_name': walletName,
    };
  }
}

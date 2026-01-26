/**
 * Payment Routes
 * 
 * Handles all Razorpay payment-related endpoints:
 * - Order creation
 * - Payment verification
 * - Webhook events
 */

const express = require('express');
const crypto = require('crypto');
const razorpay = require('../utils/razorpay');

const router = express.Router();

// =============================================================================
// CREATE ORDER
// =============================================================================

/**
 * POST /api/create-order
 * 
 * Creates a new Razorpay order.
 * 
 * Request body:
 * {
 *   "amount": 100,        // Amount in INR (will be converted to paise)
 *   "currency": "INR",    // Optional, defaults to INR
 *   "metadata": {}        // Optional, additional notes
 * }
 * 
 * Response:
 * {
 *   "id": "order_xxxxx",
 *   "amount": 10000,      // Amount in paise
 *   "currency": "INR",
 *   "receipt": "receipt_xxxxx"
 * }
 */
router.post('/create-order', async (req, res) => {
    try {
        const { amount, currency = 'INR', metadata = {} } = req.body;

        // Validate amount
        if (!amount || typeof amount !== 'number' || amount <= 0) {
            return res.status(400).json({
                error: 'Invalid amount',
                message: 'Amount must be a positive number',
            });
        }

        // Convert to paise (1 INR = 100 paise)
        const amountInPaise = Math.round(amount * 100);

        // Generate unique receipt ID
        const receipt = `receipt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // Create order options
        const options = {
            amount: amountInPaise,
            currency: currency,
            receipt: receipt,
            notes: {
                ...metadata,
                created_at: new Date().toISOString(),
            },
        };

        if (process.env.NODE_ENV === 'development') {
            console.log('Creating order');
        }

        // Create order via Razorpay API
        const order = await razorpay.orders.create(options);

        if (process.env.NODE_ENV === 'development') {
            console.log('Order created');
        }

        // Return order details to client
        res.json({
            id: order.id,
            amount: order.amount,
            currency: order.currency,
            receipt: order.receipt,
        });
    } catch (error) {
        if (process.env.NODE_ENV === 'development') {
            console.error('Order creation failed', error);
        } else {
            console.error('Order creation failed');
        }
        res.status(500).json({
            error: 'Order creation failed',
            message: process.env.NODE_ENV === 'development' ? error.message : 'An internal error occurred',
        });
    }
});

// =============================================================================
// VERIFY PAYMENT
// =============================================================================

/**
 * POST /api/verify-payment
 * 
 * Verifies the payment signature using HMAC SHA256.
 * This is the critical security step - only unlock premium features
 * after this verification passes!
 * 
 * Request body:
 * {
 *   "payment_id": "pay_xxxxx",
 *   "order_id": "order_xxxxx",
 *   "signature": "xxxxxxx"
 * }
 * 
 * Response:
 * {
 *   "verified": true,
 *   "payment_id": "pay_xxxxx",
 *   "order_id": "order_xxxxx"
 * }
 */
router.post('/verify-payment', (req, res) => {
    try {
        const { payment_id, order_id, signature } = req.body;

        // Validate required fields
        if (!payment_id || !order_id || !signature) {
            return res.status(400).json({
                error: 'Missing fields',
                message: 'payment_id, order_id, and signature are required',
            });
        }

        // Generate expected signature using HMAC SHA256
        // The signature is generated from: order_id + "|" + payment_id
        const body = order_id + '|' + payment_id;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body)
            .digest('hex');

        // Compare signatures
        const isValid = expectedSignature === signature;

        if (process.env.NODE_ENV === 'development') {
            console.log('Payment verification result');
        }

        if (isValid) {
            // =====================================================================
            // IMPORTANT: This is where you should:
            // 1. Update your database to mark the order as paid
            // 2. Grant premium access to the user
            // 3. Send confirmation email, etc.
            // =====================================================================

            res.json({
                verified: true,
                payment_id: payment_id,
                order_id: order_id,
                message: 'Payment verified successfully',
            });
        } else {
            console.error('Signature mismatch!');

            res.status(400).json({
                verified: false,
                error: 'Invalid signature',
                message: 'Payment verification failed',
            });
        }
    } catch (error) {
        if (process.env.NODE_ENV === 'development') {
            console.error('Verification failed', error);
        } else {
            console.error('Verification failed');
        }
        res.status(500).json({
            error: 'Verification failed',
            message: process.env.NODE_ENV === 'development' ? error.message : 'An internal error occurred',
        });
    }
});

// =============================================================================
// WEBHOOK HANDLER
// =============================================================================

/**
 * POST /api/webhook
 * 
 * Handles Razorpay webhook events.
 * Configure webhooks in Razorpay Dashboard > Webhooks
 * 
 * Supported events:
 * - payment.authorized
 * - payment.captured
 * - payment.failed
 * - order.paid
 * - refund.created
 */
router.post('/webhook', (req, res) => {
    try {
        // Get the webhook signature from headers
        const webhookSignature = req.headers['x-razorpay-signature'];
        const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;

        // Get raw body (configured in server.js)
        const rawBody = req.body;

        // Verify webhook signature if secret is configured
        if (webhookSecret && webhookSecret !== 'YOUR_WEBHOOK_SECRET_HERE') {
            const expectedSignature = crypto
                .createHmac('sha256', webhookSecret)
                .update(rawBody)
                .digest('hex');

            if (expectedSignature !== webhookSignature) {
                console.error('Webhook signature verification failed');
                return res.status(400).json({ error: 'Invalid signature' });
            }
        }

        // Parse the webhook payload
        const event = JSON.parse(rawBody.toString());

        if (process.env.NODE_ENV === 'development') {
            console.log('Webhook received:', event.event);
        }

        // Handle different event types
        switch (event.event) {
            case 'payment.authorized':
                if (process.env.NODE_ENV === 'development') {
                    console.log('Payment authorized event received');
                }
                // Payment is authorized but not captured yet
                break;

            case 'payment.captured':
                if (process.env.NODE_ENV === 'development') {
                    console.log('Payment captured event received');
                }
                // Payment is successfully captured
                // This is a good place to fulfill the order
                break;

            case 'payment.failed':
                if (process.env.NODE_ENV === 'development') {
                    console.log('Payment failed event received');
                }
                // Handle failed payment
                break;

            case 'order.paid':
                if (process.env.NODE_ENV === 'development') {
                    console.log('Order paid event received');
                }
                // Order is fully paid
                break;

            case 'refund.created':
                if (process.env.NODE_ENV === 'development') {
                    console.log('Refund created event received');
                }
                // Handle refund
                break;

            default:
                if (process.env.NODE_ENV === 'development') {
                    console.log('Unhandled event:', event.event);
                }
        }

        // Always respond with 200 to acknowledge receipt
        res.json({ received: true });
        } catch (error) {
            if (process.env.NODE_ENV === 'development') {
                console.error('Webhook error', error);
            } else {
                console.error('Webhook error');
            }
            // Still return 200 to prevent retries for parsing errors
            res.json({ received: true });
    }
});

// =============================================================================
// FETCH PAYMENT DETAILS (Optional helper endpoint)
// =============================================================================

/**
 * GET /api/payment/:paymentId
 * 
 * Fetches payment details from Razorpay.
 * Useful for checking payment status.
 */
router.get('/payment/:paymentId', async (req, res) => {
    try {
        const { paymentId } = req.params;

        const payment = await razorpay.payments.fetch(paymentId);

        res.json({
            id: payment.id,
            amount: payment.amount,
            currency: payment.currency,
            status: payment.status,
            method: payment.method,
            order_id: payment.order_id,
            created_at: payment.created_at,
        });
    } catch (error) {
        if (process.env.NODE_ENV === 'development') {
            console.error('Payment fetch failed:', error);
        } else {
            console.error('Payment fetch failed');
        }
        res.status(500).json({
            error: 'Payment fetch failed',
            message: process.env.NODE_ENV === 'development' ? error.message : 'An internal error occurred',
        });
    }
});

module.exports = router;

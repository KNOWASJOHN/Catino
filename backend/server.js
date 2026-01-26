/**
 * Razorpay Payment Backend Server
 * 
 * This server handles:
 * - Order creation via Razorpay Orders API
 * - Payment verification via HMAC signature
 * - Webhook events from Razorpay
 */

// Load environment variables if available. If `dotenv` is not installed
// (e.g., when running without `npm install`), avoid crashing the process.
try {
    require('dotenv').config();
} catch (err) {
    if (process.env.NODE_ENV === 'development') {
        console.warn('dotenv not found; continuing without loading .env file');
    }
}

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const paymentRoutes = require('./routes/payment');

const app = express();
const PORT = process.env.PORT || 3000;

// =============================================================================
// MIDDLEWARE
// =============================================================================

// Security headers
app.use(helmet());

// CORS configuration
// In production, replace '*' with your specific domain
app.use(cors({
    origin: '*', // Allow all origins for development
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
}));

// Parse JSON bodies
// Note: For webhooks, we need raw body for signature verification
app.use('/api/webhook', express.raw({ type: 'application/json' }));
app.use(express.json());

// Request logging (development only)
if (process.env.NODE_ENV === 'development') {
    app.use((req, res, next) => {
        console.log(`${new Date().toISOString()} | ${req.method} ${req.path}`);
        next();
    });
}

// =============================================================================
// ROUTES
// =============================================================================

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Payment routes
app.use('/api', paymentRoutes);

// =============================================================================
// ERROR HANDLING
// =============================================================================

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.path} not found`
    });
});

// Global error handler
app.use((err, req, res, next) => {
    if (process.env.NODE_ENV === 'development') {
        console.error('Server Error', err);
    } else {
        console.error('Server Error');
    }
    res.status(500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
});

// =============================================================================
// START SERVER
// =============================================================================

app.listen(PORT, () => {
    if (process.env.NODE_ENV === 'development') {
        console.log('='.repeat(60));
        console.log('🚀 Razorpay Payment Server (started - development)');
        console.log('='.repeat(60));
        console.log(`   Port: ${PORT}`);
        console.log(`   Health: http://localhost:${PORT}/health`);
        console.log('='.repeat(60));
        console.log('');
        console.log('Available endpoints:');
        console.log(`   POST /api/create-order   - Create a Razorpay order`);
        console.log(`   POST /api/verify-payment - Verify payment signature`);
        console.log(`   POST /api/webhook        - Razorpay webhook handler`);
        console.log('');
    } else {
        // Minimal startup message in production
        console.log(`Razorpay Payment Server started on port ${PORT}`);
    }
});

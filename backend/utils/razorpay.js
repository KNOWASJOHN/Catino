/**
 * Razorpay SDK Configuration
 * 
 * Initializes the Razorpay client with credentials from environment variables.
 */

const Razorpay = require('razorpay');

// Validate required environment variables
if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
    console.error('Missing Razorpay credentials in environment');
    process.exit(1);
}

// Initialize Razorpay instance
const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
});

module.exports = razorpay;

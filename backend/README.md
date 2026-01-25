# Razorpay Payment Backend

Node.js backend for handling Razorpay payments in the Catino Flutter app.

## Deploy to Render

### 1. Create Render Account
Go to [render.com](https://render.com) and sign up (free tier available).

### 2. Create Web Service
1. Click **New** → **Web Service**
2. Connect your GitHub repository
3. Configure:
   - **Name**: `catino-payment-backend`
   - **Region**: Select nearest to your users
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Instance Type**: Free

### 3. Add Environment Variables
In Render dashboard, go to **Environment** and add:

| Key | Value |
|-----|-------|
| `PORT` | `10000` (Render uses this) |
| `NODE_ENV` | `production` |
| `RAZORPAY_KEY_ID` | `rzp_test_xxxxx` |
| `RAZORPAY_KEY_SECRET` | `your_secret` |

### 4. Deploy
Click **Create Web Service**. Render will build and deploy automatically.

### 5. Get Your URL
After deployment, you'll get a URL like:
```
https://catino-payment-backend.onrender.com
```

### 6. Update Flutter App
Update `.env` in your Flutter app:
```
RAZORPAY_BACKEND_URL=https://catino-payment-backend.onrender.com/api
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/create-order` | Create Razorpay order |
| POST | `/api/verify-payment` | Verify payment signature |
| POST | `/api/webhook` | Razorpay webhooks |

## Local Development

```bash
cd backend
npm install
npm start
# Server runs on http://localhost:3000
```

## Test Credentials

- Card: `4111 1111 1111 1111`
- UPI Success: `success@razorpay`
- UPI Failure: `failure@razorpay`

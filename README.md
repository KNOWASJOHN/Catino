# Cantino - Food Ordering App

A comprehensive Flutter food ordering application with real-time notifications, cart management, and print services.

## Features

🍕 **Food Ordering System**
- Browse food items by categories
- Add items to cart with quantity management
- Real-time cart synchronization across devices
- Order placement with QR code generation
- Order status tracking with live notifications

🔔 **Smart Notifications**
- Local push notifications for order updates
- Print job status notifications
- Real-time notification history
- Firebase Cloud Messaging integration

🖨️ **Print Services**
- PDF file upload to Supabase Storage
- Print job management and tracking
- File storage with user-specific folders

👤 **User Management**
- Firebase Authentication
- User profile management with student information
- Dietary preference settings
- Order history tracking

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Provider** - State management
- **Firebase Auth** - User authentication
- **Supabase** - Database and file storage

### Backend Services
- **Firebase Realtime Database** - Real-time data synchronization (migrating to Supabase)
- **Supabase PostgreSQL** - Primary database
- **Supabase Storage** - File storage for print documents
- **Firebase Cloud Messaging** - Push notifications

### Key Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  firebase_database: ^11.1.4
  cloud_firestore: ^5.4.4
  firebase_messaging: ^15.1.3
  supabase_flutter: ^2.0.0
  provider: ^6.0.0
  flutter_local_notifications: ^17.2.3
  shared_preferences: ^2.3.3
  file_picker: ^8.0.0
  flutter_pdfview: ^1.3.2
```

## Architecture

The app follows a clean architecture pattern with:

- **Models**: Data structures for users, orders, food items, notifications
- **Services**: Business logic and external API interactions
- **Providers**: State management for cart, notifications, user data
- **Pages**: UI screens and user interactions
- **Components**: Reusable UI widgets

### Key Services

1. **AuthService** - Handles user authentication and profile management
2. **FoodService** - Manages food items and categories
3. **OrderService** - Handles order creation and status updates
4. **FCMService** - Manages push notifications and notification history
5. **FileUploadService** - Handles PDF uploads to Supabase Storage

## Database Migration: Firebase → Supabase

### Current Firebase Structure
```
├── foodPageItems/          # Food items catalog
├── scroll_cards/           # Promotional cards
├── users/
    ├── {uid}/
        ├── cart/          # User's shopping cart
        ├── orders/        # Order history
        └── notifications/ # Notification history
```

### New Supabase Schema
- **users** - User profiles and preferences
- **food_items** - Food catalog with categories
- **orders** & **order_items** - Orders with proper relationships
- **user_cart** - Shopping cart items
- **notifications** - User notifications
- **scroll_cards** - Promotional content
- **print_jobs** - Print service data

## Setup Instructions

### Prerequisites
1. Flutter SDK (^3.10.0)
2. Firebase project with Authentication and Realtime Database
3. Supabase project with PostgreSQL database
4. Android/iOS development environment

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Enable Realtime Database
4. Enable Cloud Messaging
5. Download `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
6. Update [firebase_options.dart](lib/firebase_options.dart) with your config

### Supabase Setup
1. Create a project at [supabase.com](https://supabase.com)
2. Run the SQL schema creation commands (see Database Schema section)
3. Update [supabase_config.dart](lib/services/supabase_config.dart) with your credentials:
```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

### Installation
1. Clone the repository
```bash
git clone <repository-url>
cd flutter_application_1
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Database Schema

### Supabase PostgreSQL Tables

The following tables replace the Firebase Realtime Database structure:

#### Users Table
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,  -- Firebase UID
  email TEXT UNIQUE NOT NULL,
  user_name TEXT,
  phone TEXT,
  student_id TEXT,
  branch TEXT,
  semester TEXT,
  hostel TEXT,
  profile_pic_url TEXT,
  dietary_preference TEXT DEFAULT 'Both',
  notifications_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Food Items Table
```sql
CREATE TABLE food_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  category TEXT NOT NULL,
  is_vegetarian BOOLEAN DEFAULT false,
  is_available BOOLEAN DEFAULT true,
  preparation_time INTEGER DEFAULT 15,
  tags TEXT[]
);
```

#### Orders & Order Items
```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  code TEXT NOT NULL,
  qr_code TEXT,
  status TEXT DEFAULT 'pending',
  timestamp BIGINT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(id),
  food_item_id TEXT NOT NULL,
  quantity INTEGER NOT NULL
);
```

#### User Cart
```sql
CREATE TABLE user_cart (
  user_id TEXT NOT NULL REFERENCES users(id),
  food_item_id TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (user_id, food_item_id)
);
```

#### Notifications
```sql
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at_timestamp BIGINT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  data JSONB
);
```

#### Scroll Cards
```sql
CREATE TABLE scroll_cards (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  image TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0
);
```

### Row Level Security (RLS)

All tables have RLS enabled with policies ensuring users can only access their own data:

```sql
-- Example RLS policies
CREATE POLICY "Users can view own data" ON users 
  FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Users can view own orders" ON orders 
  FOR SELECT USING (auth.uid()::text = user_id);
```

## Migration Process

### Step 1: Database Setup
1. Run the complete SQL schema creation commands
2. Enable real-time subscriptions for all tables
3. Set up proper RLS policies

### Step 2: Data Migration
1. Export existing Firebase data
2. Transform and insert into Supabase tables
3. Verify data integrity and relationships

### Step 3: Code Migration
1. Update service classes to use Supabase instead of Firebase Database
2. Replace Firebase listeners with Supabase real-time subscriptions
3. Update data models to match new schema
4. Test all functionality with new database

## Caching Strategy

The app implements multi-layer caching for offline support:

- **User Profile Cache** - `ProfileCacheService`
- **Food Items Cache** - `FoodCacheService`
- **Orders Cache** - `OrderCacheService`
- **Notifications Cache** - `NotificationCacheService`
- **Cart Cache** - Local storage in `CartProvider`

## Notification System

### Types of Notifications
1. **Order Notifications** - Order placement, status updates
2. **Print Notifications** - Print job status changes
3. **Announcements** - Global announcements from admin

### Notification Flow
1. **Local Notifications** - Immediate user notification
2. **Database Storage** - Persistent notification history
3. **Real-time Updates** - Live synchronization across devices

## File Storage

Print documents are stored in Supabase Storage with the following structure:
```
print-documents/
├── {firebase_user_id}/
    ├── {job_id}/
        └── document.pdf
```

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security Considerations

- All sensitive data is protected by Firebase Authentication
- Supabase RLS policies prevent unauthorized data access
- File uploads limited to 10MB PDF files only
- User data isolation through proper foreign key relationships

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Check the [documentation](docs/) folder for detailed guides
- Review the [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for specific setup instructions

---

**Note**: This app is currently migrating from Firebase Realtime Database to Supabase PostgreSQL. Some features may use Firebase during the transition period.

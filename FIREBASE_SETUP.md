# Firebase Setup Instructions

## Required Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  firebase_database: ^10.4.0
```

## Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "Catino")
4. Follow the setup wizard

### 2. Add Android App
1. In Firebase Console, click the Android icon
2. Enter package name: `com.example.flutter_application_1` (or your package name from AndroidManifest.xml)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### 3. Configure Android
In `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

In `android/app/build.gradle`:
```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'  // Add this line
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

### 4. Enable Firebase Services
In Firebase Console:
1. **Authentication**: Enable Email/Password authentication
   - Go to Authentication > Sign-in method
   - Enable Email/Password
   
2. **Realtime Database**: Create database
   - Go to Realtime Database > Create Database
   - Start in test mode (or set custom rules)
   - Copy your database URL

### 5. Update Firebase Config
Edit `lib/config/firebase_config.dart` with your project credentials from Firebase Console > Project Settings:
- API Key
- Project ID
- Database URL
- App ID
- etc.

### 6. Database Rules (Optional but Recommended)
Set these rules in Firebase Console > Realtime Database > Rules:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

### 7. Run Commands
```bash
flutter pub get
flutter run
```

## Testing
1. Run the app
2. Sign up with a new account
3. Check Firebase Console to see the user created in:
   - Authentication > Users
   - Realtime Database > Data

## Troubleshooting
- If build fails, run `flutter clean` then `flutter pub get`
- Make sure `google-services.json` is in the correct location
- Check that all package names match
- Verify Firebase services are enabled in console

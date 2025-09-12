# Caregiver Platform - Flutter App

A complete Flutter application that connects patients/families with caregivers, featuring user authentication, real-time chat, service booking, and payment integration using Appwrite as the backend and Stripe for payments.

## 🚀 Features

- **User Authentication**: Email/password authentication with role-based access (Patient/Family vs. Caregiver)
- **User Profiles**: Comprehensive profile management with image upload
- **Service Discovery**: Search and browse caregivers with filtering options
- **Booking System**: Complete booking workflow with scheduling and service selection
- **Real-time Chat**: In-app messaging between patients and caregivers
- **Payment Integration**: Secure payment processing with Stripe
- **Responsive Design**: Material Design 3 with cross-platform support

## 📱 Screenshots

The app includes the following main screens:
- Authentication (Login, Register, Forgot Password)
- Home Dashboard (role-specific)
- Profile Management
- Caregiver Search & Discovery
- Booking Flow
- Real-time Chat
- Payment Processing

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Appwrite (BaaS)
- **Database**: Appwrite Database
- **Authentication**: Appwrite Account
- **Real-time**: Appwrite Realtime
- **Storage**: Appwrite Storage
- **Payments**: Stripe
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **HTTP Client**: HTTP package

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (3.0.0 or later)
- Dart SDK
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)
- Git

## 🚦 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/zrottmann/caregiver_platform.git
cd caregiver_platform
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Appwrite Setup

#### Create Appwrite Project

1. Go to [Appwrite Cloud](https://cloud.appwrite.io) or set up your own Appwrite instance
2. Create a new project
3. Note down your:
   - Endpoint URL (e.g., `https://cloud.appwrite.io/v1`)
   - Project ID

#### Configure Appwrite Services

##### Enable Required Services
- Account (Authentication)
- Database
- Storage
- Realtime
- Functions (optional, for advanced features)

##### Create Database and Collections

1. Create a database named `caregiver-platform`
2. Create the following collections:

**profiles Collection:**
```json
{
  "collectionId": "profiles",
  "name": "profiles",
  "permissions": ["read", "write"],
  "attributes": [
    {"key": "userId", "type": "string", "size": 255, "required": true},
    {"key": "name", "type": "string", "size": 255, "required": true},
    {"key": "email", "type": "string", "size": 255, "required": true},
    {"key": "role", "type": "string", "size": 50, "required": true},
    {"key": "bio", "type": "string", "size": 1000, "required": false},
    {"key": "location", "type": "string", "size": 255, "required": false},
    {"key": "phoneNumber", "type": "string", "size": 50, "required": false},
    {"key": "profileImageUrl", "type": "string", "size": 500, "required": false},
    {"key": "services", "type": "string", "size": 1000, "required": false, "array": true},
    {"key": "hourlyRate", "type": "double", "required": false},
    {"key": "rating", "type": "double", "required": false},
    {"key": "reviewCount", "type": "integer", "required": false},
    {"key": "createdAt", "type": "datetime", "required": true},
    {"key": "updatedAt", "type": "datetime", "required": true}
  ]
}
```

**bookings Collection:**
```json
{
  "collectionId": "bookings",
  "name": "bookings",
  "permissions": ["read", "write"],
  "attributes": [
    {"key": "patientId", "type": "string", "size": 255, "required": true},
    {"key": "caregiverId", "type": "string", "size": 255, "required": true},
    {"key": "patientName", "type": "string", "size": 255, "required": true},
    {"key": "caregiverName", "type": "string", "size": 255, "required": true},
    {"key": "scheduledDate", "type": "datetime", "required": true},
    {"key": "timeSlot", "type": "string", "size": 100, "required": true},
    {"key": "description", "type": "string", "size": 1000, "required": true},
    {"key": "services", "type": "string", "size": 500, "required": false, "array": true},
    {"key": "totalAmount", "type": "double", "required": true},
    {"key": "status", "type": "string", "size": 50, "required": true},
    {"key": "notes", "type": "string", "size": 1000, "required": false},
    {"key": "paymentIntentId", "type": "string", "size": 255, "required": false},
    {"key": "createdAt", "type": "datetime", "required": true},
    {"key": "updatedAt", "type": "datetime", "required": true}
  ]
}
```

**chats Collection:**
```json
{
  "collectionId": "chats",
  "name": "chats",
  "permissions": ["read", "write"],
  "attributes": [
    {"key": "bookingId", "type": "string", "size": 255, "required": true},
    {"key": "patientId", "type": "string", "size": 255, "required": true},
    {"key": "caregiverId", "type": "string", "size": 255, "required": true},
    {"key": "patientName", "type": "string", "size": 255, "required": true},
    {"key": "caregiverName", "type": "string", "size": 255, "required": true},
    {"key": "createdAt", "type": "datetime", "required": true},
    {"key": "updatedAt", "type": "datetime", "required": true}
  ]
}
```

**messages Collection:**
```json
{
  "collectionId": "messages",
  "name": "messages",
  "permissions": ["read", "write"],
  "attributes": [
    {"key": "chatId", "type": "string", "size": 255, "required": true},
    {"key": "senderId", "type": "string", "size": 255, "required": true},
    {"key": "senderName", "type": "string", "size": 255, "required": true},
    {"key": "content", "type": "string", "size": 2000, "required": true},
    {"key": "type", "type": "string", "size": 50, "required": true},
    {"key": "timestamp", "type": "datetime", "required": true},
    {"key": "isRead", "type": "boolean", "required": false, "default": false}
  ]
}
```

##### Create Storage Bucket
1. Go to Storage in your Appwrite console
2. Create a bucket named `profile-images`
3. Set appropriate permissions for read/write access

#### Update Configuration
1. Open `lib/config/app_config.dart`
2. Replace the placeholder values:

```dart
static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1'; // Your endpoint
static const String appwriteProjectId = 'your-actual-project-id'; // Your project ID
```

### 4. Stripe Setup

#### Get Stripe Keys
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Get your publishable and secret keys
3. Update `lib/config/app_config.dart`:

```dart
static const String stripePublishableKey = 'pk_test_your_actual_publishable_key';
static const String stripeSecretKey = 'sk_test_your_actual_secret_key';
```

#### Configure Stripe (iOS)
Add to `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>stripe</string>
</array>
```

#### Configure Stripe (Android)
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name="com.stripe.android.PaymentAuthWebViewActivity"
    android:exported="false"
    android:theme="@style/Theme.Stripe.PaymentAuthWebView" />
```

### 5. Platform Configuration

#### Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- For web auth redirect -->
<activity
    android:name="io.appwrite.views.CallbackActivity"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="appwrite-callback-[PROJECT_ID]" />
    </intent-filter>
</activity>
```

Replace `[PROJECT_ID]` with your actual Appwrite project ID.

#### iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take profile photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select profile photos</string>

<!-- For web auth redirect -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.appwrite.callback</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>appwrite-callback-[PROJECT_ID]</string>
        </array>
    </dict>
</array>
```

### 6. Run the App

```bash
# For debug mode
flutter run

# For release mode
flutter run --release

# For specific platform
flutter run -d android
flutter run -d ios
```

## 🧪 Testing

### Create Test Users

1. Run the app
2. Register as a Patient/Family member:
   - Email: `patient@example.com`
   - Password: `password123`
   - Role: Patient/Family

3. Register as a Caregiver:
   - Email: `caregiver@example.com`
   - Password: `password123`
   - Role: Caregiver

### Test Scenarios

1. **Authentication Flow**:
   - Register new users
   - Login/logout
   - Password reset

2. **Profile Management**:
   - Complete profile information
   - Upload profile images
   - Update services (for caregivers)

3. **Booking Flow**:
   - Search for caregivers
   - Create a booking
   - Process payment (use Stripe test cards)
   - View booking details

4. **Chat System**:
   - Start a chat after booking
   - Send/receive messages
   - Real-time updates

### Stripe Test Cards

Use these test card numbers for payment testing:
- **Success**: 4242 4242 4242 4242
- **Decline**: 4000 0000 0000 0002
- **3D Secure**: 4000 0000 0000 3220

## 📁 Project Structure

```
lib/
├── config/
│   └── app_config.dart          # Configuration constants
├── models/
│   ├── user_profile.dart        # User profile model
│   ├── booking.dart             # Booking model
│   └── chat_message.dart        # Chat models
├── services/
│   ├── appwrite_service.dart    # Appwrite SDK setup
│   ├── auth_service.dart        # Authentication logic
│   ├── profile_service.dart     # Profile management
│   ├── booking_service.dart     # Booking operations
│   ├── chat_service.dart        # Chat functionality
│   └── payment_service.dart     # Stripe integration
├── providers/
│   ├── auth_provider.dart       # Auth state management
│   ├── caregiver_provider.dart  # Caregiver search
│   ├── booking_provider.dart    # Booking state
│   └── chat_provider.dart       # Chat state
├── screens/
│   ├── auth/                    # Authentication screens
│   ├── home/                    # Home dashboard
│   ├── profile/                 # Profile management
│   ├── search/                  # Caregiver search
│   ├── booking/                 # Booking flow
│   ├── chat/                    # Chat screens
│   └── payment/                 # Payment processing
├── widgets/
│   ├── bottom_nav_bar.dart      # Navigation component
│   └── caregiver_card.dart      # Caregiver display
├── router/
│   └── app_router.dart          # Navigation routing
└── main.dart                    # App entry point
```

## 🔧 Customization

### Branding
1. Update app name in `pubspec.yaml`
2. Replace app icons in `assets/icons/`
3. Update color scheme in `main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF2196F3), // Your brand color
),
```

### Features
- Add new services in caregiver profiles
- Implement additional payment methods
- Add review/rating system
- Implement push notifications
- Add video calling functionality

## 🚢 Deployment

### Android (Google Play Store)
1. Update `android/app/build.gradle` with release configuration
2. Generate release keystore
3. Build release APK: `flutter build apk --release`
4. Or build App Bundle: `flutter build appbundle --release`

### iOS (App Store)
1. Update `ios/Runner.xcodeproj` with release configuration
2. Build for iOS: `flutter build ios --release`
3. Archive and upload via Xcode

### Web
1. Build for web: `flutter build web --release`
2. Deploy to your preferred hosting service

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues:

1. Check the [Appwrite Documentation](https://appwrite.io/docs)
2. Check the [Stripe Documentation](https://stripe.com/docs)
3. Review Flutter documentation
4. Open an issue in this repository

## 🙏 Acknowledgments

- [Appwrite](https://appwrite.io) for the excellent BaaS platform
- [Stripe](https://stripe.com) for secure payment processing
- [Flutter](https://flutter.dev) team for the amazing framework
- Material Design for the beautiful UI components

---

**Note**: This is a demonstration app. For production use, ensure you:
- Implement proper error handling
- Add comprehensive testing
- Set up CI/CD pipelines
- Implement proper logging and monitoring
- Review and enhance security measures
- Comply with healthcare regulations if applicable
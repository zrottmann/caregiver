# Deployment Guide

This guide covers deploying the Caregiver Platform app to production environments.

## 📋 Pre-Deployment Checklist

### Code Quality
- [ ] All features tested thoroughly
- [ ] Error handling implemented
- [ ] Loading states for all async operations
- [ ] Proper input validation
- [ ] No hardcoded secrets or keys
- [ ] Code reviewed and optimized

### Security
- [ ] API keys properly configured
- [ ] Permissions set correctly in Appwrite
- [ ] Input sanitization implemented
- [ ] Rate limiting configured
- [ ] HTTPS enforced

### Performance
- [ ] Images optimized
- [ ] Bundle size analyzed
- [ ] Database queries optimized
- [ ] Caching implemented where appropriate
- [ ] Error boundaries in place

## 🌐 Production Configuration

### 1. Update App Configuration

**Update `lib/config/app_config.dart`:**
```dart
class AppConfig {
  // Production Appwrite Configuration
  static const String appwriteEndpoint = 'https://your-production-appwrite-endpoint/v1';
  static const String appwriteProjectId = 'your-production-project-id';
  
  // Production Stripe Configuration
  static const String stripePublishableKey = 'pk_live_your_production_publishable_key';
  
  // Remove or comment out development/test keys
  // static const String stripeSecretKey = 'sk_test_...'; // Never commit live secret keys!
}
```

### 2. Environment-Specific Builds

Create different build flavors:

**android/app/build.gradle:**
```gradle
android {
    ...
    flavorDimensions "default"
    productFlavors {
        dev {
            dimension "default"
            applicationId "com.yourcompany.caregiverplatform.dev"
            versionNameSuffix "-dev"
        }
        staging {
            dimension "default"
            applicationId "com.yourcompany.caregiverplatform.staging"
            versionNameSuffix "-staging"
        }
        prod {
            dimension "default"
            applicationId "com.yourcompany.caregiverplatform"
        }
    }
}
```

## 📱 Android Deployment

### 1. Prepare Release Build

**Generate Keystore:**
```bash
keytool -genkey -v -keystore ~/caregiver-platform-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias caregiver-platform
```

**Create `android/key.properties`:**
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=caregiver-platform
storeFile=../caregiver-platform-key.jks
```

**Update `android/app/build.gradle`:**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. Build Release APK/AAB

```bash
# Build APK
flutter build apk --release --flavor prod

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release --flavor prod
```

### 3. Google Play Store Deployment

1. **Create Google Play Console Account**
   - Go to [Google Play Console](https://play.google.com/console)
   - Pay one-time $25 registration fee

2. **Create Application**
   - Click "Create app"
   - Fill in app details
   - Set content rating
   - Add store listing information

3. **Upload Release**
   - Go to "Release" → "Production"
   - Upload AAB file
   - Fill in release notes
   - Roll out to 100% of users

4. **Store Listing**
   - Add screenshots (phone, tablet, tablet 7", tablet 10")
   - Write compelling description
   - Add feature graphic
   - Set category and tags

## 🍎 iOS Deployment

### 1. Configure Xcode Project

**Update `ios/Runner/Info.plist`:**
```xml
<dict>
    <key>CFBundleDisplayName</key>
    <string>Caregiver Platform</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.caregiverplatform</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <!-- Add other required keys -->
</dict>
```

### 2. Build iOS Release

```bash
flutter build ios --release
```

### 3. App Store Deployment

1. **Apple Developer Account**
   - Enroll in Apple Developer Program ($99/year)
   - Create App ID in Developer Portal

2. **Xcode Configuration**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select your development team
   - Configure signing & capabilities

3. **Create App Store Connect Record**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Create new app
   - Fill in app information

4. **Archive and Upload**
   - In Xcode: Product → Archive
   - Upload to App Store Connect
   - Submit for review

## 🌍 Web Deployment

### 1. Build Web Release

```bash
flutter build web --release --web-renderer canvaskit
```

### 2. Hosting Options

#### Netlify Deployment
1. Connect your GitHub repository
2. Set build command: `flutter build web --release`
3. Set publish directory: `build/web`
4. Deploy automatically on push

#### Vercel Deployment
```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "framework": null
}
```

#### Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

#### Custom Server (Nginx)
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/build/web;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
```

## 🔒 Security Hardening

### 1. API Security

**Production Appwrite Setup:**
```javascript
// Set production permissions
await databases.updateCollection(
  'caregiver-platform',
  'profiles',
  undefined,
  [
    Permission.read(Role.any()),
    Permission.write(Role.user('[USER_ID]'))
  ]
);
```

### 2. Environment Variables

Never commit sensitive information. Use:
- GitHub Secrets for CI/CD
- App Store Connect API keys
- Google Play Console service accounts

### 3. Code Obfuscation

Enable code obfuscation for release builds:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

## 📊 Monitoring & Analytics

### 1. Crashlytics Setup

**Add to `pubspec.yaml`:**
```yaml
dependencies:
  firebase_crashlytics: ^3.4.8
  firebase_analytics: ^10.7.4
```

**Initialize in `main.dart`:**
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}
```

### 2. Performance Monitoring

Add Firebase Performance:
```yaml
dependencies:
  firebase_performance: ^0.9.3+8
```

### 3. User Analytics

Track user behavior:
```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'booking_created',
  parameters: {
    'caregiver_id': caregiverId,
    'total_amount': totalAmount,
  },
);
```

## 🚀 CI/CD Pipeline

### GitHub Actions Example

**.github/workflows/deploy.yml:**
```yaml
name: Deploy to Stores

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
          packageName: com.yourcompany.caregiverplatform
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Build and upload to App Store
        run: |
          cd ios
          xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release archive -archivePath build/Runner.xcarchive
          xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/
```

## 📈 Post-Deployment Monitoring

### 1. Health Checks

Monitor key metrics:
- App crash rate (< 1%)
- App load time (< 3 seconds)
- API response times (< 500ms)
- User retention rates

### 2. User Feedback

Set up feedback channels:
- In-app feedback form
- App store reviews monitoring
- Customer support integration

### 3. Performance Monitoring

Use tools like:
- Firebase Performance Monitoring
- New Relic Mobile
- Sentry for error tracking

## 🔄 Rollback Strategy

### Emergency Rollback Plan

1. **App Stores:**
   - Use staged rollout (start with 5% users)
   - Monitor crash rates and user feedback
   - Halt rollout if issues detected

2. **Backend Changes:**
   - Keep previous Appwrite configuration backed up
   - Have database migration rollback scripts ready
   - Monitor API error rates

3. **Hot Fixes:**
   - Prepare patches for critical bugs
   - Use code push for React Native equivalents
   - Consider feature flags for instant toggles

## 📞 Support

### Production Support Checklist

- [ ] 24/7 monitoring set up
- [ ] Error alerting configured
- [ ] Support team trained
- [ ] Documentation updated
- [ ] Backup systems tested
- [ ] Disaster recovery plan ready

Remember: Always test thoroughly in staging environments before production deployment!
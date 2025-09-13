# iOS Native Deployment Setup

## Prerequisites

### 1. Apple Developer Account
- Enroll in the Apple Developer Program ($99/year)
- Sign in to [Apple Developer Console](https://developer.apple.com/)

### 2. Xcode Setup
- Install Xcode from Mac App Store
- Install Xcode Command Line Tools: `xcode-select --install`
- Open Xcode and accept license agreements

### 3. App Store Connect
- Create app record in [App Store Connect](https://appstoreconnect.apple.com/)
- Bundle ID: `com.christycares.app`
- App Name: "Christy Cares"

## Quick Setup

### 1. Bundle Identifier
Your app is already configured with:
- Bundle ID: `com.christycares.app`
- Display Name: "Christy Cares"

### 2. Build and Deploy

**For Development/Testing:**
```bash
./deploy-ios.sh
```

**For App Store Release:**
```bash
./deploy-ios.sh release
```

**Manual Flutter Build:**
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

### 3. Run on iOS Simulator
```bash
flutter run -d ios
```

### 4. Run on Physical Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d [device-id]
```

## App Store Deployment

### 1. Manual Upload via Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" or your connected device
3. Product → Archive
4. Upload to App Store Connect

### 2. Command Line Upload
```bash
# After running ./deploy-ios.sh release
xcrun altool --upload-app \
  --type ios \
  --file ios/build/Runner.ipa \
  --username YOUR_APPLE_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD \
  --asc-provider YOUR_TEAM_ID
```

### 3. Automated GitHub Actions
The app is configured with GitHub Actions for automatic TestFlight deployment.

**Required GitHub Secrets:**
- `APPLE_ID`: Your Apple ID email
- `APPLE_ID_PASSWORD`: App-specific password
- `APPLE_TEAM_ID`: Your Apple Developer Team ID

## Permissions Configured

The app is pre-configured with these iOS permissions:
- Camera access (profile photos)
- Photo library access (profile photos)
- Location access (find nearby caregivers)
- Contacts access (share caregiver info)
- Calendar access (appointment scheduling)
- Reminders access (appointment reminders)
- Microphone access (video calls)

## Security Features

- App Transport Security configured for Appwrite Cloud
- Deep linking support for authentication callbacks
- Background modes for push notifications
- Secure network communication

## Troubleshooting

### TLS Certificate Errors
- Fixed: App now uses proper Appwrite Cloud endpoint
- No self-signed certificate issues

### Missing Xcode Project
- Fixed: Complete iOS project generated with proper structure
- All necessary files and configurations included

### Bundle Identifier Issues
- Configured: `com.christycares.app` across all build configurations
- TestFlight ready with proper signing configuration

## Next Steps

1. **Apple Developer Setup**: Create certificates and provisioning profiles
2. **App Store Connect**: Configure app metadata, screenshots, descriptions
3. **TestFlight**: Upload first build for internal testing
4. **App Review**: Submit for App Store review when ready

Your iOS app is now ready for native iPhone deployment! 🚀📱
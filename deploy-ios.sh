#!/bin/bash

# Christy Cares iOS Deployment Script
echo "🍎 Building Christy Cares for iOS..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ This script must be run on macOS to build iOS apps"
  exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
  echo "❌ Xcode is not installed. Please install Xcode from the App Store."
  exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter is not installed. Please install Flutter first."
  exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
cd ios && rm -rf build/ && cd ..

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Install iOS dependencies
echo "📱 Installing iOS pods..."
cd ios
pod install --repo-update
cd ..

# Build for iOS
BUILD_TYPE=${1:-debug}

if [ "$BUILD_TYPE" = "release" ]; then
  echo "🚀 Building iOS release..."
  flutter build ios --release

  echo "📦 Creating iOS archive..."
  cd ios

  # Create export options for App Store
  cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
EOF

  # Archive
  xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination generic/platform=iOS \
    -archivePath build/Runner.xcarchive \
    archive

  # Export IPA
  xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportPath build/ \
    -exportOptionsPlist ExportOptions.plist

  echo "✅ iOS release build complete! Check ios/build/ for the IPA file."
  echo "📤 You can now upload to TestFlight via App Store Connect or use:"
  echo "   xcrun altool --upload-app --type ios --file ios/build/Runner.ipa --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD"

else
  echo "🔧 Building iOS debug..."
  flutter build ios --debug --no-codesign
  echo "✅ iOS debug build complete!"
  echo "📱 You can now run: flutter run -d ios or open ios/Runner.xcworkspace in Xcode"
fi

echo ""
echo "🎉 Build completed successfully!"
echo "Bundle Identifier: com.christycares.app"
echo "Display Name: Christy Cares"
#!/bin/bash

# Simulator UDID
SIMULATOR_ID="D0DEDDFA-CCBF-4A68-8B69-274DAA9D8AD9"
APP_BUNDLE_ID="xyz.gians.FitTimer"

# echo "Building project..."
xcodebuild clean build -scheme FitTimer -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -configuration Debug -derivedDataPath build/

# echo "Booting simulator..."
# xcrun simctl boot $SIMULATOR_ID 2>/dev/null || true

# Open Simulator app
# echo "Opening Simulator..."
# open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/

# Wait a few seconds for simulator to fully boot
# sleep 3

# Install the app
echo "Installing app..."
xcrun simctl install $SIMULATOR_ID "build/Build/Products/Debug-iphonesimulator/FitTimer.app"

# Launch the app
echo "Launching app..."
xcrun simctl launch $SIMULATOR_ID $APP_BUNDLE_ID

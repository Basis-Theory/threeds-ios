#!/bin/bash

set -eo pipefail

{
    cat <<EOT > ./ThreeDSTester/Env.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>btApiKey</key>
    <string>${DEV_BT_API_KEY}</string>
</dict>
</plist>
EOT
} || { echo "Error: Failed to create Env.plist"; exit 1; }

echo "Booting Simulator"

SIMULATOR_UUID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep -oE '[0-9A-F-]{36}' | head -n 1) || echo "none"

xcrun simctl boot $SIMULATOR_UUID

echo "Building ThreeDS Library"

if ! xcrun xcodebuild -scheme 'ThreeDS' \
    -project 'ThreeDS/ThreeDS.xcodeproj' \
    -configuration Debug \
    -sdk 'iphonesimulator' \
    -destination platform="iOS Simulator,id=${SIMULATOR_UUID}" \
    -derivedDataPath ThreeDS/.build \
    | xcpretty; then
    echo "Error: xcodebuild failed"
    exit 1
fi

echo "Building ThreeDSTester app"

if ! xcrun xcodebuild -scheme 'ThreeDSTester' \
    -project 'ThreeDSTester/ThreeDSTester.xcodeproj' \
    -configuration Debug \
    -sdk 'iphonesimulator' \
    -destination platform="iOS Simulator,id=${SIMULATOR_UUID}" \
    -derivedDataPath .build \
    | xcpretty; then
    echo "Error: xcodebuild failed"
    exit 1
fi

xcrun simctl install $SIMULATOR_UUID .build/Build/Products/Debug-iphonesimulator/ThreeDSTester.app

echo "Running maestro tests on device: $SIMULATOR_UUID"

export MAESTRO_CLI_NO_ANALYTICS=1
export MAESTRO_DRIVER_STARTUP_TIMEOUT=240000
if ! maestro --device $SIMULATOR_UUID test --format=junit .maestro/tests; then
    echo "Error: Maestro tests failed"
    exit 1
fi


echo "All operations completed successfully."

exit 0
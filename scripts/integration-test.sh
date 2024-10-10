#!/bin/bash

set -eo pipefail

{
cat <<EOT > ./ThreeDSTester/Env.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
   <dict>
        <key>btPubApiKey</key>
        <string>${BT_API_KEY_PUB}</string>
   </dict>
</plist>
EOT
} || { echo "Error: Failed to create Env.plist"; exit 1; }

echo "Booting Simulator"

SIMULATOR_UUID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep -oE '[0-9A-F-]{36}' | head -n 1) || echo "none"

xcrun simctl boot $SIMULATOR_UUID


echo "Building ThreeDS Library"

xcrun xcodebuild -scheme 'ThreeDS' \
    -project 'ThreeDS/ThreeDS.xcodeproj' \
    -configuration Debug \
    -sdk 'iphonesimulator' \
    -destination platform="iOS Simulator,id=${SIMULATOR_UUID}" \
    -derivedDataPath ThreeDS/.build 


echo "Building ThreeDSTester app"

xcrun xcodebuild -scheme 'ThreeDSTester' \
    -project 'ThreeDSTester/ThreeDSTester.xcodeproj' \
    -configuration Debug \
    -sdk 'iphonesimulator' \
    -destination platform="iOS Simulator,id=${SIMULATOR_UUID}" \
    -derivedDataPath .build

xcrun simctl install $SIMULATOR_UUID .build/Build/Products/Debug-iphonesimulator/ThreeDSTester.app

echo "Starting dev server"

make start-dev-server

echo "Running maestro tests on device: $SIMULATOR_UUID"

export MAESTRO_CLI_NO_ANALYTICS=1
export MAESTRO_DRIVER_STARTUP_TIMEOUT=240000
if ! maestro --device $SIMULATOR_UUID test .maestro/tests; then
    echo "Error: Maestro tests failed"
    exit 1
fi


echo "All operations completed successfully."

exit 0
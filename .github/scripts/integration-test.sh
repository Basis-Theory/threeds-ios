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


echo "Building ThreeDS Library"

if ! xcrun xcodebuild -scheme 'ThreeDS' \
    -project 'ThreeDS/ThreeDS.xcodeproj' \
    -configuration Debug \
    -sdk 'iphonesimulator' \
    -destination platform="iOS Simulator,OS=18.0,name=iPhone 16 Pro" \
    -derivedDataPath ThreeDS/.build \
    | xcpretty; then
    echo "Error: xcodebuild failed"
    exit 1
fi

echo "Building ThreeDSTester"

if ! xcrun xcodebuild -scheme 'ThreeDSTester' \
    -project 'ThreeDSTester/ThreeDSTester.xcodeproj' \
    -configuration Debug \
    -sdk 'iphonesimulator' \
    -destination platform="iOS Simulator,OS=18.0,name=iPhone 16 Pro" \
    -derivedDataPath .build \
    | xcpretty; then
    echo "Error: xcodebuild failed"
    exit 1
fi

echo "Running maestro tests"

if ! maestro test .maestro/tests; then
    echo "Error: Maestro tests failed"
    exit 1
fi

echo "All operations completed successfully."

exit 0
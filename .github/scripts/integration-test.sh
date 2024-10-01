#!/bin/bash

set -eo pipefail

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

xcrun xcodebuild -scheme 'ThreeDSTester' \
-project 'ThreeDSTester/ThreeDSTester.xcodeproj' \
-configuration Debug \
-sdk 'iphonesimulator' \
-destination platform="iOS Simulator,OS=18.0,name=iPhone 14 Pro" \
-derivedDataPath build
| xcpretty

booted_device_id=$(xcrun simctl list devices booted | grep -oE "[A-F0-9-]{36}")

xcrun simctl install $booted_device_id build/Build/Products/Debug-iphonesimulator/ThreeDSTester.app

maestro --device $booted_device_id test .maestro/tests
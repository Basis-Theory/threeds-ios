#!/bin/bash

set -eo pipefail

cat <<EOT > ./ThreeDsTester/Env.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>btApiKey</key>
	<string>${DEV_BT_API_KEY}</string>
</dict>
</plist>
EOT

xcodebuild clean test \
    -project ./ThreeDsTester/ThreeDsTester.xcodeproj \
    -scheme ThreeDsTester \
    -configuration Debug \
    -destination platform="iOS Simulator,OS=17.5,name=iPhone 14 Pro" \
    | xcpretty

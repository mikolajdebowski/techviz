#!/usr/bin/env bash

//change Runner/Info.plist CFBundleVersion and CFBundleShortVersionString

flutter clean

flutter analyze

flutter test

flutter build ios

xcodebuild -workspace ios/Runner.xcworkspace \
            -scheme Runner -sdk iphoneos \
            -configuration Release archive \
            -archivePath ios/Temp/Build/VersionXBuildY.xcarchive

xcodebuild -exportArchive \
            -archivePath ios/Temp/Build/VersionXBuildY.xcarchive \
            -exportOptionsPlist ios/Runner/exportOptionsAdHoc.plist -exportPath ios/Temp/Build/VersionXBuildY
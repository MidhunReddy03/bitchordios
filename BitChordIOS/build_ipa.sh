#!/bin/bash
set -e

echo "=== Building BitChord for iOS (iPhone 13 / iOS 27) ==="

# 1. Clean build directory
rm -rf build BitChordIOS.xcarchive Payload BitChord.ipa

# 2. Archive without code signing (ready for sideloading/AltStore/TrollStore)
xcodebuild archive \
  -project BitChordIOS.xcodeproj \
  -scheme BitChordIOS \
  -destination "generic/platform=iOS" \
  -archivePath BitChordIOS.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  AD_HOC_CODE_SIGNING_ALLOWED=YES

# 3. Create Payload folder and package into .ipa
mkdir -p Payload
cp -r BitChordIOS.xcarchive/Products/Applications/BitChordIOS.app Payload/
zip -qr BitChord.ipa Payload

# 4. Clean up temporary payload folder
rm -rf Payload

echo "=== Successfully built: BitChord.ipa ==="
echo "You can now install BitChord.ipa using AltStore, SideStore, Sideloadly, or TrollStore."


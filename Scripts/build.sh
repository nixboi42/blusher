#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
xcodegen generate
xcodebuild -project Blusher.xcodeproj -scheme BlusherLocal -configuration Release -derivedDataPath DerivedData build
xcodebuild -project Blusher.xcodeproj -scheme BlusherLocal -configuration Debug -derivedDataPath DerivedData build-for-testing
mkdir -p dist
ditto DerivedData/Build/Products/Release/Blusher.app dist/Blusher.app
ditto -c -k --sequesterRsrc --keepParent dist/Blusher.app dist/Blusher-0.1.0-preview.zip

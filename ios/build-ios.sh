#!/bin/bash
# Build PvZ-Portable for iOS.
# Usage: ./ios/build-ios.sh [Debug|Release]
# Requires: Xcode 15+ with iOS SDK, CMake 3.21+, vcpkg
# VCPKG_ROOT must be set to the vcpkg installation directory.

set -euo pipefail

BUILD_TYPE="${1:-Release}"
case "$BUILD_TYPE" in
    Debug|Release) ;;
    *) echo "Error: configuration must be Debug or Release"; exit 1 ;;
esac
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-ios"

echo "=== WanZi Family iOS Build ($BUILD_TYPE) ==="

if [ -z "${VCPKG_ROOT:-}" ]; then
    echo "Error: VCPKG_ROOT is not set. Install vcpkg and set VCPKG_ROOT."
    exit 1
fi

IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)
if [ -z "$IOS_SDK" ]; then
    echo "Error: iOS SDK not found. Install full Xcode and select its developer directory."
    exit 1
fi

mkdir -p "$BUILD_DIR"

# Build game (vcpkg handles all dependencies via manifest mode)
echo "--- Building PvZ-Portable ---"
cmake -B "$BUILD_DIR/game" -S "$PROJECT_ROOT" \
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_OVERLAY_TRIPLETS="$PROJECT_ROOT/CMake/triplets" \
    -DVCPKG_TARGET_TRIPLET=arm64-ios \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.4 \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DPVZ_DEBUG=OFF \
    -DDO_FIX_BUGS=OFF \
    -G Xcode

cmake --build "$BUILD_DIR/game" --config "$BUILD_TYPE" -- \
    -sdk iphoneos \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=NO

# Create unsigned IPA
APP_PATH="$BUILD_DIR/game/$BUILD_TYPE-iphoneos/pvz-portable.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Error: expected .app bundle missing: $APP_PATH"
    exit 1
fi
plutil -lint "$APP_PATH/Info.plist"
IPA_DIR=$(mktemp -d "$BUILD_DIR/package.XXXXXX")
trap 'rm -rf "$IPA_DIR"' EXIT
mkdir -p "$IPA_DIR/Payload"
cp -R "$APP_PATH" "$IPA_DIR/Payload/"
IPA_PATH="$BUILD_DIR/wanzi-family-ios-arm64-unsigned.ipa"
# Remove the previous archive so zip never retains files from an earlier build.
rm -f "$IPA_PATH"
(cd "$IPA_DIR" && zip -q -r -y "$IPA_PATH" Payload/)
(cd "$BUILD_DIR" && shasum -a 256 "$(basename "$IPA_PATH")" > SHA256SUMS.txt)
printf 'sourceRevision=%s\nconfiguration=%s\nplatform=iPhone/iPad arm64\nminimumOS=16.4\nsigned=false\n' \
    "$(git -C "$PROJECT_ROOT" rev-parse HEAD)" "$BUILD_TYPE" > "$BUILD_DIR/build-info.txt"
echo "Unsigned IPA created: $IPA_PATH"

echo "=== iOS Build Complete ==="

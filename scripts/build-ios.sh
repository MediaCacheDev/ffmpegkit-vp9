#!/bin/bash
#
# build-ios.sh
# Builds the minimal VP9 FFmpegKit (see common.sh for what's in it) as XCFrameworks into
# dist/ios/Frameworks.
#
# They are dynamic frameworks: ffmpeg-kit always builds FFmpeg shared on Apple platforms. That
# suits the LGPL, since an app's users can swap them. Apps embed them (CocoaPods does this).
#
# Slices: iOS device arm64, simulator arm64 + x86_64. CLEAN=1 starts from scratch.
#

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

BUILD_DIR="$BUILD_ROOT/ios"
OUTPUT_DIR="$DIST_DIR/ios/Frameworks"

echo "========================================"
echo "Building ffmpegkit-vp9 $FFMPEGKIT_VP9_VERSION for iOS"
echo "========================================"
echo "Build dir : $BUILD_DIR"
echo ""

if ! xcode-select -p &> /dev/null; then
    echo "❌ Xcode command line tools not found"
    echo "   Run: xcode-select --install"
    exit 1
fi

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

checkout_ffmpeg_kit
cd ffmpeg-kit

if [ "${CLEAN:-0}" = "1" ]; then
    clean_build
fi

apply_minimal_config apple
write_source_notice apple

echo "🔨 Building (see $BUILD_DIR/ffmpeg-kit/build.log)..."

./ios.sh \
  --enable-libvpx \
  --disable-armv7 \
  --disable-armv7s \
  --disable-arm64e \
  --disable-arm64-mac-catalyst \
  --disable-x86-64-mac-catalyst \
  --xcframework

FRAMEWORK_DIR="prebuilt/bundle-apple-xcframework-ios"

FRAMEWORKS=(
    "ffmpegkit.xcframework"
    "libavcodec.xcframework"
    "libavformat.xcframework"
    "libavutil.xcframework"
    "libswresample.xcframework"
    "libswscale.xcframework"
    "libavfilter.xcframework"
    "libavdevice.xcframework"
)

if [ ! -d "$FRAMEWORK_DIR" ]; then
    echo "❌ Build output not found: $FRAMEWORK_DIR"
    find prebuilt -name "*.xcframework" -type d 2>/dev/null | head -20
    exit 1
fi

rm -rf "$OUTPUT_DIR"/*.xcframework
for fw in "${FRAMEWORKS[@]}"; do
    if [ ! -d "$FRAMEWORK_DIR/$fw" ]; then
        echo "❌ Missing: $fw"
        exit 1
    fi
    cp -R "$FRAMEWORK_DIR/$fw" "$OUTPUT_DIR/"
done

echo ""
echo "✅ $OUTPUT_DIR ($(du -sh "$OUTPUT_DIR" | cut -f1))"
ls -1 "$OUTPUT_DIR"

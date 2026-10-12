#!/bin/bash
#
# build-android.sh
# Builds the minimal VP9 FFmpegKit AAR (see common.sh for what's in it) into
# dist/android/ffmpegkit-vp9.aar, where publish-android.sh picks it up.
#
# Uses the newest installed NDK; r28+ links 16 KB-page-aligned by default, which the script
# checks at the end. Override with FFMPEGKIT_NDK_HOME. CLEAN=1 starts from scratch.
#

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

BUILD_DIR="$BUILD_ROOT/android"
OUTPUT_DIR="$DIST_DIR/android"
AAR_OUT="$OUTPUT_DIR/ffmpegkit-vp9.aar"

if [ -z "${ANDROID_SDK_ROOT:-}" ]; then
    if [ -n "${ANDROID_HOME:-}" ]; then
        export ANDROID_SDK_ROOT="$ANDROID_HOME"
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    elif [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
    fi
fi

if [ -z "${ANDROID_SDK_ROOT:-}" ] || [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "❌ Android SDK not found"
    echo "   Set ANDROID_SDK_ROOT to your SDK installation path"
    exit 1
fi

# ANDROID_NDK_HOME is often pinned to an older NDK for other projects, so it isn't used here.
if [ -n "${FFMPEGKIT_NDK_HOME:-}" ]; then
    ANDROID_NDK_HOME="$FFMPEGKIT_NDK_HOME"
elif [ -d "$ANDROID_SDK_ROOT/ndk" ]; then
    ANDROID_NDK_HOME="$ANDROID_SDK_ROOT/ndk/$(ls "$ANDROID_SDK_ROOT/ndk" | sort -V | tail -1)"
else
    ANDROID_NDK_HOME=""
fi
export ANDROID_NDK_HOME

if [ -z "${ANDROID_NDK_HOME:-}" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "❌ Android NDK not found"
    echo "   Install one with the SDK manager, or set FFMPEGKIT_NDK_HOME"
    exit 1
fi

# FFmpegKit uses ANDROID_NDK_ROOT instead of ANDROID_NDK_HOME
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"

echo "========================================"
echo "Building ffmpegkit-vp9 $FFMPEGKIT_VP9_VERSION for Android"
echo "========================================"
echo "SDK: $ANDROID_SDK_ROOT"
echo "NDK: $ANDROID_NDK_HOME"
echo "Build dir: $BUILD_DIR"
echo ""

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

checkout_ffmpeg_kit
cd ffmpeg-kit

if [ "${CLEAN:-0}" = "1" ]; then
    clean_build
fi

# Newer NDKs turn some of ffmpeg-kit's warnings into errors.
git checkout -q -- android/jni/Android.mk
sed -i '' 's/-Werror/-Wno-error/g' android/jni/Android.mk

apply_minimal_config android
write_source_notice android

echo "🔨 Building (30-60 minutes from scratch; see $BUILD_DIR/ffmpeg-kit/build.log)..."

# x86 (32-bit) is emulator-only and rarely used.
./android.sh \
    --enable-libvpx \
    --disable-x86

AAR_PATH="prebuilt/bundle-android-aar/ffmpeg-kit/ffmpeg-kit.aar"
if [ ! -f "$AAR_PATH" ]; then
    echo "❌ Build output not found: $AAR_PATH"
    find prebuilt -name "*.aar" -type f 2>/dev/null | head -10
    exit 1
fi
cp "$AAR_PATH" "$AAR_OUT"

echo ""
echo "🔍 Checking 16 KB page alignment of the 64-bit libraries..."
READELF="$(ls "$ANDROID_NDK_HOME"/toolchains/llvm/prebuilt/*/bin/llvm-readelf | head -1)"
CHECK_DIR="$(mktemp -d)"
unzip -q "$AAR_OUT" 'jni/arm64-v8a/*' 'jni/x86_64/*' -d "$CHECK_DIR"
MISALIGNED=0
for so in "$CHECK_DIR"/jni/*/*.so; do
    if "$READELF" -lW "$so" | awk '$1 == "LOAD" { print $NF }' | grep -qv '0x4000'; then
        echo "  ❌ $(basename "$(dirname "$so")")/$(basename "$so")"
        MISALIGNED=1
    fi
done
rm -rf "$CHECK_DIR"
if [ "$MISALIGNED" = 1 ]; then
    echo "Some libraries are not 16 KB aligned; build with NDK r28 or newer."
    exit 1
fi
echo "  ✔ all aligned"

echo ""
echo "✅ $AAR_OUT ($(du -h "$AAR_OUT" | cut -f1))"

#!/bin/bash
#
# package-release.sh
# Collects everything the GitHub Release for this version carries into dist/release/:
#
#   ffmpegkit-vp9-<version>.aar                  the Android AAR (same file as on Maven Central)
#   ffmpegkit-vp9-<version>-ios-xcframeworks.zip  the iOS XCFrameworks (Frameworks/*.xcframework)
#   ffmpeg-kit-<commit>.tar.gz                    ffmpeg-kit at the pinned commit
#   ffmpeg-n6.0.tar.gz                            FFmpeg as ffmpeg-kit fetched it (arthenica/FFmpeg)
#   libvpx-v1.13.0.tar.gz                         libvpx as ffmpeg-kit fetched it (arthenica/libvpx)
#   cpu-features-v0.8.0.tar.gz                    cpu_features as ffmpeg-kit fetched it (Android only)
#   ffmpegkit-vp9-<version>-scripts.tar.gz        this repo's scripts and licences
#   SHA256SUMS
#
# The source tarballs are the complete corresponding source (LGPL-3.0 section 4): ffmpeg-kit's
# scripts patch FFmpeg at build time, so the pristine trees plus ffmpeg-kit plus these scripts
# reproduce the binaries. Run after build-android.sh and build-ios.sh.
#

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

KIT_DIR="$BUILD_ROOT/android/ffmpeg-kit"
AAR="$DIST_DIR/android/ffmpegkit-vp9.aar"
FRAMEWORKS="$DIST_DIR/ios/Frameworks"
OUT="$DIST_DIR/release"

for required in "$KIT_DIR/src/ffmpeg" "$AAR" "$FRAMEWORKS/ffmpegkit.xcframework"; do
    if [ ! -e "$required" ]; then
        echo "❌ Missing $required; run build-android.sh and build-ios.sh first"
        exit 1
    fi
done

rm -rf "$OUT"
mkdir -p "$OUT"

# $1: repo, $2: ref that must be checked out, $3: archive name
archive_tree() {
    if [ "$(git -C "$1" rev-parse HEAD)" != "$(git -C "$1" rev-parse "$2^{commit}")" ]; then
        echo "❌ $1 is not at $2"
        exit 1
    fi
    git -C "$1" archive --format=tar.gz --prefix="$3/" -o "$OUT/$3.tar.gz" HEAD
    echo "  ✔ $3.tar.gz"
}

archive_tree "$KIT_DIR" "$FFMPEG_KIT_COMMIT" "ffmpeg-kit-${FFMPEG_KIT_COMMIT:0:7}"
archive_tree "$KIT_DIR/src/ffmpeg" "n6.0" "ffmpeg-n6.0"
archive_tree "$KIT_DIR/src/libvpx" "v1.13.0" "libvpx-v1.13.0"
archive_tree "$KIT_DIR/src/cpu-features" "v0.8.0" "cpu-features-v0.8.0"

SCRIPTS_NAME="ffmpegkit-vp9-$FFMPEGKIT_VP9_VERSION-scripts"
tar -czf "$OUT/$SCRIPTS_NAME.tar.gz" -C "$ROOT_DIR" -s "|^|$SCRIPTS_NAME/|" \
    scripts LICENSE THIRD_PARTY_NOTICES.md licenses README.md
echo "  ✔ $SCRIPTS_NAME.tar.gz"

cp "$AAR" "$OUT/ffmpegkit-vp9-$FFMPEGKIT_VP9_VERSION.aar"
echo "  ✔ ffmpegkit-vp9-$FFMPEGKIT_VP9_VERSION.aar"

(cd "$DIST_DIR/ios" && zip -qry "$OUT/ffmpegkit-vp9-$FFMPEGKIT_VP9_VERSION-ios-xcframeworks.zip" Frameworks)
echo "  ✔ ffmpegkit-vp9-$FFMPEGKIT_VP9_VERSION-ios-xcframeworks.zip"

(cd "$OUT" && shasum -a 256 *.tar.gz *.aar *.zip > SHA256SUMS)
echo ""
echo "✅ $OUT"
cat "$OUT/SHA256SUMS"

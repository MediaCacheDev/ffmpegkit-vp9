# ffmpegkit-vp9

[FFmpegKit](https://github.com/arthenica/ffmpeg-kit) 6.0 for Android and iOS, built with only what it takes to decode VP9 WebM with alpha to raw frames. The API is FFmpegKit's own (`com.arthenica.ffmpegkit` on Android, `ffmpegkit` on iOS); only the FFmpeg inside is smaller.

FFmpegKit itself is archived and its binaries are no longer published. These scripts build its last release (commit `1036d3c`: FFmpeg 6.0, libvpx 1.13.0) with FFmpeg configured as `--disable-everything` plus:

- the Matroska/WebM demuxer and the VP9 parser
- the libvpx VP9 decoder, which keeps the alpha channel (FFmpeg's native VP9 decoder drops it)
- the rawvideo encoder and muxer
- the file and pipe protocols
- the filters FFmpeg's command line needs for scaling, pixel format conversion and rotation

| | Default `--enable-libvpx` build | ffmpegkit-vp9 |
|---|---|---|
| Android AAR (arm-v7a, arm64-v8a, x86_64) | 31 MB | 4 MB |
| iOS XCFrameworks (arm64, simulator arm64/x86_64) | 60 MB | 11 MB |

The Android libraries are 16 KB page aligned, as Google Play requires for Android 15+.

## Usage

### Android

```groovy
dependencies {
    implementation 'dev.mediacache:ffmpegkit-vp9:6.0.0'
}
```

minSdk 24. The POM brings in `com.arthenica:smart-exception-java`, which FFmpegKit needs at runtime.

```java
FFmpegSession session = FFmpegKit.execute(
    "-c:v libvpx-vp9 -i input.webm -an -pix_fmt yuva420p -f rawvideo frames.yuv");
```

Always pass `-c:v libvpx-vp9` (only the libvpx decoder is built) and `-an` (there are no audio decoders).

### iOS

Download `ffmpegkit-vp9-6.0.0-ios-xcframeworks.zip` from the [release](https://github.com/MediaCacheDev/ffmpegkit-vp9/releases/tag/6.0.0) and embed the eight XCFrameworks. They are dynamic frameworks; with CocoaPods, list them in `vendored_frameworks` and they are embedded for you.

## Building

```bash
./scripts/build-android.sh   # → dist/android/ffmpegkit-vp9.aar
./scripts/build-ios.sh       # → dist/ios/Frameworks/*.xcframework
```

- **Android:** the Android SDK, an NDK (the newest one under `$ANDROID_HOME/ndk` is used; override with `FFMPEGKIT_NDK_HOME`; r28 or newer for 16 KB pages, which the script checks) and Java 17.
- **iOS:** Xcode.
- The first build clones ffmpeg-kit and fetches FFmpeg and libvpx into `build/`. `CLEAN=1` rebuilds from scratch.

### Releasing

```bash
./scripts/package-release.sh          # → dist/release/: binaries, source tarballs, SHA256SUMS
./scripts/publish-android.sh local    # → ~/.m2
./scripts/publish-android.sh central  # → Central Portal deployment (needs credentials, see the script)
```

The binaries name this version's release page as the place to get their source, so create the GitHub Release (with everything in `dist/release/`) before publishing the Maven Central deployment.

## Licence

The scripts are MIT. The binaries are LGPL-3.0 (FFmpegKit and FFmpeg), BSD-3-Clause (libvpx) and Apache-2.0 (cpu_features, Android only); see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

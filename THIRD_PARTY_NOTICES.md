# Third-party notices

The scripts in this repository are MIT-licensed (see `LICENSE`). The binaries they build, and that the releases and `dev.mediacache:ffmpegkit-vp9` distribute, are not:

| Component | Version | Licence | Where |
|---|---|---|---|
| [FFmpegKit](https://github.com/arthenica/ffmpeg-kit) | commit `1036d3c` | LGPL-3.0 | `ffmpegkit.xcframework`; `libffmpegkit*.so` in the AAR |
| [FFmpeg](https://ffmpeg.org) (arthenica's fork, tag `n6.0`) | 6.0 | LGPL-3.0-or-later | `lib*.xcframework`; `libav*.so`, `libsw*.so` in the AAR |
| [libvpx](https://chromium.googlesource.com/webm/libvpx) (arthenica's fork, tag `v1.13.0`) | 1.13.0 | BSD-3-Clause, plus the WebM patent grant | linked into libavcodec |
| [cpu_features](https://github.com/google/cpu_features) (arthenica's fork, tag `v0.8.0`) | 0.8.0 | Apache-2.0 | Android only, linked into the FFmpegKit libraries |

Licence texts: `licenses/LGPL-3.0.txt`, `licenses/GPL-3.0.txt` (LGPL-3.0 is written as additional permissions on top of GPL-3.0), `licenses/libvpx-LICENSE.txt`, `licenses/libvpx-PATENTS.txt`, `licenses/cpu_features-LICENSE.txt`.

## What the build contains

FFmpeg is configured with `--disable-everything` and only these components: the Matroska/WebM demuxer, the VP9 parser, the libvpx VP9 decoder, the rawvideo encoder and muxer, the file and pipe protocols, and the filters FFmpeg's command line needs to build a filter graph. No GPL code is enabled (no `--enable-gpl`); ffmpeg-kit always passes `--enable-version3`, which is why FFmpeg is LGPL-3.0 rather than 2.1. The exact options are in `scripts/common.sh`.

## Source code

Each [release](https://github.com/MediaCacheDev/ffmpegkit-vp9/releases) carries the complete corresponding source of its binaries: ffmpeg-kit at the commit above, FFmpeg 6.0, libvpx 1.13.0 and cpu_features 0.8.0 as fetched by ffmpeg-kit, and these build scripts.

## Replacing the libraries

On Android the FFmpeg libraries are separate `.so` files in the AAR, and on iOS they are dynamic frameworks, so an app's users can swap in their own builds. LGPL-3.0 also asks for "installation information" on consumer devices where that is otherwise impossible, which applies to iOS App Store apps. If that matters for your app, prefer an FFmpeg build under LGPL-2.1.

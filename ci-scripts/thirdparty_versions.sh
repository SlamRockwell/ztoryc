# =============================================================================
# Single source of truth: third-party versions for Tahoma2D / Ztoryc CI scripts.
# Bump versions only here. Shell scripts: source this file:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/thirdparty_versions.sh"
# Windows .bat: use read_thirdparty_version.py — do not duplicate literals.
#
# Why FFmpeg appears “twice” (not circular):
#   • TAHOMA_FFMPEG_GIT_TAG — checkout tag on tahoma2d/FFmpeg to **compile shared
#     libraries** into the Homebrew (/usr/local) prefix so OpenCV and the app can
#     **link** against libav*.dylib / libav*.so.
#   • TAHOMA_FFMPEG_STATIC_RELEASE — **pre-built static** ffmpeg/ffprobe zips
#     published on GitHub **Releases** for that repo. CI **downloads** them for
#     thirdparty/apps (bundled CLI tools). Those release assets are built and
#     uploaded by the upstream project — this job does not produce them.
#   The static release tag can legitimately differ from the git tag used for dev
#   libraries (historically v5.0.0 zips vs v4.3.1 fork tag). Align deliberately
#   by editing both constants below.
#
# OpenCV: TAHOMA_OPENCV_GIT_REF empty means `git clone` default branch of the fork.
# Set to a tag or branch for reproducible CI (e.g. 4.x-tahoma).
# =============================================================================

export TAHOMA_FFMPEG_REPO=https://github.com/tahoma2d/FFmpeg.git
export TAHOMA_FFMPEG_GIT_TAG=v4.3.1

# GitHub Releases tag for static LGPL zip assets.
export TAHOMA_FFMPEG_STATIC_RELEASE=v5.0.0

export TAHOMA_OPENCV_REPO=https://github.com/tahoma2d/opencv.git
export TAHOMA_OPENCV_GIT_REF=

export TAHOMA_RHUBARB_RELEASE=v1.13.0

export DAV1D_TAG=0.9.2

# Derived semver for zip basenames (ffmpeg-5.0.0-macos64-…); not parsed by read_thirdparty_version.py
if [ -n "${BASH_VERSION:-}" ]; then
  TAHOMA_FFMPEG_STATIC_VER="${TAHOMA_FFMPEG_STATIC_RELEASE#v}"
  export TAHOMA_FFMPEG_STATIC_VER
fi

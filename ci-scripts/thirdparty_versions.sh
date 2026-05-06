# =============================================================================
# Single source of truth: third-party versions for Tahoma2D / Ztoryc CI scripts.
# Bump versions only here. Shell scripts: source this file:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/thirdparty_versions.sh"
# Windows .bat: use read_thirdparty_version.py — do not duplicate literals.
#
# FFmpeg (macOS / Linux): one fork tag is built from source into the prefix
# (Homebrew / /usr/local). Bundled CLI binaries for the app are staged from that
# same install (ci-scripts/*/tahoma-bundle-apps.sh) — no separate “static zip”
# download from third-party releases.
#
# OpenCV: TAHOMA_OPENCV_GIT_REF empty means `git clone` default branch of the fork.
# Set to a tag or branch for reproducible CI (e.g. 4.x-tahoma).
# =============================================================================

export TAHOMA_FFMPEG_REPO=https://github.com/tahoma2d/FFmpeg.git
export TAHOMA_FFMPEG_GIT_TAG=v4.3.1

export TAHOMA_OPENCV_REPO=https://github.com/tahoma2d/opencv.git
export TAHOMA_OPENCV_GIT_REF=

export TAHOMA_RHUBARB_RELEASE=v1.13.0

export DAV1D_TAG=0.9.2

#!/bin/bash
# Stage bundled CLI apps for packaging: FFmpeg from the same Homebrew install produced
# by tahoma-buildffmpeg.sh (no upstream static zips). Rhubarb still fetched by release URL.
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$_SCRIPT_DIR/../thirdparty_versions.sh"
REPO_ROOT="$(cd "$_SCRIPT_DIR/../.." && pwd)"
export BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix)}"
APPS="$REPO_ROOT/thirdparty/apps"
mkdir -p "$APPS"

if [[ ! -x "$BREW_PREFIX/bin/ffmpeg" ]]; then
  echo "ERROR: $BREW_PREFIX/bin/ffmpeg not found. Run ci-scripts/osx/tahoma-buildffmpeg.sh first."
  exit 1
fi

echo ">>> Bundling FFmpeg CLI from $BREW_PREFIX (dylibs → thirdparty/apps/ffmpeg/libs)"
FFDEST="$APPS/ffmpeg"
rm -rf "$FFDEST"
mkdir -p "$FFDEST/bin" "$FFDEST/libs"

cp "$BREW_PREFIX/bin/ffmpeg" "$BREW_PREFIX/bin/ffprobe" "$FFDEST/bin/"

if ! command -v dylibbundler >/dev/null 2>&1; then
  echo ">>> Installing dylibbundler"
  brew install dylibbundler
fi

# dylibbundler rewrites load commands to @executable_path/../libs/*.dylib — target dir must be **libs** (not lib).
dylibbundler -of -b -x "$FFDEST/bin/ffmpeg" -d "$FFDEST/libs"
dylibbundler -of -b -x "$FFDEST/bin/ffprobe" -d "$FFDEST/libs"

echo ">>> Bundled ffmpeg linkage:"
otool -L "$FFDEST/bin/ffmpeg" | head -25

echo ">>> Rhubarb Lip Sync (${TAHOMA_RHUBARB_RELEASE})"
RH="$APPS/rhubarb"
if [[ ! -x "$RH/rhubarb" ]]; then
  rm -rf "$RH"
  (
    cd "$APPS"
    curl -fsSL -o rhubarb-lip-sync-tahoma2d-osx.zip "https://github.com/tahoma2d/rhubarb-lip-sync/releases/download/${TAHOMA_RHUBARB_RELEASE}/rhubarb-lip-sync-tahoma2d-osx.zip"
    unzip rhubarb-lip-sync-tahoma2d-osx.zip -d rhubarb
    rm -f rhubarb-lip-sync-tahoma2d-osx.zip
  )
fi

date -u +"%Y-%m-%dT%H:%M:%SZ staged bundle (ffmpeg from brew + rhubarb)" > "$APPS/.bundle_ready"

#!/bin/bash
# Bundled FFmpeg (static) + Rhubarb for packaging — avoid re-download when CI restores thirdparty/apps cache.
set -e
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$_SCRIPT_DIR/../thirdparty_versions.sh"
REPO_ROOT="$(cd "$_SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT/thirdparty"

if [ ! -d apps ]; then
   mkdir apps
fi
cd apps
echo "*" >| .gitignore

MARKER=".bundle_ready"

_apps_ready() {
  [ "${FORCE_APPS_DOWNLOAD:-0}" = "1" ] && return 1
  [ -f "$MARKER" ] || return 1
  [ -x ffmpeg/ffmpeg ] || return 1
  [ -x rhubarb/rhubarb ] || return 1
  return 0
}

if _apps_ready; then
  echo ">>> Third-party apps already present (ffmpeg + rhubarb), skipping downloads."
  exit 0
fi

echo ">>> Getting FFmpeg (static bundle release ${TAHOMA_FFMPEG_STATIC_RELEASE})"
rm -rf ffmpeg
wget "https://github.com/tahoma2d/FFmpeg/releases/download/${TAHOMA_FFMPEG_STATIC_RELEASE}/ffmpeg-${TAHOMA_FFMPEG_STATIC_VER}-macos64-static-lgpl.zip"
unzip "ffmpeg-${TAHOMA_FFMPEG_STATIC_VER}-macos64-static-lgpl.zip"
mv "ffmpeg-${TAHOMA_FFMPEG_STATIC_VER}-macos64-static-lgpl" ffmpeg

echo ">>> Getting Rhubarb Lip Sync"
rm -rf rhubarb
wget "https://github.com/tahoma2d/rhubarb-lip-sync/releases/download/${TAHOMA_RHUBARB_RELEASE}/rhubarb-lip-sync-tahoma2d-osx.zip"
unzip rhubarb-lip-sync-tahoma2d-osx.zip -d rhubarb

date -u +"%Y-%m-%dT%H:%M:%SZ downloaded bundle" > "$MARKER"

#!/bin/bash
# Bundled FFmpeg (static) + Rhubarb for packaging — avoid re-download when CI restores thirdparty/apps cache.
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
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

echo ">>> Getting FFmpeg"
rm -rf ffmpeg
wget https://github.com/tahoma2d/FFmpeg/releases/download/v5.0.0/ffmpeg-5.0.0-macos64-static-lgpl.zip
unzip ffmpeg-5.0.0-macos64-static-lgpl.zip
mv ffmpeg-5.0.0-macos64-static-lgpl ffmpeg

echo ">>> Getting Rhubarb Lip Sync"
rm -rf rhubarb
wget https://github.com/tahoma2d/rhubarb-lip-sync/releases/download/v1.13.0/rhubarb-lip-sync-tahoma2d-osx.zip
unzip rhubarb-lip-sync-tahoma2d-osx.zip -d rhubarb

date -u +"%Y-%m-%dT%H:%M:%SZ downloaded bundle" > "$MARKER"

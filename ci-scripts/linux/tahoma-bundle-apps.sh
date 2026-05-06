#!/bin/bash
# Stage bundled FFmpeg from /usr/local (same install as OpenCV links against).
# Copies only libraries under /usr/local referenced by ldd; Rhubarb by release URL.
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$_SCRIPT_DIR/../thirdparty_versions.sh"
REPO_ROOT="$(cd "$_SCRIPT_DIR/../.." && pwd)"
PREFIX="${PREFIX:-/usr/local}"
APPS="$REPO_ROOT/thirdparty/apps"
mkdir -p "$APPS"

if [[ ! -x "$PREFIX/bin/ffmpeg" ]]; then
  echo "ERROR: $PREFIX/bin/ffmpeg not found. Run ci-scripts/linux/tahoma-buildffmpeg.sh first."
  exit 1
fi

echo ">>> Bundling FFmpeg CLI from $PREFIX"
DEST="$APPS/ffmpeg"
rm -rf "$DEST"
mkdir -p "$DEST/bin" "$DEST/lib"

cp "$PREFIX/bin/ffmpeg" "$PREFIX/bin/ffprobe" "$DEST/bin/"

bundle_ldd_local() {
  local bin="$1"
  local libdest="$2"
  local lib
  while IFS= read -r lib; do
    [[ -z "$lib" || ! -f "$lib" ]] && continue
    case "$lib" in
      */ld-linux-*.so*) continue ;;
      */libpthread.so.0) continue ;;
      */libc.so.6) continue ;;
      */libm.so.6) continue ;;
      */libdl.so.2) continue ;;
      */librt.so.1) continue ;;
      */libgcc_s.so.1) continue ;;
      */libstdc++.so.6) continue ;;
    esac
    if [[ "$lib" == "$PREFIX"/* ]]; then
      cp -f "$lib" "$libdest/"
    fi
  done < <(ldd "$bin" | awk '/=>/ {print $3}' | grep -E '^/' || true)
}

bundle_ldd_local "$DEST/bin/ffmpeg" "$DEST/lib"
bundle_ldd_local "$DEST/bin/ffprobe" "$DEST/lib"

for exe in "$DEST/bin/ffmpeg" "$DEST/bin/ffprobe"; do
  if command -v patchelf >/dev/null 2>&1; then
    patchelf --set-rpath '$ORIGIN/../lib' "$exe"
  fi
done

echo ">>> Bundled ffmpeg deps:"
ldd "$DEST/bin/ffmpeg" | head -30 || true

echo ">>> Rhubarb Lip Sync (${TAHOMA_RHUBARB_RELEASE})"
RH="$APPS/rhubarb"
if [[ ! -x "$RH/rhubarb" ]]; then
  rm -rf "$RH"
  (
    cd "$APPS"
    wget "https://github.com/tahoma2d/rhubarb-lip-sync/releases/download/${TAHOMA_RHUBARB_RELEASE}/rhubarb-lip-sync-tahoma2d-linux.zip"
    unzip rhubarb-lip-sync-tahoma2d-linux.zip -d rhubarb
    rm -f rhubarb-lip-sync-tahoma2d-linux.zip
  )
fi

date -u +"%Y-%m-%dT%H:%M:%SZ staged bundle (ffmpeg from $PREFIX + rhubarb)" > "$APPS/.bundle_ready"

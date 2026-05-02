#!/bin/sh
# Download official ccache macOS binary into repo .tools/ccache/bin (no brew).
# Re-run CMake configure after installing so CMAKE_*_COMPILER_LAUNCHER picks it up.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_BIN="$ROOT/.tools/ccache/bin"
VERSION="${CCACHE_VERSION:-4.13.4}"
TAG="v${VERSION}"
ARCHIVE="ccache-${VERSION}-darwin.tar.gz"
URL="https://github.com/ccache/ccache/releases/download/${TAG}/${ARCHIVE}"

echo "→ Installing ccache ${VERSION} to ${DEST_BIN}"
tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

curl -fsSL -o "$tmpdir/$ARCHIVE" "$URL"
tar -xzf "$tmpdir/$ARCHIVE" -C "$tmpdir"
BIN="$(find "$tmpdir" -name ccache -type f | head -1)"
if test -z "$BIN"; then
  echo "error: could not find ccache binary inside archive" >&2
  exit 1
fi
mkdir -p "$DEST_BIN"
cp "$BIN" "$DEST_BIN/ccache"
chmod +x "$DEST_BIN/ccache"
echo "→ Done."
"$DEST_BIN/ccache" --version
echo "Reconfigure CMake (delete CMakeCache.txt or run cmake again) so the build uses ccache."

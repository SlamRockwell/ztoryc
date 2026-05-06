#!/bin/bash
BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix)}"
# Avoid 5–15+ minute meta-updates every CI run (brew formulae pins are unchanged in-tree).
if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
  brew update
else
  echo "Skipping brew update on GitHub Actions (scripts pin versions)."
fi
# Remove symlink in order for latest python to install (Intel + Apple Silicon Homebrew)
for f in python3 python3.12 2to3 2to3-3.12 idle3 idle3.12 pydoc3 pydoc3.12 python3-config python3.12-config; do
  rm -f "$BREW_PREFIX/bin/$f"
done
# Remove synlink to nghttp2 in order for latest curl to install
#brew unlink nghttp2
# SuperLU: required when WITH_SYSTEM_SUPERLU=ON (default on macOS — see toonz/sources/CMakeLists.txt)
brew install superlu
brew install openjpeg libresample protobuf boost qt@5 clang-format glew lz4 lzo libmypaint jpeg-turbo nasm yasm fontconfig freetype gnutls lame libass libbluray libsoxr libvorbis libvpx opencore-amr openh264 openjpeg opus rav1e sdl2 snappy speex tesseract theora webp xvid xz gsed
#brew install dav1d
# Avoid brew "already installed" noise on CI when runners pre-seed these.
brew list meson >/dev/null 2>&1 || brew install meson
brew list ninja >/dev/null 2>&1 || brew install ninja
brew install dylibbundler
brew install automake autoconf gettext pkg-config libtool libusb-compat gd libexif libdeflate
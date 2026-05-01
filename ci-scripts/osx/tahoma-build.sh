#!/bin/bash
set -e
# TIFF is rebuilt here (not ffmpeg/opencv). When deps cache restores a prior libtiff build, skip compile.
_should_rebuild_tiff() {
  if [ "${FORCE_TIFF_REBUILD:-0}" = "1" ]; then
    return 0
  fi
  if [ ! -d thirdparty/tiff-4.2.0/libtiff/.libs ]; then
    return 0
  fi
  if [ -z "$(find thirdparty/tiff-4.2.0/libtiff/.libs -maxdepth 1 -name 'libtiff.*' -print -quit 2>/dev/null)" ]; then
    return 0
  fi
  return 1
}
if _should_rebuild_tiff; then
  echo "TIFF: configuring and building (first run / cache miss)"
  pushd thirdparty/tiff-4.2.0
  ./configure --disable-lzma --disable-webp --disable-zstd --without-x && make
  popd
else
  echo "TIFF: reuse existing libtiff/.libs from cache — skipped configure/make"
fi

cd toonz

if [ ! -d build ]
then
   mkdir build
fi
cd build

if [ -d /usr/local/Cellar/qt@5 ]
then
   QTVERSION=`ls /usr/local/Cellar/qt@5`
   USEQTLIB="/usr/local/opt/qt@5/lib/"
elif [ -d /opt/homebrew/opt/qt@5 ]
then
   QTVERSION=`ls /opt/homebrew/opt/qt@5`
   USEQTLIB="/opt/homebrew/opt/qt@5/lib/"
else
   QTVERSION=`ls /usr/local/Cellar/qt`
   USEQTLIB="/usr/local/opt/qt/lib/"
fi

echo "QT Version detected: $QTVERSION"

if [ -d ../../thirdparty/canon/Header ]
then
   export CANON_FLAG=-DWITH_CANON=ON
fi

export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/opt/jpeg-turbo/lib/pkgconfig"

NPROC=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 7)
CMAKE_EXTRA=()
BUILD_CMD=(make -j7)
if [ "${GITHUB_ACTIONS:-}" = "true" ] && command -v ninja >/dev/null 2>&1; then
  CMAKE_EXTRA=(-G Ninja)
  BUILD_CMD=(ninja -j"${NPROC}")
  echo "Using Ninja with -j${NPROC} (GitHub Actions)"
fi

cmake ../sources "${CMAKE_EXTRA[@]}" $CANON_FLAG \
      -DCMAKE_BUILD_TYPE="${CI_BUILD_TYPE:-RelWithDebInfo}" \
      -DWITH_GPHOTO2=ON \
      -DWITH_SYSTEM_SUPERLU=ON \
      -DQT_PATH=$USEQTLIB \
      -DTIFF_INCLUDE_DIR=../../thirdparty/tiff-4.2.0/libtiff/

"${BUILD_CMD[@]}"

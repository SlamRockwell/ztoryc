#!/bin/bash
set -e
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$_SCRIPT_DIR/../thirdparty_versions.sh"
cd thirdparty

if [ ! -d apps ]
then
   mkdir apps
fi
cd apps
echo "*" >| .gitignore

echo ">>> Getting FFmpeg (static bundle release ${TAHOMA_FFMPEG_STATIC_RELEASE})"
if [ -d ffmpeg ]
then
   rm -rf ffmpeg
fi
wget "https://github.com/tahoma2d/FFmpeg/releases/download/${TAHOMA_FFMPEG_STATIC_RELEASE}/ffmpeg-${TAHOMA_FFMPEG_STATIC_VER}-linux64-static-lgpl.zip"
unzip "ffmpeg-${TAHOMA_FFMPEG_STATIC_VER}-linux64-static-lgpl.zip"
mv "ffmpeg-${TAHOMA_FFMPEG_STATIC_VER}-linux64-static-lgpl" ffmpeg


echo ">>> Getting Rhubarb Lip Sync"
if [ -d rhubarb ]
then
   rm -rf rhubarb
fi
wget "https://github.com/tahoma2d/rhubarb-lip-sync/releases/download/${TAHOMA_RHUBARB_RELEASE}/rhubarb-lip-sync-tahoma2d-linux.zip"
unzip rhubarb-lip-sync-tahoma2d-linux.zip -d rhubarb


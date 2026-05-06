@echo off
setlocal EnableDelayedExpansion
REM Versions: read from ci-scripts\thirdparty_versions.sh via read_thirdparty_version.py (single source of truth).
set "VER_PY=%~dp0..\read_thirdparty_version.py"
for /f "delims=" %%a in ('python "%VER_PY%" TAHOMA_FFMPEG_STATIC_VER') do set "TAHOMA_FFMPEG_STATIC_VER=%%a"
for /f "delims=" %%a in ('python "%VER_PY%" TAHOMA_FFMPEG_STATIC_RELEASE') do set "TAHOMA_FFMPEG_STATIC_RELEASE=%%a"
for /f "delims=" %%a in ('python "%VER_PY%" TAHOMA_RHUBARB_RELEASE') do set "TAHOMA_RHUBARB_RELEASE=%%a"

cd thirdparty

IF NOT EXIST apps mkdir apps

cd apps
echo * > .gitignore

echo ">>> Getting FFmpeg"

IF EXIST ffmpeg rmdir /S /Q ffmpeg
curl -fsSL -o "ffmpeg-!TAHOMA_FFMPEG_STATIC_VER!-win64-static-lgpl.zip" "https://github.com/tahoma2d/FFmpeg/releases/download/!TAHOMA_FFMPEG_STATIC_RELEASE!/ffmpeg-!TAHOMA_FFMPEG_STATIC_VER!-win64-static-lgpl.zip"
7z x "ffmpeg-!TAHOMA_FFMPEG_STATIC_VER!-win64-static-lgpl.zip"
rename "ffmpeg-!TAHOMA_FFMPEG_STATIC_VER!-win64-static-lgpl" ffmpeg

echo ">>> Getting Rhubarb Lip Sync"

IF EXIST rhubarb rmdir /S /Q rhubarb
curl -fsSL -o rhubarb-lip-sync-tahoma2d-win.zip "https://github.com/tahoma2d/rhubarb-lip-sync/releases/download/!TAHOMA_RHUBARB_RELEASE!/rhubarb-lip-sync-tahoma2d-win.zip"
7z x rhubarb-lip-sync-tahoma2d-win.zip
rename rhubarb-lip-sync-tahoma2d-win rhubarb

cd ..\..

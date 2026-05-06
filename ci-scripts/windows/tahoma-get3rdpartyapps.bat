@echo off
setlocal EnableDelayedExpansion
REM FFmpeg: install via Chocolatey (no Tahoma release zips). Rhubarb: version from thirdparty_versions.sh.
cd /d "%~dp0..\.."

set "VER_PY=%~dp0..\read_thirdparty_version.py"
for /f "delims=" %%a in ('python "%VER_PY%" TAHOMA_RHUBARB_RELEASE') do set "TAHOMA_RHUBARB_RELEASE=%%a"

IF NOT EXIST thirdparty\apps mkdir thirdparty\apps
cd thirdparty\apps
echo * > .gitignore

echo ">>> FFmpeg (Chocolatey — portable layout under lib\\ffmpeg)"
IF NOT EXIST ffmpeg\bin mkdir ffmpeg\bin
where choco >nul 2>&1
IF ERRORLEVEL 1 (
  echo ERROR: Chocolatey not found. Install Chocolatey or bundle ffmpeg manually into thirdparty\apps\ffmpeg\bin
  exit /b 1
)
IF "%ChocolateyInstall%"=="" SET "ChocolateyInstall=C:\ProgramData\chocolatey"
choco install ffmpeg -y --no-progress
IF ERRORLEVEL 1 exit /b 1

set "FFBIN=%ChocolateyInstall%\lib\ffmpeg\tools\ffmpeg\bin"
IF NOT EXIST "%FFBIN%\ffmpeg.exe" set "FFBIN=%ChocolateyInstall%\lib\ffmpeg-full\tools\ffmpeg\bin"
IF NOT EXIST "%FFBIN%\ffmpeg.exe" (
  echo ERROR: Expected ffmpeg.exe under Chocolatey lib\ffmpeg after choco install — adjust FFBIN in ci-scripts\windows\tahoma-get3rdpartyapps.bat
  exit /b 1
)
xcopy /Y /I "%FFBIN%\*.*" ffmpeg\bin\

echo ">>> Rhubarb Lip Sync"
IF EXIST rhubarb rmdir /S /Q rhubarb
curl -fsSL -o rhubarb-lip-sync-tahoma2d-win.zip "https://github.com/tahoma2d/rhubarb-lip-sync/releases/download/!TAHOMA_RHUBARB_RELEASE!/rhubarb-lip-sync-tahoma2d-win.zip"
7z x rhubarb-lip-sync-tahoma2d-win.zip
rename rhubarb-lip-sync-tahoma2d-win rhubarb

cd ..\..

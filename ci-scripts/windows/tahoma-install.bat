if not exist C:\tools\opencv\build (
  choco install opencv --version=4.11.0 -y
) else (
  echo OpenCV already present ^(CI cache^), skipping choco opencv.
)
if not exist C:\local\boost_1_87_0 (
  choco install boost-msvc-14.3 --version=1.87.0 -y
) else (
  echo Boost already present ^(CI cache^), skipping choco boost.
)

if not exist thirdparty\qt\5.15.2_wintab (
  mkdir thirdparty\qt
  REM Install Custom Qt 5.15.2 with WinTab support (skip when restored from CI cache)
  curl -fsSL -o Qt5.15.2_wintab.zip https://github.com/tahoma2d/qt5/releases/download/v5.15.2/Qt5.15.2_wintab.zip
  7z x Qt5.15.2_wintab.zip
  move Qt5.15.2_wintab\5.15.2_wintab thirdparty\qt
) else (
  echo Qt WinTab kit already present, skipping download.
)

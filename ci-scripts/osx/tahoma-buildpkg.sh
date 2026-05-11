#!/bin/bash
# Bundles the full repo "stuff" tree (themes live in stuff/config/qss/). Paths must
# not depend on the caller's cwd — GitHub Actions runs from repo root, but local
# runs may not.
export TAHOMA2DVERSION=1.6

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STUFF_SRC="$REPO_ROOT/stuff"

if [[ ! -f "$STUFF_SRC/config/qss/Dark/Dark.qss" ]]; then
  echo "ERROR: Theme files missing — expected $STUFF_SRC/config/qss/Dark/Dark.qss"
  echo "       (/checkout may be incomplete; verify stuff/config/qss is in git)"
  ls -la "$STUFF_SRC/config/qss" 2>&1 || true
  exit 1
fi
QSS_N="$(find "$STUFF_SRC/config/qss" -name '*.qss' 2>/dev/null | wc -l | tr -d ' ')"
echo ">>> Packaging stuff from $STUFF_SRC ($QSS_N theme .qss file(s) under config/qss)"

cd "$REPO_ROOT" || {
  echo "ERROR: cannot cd to REPO_ROOT=$REPO_ROOT"
  exit 1
}

export BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix)}"
echo ">>> BREW_PREFIX=$BREW_PREFIX"

if [ -d /usr/local/Cellar/qt@5 ]
then
   export QTDIR=/usr/local/opt/qt@5
elif [ -d /opt/homebrew/opt/qt@5 ]
then
   export QTDIR=/opt/homebrew/opt/qt@5
else
   export QTDIR=/usr/local/opt/qt
fi
export TOONZDIR=toonz/build/toonz

# If found, use Xcode Release build
if [ -d $TOONZDIR/Release ]
then
   export TOONZDIR=$TOONZDIR/Release
fi

if [ -d $TOONZDIR/Ztoryc.app/tahomastuff ]
then
   # In case of prior builds, replace stuff folder
   rm -rf $TOONZDIR/Ztoryc.app/tahomastuff
fi

if [ -d thirdparty/apps/ffmpeg/bin ]
then
   echo ">>> Copying FFmpeg to Ztoryc.app/ffmpeg"
   if [ -d $TOONZDIR/Ztoryc.app/ffmpeg ]
   then
      # In case of prior builds, replace ffmpeg folder
      rm -rf $TOONZDIR/Ztoryc.app/ffmpeg
   fi
   mkdir $TOONZDIR/Ztoryc.app/ffmpeg
   cp -R thirdparty/apps/ffmpeg/bin/ffmpeg thirdparty/apps/ffmpeg/bin/ffprobe $TOONZDIR/Ztoryc.app/ffmpeg
   if [ -d thirdparty/apps/ffmpeg/libs ]
   then
      cp -R thirdparty/apps/ffmpeg/libs $TOONZDIR/Ztoryc.app/ffmpeg/
   elif [ -d thirdparty/apps/ffmpeg/lib ]
   then
      cp -R thirdparty/apps/ffmpeg/lib $TOONZDIR/Ztoryc.app/ffmpeg/
   fi
   chmod -R 755 $TOONZDIR/Ztoryc.app/ffmpeg
fi

if [ -d thirdparty/apps/rhubarb ]
then
   echo ">>> Copying Rhubarb Lip Sync to Ztoryc.app/rhubarb"
   if [ -d $TOONZDIR/Ztoryc.app/rhubarb ]
   then
      # In case of prior builds, replace rhubarb folder
      rm -rf $TOONZDIR/Ztoryc.app/rhubarb
   fi
   mkdir $TOONZDIR/Ztoryc.app/rhubarb
   cp -R thirdparty/apps/rhubarb/rhubarb thirdparty/apps/rhubarb/res $TOONZDIR/Ztoryc.app/rhubarb
   chmod -R 755 $TOONZDIR/Ztoryc.app/rhubarb
fi

if [ ! -d $TOONZDIR/Ztoryc.app/Contents/Frameworks ]
then
   mkdir $TOONZDIR/Ztoryc.app/Contents/Frameworks
fi

if [ -d thirdparty/canon/Framework ]
then
   if [ ! -d $TOONZDIR/Ztoryc.app/Contents/Frameworks/EDSDK.framework ]
   then
      echo ">>> Copying canon framework to Ztoryc.app/Contents/Frameworks/EDSDK.Framework"
      cp -R thirdparty/canon/Framework/ $TOONZDIR/Ztoryc.app/Contents/Frameworks
      chmod -R 755 $TOONZDIR/Ztoryc.app/Contents/Frameworks/EDSDK.framework
   fi
fi

if [ ! -d $TOONZDIR/Ztoryc.app/Contents/Frameworks/libgphoto2 ]
then
   echo ">>> Copying libghoto2 supporting directories to Ztoryc.app/Contents/Frameworks"
   cp -R "$BREW_PREFIX/lib/libgphoto2" $TOONZDIR/Ztoryc.app/Contents/Frameworks
   cp -R "$BREW_PREFIX/lib/libgphoto2_port" $TOONZDIR/Ztoryc.app/Contents/Frameworks

   rm -f $TOONZDIR/Ztoryc.app/Contents/Frameworks/libgphoto2/print-camera-list
   find $TOONZDIR/Ztoryc.app/Contents/Frameworks/libgphoto2* -name *.la -exec rm -f {} \;
fi

echo ">>> Creating DSYM files"
if [ -d $TOONZDIR/DSYM ]
then
   rm -rf $TOONZDIR/DSYM
fi

for X in `find $TOONZDIR/Ztoryc.app/Contents/MacOS -type f`
do
   chmod u+w "$X" 2>/dev/null || true
   dsymutil -o $TOONZDIR/DSYM $X
   # No strip(1): like upstream Tahoma2D mac packaging we do not re-codesign the bundle;
   # stripping breaks embedded signatures and recent macOS kills at dlopen.
done

if [ -d $TOONZDIR/Ztoryc.app/DSYM ]
then
   rm -rf $TOONZDIR/Ztoryc.app/DSYM
fi

echo ">>> Configuring Ztoryc.app for deployment"

$QTDIR/bin/macdeployqt $TOONZDIR/Ztoryc.app -verbose=0 -always-overwrite \
   -executable=$TOONZDIR/Ztoryc.app/Contents/MacOS/lzocompress \
   -executable=$TOONZDIR/Ztoryc.app/Contents/MacOS/lzodecompress \
   -executable=$TOONZDIR/Ztoryc.app/Contents/MacOS/tcleanup \
   -executable=$TOONZDIR/Ztoryc.app/Contents/MacOS/tcomposer \
   -executable=$TOONZDIR/Ztoryc.app/Contents/MacOS/tconverter \
   -executable=$TOONZDIR/Ztoryc.app/Contents/MacOS/tfarmcontroller \
   -executable=$TOONZDIR/Ztoryc.app/Contents/MacOS/tfarmserver 

for FW in `echo "QtDBus QtPdf QtQml QtQmlModels QtQuick QtVirtualKeyboard"`
do
   if [ ! -d $TOONZDIR/Ztoryc.app/Contents/Frameworks/$FW.framework ]
   then
      echo ">>> Copying missing $FW.framework to Ztoryc.app/Contents/Frameworks"
      cp -r $QTDIR/Frameworks/$FW.framework $TOONZDIR/Ztoryc.app/Contents/Frameworks
   fi
done

if [ ! -d $TOONZDIR/Ztoryc.app/Contents/lib ]
then
   echo ">>> Adding Contents/lib symbolic link to Ztoryc.app/Contents/Frameworks"
   ln -s Frameworks $TOONZDIR/Ztoryc.app/Contents/lib
fi

echo ">>> Correcting library paths"
function checkLibFile() {
   local LIBFILE=$1   
   for DEPFILE in `otool -L $LIBFILE | sed -e "s/ (.*$//" | grep -e"$BREW_PREFIX" -e"@rpath" -e"\.\./\.\./\.\." | grep -v "/qt"`
   do
      local Z=`echo $DEPFILE | cut -c 1-1`
      if [ "$Z" = "/" -o "$Z" = "@" ]
      then
         local Y=`basename $DEPFILE`
         local W=`basename $LIBFILE`
         local X=`echo $DEPFILE | grep "\.framework\/"`
         if [ "$X" = "" -a ! -f $TOONZDIR/Ztoryc.app/Contents/Frameworks/$Y ]
         then
            local SRC=$DEPFILE
            local Z=`echo $DEPFILE | cut -c 1-16`
            local Z2=`echo $DEPFILE | cut -c 1-6`
            if [ "$Z" = "@loader_path/../" ]
            then
               local V=`echo $DEPFILE | sed -e"s/^.*\/\.\.\///"`
               local SRC=$BREW_PREFIX/$V
            elif [ "$Z2" = "@rpath" ]
            then
                local SRC=$BREW_PREFIX/lib/$Y
            fi
            echo "Copying $SRC to Frameworks"
            cp $SRC $TOONZDIR/Ztoryc.app/Contents/Frameworks
            chmod 644 $TOONZDIR/Ztoryc.app/Contents/Frameworks/$Y
            local ORIGDEPFILE=$DEPFILE
            checkLibFile $TOONZDIR/Ztoryc.app/Contents/Frameworks/$Y
            DEPFILE=$ORIGDEPFILE
         fi
         if [ "$Y" != "$W" ]
         then
            echo "Fixing $DEPFILE in $LIBFILE"
            if [ "$X" != "" ]
            then
               local Y=`echo $DEPFILE | sed -e"s/^.*\/\.\.\///" -e"s/@rpath.//"`
               install_name_tool -change $DEPFILE @executable_path/../Frameworks/$Y $LIBFILE
            else
               install_name_tool -change $DEPFILE @executable_path/../Frameworks/$Y $LIBFILE
            fi
         fi
         FIXCHECK=`otool -D $LIBFILE | grep -v ":" | grep -F "$BREW_PREFIX"`
         if [ "$FIXCHECK" == "$DEPFILE" ]
         then
            echo "   Fixed ID!"
            install_name_tool -id @executable_path/../Frameworks/$Y $LIBFILE
         fi
      fi
   done
}

for FILE in `find $TOONZDIR/Ztoryc.app/Contents -type f | grep -v -e"\.h" -e"\.prl" -e"\.plist" -e"\.conf" -e"\.icns" -e"EDSDK" -e"\/Headers\/"`
do
   checkLibFile $FILE
done

# gfortran / OpenMP often link libgcc_s from Homebrew GCC; it must live in Frameworks
# with load paths rewritten or macOS library validation kills the process at dlopen.
echo ">>> Vendoring libgcc_s from GCC toolchain (if present)"
_LIBGCC_SRC=$(find "$BREW_PREFIX/opt/gcc" "$BREW_PREFIX/Cellar/gcc" -name 'libgcc_s*.dylib' 2>/dev/null | head -1)
if [ -n "$_LIBGCC_SRC" ] && [ -f "$_LIBGCC_SRC" ]; then
   _LIBGCC_BASE=$(basename "$_LIBGCC_SRC")
   cp -f "$_LIBGCC_SRC" "$TOONZDIR/Ztoryc.app/Contents/Frameworks/"
   chmod 644 "$TOONZDIR/Ztoryc.app/Contents/Frameworks/$_LIBGCC_BASE"
   find "$TOONZDIR/Ztoryc.app/Contents" -type f 2>/dev/null | while IFS= read -r _M; do
      file "$_M" 2>/dev/null | grep -q 'Mach-O' || continue
      while IFS= read -r _OLD; do
         case "$_OLD" in
            /*) install_name_tool -change "$_OLD" "@executable_path/../Frameworks/$_LIBGCC_BASE" "$_M" 2>/dev/null || true ;;
         esac
      done < <(otool -L "$_M" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/ (compatibility.*$//' | grep 'libgcc_s' || true)
   done
   install_name_tool -id "@executable_path/../Frameworks/$_LIBGCC_BASE" "$TOONZDIR/Ztoryc.app/Contents/Frameworks/$_LIBGCC_BASE" 2>/dev/null || true
fi

echo ">>> Moving DYSM to Ztoryc.app"
mv $TOONZDIR/DSYM $TOONZDIR/Ztoryc.app

if [ "${SKIP_PKG:-0}" != "1" ]; then
  echo ">>> Creating Ztoryc-install-osx.pkg"
  toonz/installer/osx/app.rb "$TOONZDIR" "$STUFF_SRC" toonz/installer/osx/scripts $TAHOMA2DVERSION
  mv $TOONZDIR/Ztoryc-install-osx.pkg $TOONZDIR/..
else
  echo ">>> Skipping PKG (SKIP_PKG=1)"
fi

FINAL_DMG_NAME="${ZTORYC_DMG_BASENAME:-Ztoryc-portable-osx.dmg}"
echo ">>> Creating portable DMG: $FINAL_DMG_NAME (dmgbuild — no Finder during build)"

cp -R "$STUFF_SRC" "$TOONZDIR/Ztoryc.app/tahomastuff"
chmod -R 777 "$TOONZDIR/Ztoryc.app/tahomastuff"

find "$TOONZDIR/Ztoryc.app/tahomastuff" -name .gitkeep -exec rm -f {} \;

if [[ ! -f "$TOONZDIR/Ztoryc.app/tahomastuff/config/qss/Dark/Dark.qss" ]]; then
  echo "ERROR: After copy, portable bundle missing $TOONZDIR/Ztoryc.app/tahomastuff/config/qss/Dark/Dark.qss"
  exit 1
fi

cd $TOONZDIR

# Drag-to-Applications can fail with error -8060 if the bundle has odd xattrs,
# immutable flags, or non-writable Mach-O.
echo ">>> Normalizing Ztoryc.app for install-by-copy (xattr, flags, permissions)"
find Ztoryc.app -name '.DS_Store' -exec rm -f {} \; 2>/dev/null || true
find Ztoryc.app -name '._*' -exec rm -f {} \; 2>/dev/null || true
xattr -cr Ztoryc.app 2>/dev/null || true
chmod -R u+rwX Ztoryc.app 2>/dev/null || true
chflags -R nouchg,noschg Ztoryc.app 2>/dev/null || true

OUTPUT_DMG="$REPO_ROOT/toonz/build/$FINAL_DMG_NAME"
mkdir -p "$(dirname "$OUTPUT_DMG")"

if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'; then
   echo "ERROR: dmgbuild requires Python 3.10 or newer (found $(python3 -V 2>&1))"
   exit 1
fi

DMG_VENV="$REPO_ROOT/toonz/build/.dmgbuild-venv"
DMG_REQ="$SCRIPT_DIR/requirements-dmgbuild.txt"
if [ ! -x "$DMG_VENV/bin/dmgbuild" ]; then
   echo ">>> Installing dmgbuild into $DMG_VENV (one-time; needs network for pip)"
   python3 -m venv "$DMG_VENV"
   # --no-cache-dir avoids noisy/broken pip cache deserialization on some machines
   "$DMG_VENV/bin/pip" install -q --no-cache-dir --upgrade pip
   "$DMG_VENV/bin/pip" install -q --no-cache-dir -r "$DMG_REQ"
fi

DMG_BG_FALLBACK="$SCRIPT_DIR/assets/ztoryc-dmg-background.png"

# dmgbuild does not mount the *output* DMG. This only clears stale /Volumes/Ztoryc*
# from a previous local open of an installer DMG (avoids name clashes / busy volume).
if [ -z "${CI:-}" ] && [ -z "${GITHUB_ACTIONS:-}" ]; then
   _had_ztoryc_vol=0
   while IFS= read -r _vol; do
      [ -n "$_vol" ] || continue
      _had_ztoryc_vol=1
      hdiutil detach "$_vol" -force >/dev/null 2>&1 || true
   done < <(find /Volumes -maxdepth 1 \( -name 'Ztoryc' -o -name 'Ztoryc *' \) 2>/dev/null)
   if [ "$_had_ztoryc_vol" = "1" ]; then
      echo ">>> Detached leftover Ztoryc installer volume(s) under /Volumes (not opened by this script)"
   fi
fi

let MAXTRY=5
for TRY in $(seq 1 $MAXTRY)
do
   if [ $TRY -gt 1 ]; then
      echo ">>> dmgbuild retry $TRY/$MAXTRY..."
      sleep $((TRY * 3))
   fi
   DMG_STAGE=$(mktemp -d "$REPO_ROOT/toonz/build/.ztoryc_dmg_bg.XXXXXX")
   mkdir -p "$DMG_STAGE/.background"
   if ! python3 "$SCRIPT_DIR/render-dmg-background.py" "$DMG_STAGE/.background/background.png"; then
      echo ">>> WARN: render-dmg-background.py failed, trying fallback asset"
      if [ -f "$DMG_BG_FALLBACK" ]; then
         cp "$DMG_BG_FALLBACK" "$DMG_STAGE/.background/background.png"
      fi
   fi

   APP_ABS="$(pwd)/Ztoryc.app"
   BG_ABS="$DMG_STAGE/.background/background.png"
   rm -f "$OUTPUT_DMG"

   if "$DMG_VENV/bin/dmgbuild" -s "$SCRIPT_DIR/ztoryc_dmg_settings.py" \
         -D "app=$APP_ABS" -D "bg=$BG_ABS" \
         "Ztoryc" "$OUTPUT_DMG"; then
      rm -rf "$DMG_STAGE"
      echo ">>> DMG created successfully: $OUTPUT_DMG"
      exit 0
   fi
   rm -rf "$DMG_STAGE"
done

echo "ERROR: dmgbuild failed after $MAXTRY attempts. Aborting!"
exit 1


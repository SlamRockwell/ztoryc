#!/bin/bash
export TAHOMA2DVERSION=1.6
#source /opt/qt515/bin/qt515-env.sh

echo ">>> Temporary install of Ztoryc"
SCRIPTPATH=`dirname "$0"`
export BUILDDIR=$SCRIPTPATH/../../toonz/build
cd $BUILDDIR
# Leave one processor available for other processing if possible
parallel=$(($(nproc) < 2 ? 1 : $(nproc) - 1))
sudo make -j "$parallel" install

sudo ldconfig

echo ">>> Creating appDir"
if [ -d appdir ]
then
   rm -rf appdir
fi
mkdir -p appdir/usr

echo ">>> Copy and configure Ztoryc installation in appDir"
cp -r /opt/tahoma2d/* appdir/usr
cp appdir/usr/share/applications/*.desktop appdir
cp appdir/usr/share/icons/hicolor/128x128/apps/*.png appdir
mv appdir/usr/lib/tahoma2d/* appdir/usr/lib
rmdir appdir/usr/lib/tahoma2d

echo ">>> Creating Ztoryc directory"
if [ -d Ztoryc ]
then
   rm -rf Ztoryc
fi
mkdir Ztoryc

echo ">>> Copying stuff to Ztoryc/tahomastuff"

mv appdir/usr/share/tahoma2d/stuff Ztoryc/tahomastuff
chmod -R 777 Ztoryc/tahomastuff
rmdir appdir/usr/share/tahoma2d

find Ztoryc/tahomastuff -name .gitkeep -exec rm -f {} \;

if [ -d ../../thirdparty/apps/ffmpeg/bin ]
then
   echo ">>> Copying FFmpeg to Ztoryc/ffmpeg"
   if [ -d Ztoryc/ffmpeg ]
   then
      rm -rf Ztoryc/ffmpeg
   fi
   mkdir -p Ztoryc/ffmpeg
   cp -R ../../thirdparty/apps/ffmpeg/bin/ffmpeg ../../thirdparty/apps/ffmpeg/bin/ffprobe Ztoryc/ffmpeg
   if [ -d ../../thirdparty/apps/ffmpeg/lib ]
   then
      cp -R ../../thirdparty/apps/ffmpeg/lib Ztoryc/ffmpeg/
   fi
   chmod -R 755 Ztoryc/ffmpeg
fi

if [ -d ../../thirdparty/apps/rhubarb ]
then
   echo ">>> Copying Rhubarb Lip Sync to Ztoryc/rhubarb"
   if [ -d Ztoryc/rhubarb ]
   then
      rm -rf Ztoryc/rhubarb
   fi
   mkdir -p Ztoryc/rhubarb
   cp -R ../../thirdparty/apps/rhubarb/rhubarb ../../thirdparty/apps/rhubarb/res Ztoryc/rhubarb
   chmod 755 -R Ztoryc/rhubarb
fi

if [ -d ../../thirdparty/canon/Library ]
then
   echo ">>> Copying canon libraries"
   cp -R ../../thirdparty/canon/Library/x86_64/* appdir/usr/lib
fi

echo ">>> Copying libghoto2 supporting directories"
cp -r /usr/local/lib/libgphoto2 appdir/usr/lib
cp -r /usr/local/lib/libgphoto2_port appdir/usr/lib

rm appdir/usr/lib/libgphoto2/print-camera-list
find appdir/usr/lib/libgphoto2* -name *.la -exec rm -f {} \;
find appdir/usr/lib/libgphoto2* -name *.so -exec patchelf --set-rpath '$ORIGIN/../..' {} \;

echo ">>> Creating Ztoryc/Ztoryc.AppImage"

if [ -f /usr/lib/qt5/bin/linuxdeployqt ]
then
   LINUXDEPLOYQT=/usr/lib/qt5/bin/linuxdeployqt
else
if [ ! -f linuxdeployqt*.AppImage ]
then
   wget -c "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
   chmod a+x linuxdeployqt*.AppImage
fi
   LINUXDEPLOYQT=./linuxdeployqt*.AppImage
fi

export LD_LIBRARY_PATH=appdir/usr/lib/tahoma2d
$LINUXDEPLOYQT appdir/usr/bin/Ztoryc -bundle-non-qt-libs -verbose=0 -always-overwrite -no-strip \
   -executable=appdir/usr/bin/lzocompress \
   -executable=appdir/usr/bin/lzodecompress \
   -executable=appdir/usr/bin/tcleanup \
   -executable=appdir/usr/bin/tcomposer \
   -executable=appdir/usr/bin/tconverter \
   -executable=appdir/usr/bin/tfarmcontroller \
   -executable=appdir/usr/bin/tfarmserver 

rm appdir/AppRun
cp ../sources/scripts/AppRun appdir
chmod 775 appdir/AppRun

$LINUXDEPLOYQT appdir/usr/bin/Ztoryc -appimage -no-strip

mv Ztoryc*.AppImage Ztoryc/Ztoryc.AppImage

echo ">>> Creating Ztoryc Linux package"

tar zcf Ztoryc-linux.tar.gz Ztoryc

echo ">>> Creating Ztoryc Debian Package"

chmod +x ../installer/linux/deb-creator/debcreator.sh 

../installer/linux/deb-creator/debcreator.sh \
 -p $TAHOMA2DVERSION \
 -v $TAHOMA2DVERSION \
 -t ../installer/linux/deb-creator/deb-template \
 -x ./appdir \
 -f ./Ztoryc/ffmpeg \
 -r ./Ztoryc/rhubarb \
 -s ../../stuff

 mv ztoryc_*_amd64.deb Ztoryc-linux.deb
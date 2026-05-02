#!/bin/sh
INIFILE=/Applications/Ztoryc.app/Contents/Resources/SystemVar.ini
STUFF_DIR="/Applications/Ztoryc/Ztoryc_stuff"
if [ -f ztorycstuffdirloc ]
then
   STUFF_DIR=`cat ztorycstuffdirloc`
elif [ -f tahoma2dstuffdirloc ]
then
   STUFF_DIR=`cat tahoma2dstuffdirloc`
fi

# Archive is bzip2 (see app.rb: tar cjvf) — use -j, not -z (gzip).
tar xjvf stuff.tar.bz2

if [ ! -d "$STUFF_DIR" ]
then
   mkdir -p "$STUFF_DIR"
fi

cp -rf stuff/* "$STUFF_DIR/"
rm -rf stuff

chmod -R 777 "$STUFF_DIR"

xxx=`echo "$STUFF_DIR" | sed -e"s/\//|/g"`
sed -e"s/.Applications.*Ztoryc_stuff/$xxx/" "$INIFILE" | sed -e"s/|/\//g" >| temp.ini
sudo mv -f temp.ini "$INIFILE"


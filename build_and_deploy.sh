#!/bin/zsh
# build_and_deploy.sh
# Compila Ztoryc e aggiorna Ztoryc.app
# Uso: ./build_and_deploy.sh [file.cpp opzionale da toccare]

WORKSPACE="/Volumes/ZioSam/tahoma2d-workspace/tahoma2d"
BUILD="$WORKSPACE/toonz/build"
APP="$WORKSPACE/toonz/Ztoryc.app"
MACOS="$APP/Contents/MacOS"

if [ -n "$1" ]; then
  echo "→ Touch $1..."
  touch "$1"
fi

echo "→ Compilazione..."
ninja -j4 -C "$BUILD" 2>&1 | grep -E "error:|Linking|up-to-date"

echo "→ Copia binario..."
cp "$BUILD/toonz/Ztoryc.app/Contents/MacOS/Ztoryc" "$MACOS/Ztoryc"

echo "→ Copia dylib Ztoryc..."
# Dylib modificate da Ztoryc — aggiornate ad ogni build:
cp "$BUILD/libtoonzlib.dylib"           "$MACOS/"
cp "$BUILD/libtnzcore.dylib"            "$MACOS/"
cp "$BUILD/tnzbase/libtnzbase.dylib"    "$MACOS/"
cp "$BUILD/sound/libsound.dylib"        "$MACOS/"
cp "$BUILD/tnztools/libtnztools.dylib"  "$MACOS/"

echo "→ Patch rpath libimage (libtiff: /usr/local/lib → @executable_path)..."
install_name_tool -change \
  /usr/local/lib/libtiff.5.dylib \
  @executable_path/libtiff.5.dylib \
  "$BUILD/image/libimage.dylib" 2>/dev/null || true
cp "$BUILD/image/libimage.dylib" "$MACOS/"

# Dylib secondarie (raramente cambiate) — aggiorna dal build tree se presente
for lib in libcolorfx.dylib libtnzstdfx.dylib libtoonzqt.dylib libtfarm.dylib libtnzext.dylib; do
  actual=$(find "$BUILD" -name "$lib" -not -path "*/Ztoryc.app/*" -not -path "*CMakeFiles*" 2>/dev/null | head -1)
  if [ -n "$actual" ]; then
    cp "$actual" "$MACOS/"
  fi
done

echo "→ Copia risorse..."
# SystemVar.ini: path assoluti alle risorse (stuff dir).
# Viene scritto esplicitamente con chiavi sia TAHOMA2D* che ZTORYC* per coprire
# l'init anticipata di TEnv (che usa toUpper(appName)="ZTORYC" come prefix
# prima che main.cpp chiami setSystemVarPrefix("TAHOMA2D")).
SYSVAR="$APP/Contents/Resources/SystemVar.ini"
STUFF="$WORKSPACE/stuff"
cat > "$SYSVAR" << EOF
TAHOMA2DROOT=$STUFF
TAHOMA2DPROFILES=$STUFF/profiles
TAHOMA2DCONFIG=$STUFF/config
ZTORYCROOT=$STUFF
ZTORYCPROFILES=$STUFF/profiles
ZTORYCCONFIG=$STUFF/config
EOF

echo "→ Copia helper LZO..."
cp "$BUILD/lzocompress"   "$MACOS/lzocompress"
cp "$BUILD/lzodecompress" "$MACOS/lzodecompress"

echo "→ Rimozione xattr e runtime artifacts prima della firma..."
# Rimuove attributi estesi (com.apple.provenance ecc.) che invalidano il seal
xattr -cr "$APP" 2>/dev/null || true
# Rimuove directory create a runtime dall'app (profiles/, cache/ ecc.)
# che non fanno parte del bundle sigillato
rm -rf "$APP/profiles" "$APP/cache" "$APP/logs" 2>/dev/null || true

echo "→ Firma codice (dylib prima, poi bundle)..."
# Prima firma ogni dylib singolarmente
for f in "$MACOS"/*.dylib; do
  codesign --force --sign - "$f" 2>/dev/null
done
# Poi firma i binari helper
codesign --force --sign - "$MACOS/lzocompress"   2>/dev/null
codesign --force --sign - "$MACOS/lzodecompress" 2>/dev/null
# Infine firma il bundle completo (senza --deep per evitare re-firma ricorsiva)
codesign --force --sign - --entitlements "$WORKSPACE/Ztoryc.entitlements" "$APP"

echo "✓ Fatto. Apertura app..."
open "$APP"

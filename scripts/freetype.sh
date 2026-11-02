#!/usr/bin/env bash
# 8u has no bundled FreeType for Linux, and the font library of the desktop module links against one,
# so it is built here for the target and handed to configure. configure insists on a shared library, which
# then has to travel in the image beside the font library that links it.
. "$(dirname "$0")/common.sh"
FT_VERSION=2.13.3
FT_SHA256=0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
OUT=$WORK/freetype-android
[ -f "$OUT/lib/libfreetype.so" ] && { log "freetype already built"; exit 0; }
mkdir -p "$DL"
[ -f "$DL/freetype-$FT_VERSION.tar.xz" ] || curl -fL --retry 5 -o "$DL/freetype-$FT_VERSION.tar.xz" "https://download.savannah.gnu.org/releases/freetype/freetype-$FT_VERSION.tar.xz"
verify "$DL/freetype-$FT_VERSION.tar.xz" "$FT_SHA256"
build=$WORK/freetype-build
rm -rf "$build" "$OUT" && mkdir -p "$build" "$OUT"
tar -xJf "$DL/freetype-$FT_VERSION.tar.xz" -C "$build" --strip-components=1
cd "$build"
CC="$LLVM/bin/aarch64-linux-android28-clang" AR="$LLVM/bin/llvm-ar" RANLIB="$LLVM/bin/llvm-ranlib" CFLAGS="-O2 -fPIC" \
  ./configure --host=aarch64-linux-android --prefix="$OUT" --enable-shared --disable-static \
  --with-zlib=no --with-bzip2=no --with-png=no --with-harfbuzz=no --with-brotli=no
make -j"${JOBS:-$(nproc)}" && make install
log "freetype $FT_VERSION in $OUT"

#!/usr/bin/env bash
# Needs on the host: clang, llvm, autoconf, make, and the cups, fontconfig and alsa headers under /usr/include.
. "$(dirname "$0")/common.sh"
STUBS=$WORK/stubs
mkdir -p "$STUBS"
# Android has no libpthread or librt, the JDK build links both by name.
for lib in libpthread.a librt.a; do rm -f "$STUBS/$lib"; "$LLVM/bin/llvm-ar" rcs "$STUBS/$lib"; done

cd "$SRC"
JAVA_HOME= bash configure \
  --with-conf-name=$CONF \
  --openjdk-target=aarch64-linux-android \
  --with-toolchain-type=clang \
  --with-boot-jdk="$BOOT" \
  --with-jvm-variants=server \
  --with-debug-level=release \
  --with-version-opt=nexira.android \
  --enable-headless-only \
  --with-sysroot="$LLVM/sysroot" \
  --with-toolchain-path="$LLVM/bin" \
  --with-freetype=bundled --with-zlib=bundled --with-libpng=bundled --with-giflib=bundled --with-libjpeg=bundled --with-lcms=bundled \
  --with-cups-include=/usr/include --with-fontconfig-include=/usr/include --with-alsa-include=/usr/include \
  --disable-warnings-as-errors --disable-precompiled-headers \
  --with-extra-ldflags="-L$STUBS" \
  CC="$LLVM/bin/aarch64-linux-android28-clang" CXX="$LLVM/bin/aarch64-linux-android28-clang++" \
  AR="$LLVM/bin/llvm-ar" NM="$LLVM/bin/llvm-nm" OBJCOPY="$LLVM/bin/llvm-objcopy" OBJDUMP="$LLVM/bin/llvm-objdump" \
  STRIP="$LLVM/bin/llvm-strip" CXXFILT="$LLVM/bin/llvm-cxxfilt" \
  BUILD_CC=/usr/bin/clang BUILD_CXX=/usr/bin/clang++ BUILD_NM=/usr/bin/llvm-nm BUILD_AR=/usr/bin/llvm-ar \
  BUILD_OBJCOPY=/usr/bin/llvm-objcopy BUILD_STRIP=/usr/bin/llvm-strip \
  --with-jobs="${JOBS:-$(nproc)}"

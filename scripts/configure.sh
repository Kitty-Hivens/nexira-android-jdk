#!/usr/bin/env bash
# Needs on the host: clang, llvm, autoconf, make, and the cups, fontconfig and alsa headers under /usr/include.
. "$(dirname "$0")/common.sh"
STUBS=$WORK/stubs
mkdir -p "$STUBS"
# Android has no libpthread or librt, the JDK build links both by name.
for lib in libpthread.a librt.a; do rm -f "$STUBS/$lib"; "$LLVM/bin/llvm-ar" rcs "$STUBS/$lib"; done

# Before 25 even a headless build asks for X11, though only the headers are read. The host's are
# enough, and the library directory is the empty stub one so no host library is ever linked.
# The toolkit header Intrinsic.h is only listed by the check and never included by a headless build,
# so a host without it gets an empty one in a directory of links to the host's own headers.
X11_ARGS=()
if [ "$MAJOR" -lt 25 ]; then
  XINC=$WORK/x11inc
  rm -rf "$XINC" && mkdir -p "$XINC/X11"
  ln -s /usr/include/X11/* "$XINC/X11/" 2>/dev/null || true
  [ -e "$XINC/X11/Intrinsic.h" ] || : > "$XINC/X11/Intrinsic.h"
  X11_ARGS=(--x-includes="$XINC" --x-libraries="$STUBS")
fi
# 17 and 8 do not ask for X11 in a headless build, but the headless AWT library still includes its headers.
if [ "$MAJOR" -le 17 ]; then X11_ARGS+=(--with-extra-cflags="-I$XINC" --with-extra-cxxflags="-I$XINC"); fi
# 8u does not make its native libraries position independent on its own, which a shared library needs.
# Its VM also calls methods on a null mark word, which a newer compiler may assume cannot happen unless
# it is told otherwise, as the later releases already do for clang.
if [ "$MAJOR" = 8 ]; then X11_ARGS=(--x-includes="$XINC" --x-libraries="$STUBS" --with-extra-cflags="-I$XINC -fPIC" --with-extra-cxxflags="-I$XINC -fPIC -fno-delete-null-pointer-checks"); fi

# The cups, fontconfig and alsa headers are only read, but pointing the build at all of /usr/include
# puts the host's C library headers ahead of the NDK sysroot's in every file of the desktop libraries.
HOSTINC=$WORK/hostinc
if [ "$MAJOR" -lt 25 ]; then
  rm -rf "$HOSTINC" && mkdir -p "$HOSTINC"
  for d in cups fontconfig alsa; do ln -s "/usr/include/$d" "$HOSTINC/$d"; done
  INCLUDES=$HOSTINC
else
  INCLUDES=/usr/include
fi

if [ "$MAJOR" = 8 ]; then
  "$(dirname "$0")/freetype.sh" 8
  FT=$WORK/freetype-android
  cd "$SRC"
  # 8u calls the headless switch --disable-headful, takes its zlib and giflib from the source tree
  # and has no flags for the other bundled libraries. lld refuses a version script that names a symbol the
  # library no longer defines, where the GNU linker skips it, and the 8u scripts have several. Its version string is set in pieces.
  JAVA_HOME= bash configure "${X11_ARGS[@]}" \
    --with-conf-name=$CONF \
    --openjdk-target=aarch64-linux-android \
    --with-toolchain-type=clang \
    --with-boot-jdk="$BOOT" \
    --with-jvm-variants=server \
    --with-debug-level=release \
    --with-user-release-suffix=nexira.android \
    --disable-headful \
    --with-sysroot="$LLVM/sysroot" \
    --with-toolchain-path="$LLVM/bin" \
    --with-freetype-include="$FT/include/freetype2" --with-freetype-lib="$FT/lib" \
    --with-zlib=bundled --with-giflib=bundled \
    --with-cups-include="$INCLUDES" --with-fontconfig-include="$INCLUDES" --with-alsa-include="$INCLUDES" \
    --with-extra-ldflags="-L$STUBS -Wl,--undefined-version" \
    CC="$LLVM/bin/aarch64-linux-android28-clang" CXX="$LLVM/bin/aarch64-linux-android28-clang++" \
    AR="$LLVM/bin/llvm-ar" NM="$LLVM/bin/llvm-nm" OBJCOPY="$LLVM/bin/llvm-objcopy" OBJDUMP="$LLVM/bin/llvm-objdump" \
    STRIP="$LLVM/bin/llvm-strip" \
    BUILD_CC=/usr/bin/clang BUILD_CXX=/usr/bin/clang++ BUILD_NM=/usr/bin/llvm-nm BUILD_AR=/usr/bin/llvm-ar \
    --with-jobs="${JOBS:-$(nproc)}"
  exit
fi

cd "$SRC"
JAVA_HOME= bash configure "${X11_ARGS[@]}" \
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
  --with-cups-include="$INCLUDES" --with-fontconfig-include="$INCLUDES" --with-alsa-include="$INCLUDES" \
  --disable-warnings-as-errors --disable-precompiled-headers \
  --with-extra-ldflags="-L$STUBS" \
  CC="$LLVM/bin/aarch64-linux-android28-clang" CXX="$LLVM/bin/aarch64-linux-android28-clang++" \
  AR="$LLVM/bin/llvm-ar" NM="$LLVM/bin/llvm-nm" OBJCOPY="$LLVM/bin/llvm-objcopy" OBJDUMP="$LLVM/bin/llvm-objdump" \
  STRIP="$LLVM/bin/llvm-strip" CXXFILT="$LLVM/bin/llvm-cxxfilt" \
  BUILD_CC=/usr/bin/clang BUILD_CXX=/usr/bin/clang++ BUILD_NM=/usr/bin/llvm-nm BUILD_AR=/usr/bin/llvm-ar \
  BUILD_OBJCOPY=/usr/bin/llvm-objcopy BUILD_STRIP=/usr/bin/llvm-strip \
  --with-jobs="${JOBS:-$(nproc)}"

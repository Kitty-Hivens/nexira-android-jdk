#!/usr/bin/env bash
# Cuts the built image down to what the embedded VM loads and writes <out>/<name>.zip with its SHA-256.
. "$(dirname "$0")/common.sh"
IMAGE=${IMAGE:-$SRC/build/$CONF/images/jdk}
OUT=${OUT:-$WORK/out}
if [ "$MAJOR" = 8 ]; then
  # 8 has no module image: the runtime to ship is the JRE image, whose libraries sit under lib/aarch64.
  IMAGE=$SRC/build/$CONF/images/j2re-image
  update=$(awk -F'"' '/^JAVA_VERSION=/ { print $2 }' "$IMAGE/release" | awk -F_ '{ print $2 }')
  version=8u$update
else
  version=$(awk -F'"' '/^JAVA_VERSION=/ { print $2 }' "$IMAGE/release")
fi
name=jdk-$version-android-aarch64
stage=$OUT/$name

rm -rf "$stage" && mkdir -p "$stage"
if [ "$MAJOR" = 8 ]; then
  cp -r "$IMAGE/lib" "$IMAGE/release" "$stage/"
  cd "$stage"
  rm -rf lib/applet lib/images lib/jexec lib/jexec.diz lib/aarch64/*.diz lib/aarch64/libjdwp.so lib/aarch64/libattach.so \
    lib/aarch64/libj2pcsc.so lib/aarch64/libj2pkcs11.so lib/aarch64/libj2gss.so lib/aarch64/libsctp.so lib/aarch64/libhprof.so \
    lib/aarch64/libdt_socket.so lib/aarch64/libjsdt.so lib/aarch64/libjava_crw_demo.so
  # The font library is linked against this one, and a loader in an app does not look beside it.
  cp -P "$WORK"/freetype-android/lib/libfreetype.so* lib/aarch64/
  # 8u links the C++ runtime dynamically, where 17 and later carry what they need.
  cp "$LLVM/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" lib/aarch64/
else
cp -r "$IMAGE/lib" "$IMAGE/conf" "$IMAGE/release" "$stage/"
cd "$stage"
# No launcher runs from the app, and the debugging, attach and smartcard pieces are not used.
rm -rf lib/src.zip lib/ct.sym lib/jexec lib/jspawnhelper lib/jfr lib/classlist lib/psfont* \
  lib/libjdwp.so lib/libattach.so lib/libj2pcsc.so lib/libj2pkcs11.so lib/libj2gss.so lib/libjaas.so \
  lib/librmi.so lib/libsctp.so lib/libmanagement_agent.so lib/libjawt.so
fi
find . -name '*.so' -exec "$LLVM/bin/llvm-strip" --strip-unneeded {} +

cd "$OUT"
rm -f "$name.zip" && zip -qr -X -9 "$name.zip" "$name"
sha256sum "$name.zip" > "$name.zip.sha256"
log "$(du -h "$name.zip" | cut -f1) $OUT/$name.zip"
cat "$name.zip.sha256"

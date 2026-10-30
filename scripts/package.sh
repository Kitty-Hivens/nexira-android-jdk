#!/usr/bin/env bash
# Cuts the built image down to what the embedded VM loads and writes <out>/<name>.zip with its SHA-256.
. "$(dirname "$0")/common.sh"
IMAGE=${IMAGE:-$SRC/build/$CONF/images/jdk}
OUT=${OUT:-$WORK/out}
version=$(awk -F'"' '/^JAVA_VERSION=/ { print $2 }' "$IMAGE/release")
name=jdk-$version-android-aarch64
stage=$OUT/$name

rm -rf "$stage" && mkdir -p "$stage"
cp -r "$IMAGE/lib" "$IMAGE/conf" "$IMAGE/release" "$stage/"
cd "$stage"
# No launcher runs from the app, and the debugging, attach and smartcard pieces are not used.
rm -rf lib/src.zip lib/ct.sym lib/jexec lib/jspawnhelper lib/jfr lib/classlist lib/psfont* \
  lib/libjdwp.so lib/libattach.so lib/libj2pcsc.so lib/libj2pkcs11.so lib/libj2gss.so lib/libjaas.so \
  lib/librmi.so lib/libsctp.so lib/libmanagement_agent.so lib/libjawt.so
find . -name '*.so' -exec "$LLVM/bin/llvm-strip" --strip-unneeded {} +

cd "$OUT"
rm -f "$name.zip" && zip -qr -X -9 "$name.zip" "$name"
sha256sum "$name.zip" > "$name.zip.sha256"
log "$(du -h "$name.zip" | cut -f1) $OUT/$name.zip"
cat "$name.zip.sha256"

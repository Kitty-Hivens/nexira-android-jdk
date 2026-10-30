#!/usr/bin/env bash
# Downloads and checks the NDK, the boot JDK and the upstream source at the pinned commit.
. "$(dirname "$0")/common.sh"
mkdir -p "$DL" "$WORK/ndk"

get() {
  [ -f "$DL/$1" ] || { log "download $1"; curl -fL --retry 5 --retry-delay 5 -C - -o "$DL/$1" "$2"; }
  verify "$DL/$1" "$3"
}

get "$(basename "$NDK_URL")" "$NDK_URL" "$NDK_SHA256"
[ -d "$NDK" ] || unzip -q "$DL/$(basename "$NDK_URL")" -d "$WORK/ndk"

get "boot-$MAJOR.tar.gz" "$BOOT_URL" "$BOOT_SHA256"
if [ ! -x "$BOOT/bin/java" ]; then
  mkdir -p "$BOOT"
  tar -xzf "$DL/boot-$MAJOR.tar.gz" -C "$BOOT" --strip-components=1
fi

if [ ! -d "$SRC/.git" ]; then
  log "clone $UPSTREAM $TAG"
  git clone --depth 1 --branch "$TAG" "$UPSTREAM" "$SRC"
fi
[ "$(git -C "$SRC" rev-parse "$TAG^{commit}")" = "$COMMIT" ] || { log "$TAG is not $COMMIT"; exit 1; }
log "sources ready at $SRC"

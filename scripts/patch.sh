#!/usr/bin/env bash
# Resets the source tree to the pinned commit and applies the series from patches/jdk-<major>.
. "$(dirname "$0")/common.sh"
git -C "$SRC" reset -q --hard "$COMMIT"
git -C "$SRC" clean -qdf
for p in "$ROOT/patches/jdk-$MAJOR"/*.patch; do
  git -C "$SRC" apply --index "$p" || { log "does not apply: $(basename "$p")"; exit 1; }
done
git -C "$SRC" -c user.name=build -c user.email=build@localhost commit -q -m "android patches"
log "applied $(ls "$ROOT/patches/jdk-$MAJOR"/*.patch | wc -l) patches"

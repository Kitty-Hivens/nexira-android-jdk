#!/usr/bin/env bash
# Whole pipeline for one major: fetch, patch, configure, make, package.
here=$(dirname "$0")
"$here/fetch.sh" "$1"
"$here/patch.sh" "$1"
"$here/configure.sh" "$1"
. "$here/common.sh"
# 8u turns on its tracing probes whenever the HOST has the SystemTap header, and the target has none.
# The headless switch of configure leaves the splash screen and X toolkit libraries in, so make is told too.
# It also builds its VM with warnings as errors, which a clang newer than its sources fails on.
EXTRA=()
if [ "$MAJOR" = 8 ]; then EXTRA=(SDT_H_FILE=/nonexistent WARNINGS_ARE_ERRORS= BUILD_HEADLESS_ONLY=1); fi
make -C "$SRC" CONF=$CONF JOBS="${JOBS:-$(nproc)}" images "${EXTRA[@]}"
"$here/package.sh" "$1"

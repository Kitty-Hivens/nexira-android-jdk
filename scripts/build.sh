#!/usr/bin/env bash
# Whole pipeline for one major: fetch, patch, configure, make, package.
here=$(dirname "$0")
"$here/fetch.sh" "$1"
"$here/patch.sh" "$1"
"$here/configure.sh" "$1"
. "$here/common.sh"
make -C "$SRC" CONF=$CONF JOBS="${JOBS:-$(nproc)}" images
"$here/package.sh" "$1"

# Sourced by the other scripts: loads the version file for the major and fixes the work layout.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MAJOR=${1:?usage: $(basename "$0") <major>}
. "$ROOT/toolchain.env"
. "$ROOT/versions/$MAJOR.env"
WORK=${WORK:-$ROOT/work}
DL=$WORK/dl
SRC=$WORK/jdk$MAJOR
NDK=$WORK/ndk/android-ndk-$NDK_REV
LLVM=$NDK/toolchains/llvm/prebuilt/linux-x86_64
BOOT=$WORK/boot-$MAJOR
CONF=android-aarch64

log() { echo "[$(date +%H:%M:%S)] $*"; }

verify() {
  echo "$2  $1" | sha256sum -c --quiet - || { log "checksum mismatch: $1"; exit 1; }
}

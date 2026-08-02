#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh

# Keep Xcode's internal SwiftPM Git probes non-interactive. A configured
# credential helper must never stall documentation generation.
export GIT_TERMINAL_PROMPT=0
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=credential.helper
export GIT_CONFIG_VALUE_0=''

if (( $# > 1 )); then
    printf 'Usage: %s [derived-data-directory]\n' "$0" >&2
    exit 64
fi

CLEAN_UP=false
if (( $# == 1 )); then
    DOCC_DERIVED_DATA="$1"
    mkdir -p "$DOCC_DERIVED_DATA"
else
    DOCC_DERIVED_DATA="$(mktemp -d -t voxelia-docc.XXXXXX)"
    CLEAN_UP=true
fi

clean_up() {
    if [[ "$CLEAN_UP" == true && -d "$DOCC_DERIVED_DATA" ]]; then
        rm -rf -- "$DOCC_DERIVED_DATA"
    fi
}
trap clean_up EXIT

xcodebuild -quiet docbuild \
    -scheme Voxelia-Package \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$DOCC_DERIVED_DATA" \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=YES \
    OTHER_DOCC_FLAGS='--warnings-as-errors'

python3 Tools/Scripts/check_docc_archives.py \
    "$DOCC_DERIVED_DATA/Build/Products/Debug"

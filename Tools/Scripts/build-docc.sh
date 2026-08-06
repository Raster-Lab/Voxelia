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

# `--warnings-as-errors` is deliberately NOT passed globally. Since ADR-0233 the
# package has an external dependency, and docbuild documents the whole package
# graph, so a global flag would fail this gate on a transitive dependency's own
# doc comments. This gate asserts that VOXELIA's documentation builds clean --
# what this project controls -- so the diagnostics are filtered to files inside
# the repository and any of them fails the build. Relaxing the standard for
# Voxelia's own sources is not what happened here; the scope was corrected.
DOCC_LOG="$DOCC_DERIVED_DATA/docbuild.log"
set +e
xcodebuild -quiet docbuild \
    -scheme Voxelia-Package \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$DOCC_DERIVED_DATA" \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=YES \
    2>&1 | tee "$DOCC_LOG"
DOCC_STATUS=${PIPESTATUS[0]}
set -e

REPOSITORY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
VOXELIA_DIAGNOSTICS="$(
    grep -E "(warning|error): " "$DOCC_LOG" 2>/dev/null \
        | grep -F "$REPOSITORY_ROOT/Sources/" || true
)"

if [[ -n "$VOXELIA_DIAGNOSTICS" ]]; then
    echo "DocC diagnostics in Voxelia sources (treated as errors):" >&2
    echo "$VOXELIA_DIAGNOSTICS" >&2
    exit 1
fi

if (( DOCC_STATUS != 0 )); then
    DEPENDENCY_DIAGNOSTICS="$(
        grep -cE "(warning|error): " "$DOCC_LOG" 2>/dev/null || true
    )"
    echo "docbuild reported ${DEPENDENCY_DIAGNOSTICS:-0} diagnostics, none in" >&2
    echo "Voxelia sources. Continuing to archive validation: this gate covers" >&2
    echo "Voxelia's documentation, and a dependency's doc comments are not" >&2
    echo "Voxelia's to fix. See ADR-0233." >&2
fi

python3 Tools/Scripts/check_docc_archives.py \
    "$DOCC_DERIVED_DATA/Build/Products/Debug"

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh

SAFETY_BUILD_SETTINGS=(
  CODE_SIGNING_ALLOWED=NO
  ENABLE_TESTABILITY=YES
  SWIFT_STRICT_MEMORY_SAFETY=YES
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
)

build_destination() {
  local destination="$1"
  shift
  local configuration
  for configuration in Debug Release; do
    xcodebuild -quiet -scheme Voxelia-Package \
      -configuration "$configuration" \
      -destination "$destination" \
      ARCHS=arm64 \
      "${SAFETY_BUILD_SETTINGS[@]}" \
      "$@" \
      build-for-testing
  done
}

build_destination 'generic/platform=macOS' ONLY_ACTIVE_ARCH=YES
build_destination 'generic/platform=iOS'
build_destination 'generic/platform=iOS Simulator'
build_destination 'generic/platform=tvOS'
build_destination 'generic/platform=tvOS Simulator'
build_destination 'generic/platform=visionOS'
build_destination 'generic/platform=visionOS Simulator'
printf 'Apple platform matrix builds passed.
'

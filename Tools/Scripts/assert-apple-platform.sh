#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  printf 'Voxelia requires an Apple Silicon Mac running macOS.
' >&2
  exit 64
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  printf 'Voxelia requires Xcode and the Apple developer toolchain.
' >&2
  exit 69
fi

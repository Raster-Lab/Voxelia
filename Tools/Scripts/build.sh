#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
swift build
swift build -c release
swift build --package-path Validation
swift build --package-path Benchmarks
swift build --package-path Tools
printf 'All package builds passed.
'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
Tools/Scripts/test-repository-scripts.sh
swift test
swift test --package-path Validation
swift test --package-path Benchmarks
swift test --package-path Tools
printf 'All package tests passed.
'

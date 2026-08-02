#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
printf 'Repository: %s
' "$ROOT"
swift --version
python3 --version
swift package describe >/dev/null
printf 'Bootstrap checks passed.
'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
for script in Tools/Scripts/*.sh; do
  bash -n "$script"
done
python3 -m compileall -q Tools/Scripts Tools/Tests/Python
python3 -m unittest discover -s Tools/Tests/Python -p 'test_*.py'
printf 'Repository script regression tests passed.
'

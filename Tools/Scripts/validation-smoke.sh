#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
swift run --package-path Validation voxelia-validation --self-check

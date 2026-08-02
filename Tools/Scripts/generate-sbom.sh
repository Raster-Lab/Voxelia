#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
OUT="${1:-docs/releases/v0.1.1/SBOM.scaffold.generated.json}"
mkdir -p "$(dirname "$OUT")"
python3 Tools/Scripts/generate_sbom.py "$OUT"

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
Tools/Scripts/generate-sbom.sh
python3 Tools/Scripts/generate_sbom.py --validate \
  docs/releases/v0.1.1/SBOM.scaffold.generated.json
python3 Tools/Scripts/check_release_integrity.py --write
Tools/Scripts/validate-scaffold.sh
Tools/Scripts/build.sh
Tools/Scripts/test.sh
python3 Tools/Scripts/check_release_integrity.py
printf 'Release-candidate scaffold checks completed.
'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
Tools/Scripts/validate-scaffold.sh
Tools/Scripts/build.sh
Tools/Scripts/test.sh
Tools/Scripts/generate-sbom.sh
printf 'Release-candidate scaffold checks completed.
'

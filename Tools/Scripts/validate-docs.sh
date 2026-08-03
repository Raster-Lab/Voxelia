#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
python3 Tools/Scripts/check_front_matter.py
python3 Tools/Scripts/check_adr_register.py
python3 Tools/Scripts/check_rfc_register.py
python3 Tools/Scripts/check_document_text.py
printf 'Documentation validation passed.
'

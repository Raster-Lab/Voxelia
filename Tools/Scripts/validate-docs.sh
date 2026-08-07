#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
python3 Tools/Scripts/check_front_matter.py
python3 Tools/Scripts/check_adr_register.py
python3 Tools/Scripts/check_adr_links.py
python3 Tools/Scripts/check_rfc_register.py
python3 Tools/Scripts/check_document_text.py
python3 Tools/Scripts/check_requirement_traceability.py
python3 Tools/Scripts/check_test_levels.py
python3 Tools/Scripts/check_temporary_files.py
python3 Tools/Scripts/check_example_safety.py
python3 Tools/Scripts/check_british_english.py
python3 Tools/Scripts/check_licence_policy.py
printf 'Documentation validation passed.
'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
python3 Tools/Scripts/check_required_files.py
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py
python3 Tools/Scripts/check_package_graph_static.py
python3 Tools/Scripts/check_package_graph.py
python3 Tools/Scripts/check_prohibited_imports.py
python3 Tools/Scripts/check_apple_platform_policy.py
python3 Tools/Scripts/check_front_matter.py
python3 Tools/Scripts/check_adr_register.py
python3 Tools/Scripts/check_rfc_register.py
python3 Tools/Scripts/check_document_text.py
python3 Tools/Scripts/generate_requirement_index.py --check
Tools/Scripts/test-repository-scripts.sh
swift package describe >/dev/null
swift test
swift run --package-path Validation voxelia-validation --self-check
swift run --package-path Benchmarks voxelia-benchmark --self-check
swift run --package-path Tools voxelia-repo-check --self-check
printf 'M0 scaffold validation passed.
'

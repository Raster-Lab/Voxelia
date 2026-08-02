#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
Tools/Scripts/assert-apple-platform.sh
OUT="${1:-docs/releases/v0.1.1/SBOM.scaffold.generated.json}"
mkdir -p "$(dirname "$OUT")"
python3 - "$OUT" <<'PYSBOM'
import json
import subprocess
import sys
from pathlib import Path

out = Path(sys.argv[1])
package = json.loads(subprocess.check_output(["swift", "package", "dump-package"], text=True))
components = [{"name": target["name"], "type": target["type"]} for target in package["targets"]]
out.write_text(
    json.dumps(
        {
            "bomFormat": "Voxelia-Scaffold-SBOM",
            "specVersion": "0.1.1",
            "project": "Voxelia",
            "platform": "Apple Silicon ARM64 and Apple operating systems only",
            "externalRuntimeDependencies": [],
            "components": components,
        },
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
print(out)
PYSBOM

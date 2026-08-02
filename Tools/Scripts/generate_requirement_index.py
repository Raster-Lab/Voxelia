#!/usr/bin/env python3
"""Extract VOX requirement identifiers and their table fields."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
source = ROOT / "docs" / "project" / "Voxelia_Requirements_Baseline_v0.1.1.md"
out = ROOT / "docs" / "releases" / "v0.1.1" / "Requirements_Traceability_Index.json"
text = source.read_text(encoding="utf-8")
row_pattern = re.compile(
    r"^\| `(?P<id>VOX-[A-Z0-9]+-\d{3})` \| (?P<text>.*?) \| (?P<priority>P[0-2]) \| (?P<verification>.*?) \| (?P<target>M\d+) \|$",
    re.MULTILINE,
)
rows = [match.groupdict() for match in row_pattern.finditer(text)]
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({"schemaVersion": "0.1.1", "requirements": rows}, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {len(rows)} requirements to {out.relative_to(ROOT)}")

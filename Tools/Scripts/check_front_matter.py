#!/usr/bin/env python3
"""Validate YAML-front-matter presence in controlled project documents."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTROLLED = ROOT / "docs" / "project"
REQUIRED = {"document_id", "title", "version", "status", "document_type", "project", "licence", "language", "date", "owner"}
errors = []
paths = [p for p in sorted(CONTROLLED.glob("*.md")) if p.name != "README.md"]
for path in paths:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        errors.append(f"{path.name}: missing opening front matter")
        continue
    end = text.find("\n---\n", 4)
    if end == -1:
        errors.append(f"{path.name}: missing closing front matter")
        continue
    block = text[4:end]
    keys = {match.group(1) for match in re.finditer(r"^([A-Za-z0-9_]+):", block, re.MULTILINE)}
    missing = sorted(REQUIRED - keys)
    if missing:
        errors.append(f"{path.name}: missing {', '.join(missing)}")
if errors:
    print("Front-matter check failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)
print(f"Front-matter check passed for {len(paths)} documents.")

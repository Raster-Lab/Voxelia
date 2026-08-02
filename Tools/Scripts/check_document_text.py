#!/usr/bin/env python3
"""Validate controlled Markdown text for layout-risking characters."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
errors: list[str] = []
checked = 0

for path in sorted(DOCS.rglob("*.md")):
    checked += 1
    text = path.read_text(encoding="utf-8")
    for line_number, line in enumerate(text.splitlines(), 1):
        if "	" in line:
            errors.append(f"{path.relative_to(ROOT)}:{line_number}: contains a tab character")
        if line.rstrip(" ") != line:
            errors.append(f"{path.relative_to(ROOT)}:{line_number}: contains trailing whitespace")
    if chr(0) in text:
        errors.append(f"{path.relative_to(ROOT)}: contains a NUL character")

if errors:
    print("Documentation text check failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print(f"Documentation text check passed for {checked} Markdown files.")

#!/usr/bin/env python3
"""Hold documentation prose to British spelling, per `ADR-0321` (`VOX-DOC-003`).

That row requires British English "except where external standards or programming
identifiers require otherwise", and nothing enforced it: `check_document_text.py` is thirty
lines and checks other things entirely. A measurement found 73 American spellings in prose.

The exemption is honoured structurally rather than by a list of blessed words. **Fenced
blocks and inline code are stripped before scanning**, so an identifier, a DICOM keyword or a
quoted API name is invisible to this check as long as it is written as code -- which this
project's style already does. A record quoting a misspelling as evidence must likewise put it
in backticks, exactly as `ADR-0309` had to for links.

This is a RATCHET, following `check_requirement_traceability.py` and `ADR-0301`: the 73
existing hits are recorded per file in `docs/progress/american-spellings.txt`. A file's count
may shrink but never grow, and a file absent from the baseline may introduce none.
"""

from __future__ import annotations

import os
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(os.environ.get("VOXELIA_ROOT", Path(__file__).resolve().parents[2]))
DOCS = ROOT / "docs"
BASELINE = ROOT / os.environ.get(
    "VOXELIA_AMERICAN_SPELLINGS", "docs/progress/american-spellings.txt"
)

AMERICAN = [
    "behavior", "behaviors", "normalize", "normalized", "normalizes", "normalization",
    "serialize", "serialized", "serialization", "initialize", "initialized",
    "optimize", "optimized", "optimization", "analyze", "analyzed", "authorize",
    "authorized", "organize", "organized", "recognize", "recognized", "summarize",
    "visualize", "minimize", "maximize", "utilize", "color", "colors", "gray",
    "catalog", "defense", "fiber", "meter", "meters",
]
PATTERNS = [(re.compile(r"\b" + word + r"\b", re.IGNORECASE), word) for word in AMERICAN]

FENCE = re.compile(r"```.*?```", re.DOTALL)
INLINE = re.compile(r"`[^`]*`")


def prose(source: str) -> str:
    """Blanks code, keeping newlines so line numbers stay true."""

    def blank(match: re.Match[str]) -> str:
        return re.sub(r"[^\n]", " ", match.group(0))

    return INLINE.sub(blank, FENCE.sub(blank, source))


def scan() -> tuple[Counter[str], list[str]]:
    counts: Counter[str] = Counter()
    findings: list[str] = []
    for path in sorted(DOCS.rglob("*.md")):
        relative = path.relative_to(ROOT).as_posix()
        text = prose(path.read_text())
        for pattern, word in PATTERNS:
            for hit in pattern.finditer(text):
                counts[relative] += 1
                line = text[: hit.start()].count("\n") + 1
                findings.append(f"{relative}:{line}: American spelling '{word}'")
    return counts, findings


def read_baseline() -> dict[str, int]:
    entries: dict[str, int] = {}
    if not BASELINE.exists():
        return entries
    for raw in BASELINE.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        count, _, name = line.partition(" ")
        entries[name.strip()] = int(count)
    return entries


def main() -> int:
    counts, findings = scan()
    if "--write" in sys.argv:
        lines = [
            "# American spellings in documentation prose, per `ADR-0321`.",
            "# A count may shrink but never grow, and a file absent here may add none.",
            "# Regenerate deliberately with --write, never to silence a failure.",
        ]
        lines += [f"{counts[name]} {name}" for name in sorted(counts)]
        BASELINE.write_text("\n".join(lines) + "\n")
        print(f"British-English baseline written: {sum(counts.values())} spellings.")
        return 0

    baseline = read_baseline()
    errors: list[str] = []
    for name in sorted(counts):
        allowed = baseline.get(name)
        if allowed is None:
            errors.append(f"ERROR: {name} introduces {counts[name]} American spelling(s)")
        elif counts[name] > allowed:
            errors.append(
                f"ERROR: {name} has {counts[name]} American spellings, above its"
                f" baseline of {allowed}"
            )
    if errors:
        for error in errors:
            print(error)
        for finding in findings[:20]:
            print(f"  {finding}")
        return 1
    print(
        f"British-English check passed: {sum(counts.values())} spellings within baseline"
        f" across {len(counts)} file(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

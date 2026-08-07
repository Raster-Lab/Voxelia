#!/usr/bin/env python3
"""Keep unstructured concurrency out of the interaction module, per `ADR-0327`.

`VOX-CON-005` requires that interactive draw callbacks not launch overlapping unstructured
work. `ADR-0326` located every unstructured site in `Sources/` and found four, all in
`VoxeliaExecution`, all binding a task to a name and sharing it -- the coalescing pattern,
which prevents overlap rather than creating it. `VoxeliaInteraction` had none, and nothing
stopped the next increment adding one.

This is a boundary rather than a ban, in the shape `ADR-0311` used for Metal Performance
Shaders. Detached and bare tasks are legitimate in the coordinators that deduplicate work;
they are forbidden in the module a draw callback calls into, because a task launched there is
launched per draw.

`EmissionTask` and similar identifiers are not matched: the pattern requires a word boundary
before `Task`, so a name merely ending in it is invisible. `ADR-0326` found exactly that false
positive by hand, and the pattern is written so the gate does not repeat it.
"""

from __future__ import annotations

import os
import re
from pathlib import Path

ROOT = Path(os.environ.get("VOXELIA_ROOT", Path(__file__).resolve().parents[2]))
SOURCES = ROOT / "Sources"

# Modules a draw callback calls into, which must launch nothing per draw.
FORBIDDEN_IN = ("VoxeliaInteraction",)

PATTERNS = (
    (re.compile(r"\bTask\.detached\b"), "Task.detached"),
    (re.compile(r"\bTask\s*\{"), "an unstructured `Task {`"),
    (re.compile(r"\bTask\.init\b"), "Task.init"),
)


def main() -> int:
    findings: list[str] = []
    scanned = 0
    for module in FORBIDDEN_IN:
        for path in sorted((SOURCES / module).rglob("*.swift")):
            scanned += 1
            source = path.read_text()
            for number, text in enumerate(source.splitlines(), start=1):
                for pattern, name in PATTERNS:
                    if pattern.search(text):
                        findings.append(
                            f"{path.relative_to(ROOT).as_posix()}:{number}: {name} in"
                            f" {module}; `VOX-CON-005` forbids a draw callback launching"
                            " unstructured work"
                        )
    if findings:
        print("Unstructured-concurrency check failed:")
        for finding in findings:
            print(f"- {finding}")
        return 1
    print(
        f"Unstructured-concurrency check passed: {scanned} source(s) in"
        f" {', '.join(FORBIDDEN_IN)} launch nothing."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

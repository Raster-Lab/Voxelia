#!/usr/bin/env python3
"""Enforce the test-level taxonomy `VOX-VAL-001` requires.

That row requires Voxelia to "maintain automated unit, kernel, operation, pipeline,
integration and system-reference test levels". Nothing enforced it, and the measurement
`ADR-0301` took shows what an unenforced vocabulary drifts into: four of the six named
levels had no tag at all, three tags the row never named were in use, and one spelling
-- `Boundary` -- appeared exactly once in 1,229 tests.

This check is a RATCHET for the untagged backlog and a CLEAN GATE for everything else,
following `check_requirement_traceability.py`'s precedent. The tests that carried no
level when it was written are recorded in `docs/progress/untagged-tests.txt` as an
explicit debt baseline: a file's count may shrink but never grow, and a file absent from
the baseline may not introduce untagged tests at all.

The two rules that are clean from day one:

  * every level tag must be in the frozen vocabulary, so a fresh singleton cannot appear;
  * every one of the six levels the requirement names must have at least one test, so a
    level cannot quietly empty out.
"""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TESTS = ROOT / "Tests"
BASELINE = ROOT / "docs/progress/untagged-tests.txt"

# The six `VOX-VAL-001` names, in the tag spellings this repository uses.
REQUIRED_LEVELS = {
    "Unit",
    "Kernel",
    "Operation",
    "Pipeline",
    "Integration",
    "SystemReference",
}

# Levels that exist and the requirement does not name. They are admitted rather than
# rewritten: `Concurrency` and `Oracle` each mark a real and distinct kind of test, and a
# gate that rejected them would delete information instead of enforcing a taxonomy.
ADDITIONAL_LEVELS = {"Concurrency", "Oracle"}

VOCABULARY = REQUIRED_LEVELS | ADDITIONAL_LEVELS

TEST_ATTRIBUTE = re.compile(r"@Test\(")
LEVEL_PREFIX = re.compile(r'"\s*\[([A-Za-z-]+)\]')


def scan() -> tuple[Counter[str], Counter[str], list[str]]:
    """Returns level counts, per-file untagged counts, and unknown-tag findings."""

    levels: Counter[str] = Counter()
    untagged: Counter[str] = Counter()
    unknown: list[str] = []
    for path in sorted(TESTS.rglob("*.swift")):
        source = path.read_text()
        relative = path.relative_to(ROOT).as_posix()
        for match in TEST_ATTRIBUTE.finditer(source):
            # The display string may sit on the following line when the attribute wraps,
            # so the prefix is matched against the text after the attribute rather than
            # against the same line.
            tail = source[match.end() : match.end() + 200].lstrip()
            prefix = LEVEL_PREFIX.match(tail)
            if prefix is None:
                untagged[relative] += 1
                continue
            tag = prefix.group(1)
            if tag not in VOCABULARY:
                line = source[: match.start()].count("\n") + 1
                unknown.append(f"{relative}:{line}: unknown test level [{tag}]")
            levels[tag] += 1
    return levels, untagged, unknown


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


def write_baseline(untagged: Counter[str]) -> None:
    lines = [
        "# Tests carrying no level tag, per `ADR-0301`.",
        "# A count may shrink but never grow, and a file absent here may not add any.",
        "# Regenerate deliberately with `check_test_levels.py --write`, never to silence a"
        " failure.",
    ]
    for name in sorted(untagged):
        lines.append(f"{untagged[name]} {name}")
    BASELINE.write_text("\n".join(lines) + "\n")


def main() -> int:
    levels, untagged, unknown = scan()
    errors = list(unknown)

    missing = sorted(REQUIRED_LEVELS - set(levels))
    for level in missing:
        errors.append(
            f"ERROR: no test declares the required level [{level}]; `VOX-VAL-001` names it"
        )

    if "--write" in sys.argv:
        write_baseline(untagged)
        print(f"Untagged-test baseline written: {sum(untagged.values())} tests.")
    else:
        baseline = read_baseline()
        for name in sorted(untagged):
            allowed = baseline.get(name)
            if allowed is None:
                errors.append(
                    f"ERROR: {name} introduces {untagged[name]} test(s) with no level tag;"
                    " new tests must declare one"
                )
            elif untagged[name] > allowed:
                errors.append(
                    f"ERROR: {name} has {untagged[name]} untagged tests, above its"
                    f" baseline of {allowed}"
                )

    if errors:
        for error in errors:
            print(error)
        return 1

    total = sum(levels.values()) + sum(untagged.values())
    summary = ", ".join(f"{name} {levels[name]}" for name in sorted(levels))
    print(
        f"Test level check passed for {total} tests: {summary};"
        f" {sum(untagged.values())} untagged within baseline."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

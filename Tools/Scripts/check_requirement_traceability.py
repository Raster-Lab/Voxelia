#!/usr/bin/env python3
"""Fail when a requirement in an entered milestone is traced nowhere.

`VOX-DOC-008` requires every requirement to be traceable to architecture,
implementation, tests and validation. Nothing enforced that, and the omission
hid `VOX-MPR-011` — a baseline row that reached no accepted record and not one
ledger entry — until a manual sweep found it. Two other rows had been missed the
same way earlier.

This check is a RATCHET, not a clean gate. The rows untraced when it was written
are recorded in `docs/progress/untraced-requirements.txt` as an explicit debt
baseline. The check fails when a row outside that list becomes untraced, so the
debt can shrink but never grow. A clean gate would have been red on the day it
landed and would have been switched off.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASELINE = ROOT / "docs/project/Voxelia_Requirements_Baseline_v0.1.1.md"
ALLOWLIST = ROOT / "docs/progress/untraced-requirements.txt"

# Milestones the project has entered. Raise this as a milestone opens; a row in
# a future milestone is not yet due and is not a gap.
HIGHEST_ENTERED_MILESTONE = 6

# Directories searched for a mention. A requirement named in a decision record,
# an algorithm specification, the ledger, a source comment or a test name is
# traced; one named nowhere is not.
SEARCH_DIRECTORIES = (
    "docs/progress",
    "docs/architecture",
    "docs/algorithms",
    "Sources",
    "Tests",
    "Tools",
    "Benchmarks",
    "Validation",
)
SEARCH_SUFFIXES = (".md", ".swift", ".py", ".json", ".txt")

# Files that list identifiers by construction, so counting them as mentions
# would make the check vacuous. The allowlist is one of them: it lives under a
# searched directory, and the first run of this check caught itself reporting
# every allowlisted row as newly traced the moment the list was written.
EXCLUDED_NAMES = (
    "Requirements_Baseline",
    "Requirements_Traceability_Index",
    "untraced-requirements",
)

ROW = re.compile(
    r"\|\s*`(VOX-[A-Z0-9]+-\d+)`\s*\|(.*?)\|\s*(P\d)\s*\|\s*([A-Z,]+)\s*\|"
    r"\s*(M\d+)\s*\|"
)


def baseline_rows() -> list:
    rows = []
    for line in BASELINE.read_text(encoding="utf-8").splitlines():
        match = ROW.match(line)
        if match:
            rows.append(
                {
                    "id": match.group(1),
                    "priority": match.group(3),
                    "verification": match.group(4),
                    "milestone": match.group(5),
                }
            )
    return rows


def corpus() -> str:
    parts = []
    for directory in SEARCH_DIRECTORIES:
        base = ROOT / directory
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix not in SEARCH_SUFFIXES:
                continue
            if any(name in path.name for name in EXCLUDED_NAMES):
                continue
            parts.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(parts)


def allowed() -> set:
    if not ALLOWLIST.exists():
        return set()
    entries = set()
    for line in ALLOWLIST.read_text(encoding="utf-8").splitlines():
        stripped = line.split("#", 1)[0].strip()
        if stripped:
            entries.add(stripped)
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--write",
        action="store_true",
        help="rewrite the allowlist to the current untraced set",
    )
    arguments = parser.parse_args()

    rows = baseline_rows()
    text = corpus()
    entered = [
        row
        for row in rows
        if int(row["milestone"][1:]) <= HIGHEST_ENTERED_MILESTONE
    ]
    untraced = sorted(
        row["id"] for row in entered if row["id"] not in text
    )

    if arguments.write:
        header = (
            "# Requirements in entered milestones traced by no record, source\n"
            "# or test, recorded by ADR-0216 as an explicit debt baseline.\n"
            "# Tools/Scripts/check_requirement_traceability.py fails when a row\n"
            "# outside this list becomes untraced, so the debt can shrink but\n"
            "# never grow. Remove a line when its row is genuinely traced.\n"
        )
        ALLOWLIST.write_text(
            header + "\n".join(untraced) + "\n", encoding="utf-8"
        )
        print(f"Untraced-requirement allowlist updated: {len(untraced)} rows.")
        return 0

    permitted = allowed()
    new = [identifier for identifier in untraced if identifier not in permitted]
    if new:
        print(
            "Requirement traceability check FAILED: "
            f"{len(new)} requirement(s) in entered milestones are traced by no "
            "record, source or test, and are not in the recorded debt "
            "baseline."
        )
        for identifier in new:
            print(f"  {identifier}")
        print(
            "\nTrace each one in the record that satisfies it, or add it to "
            f"{ALLOWLIST.relative_to(ROOT)} with a recorded reason."
        )
        return 1

    resolved = sorted(permitted - set(untraced))
    if resolved:
        print(
            "Requirement traceability check FAILED: "
            f"{len(resolved)} allowlisted row(s) are now traced. Remove them "
            "from the allowlist so the ratchet keeps its grip."
        )
        for identifier in resolved:
            print(f"  {identifier}")
        return 1

    print(
        "Requirement traceability check passed: "
        f"{len(entered)} requirements in entered milestones, "
        f"{len(untraced)} untraced and all recorded as known debt."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

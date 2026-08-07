#!/usr/bin/env python3
"""Resolve every architecture-decision cross-reference, per `ADR-0309` (`VOX-DOC-009`).

That row requires architecture deviations to be "linked to approved ADRs". Every record
carries a `## Supersession` section and `check_adr_register.py` requires it, so the *shape*
of the linkage was enforced. Its *targets* were not: nothing resolved a link, so a record
could cite a number that does not exist -- and two did -- or one whose status was never
approved.

Two rules, both clean:

  * every `ADR-NNNN...md` link inside a decision record must resolve to a file that exists;
  * that file's `status` must be `Accepted`, because the row says *approved*, not *written*.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DECISIONS = ROOT / "docs/architecture/decisions"

LINK = re.compile(r"\]\((ADR-\d{4}[^)#]*\.md)\)")
STATUS = re.compile(r'^status:\s*"([^"]+)"', re.MULTILINE)
FENCE = re.compile(r"^```", re.MULTILINE)


def outside_fences(source: str) -> str:
    """Blanks fenced blocks, keeping offsets so reported line numbers stay true.

    A record quoting a broken link as an illustration is doing the right thing --
    `ADR-0309` does exactly that about the two it repairs. A checker that could not tell a
    citation from an example would push authors to stop showing their evidence.
    """

    kept = list(source)
    inside = False
    previous = 0
    for fence in FENCE.finditer(source):
        if inside:
            for index in range(previous, fence.start()):
                if kept[index] != "\n":
                    kept[index] = " "
        inside = not inside
        previous = fence.end()
    if inside:
        for index in range(previous, len(source)):
            if kept[index] != "\n":
                kept[index] = " "
    return "".join(kept)


def main() -> int:
    statuses: dict[str, str] = {}
    for path in DECISIONS.glob("ADR-*.md"):
        found = STATUS.search(path.read_text())
        statuses[path.name] = found.group(1) if found else "(none)"

    errors: list[str] = []
    total = 0
    for path in sorted(DECISIONS.glob("ADR-*.md")):
        source = outside_fences(path.read_text())
        for match in LINK.finditer(source):
            total += 1
            target = match.group(1)
            line = source[: match.start()].count("\n") + 1
            if target not in statuses:
                errors.append(f"{path.name}:{line}: link to {target}, which does not exist")
            elif statuses[target] != "Accepted":
                errors.append(
                    f"{path.name}:{line}: link to {target}, whose status is"
                    f" {statuses[target]} rather than Accepted"
                )

    if errors:
        print("Architecture decision link check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(
        f"Architecture decision link check passed: {total} cross-references across"
        f" {len(statuses)} records, all resolving to approved decisions."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

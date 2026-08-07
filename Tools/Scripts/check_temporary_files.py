#!/usr/bin/env python3
"""Keep temporary-file creation in product code explicit and declared.

`VOX-SEC-005` requires that "temporary-file creation shall be explicit, documented and
configurable". `ADR-0302` measured the product surface and found **no temporary-file
creation at all** -- but as an accident of implementation, not a stated property. Nothing
documented it and nothing stopped the next increment from adding one silently.

So the rule is not a ban. Any temporary-file site in `Sources/` must be declared in
`docs/progress/temporary-file-sites.txt` together with the record that authorised it, which
is what makes the creation explicit and documented. Whether the site is *configurable* is a
design question that record has to answer; this check makes sure the record exists.

Tests are out of scope. A test creating a scratch directory produces no product artefact on
a user's machine, and forcing declarations for them would bury the product sites the rule
cares about.
"""

from __future__ import annotations

import os
import re
from pathlib import Path

# Overridable so the self-tests can point the check at a fixture tree. Unset in every real
# invocation, which is the only way this check is ever run outside its own tests.
ROOT = Path(os.environ.get("VOXELIA_ROOT", Path(__file__).resolve().parents[2]))
SOURCES = ROOT / os.environ.get("VOXELIA_SOURCES", "Sources")
DECLARATIONS = ROOT / os.environ.get(
    "VOXELIA_TEMPORARY_FILE_SITES", "docs/progress/temporary-file-sites.txt"
)

# The Foundation and POSIX spellings that create or name a temporary location. Matched as
# whole words so an identifier that merely contains one does not trip the check.
PATTERNS = [
    re.compile(r"\btemporaryDirectory\b"),
    re.compile(r"\bNSTemporaryDirectory\b"),
    re.compile(r"\bitemReplacementDirectory\b"),
    re.compile(r"\bmkstemp\b"),
    re.compile(r"\bmkdtemp\b"),
    re.compile(r"\btmpfile\b"),
    re.compile(r"\btmpnam\b"),
    re.compile(r'"/tmp'),
    re.compile(r'"/var/tmp'),
]


def declared_sites() -> set[str]:
    """Declared sites, as `path:line` keys."""

    sites: set[str] = set()
    if not DECLARATIONS.exists():
        return sites
    for raw in DECLARATIONS.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        sites.add(line.split(" ", 1)[0])
    return sites


def main() -> int:
    declared = declared_sites()
    findings: list[str] = []
    scanned = 0
    for path in sorted(SOURCES.rglob("*.swift")):
        scanned += 1
        relative = path.relative_to(ROOT).as_posix()
        for number, text in enumerate(path.read_text().splitlines(), start=1):
            for pattern in PATTERNS:
                if pattern.search(text):
                    key = f"{relative}:{number}"
                    if key not in declared:
                        findings.append(
                            f"ERROR: {key} creates or names a temporary location and is not"
                            " declared in docs/progress/temporary-file-sites.txt;"
                            " `VOX-SEC-005` requires it to be explicit and documented"
                        )
                    break

    if findings:
        for finding in findings:
            print(finding)
        return 1

    print(
        f"Temporary-file check passed: {scanned} product sources scanned,"
        f" {len(declared)} declared site(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

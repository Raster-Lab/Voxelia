#!/usr/bin/env python3
"""Enforce the two licence-posture properties nothing was checking.

`ADR-0219` found both while tracing the governance and licence requirements,
and both are the pattern `ADR-0196` first recorded: a claim asserted in accepted
places and enforced in none.

1. **No external package dependencies.** `VOX-LIC-007` forbids strong-copyleft
   dependencies in core distribution targets, `VOX-LIC-008` requires restrictive
   ones to be isolated in optional modules, `VOX-LIC-009` requires dependency
   licences to be checked for compatibility, and `VOX-REP-009` requires external
   dependencies to be attached only to the targets needing them. Every one of
   those is satisfied today for a single reason: `Package.swift` declares
   `dependencies: []`. Nothing enforced that, so one added line would have
   silently invalidated four accepted requirements at once — and third-party
   dependencies are reserved to the project owner.

2. **Every Swift source carries the SPDX identifier.** `VOX-LIC-003` asks for it
   where technically applicable; all 395 files carried it and nothing checked.

Neither check needs an allowlist: both properties hold completely today, so
these are clean gates rather than ratchets.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Package.swift"
SOURCE_DIRECTORIES = ("Sources", "Tests")
SPDX = "SPDX-License-Identifier: MIT"

# The manifest's own package-level dependency list, which must stay empty.
DEPENDENCY_LIST = re.compile(r"^\s*dependencies:\s*\[\s*\]\s*,\s*$", re.M)


def main() -> int:
    errors = []

    manifest = MANIFEST.read_text(encoding="utf-8")
    if not DEPENDENCY_LIST.search(manifest):
        errors.append(
            "Package.swift no longer declares an empty package-level "
            "`dependencies: []`. Adding an external dependency needs an "
            "accepted record and the owner's decision: it bears directly on "
            "VOX-LIC-007, VOX-LIC-008, VOX-LIC-009 and VOX-REP-009, all of "
            "which are satisfied today only because there are none."
        )

    missing = []
    for directory in SOURCE_DIRECTORIES:
        base = ROOT / directory
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*.swift")):
            if SPDX not in path.read_text(encoding="utf-8", errors="ignore"):
                missing.append(path.relative_to(ROOT))
    if missing:
        errors.append(
            f"{len(missing)} Swift source file(s) lack "
            f"`{SPDX}` (VOX-LIC-003):"
        )
        errors.extend(f"  {path}" for path in missing)

    if errors:
        print("Licence policy check FAILED:")
        for line in errors:
            print(line)
        return 1

    counted = sum(
        len(list((ROOT / directory).rglob("*.swift")))
        for directory in SOURCE_DIRECTORIES
        if (ROOT / directory).is_dir()
    )
    print(
        "Licence policy check passed: no external package dependencies, and "
        f"{counted} Swift sources carry the SPDX identifier."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

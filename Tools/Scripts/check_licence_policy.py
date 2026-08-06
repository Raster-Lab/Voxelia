#!/usr/bin/env python3
"""Enforce the two licence-posture properties nothing was checking.

`ADR-0219` found both while tracing the governance and licence requirements,
and both are the pattern `ADR-0196` first recorded: a claim asserted in accepted
places and enforced in none.

1. **The dependency closure is exactly the approved one.** `VOX-LIC-007` forbids
   strong-copyleft dependencies in core distribution targets, `VOX-LIC-008`
   requires restrictive ones to be isolated in optional modules, `VOX-LIC-009`
   requires dependency licences to be checked for compatibility, and
   `VOX-REP-009` requires external dependencies to be attached only to the
   targets needing them.

   Until `ADR-0233` these held because `Package.swift` declared
   `dependencies: []`. That is no longer true, so the check was **strengthened
   rather than relaxed**: it now pins the *declared* dependencies, the whole
   *resolved closure* with each package's recorded licence, and the set of
   targets permitted to link an external product.

   The closure check exists because of a specific finding. `ADR-0231` read
   DICOMKit's manifest and recorded five transitive packages; resolving the graph
   produced **six**, with `CompressionFamily` arriving a level further down.
   Reading a manifest gives one level; only resolution gives the closure — so a
   version bump that pulls in a seventh package now fails this gate instead of
   passing unnoticed.

2. **Every Swift source carries the SPDX identifier.** `VOX-LIC-003` asks for it
   where technically applicable; all 395 files carried it and nothing checked.

The closure allowlist is an approval record, not a debt ratchet: every entry
names a package the owner approved and a licence that was established. Adding a
line to it is a governance act.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Package.swift"
SOURCE_DIRECTORIES = ("Sources", "Tests")
SPDX = "SPDX-License-Identifier: MIT"

RESOLVED = ROOT / "Package.resolved"

# The only package-level dependency Voxelia declares, at the exact pinned
# version the owner approved. Adding to this needs an accepted record.
APPROVED_DECLARED = {
    "https://github.com/Raster-Lab/DICOMKit.git": "2.2.11",
    # Declared directly under the owner authorisation `ADR-0266` records. It was
    # already in the approved closure below as a transitive DICOMKit dependency
    # with its licence file read, so this widens the LINKAGE claim rather than the
    # trust decision -- but it is still a change only the owner may make.
    "https://github.com/Raster-Lab/J2KSwift.git": "11.0.2",
}

# The complete resolved closure, with the licence recorded for each package and
# how that licence was established. `ADR-0233` holds the evidence.
APPROVED_CLOSURE = {
    "dicomkit": ("2.2.11", "MIT", "licence file read"),
    "swift-argument-parser": ("1.8.2", "Apache-2.0", "licence file read"),
    "j2kswift": ("11.0.2", "MIT", "licence file read"),
    "jliswift": ("0.5.0", "Apache-2.0", "licence file read"),
    "jxlswift": ("1.4.0", "MIT", "licence file read"),
    "jlswift": ("0.9.0", "MIT", "owner grant 2026-08-06; licence file pending"),
    "compressionfamily": ("1.0.0", "MIT", "owner grant 2026-08-06; licence file pending"),
}

# Licences that would trigger VOX-LIC-008's isolation requirement. None of the
# approved closure carries one; the list exists so that a future addition that
# does is refused here rather than argued about later.
RESTRICTIVE_LICENCES = {"GPL-2.0", "GPL-3.0", "AGPL-3.0", "LGPL-2.1", "LGPL-3.0"}

# The only targets permitted to link an external product (VOX-REP-009).
# `VoxeliaCompression` links J2KCodec and J2K3D, and deliberately NOT J2KMetal:
# `VOX-CMP-007` forbids compressed data reaching a sampleable texture, and
# `check_prohibited_imports.py` blocks the import as well as the linkage.
TARGETS_PERMITTED_EXTERNAL_PRODUCTS = {
    "VoxeliaDICOMKit",
    "VoxeliaDICOMKitTests",
    "VoxeliaCompression",
    "VoxeliaCompressionTests",
}

DECLARED_PACKAGE = re.compile(r'\.package\(\s*url:\s*"([^"]+)"\s*,\s*exact:\s*"([^"]+)"')
PRODUCT_USE = re.compile(r'\.product\(\s*name:\s*"[^"]+"\s*,\s*package:\s*"[^"]+"\s*\)')
TARGET_HEADER = re.compile(r'\.(?:test)?[Tt]arget\(\s*\n?\s*name:\s*"([^"]+)"')


def check_declared(manifest: str, errors: list[str]) -> None:
    """The declared dependencies must be exactly the approved set."""
    declared = dict(DECLARED_PACKAGE.findall(manifest))
    if declared != APPROVED_DECLARED:
        errors.append(
            "Package.swift's declared dependencies are not the approved set. "
            f"Approved: {APPROVED_DECLARED}. Found: {declared}. Every change "
            "here bears directly on VOX-LIC-007, VOX-LIC-008, VOX-LIC-009 and "
            "VOX-REP-009, needs an accepted record, and is the project owner's "
            "decision. Do not widen this list to make the gate pass."
        )
    # A non-exact requirement would let the closure drift without a manifest edit.
    loose = re.findall(r'\.package\(\s*url:\s*"([^"]+)"\s*,\s*(?:from|branch|revision|"?upToNextM)', manifest)
    for url in loose:
        errors.append(
            f"Package.swift depends on {url} without an exact version. "
            "Voxelia pins exactly, so the resolved closure cannot change "
            "without a manifest edit that this gate sees."
        )


def check_closure(errors: list[str]) -> None:
    """The resolved closure must be exactly the approved one, licence by licence."""
    if not RESOLVED.is_file():
        errors.append(
            "Package.resolved is missing. The resolved closure is what "
            "VOX-LIC-009 is checked against, so it must be committed."
        )
        return
    try:
        document = json.loads(RESOLVED.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        errors.append(f"Package.resolved is not valid JSON: {error}")
        return

    pins = document.get("pins") or document.get("object", {}).get("pins", [])
    resolved = {
        pin.get("identity", ""): (pin.get("state", {}) or {}).get("version", "")
        for pin in pins
    }

    unexpected = sorted(set(resolved) - set(APPROVED_CLOSURE))
    if unexpected:
        errors.append(
            "Package.resolved contains packages outside the approved closure: "
            f"{unexpected}. A transitive dependency appeared without an "
            "accepted record. ADR-0231 found exactly this: reading a manifest "
            "gives one level, and only resolution gives the closure. Each new "
            "package needs its licence established before VOX-LIC-007 and "
            "VOX-LIC-009 can be discharged."
        )
    absent = sorted(set(APPROVED_CLOSURE) - set(resolved))
    if absent:
        errors.append(
            f"Approved packages are missing from Package.resolved: {absent}. "
            "Re-resolve, or update the approved closure with a record."
        )
    for identity, version in sorted(resolved.items()):
        approved = APPROVED_CLOSURE.get(identity)
        if approved is None:
            continue
        if version != approved[0]:
            errors.append(
                f"{identity} is resolved at {version}, not the approved "
                f"{approved[0]}. A version change can change a licence, so it "
                "needs a record."
            )
        if approved[1] in RESTRICTIVE_LICENCES:
            errors.append(
                f"{identity} carries {approved[1]}, which VOX-LIC-008 requires "
                "to be isolated in an optional module and VOX-LIC-007 forbids "
                "in core distribution targets."
            )


def check_external_product_targets(manifest: str, errors: list[str]) -> None:
    """VOX-REP-009: only the permitted targets may link an external product."""
    positions = [(match.start(), match.group(1)) for match in TARGET_HEADER.finditer(manifest)]
    for match in PRODUCT_USE.finditer(manifest):
        owner = None
        for start, name in positions:
            if start < match.start():
                owner = name
            else:
                break
        if owner is not None and owner not in TARGETS_PERMITTED_EXTERNAL_PRODUCTS:
            errors.append(
                f"Target {owner} links an external product. VOX-REP-009 attaches "
                "external dependencies only to the targets that need them, and "
                f"only {sorted(TARGETS_PERMITTED_EXTERNAL_PRODUCTS)} may."
            )


def main() -> int:
    errors = []

    manifest = MANIFEST.read_text(encoding="utf-8")
    check_declared(manifest, errors)
    check_closure(errors)
    check_external_product_targets(manifest, errors)

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
        f"Licence policy check passed: {len(APPROVED_DECLARED)} declared "
        f"dependency and a {len(APPROVED_CLOSURE)}-package approved closure, "
        f"and {counted} Swift sources carry the SPDX identifier."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

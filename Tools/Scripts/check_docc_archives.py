#!/usr/bin/env python3
"""Verify that DocC produced exactly the expected Voxelia module archives."""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import sys


EXPECTED_ARCHIVES = frozenset(
    {
        "Voxelia.doccarchive",
        "VoxeliaDICOMKit.doccarchive",
        "VoxeliaCompression.doccarchive",
        "VoxeliaCPU.doccarchive",
        "VoxeliaCore.doccarchive",
        "VoxeliaExecution.doccarchive",
        "VoxeliaGeometry.doccarchive",
        "VoxeliaImaging.doccarchive",
        "VoxeliaInteraction.doccarchive",
        "VoxeliaMetal.doccarchive",
        "VoxeliaPhotorealistic.doccarchive",
        "VoxeliaRendering.doccarchive",
        "VoxeliaSpatial.doccarchive",
        "VoxeliaStorage.doccarchive",
        "VoxeliaValidation.doccarchive",
    }
)


def archive_errors(products_directory: Path) -> list[str]:
    """Return deterministic errors for missing, unexpected or duplicate archives."""
    if not products_directory.is_dir():
        return [f"products directory does not exist: {products_directory}"]

    archive_names = [
        path.name
        for path in products_directory.rglob("*.doccarchive")
        if path.is_dir()
    ]
    counts = Counter(archive_names)
    actual = set(archive_names)
    errors: list[str] = []

    # Since ADR-0233 the package has an external dependency, and docbuild
    # documents the whole package graph, so archives for a dependency's targets
    # appear here too. This gate covers VOXELIA's documentation: every expected
    # Voxelia archive must be present, and an unexpected archive is one whose
    # name begins with `Voxelia` -- which still catches a new Voxelia module that
    # nobody added here. A dependency's archives are counted and ignored, never
    # silently discarded.
    missing = sorted(EXPECTED_ARCHIVES - actual)
    unexpected = sorted(
        name
        for name in actual - EXPECTED_ARCHIVES
        if name.startswith("Voxelia")
    )
    duplicates = sorted(name for name, count in counts.items() if count > 1)

    if missing:
        errors.append(f"missing archives: {', '.join(missing)}")
    if unexpected:
        errors.append(
            f"unexpected Voxelia archives: {', '.join(unexpected)}. Add the "
            "module to EXPECTED_ARCHIVES with a record, or explain its absence."
        )
    if duplicates:
        errors.append(f"duplicate archives: {', '.join(duplicates)}")
    return errors


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"Usage: {argv[0]} products-directory", file=sys.stderr)
        return 64

    errors = archive_errors(Path(argv[1]))
    if errors:
        print("DocC archive verification failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    external = sorted(
        path.name
        for path in Path(argv[1]).glob("*.doccarchive")
        if path.name not in EXPECTED_ARCHIVES and not path.name.startswith("Voxelia")
    )
    print(
        "DocC documentation validation passed: "
        f"{len(EXPECTED_ARCHIVES)} expected Voxelia archives generated"
        + (
            f"; {len(external)} external-dependency archives ignored."
            if external
            else "."
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

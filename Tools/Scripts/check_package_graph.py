#!/usr/bin/env python3
"""Validate the M0 Swift target dependency graph."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPECTED = {
    "VoxeliaSpatial": set(),
    "VoxeliaCore": {"VoxeliaSpatial"},
    "VoxeliaStorage": {"VoxeliaCore"},
    "VoxeliaExecution": {"VoxeliaStorage"},
    "VoxeliaImaging": {"VoxeliaExecution"},
    "VoxeliaGeometry": {"VoxeliaCore", "VoxeliaSpatial"},
    "VoxeliaRendering": {"VoxeliaImaging", "VoxeliaGeometry"},
    "VoxeliaInteraction": {"VoxeliaRendering"},
    "VoxeliaCPU": {"VoxeliaImaging", "VoxeliaGeometry", "VoxeliaExecution"},
    "VoxeliaMetal": {"VoxeliaExecution", "VoxeliaRendering"},
    "VoxeliaCompression": {"VoxeliaCore"},
    # Only `byName` dependencies are extracted below, so the external DICOMKit
    # product this target also links is not visible here. That linkage is gated by
    # check_licence_policy.py's TARGETS_PERMITTED_EXTERNAL_PRODUCTS instead.
    "VoxeliaDICOMKit": {"VoxeliaImaging"},
    "VoxeliaTestSupport": {"VoxeliaCore", "VoxeliaValidation"},
    "VoxeliaValidation": {"VoxeliaCPU", "VoxeliaMetal"},
    "Voxelia": {
        "VoxeliaSpatial", "VoxeliaCore", "VoxeliaStorage", "VoxeliaExecution",
        "VoxeliaImaging", "VoxeliaGeometry", "VoxeliaRendering", "VoxeliaInteraction",
    },
}

raw = subprocess.check_output(["swift", "package", "dump-package"], cwd=ROOT, text=True)
data = json.loads(raw)
targets = {target["name"]: target for target in data["targets"]}

actual = {}
for name in EXPECTED:
    target = targets.get(name)
    if target is None:
        print(f"ERROR: missing target {name}")
        sys.exit(1)
    deps = set()
    for dep in target.get("dependencies", []):
        if isinstance(dep, dict) and "byName" in dep:
            value = dep["byName"]
            deps.add(value[0] if isinstance(value, list) else value)
        elif isinstance(dep, str):
            deps.add(dep)
    actual[name] = deps

errors = []

# Every Voxelia library or support target the manifest declares must be registered
# above. Without this the check only visits what EXPECTED lists, so a new module
# escapes graph review entirely -- VoxeliaDICOMKit did so from ADR-0233 until
# ADR-0256. Test targets are excluded: they depend on products by design and are
# not part of the layered graph.
unregistered = sorted(
    name
    for name, target in targets.items()
    if name.startswith("Voxelia")
    and name not in EXPECTED
    and target.get("type") != "test"
)
if unregistered:
    errors.append(
        "unregistered Voxelia targets: "
        + ", ".join(unregistered)
        + ". Add each to EXPECTED with its declared dependencies."
    )

for name, expected in EXPECTED.items():
    if actual[name] != expected:
        errors.append(f"{name}: expected {sorted(expected)}, got {sorted(actual[name])}")

# Cycle detection across production targets.
visiting = set()
visited = set()

def visit(node: str) -> None:
    if node in visiting:
        errors.append(f"dependency cycle includes {node}")
        return
    if node in visited:
        return
    visiting.add(node)
    for dep in actual.get(node, set()):
        if dep in actual:
            visit(dep)
    visiting.remove(node)
    visited.add(node)

for node in actual:
    visit(node)

if errors:
    print("Package graph check failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("Package graph check passed.")
for name in sorted(actual):
    print(f"{name}: {', '.join(sorted(actual[name])) or '(none)'}")

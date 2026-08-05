#!/usr/bin/env python3
"""Statically verify the declared M0 target edges in Package.swift."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
text = (ROOT / "Package.swift").read_text(encoding="utf-8")

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
    "VoxeliaValidation": {"VoxeliaCPU", "VoxeliaMetal"},
    "Voxelia": {
        "VoxeliaSpatial", "VoxeliaCore", "VoxeliaStorage", "VoxeliaExecution",
        "VoxeliaImaging", "VoxeliaGeometry", "VoxeliaRendering", "VoxeliaInteraction",
    },
}

# Extract .target blocks while respecting balanced parentheses.
blocks: dict[str, str] = {}
for match in re.finditer(r"\.target\s*\(", text):
    start = match.start()
    depth = 0
    end = None
    for index in range(match.end() - 1, len(text)):
        char = text[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
    if end is None:
        continue
    block = text[start:end]
    name_match = re.search(r'name:\s*"([^"]+)"', block)
    if name_match:
        blocks[name_match.group(1)] = block

errors: list[str] = []
actual: dict[str, set[str]] = {}
for name, expected in EXPECTED.items():
    block = blocks.get(name)
    if block is None:
        errors.append(f"missing target {name}")
        continue
    dep_match = re.search(r"dependencies:\s*\[(.*?)\]", block, re.DOTALL)
    deps = set(re.findall(r'"(Voxelia[A-Za-z0-9]+)"', dep_match.group(1))) if dep_match else set()
    actual[name] = deps
    if deps != expected:
        errors.append(f"{name}: expected {sorted(expected)}, got {sorted(deps)}")

visiting: set[str] = set()
visited: set[str] = set()

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
    print("Static package graph check failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("Static package graph check passed.")

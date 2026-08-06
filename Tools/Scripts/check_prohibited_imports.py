#!/usr/bin/env python3
"""Reject imports that violate the M0 module boundaries."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROHIBITED = {
    "VoxeliaSpatial": {"Metal", "MetalKit", "RealityKit", "ModelIO", "CoreImage", "DICOMKit"},
    "VoxeliaCore": {"Metal", "MetalKit", "RealityKit", "ModelIO", "CoreImage", "DICOMKit"},
    "VoxeliaStorage": {"Metal", "MetalKit", "RealityKit", "ModelIO", "CoreImage", "DICOMKit"},
    "VoxeliaExecution": {"Metal", "MetalKit", "RealityKit", "ModelIO", "CoreImage", "DICOMKit"},
    "VoxeliaImaging": {"Metal", "MetalKit", "RealityKit", "ModelIO", "CoreImage", "DICOMKit"},
    "VoxeliaGeometry": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreImage",
        "DICOMKit",
    },
    "VoxeliaRendering": {"Metal", "MetalKit", "RealityKit", "ModelIO", "CoreImage", "DICOMKit"},
    "VoxeliaInteraction": {"SwiftUI", "AppKit", "UIKit", "RealityKit", "MetalKit"},
    "VoxeliaCPU": {"Metal", "MetalKit", "RealityKit", "DICOMKit"},
    "VoxeliaMetal": {"DICOMKit", "RealityKit", "ModelIO", "CoreImage"},
}
pattern = re.compile(r"^\s*import\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)
errors = []
for target, prohibited in PROHIBITED.items():
    for path in (ROOT / "Sources" / target).rglob("*.swift"):
        imports = set(pattern.findall(path.read_text(encoding="utf-8")))
        bad = sorted(imports & prohibited)
        if bad:
            errors.append(f"{path.relative_to(ROOT)} imports {', '.join(bad)}")
if errors:
    print("Prohibited import check failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)
print("Prohibited import check passed.")

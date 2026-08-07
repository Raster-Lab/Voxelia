#!/usr/bin/env python3
"""Reject imports that violate the M0 module boundaries.

`VoxeliaCompression` appears twice, and the second entry is the load-bearing one.
`VOX-CMP-007` requires that compressed data is never treated as directly sampleable
Metal texture data, so `VoxeliaCompression` may not import Metal (it cannot build a
texture) and `VoxeliaMetal` may not import `VoxeliaCompression` (the module that can
build textures cannot name a compressed value). `ADR-0196` found a claimed
independence that nothing enforced; `ADR-0256` enforces this one before any codec
arrives.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROHIBITED = {
    "VoxeliaSpatial": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaCore": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaStorage": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaExecution": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaImaging": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaGeometry": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaRendering": {
        "Metal",
        "MetalKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaCompression": {
        "Metal",
        "MetalKit",
        # The codec package ships a `J2KMetal` product. `VOX-CMP-007` forbids
        # compressed data being treated as sampleable texture data, so the Metal
        # product is barred here as firmly as Metal itself -- found by reading
        # J2KSwift's product list before declaring the dependency (`ADR-0267`).
        "J2KMetal",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "DICOMKit",
        "Accelerate",
        "vImage",
    },
    "VoxeliaInteraction": {
        "SwiftUI", "AppKit", "UIKit", "RealityKit", "MetalKit", "ModelIO",
        "CoreML",
        "CreateML",
    },
    "VoxeliaCPU": {"Metal", "MetalKit", "RealityKit", "DICOMKit"},
    "VoxeliaMetal": {
        "DICOMKit",
        "RealityKit",
        "ModelIO",
        "CoreML",
        "CreateML",
        "CoreImage",
        "VoxeliaCompression",
    },
}
# `VOX-HLS-001` requires off-screen rendering without an application window, per `ADR-0303`.
# The four frameworks below are how a window or a view would enter, and every product target
# refuses them -- including `VoxeliaMetal`, which forbade five things and none of these, and
# is the one target that actually talks to the GPU.
WINDOWING = {"AppKit", "UIKit", "SwiftUI", "MetalKit"}
for target in PROHIBITED:
    PROHIBITED[target] = PROHIBITED[target] | WINDOWING

# `VOX-ADP-006` permits Metal Performance Shaders **only behind validated Voxelia
# operations**, so this is a boundary rather than a ban, per `ADR-0311`. `VoxeliaMetal` is the
# one target that may import it, because it is the one where a validated operation wrapping it
# would live. Every other target refuses it, which is what keeps MPS types out of general
# APIs: a type a module cannot import is a type it cannot name in a signature.
ACCELERATION = {"MetalPerformanceShaders", "MetalPerformanceShadersGraph"}
for target in PROHIBITED:
    if target != "VoxeliaMetal":
        PROHIBITED[target] = PROHIBITED[target] | ACCELERATION

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

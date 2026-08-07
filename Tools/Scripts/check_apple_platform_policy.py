#!/usr/bin/env python3
"""Enforce Voxelia's Apple Silicon and Apple operating-system-only policy."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
errors: list[str] = []

required = [
    ROOT / "PLATFORM_SUPPORT.md",
    ROOT / "Tools/Scripts/assert-apple-platform.sh",
    ROOT / "docs/architecture/decisions/ADR-0025-apple-ecosystem-only.md",
]
for path in required:
    if not path.exists():
        errors.append(f"missing {path.relative_to(ROOT)}")

manifest_paths = [ROOT / "Package.swift", ROOT / "Validation/Package.swift", ROOT / "Benchmarks/Package.swift", ROOT / "Tools/Package.swift"]
for path in manifest_paths:
    text = path.read_text(encoding="utf-8")
    if "swift-tools-version: 6.2" not in text:
        errors.append(f"{path.relative_to(ROOT)} does not declare Swift tools 6.2")
    if path.name == "Package.swift" and path.parent == ROOT:
        for token in [".macOS(.v15)", ".iOS(.v18)", ".tvOS(.v18)", ".visionOS(.v2)"]:
            if token not in text:
                errors.append(f"root Package.swift missing {token}")

for workflow in sorted((ROOT / ".github/workflows").glob("*.yml")):
    text = workflow.read_text(encoding="utf-8")
    for match in re.finditer(r"^\s*runs-on:\s*(.+)$", text, re.MULTILINE):
        value = match.group(1)
        for label in ["self-hosted", "macOS", "ARM64", "voxelia"]:
            if label not in value:
                errors.append(f"{workflow.relative_to(ROOT)} runner lacks {label}")

for target_dir in sorted((ROOT / "Sources").iterdir()):
    if target_dir.is_dir() and not (target_dir / "ApplePlatformGate.swift").exists():
        errors.append(f"{target_dir.relative_to(ROOT)} missing ApplePlatformGate.swift")

auxiliary_gates = [
    ROOT / "Tests/Support/ApplePlatformGate.swift",
    ROOT / "Validation/Sources/voxelia-validation/ApplePlatformGate.swift",
    ROOT / "Benchmarks/Sources/voxelia-benchmark/ApplePlatformGate.swift",
    ROOT / "Tools/Sources/voxelia-repo-check/ApplePlatformGate.swift",
]
for path in auxiliary_gates:
    if not path.exists():
        errors.append(f"{path.relative_to(ROOT)} missing Apple platform gate")

metal = (ROOT / "Sources/VoxeliaMetal/Module.swift").read_text(encoding="utf-8")
conditional_metal_import = "#if can" + "Import(Metal)"
if conditional_metal_import in metal or "import Metal" not in metal:
    errors.append("VoxeliaMetal must import Metal unconditionally")

# Active execution/configuration paths must contain no alternative platform targets.
active_roots = [ROOT / ".github", ROOT / "Sources", ROOT / "Validation", ROOT / "Benchmarks", ROOT / "Tools"]
forbidden_patterns = [
    "runs-on: " + "ubu" + "ntu",
    "runs-on: " + "win" + "dows",
    "generic/platform=" + "lin" + "ux",
    "generic/platform=" + "win" + "dows",
]
for active_root in active_roots:
    for path in active_root.rglob("*"):
        if path.resolve() == Path(__file__).resolve():
            continue
        # Resolved third-party checkouts and build products are not the
        # repository's active configuration.
        if ".build" in path.parts or ".swiftpm" in path.parts:
            continue
        if not path.is_file() or path.suffix.lower() not in {".swift", ".py", ".sh", ".yml", ".yaml", ".md"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore").lower()
        for forbidden in forbidden_patterns:
            if forbidden in text:
                errors.append(f"{path.relative_to(ROOT)} contains a prohibited platform configuration")

if errors:
    print("Apple platform policy check failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("Apple platform policy check passed.")

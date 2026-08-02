#!/usr/bin/env python3
"""Check the essential M0 repository files and directories."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
REQUIRED = [
    "Package.swift", "README.md", "LICENSE", "CHANGELOG.md", "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md", "GOVERNANCE.md", "SECURITY.md", "SUPPORT.md",
    "THIRD_PARTY_NOTICES.md", "PLATFORM_SUPPORT.md", "VERSION", "RELEASE.json", ".editorconfig", ".gitattributes", ".gitignore",
    ".swift-format", "Sources", "Tests", "Validation/Package.swift",
    "Benchmarks/Package.swift", "Tools/Package.swift", "Tools/Scripts/assert-apple-platform.sh", "Tools/Scripts/test-repository-scripts.sh", "docs/project", "docs/architecture/decisions/ADR-0001-apple-ecosystem-only.md", ".github/workflows",
]
missing = [item for item in REQUIRED if not (ROOT / item).exists()]
if missing:
    print("Required-file check failed:")
    for item in missing:
        print(f"- {item}")
    sys.exit(1)
print("Required-file check passed.")

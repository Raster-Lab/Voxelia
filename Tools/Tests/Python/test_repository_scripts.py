from __future__ import annotations

import platform
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class RepositoryScriptTests(unittest.TestCase):
    def test_explicit_entry_points_are_not_named_main_swift(self) -> None:
        expected_entry_points = [
            ROOT
            / "Validation/Sources/voxelia-validation/VoxeliaValidationCommand.swift",
            ROOT
            / "Benchmarks/Sources/voxelia-benchmark/VoxeliaBenchmarkCommand.swift",
            ROOT
            / "Tools/Sources/voxelia-repo-check/VoxeliaRepositoryCheck.swift",
        ]
        for path in expected_entry_points:
            self.assertTrue(path.is_file(), path)
            self.assertIn("@main", path.read_text(encoding="utf-8"), path)

        for package in ("Validation", "Benchmarks", "Tools"):
            for path in (ROOT / package / "Sources").rglob("main.swift"):
                self.assertNotIn(
                    "@main",
                    path.read_text(encoding="utf-8"),
                    f"{path} would define both implicit and explicit entry points",
                )

    def test_manifest_paths_pass(self) -> None:
        subprocess.run(
            ["python3", "Tools/Scripts/check_manifest_paths.py"],
            cwd=ROOT,
            check=True,
        )

    def test_requirement_index_passes(self) -> None:
        subprocess.run(
            ["python3", "Tools/Scripts/generate_requirement_index.py", "--check"],
            cwd=ROOT,
            check=True,
        )

    def test_document_python_checks_pass(self) -> None:
        subprocess.run(
            ["python3", "Tools/Scripts/check_front_matter.py"],
            cwd=ROOT,
            check=True,
        )
        subprocess.run(
            ["python3", "Tools/Scripts/check_document_text.py"],
            cwd=ROOT,
            check=True,
        )

    def test_validate_docs_wrapper_contains_no_inline_python(self) -> None:
        text = (ROOT / "Tools/Scripts/validate-docs.sh").read_text(encoding="utf-8")
        self.assertNotIn("python3 - <<", text)
        self.assertIn("check_document_text.py", text)


    def test_validate_docs_wrapper_executes_on_supported_host(self) -> None:
        if platform.system() != "Darwin" or platform.machine() != "arm64":
            self.skipTest("Apple Silicon macOS execution required")
        subprocess.run(
            ["Tools/Scripts/validate-docs.sh"],
            cwd=ROOT,
            check=True,
        )

    def test_all_shell_scripts_parse(self) -> None:
        for path in sorted((ROOT / "Tools/Scripts").glob("*.sh")):
            subprocess.run(["bash", "-n", str(path)], cwd=ROOT, check=True)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CHECKER = ROOT / "Tools/Scripts/check_manifest_paths.py"


class ManifestPathTests(unittest.TestCase):
    def run_checker(self, contents: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "manifest.txt"
            manifest.write_text(contents, encoding="utf-8")
            return subprocess.run(
                ["python3", str(CHECKER), "--manifest", str(manifest)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def test_accepts_distinct_portable_paths(self) -> None:
        result = self.run_checker("Sources/Voxelia.swift\ndocs/a.md\ndocs/b.md\n")

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("passed for 3 entries", result.stdout)

    def test_accepts_folded_leaf_names_under_distinct_parents(self) -> None:
        result = self.run_checker("A/README.md\nB/readme.md\n")

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_repository_manifest_passes(self) -> None:
        result = subprocess.run(
            ["python3", str(CHECKER)],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_rejects_exact_duplicate(self) -> None:
        result = self.run_checker("README.md\nREADME.md\n")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("duplicate path", result.stdout)

    def test_rejects_case_insensitive_collision(self) -> None:
        result = self.run_checker(
            "docs/releases/Logs/01-static.txt\ndocs/releases/logs/runtime.log\n"
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("case-insensitive", result.stdout)
        self.assertIn("docs/releases/Logs", result.stdout)
        self.assertIn("docs/releases/logs", result.stdout)
        self.assertEqual(result.stdout.count("path prefix"), 1)

    def test_rejects_leaf_only_collision(self) -> None:
        result = self.run_checker("docs/A.md\ndocs/a.md\n")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("case-insensitive", result.stdout)

    def test_rejects_unicode_normalization_collision(self) -> None:
        result = self.run_checker("docs/Caf\u00e9/a.md\ndocs/Cafe\u0301/b.md\n")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unicode-normalizing", result.stdout)

    def test_rejects_unsafe_relative_component(self) -> None:
        result = self.run_checker("docs/../README.md\n")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsafe path component", result.stdout)

    def test_rejects_empty_manifest(self) -> None:
        result = self.run_checker("")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("manifest is empty", result.stdout)

    def test_rejects_file_directory_conflict(self) -> None:
        result = self.run_checker("docs/release\ndocs/release/report.md\n")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("both a file and a directory", result.stdout)


if __name__ == "__main__":
    unittest.main()

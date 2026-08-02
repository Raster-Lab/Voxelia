from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CHECKER = ROOT / "Tools/Scripts/check_release_integrity.py"


class ReleaseIntegrityTests(unittest.TestCase):
    def make_repository(self, directory: str) -> Path:
        root = Path(directory)
        (root / "Sources").mkdir()
        (root / "Sources/Voxelia.swift").write_text("public enum Voxelia {}\n")
        (root / "manifest.txt").write_text("")
        (root / "release-checksums.sha256").write_text("")
        (root / "RELEASE_INVENTORY.json").write_text(
            json.dumps(
                {
                    "schemaVersion": "test",
                    "project": "Voxelia",
                    "release": "Test",
                    "platform": "Apple",
                    "files": [],
                }
            )
            + "\n",
            encoding="utf-8",
        )
        return root

    def run_checker(self, root: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(CHECKER), "--root", str(root), *arguments],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

    def test_write_then_check_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_repository(directory)

            update = self.run_checker(root, "--write")
            check = self.run_checker(root)

            self.assertEqual(update.returncode, 0, update.stdout + update.stderr)
            self.assertEqual(check.returncode, 0, check.stdout + check.stderr)

    def test_detects_file_missing_from_ledgers(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_repository(directory)
            self.assertEqual(self.run_checker(root, "--write").returncode, 0)
            (root / "Sources/NewFile.swift").write_text("public enum NewFile {}\n")

            result = self.run_checker(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("manifest is missing paths", result.stdout)
            self.assertIn("Sources/NewFile.swift", result.stdout)

    def test_detects_modified_file_digest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_repository(directory)
            self.assertEqual(self.run_checker(root, "--write").returncode, 0)
            (root / "Sources/Voxelia.swift").write_text("public struct Voxelia {}\n")

            result = self.run_checker(root)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("release inventory metadata mismatch", result.stdout)
            self.assertIn("checksum mismatch", result.stdout)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from Tools.Scripts import check_release_integrity
from Tools.Scripts.check_release_integrity import sha256_git_index


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

    def test_hashes_dataless_content_from_the_git_index(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_repository(directory)
            subprocess.run(["git", "init", "-q"], cwd=root, check=True)
            subprocess.run(
                ["git", "add", "Sources/Voxelia.swift"],
                cwd=root,
                check=True,
            )
            contents = (root / "Sources/Voxelia.swift").read_bytes()

            digest = sha256_git_index(
                root,
                "Sources/Voxelia.swift",
                len(contents),
            )

            self.assertEqual(digest, hashlib.sha256(contents).hexdigest())

    def test_refuses_modified_content_with_the_same_size(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_repository(directory)
            subprocess.run(["git", "init", "-q"], cwd=root, check=True)
            source = root / "Sources/Voxelia.swift"
            subprocess.run(
                ["git", "add", "Sources/Voxelia.swift"],
                cwd=root,
                check=True,
            )
            original_size = source.stat().st_size
            source.write_bytes(b"x" * original_size)

            with self.assertRaisesRegex(
                ValueError,
                "dataless file differs from the Git index",
            ):
                sha256_git_index(
                    root,
                    "Sources/Voxelia.swift",
                    original_size,
                )

    def test_check_reports_evidence_computation_failure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_repository(directory)
            self.assertEqual(self.run_checker(root, "--write").returncode, 0)

            with patch.object(
                check_release_integrity,
                "expected_inventory",
                side_effect=ValueError("simulated dataless mismatch"),
            ):
                errors = check_release_integrity.check_integrity(root)

            self.assertIn(
                "cannot compute release inventory: simulated dataless mismatch",
                errors,
            )

    def test_write_failure_preserves_existing_ledgers(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_repository(directory)
            ledger_paths = [root / name for name in check_release_integrity.LEDGERS]
            before = {path.name: path.read_bytes() for path in ledger_paths}

            with patch.object(
                check_release_integrity,
                "expected_checksums",
                side_effect=ValueError("simulated hashing failure"),
            ):
                with self.assertRaisesRegex(ValueError, "simulated hashing failure"):
                    check_release_integrity.write_integrity(root)

            after = {path.name: path.read_bytes() for path in ledger_paths}
            self.assertEqual(after, before)


if __name__ == "__main__":
    unittest.main()

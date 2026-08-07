from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from Tools.Scripts.check_docc_archives import EXPECTED_ARCHIVES, archive_errors


class DocCArchiveTests(unittest.TestCase):
    def create_expected_archives(self, root: Path) -> None:
        for name in EXPECTED_ARCHIVES:
            (root / name).mkdir(parents=True)

    def test_exact_expected_archive_set_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            products = Path(temporary_directory)
            self.create_expected_archives(products)

            self.assertEqual(archive_errors(products), [])

    def test_missing_and_unexpected_archives_fail(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            products = Path(temporary_directory)
            self.create_expected_archives(products)
            missing = sorted(EXPECTED_ARCHIVES)[0]
            (products / missing).rmdir()
            # `ADR-0233` narrowed this gate to `Voxelia`-prefixed archives,
            # because docbuild documents the whole package graph and a
            # dependency's archives legitimately appear beside Voxelia's. A
            # non-prefixed name is therefore ignored by design, so the fixture
            # uses a prefixed one -- which is also the case that matters: a new
            # Voxelia module nobody added to `EXPECTED_ARCHIVES`.
            (products / "VoxeliaUnregistered.doccarchive").mkdir()

            errors = archive_errors(products)

            self.assertIn(f"missing archives: {missing}", errors)
            self.assertIn(
                "unexpected Voxelia archives: VoxeliaUnregistered.doccarchive. "
                "Add the module to EXPECTED_ARCHIVES with a record, or explain "
                "its absence.",
                errors,
            )

    def test_duplicate_archive_names_fail(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            products = Path(temporary_directory)
            self.create_expected_archives(products)
            duplicate = sorted(EXPECTED_ARCHIVES)[0]
            (products / "nested" / duplicate).mkdir(parents=True)

            self.assertIn(
                f"duplicate archives: {duplicate}",
                archive_errors(products),
            )


if __name__ == "__main__":
    unittest.main()

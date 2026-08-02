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
            (products / "Unexpected.doccarchive").mkdir()

            errors = archive_errors(products)

            self.assertIn(f"missing archives: {missing}", errors)
            self.assertIn(
                "unexpected archives: Unexpected.doccarchive",
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

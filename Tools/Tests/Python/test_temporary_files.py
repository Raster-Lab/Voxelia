"""Self-tests for `check_temporary_files.py`, per `ADR-0302` (`VOX-SEC-005`).

The check's whole value is that it fails on an undeclared temporary-file site, so these
tests exercise the failure first. A gate nobody has seen fail is a gate nobody has tested.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "Tools/Scripts/check_temporary_files.py"

DECLARATION_HEADER = "# Declared temporary-file sites, per `ADR-0302`.\n"


class TemporaryFileCheckTests(unittest.TestCase):
    def run_check(self, source: str, declarations: str) -> subprocess.CompletedProcess[str]:
        # A test may use a scratch directory; `ADR-0302` puts tests outside the rule
        # precisely because they create no product artefact.
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            (root / "Sources").mkdir()
            (root / "Sources/Probe.swift").write_text(source)
            (root / "sites.txt").write_text(declarations)
            return subprocess.run(
                [sys.executable, str(SCRIPT)],
                capture_output=True,
                text=True,
                env={
                    "PATH": "/usr/bin:/bin",
                    "VOXELIA_ROOT": str(root),
                    "VOXELIA_TEMPORARY_FILE_SITES": "sites.txt",
                },
                check=False,
            )

    def test_undeclared_site_fails(self) -> None:
        result = self.run_check(
            "let url = FileManager.default.temporaryDirectory\n", DECLARATION_HEADER
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("Sources/Probe.swift:1", result.stdout)
        self.assertIn("VOX-SEC-005", result.stdout)

    def test_declared_site_passes(self) -> None:
        result = self.run_check(
            "let url = FileManager.default.temporaryDirectory\n",
            DECLARATION_HEADER + "Sources/Probe.swift:1  ADR-0302  a declared probe\n",
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("1 declared site(s)", result.stdout)

    def test_declaration_must_match_the_line(self) -> None:
        # A declaration for a different line does not excuse this one, so moving a site
        # without updating its entry is caught rather than silently inherited.
        result = self.run_check(
            "\nlet url = FileManager.default.temporaryDirectory\n",
            DECLARATION_HEADER + "Sources/Probe.swift:1  ADR-0302  a stale entry\n",
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("Sources/Probe.swift:2", result.stdout)

    def test_every_pattern_is_detected(self) -> None:
        # Each spelling the check claims to cover is exercised, so a pattern cannot be
        # listed in the source and be dead.
        for spelling in [
            "FileManager.default.temporaryDirectory",
            "NSTemporaryDirectory()",
            "url(for: .itemReplacementDirectory)",
            "mkstemp(&template)",
            "mkdtemp(&template)",
            "tmpfile()",
            "tmpnam(nil)",
            'let path = "/tmp/probe"',
            'let path = "/var/tmp/probe"',
        ]:
            with self.subTest(spelling=spelling):
                result = self.run_check(f"let x = {spelling}\n", DECLARATION_HEADER)
                self.assertEqual(result.returncode, 1, spelling)

    def test_clean_source_passes(self) -> None:
        result = self.run_check(
            "let url = URL(fileURLWithPath: suppliedPath)\n", DECLARATION_HEADER
        )
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_repository_itself_is_clean(self) -> None:
        # The live invocation, with no overrides: the product surface must declare nothing
        # because it creates nothing.
        result = subprocess.run(
            [sys.executable, str(SCRIPT)], capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("0 declared site(s)", result.stdout)


if __name__ == "__main__":
    unittest.main()

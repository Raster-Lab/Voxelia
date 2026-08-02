from __future__ import annotations

import platform
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


class RepositoryScriptTests(unittest.TestCase):
    def test_manifest_paths_pass(self) -> None:
        subprocess.run(
            ["python3", "Tools/Scripts/check_manifest_paths.py"],
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

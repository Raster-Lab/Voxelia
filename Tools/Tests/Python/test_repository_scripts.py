from __future__ import annotations

import platform
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
COMMAND_TIMEOUT_SECONDS = 60
SYNTAX_TIMEOUT_SECONDS = 15


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
            timeout=COMMAND_TIMEOUT_SECONDS,
        )

    def test_requirement_index_passes(self) -> None:
        subprocess.run(
            ["python3", "Tools/Scripts/generate_requirement_index.py", "--check"],
            cwd=ROOT,
            check=True,
            timeout=COMMAND_TIMEOUT_SECONDS,
        )

    def test_document_python_checks_pass(self) -> None:
        subprocess.run(
            ["python3", "Tools/Scripts/check_front_matter.py"],
            cwd=ROOT,
            check=True,
            timeout=COMMAND_TIMEOUT_SECONDS,
        )
        subprocess.run(
            ["python3", "Tools/Scripts/check_document_text.py"],
            cwd=ROOT,
            check=True,
            timeout=COMMAND_TIMEOUT_SECONDS,
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
            timeout=COMMAND_TIMEOUT_SECONDS,
        )

    def test_documentation_workflow_runs_the_docc_archive_gate(self) -> None:
        workflow = (
            ROOT / ".github/workflows/documentation.yml"
        ).read_text(encoding="utf-8")
        wrapper = (ROOT / "Tools/Scripts/build-docc.sh").read_text(
            encoding="utf-8"
        )

        for dependency in (
            "assert-apple-platform.sh",
            "build-docc.sh",
            "check_docc_archives.py",
            "check_document_text.py",
            "check_front_matter.py",
            "generate_requirement_index.py",
            "validate-docs.sh",
        ):
            self.assertIn(f"Tools/Scripts/{dependency}", workflow)
        self.assertNotIn("swift package generate-documentation", workflow)
        self.assertIn("xcodebuild -quiet docbuild", wrapper)
        self.assertIn("OTHER_DOCC_FLAGS='--warnings-as-errors'", wrapper)
        self.assertIn("check_docc_archives.py", wrapper)

    def test_sbom_workflow_validates_the_release_profile(self) -> None:
        workflow = (ROOT / ".github/workflows/sbom.yml").read_text(
            encoding="utf-8"
        )
        wrapper = (ROOT / "Tools/Scripts/generate-sbom.sh").read_text(
            encoding="utf-8"
        )

        self.assertIn("Tools/Scripts/generate_sbom.py", wrapper)
        self.assertNotIn("python3 - ", wrapper)
        self.assertIn("generate_sbom.py --validate", workflow)
        self.assertNotIn("test -s", workflow)

    def test_release_preparation_finalizes_generated_evidence_before_validation(self) -> None:
        script = (ROOT / "Tools/Scripts/prepare-release.sh").read_text(
            encoding="utf-8"
        )

        generate = script.index("Tools/Scripts/generate-sbom.sh")
        write_ledgers = script.index("check_release_integrity.py --write")
        validate = script.index("Tools/Scripts/validate-scaffold.sh")
        final_check = script.rindex("check_release_integrity.py")

        self.assertLess(generate, write_ledgers)
        self.assertLess(write_ledgers, validate)
        self.assertGreater(final_check, validate)

    def test_all_shell_scripts_parse(self) -> None:
        for path in sorted((ROOT / "Tools/Scripts").glob("*.sh")):
            subprocess.run(
                ["bash", "-n", str(path)],
                cwd=ROOT,
                check=True,
                timeout=SYNTAX_TIMEOUT_SECONDS,
            )


if __name__ == "__main__":
    unittest.main()

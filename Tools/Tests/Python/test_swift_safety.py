from __future__ import annotations

import importlib.util
import platform
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "Tools/Scripts/check_swift_safety.py"
SPEC = importlib.util.spec_from_file_location("check_swift_safety", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)


class SwiftSafetyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write(self, relative: str, source: str) -> Path:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8")
        return path

    def findings(self, source: str) -> list[object]:
        self.write("Sources/Example/Example.swift", source)
        return CHECKER.scan_repository(self.root)

    def write_minimal_package(
        self,
        *,
        language_mode: str = ".v6",
        target_path: str | None = None,
    ) -> None:
        path_argument = (
            f', path: "{target_path}"' if target_path is not None else ""
        )
        self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let package = Package(\n"
            '    name: "Probe",\n'
            f'    targets: [.target(name: "Probe"{path_argument})],\n'
            f"    swiftLanguageModes: [{language_mode}]\n"
            ")\n",
        )

    def test_repository_currently_passes(self) -> None:
        result = subprocess.run(
            ["python3", str(SCRIPT)],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
            timeout=30,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("inventory scan passed", result.stdout)
        self.assertIn("Use --compile", result.stdout)

    def test_accepts_exact_reviewed_metal_transfer_boundary(self) -> None:
        relative = "Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift"
        reviewed = (ROOT / relative).read_text(encoding="utf-8")
        self.write(
            "docs/security/SWIFT_SAFETY_POLICY.md",
            "# Swift safety policy\n",
        )
        path = self.write(relative, reviewed)

        self.assertEqual(CHECKER.scan_file(path, self.root), [])

    def test_rejects_reviewed_boundary_without_governing_policy(self) -> None:
        relative = "Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift"
        reviewed = (ROOT / relative).read_text(encoding="utf-8")
        path = self.write(relative, reviewed)

        findings = CHECKER.scan_file(path, self.root)

        categories = [finding.category for finding in findings]
        self.assertEqual(categories.count("reserved Swift unsafe marker"), 3)
        self.assertIn("approved source exception policy missing", categories)

    def test_rejects_one_byte_change_to_reviewed_boundary(self) -> None:
        relative = "Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift"
        reviewed = (ROOT / relative).read_text(encoding="utf-8")
        self.write(
            "docs/security/SWIFT_SAFETY_POLICY.md",
            "# Swift safety policy\n",
        )
        path = self.write(relative, reviewed + "\n")

        findings = CHECKER.scan_file(path, self.root)

        self.assertIn(
            "approved source exception fingerprint mismatch",
            {finding.category for finding in findings},
        )

    def test_rejects_extra_or_removed_reviewed_boundary_marker(self) -> None:
        relative = "Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift"
        reviewed = (ROOT / relative).read_text(encoding="utf-8")
        self.write(
            "docs/security/SWIFT_SAFETY_POLICY.md",
            "# Swift safety policy\n",
        )
        extra = self.write(relative, reviewed + "let extra = unsafe 1\n")
        extra_findings = CHECKER.scan_file(extra, self.root)
        self.assertIn(
            "approved source exception fingerprint mismatch",
            {finding.category for finding in extra_findings},
        )

        removed_source = reviewed.replace(
            "        unsafe buffer.contents()",
            "        buffer.contents()",
            1,
        )
        removed = self.write(relative, removed_source)
        removed_findings = CHECKER.scan_file(removed, self.root)
        self.assertIn(
            "approved source exception fingerprint mismatch",
            {finding.category for finding in removed_findings},
        )

    def test_rejects_reviewed_markers_at_a_different_path(self) -> None:
        reviewed = (
            ROOT / "Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift"
        ).read_text(encoding="utf-8")
        path = self.write(
            "Sources/VoxeliaMetal/Internal/DifferentBoundary.swift",
            reviewed,
        )

        findings = CHECKER.scan_file(path, self.root)

        self.assertEqual(
            [finding.category for finding in findings],
            ["reserved Swift unsafe marker"] * 3,
        )

    def test_rejects_different_category_in_reviewed_boundary(self) -> None:
        relative = "Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift"
        reviewed = (ROOT / relative).read_text(encoding="utf-8")
        self.write(
            "docs/security/SWIFT_SAFETY_POLICY.md",
            "# Swift safety policy\n",
        )
        path = self.write(relative, reviewed + "// @unchecked\n")

        findings = CHECKER.scan_file(path, self.root)

        categories = {finding.category for finding in findings}
        self.assertIn("unchecked Sendable conformance", categories)
        self.assertIn("approved source exception fingerprint mismatch", categories)

    def test_rejects_missing_reviewed_boundary_when_policy_is_present(self) -> None:
        self.write(
            "docs/security/SWIFT_SAFETY_POLICY.md",
            "# Swift safety policy\n",
        )

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(len(findings), 2)
        for finding in findings:
            self.assertEqual(
                finding.category, "approved source exception missing"
            )

    def test_governing_repository_requires_policy_and_boundary(self) -> None:
        with mock.patch.object(CHECKER, "ROOT", self.root):
            findings = CHECKER.scan_repository(self.root)

        self.assertEqual(
            {finding.category for finding in findings},
            {
                "approved source exception missing",
                "approved source exception policy missing",
            },
        )

    def test_accepts_checked_sendable_value_and_safe_vocabulary(self) -> None:
        findings = self.findings(
            "/// Allocation-free checked representation.\n"
            "struct Value: Sendable { let count: Int }\n"
            "enum Tier { case free }\n"
            "let isUnchecked = false\n"
            "let lowerBound = -Double.greatestFiniteMagnitude\n"
            'let explanation = "UnsafePointer and withUnsafeBytes are names"\n'
        )

        self.assertEqual(findings, [])

    def test_rejects_compiler_execution_from_swift_tooling(self) -> None:
        findings = self.findings(
            'let compiler = ["swiftc", "-Ounchecked"]\n'
            'let driver = ["swift", "build", "-Xfrontend"]\n'
            'let interpreter = ["/usr/bin/swift", "probe"]\n'
        )

        self.assertEqual(
            {finding.category for finding in findings},
            {
                "compiler escape channel in active configuration",
                "direct Swift script or compiler execution",
                "weakened compiler safety",
            },
        )

    def test_rejects_unchecked_sendable_across_whitespace(self) -> None:
        findings = self.findings("final class Box: @unchecked\n Sendable {}\n")

        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].category, "unchecked Sendable conformance")
        self.assertEqual(findings[0].line, 1)

    def test_rejects_module_qualified_unchecked_sendable(self) -> None:
        findings = self.findings(
            "final class Box: @unchecked Swift.Sendable {}\n"
        )

        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].token, "@unchecked")

    def test_rejects_backticked_escape_attributes(self) -> None:
        findings = self.findings(
            "@`preconcurrency` import Foundation\n"
            "final class Box: @`unchecked` Sendable {}\n"
            "@`_unsafeInheritExecutor` func run() async {}\n"
        )

        self.assertEqual(len(findings), 3)
        self.assertEqual(
            {finding.category for finding in findings},
            {
                "unchecked Sendable conformance",
                "concurrency-checking escape hatch",
            },
        )

    def test_rejects_concurrency_escape_hatches(self) -> None:
        findings = self.findings(
            "@preconcurrency import Legacy\n"
            "nonisolated(unsafe) var shared = 0\n"
            "@_unsafeInheritExecutor func run() {}\n"
        )

        self.assertEqual(len(findings), 3)
        self.assertEqual(
            {finding.category for finding in findings},
            {"concurrency-checking escape hatch"},
        )

    def test_rejects_compiler_valid_explicit_unsafe_markers(self) -> None:
        findings = self.findings(
            "@unsafe func make() {}\n"
            "func use() {\n"
            "    let memory = unsafe malloc(8)\n"
            "    let environment = unsafe environ\n"
            "    let commented = unsafe /* nested /* gap */ gap */ environ\n"
            "}\n"
        )

        self.assertEqual(len(findings), 4)
        self.assertEqual(
            {finding.category for finding in findings},
            {
                "explicit unsafe declaration marker",
                "reserved Swift unsafe marker",
            },
        )

    def test_rejects_manifest_unsafe_flags(self) -> None:
        self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let settings = [SwiftSetting.`unsafeFlags`([\n"
            '    "-Xfrontend", "-disable-dynamic-actor-isolation",\n'
            "]) ]\n"
            "let package = Package(\n"
            '    name: "Probe",\n'
            "    targets: [],\n"
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )

        findings = CHECKER.scan_repository(self.root)

        categories = {finding.category for finding in findings}
        self.assertIn("unsafe package compiler flags", categories)

    def test_manifest_policy_rejects_access_modified_import(self) -> None:
        self.write_minimal_package()
        manifest = self.root / "Package.swift"
        source = manifest.read_text(encoding="utf-8").replace(
            "import PackageDescription",
            "internal import Foundation\nimport PackageDescription",
        )
        manifest.write_text(source, encoding="utf-8")

        findings = CHECKER.scan_repository(self.root)

        self.assertIn(
            "manifest import outside PackageDescription",
            {finding.category for finding in findings},
        )

    def test_manifest_rejects_foreign_pointer_execution(self) -> None:
        self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            '@`_silgen_name`("getenv")\n'
            "func environment(\n"
            "    _ name: UnsafePointer<CChar>\n"
            ") -> UnsafeMutablePointer<CChar>?\n"
            'let value = "PATH".withCString { environment($0) }\n'
            "let package = Package(\n"
            '    name: "Probe", targets: [],\n'
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )

        findings = CHECKER.scan_repository(self.root)

        categories = {finding.category for finding in findings}
        self.assertIn("manifest foreign-symbol escape hatch", categories)
        self.assertIn("manifest unsafe pointer or ownership type", categories)
        self.assertIn(
            "manifest unsafe memory or lifetime operation",
            categories,
        )

    def test_manifest_rejects_environment_dependent_target_scope(self) -> None:
        self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            'let targetPath = Context.environment["CI"] == nil\n'
            '    ? "Sources/Probe"\n'
            '    : "docs/progress/evidence/Probe"\n'
            "let package = Package(\n"
            '    name: "Probe",\n'
            '    targets: [.target(name: "Probe", path: targetPath)],\n'
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )

        findings = CHECKER.scan_repository(self.root)

        self.assertIn(
            "manifest nondeterministic input",
            {finding.category for finding in findings},
        )

    def test_manifest_rejects_clock_selected_language_override(self) -> None:
        manifest = self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let legacy = ContinuousClock.now.duration(to: .now)\n"
            "    .components.attoseconds > 0\n"
            "let package = Package(\n"
            '    name: "Probe",\n'
            "    targets: [\n"
            "        .target(\n"
            '            name: "Probe",\n'
            "            swiftSettings: legacy\n"
            "                ? [.swiftLanguageMode(.v5)]\n"
            "                : []\n"
            "        )\n"
            "    ],\n"
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )

        findings = CHECKER.scan_file(manifest, self.root)

        categories = {finding.category for finding in findings}
        self.assertIn("manifest outside approved declarative subset", categories)
        self.assertIn("manifest target language override API", categories)

    def test_rejects_safety_oracle_conditionals(self) -> None:
        findings = self.findings(
            "#if hasFeature(StrictMemorySafety /* lexical gap */)\n"
            "let checked = true\n"
            "#else\n"
            "let checked = false\n"
            "#endif\n"
        )

        self.assertEqual(len(findings), 1)
        self.assertEqual(
            {finding.category for finding in findings},
            {"strict-memory-safety oracle conditional"},
        )

    def test_comments_are_in_scope_under_zero_exception_policy(self) -> None:
        findings = self.findings(
            "// @unchecked Sendable\n"
            "/* @preconcurrency\n"
            "   /* nonisolated(unsafe) */\n"
            "*/\n"
            "struct Safe: Sendable {}\n"
        )

        self.assertGreaterEqual(len(findings), 3)
        self.assertIn("@unchecked", {finding.token for finding in findings})
        self.assertIn("@preconcurrency", {finding.token for finding in findings})

    def test_strings_are_in_scope_under_zero_exception_policy(self) -> None:
        findings = self.findings(
            'let one = "@preconcurrency"\n'
            'let two = """\n@unchecked Sendable\n"""\n'
            'let three = #"nonisolated(unsafe)"#\n'
            'let four = ##"""@unsafe"""##\n'
        )

        tokens = {finding.token for finding in findings}
        self.assertIn("@preconcurrency", tokens)
        self.assertIn("@unchecked", tokens)
        self.assertIn("nonisolated(unsafe)", tokens)
        self.assertIn("@unsafe", tokens)

    def test_regex_literals_are_in_scope_and_cannot_hide_source(self) -> None:
        findings = self.findings(
            "let inert = ##/@unchecked @preconcurrency/##\n"
            "let escaped = #/x\\/#//y/#\n"
            "let pointer = unsafe malloc(1)\n"
        )

        tokens = [finding.token for finding in findings]
        for token in ("@unchecked", "@preconcurrency", "unsafe"):
            self.assertIn(token, tokens)

    def test_bare_regex_cannot_corrupt_interpolation_lexing(self) -> None:
        findings = self.findings(
            "import Darwin\n"
            'let text = "\\( { _ = /\\)/; return unsafe malloc(1) }() )"\n'
            "let inert = /@unchecked/\n"
            "let ratio = numerator / denominator\n"
        )

        tokens = [finding.token for finding in findings]
        self.assertIn("unsafe", tokens)
        self.assertIn("@unchecked", tokens)

    def test_force_unwrap_division_cannot_hide_unchecked_conformance(self) -> None:
        findings = self.findings(
            "func ratio(_ x: Int?, _ y: Int) -> Int { x!/y }\n"
            "final class Box: @unchecked Swift.Sendable {}\n"
        )

        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].token, "@unchecked")

    def test_scans_executable_string_interpolation(self) -> None:
        findings = self.findings(
            'let text = "value: \\({ final class Box: @unchecked Sendable {}; '
            'return 1 }())"\n'
            'let raw = #"value: \\#({ nonisolated(unsafe) var value = 1; '
            'return value }())"#\n'
        )

        self.assertEqual(len(findings), 2)
        self.assertEqual(
            {finding.token for finding in findings},
            {"@unchecked", "nonisolated(unsafe)"},
        )

    def test_scans_auxiliary_package_sources_and_tests(self) -> None:
        self.write(
            "Validation/Sources/tool/Tool.swift",
            "final class Box: @unchecked Sendable {}\n",
        )
        self.write(
            "Benchmarks/Tests/ToolTests/ToolTests.swift",
            "nonisolated(unsafe) var value = 0\n",
        )

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(
            [finding.path.as_posix() for finding in findings],
            [
                "Benchmarks/Tests/ToolTests/ToolTests.swift",
                "Validation/Sources/tool/Tool.swift",
            ],
        )

    def test_scans_shell_and_workflow_compiler_flags(self) -> None:
        self.write(
            "Tools/Scripts/build.sh",
            "swift build -Xswiftc -Ounchecked\n"
            "swift build -Xswiftc -strict-concurrency -Xswiftc minimal\n"
            "swift build -Xswiftc -swift-version -Xswiftc 5\n"
            "swift build -Xswiftc -remove-runtime-asserts\n"
            "swift build -D SPECIAL_PATH\n"
            "swift build -DSPECIAL_PATH\n"
            "swiftc Probe.swift -no-warnings-as-errors "
            "-disable-verify-exclusivity\n"
            "swift Tools/Scripts/probe\n",
        )
        self.write(
            ".github/workflows/ci.yml",
            "run: swift test -Xswiftc -disable-actor-data-race-checks "
            "-Xswiftc -disable-dynamic-actor-isolation "
            "-Xswiftc -assume-single-threaded\n",
        )

        findings = CHECKER.scan_repository(self.root)

        self.assertGreaterEqual(len(findings), 13)
        self.assertEqual(
            {finding.path.as_posix() for finding in findings},
            {".github/workflows/ci.yml", "Tools/Scripts/build.sh"},
        )
        self.assertIn(
            "compiler escape channel in active configuration",
            {finding.category for finding in findings},
        )

    def test_rejects_xcode_setting_selectors_and_dynamic_values(self) -> None:
        self.write(
            "Config/Unsafe.xcconfig",
            "SWIFT_DISABLE_SAFETY_CHECKS[sdk=iphoneos*] = YES\n"
            "SWIFT_STRICT_CONCURRENCY[config=Release] = minimal\n"
            "SWIFT_ENFORCE_EXCLUSIVE_ACCESS = $(EXCLUSIVITY_MODE)\n"
            "SWIFT_VERSION = 5.0\n"
            "SWIFT_STRICT_MEMORY_SAFETY = MIGRATE\n"
            "SWIFT_SUPPRESS_WARNINGS = YES\n"
            "SWIFT_TREAT_WARNINGS_AS_ERRORS = NO\n"
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS = SPECIAL_PATH\n"
            "SWIFT_EXEC = ./wrapper\n"
            "SWIFT_TOOLCHAIN_FLAGS = -something\n",
        )
        self.write(
            "Config/Safe.xcconfig",
            "SWIFT_DISABLE_SAFETY_CHECKS = NO\n"
            "SWIFT_STRICT_CONCURRENCY = complete\n"
            "SWIFT_ENFORCE_EXCLUSIVE_ACCESS = on\n"
            "SWIFT_STRICT_MEMORY_SAFETY = YES\n"
            "SWIFT_SUPPRESS_WARNINGS = NO\n"
            "SWIFT_TREAT_WARNINGS_AS_ERRORS = YES\n"
            "SWIFT_VERSION = 6.0\n",
        )

        findings = CHECKER.scan_repository(self.root)

        unsafe_settings = [
            finding
            for finding in findings
            if finding.category == "unsafe or dynamic Xcode Swift setting"
        ]
        self.assertEqual(len(unsafe_settings), 7)
        self.assertEqual(
            {finding.path.as_posix() for finding in unsafe_settings},
            {"Config/Unsafe.xcconfig"},
        )
        forbidden_settings = [
            finding
            for finding in findings
            if finding.category == "forbidden Xcode Swift setting"
        ]
        self.assertEqual(len(forbidden_settings), 3)
        self.assertEqual(
            {finding.path.as_posix() for finding in forbidden_settings},
            {"Config/Unsafe.xcconfig"},
        )

    def test_ignores_controlled_evidence_and_generated_build_trees(self) -> None:
        self.write(
            "docs/progress/evidence/Probe.swift",
            "final class Box: @unchecked Sendable {}\n",
        )
        self.write(
            ".build/checkouts/Dependency.swift",
            "@preconcurrency import X\n",
        )
        self.write(
            "DerivedData/Generated.swift",
            "@unsafe func generated() {}\n",
        )

        self.assertEqual(CHECKER.scan_repository(self.root), [])

    def test_does_not_hide_a_compiled_source_directory_named_docs(self) -> None:
        self.write(
            "Sources/Example/docs/Compiled.swift",
            "final class Box: @unchecked Sendable {}\n",
        )

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(len(findings), 1)
        self.assertEqual(
            findings[0].path.as_posix(),
            "Sources/Example/docs/Compiled.swift",
        )

    def test_does_not_hide_generated_directory_names_inside_sources(self) -> None:
        self.write(
            "Sources/Example/Build/Escape.swift",
            "final class Box: @unchecked Sendable {}\n",
        )
        self.write(
            "Sources/Example/DerivedData/Escape.swift",
            "@preconcurrency import Foundation\n",
        )

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(
            [finding.path.as_posix() for finding in findings],
            [
                "Sources/Example/Build/Escape.swift",
                "Sources/Example/DerivedData/Escape.swift",
            ],
        )

    def test_rejects_swift_outside_approved_package_trees(self) -> None:
        self.write("Scripts/Probe.swift", "public struct Probe {}\n")
        self.write(
            "Extra/Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let package = Package(\n"
            '    name: "Extra", targets: [],\n'
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )

        findings = CHECKER.scan_repository(self.root)

        outside = [
            finding
            for finding in findings
            if finding.category == "Swift source outside approved package trees"
        ]
        self.assertEqual(
            [finding.path.as_posix() for finding in outside],
            ["Extra/Package.swift", "Scripts/Probe.swift"],
        )

    def test_rejects_source_directory_symlinks(self) -> None:
        target = self.write(
            "docs/progress/evidence/Linked/Unsafe.swift",
            "@unsafe public func use() {}\n",
        ).parent
        link = self.root / "Sources/Example/Linked"
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to(target, target_is_directory=True)

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(len(findings), 1)
        self.assertEqual(
            findings[0].category,
            "directory symlink outside safety inventory",
        )

    def test_rejects_file_symlink_without_reading_its_target(self) -> None:
        link = self.root / "Sources/Example/Device.swift"
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to("/dev/zero")

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(len(findings), 1)
        self.assertEqual(
            findings[0].category,
            "file symlink outside safety inventory",
        )

    def test_rejects_extensionless_file_symlink(self) -> None:
        link = self.root / "Tools/Scripts/probe"
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to("/dev/zero")

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(len(findings), 1)
        self.assertEqual(
            findings[0].category,
            "file symlink outside safety inventory",
        )

    def test_rejects_swift_shebang_with_non_swift_suffix(self) -> None:
        shebangs = (
            "#!/usr/bin/swift",
            "#!/usr/bin/env -Sswift",
            "#!/usr/bin/env --split-string=swift -O",
        )
        for index, shebang in enumerate(shebangs):
            self.write(
                f"Tools/Scripts/probe-{index}.command",
                f"{shebang}\nprint(1)\n",
            )

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(len(findings), len(shebangs))
        self.assertEqual(
            {finding.category for finding in findings},
            {"non-.swift Swift script outside package coverage"},
        )

    def test_rejects_nested_package_manifest_in_approved_source_tree(self) -> None:
        self.write(
            "Sources/Example/Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let package = Package(\n"
            '    name: "Nested", targets: [],\n'
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )

        findings = CHECKER.scan_repository(self.root)

        outside = [
            finding
            for finding in findings
            if finding.category == "Swift source outside approved package trees"
        ]
        self.assertEqual(len(outside), 1)
        self.assertEqual(
            outside[0].path.as_posix(),
            "Sources/Example/Package.swift",
        )

    @unittest.skipUnless(
        platform.system() == "Darwin" and platform.machine() == "arm64",
        "Apple Silicon SwiftPM required",
    )
    def test_package_description_rejects_excluded_target_sources(self) -> None:
        self.write_minimal_package(target_path="docs/progress/evidence/Probe")
        self.write(
            "docs/progress/evidence/Probe/Probe.swift",
            "@unsafe public func use() {}\n",
        )

        errors = CHECKER.package_description_errors(self.root, Path("."))

        self.assertTrue(
            any("outside the safety inventory" in error for error in errors),
            errors,
        )

    @unittest.skipUnless(
        platform.system() == "Darwin" and platform.machine() == "arm64",
        "Apple Silicon SwiftPM required",
    )
    def test_package_description_rejects_orphaned_excluded_swift(self) -> None:
        self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let package = Package(\n"
            '    name: "Probe",\n'
            "    targets: [\n"
            "        .target(\n"
            '            name: "Probe",\n'
            '            exclude: ["Excluded.swift"]\n'
            "        )\n"
            "    ],\n"
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )
        self.write("Sources/Probe/Probe.swift", "public struct Probe {}\n")
        self.write(
            "Sources/Probe/Excluded.swift",
            "public struct Excluded {}\n",
        )

        errors = CHECKER.package_description_errors(self.root, Path("."))

        self.assertTrue(
            any("not compiled by any target" in error for error in errors),
            errors,
        )

    @unittest.skipUnless(
        platform.system() == "Darwin" and platform.machine() == "arm64",
        "Apple Silicon SwiftPM required",
    )
    def test_package_description_rejects_effective_swift_five(self) -> None:
        self.write_minimal_package(language_mode=".v5")
        self.write("Sources/Probe/Probe.swift", "public struct Probe {}\n")

        errors = CHECKER.package_description_errors(self.root, Path("."))

        self.assertTrue(any("expected ['6']" in error for error in errors), errors)

    @unittest.skipUnless(
        platform.system() == "Darwin" and platform.machine() == "arm64",
        "Apple Silicon SwiftPM required",
    )
    def test_package_description_rejects_computed_unsafe_flags(self) -> None:
        self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let compilerSetting = SwiftSetting.unsafeFlags\n"
            'let weakenedMode = "-disable-dynamic-" + "actor-isolation"\n'
            "let package = Package(\n"
            '    name: "Probe",\n'
            "    targets: [\n"
            "        .target(\n"
            '            name: "Probe",\n'
            "            swiftSettings: [\n"
            '                compilerSetting(["-Xfrontend", weakenedMode], nil)\n'
            "            ]\n"
            "        )\n"
            "    ],\n"
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )
        self.write("Sources/Probe/Probe.swift", "public struct Probe {}\n")

        errors = CHECKER.package_description_errors(self.root, Path("."))

        self.assertTrue(any("uses unsafeFlags" in error for error in errors), errors)

    @unittest.skipUnless(
        platform.system() == "Darwin" and platform.machine() == "arm64",
        "Apple Silicon SwiftPM required",
    )
    def test_package_description_rejects_target_language_override(self) -> None:
        self.write(
            "Package.swift",
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let package = Package(\n"
            '    name: "Probe",\n'
            "    targets: [\n"
            "        .target(\n"
            '            name: "Probe",\n'
            "            swiftSettings: [.swiftLanguageMode(.v5)]\n"
            "        )\n"
            "    ],\n"
            "    swiftLanguageModes: [.v6]\n"
            ")\n",
        )
        self.write("Sources/Probe/Probe.swift", "public struct Probe {}\n")

        errors = CHECKER.package_description_errors(self.root, Path("."))

        self.assertTrue(
            any(
                "overrides the package Swift language mode" in error
                for error in errors
            ),
            errors,
        )

    @unittest.skipUnless(
        platform.system() == "Darwin" and platform.machine() == "arm64",
        "Apple Silicon Swift compiler required",
    )
    def test_compiler_rejects_inferred_unsafe_operations(self) -> None:
        self.write_minimal_package()
        self.write(
            "Sources/Probe/Probe.swift",
            "public struct Probe {}\n"
            "import Darwin\n"
            "#if DEBUG\n"
            "public func use() {}\n"
            "#else\n"
            "public func use() {\n"
            "    let pointer = malloc(8)!\n"
            "    free(pointer)\n"
            "}\n"
            "#endif\n",
        )

        result = CHECKER._run_bounded(
            CHECKER.strict_memory_safety_command(Path("."), "release"),
            cwd=self.root,
            capture_output=True,
            timeout=30,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsafe constructs", result.stdout + result.stderr)

    def test_release_command_covers_products_only(self) -> None:
        # Test targets compile in the debug pass; the release pass covers
        # products only, per the recorded Swift 6.3.3 optimiser crash on
        # release test builds.
        release = CHECKER.strict_memory_safety_command(Path("."), "release")
        self.assertIn("--configuration", release)
        self.assertNotIn("--build-tests", release)
        self.assertNotIn("-enable-testing", release)

        debug = CHECKER.strict_memory_safety_command(Path("."), "debug")
        self.assertIn("--build-tests", debug)

    def test_bounded_subprocess_capture_rejects_excess_output(self) -> None:
        command = [
            sys.executable,
            "-c",
            "import os, sys; os.write(1, b'x' * int(sys.argv[1]))",
            str(CHECKER.MAX_SUBPROCESS_OUTPUT_BYTES + 1),
        ]

        with self.assertRaises(CHECKER.SubprocessOutputLimitExceeded) as context:
            CHECKER._run_bounded(
                command,
                cwd=self.root,
                capture_output=True,
                timeout=10,
            )

        self.assertEqual(
            context.exception.limit,
            CHECKER.MAX_SUBPROCESS_OUTPUT_BYTES,
        )

    def test_bounded_capture_enforces_deadline_after_pipe_eof(self) -> None:
        command = [
            sys.executable,
            "-c",
            "import os, time; os.close(1); os.close(2); time.sleep(2)",
        ]

        with self.assertRaises(subprocess.TimeoutExpired):
            CHECKER._run_bounded(
                command,
                cwd=self.root,
                capture_output=True,
                timeout=0.1,
            )

    def test_diagnostics_are_stable_and_include_location(self) -> None:
        findings = self.findings(
            "struct Safe {}\n"
            "final class Box: @unchecked Sendable {}\n"
            "nonisolated(unsafe) var value = 0\n"
        )

        self.assertEqual(
            [finding.diagnostic() for finding in findings],
            [
                "Sources/Example/Example.swift:2:18: "
                "unchecked Sendable conformance: @unchecked",
                "Sources/Example/Example.swift:3:1: "
                "concurrency-checking escape hatch: nonisolated(unsafe)",
            ],
        )

    def test_large_finding_set_is_bounded_and_reports_omissions(self) -> None:
        source = "".join(
            f"// {index}: @unchecked Sendable\n"
            for index in range(4_000)
        )

        findings = self.findings(source)

        self.assertEqual(len(findings), CHECKER.MAX_FINDINGS_PER_FILE + 1)
        self.assertEqual(
            findings[-1].category,
            "additional prohibited matches omitted",
        )
        self.assertEqual(findings[-1].token, "3900 additional matches")

    def test_oversized_scanned_files_fail_before_reading(self) -> None:
        paths = [
            self.root / "Sources/Example/Large.swift",
            self.root / ".github/workflows/large.yml",
        ]
        for path in paths:
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("wb") as output:
                output.truncate(CHECKER.MAX_SCANNED_FILE_BYTES + 1)

        findings = CHECKER.scan_repository(self.root)

        self.assertEqual(len(findings), 2)
        self.assertEqual(
            {finding.category for finding in findings},
            {"source/configuration exceeds safety scan size limit"},
        )


if __name__ == "__main__":
    unittest.main()

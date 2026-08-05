#!/usr/bin/env python3
"""Reject unreviewed Swift memory-safety and concurrency escape hatches."""
from __future__ import annotations

import argparse
import bisect
import hashlib
import io
import json
import os
import re
import selectors
import signal
import stat
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Pattern


ROOT = Path(__file__).resolve().parents[2]
IGNORED_RELATIVE_TREES = {
    Path(".build"),
    Path(".git"),
    Path(".swiftpm"),
    Path("Benchmarks/.build"),
    Path("Benchmarks/.swiftpm"),
    Path("Build"),
    Path("DerivedData"),
    Path("Tools/.build"),
    Path("Tools/.swiftpm"),
    Path("Validation/.build"),
    Path("Validation/.swiftpm"),
    Path("docs/progress/evidence"),
}
CONFIGURATION_SUFFIXES = {".pbxproj", ".sh", ".xcconfig", ".yaml", ".yml"}
CONFIGURATION_FILENAMES = {"Makefile"}
PACKAGE_PATHS = (Path("."), Path("Validation"), Path("Benchmarks"), Path("Tools"))
KNOWN_MANIFESTS = {
    Path("Package.swift"),
    Path("Benchmarks/Package.swift"),
    Path("Tools/Package.swift"),
    Path("Validation/Package.swift"),
}
KNOWN_SWIFT_TREES = {
    Path("Sources"),
    Path("Tests"),
    Path("Benchmarks/Sources"),
    Path("Benchmarks/Tests"),
    Path("Tools/Sources"),
    Path("Tools/Tests"),
    Path("Validation/Sources"),
    Path("Validation/Tests"),
}
XCODE_SAFE_SETTINGS = {
    "SWIFT_DISABLE_SAFETY_CHECKS": {"no"},
    "SWIFT_ENFORCE_EXCLUSIVE_ACCESS": {"default", "on"},
    "SWIFT_STRICT_MEMORY_SAFETY": {"yes"},
    "SWIFT_STRICT_CONCURRENCY": {"complete"},
    "SWIFT_SUPPRESS_WARNINGS": {"no"},
    "SWIFT_TREAT_WARNINGS_AS_ERRORS": {"yes"},
    "SWIFT_VERSION": {"6", "6.0"},
}
XCODE_FORBIDDEN_SETTINGS = {
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
    "SWIFT_EXEC",
    "SWIFT_TOOLCHAIN_FLAGS",
}
PACKAGE_SOURCE_TREES = {
    Path("."): (Path("Sources"), Path("Tests")),
    Path("Benchmarks"): (
        Path("Benchmarks/Sources"),
        Path("Benchmarks/Tests"),
    ),
    Path("Tools"): (Path("Tools/Sources"), Path("Tools/Tests")),
    Path("Validation"): (
        Path("Validation/Sources"),
        Path("Validation/Tests"),
    ),
}
EXPECTED_LOCAL_DEPENDENCIES = {
    Path("."): set(),
    Path("Benchmarks"): {Path(".")},
    Path("Tools"): set(),
    Path("Validation"): {Path(".")},
}
MAX_FINDINGS_PER_FILE = 100
MAX_REPOSITORY_FINDINGS = 500
MAX_SCANNED_FILE_BYTES = 1024 * 1024
MAX_SUBPROCESS_OUTPUT_BYTES = 4 * 1024 * 1024
MAX_DIAGNOSTIC_TOKEN_CHARACTERS = 240
PACKAGE_COMMAND_TIMEOUT_SECONDS = 60
PACKAGE_BUILD_TIMEOUT_SECONDS = 300
MANIFEST_HEADER = "// swift-tools-version: 6.2"
MANIFEST_DECLARATIVE_IDENTIFIERS = {
    "Package",
    "PackageDescription",
    "dependencies",
    "executable",
    "executableTarget",
    "iOS",
    "import",
    "let",
    "library",
    "macOS",
    "name",
    "package",
    "path",
    "platforms",
    "process",
    "product",
    "products",
    "resources",
    "swiftLanguageModes",
    "target",
    "targets",
    "testTarget",
    "tvOS",
    "v15",
    "v18",
    "v2",
    "v6",
    "visionOS",
}
MANIFEST_TOKEN = re.compile(
    r'\s+|"[^"\\\r\n]*"|[A-Za-z_][A-Za-z0-9_]*|[\[\]().,:=]'
)


@dataclass(frozen=True)
class SafetyPattern:
    """A prohibited source pattern and its diagnostic category."""

    category: str
    expression: Pattern[str]
    include_string_payloads: bool = False
    scan_swift_source: bool = True


@dataclass(frozen=True, order=True)
class SafetyFinding:
    """One prohibited token located in a repository-relative Swift file."""

    path: Path
    line: int
    column: int
    category: str
    token: str

    def diagnostic(self) -> str:
        return (
            f"{self.path}:{self.line}:{self.column}: {self.category}: "
            f"{self.token}"
        )


@dataclass(frozen=True)
class ApprovedSourceException:
    """One exact reviewed source fingerprint and permitted finding multiset."""

    sha256: str
    expected_findings: tuple[tuple[str, str], ...]


APPROVED_SOURCE_EXCEPTIONS = {
    Path(
        "Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift"
    ): ApprovedSourceException(
        sha256="161b5298d68bfc1e6e312f650458db3e41e6b9ca418f6a49c486ff86e53c7aa9",
        expected_findings=(
            ("reserved Swift unsafe marker", "unsafe"),
            ("reserved Swift unsafe marker", "unsafe"),
            ("reserved Swift unsafe marker", "unsafe"),
        ),
    )
}
APPROVED_EXCEPTION_POLICY_PATH = Path("docs/security/SWIFT_SAFETY_POLICY.md")


class SubprocessOutputLimitExceeded(RuntimeError):
    """A bounded subprocess exceeded its combined captured-output budget."""

    def __init__(self, command: list[str], limit: int) -> None:
        super().__init__(
            f"{' '.join(command)} exceeded {limit} captured output bytes"
        )
        self.command = command
        self.limit = limit


PATTERNS = (
    SafetyPattern(
        "unchecked Sendable conformance",
        re.compile(r"@\s*`?unchecked`?(?![A-Za-z0-9_])"),
    ),
    SafetyPattern(
        "concurrency-checking escape hatch",
        re.compile(
            r"@\s*`?preconcurrency`?(?![A-Za-z0-9_])|"
            r"@\s*`?_unsafeInheritExecutor`?(?![A-Za-z0-9_])|"
            r"\bnonisolated\s*\(\s*unsafe\s*\)"
        ),
    ),
    SafetyPattern(
        "strict-memory-safety oracle conditional",
        re.compile(r"\bStrictMemorySafety\b"),
    ),
    SafetyPattern(
        "explicit unsafe declaration marker",
        re.compile(r"@\s*unsafe\b"),
    ),
    SafetyPattern(
        "reserved Swift unsafe marker",
        re.compile(r"\bunsafe\b"),
    ),
    SafetyPattern(
        "unsafe package compiler flags",
        re.compile(r"\.\s*(?:unsafeFlags\b|`unsafeFlags`)"),
    ),
    SafetyPattern(
        "compiler escape channel in active configuration",
        re.compile(r"-Xswiftc\b|-Xfrontend\b|\bOTHER_SWIFT_FLAGS\b"),
        include_string_payloads=True,
    ),
    SafetyPattern(
        "external compilation condition in active configuration",
        re.compile(
            r"(?<![A-Za-z0-9_])-D(?:[A-Za-z_][A-Za-z0-9_]*|"
            r"(?=$|[\s\"'=,]))"
        ),
        include_string_payloads=True,
        scan_swift_source=False,
    ),
    SafetyPattern(
        "direct Swift script or compiler execution",
        re.compile(
            r"\bswiftc\b|\bswift\s+(?!"
            r"--version\b|-version\b|build\b|experimental-sdk\b|format\b|"
            r"help\b|package\b|run\b|sdk\b|test\b)"
        ),
        include_string_payloads=True,
    ),
    SafetyPattern(
        "direct Swift script or compiler execution",
        re.compile(
            r"[\"'](?:/(?:usr/)?(?:local/)?bin/)?swiftc?[\"']"
        ),
    ),
    SafetyPattern(
        "weakened compiler safety",
        re.compile(
            r"-assume-single-threaded\b|"
            r"-disable-actor-data-race-checks\b|"
            r"-disable-dynamic-actor-isolation\b|"
            r"-Ounchecked\b|"
            r"-remove-runtime-asserts\b|"
            r"-swift-version(?:=|(?:[\s\"',]+-(?:Xfrontend|Xswiftc))?"
            r"[\s\"',]+)(?:[0-5](?:\.\d+)?)\b|"
            r"-enforce-exclusivity(?:=|(?:[\s\"',]+-(?:Xfrontend|Xswiftc))?"
            r"[\s\"',]+)(?:none|unchecked)\b|"
            r"-disable-exclusivity-checking\b|"
            r"-disable-verify-exclusivity\b|"
            r"-no-warnings-as-errors\b|"
            r"-suppress-warnings\b|"
            r"-strict-memory-safety:migrate\b|"
            r"-strict-concurrency(?:=|(?:[\s\"',]+-(?:Xfrontend|Xswiftc))?"
            r"[\s\"',]+)(?:minimal|targeted)\b"
        ),
        include_string_payloads=True,
    ),
)
MANIFEST_PATTERNS = (
    SafetyPattern(
        "manifest nondeterministic input",
        re.compile(
            r"\b(?:CommandLine|Context|ProcessInfo|"
            r"SystemRandomNumberGenerator)\b|\bhashValue\b|\.\s*random\b"
        ),
    ),
    SafetyPattern(
        "manifest foreign-symbol escape hatch",
        re.compile(
            r"@\s*`?_[A-Za-z0-9_]*(?:cdecl|extern|expose|silgen)"
            r"[A-Za-z0-9_]*`?(?![A-Za-z0-9_])"
        ),
    ),
    SafetyPattern(
        "manifest unsafe pointer or ownership type",
        re.compile(
            r"\b(?:"
            r"AutoreleasingUnsafeMutablePointer|OpaquePointer|Unmanaged|"
            r"UnsafeBufferPointer|UnsafeMutableBufferPointer|"
            r"UnsafeMutablePointer|UnsafeMutableRawBufferPointer|"
            r"UnsafeMutableRawPointer|UnsafePointer|UnsafeRawBufferPointer|"
            r"UnsafeRawPointer"
            r")\b"
        ),
    ),
    SafetyPattern(
        "manifest unsafe memory or lifetime operation",
        re.compile(
            r"\b(?:"
            r"_fixLifetime|unsafeBitCast|withoutActuallyEscaping|"
            r"withCString|withUTF8|withUnsafe[A-Za-z0-9_]*"
            r")\b"
        ),
    ),
    SafetyPattern(
        "manifest target language override API",
        re.compile(r"\.\s*`?swiftLanguageMode`?(?![A-Za-z0-9_])"),
    ),
)


def _is_ignored(relative: Path) -> bool:
    return relative in IGNORED_RELATIVE_TREES


def _is_regular_file(path: Path) -> bool:
    try:
        return stat.S_ISREG(path.stat(follow_symlinks=False).st_mode)
    except OSError:
        return False


def _is_swift_shebang(path: Path) -> bool:
    if not _is_regular_file(path):
        return False
    try:
        with path.open("rb") as source:
            first_line = source.readline(512)
    except OSError:
        return False
    return first_line.startswith(b"#!") and b"swift" in first_line.lower()


def swift_files(root: Path) -> list[Path]:
    """Return repository-owned Swift sources, excluding evidence and build trees."""

    paths: list[Path] = []
    for directory, child_directories, filenames in os.walk(root):
        relative_directory = Path(directory).relative_to(root)
        child_directories[:] = sorted(
            child
            for child in child_directories
            if not _is_ignored(relative_directory / child)
            and not (Path(directory) / child).is_symlink()
        )
        directory_path = Path(directory)
        for filename in sorted(filenames):
            path = directory_path / filename
            if filename.endswith(".swift") and _is_regular_file(path):
                paths.append(path)
    return sorted(paths, key=lambda item: item.relative_to(root).as_posix())


def configuration_files(root: Path) -> list[Path]:
    """Return active build and workflow configurations that can weaken Swift."""

    paths: list[Path] = []
    for directory, child_directories, filenames in os.walk(root):
        relative_directory = Path(directory).relative_to(root)
        child_directories[:] = sorted(
            child
            for child in child_directories
            if not _is_ignored(relative_directory / child)
            and not (Path(directory) / child).is_symlink()
        )
        directory_path = Path(directory)
        for filename in sorted(filenames):
            path = directory_path / filename
            if (
                filename in CONFIGURATION_FILENAMES
                or path.suffix in CONFIGURATION_SUFFIXES
            ) and _is_regular_file(path):
                paths.append(path)
    return sorted(paths, key=lambda item: item.relative_to(root).as_posix())


def _source_location(newline_offsets: list[int], position: int) -> tuple[int, int]:
    """Return a one-based line and column without rescanning source prefixes."""

    newline_index = bisect.bisect_left(newline_offsets, position)
    previous_newline = newline_offsets[newline_index - 1] if newline_index else -1
    return newline_index + 1, position - previous_newline


def _finding(
    *,
    path: Path,
    root: Path,
    source: str,
    newline_offsets: list[int],
    start: int,
    end: int,
    category: str,
) -> SafetyFinding:
    line, column = _source_location(newline_offsets, start)
    return SafetyFinding(
        path=path.relative_to(root),
        line=line,
        column=column,
        category=category,
        token=_diagnostic_token(source[start:end]),
    )


def _diagnostic_token(value: str) -> str:
    normalized = " ".join(value.split())
    if len(normalized) <= MAX_DIAGNOSTIC_TOKEN_CHARACTERS:
        return normalized
    return normalized[: MAX_DIAGNOSTIC_TOKEN_CHARACTERS - 3] + "..."


def _read_scannable_text(
    path: Path,
    root: Path,
) -> tuple[str | None, SafetyFinding | None]:
    try:
        size = path.stat(follow_symlinks=False).st_size
    except OSError as error:
        return None, SafetyFinding(
            path=path.relative_to(root),
            line=1,
            column=1,
            category="source/configuration cannot be inspected",
            token=str(error),
        )
    if size > MAX_SCANNED_FILE_BYTES:
        return None, SafetyFinding(
            path=path.relative_to(root),
            line=1,
            column=1,
            category="source/configuration exceeds safety scan size limit",
            token=f"{size} bytes exceeds {MAX_SCANNED_FILE_BYTES}",
        )
    try:
        return path.read_text(encoding="utf-8"), None
    except (OSError, UnicodeError) as error:
        return None, SafetyFinding(
            path=path.relative_to(root),
            line=1,
            column=1,
            category="source/configuration is not readable UTF-8",
            token=str(error),
        )


def _manifest_declarative_findings(
    path: Path,
    root: Path,
    source: str,
) -> list[SafetyFinding]:
    """Constrain manifests to a reviewable, deterministic declarative subset."""

    newline_offsets = [
        index for index, character in enumerate(source) if character == "\n"
    ]

    def violation(start: int, token: str) -> list[SafetyFinding]:
        return [
            _finding(
                path=path,
                root=root,
                source=source,
                newline_offsets=newline_offsets,
                start=start,
                end=min(len(source), start + max(1, len(token))),
                category="manifest outside approved declarative subset",
            )
        ]

    first_line, separator, body = source.partition("\n")
    if first_line.rstrip("\r") != MANIFEST_HEADER or not separator:
        return violation(0, first_line or "missing tools-version header")

    body_offset = len(first_line) + len(separator)
    tokens: list[tuple[str, int]] = []
    position = 0
    while position < len(body):
        match = MANIFEST_TOKEN.match(body, position)
        if match is None:
            return violation(body_offset + position, body[position])
        value = match.group(0)
        absolute_position = body_offset + position
        position = match.end()
        if value.isspace():
            continue
        if value.startswith('"'):
            tokens.append(("<string>", absolute_position))
            continue
        if value[0].isalpha() or value[0] == "_":
            if value not in MANIFEST_DECLARATIVE_IDENTIFIERS:
                return violation(absolute_position, value)
        tokens.append((value, absolute_position))

    values = [value for value, _ in tokens]
    required_prefix = [
        "import",
        "PackageDescription",
        "let",
        "package",
        "=",
        "Package",
        "(",
    ]
    if values[: len(required_prefix)] != required_prefix:
        start = tokens[0][1] if tokens else body_offset
        return violation(start, "manifest prelude")
    if values[-1:] != [")"] or values.count("let") != 1 or values.count("=") != 1:
        start = tokens[-1][1] if tokens else body_offset
        return violation(start, "manifest structure")

    openers: list[tuple[str, int]] = []
    matching = {")": "(", "]": "["}
    for value, start in tokens:
        if value in {"(", "["}:
            openers.append((value, start))
        elif value in matching:
            if not openers or openers[-1][0] != matching[value]:
                return violation(start, value)
            openers.pop()
    if openers:
        return violation(openers[-1][1], openers[-1][0])
    return []


def _manifest_policy_findings(
    path: Path,
    root: Path,
    source: str,
) -> list[SafetyFinding]:
    """Keep manifest evaluation in Swift 6 and PackageDescription only."""

    if path.name != "Package.swift":
        return []

    findings = _manifest_declarative_findings(path, root, source)
    newline_offsets = [
        index for index, character in enumerate(source) if character == "\n"
    ]
    for pattern in MANIFEST_PATTERNS:
        for match in pattern.expression.finditer(source):
            if len(findings) >= MAX_FINDINGS_PER_FILE:
                break
            findings.append(
                _finding(
                    path=path,
                    root=root,
                    source=source,
                    newline_offsets=newline_offsets,
                    start=match.start(),
                    end=match.end(),
                    category=pattern.category,
                )
            )
    total_lines = 0
    language_mode_count = 0
    language_mode_line = 0
    package_import_count = 0
    for total_lines, raw_line in enumerate(io.StringIO(source), start=1):
        line = raw_line.rstrip("\r\n")
        if line.strip() == "swiftLanguageModes: [.v6]":
            language_mode_count += 1
            language_mode_line = total_lines
        if not re.search(r"\bimport\b", line):
            continue
        if line.strip() == "import PackageDescription":
            package_import_count += 1
            continue
        if len(findings) < MAX_FINDINGS_PER_FILE:
            findings.append(
                SafetyFinding(
                    path=path.relative_to(root),
                    line=total_lines,
                    column=1,
                    category="manifest import outside PackageDescription",
                    token=_diagnostic_token(line),
                )
            )

    if language_mode_count != 1 or language_mode_line != total_lines - 1:
        findings.append(
            SafetyFinding(
                path=path.relative_to(root),
                line=1,
                column=1,
                category="manifest language-mode policy",
                token="require one terminal exact swiftLanguageModes: [.v6]",
            )
        )

    if package_import_count != 1:
        findings.append(
            SafetyFinding(
                path=path.relative_to(root),
                line=1,
                column=1,
                category="manifest import policy",
                token="require one exact import PackageDescription line",
            )
        )
    return findings


def _apply_approved_source_exception(
    *,
    path: Path,
    root: Path,
    findings: list[SafetyFinding],
) -> list[SafetyFinding]:
    """Suppress only one exact reviewed finding multiset and file fingerprint."""

    relative = path.relative_to(root)
    approved = APPROVED_SOURCE_EXCEPTIONS.get(relative)
    if approved is None:
        return findings

    if not _is_regular_file(root / APPROVED_EXCEPTION_POLICY_PATH):
        return sorted(
            findings
            + [
                SafetyFinding(
                    path=APPROVED_EXCEPTION_POLICY_PATH,
                    line=1,
                    column=1,
                    category="approved source exception policy missing",
                    token=APPROVED_EXCEPTION_POLICY_PATH.as_posix(),
                )
            ]
        )

    try:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError as error:
        return sorted(
            findings
            + [
                SafetyFinding(
                    path=relative,
                    line=1,
                    column=1,
                    category="approved source exception cannot be fingerprinted",
                    token=str(error),
                )
            ]
        )
    actual_findings = tuple(
        sorted((finding.category, finding.token) for finding in findings)
    )
    expected_findings = tuple(sorted(approved.expected_findings))
    if digest == approved.sha256 and actual_findings == expected_findings:
        return []

    mismatch_category = (
        "approved source exception fingerprint mismatch"
        if digest != approved.sha256
        else "approved source exception finding mismatch"
    )
    return sorted(
        findings
        + [
            SafetyFinding(
                path=relative,
                line=1,
                column=1,
                category=mismatch_category,
                token=(
                    f"observed sha256 {digest}; expected {approved.sha256}; "
                    f"observed findings {len(actual_findings)}; "
                    f"expected {len(expected_findings)}"
                ),
            )
        ]
    )


def scan_file(path: Path, root: Path) -> list[SafetyFinding]:
    """Find prohibited spellings under the governed exception policy."""

    source, read_finding = _read_scannable_text(path, root)
    if read_finding is not None:
        return [read_finding]
    assert source is not None
    newline_offsets = [
        index for index, character in enumerate(source) if character == "\n"
    ]
    candidates: list[tuple[int, int, int, SafetyPattern]] = []
    candidate_count = 0
    source_patterns = tuple(
        pattern for pattern in PATTERNS if pattern.scan_swift_source
    )
    for pattern_index, pattern in enumerate(source_patterns):
        retained_for_pattern = 0
        for match in pattern.expression.finditer(source):
            candidate_count += 1
            if retained_for_pattern < MAX_FINDINGS_PER_FILE:
                candidates.append(
                    (match.start(), match.end(), pattern_index, pattern)
                )
                retained_for_pattern += 1

    candidates.sort(key=lambda item: (item[0], -(item[1] - item[0]), item[2]))
    findings: list[SafetyFinding] = []
    distinct_retained_count = 0
    occupied_end = -1
    for start, end, _, pattern in candidates:
        if start < occupied_end:
            continue
        occupied_end = end
        distinct_retained_count += 1
        if len(findings) < MAX_FINDINGS_PER_FILE:
            findings.append(
                _finding(
                    path=path,
                    root=root,
                    source=source,
                    newline_offsets=newline_offsets,
                    start=start,
                    end=end,
                    category=pattern.category,
                )
            )

    manifest_findings = _manifest_policy_findings(
        path,
        root,
        source,
    )
    findings = sorted(findings + manifest_findings)[:MAX_FINDINGS_PER_FILE]
    omitted_count = max(
        0,
        distinct_retained_count
        + (candidate_count - len(candidates))
        + len(manifest_findings)
        - len(findings),
    )
    if omitted_count:
        findings.append(
            SafetyFinding(
                path=path.relative_to(root),
                line=source.count("\n") + 1,
                column=1,
                category="additional prohibited matches omitted",
                token=f"{omitted_count} additional matches",
            )
        )
    return _apply_approved_source_exception(
        path=path,
        root=root,
        findings=findings,
    )


def scan_configuration_file(path: Path, root: Path) -> list[SafetyFinding]:
    """Find weakened compiler-safety flags in an active configuration file."""

    source, read_finding = _read_scannable_text(path, root)
    if read_finding is not None:
        return [read_finding]
    assert source is not None
    newline_offsets = [
        index for index, character in enumerate(source) if character == "\n"
    ]
    findings: list[SafetyFinding] = []
    finding_count = 0
    patterns = tuple(
        pattern for pattern in PATTERNS if pattern.include_string_payloads
    )
    for pattern in patterns:
        for match in pattern.expression.finditer(source):
            finding_count += 1
            if len(findings) < MAX_FINDINGS_PER_FILE:
                findings.append(
                    _finding(
                        path=path,
                        root=root,
                        source=source,
                        newline_offsets=newline_offsets,
                        start=match.start(),
                        end=match.end(),
                        category=pattern.category,
                    )
                )

    for line_number, raw_line in enumerate(io.StringIO(source), start=1):
        line = raw_line.rstrip("\r\n")
        for setting in XCODE_FORBIDDEN_SETTINGS:
            for _ in re.finditer(rf"\b{setting}\b", line):
                finding_count += 1
                if len(findings) >= MAX_FINDINGS_PER_FILE:
                    continue
                findings.append(
                    SafetyFinding(
                        path=path.relative_to(root),
                        line=line_number,
                        column=1,
                        category="forbidden Xcode Swift setting",
                        token=_diagnostic_token(line),
                    )
                )

        for setting, safe_values in XCODE_SAFE_SETTINGS.items():
            if setting not in line:
                continue
            setting_token_count = sum(
                1 for _ in re.finditer(rf"\b{setting}\b", line)
            )
            assignment_count = 0
            unsafe_count = 0
            for assignment in re.finditer(
                rf"\b{setting}(?:\[[^\]\r\n]+\])?\s*=\s*"
                r"(\"[^\"]*\"|'[^']*'|[^\s;#)]+)",
                line,
            ):
                assignment_count += 1
                value = assignment.group(1).strip("\"'").lower()
                unsafe_count += value not in safe_values
            unsafe_count += max(0, setting_token_count - assignment_count)
            finding_count += unsafe_count
            for _ in range(unsafe_count):
                if len(findings) >= MAX_FINDINGS_PER_FILE:
                    break
                findings.append(
                    SafetyFinding(
                        path=path.relative_to(root),
                        line=line_number,
                        column=1,
                        category="unsafe or dynamic Xcode Swift setting",
                        token=_diagnostic_token(line),
                    )
                )
    findings = sorted(findings)[:MAX_FINDINGS_PER_FILE]
    omitted_count = max(0, finding_count - len(findings))
    if omitted_count:
        findings.append(
            SafetyFinding(
                path=path.relative_to(root),
                line=source.count("\n") + 1,
                column=1,
                category="additional prohibited matches omitted",
                token=f"{omitted_count} additional matches",
            )
        )
    return findings


def _is_known_swift_path(relative: Path) -> bool:
    if relative.name == "Package.swift" or re.fullmatch(
        r"Package@swift-[0-9.]+\.swift",
        relative.name,
    ):
        return relative in KNOWN_MANIFESTS
    if relative in KNOWN_MANIFESTS:
        return True
    return any(
        tree == relative or tree in relative.parents
        for tree in KNOWN_SWIFT_TREES
    )


def repository_scope_findings(root: Path) -> list[SafetyFinding]:
    """Reject Swift outside approved package trees and scan-affecting symlinks."""

    findings: list[SafetyFinding] = []

    def add(finding: SafetyFinding) -> None:
        if len(findings) < MAX_REPOSITORY_FINDINGS:
            findings.append(finding)

    exception_governance_present = (
        root.resolve() == ROOT.resolve()
        or _is_regular_file(root / APPROVED_EXCEPTION_POLICY_PATH)
        or any(
            _is_regular_file(root / relative)
            for relative in APPROVED_SOURCE_EXCEPTIONS
        )
    )
    if exception_governance_present:
        if not _is_regular_file(root / APPROVED_EXCEPTION_POLICY_PATH):
            add(
                SafetyFinding(
                    path=APPROVED_EXCEPTION_POLICY_PATH,
                    line=1,
                    column=1,
                    category="approved source exception policy missing",
                    token=APPROVED_EXCEPTION_POLICY_PATH.as_posix(),
                )
            )
        for relative in APPROVED_SOURCE_EXCEPTIONS:
            if _is_regular_file(root / relative):
                continue
            add(
                SafetyFinding(
                    path=relative,
                    line=1,
                    column=1,
                    category="approved source exception missing",
                    token=relative.as_posix(),
                )
            )

    for path in swift_files(root):
        relative = path.relative_to(root)
        if _is_known_swift_path(relative):
            continue
        add(
            SafetyFinding(
                path=relative,
                line=1,
                column=1,
                category="Swift source outside approved package trees",
                token=relative.as_posix(),
            )
        )

    for directory, child_directories, filenames in os.walk(root):
        relative_directory = Path(directory).relative_to(root)
        retained_directories: list[str] = []
        for child in sorted(child_directories):
            relative = relative_directory / child
            if _is_ignored(relative):
                continue
            path = Path(directory) / child
            if path.is_symlink():
                add(
                    SafetyFinding(
                        path=relative,
                        line=1,
                        column=1,
                        category="directory symlink outside safety inventory",
                        token=relative.as_posix(),
                    )
                )
                continue
            retained_directories.append(child)
        child_directories[:] = retained_directories

        for filename in sorted(filenames):
            path = Path(directory) / filename
            relative = path.relative_to(root)
            relevant = (
                filename.endswith(".swift")
                or filename in CONFIGURATION_FILENAMES
                or path.suffix in CONFIGURATION_SUFFIXES
            )
            if path.is_symlink():
                add(
                    SafetyFinding(
                        path=relative,
                        line=1,
                        column=1,
                        category="file symlink outside safety inventory",
                        token=relative.as_posix(),
                    )
                )
                continue
            if relevant and not _is_regular_file(path):
                add(
                    SafetyFinding(
                        path=relative,
                        line=1,
                        column=1,
                        category="non-regular source/configuration file",
                        token=relative.as_posix(),
                    )
                )
                continue
            if not filename.endswith(".swift") and _is_swift_shebang(path):
                add(
                    SafetyFinding(
                        path=relative,
                        line=1,
                        column=1,
                        category="non-.swift Swift script outside package coverage",
                        token=relative.as_posix(),
                    )
                )

    return sorted(findings)


def scan_repository(root: Path) -> list[SafetyFinding]:
    """Find prohibited constructs in all repository-owned Swift sources."""

    findings = repository_scope_findings(root)
    if findings:
        return sorted(findings)
    for path in swift_files(root):
        findings.extend(scan_file(path, root))
        if len(findings) >= MAX_REPOSITORY_FINDINGS:
            return sorted(findings[:MAX_REPOSITORY_FINDINGS])
    for path in configuration_files(root):
        findings.extend(scan_configuration_file(path, root))
        if len(findings) >= MAX_REPOSITORY_FINDINGS:
            return sorted(findings[:MAX_REPOSITORY_FINDINGS])
    return sorted(findings)


def _swiftpm_environment() -> dict[str, str]:
    """Run SwiftPM without consulting slow or mutable repository metadata."""

    environment = os.environ.copy()
    environment["GIT_DIR"] = os.devnull
    return environment


def _kill_process_group(process: subprocess.Popen[bytes]) -> None:
    """Kill a bounded command and every child that inherited its process group."""

    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()


def _captured_process_result(
    process: subprocess.Popen[bytes],
    command: list[str],
    timeout: int,
) -> subprocess.CompletedProcess[str]:
    """Drain stdout/stderr incrementally with time and byte ceilings."""

    assert process.stdout is not None
    assert process.stderr is not None
    streams = {
        process.stdout: bytearray(),
        process.stderr: bytearray(),
    }

    def timeout_error() -> subprocess.TimeoutExpired:
        return subprocess.TimeoutExpired(
            command,
            timeout,
            output=streams[process.stdout].decode("utf-8", errors="replace"),
            stderr=streams[process.stderr].decode("utf-8", errors="replace"),
        )

    deadline = time.monotonic() + timeout
    total_bytes = 0
    try:
        with selectors.DefaultSelector() as selector:
            for stream in streams:
                selector.register(stream, selectors.EVENT_READ)
            while selector.get_map():
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    _kill_process_group(process)
                    raise timeout_error()
                for key, _ in selector.select(timeout=min(remaining, 0.1)):
                    stream = key.fileobj
                    chunk = os.read(stream.fileno(), 64 * 1024)
                    if not chunk:
                        selector.unregister(stream)
                        continue
                    total_bytes += len(chunk)
                    if total_bytes > MAX_SUBPROCESS_OUTPUT_BYTES:
                        _kill_process_group(process)
                        raise SubprocessOutputLimitExceeded(
                            command,
                            MAX_SUBPROCESS_OUTPUT_BYTES,
                        )
                    streams[stream].extend(chunk)

        remaining = max(0.0, deadline - time.monotonic())
        try:
            returncode = process.wait(timeout=remaining)
        except subprocess.TimeoutExpired as error:
            _kill_process_group(process)
            raise timeout_error() from error
        return subprocess.CompletedProcess(
            command,
            returncode,
            streams[process.stdout].decode("utf-8", errors="replace"),
            streams[process.stderr].decode("utf-8", errors="replace"),
        )
    finally:
        process.stdout.close()
        process.stderr.close()


def _run_bounded(
    command: list[str],
    *,
    cwd: Path,
    timeout: int,
    capture_output: bool,
) -> subprocess.CompletedProcess[str]:
    """Run a command in a process group so timeout cleanup includes children."""

    process = subprocess.Popen(
        command,
        cwd=cwd,
        env=_swiftpm_environment(),
        stdout=subprocess.PIPE if capture_output else None,
        stderr=subprocess.PIPE if capture_output else None,
        start_new_session=True,
    )
    if capture_output:
        return _captured_process_result(process, command, timeout)
    try:
        returncode = process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        _kill_process_group(process)
        raise
    return subprocess.CompletedProcess(
        command,
        returncode,
        None,
        None,
    )


def _dependency_errors(
    dump: dict[str, object],
    root: Path,
    package_path: Path,
) -> list[str]:
    dependencies = dump.get("dependencies")
    if not isinstance(dependencies, list):
        return [f"{package_path}: package dump has malformed dependencies"]

    actual_paths: set[Path] = set()
    errors: list[str] = []
    for dependency in dependencies:
        if not isinstance(dependency, dict) or set(dependency) != {"fileSystem"}:
            errors.append(
                f"{package_path}: non-filesystem SwiftPM dependency is outside "
                "the repository-owned safety inventory"
            )
            continue
        entries = dependency.get("fileSystem")
        if not isinstance(entries, list) or len(entries) != 1:
            errors.append(f"{package_path}: malformed filesystem dependency")
            continue
        entry = entries[0]
        dependency_path = entry.get("path") if isinstance(entry, dict) else None
        if not isinstance(dependency_path, str):
            errors.append(f"{package_path}: filesystem dependency has no path")
            continue
        resolved_dependency = Path(dependency_path).resolve()
        try:
            actual_paths.add(resolved_dependency.relative_to(root.resolve()))
        except ValueError:
            errors.append(
                f"{package_path}: filesystem dependency escapes repository: "
                f"{resolved_dependency}"
            )

    expected_paths = EXPECTED_LOCAL_DEPENDENCIES[package_path]
    if actual_paths != expected_paths:
        errors.append(
            f"{package_path}: local dependency paths are "
            f"{sorted(path.as_posix() for path in actual_paths)!r}, expected "
            f"{sorted(path.as_posix() for path in expected_paths)!r}"
        )
    return errors


def package_description_errors(root: Path, package_path: Path) -> list[str]:
    """Validate effective language mode and complete target-source coverage."""

    package_root = (root / package_path).resolve()
    commands = (
        ["swift", "package", "dump-package"],
        ["swift", "package", "describe", "--type", "json"],
    )
    documents: list[dict[str, object]] = []
    for command in commands:
        try:
            result = _run_bounded(
                command,
                cwd=package_root,
                timeout=PACKAGE_COMMAND_TIMEOUT_SECONDS,
                capture_output=True,
            )
        except subprocess.TimeoutExpired:
            return [
                f"{package_path}: {' '.join(command)} exceeded "
                f"{PACKAGE_COMMAND_TIMEOUT_SECONDS} seconds"
            ]
        except SubprocessOutputLimitExceeded as error:
            return [f"{package_path}: {error}"]
        if result.returncode != 0:
            return [
                f"{package_path}: {' '.join(command)} failed: "
                f"{result.stderr.strip()}"
            ]
        try:
            documents.append(json.loads(result.stdout))
        except json.JSONDecodeError as error:
            return [f"{package_path}: invalid SwiftPM JSON: {error}"]

    dump, description = documents
    errors: list[str] = []
    if dump.get("swiftLanguageVersions") != ["6"]:
        errors.append(
            f"{package_path}: effective Swift language modes are "
            f"{dump.get('swiftLanguageVersions')!r}, expected ['6']"
        )
    errors.extend(_dependency_errors(dump, root, package_path))

    dumped_targets = dump.get("targets")
    if not isinstance(dumped_targets, list):
        errors.append(f"{package_path}: package dump has no targets")
    else:
        for target in dumped_targets:
            if not isinstance(target, dict):
                errors.append(f"{package_path}: malformed dumped target")
                continue
            for setting in target.get("settings", []):
                if not isinstance(setting, dict):
                    errors.append(
                        f"{package_path}: malformed build setting in "
                        f"{target.get('name', '<unnamed>')}"
                    )
                    continue
                kind = setting.get("kind")
                if isinstance(kind, dict) and "unsafeFlags" in kind:
                    errors.append(
                        f"{package_path}: target "
                        f"{target.get('name', '<unnamed>')} uses unsafeFlags"
                    )
                if isinstance(kind, dict) and "swiftLanguageMode" in kind:
                    errors.append(
                        f"{package_path}: target "
                        f"{target.get('name', '<unnamed>')} overrides the "
                        "package Swift language mode"
                    )

    scanned_sources = {path.resolve() for path in swift_files(root)}
    eligible_trees = PACKAGE_SOURCE_TREES[package_path]
    eligible_sources = {
        path.resolve()
        for path in swift_files(root)
        if any(
            tree == path.relative_to(root)
            or tree in path.relative_to(root).parents
            for tree in eligible_trees
        )
    }
    described_sources: set[Path] = set()
    targets = description.get("targets")
    if not isinstance(targets, list):
        return errors + [f"{package_path}: SwiftPM description has no targets"]
    for target in targets:
        if not isinstance(target, dict):
            errors.append(f"{package_path}: malformed SwiftPM target description")
            continue
        target_name = target.get("name", "<unnamed>")
        target_path = target.get("path")
        sources = target.get("sources")
        if not isinstance(target_path, str) or not isinstance(sources, list):
            errors.append(f"{package_path}: target {target_name} has invalid paths")
            continue
        for source_name in sources:
            if not isinstance(source_name, str) or not source_name.endswith(".swift"):
                continue
            source_path = (package_root / target_path / source_name).resolve()
            described_sources.add(source_path)
            try:
                relative_source = source_path.relative_to(root.resolve())
            except ValueError:
                errors.append(
                    f"{package_path}: target {target_name} source escapes repository: "
                    f"{source_path}"
                )
                continue
            if source_path not in scanned_sources:
                errors.append(
                    f"{package_path}: target {target_name} source is outside the "
                    f"safety inventory: {relative_source}"
                )
            elif source_path not in eligible_sources:
                errors.append(
                    f"{package_path}: target {target_name} source is outside the "
                    f"package source trees: {relative_source}"
                )
    for orphan_source in sorted(
        eligible_sources - described_sources,
        key=lambda item: item.relative_to(root.resolve()).as_posix(),
    ):
        errors.append(
            f"{package_path}: Swift source is not compiled by any target: "
            f"{orphan_source.relative_to(root.resolve())}"
        )
    return errors


def strict_memory_safety_command(
    package_path: Path,
    configuration: str = "debug",
) -> list[str]:
    """Build command using Swift's semantic strict-memory-safety oracle."""

    command = ["swift", "build", "--build-tests"]
    if configuration == "release":
        command.extend(["--configuration", "release"])
    elif configuration != "debug":
        raise ValueError(f"unsupported build configuration: {configuration}")
    if package_path != Path("."):
        command.extend(["--package-path", str(package_path)])
    command.extend(
        [
            "-Xswiftc",
            "-strict-memory-safety",
            "-Xswiftc",
            "-warnings-as-errors",
        ]
    )
    if configuration == "release":
        command.extend(["-Xswiftc", "-enable-testing"])
    return command


def compile_with_strict_memory_safety(root: Path) -> int:
    """Compile every repository package with compiler-known unsafe uses denied."""

    for package_path in PACKAGE_PATHS:
        resolved_package = root / package_path
        if not (resolved_package / "Package.swift").is_file():
            print(
                "Swift strict-memory-safety build failed: missing package at "
                f"{package_path}"
            )
            return 2
        description_errors = package_description_errors(root, package_path)
        if description_errors:
            print("Swift package safety coverage failed:")
            for error in description_errors:
                print(f"- {error}")
            return 1
        for configuration in ("debug", "release"):
            print(f"Strict-memory-safety build: {package_path} ({configuration})")
            try:
                result = _run_bounded(
                    strict_memory_safety_command(package_path, configuration),
                    cwd=root,
                    timeout=PACKAGE_BUILD_TIMEOUT_SECONDS,
                    capture_output=False,
                )
            except subprocess.TimeoutExpired:
                print(
                    "Swift strict-memory-safety build timed out for package: "
                    f"{package_path} ({configuration}) after "
                    f"{PACKAGE_BUILD_TIMEOUT_SECONDS} seconds"
                )
                return 1
            if result.returncode != 0:
                print(
                    "Swift strict-memory-safety build failed for package: "
                    f"{package_path} ({configuration})"
                )
                return result.returncode
    print("Swift strict-memory-safety builds passed for all repository packages.")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=ROOT,
        help="repository root to scan (defaults to this script's repository)",
    )
    parser.add_argument(
        "--compile",
        action="store_true",
        help=(
            "also build every repository package with compiler strict-memory-"
            "safety diagnostics promoted to errors"
        ),
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    root = args.root.resolve()
    if not root.is_dir():
        print(f"Swift safety check failed: repository root is not a directory: {root}")
        return 2
    findings = scan_repository(root)

    if findings:
        print("Swift safety check failed:")
        for finding in findings:
            print(f"- {finding.diagnostic()}")
        print(
            "Current policy permits no ungoverned exceptions. See "
            "docs/security/SWIFT_SAFETY_POLICY.md."
        )
        return 1

    if args.compile:
        compile_status = compile_with_strict_memory_safety(root)
        if compile_status != 0:
            return compile_status

    if args.compile:
        print(
            "Swift safety check passed: no compiler-classified unsafe Swift "
            "or unchecked Sendable exceptions found."
        )
    else:
        print(
            "Swift safety inventory scan passed: no unapproved escape-hatch "
            "syntax or compiler configuration found. Use --compile for the "
            "semantic compiler gate."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

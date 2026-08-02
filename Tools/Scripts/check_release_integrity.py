#!/usr/bin/env python3
"""Verify or regenerate Voxelia's repository release-integrity ledgers."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = "manifest.txt"
INVENTORY = "RELEASE_INVENTORY.json"
CHECKSUMS = "release-checksums.sha256"
LEDGERS = (MANIFEST, INVENTORY, CHECKSUMS)
IGNORED_DIRECTORIES = {
    ".build",
    ".git",
    ".idea",
    ".local",
    ".swiftpm",
    ".tmp",
    ".vscode",
    "DerivedData",
    "__pycache__",
    "coverage",
    "xcuserdata",
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def repository_paths(root: Path) -> list[str]:
    """Return releasable files, using Git ignore rules when available."""

    if (root / ".git").exists():
        result = subprocess.run(
            [
                "git",
                "-C",
                str(root),
                "ls-files",
                "--cached",
                "--others",
                "--exclude-standard",
                "-z",
            ],
            check=True,
            capture_output=True,
        )
        try:
            paths = [
                raw_path.decode("utf-8")
                for raw_path in result.stdout.split(b"\0")
                if raw_path
            ]
        except UnicodeDecodeError as error:
            raise ValueError(f"repository path is not valid UTF-8: {error}") from error
        return sorted(path for path in paths if (root / path).is_file())

    paths: list[str] = []
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        if any(component in IGNORED_DIRECTORIES for component in relative.parts):
            continue
        if path.name == ".DS_Store" or path.suffix in {".pyc", ".pyo"}:
            continue
        if path.is_file():
            paths.append(relative.as_posix())
    return sorted(paths)


def inventory_metadata(root: Path) -> dict[str, object]:
    try:
        document = json.loads((root / INVENTORY).read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot read {INVENTORY}: {error}") from error
    if not isinstance(document, dict):
        raise ValueError(f"{INVENTORY} must contain a JSON object")

    metadata = {key: value for key, value in document.items() if key != "files"}
    for key in ("schemaVersion", "project", "release", "platform"):
        if not isinstance(metadata.get(key), str) or not metadata[key]:
            raise ValueError(f"{INVENTORY} has invalid or missing {key!r}")
    return metadata


def expected_manifest(paths: list[str]) -> list[str]:
    return [path for path in paths if path != MANIFEST]


def expected_inventory(root: Path, paths: list[str]) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    for relative_path in paths:
        if relative_path in {INVENTORY, CHECKSUMS}:
            continue
        path = root / relative_path
        records.append(
            {
                "path": relative_path,
                "size": path.stat().st_size,
                "sha256": sha256_file(path),
            }
        )
    return records


def expected_checksums(root: Path, paths: list[str]) -> list[str]:
    return [
        f"{sha256_file(root / path)}  {path}"
        for path in paths
        if path != CHECKSUMS
    ]


def summarize_paths(paths: list[str]) -> str:
    visible = paths[:5]
    summary = ", ".join(repr(path) for path in visible)
    if len(paths) > len(visible):
        summary += f", and {len(paths) - len(visible)} more"
    return summary


def compare_path_lists(
    label: str,
    actual: list[str],
    expected: list[str],
) -> list[str]:
    errors: list[str] = []
    actual_set = set(actual)
    expected_set = set(expected)
    missing = sorted(expected_set - actual_set)
    unexpected = sorted(actual_set - expected_set)
    if missing:
        errors.append(f"{label} is missing paths: {summarize_paths(missing)}")
    if unexpected:
        errors.append(f"{label} has unexpected paths: {summarize_paths(unexpected)}")
    if not missing and not unexpected and actual != expected:
        errors.append(f"{label} paths are not in canonical sorted order")
    if len(actual) != len(actual_set):
        errors.append(f"{label} contains duplicate paths")
    return errors


def read_inventory(root: Path) -> tuple[list[dict[str, object]], list[str]]:
    try:
        document = json.loads((root / INVENTORY).read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return [], [f"cannot read {INVENTORY}: {error}"]
    if not isinstance(document, dict) or not isinstance(document.get("files"), list):
        return [], [f"{INVENTORY} must contain a 'files' array"]
    if not all(isinstance(record, dict) for record in document["files"]):
        return [], [f"{INVENTORY} contains a non-object file record"]
    return document["files"], []


def read_checksums(root: Path) -> tuple[list[tuple[str, str]], list[str]]:
    try:
        lines = (root / CHECKSUMS).read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        return [], [f"cannot read {CHECKSUMS}: {error}"]

    records: list[tuple[str, str]] = []
    errors: list[str] = []
    for line_number, line in enumerate(lines, start=1):
        digest, separator, path = line.partition("  ")
        if (
            separator != "  "
            or len(digest) != 64
            or any(character not in "0123456789abcdef" for character in digest)
            or not path
        ):
            errors.append(f"{CHECKSUMS} line {line_number} is malformed")
            continue
        records.append((path, digest))
    return records, errors


def check_integrity(root: Path) -> list[str]:
    try:
        paths = repository_paths(root)
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        return [f"cannot enumerate repository files: {error}"]

    errors: list[str] = []
    try:
        manifest_paths = (root / MANIFEST).read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        manifest_paths = []
        errors.append(f"cannot read {MANIFEST}: {error}")
    errors.extend(
        compare_path_lists("manifest", manifest_paths, expected_manifest(paths))
    )

    inventory, inventory_errors = read_inventory(root)
    errors.extend(inventory_errors)
    try:
        inventory_metadata(root)
    except ValueError as error:
        errors.append(str(error))
    if not inventory_errors:
        actual_inventory_paths = [record.get("path") for record in inventory]
        if not all(isinstance(path, str) for path in actual_inventory_paths):
            errors.append(f"{INVENTORY} contains an invalid path")
        else:
            expected_records = expected_inventory(root, paths)
            errors.extend(
                compare_path_lists(
                    "release inventory",
                    actual_inventory_paths,
                    [record["path"] for record in expected_records],
                )
            )
            actual_by_path = {record.get("path"): record for record in inventory}
            for expected_record in expected_records:
                path = expected_record["path"]
                actual_record = actual_by_path.get(path)
                if actual_record is not None and actual_record != expected_record:
                    errors.append(f"release inventory metadata mismatch: {path!r}")

    checksums, checksum_errors = read_checksums(root)
    errors.extend(checksum_errors)
    if not checksum_errors:
        actual_checksum_paths = [path for path, _ in checksums]
        expected_lines = expected_checksums(root, paths)
        expected_checksum_records = [
            (line[66:], line[:64]) for line in expected_lines
        ]
        errors.extend(
            compare_path_lists(
                "checksum ledger",
                actual_checksum_paths,
                [path for path, _ in expected_checksum_records],
            )
        )
        actual_by_path = {path: digest for path, digest in checksums}
        for path, digest in expected_checksum_records:
            if path in actual_by_path and actual_by_path[path] != digest:
                errors.append(f"checksum mismatch: {path!r}")

    return errors


def write_integrity(root: Path) -> tuple[int, int, int]:
    for ledger in LEDGERS:
        (root / ledger).touch(exist_ok=True)
    paths = repository_paths(root)

    manifest = expected_manifest(paths)
    (root / MANIFEST).write_text("\n".join(manifest) + "\n", encoding="utf-8")

    inventory = inventory_metadata(root)
    inventory["files"] = expected_inventory(root, paths)
    (root / INVENTORY).write_text(
        json.dumps(inventory, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    checksums = expected_checksums(root, paths)
    (root / CHECKSUMS).write_text("\n".join(checksums) + "\n", encoding="utf-8")
    return len(manifest), len(inventory["files"]), len(checksums)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT, help="repository root")
    parser.add_argument(
        "--write",
        action="store_true",
        help="regenerate integrity ledgers instead of checking them",
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    root = arguments.root.resolve()
    if arguments.write:
        try:
            manifest_count, inventory_count, checksum_count = write_integrity(root)
        except (OSError, subprocess.CalledProcessError, ValueError) as error:
            print(f"Release integrity update failed: {error}")
            return 1
        print(
            "Release integrity ledgers updated: "
            f"{manifest_count} manifest paths, "
            f"{inventory_count} inventory records, "
            f"{checksum_count} checksums."
        )
        return 0

    errors = check_integrity(root)
    if errors:
        print("Release integrity check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Release integrity check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

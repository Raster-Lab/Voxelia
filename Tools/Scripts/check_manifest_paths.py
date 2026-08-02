#!/usr/bin/env python3
"""Reject ambiguous or non-portable paths in a release manifest."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
import unicodedata


ROOT = Path(__file__).resolve().parents[2]


def portable_key(path: str) -> str:
    """Return a Unicode-normalized, case-insensitive comparison key."""

    normalized = unicodedata.normalize("NFC", path)
    return unicodedata.normalize("NFC", normalized.casefold())


def validate_manifest(manifest: Path) -> tuple[int, list[str]]:
    """Return the entry count and all path-safety errors in ``manifest``."""

    try:
        lines = manifest.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        return 0, [f"cannot read {manifest}: {error}"]

    errors: list[str] = []
    seen: dict[str, tuple[int, str]] = {}
    seen_prefixes: dict[tuple[str, ...], tuple[int, str]] = {}
    valid_entries: list[tuple[int, str, tuple[str, ...]]] = []

    if not lines:
        errors.append("manifest is empty")

    for line_number, raw_entry in enumerate(lines, start=1):
        entry = raw_entry.strip()
        if not entry:
            errors.append(f"line {line_number}: path is empty")
            continue
        if entry != raw_entry:
            errors.append(
                f"line {line_number}: path has surrounding whitespace: {raw_entry!r}"
            )
        if entry.startswith("/"):
            errors.append(f"line {line_number}: absolute path is not allowed: {entry!r}")
        if "\\" in entry:
            errors.append(f"line {line_number}: use '/' separators: {entry!r}")
        if "\0" in entry:
            errors.append(f"line {line_number}: NUL is not allowed in a path")

        components = entry.split("/")
        unsafe_component = next(
            (component for component in components if component in {"", ".", ".."}),
            None,
        )
        if unsafe_component is not None:
            errors.append(
                f"line {line_number}: unsafe path component {unsafe_component!r}: {entry!r}"
            )

        prefix_collision = False
        if (
            not entry.startswith("/")
            and "\\" not in entry
            and "\0" not in entry
            and unsafe_component is None
        ):
            key_parts: list[str] = []
            raw_parts: list[str] = []
            for component in components:
                key_parts.append(portable_key(component))
                raw_parts.append(component)
                key = tuple(key_parts)
                prefix = "/".join(raw_parts)
                previous_prefix = seen_prefixes.get(key)
                if previous_prefix is None:
                    seen_prefixes[key] = (line_number, prefix)
                    continue

                previous_line, previous_spelling = previous_prefix
                if previous_spelling != prefix:
                    errors.append(
                        f"line {line_number}: path prefix {prefix!r} collides with "
                        f"{previous_spelling!r} from line {previous_line} on "
                        "case-insensitive or Unicode-normalizing filesystems"
                    )
                    prefix_collision = True
                    break

            valid_entries.append(
                (
                    line_number,
                    entry,
                    tuple(portable_key(component) for component in components),
                )
            )

        key = portable_key(entry)
        previous = seen.get(key)
        if previous is None:
            seen[key] = (line_number, entry)
            continue

        previous_line, previous_entry = previous
        if previous_entry == entry:
            errors.append(
                f"line {line_number}: duplicate path {entry!r}; "
                f"first listed on line {previous_line}"
            )
        elif not prefix_collision:
            errors.append(
                f"line {line_number}: path {entry!r} collides with {previous_entry!r} "
                f"from line {previous_line} on case-insensitive or "
                "Unicode-normalizing filesystems"
            )

    entries_by_components: dict[tuple[str, ...], tuple[int, str]] = {}
    for line_number, entry, components in valid_entries:
        entries_by_components.setdefault(components, (line_number, entry))

    for line_number, entry, components in valid_entries:
        for depth in range(1, len(components)):
            parent = entries_by_components.get(components[:depth])
            if parent is None:
                continue
            parent_line, parent_entry = parent
            errors.append(
                f"line {line_number}: path {entry!r} requires {parent_entry!r} "
                f"from line {parent_line} to be both a file and a directory"
            )
            break

    return len(lines), errors


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=ROOT / "manifest.txt",
        help="manifest to validate (default: repository manifest.txt)",
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    entry_count, errors = validate_manifest(arguments.manifest)
    if errors:
        print("Manifest path check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Manifest path check passed for {entry_count} entries.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

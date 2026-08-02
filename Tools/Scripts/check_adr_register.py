#!/usr/bin/env python3
"""Validate metadata and identifier consistency for file-backed ADRs."""
from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DECISIONS_DIR = ROOT / "docs" / "architecture" / "decisions"
ADR_ID_PATTERN = re.compile(r"ADR-(?:[0-9]{4}|M[0-9]+-[0-9]{3})")
TOP_LEVEL_FIELD_PATTERN = re.compile(r"^([A-Za-z0-9_]+):(?:\s*(.*))?$")
LIST_ITEM_PATTERN = re.compile(r"^\s+-\s*(.*?)\s*$")
FENCE_PATTERN = re.compile(r"^ {0,3}(`{3,}|~{3,})")
REQUIRED_SCALARS = ("document_id", "title", "status", "date")
REQUIRED_LISTS = ("owners", "affected_requirements")


def unquote(value: str) -> str:
    """Remove one matching pair of simple YAML string quotes."""
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def parse_front_matter(text: str) -> tuple[dict[str, object], str, list[str]]:
    """Parse the small ADR front-matter subset used by the project."""
    if not text.startswith("---\n"):
        return {}, text, ["missing opening front matter"]

    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text, ["missing closing front matter"]

    block = text[4:end]
    body = text[end + len("\n---\n") :]
    fields: dict[str, object] = {}
    errors: list[str] = []
    current_list: str | None = None

    for line_number, line in enumerate(block.splitlines(), 2):
        field_match = TOP_LEVEL_FIELD_PATTERN.fullmatch(line)
        if field_match:
            key, raw_value = field_match.groups()
            if key in fields:
                errors.append(
                    f"front matter line {line_number}: duplicate field {key}"
                )
                current_list = None
                continue

            raw_value = (raw_value or "").strip()
            if raw_value:
                fields[key] = unquote(raw_value)
                current_list = None
            else:
                fields[key] = []
                current_list = key
            continue

        list_match = LIST_ITEM_PATTERN.fullmatch(line)
        if current_list is not None and list_match:
            value = unquote(list_match.group(1))
            current_values = fields[current_list]
            if isinstance(current_values, list):
                current_values.append(value)
            continue

        if line.strip() and not line.lstrip().startswith("#"):
            errors.append(
                f"front matter line {line_number}: unsupported or malformed syntax"
            )
            current_list = None

    return fields, body, errors


def h1_headings(body: str) -> list[str]:
    """Return H1 headings outside fenced Markdown code blocks."""
    headings: list[str] = []
    open_fence: tuple[str, int] | None = None

    for line in body.splitlines():
        fence_match = FENCE_PATTERN.match(line)
        if fence_match:
            marker = fence_match.group(1)
            if open_fence is None:
                open_fence = (marker[0], len(marker))
            elif marker[0] == open_fence[0] and len(marker) >= open_fence[1]:
                open_fence = None
            continue

        if open_fence is None and line.startswith("# "):
            headings.append(line)

    return headings


def validate_record(path: Path) -> tuple[str | None, list[str]]:
    """Return a record identifier and all deterministic validation errors."""
    text = path.read_text(encoding="utf-8")
    fields, body, errors = parse_front_matter(text)

    for key in REQUIRED_SCALARS:
        value = fields.get(key)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"{key} must be a nonblank scalar")

    for key in REQUIRED_LISTS:
        value = fields.get(key)
        if (
            not isinstance(value, list)
            or not value
            or any(not isinstance(item, str) or not item.strip() for item in value)
        ):
            errors.append(f"{key} must be a nonempty list of nonblank values")

    document_id = fields.get("document_id")
    title = fields.get("title")
    date = fields.get("date")

    valid_id: str | None = None
    if isinstance(document_id, str) and document_id.strip():
        if not ADR_ID_PATTERN.fullmatch(document_id):
            errors.append(
                "document_id must use the ADR-0001 or ADR-M4-001 form"
            )
        else:
            valid_id = document_id

        expected_prefix = f"{document_id}-"
        if (
            not path.name.startswith(expected_prefix)
            or not path.name.endswith(".md")
            or len(path.name) <= len(expected_prefix) + len(".md")
        ):
            errors.append(
                f"filename must be {document_id}-<nonempty-short-title>.md"
            )

    if isinstance(date, str) and date.strip():
        try:
            parsed_date = dt.date.fromisoformat(date)
        except ValueError:
            parsed_date = None
        if parsed_date is None or parsed_date.isoformat() != date:
            errors.append("date must be a real ISO YYYY-MM-DD calendar date")

    headings = h1_headings(body)
    if len(headings) != 1:
        errors.append(f"expected exactly one H1 heading, found {len(headings)}")
    elif isinstance(document_id, str) and isinstance(title, str):
        expected_headings = {
            f"# {document_id} - {title}",
            f"# {document_id} — {title}",
        }
        if headings[0] not in expected_headings:
            errors.append(
                "H1 heading must exactly match front-matter document_id and title"
            )

    return valid_id, errors


def check_adr_register(decisions_dir: Path) -> list[str]:
    """Validate all file-backed ADRs without interpreting body references."""
    if not decisions_dir.is_dir():
        return [f"missing decisions directory: {decisions_dir}"]

    paths = sorted(
        path
        for path in decisions_dir.glob("*.md")
        if path.name != "README.md"
    )
    if not paths:
        return [f"no ADR records found under {decisions_dir}"]

    errors: list[str] = []
    identifiers: dict[str, list[str]] = {}

    for path in paths:
        document_id, record_errors = validate_record(path)
        errors.extend(f"{path.name}: {error}" for error in record_errors)
        if document_id is not None:
            identifiers.setdefault(document_id, []).append(path.name)

    for document_id, names in sorted(identifiers.items()):
        if len(names) > 1:
            errors.append(
                f"duplicate document_id {document_id}: {', '.join(sorted(names))}"
            )

    return sorted(errors)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--decisions-dir",
        type=Path,
        default=DEFAULT_DECISIONS_DIR,
        help="directory containing file-backed ADR Markdown records",
    )
    args = parser.parse_args()

    errors = check_adr_register(args.decisions_dir)
    if errors:
        print("ADR register check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    count = len(
        [
            path
            for path in args.decisions_dir.glob("*.md")
            if path.name != "README.md"
        ]
    )
    print(f"ADR register check passed for {count} records.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

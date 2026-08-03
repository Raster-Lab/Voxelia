#!/usr/bin/env python3
"""Validate RFC records, their register, and correction companions.

This check is structural only. A successful result never accepts an RFC,
applies a correction, or grants implementation authority.
"""
from __future__ import annotations

import argparse
from collections.abc import Callable
from collections import Counter
from dataclasses import dataclass
import datetime as dt
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

from check_adr_register import (
    has_meaningful_content,
    h1_headings,
    h2_sections,
    normalized_atx_heading,
    parse_front_matter,
)
from generate_requirement_index import parse_requirements


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RFCS_DIR = ROOT / "docs" / "rfcs"
DEFAULT_REQUIREMENTS_SOURCE = (
    ROOT / "docs" / "project" / "Voxelia_Requirements_Baseline_v0.1.1.md"
)
PRIMARY_ID_PATTERN = re.compile(r"RFC-(?P<number>[0-9]{4})")
COMPANION_ID_PATTERN = re.compile(
    r"RFC-(?P<parent_number>[0-9]{4})-CCD-(?P<sequence>[0-9]{2})"
)
REQUIREMENT_ID_PATTERN = re.compile(r"VOX-[A-Z0-9]+-[0-9]{3}")
FENCE_PATTERN = re.compile(r"^ {0,3}(`{3,}|~{3,})")
HEADING_PATTERN = re.compile(r"^(?P<marks>#{1,6})\s+(?P<name>.*?)\s*$")
RAW_HTML_TAG_PATTERN = re.compile(
    r"</?[A-Za-z][A-Za-z0-9-]*(?:\s[^>\n]*)?/?>"
)
LINK_PATTERN = re.compile(
    r"(?<![!\\])\[(?P<label>[^]\n]+)\]\("
    r"(?:<(?P<angle_target>[^>\n]+)>|(?P<bare_target>[^)\s]+))"
    r"(?:\s+(?:\"[^\"]*\"|'[^']*'|\([^)]*\)))?\)"
)
REFERENCE_LINK_PATTERN = re.compile(
    r"(?<![!\\])\[[^]\n]+\]\[[^]\n]*\]"
)
REFERENCE_DEFINITION_PATTERN = re.compile(r"^\[[^]\n]+\]:\s*\S", re.MULTILINE)
SETEXT_UNDERLINE_PATTERN = re.compile(r"^(?:=+|-+)\s*$", re.MULTILINE)
REGISTER_ROW_PATTERN = re.compile(
    r"^\|\s*\[`?(?P<id>RFC-[A-Z0-9-]+)`?\]"
    r"\((?P<target>[^)]+)\)\s*\|\s*(?P<status>[^|]+?)\s*"
    r"\|\s*(?P<title>[^|]+?)\s*\|\s*$"
)
NEXT_IDENTIFIER_PATTERN = re.compile(
    r"The next unallocated numeric identifier is `RFC-(?P<number>[0-9]{4})`\."
)
INVENTORY_ROW_PATTERN = re.compile(
    r"^\|\s*`(?P<id>RFC-[0-9]{4}-C[0-9]{2})`\s*\|"
)
DELTA_HEADING_PATTERN = re.compile(
    r"^###\s+(?P<id>RFC-[0-9]{4}-C[0-9]{2})\s+(?:-|—)\s+\S"
)
PRIMARY_REQUIRED_SCALARS = (
    "document_id",
    "title",
    "status",
    "date",
    "authority",
)
PRIMARY_REQUIRED_LISTS = ("authors", "affected_requirements")
COMPANION_REQUIRED_SCALARS = (
    "document_id",
    "title",
    "version",
    "status",
    "date",
    "document_type",
    "project",
    "licence",
    "language",
    "owner",
    "parent_rfc",
    "baseline_revision_set",
    "proposed_revision_set",
    "authority",
)
COMPANION_REQUIRED_LISTS = ("affected_requirements",)
COMPANION_CONSTANTS = {
    "document_type": "Controlled Correction Delta Proposal",
    "project": "Voxelia",
    "licence": "MIT",
    "language": "en-GB",
}
PRIMARY_REQUIRED_SECTION_ALIASES = (
    ("Decision status", ("Decision status",)),
    ("Summary", ("Summary",)),
    ("Motivation", ("Motivation",)),
    ("Scope", ("Scope",)),
    ("Proposed design", ("Proposed design",)),
    ("Security", ("Security",)),
    ("Performance", ("Performance",)),
    ("Validation", ("Validation",)),
    ("Compatibility", ("Compatibility", "Compatibility and migration")),
    ("Alternatives", ("Alternatives",)),
    ("Implementation plan", ("Implementation plan",)),
    ("Unresolved questions", ("Unresolved questions",)),
)
RFC_0001_COMPOSED_ADRS = ("ADR-0039", "ADR-0040", "ADR-0041")
RFC_0001_SUPPLEMENTAL_REQUIREMENTS = (
    "VOX-DOC-008",
    "VOX-DOC-009",
    "VOX-DOC-010",
)


@dataclass(frozen=True)
class RFCRecord:
    """One parsed primary RFC or controlled-correction companion."""

    path: Path
    document_id: str
    title: str
    status: str
    fields: dict[str, object]
    body: str
    is_companion: bool
    parent_rfc: str | None


@dataclass(frozen=True)
class RegisterRow:
    """One primary RFC row from the Markdown register."""

    document_id: str
    target: str
    status: str
    title: str


def lines_outside_fences(text: str) -> list[str]:
    """Return lines outside fenced code and closed/unterminated HTML comments."""
    lines: list[str] = []
    open_fence: tuple[str, int] | None = None
    in_comment = False

    for line in text.splitlines():
        if open_fence is not None:
            fence_match = FENCE_PATTERN.match(line)
            if fence_match:
                marker = fence_match.group(1)
                if (
                    marker[0] == open_fence[0]
                    and len(marker) >= open_fence[1]
                    and not line[fence_match.end() :].strip()
                ):
                    open_fence = None
            continue

        if not in_comment:
            fence_match = FENCE_PATTERN.match(line)
            if fence_match:
                marker = fence_match.group(1)
                open_fence = (marker[0], len(marker))
                continue
            if line.startswith("\t") or len(line) - len(line.lstrip(" ")) >= 4:
                continue

        visible_parts: list[str] = []
        position = 0
        while position < len(line):
            if in_comment:
                end = line.find("-->", position)
                if end == -1:
                    position = len(line)
                    break
                in_comment = False
                position = end + len("-->")
                continue

            start = line.find("<!--", position)
            if start == -1:
                visible_parts.append(line[position:])
                position = len(line)
                break
            visible_parts.append(line[position:start])
            in_comment = True
            position = start + len("<!--")

        if visible_parts:
            visible_line = "".join(visible_parts)
            indentation = len(visible_line) - len(visible_line.lstrip(" "))
            if 0 < indentation <= 3:
                visible_line = visible_line[indentation:]
            lines.append(visible_line)
        elif not in_comment:
            lines.append("")

    return lines


def inline_code_ranges(line: str) -> list[tuple[int, int]]:
    """Return CommonMark-style same-length backtick code-span ranges."""
    runs: list[tuple[int, int]] = []
    position = 0
    while position < len(line):
        start = line.find("`", position)
        if start == -1:
            break
        end = start
        while end < len(line) and line[end] == "`":
            end += 1
        runs.append((start, end))
        position = end

    ranges: list[tuple[int, int]] = []
    index = 0
    while index < len(runs):
        opening_start, opening_end = runs[index]
        opening_length = opening_end - opening_start
        closing_index = next(
            (
                candidate
                for candidate in range(index + 1, len(runs))
                if runs[candidate][1] - runs[candidate][0] == opening_length
            ),
            None,
        )
        if closing_index is None:
            index += 1
            continue
        ranges.append((opening_start, runs[closing_index][1]))
        index = closing_index + 1
    return ranges


def position_is_in_ranges(position: int, ranges: list[tuple[int, int]]) -> bool:
    """Return whether a character position lies inside any half-open range."""
    return any(start <= position < end for start, end in ranges)


def section_lines(text: str, level: int, name: str) -> list[str] | None:
    """Return lines below one exact ATX heading and before its peer/ancestor."""
    result: list[str] = []
    found = False

    for line in lines_outside_fences(text):
        heading_match = HEADING_PATTERN.match(line)
        if heading_match:
            heading_level = len(heading_match.group("marks"))
            heading_name = normalized_atx_heading(heading_match.group("name"))
            if not found and heading_level == level and heading_name == name:
                found = True
                continue
            if found and heading_level <= level:
                break
        if found:
            result.append(line)

    return result if found else None


def table_cells(line: str) -> list[str] | None:
    """Return cells for a simple leading/trailing-pipe GFM table row."""
    if not line.startswith("|") or not line.endswith("|"):
        return None
    return [cell.strip() for cell in line[1:-1].split("|")]


def table_token(cell: str) -> str:
    """Remove one common inline-code/emphasis wrapper for diagnostics."""
    value = cell.strip()
    for marker in ("`", "**", "__"):
        if value.startswith(marker) and value.endswith(marker):
            return value[len(marker) : -len(marker)]
    return value


def governed_table_rows(
    lines: list[str],
    *,
    label: str,
    header_matches: Callable[[list[str]], bool],
) -> tuple[list[str], list[str]]:
    """Return rows from exactly one live table with a valid delimiter."""
    matching_indexes: list[int] = []
    for index, line in enumerate(lines):
        cells = table_cells(line)
        if cells is not None and header_matches(cells):
            matching_indexes.append(index)
    if len(matching_indexes) != 1:
        return [], [f"must contain exactly one {label} table"]

    header_index = matching_indexes[0]
    delimiter_index = header_index + 1
    if delimiter_index >= len(lines):
        return [], [f"{label} table is missing its delimiter row"]
    delimiter = table_cells(lines[delimiter_index])
    header = table_cells(lines[header_index])
    assert header is not None
    if (
        delimiter is None
        or len(delimiter) != len(header)
        or any(re.fullmatch(r":?-{3,}:?", cell) is None for cell in delimiter)
    ):
        return [], [f"{label} table has an invalid delimiter row"]

    rows: list[str] = []
    for line in lines[delimiter_index + 1 :]:
        cells = table_cells(line)
        if cells is None:
            break
        rows.append(line)
    return rows, []


def heading_count(text: str, level: int, name: str) -> int:
    """Count one exact ATX heading outside fences and HTML comments."""
    count = 0
    for line in lines_outside_fences(text):
        match = HEADING_PATTERN.match(line)
        if match is None or len(match.group("marks")) != level:
            continue
        if normalized_atx_heading(match.group("name")) == name:
            count += 1
    return count


def markdown_links(text: str) -> list[tuple[str, str]]:
    """Return normalized Markdown link labels and raw targets outside fences."""
    links: list[tuple[str, str]] = []
    visible_text = "\n".join(lines_outside_fences(text))
    code_ranges = inline_code_ranges(visible_text)
    for match in LINK_PATTERN.finditer(visible_text):
        if position_is_in_ranges(match.start(), code_ranges):
            continue
        label = match.group("label").strip()
        if len(label) >= 2 and label.startswith("`") and label.endswith("`"):
            label = label[1:-1]
        target = match.group("angle_target") or match.group("bare_target")
        links.append((label, target))
    return links


def raw_html_errors(source: Path, text: str) -> list[str]:
    """Reject raw HTML tags so required Markdown cannot be hidden in HTML blocks."""
    visible_text = "\n".join(lines_outside_fences(text))
    code_ranges = inline_code_ranges(visible_text)
    tags = [
        match.group(0)
        for match in RAW_HTML_TAG_PATTERN.finditer(visible_text)
        if not position_is_in_ranges(match.start(), code_ranges)
    ]
    if not tags:
        return []
    return [
        f"{source.name}: raw HTML tags are unsupported in governed RFC text: "
        + ", ".join(tags[:3])
    ]


def unsupported_reference_link_errors(source: Path, text: str) -> list[str]:
    """Fail closed on reference links until the governance parser resolves them."""
    visible_text = "\n".join(lines_outside_fences(text))
    code_ranges = inline_code_ranges(visible_text)
    matches = [
        match.group(0)
        for pattern in (REFERENCE_LINK_PATTERN, REFERENCE_DEFINITION_PATTERN)
        for match in pattern.finditer(visible_text)
        if not position_is_in_ranges(match.start(), code_ranges)
    ]
    if not matches:
        return []
    return [
        f"{source.name}: reference-style Markdown links are unsupported: "
        + ", ".join(matches[:3])
    ]


def unsupported_setext_errors(source: Path, text: str) -> list[str]:
    """Reject alternate headings so the governed ATX topology is unambiguous."""
    visible_text = "\n".join(lines_outside_fences(text))
    if SETEXT_UNDERLINE_PATTERN.search(visible_text) is None:
        return []
    return [f"{source.name}: setext headings or thematic rules are unsupported"]


def file_target(target: str) -> str:
    """Return a relative link's path component without an anchor."""
    return target.split("#", maxsplit=1)[0]


def relative_link_errors(source: Path, text: str, link_root: Path) -> list[str]:
    """Validate that every local Markdown link stays in and resolves under root."""
    errors: list[str] = []
    resolved_root = link_root.resolve()
    for label, target in markdown_links(text):
        parsed = urlsplit(target)
        if parsed.scheme in {"http", "https", "mailto"}:
            continue
        if parsed.scheme or parsed.netloc:
            errors.append(f"unsupported link target for {label!r}: {target}")
            continue
        if not parsed.path:
            continue
        relative_path = Path(unquote(parsed.path))
        if relative_path.is_absolute():
            errors.append(f"absolute local link target for {label!r}: {target}")
            continue
        resolved_target = (source.parent / relative_path).resolve()
        try:
            resolved_target.relative_to(resolved_root)
        except ValueError:
            errors.append(f"local link escapes repository for {label!r}: {target}")
            continue
        if not resolved_target.is_file():
            errors.append(f"local link target does not exist for {label!r}: {target}")
    return errors


def field_errors(
    fields: dict[str, object],
    required_scalars: tuple[str, ...],
    required_lists: tuple[str, ...],
) -> list[str]:
    """Validate the scalar/list front-matter subset used by RFCs."""
    errors: list[str] = []
    for key in required_scalars:
        value = fields.get(key)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"{key} must be a nonblank scalar")
    for key in required_lists:
        value = fields.get(key)
        if (
            not isinstance(value, list)
            or not value
            or any(not isinstance(item, str) or not item.strip() for item in value)
        ):
            errors.append(f"{key} must be a nonempty list of nonblank values")
    return errors


def date_errors(fields: dict[str, object]) -> list[str]:
    """Validate an exact real ISO calendar date when one was parsed."""
    value = fields.get("date")
    if not isinstance(value, str) or not value.strip():
        return []
    try:
        parsed = dt.date.fromisoformat(value)
    except ValueError:
        parsed = None
    if parsed is None or parsed.isoformat() != value:
        return ["date must be a real ISO YYYY-MM-DD calendar date"]
    return []


def requirement_errors(
    fields: dict[str, object], known_requirements: set[str]
) -> list[str]:
    """Validate affected requirement identifiers and baseline membership."""
    values = fields.get("affected_requirements")
    if not isinstance(values, list):
        return []

    errors: list[str] = []
    identifiers = [value for value in values if isinstance(value, str)]
    malformed = sorted(
        value
        for value in identifiers
        if REQUIREMENT_ID_PATTERN.fullmatch(value) is None
    )
    if malformed:
        errors.append(f"malformed affected requirement IDs: {', '.join(malformed)}")
    duplicates = sorted(
        identifier
        for identifier, count in Counter(identifiers).items()
        if count > 1
    )
    if duplicates:
        errors.append(f"duplicate affected requirement IDs: {', '.join(duplicates)}")
    unknown = sorted(set(identifiers) - known_requirements)
    if unknown:
        errors.append(f"unknown affected requirement IDs: {', '.join(unknown)}")
    return errors


def primary_section_errors(body: str) -> list[str]:
    """Validate the RFC areas required by the scaffold specification."""
    sections = h2_sections(body)
    errors: list[str] = []
    for logical_name, aliases in PRIMARY_REQUIRED_SECTION_ALIASES:
        matches = [content for name, content in sections if name in aliases]
        if not matches:
            errors.append(f"missing required section {logical_name}")
        elif len(matches) > 1:
            errors.append(f"required section {logical_name} appears more than once")
        elif not has_meaningful_content(matches[0]):
            errors.append(
                f"required section {logical_name} must have nonblank content"
            )
    return errors


def decision_status_errors(
    body: str, status: str, *, is_companion: bool
) -> list[str]:
    """Validate the fail-closed Draft marker in the decision-status section."""
    sections = [
        content for name, content in h2_sections(body) if name == "Decision status"
    ]
    if len(sections) != 1 or not status:
        return []
    if status != "Draft":
        return [
            f"status {status!r} is unsupported; only non-authoritative Draft "
            "records can pass until an approval schema is governed"
        ]

    marker = (
        "This document is a **Draft, non-authoritative correction proposal**"
        if is_companion
        else "This RFC is a **Draft**"
    )
    first_paragraph = sections[0].strip().split("\n\n", maxsplit=1)[0]
    errors: list[str] = []
    if not first_paragraph.startswith(marker):
        errors.append(f"Decision status section must begin with {marker!r}")
    if re.search(
        r"\bdoes\s+not\b.*\bauthorise\s+product\s+source\b",
        first_paragraph,
        re.DOTALL,
    ) is None:
        errors.append(
            "Draft Decision status first paragraph must explicitly state that "
            "it does not authorise product source"
        )
    return errors


def two_column_table(
    section: list[str] | None,
) -> tuple[dict[str, list[str]], list[str]]:
    """Parse the simple key/value companion approval table."""
    values: dict[str, list[str]] = {}
    if section is None:
        return values, ["missing Approval record section"]
    rows, errors = governed_table_rows(
        section,
        label="approval record",
        header_matches=lambda cells: cells == ["Field", "Current value"],
    )
    for line in rows:
        cells = table_cells(line)
        if cells is None or len(cells) != 2:
            errors.append(f"malformed approval record row: {line}")
            continue
        values.setdefault(cells[0], []).append(cells[1])
    return values, errors


def draft_companion_errors(record: RFCRecord) -> list[str]:
    """Prevent a Draft companion from claiming effective authority."""
    if record.status != "Draft":
        return []

    errors: list[str] = []
    approval, approval_errors = two_column_table(
        section_lines(record.body, 2, "Approval record")
    )
    errors.extend(approval_errors)
    expected = {
        "Delta status": "Draft",
        "Effective revision set": "None",
        "Effective commit/date": "None",
    }
    for field, value in expected.items():
        actual = approval.get(field, [])
        if actual != [value]:
            errors.append(
                f"Draft companion approval field {field!r} must be exactly {value!r}"
            )
    return errors


def authority_errors(record: RFCRecord) -> list[str]:
    """Require explicit non-authority for every structurally admitted Draft."""
    if record.fields.get("authority") == "Non-authoritative proposal":
        return []
    return ["authority must be exactly 'Non-authoritative proposal'"]


def validate_record(
    path: Path, known_requirements: set[str]
) -> tuple[RFCRecord | None, list[str]]:
    """Parse and validate one RFC Markdown record."""
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        return None, [f"cannot read UTF-8 text: {error}"]

    fields, body, errors = parse_front_matter(text)
    body = "\n".join(lines_outside_fences(body))
    raw_id = fields.get("document_id")
    document_id = raw_id if isinstance(raw_id, str) else ""
    primary_match = PRIMARY_ID_PATTERN.fullmatch(document_id)
    companion_match = COMPANION_ID_PATTERN.fullmatch(document_id)
    if primary_match is None and companion_match is None:
        errors.append("document_id must use RFC-0001 or RFC-0001-CCD-01 form")
        return None, errors

    is_companion = companion_match is not None
    required_scalars = (
        COMPANION_REQUIRED_SCALARS if is_companion else PRIMARY_REQUIRED_SCALARS
    )
    required_lists = (
        COMPANION_REQUIRED_LISTS if is_companion else PRIMARY_REQUIRED_LISTS
    )
    errors.extend(field_errors(fields, required_scalars, required_lists))
    errors.extend(date_errors(fields))
    errors.extend(requirement_errors(fields, known_requirements))

    title_value = fields.get("title")
    status_value = fields.get("status")
    title = title_value if isinstance(title_value, str) else ""
    status = status_value if isinstance(status_value, str) else ""
    parent_value = fields.get("parent_rfc")
    parent_rfc = parent_value if isinstance(parent_value, str) else None

    if primary_match is not None:
        number = int(primary_match.group("number"))
        if number == 0:
            errors.append("primary RFC number must be greater than zero")
        expected_prefix = f"{document_id}-"
        if (
            not path.name.startswith(expected_prefix)
            or not path.name.endswith(".md")
            or len(path.name) <= len(expected_prefix) + len(".md")
        ):
            errors.append(f"filename must be {document_id}-<nonempty-short-title>.md")
        errors.extend(primary_section_errors(body))
    else:
        assert companion_match is not None
        parent_number = int(companion_match.group("parent_number"))
        sequence = int(companion_match.group("sequence"))
        if parent_number == 0 or sequence == 0:
            errors.append(
                "companion parent and sequence numbers must be greater than zero"
            )
        expected_parent = f"RFC-{companion_match.group('parent_number')}"
        if parent_rfc != expected_parent:
            errors.append(f"parent_rfc must match companion prefix {expected_parent}")
        expected_prefix = f"{expected_parent}-"
        if (
            not path.name.startswith(expected_prefix)
            or not path.name.endswith(".md")
            or len(path.name) <= len(expected_prefix) + len(".md")
        ):
            errors.append(
                "companion filename must be "
                f"{expected_parent}-<nonempty-short-title>.md"
            )
        for key, expected in COMPANION_CONSTANTS.items():
            value = fields.get(key)
            if isinstance(value, str) and value.strip() and value != expected:
                errors.append(f"{key} must be exactly {expected!r}")

    headings = h1_headings(body)
    if len(headings) != 1:
        errors.append(f"expected exactly one H1 heading, found {len(headings)}")
    elif document_id and title:
        expected_headings = {
            f"# {document_id} - {title}",
            f"# {document_id} — {title}",
        }
        if headings[0] not in expected_headings:
            errors.append(
                "H1 heading must exactly match front-matter document_id and title"
            )

    decision_sections = [
        content for name, content in h2_sections(body) if name == "Decision status"
    ]
    if not decision_sections:
        errors.append("missing required section Decision status")
    elif len(decision_sections) > 1:
        errors.append("required section Decision status appears more than once")
    elif not has_meaningful_content(decision_sections[0]):
        errors.append("required section Decision status must have nonblank content")
    errors.extend(
        decision_status_errors(body, status, is_companion=is_companion)
    )

    record = RFCRecord(
        path=path,
        document_id=document_id,
        title=title,
        status=status,
        fields=fields,
        body=body,
        is_companion=is_companion,
        parent_rfc=parent_rfc,
    )
    errors.extend(authority_errors(record))
    if is_companion:
        errors.extend(draft_companion_errors(record))
    return record, errors


def parse_register(readme: str) -> tuple[list[RegisterRow], list[str]]:
    """Parse all RFC-looking rows in the primary register table."""
    rows: list[RegisterRow] = []
    table_rows, errors = governed_table_rows(
        lines_outside_fences(readme),
        label="primary RFC register",
        header_matches=lambda cells: cells == ["ID", "Status", "Proposal"],
    )
    for line in table_rows:
        match = REGISTER_ROW_PATTERN.fullmatch(line)
        if match is None:
            errors.append(f"malformed primary RFC register row: {line}")
            continue
        rows.append(
            RegisterRow(
                document_id=match.group("id"),
                target=match.group("target").strip(),
                status=match.group("status").strip(),
                title=match.group("title").strip(),
            )
        )
    return rows, errors


def register_errors(
    rfcs_dir: Path,
    readme: str,
    primary: dict[str, RFCRecord],
    companions: dict[str, RFCRecord],
) -> list[str]:
    """Validate primary rows, companion links, and next allocation."""
    errors: list[str] = []
    rows, table_errors = parse_register(readme)
    errors.extend(table_errors)
    rows_by_id: dict[str, list[RegisterRow]] = {}
    for row in rows:
        rows_by_id.setdefault(row.document_id, []).append(row)

    for document_id, matching_rows in sorted(rows_by_id.items()):
        if document_id not in primary:
            errors.append(f"primary register has orphan or companion row {document_id}")
        if len(matching_rows) > 1:
            errors.append(f"primary register has duplicate rows for {document_id}")

    for document_id, record in sorted(primary.items()):
        matching_rows = rows_by_id.get(document_id, [])
        if not matching_rows:
            errors.append(f"primary register is missing {document_id}")
            continue
        row = matching_rows[0]
        if row.target != record.path.name:
            errors.append(
                f"primary register target for {document_id} must be "
                f"{record.path.name!r}"
            )
        if row.status != record.status:
            errors.append(
                f"primary register status for {document_id} must be {record.status!r}"
            )
        if row.title != record.title:
            errors.append(
                f"primary register title for {document_id} must be {record.title!r}"
            )
        target_path = rfcs_dir / file_target(row.target)
        if not target_path.is_file():
            errors.append(f"primary register target does not exist: {row.target}")

    visible_readme = "\n".join(lines_outside_fences(readme))
    code_ranges = inline_code_ranges(visible_readme)
    next_matches = [
        match
        for match in NEXT_IDENTIFIER_PATTERN.finditer(visible_readme)
        if not position_is_in_ranges(match.start(), code_ranges)
    ]
    if len(next_matches) != 1:
        errors.append(
            "README must state exactly one next unallocated numeric RFC identifier"
        )
    numbers = sorted(
        int(match.group("number"))
        for identifier in primary
        if (match := PRIMARY_ID_PATTERN.fullmatch(identifier)) is not None
    )
    if numbers:
        expected_numbers = list(range(1, max(numbers) + 1))
        if numbers != expected_numbers:
            missing = sorted(set(expected_numbers) - set(numbers))
            errors.append(
                "primary RFC allocation has gaps: "
                + ", ".join(f"RFC-{number:04d}" for number in missing)
            )
        expected_next = max(numbers) + 1
        if expected_next > 9999:
            errors.append("primary RFC numeric identifier space is exhausted")
        elif len(next_matches) == 1:
            stated_next = int(next_matches[0].group("number"))
            if stated_next != expected_next:
                errors.append(
                    f"next unallocated identifier must be RFC-{expected_next:04d}"
                )

    readme_links = markdown_links(readme)
    for document_id, record in sorted(companions.items()):
        matches = [
            (label, target)
            for label, target in readme_links
            if label == document_id
        ]
        if len(matches) != 1 or matches[0][1] != record.path.name:
            errors.append(
                f"README must link companion {document_id} to "
                f"{record.path.name} exactly once"
            )
        if not (rfcs_dir / record.path.name).is_file():
            errors.append(f"companion README target does not exist: {record.path.name}")
    return errors


def reciprocal_link_errors(
    primary: dict[str, RFCRecord], companions: dict[str, RFCRecord]
) -> list[str]:
    """Validate companion parents and reciprocal Markdown links."""
    errors: list[str] = []
    for document_id, companion in sorted(companions.items()):
        parent_id = companion.parent_rfc
        parent = primary.get(parent_id or "")
        if parent is None:
            errors.append(
                f"{document_id} references missing primary parent {parent_id!r}"
            )
            continue

        parent_links = markdown_links(parent.body)
        if not any(
            label.startswith(document_id) and file_target(target) == companion.path.name
            for label, target in parent_links
        ):
            errors.append(
                f"{parent.document_id} must link companion {document_id} "
                f"to {companion.path.name}"
            )

        companion_links = markdown_links(companion.body)
        if not any(
            label.startswith(parent.document_id)
            and file_target(target) == parent.path.name
            for label, target in companion_links
        ):
            errors.append(
                f"{document_id} must link parent {parent.document_id} "
                f"to {parent.path.name}"
            )
        inventory_target = f"{parent.path.name}#controlled-correction-inventory"
        if not any(target == inventory_target for _, target in companion_links):
            errors.append(
                f"{document_id} must link the parent correction inventory at "
                f"{inventory_target}"
            )

        parent_requirements = parent.fields.get("affected_requirements")
        companion_requirements = companion.fields.get("affected_requirements")
        if parent_requirements != companion_requirements:
            errors.append(
                f"{document_id} affected_requirements must exactly match "
                f"{parent.document_id}"
            )
    return errors


def crosswalk_ids(
    record: RFCRecord, heading: str, companion: bool
) -> tuple[list[str] | None, list[str], list[str]]:
    """Extract canonical IDs and correction-like malformed tokens."""
    level = 2 if companion else 3
    lines = section_lines(record.body, level, heading)
    if lines is None:
        return None, [], []

    table_errors: list[str] = []
    if not companion:
        lines, table_errors = governed_table_rows(
            lines,
            label="controlled correction inventory",
            header_matches=lambda cells: len(cells) == 4 and cells[0] == "ID",
        )

    parent_id = record.parent_rfc if companion else record.document_id
    prefix = f"{parent_id}-C"
    identifiers: list[str] = []
    malformed: list[str] = []
    for line in lines:
        if companion:
            heading_match = HEADING_PATTERN.match(line)
            if heading_match is None:
                continue
            canonical_match = DELTA_HEADING_PATTERN.match(line)
            if canonical_match is None:
                malformed.append(
                    normalized_atx_heading(heading_match.group("name"))
                )
                continue
            identifier = canonical_match.group("id")
            if not identifier.startswith(prefix):
                malformed.append(identifier)
                continue
            identifiers.append(identifier)
            continue

        cells = table_cells(line)
        canonical_match = INVENTORY_ROW_PATTERN.match(line)
        if cells is None or len(cells) != 4 or canonical_match is None:
            malformed.append(table_token(cells[0]) if cells else line.strip())
            continue
        identifier = canonical_match.group("id")
        if not identifier.startswith(prefix):
            malformed.append(identifier)
            continue
        identifiers.append(identifier)
    return identifiers, malformed, table_errors


def crosswalk_errors(
    primary: dict[str, RFCRecord], companions: dict[str, RFCRecord]
) -> list[str]:
    """Validate ordered correction inventories and the exact C01-C24 set."""
    errors: list[str] = []
    by_parent: dict[str, list[RFCRecord]] = {}
    for companion in companions.values():
        if companion.parent_rfc is not None:
            by_parent.setdefault(companion.parent_rfc, []).append(companion)

    if "RFC-0001" in primary and "RFC-0001" not in by_parent:
        parent = primary["RFC-0001"]
        parent_count = heading_count(
            parent.body, 3, "Controlled correction inventory"
        )
        if parent_count != 1:
            errors.append(
                "RFC-0001 must contain exactly one Controlled correction inventory"
            )
        parent_ids, malformed, table_errors = crosswalk_ids(
            parent, "Controlled correction inventory", False
        )
        errors.extend(f"RFC-0001 {error}" for error in table_errors)
        if malformed:
            errors.append(
                "RFC-0001 has malformed correction row IDs: "
                + ", ".join(malformed)
            )
        expected = [f"RFC-0001-C{number:02d}" for number in range(1, 25)]
        if parent_ids != expected:
            errors.append(
                "RFC-0001 controlled correction inventory must be exactly "
                "C01 through C24"
            )

    for parent_id, linked_companions in sorted(by_parent.items()):
        if len(linked_companions) > 1:
            errors.append(
                "multiple controlled-correction companions for "
                f"{parent_id} are unsupported"
            )
            continue
        parent = primary.get(parent_id)
        if parent is None:
            continue
        companion = linked_companions[0]
        parent_heading_count = heading_count(
            parent.body, 3, "Controlled correction inventory"
        )
        companion_heading_count = heading_count(
            companion.body, 2, "Proposed exact deltas"
        )
        if parent_heading_count != 1:
            errors.append(
                f"{parent_id} must contain exactly one Controlled correction inventory"
            )
        if companion_heading_count != 1:
            errors.append(
                f"{companion.document_id} must contain exactly one "
                "Proposed exact deltas"
            )

        parent_ids, malformed_parent, parent_table_errors = crosswalk_ids(
            parent, "Controlled correction inventory", False
        )
        companion_ids, malformed_companion, companion_table_errors = crosswalk_ids(
            companion, "Proposed exact deltas", True
        )
        errors.extend(f"{parent_id} {error}" for error in parent_table_errors)
        errors.extend(
            f"{companion.document_id} {error}" for error in companion_table_errors
        )
        if parent_ids is None:
            errors.append(f"{parent_id} is missing Controlled correction inventory")
            continue
        if companion_ids is None:
            errors.append(f"{companion.document_id} is missing Proposed exact deltas")
            continue
        if malformed_parent:
            errors.append(
                f"{parent_id} has malformed correction row IDs: "
                + ", ".join(malformed_parent)
            )
        if malformed_companion:
            errors.append(
                f"{companion.document_id} has malformed correction heading IDs: "
                + ", ".join(malformed_companion)
            )
        if parent_ids != companion_ids:
            errors.append(
                f"{companion.document_id} correction IDs must exactly match the "
                f"ordered {parent_id} inventory"
            )

        if parent_id == "RFC-0001":
            expected = [f"RFC-0001-C{number:02d}" for number in range(1, 25)]
            if parent_ids != expected:
                errors.append(
                    "RFC-0001 controlled correction inventory must be exactly "
                    "C01 through C24"
                )
            if companion_ids != expected:
                errors.append(
                    "RFC-0001-CCD-01 proposed deltas must be exactly C01 through C24"
                )
    return errors


def required_companion_errors(
    primary: dict[str, RFCRecord], companions: dict[str, RFCRecord]
) -> list[str]:
    """Freeze the currently allocated RFC-0001 correction companion."""
    if "RFC-0001" not in primary:
        return []
    linked = sorted(
        record.document_id
        for record in companions.values()
        if record.parent_rfc == "RFC-0001"
    )
    if linked == ["RFC-0001-CCD-01"]:
        return []
    rendered = ", ".join(linked) if linked else "none"
    return [
        "RFC-0001 must have exactly the allocated companion "
        f"RFC-0001-CCD-01; found {rendered}"
    ]


def load_known_requirements(path: Path) -> tuple[set[str], list[str]]:
    """Load normative requirement IDs used by RFC traceability."""
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        return set(), [f"cannot read requirements source {path}: {error}"]
    identifiers = [record["id"] for record in parse_requirements(text)]
    if not identifiers:
        return set(), [f"requirements source contains no normative rows: {path}"]
    duplicates = sorted(
        identifier
        for identifier, count in Counter(identifiers).items()
        if count > 1
    )
    errors = []
    if duplicates:
        errors.append(
            "requirements source contains duplicate IDs: " + ", ".join(duplicates)
        )
    return set(identifiers), errors


def composed_adr_requirements(
    decisions_dir: Path, identifiers: tuple[str, ...]
) -> tuple[set[str], list[str]]:
    """Load the affected-requirement union from exact composed ADR records."""
    requirements: set[str] = set()
    errors: list[str] = []
    for identifier in identifiers:
        paths = sorted(decisions_dir.glob(f"{identifier}-*.md"))
        if len(paths) != 1:
            errors.append(
                f"expected exactly one {identifier} record under {decisions_dir}, "
                f"found {len(paths)}"
            )
            continue
        try:
            text = paths[0].read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            errors.append(f"cannot read composed {identifier}: {error}")
            continue
        fields, _, parse_errors = parse_front_matter(text)
        errors.extend(f"{identifier}: {error}" for error in parse_errors)
        if fields.get("document_id") != identifier:
            errors.append(f"{paths[0].name}: document_id must be {identifier}")
        affected = fields.get("affected_requirements")
        if not isinstance(affected, list) or not affected:
            errors.append(f"{identifier}: affected_requirements must be nonempty")
            continue
        if not all(isinstance(value, str) for value in affected):
            errors.append(f"{identifier}: affected_requirements must contain strings")
            continue
        requirements.update(affected)
    return requirements, errors


def composition_requirement_errors(
    primary: dict[str, RFCRecord],
    companions: dict[str, RFCRecord],
    decisions_dir: Path,
) -> list[str]:
    """Validate RFC-0001's declared ADR union plus correction documentation IDs."""
    parent = primary.get("RFC-0001")
    if parent is None:
        return []

    errors: list[str] = []
    expected_metadata = {
        "composed_adrs": list(RFC_0001_COMPOSED_ADRS),
        "supplemental_affected_requirements": list(
            RFC_0001_SUPPLEMENTAL_REQUIREMENTS
        ),
    }
    related = [
        record
        for record in companions.values()
        if record.parent_rfc == parent.document_id
    ]
    for record in [parent, *related]:
        for field, expected in expected_metadata.items():
            if record.fields.get(field) != expected:
                errors.append(
                    f"{record.document_id} {field} must be exactly "
                    + ", ".join(expected)
                )

    adr_requirements, adr_errors = composed_adr_requirements(
        decisions_dir, RFC_0001_COMPOSED_ADRS
    )
    errors.extend(adr_errors)
    if adr_errors:
        return errors

    expected_requirements = adr_requirements | set(
        RFC_0001_SUPPLEMENTAL_REQUIREMENTS
    )
    for record in [parent, *related]:
        affected = record.fields.get("affected_requirements")
        if not isinstance(affected, list):
            continue
        actual = {value for value in affected if isinstance(value, str)}
        if actual != expected_requirements:
            missing = sorted(expected_requirements - actual)
            unexpected = sorted(actual - expected_requirements)
            details: list[str] = []
            if missing:
                details.append("missing " + ", ".join(missing))
            if unexpected:
                details.append("unexpected " + ", ".join(unexpected))
            errors.append(
                f"{record.document_id} affected_requirements must equal the "
                "composed ADR union plus supplemental requirements: "
                + "; ".join(details)
            )
    return errors


def check_rfc_register(
    rfcs_dir: Path,
    requirements_source: Path,
    decisions_dir: Path,
    link_root: Path | None,
) -> tuple[list[str], int, int, Counter[str]]:
    """Return deterministic RFC governance errors and a structural summary."""
    errors: list[str] = []
    known_requirements, source_errors = load_known_requirements(requirements_source)
    errors.extend(source_errors)
    if not rfcs_dir.is_dir():
        return [f"missing RFC directory: {rfcs_dir}", *errors], 0, 0, Counter()

    effective_link_root = link_root
    if effective_link_root is None:
        effective_link_root = (
            ROOT
            if rfcs_dir.resolve() == DEFAULT_RFCS_DIR.resolve()
            else rfcs_dir.resolve()
        )

    readme_path = rfcs_dir / "README.md"
    try:
        readme = readme_path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        readme = ""
        errors.append(f"cannot read RFC register {readme_path}: {error}")
    errors.extend(raw_html_errors(readme_path, readme))
    errors.extend(unsupported_reference_link_errors(readme_path, readme))
    errors.extend(unsupported_setext_errors(readme_path, readme))
    errors.extend(relative_link_errors(readme_path, readme, effective_link_root))

    paths = sorted(path for path in rfcs_dir.glob("*.md") if path.name != "README.md")
    if not paths:
        errors.append(f"no RFC records found under {rfcs_dir}")

    records: list[RFCRecord] = []
    for path in paths:
        record, record_errors = validate_record(path, known_requirements)
        errors.extend(f"{path.name}: {error}" for error in record_errors)
        if record is not None:
            records.append(record)
            errors.extend(raw_html_errors(path, record.body))
            errors.extend(unsupported_reference_link_errors(path, record.body))
            errors.extend(unsupported_setext_errors(path, record.body))
            errors.extend(relative_link_errors(path, record.body, effective_link_root))

    identifiers: dict[str, list[str]] = {}
    for record in records:
        identifiers.setdefault(record.document_id, []).append(record.path.name)
    for document_id, names in sorted(identifiers.items()):
        if len(names) > 1:
            errors.append(
                f"duplicate document_id {document_id}: {', '.join(sorted(names))}"
            )

    primary = {
        record.document_id: record for record in records if not record.is_companion
    }
    companions = {
        record.document_id: record for record in records if record.is_companion
    }
    errors.extend(register_errors(rfcs_dir, readme, primary, companions))
    errors.extend(reciprocal_link_errors(primary, companions))
    errors.extend(required_companion_errors(primary, companions))
    errors.extend(crosswalk_errors(primary, companions))
    errors.extend(composition_requirement_errors(primary, companions, decisions_dir))
    statuses = Counter(record.status for record in records if record.status)
    return sorted(set(errors)), len(primary), len(companions), statuses


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--rfcs-dir",
        type=Path,
        default=DEFAULT_RFCS_DIR,
        help="directory containing RFC Markdown records and README register",
    )
    parser.add_argument(
        "--requirements-source",
        type=Path,
        default=DEFAULT_REQUIREMENTS_SOURCE,
        help="controlled Requirements Baseline used to validate traceability IDs",
    )
    parser.add_argument(
        "--decisions-dir",
        type=Path,
        default=ROOT / "docs" / "architecture" / "decisions",
        help="directory containing composed ADR records",
    )
    parser.add_argument(
        "--link-root",
        type=Path,
        help="root that local RFC links must remain under (inferred by default)",
    )
    arguments = parser.parse_args()

    errors, primary_count, companion_count, statuses = check_rfc_register(
        arguments.rfcs_dir,
        arguments.requirements_source,
        arguments.decisions_dir,
        arguments.link_root,
    )
    if errors:
        print("RFC governance check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    status_summary = ", ".join(
        f"{status}: {count}" for status, count in sorted(statuses.items())
    )
    print(
        "RFC governance check passed for "
        f"{primary_count} primary and {companion_count} companion records "
        f"({status_summary}); structural validation confers no authority."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

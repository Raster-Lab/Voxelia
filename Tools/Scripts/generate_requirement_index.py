#!/usr/bin/env python3
"""Validate requirement summaries and generate their traceability index."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs/project/Voxelia_Requirements_Baseline_v0.1.1.md"
OUTPUT = ROOT / "docs/releases/v0.1.1/Requirements_Traceability_Index.json"
SCHEMA_VERSION = "0.1.1"

ROW_PATTERN = re.compile(
    r"^\| `(?P<id>VOX-[A-Z0-9]+-\d{3})` \| "
    r"(?P<text>.*?) \| "
    r"(?P<priority>P[0-2]) \| "
    r"(?P<verification>.*?) \| "
    r"(?P<target>M\d+) \|$",
    re.MULTILINE,
)
CATEGORY_PATTERN = re.compile(
    r"^\| `(?P<category>[A-Z0-9]+)` \| .*? \| "
    r"(?P<total>\d+) \| (?P<P0>\d+) \| (?P<P1>\d+) \| (?P<P2>\d+) \|$",
    re.MULTILINE,
)
COUNT_PATTERN = re.compile(r"^\| (?P<key>P[0-2]|M\d+) \| (?P<count>\d+) \|$", re.MULTILINE)
TOTAL_PATTERN = re.compile(r"^\| \*\*Total\*\* \| \*\*(?P<count>\d+)\*\* \|$", re.MULTILINE)
DECLARED_COUNT_PATTERNS = (
    (
        "front matter requirement count",
        re.compile(r"^requirement_count: (?P<count>\d+)\s*$", re.MULTILINE),
    ),
    (
        "document-control requirement count",
        re.compile(r"^\| Requirement count \| (?P<count>\d+) \|$", re.MULTILINE),
    ),
)


def section(text: str, heading: str, next_heading: str) -> str:
    start = text.find(heading)
    end = text.find(next_heading, start + len(heading)) if start >= 0 else -1
    if start < 0 or end < 0:
        return ""
    return text[start:end]


def parse_requirements(text: str) -> list[dict[str, str]]:
    return [match.groupdict() for match in ROW_PATTERN.finditer(text)]


def parse_category_summary(text: str) -> dict[str, tuple[int, int, int, int]]:
    summary = section(
        text,
        "### 5.1 Requirements by category",
        "### 5.2 Requirements by priority",
    )
    return {
        match["category"]: (
            int(match["total"]),
            int(match["P0"]),
            int(match["P1"]),
            int(match["P2"]),
        )
        for match in CATEGORY_PATTERN.finditer(summary)
    }


def parse_count_summary(text: str, heading: str, next_heading: str) -> dict[str, int]:
    summary = section(text, heading, next_heading)
    return {
        match["key"]: int(match["count"])
        for match in COUNT_PATTERN.finditer(summary)
    }


def actual_category_counts(
    requirements: list[dict[str, str]],
) -> dict[str, tuple[int, int, int, int]]:
    counts: dict[str, Counter[str]] = defaultdict(Counter)
    for requirement in requirements:
        category = requirement["id"].split("-")[1]
        counts[category]["total"] += 1
        counts[category][requirement["priority"]] += 1
    return {
        category: (
            values["total"],
            values["P0"],
            values["P1"],
            values["P2"],
        )
        for category, values in counts.items()
    }


def compare_counts(
    label: str,
    stated: dict[str, object],
    actual: dict[str, object],
) -> list[str]:
    errors: list[str] = []
    for key in sorted(actual.keys() - stated.keys()):
        errors.append(f"{label} summary is missing {key}")
    for key in sorted(stated.keys() - actual.keys()):
        errors.append(f"{label} summary has unexpected {key}")
    for key in sorted(actual.keys() & stated.keys()):
        if stated[key] != actual[key]:
            errors.append(
                f"{label} {key} states {stated[key]!r}, "
                f"but requirement rows yield {actual[key]!r}"
            )
    return errors


def duplicate_summary_errors(label: str, keys: list[str]) -> list[str]:
    duplicates = sorted(key for key, count in Counter(keys).items() if count > 1)
    if not duplicates:
        return []
    return [f"{label} summary contains duplicate keys: {', '.join(duplicates)}"]


def validate_baseline(text: str, requirements: list[dict[str, str]]) -> list[str]:
    errors: list[str] = []
    malformed_lines = [
        str(line_number)
        for line_number, line in enumerate(text.splitlines(), start=1)
        if line.startswith("| `VOX-") and ROW_PATTERN.fullmatch(line) is None
    ]
    if malformed_lines:
        errors.append(
            "malformed normative requirement rows at lines: "
            + ", ".join(malformed_lines)
        )
    if not requirements:
        errors.append("no normative requirement rows were parsed")
        return errors

    identifiers = [requirement["id"] for requirement in requirements]
    duplicates = sorted(
        identifier for identifier, count in Counter(identifiers).items() if count > 1
    )
    if duplicates:
        errors.append(f"duplicate requirement identifiers: {', '.join(duplicates)}")

    for label, pattern in DECLARED_COUNT_PATTERNS:
        matches = list(pattern.finditer(text))
        if not matches:
            errors.append(f"{label} is missing")
            continue
        if len(matches) > 1:
            errors.append(f"{label} appears more than once")
        for match in matches:
            if int(match["count"]) != len(requirements):
                errors.append(
                    f"{label} states {match['count']}, "
                    f"but requirement rows yield {len(requirements)}"
                )

    category_section = section(
        text,
        "### 5.1 Requirements by category",
        "### 5.2 Requirements by priority",
    )
    category_keys = [
        match["category"] for match in CATEGORY_PATTERN.finditer(category_section)
    ]
    errors.extend(duplicate_summary_errors("category", category_keys))
    errors.extend(
        compare_counts(
            "category",
            parse_category_summary(text),
            actual_category_counts(requirements),
        )
    )

    stated_priorities = parse_count_summary(
        text,
        "### 5.2 Requirements by priority",
        "### 5.3 Requirements by first target milestone",
    )
    priority_section = section(
        text,
        "### 5.2 Requirements by priority",
        "### 5.3 Requirements by first target milestone",
    )
    priority_keys = [
        match["key"] for match in COUNT_PATTERN.finditer(priority_section)
    ]
    errors.extend(duplicate_summary_errors("priority", priority_keys))
    actual_priorities = dict(Counter(row["priority"] for row in requirements))
    errors.extend(compare_counts("priority", stated_priorities, actual_priorities))

    total_match = TOTAL_PATTERN.search(priority_section)
    if total_match is None:
        errors.append("priority summary is missing its total")
    elif int(total_match["count"]) != len(requirements):
        errors.append(
            f"priority total states {total_match['count']}, "
            f"but requirement rows yield {len(requirements)}"
        )

    stated_milestones = parse_count_summary(
        text,
        "### 5.3 Requirements by first target milestone",
        "## 6. Normative requirements",
    )
    milestone_section = section(
        text,
        "### 5.3 Requirements by first target milestone",
        "## 6. Normative requirements",
    )
    milestone_keys = [
        match["key"] for match in COUNT_PATTERN.finditer(milestone_section)
    ]
    errors.extend(duplicate_summary_errors("milestone", milestone_keys))
    actual_milestones = dict(Counter(row["target"] for row in requirements))
    errors.extend(compare_counts("milestone", stated_milestones, actual_milestones))
    return errors


def render_index(requirements: list[dict[str, str]]) -> str:
    document = {"schemaVersion": SCHEMA_VERSION, "requirements": requirements}
    return json.dumps(document, indent=2) + "\n"


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate summaries and require the existing index to be current",
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    try:
        text = arguments.source.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        print(f"Requirement baseline check failed: {error}")
        return 1

    requirements = parse_requirements(text)
    errors = validate_baseline(text, requirements)
    rendered = render_index(requirements)

    if arguments.check:
        try:
            existing = arguments.output.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            errors.append(f"cannot read requirement index: {error}")
        else:
            if existing != rendered:
                errors.append("requirement index is out of date")

    if errors:
        print("Requirement baseline check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    if arguments.check:
        print(
            f"Requirement summaries and {len(requirements)}-record index check passed."
        )
        return 0

    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(rendered, encoding="utf-8")
    try:
        output_label = arguments.output.resolve().relative_to(ROOT)
    except ValueError:
        output_label = arguments.output
    print(
        f"Wrote {len(requirements)} requirements to "
        f"{output_label}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

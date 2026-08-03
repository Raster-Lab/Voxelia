from __future__ import annotations

import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CHECKER = ROOT / "Tools/Scripts/check_rfc_register.py"
PARENT_NAME = "RFC-0001-example-proposal.md"
COMPANION_NAME = "RFC-0001-controlled-correction-delta.md"
CORRECTION_IDS = tuple(f"RFC-0001-C{number:02d}" for number in range(1, 25))


def repository_rfc_requirements() -> tuple[str, ...]:
    path = (
        ROOT
        / "docs/rfcs/RFC-0001-storage-contract-and-logical-data-model-composition.md"
    )
    text = path.read_text(encoding="utf-8")
    front_matter = text.split("\n---\n", maxsplit=1)[0]
    affected = front_matter.split("\naffected_requirements:\n", maxsplit=1)[1]
    return tuple(
        line.removeprefix('  - "').removesuffix('"')
        for line in affected.splitlines()
        if line.startswith('  - "VOX-') and line.endswith('"')
    )


DEFAULT_REQUIREMENTS = repository_rfc_requirements()


def correction_rows(ids: tuple[str, ...] = CORRECTION_IDS) -> str:
    rows = ["| ID | Drift | Correction | Gates |", "|---|---|---|---|"]
    rows.extend(
        f"| `{identifier}` | Drift. | Correct. | `A` |" for identifier in ids
    )
    return "\n".join(rows)


def correction_headings(ids: tuple[str, ...] = CORRECTION_IDS) -> str:
    return "\n\n".join(
        f"### {identifier} — Correction {identifier[-2:]}\n\nExact delta."
        for identifier in ids
    )


def parent_text(
    *,
    document_id: str = "RFC-0001",
    status: str = "Draft",
    requirements: tuple[str, ...] = DEFAULT_REQUIREMENTS,
    rows: tuple[str, ...] = CORRECTION_IDS,
) -> str:
    requirement_lines = "\n".join(f'  - "{value}"' for value in requirements)
    return f'''---
document_id: "{document_id}"
title: "Example proposal"
status: "{status}"
date: "2026-08-03"
authority: "Non-authoritative proposal"
composed_adrs:
  - "ADR-0039"
  - "ADR-0040"
  - "ADR-0041"
supplemental_affected_requirements:
  - "VOX-DOC-008"
  - "VOX-DOC-009"
  - "VOX-DOC-010"
authors:
  - "Voxelia Project"
affected_requirements:
{requirement_lines}
---

# {document_id} - Example proposal

## Decision status

This RFC is a **{status}**. It does not authorise product source.

## Summary

Summary content.

## Motivation

Motivation content.

## Scope

Scope content.

## Proposed design

Design content.

## Security

Security content.

## Performance

Performance content.

## Validation

Validation content.

## Compatibility and migration

Compatibility content.

### Controlled correction inventory

{correction_rows(rows)}

## Alternatives

Alternatives content.

## Implementation plan

Implementation content.

## Unresolved questions

Questions content.

## References

- [`RFC-0001-CCD-01`]({COMPANION_NAME})
'''


def companion_text(
    *,
    document_id: str = "RFC-0001-CCD-01",
    parent_rfc: str = "RFC-0001",
    status: str = "Draft",
    authority: str = "Non-authoritative proposal",
    requirements: tuple[str, ...] = DEFAULT_REQUIREMENTS,
    headings: tuple[str, ...] = CORRECTION_IDS,
    delta_status: str = "Draft",
    effective_revision: str = "None",
    effective_commit: str = "None",
) -> str:
    requirement_lines = "\n".join(f'  - "{value}"' for value in requirements)
    return f'''---
document_id: "{document_id}"
title: "Example controlled-correction delta"
version: "0.1"
status: "{status}"
date: "2026-08-03"
document_type: "Controlled Correction Delta Proposal"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
owner: "Voxelia Project"
parent_rfc: "{parent_rfc}"
baseline_revision_set: "0.1.1"
proposed_revision_set: "0.1.2"
authority: "{authority}"
composed_adrs:
  - "ADR-0039"
  - "ADR-0040"
  - "ADR-0041"
supplemental_affected_requirements:
  - "VOX-DOC-008"
  - "VOX-DOC-009"
  - "VOX-DOC-010"
affected_requirements:
{requirement_lines}
---

# {document_id} - Example controlled-correction delta

## Decision status

This document is a **{status}, non-authoritative correction proposal**. It does
not authorise product source.

## Approval record

| Field | Current value |
|---|---|
| Delta status | {delta_status} |
| Effective revision set | {effective_revision} |
| Effective commit/date | {effective_commit} |

## Proposed exact deltas

{correction_headings(headings)}

## References

- [{parent_rfc} - Example proposal]({PARENT_NAME}#controlled-correction-inventory)
'''


def readme_text(
    *,
    next_identifier: str = "RFC-0002",
    status: str = "Draft",
    title: str = "Example proposal",
    parent_target: str = PARENT_NAME,
    companion_target: str = COMPANION_NAME,
    extra_rows: str = "",
) -> str:
    return f'''# Requests for Comments

The next unallocated numeric identifier is `{next_identifier}`.

[`RFC-0001-CCD-01`]({companion_target}) is the Draft companion.

| ID | Status | Proposal |
|---|---|---|
| [RFC-0001]({parent_target}) | {status} | {title} |
{extra_rows}'''


def valid_documents() -> dict[str, str]:
    return {
        "README.md": readme_text(),
        PARENT_NAME: parent_text(),
        COMPANION_NAME: companion_text(),
    }


class RFCRegisterTests(unittest.TestCase):
    def run_checker(
        self, documents: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            rfcs_dir = Path(directory)
            for name, text in documents.items():
                (rfcs_dir / name).write_text(text, encoding="utf-8")
            return subprocess.run(
                ["python3", str(CHECKER), "--rfcs-dir", str(rfcs_dir)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def assert_rejected(self, documents: dict[str, str], message: str) -> None:
        result = self.run_checker(documents)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(message, result.stdout)

    def test_accepts_minimal_primary_companion_and_register_fixture(self) -> None:
        result = self.run_checker(valid_documents())

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("1 primary and 1 companion", result.stdout)
        self.assertIn("Draft: 2", result.stdout)
        self.assertIn("structural validation confers no authority", result.stdout)

    def test_repository_records_pass(self) -> None:
        result = subprocess.run(
            ["python3", str(CHECKER)],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        identifiers = []
        for path in (ROOT / "docs/rfcs").glob("*.md"):
            if path.name == "README.md":
                continue
            match = re.search(
                r'^document_id: "(?P<id>RFC-[A-Z0-9-]+)"$',
                path.read_text(encoding="utf-8"),
                re.MULTILINE,
            )
            self.assertIsNotNone(match, path)
            identifiers.append(match.group("id"))
        primary_count = sum("-CCD-" not in identifier for identifier in identifiers)
        companion_count = len(identifiers) - primary_count
        self.assertIn(
            f"{primary_count} primary and {companion_count} companion",
            result.stdout,
        )
        self.assertIn("structural validation confers no authority", result.stdout)

    def test_rejects_duplicate_and_malformed_identifiers(self) -> None:
        duplicate = valid_documents()
        duplicate["RFC-0001-second.md"] = parent_text()
        self.assert_rejected(duplicate, "duplicate document_id RFC-0001")

        malformed = valid_documents()
        malformed[COMPANION_NAME] = companion_text(document_id="RFC-0001-CCD-1")
        self.assert_rejected(
            malformed,
            "document_id must use RFC-0001 or RFC-0001-CCD-01 form",
        )

        zero = valid_documents()
        zero[PARENT_NAME] = parent_text(document_id="RFC-0000")
        self.assert_rejected(zero, "primary RFC number must be greater than zero")

    def test_rejects_invalid_metadata_date_filename_and_heading(self) -> None:
        cases = {
            "metadata": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        'authors:\n  - "Voxelia Project"\n', ""
                    ),
                ),
                "authors must be a nonempty list",
            ),
            "date": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace("2026-08-03", "2026-02-30"),
                ),
                "real ISO YYYY-MM-DD",
            ),
            "filename": (
                lambda docs: docs.__setitem__("proposal.md", docs.pop(PARENT_NAME)),
                "filename must be RFC-0001-<nonempty-short-title>.md",
            ),
            "heading": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        "# RFC-0001 - Example proposal",
                        "# RFC-0001 - Wrong title",
                    ),
                ),
                "H1 heading must exactly match",
            ),
        }
        for label, (mutate, message) in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                mutate(documents)
                self.assert_rejected(documents, message)

    def test_rejects_missing_or_mismatched_parent(self) -> None:
        mismatch = valid_documents()
        mismatch[COMPANION_NAME] = companion_text(parent_rfc="RFC-0002")
        self.assert_rejected(
            mismatch, "parent_rfc must match companion prefix RFC-0001"
        )

        missing = valid_documents()
        del missing[PARENT_NAME]
        self.assert_rejected(missing, "references missing primary parent")

    def test_requires_exact_allocated_rfc0001_companion(self) -> None:
        missing = valid_documents()
        del missing[COMPANION_NAME]
        missing["README.md"] = missing["README.md"].replace(
            f"[`RFC-0001-CCD-01`]({COMPANION_NAME}) is the Draft companion.\n\n",
            "",
        )
        missing[PARENT_NAME] = missing[PARENT_NAME].replace(
            f"- [`RFC-0001-CCD-01`]({COMPANION_NAME})\n",
            "",
        )
        self.assert_rejected(
            missing,
            "must have exactly the allocated companion RFC-0001-CCD-01",
        )

        wrong_sequence = valid_documents()
        wrong_sequence[PARENT_NAME] = parent_text(rows=(CORRECTION_IDS[0],))
        wrong_sequence[COMPANION_NAME] = companion_text(
            document_id="RFC-0001-CCD-02",
            headings=(CORRECTION_IDS[0],),
        )
        for name in ("README.md", PARENT_NAME):
            wrong_sequence[name] = wrong_sequence[name].replace(
                "RFC-0001-CCD-01", "RFC-0001-CCD-02"
            )
        self.assert_rejected(
            wrong_sequence,
            "must have exactly the allocated companion RFC-0001-CCD-01",
        )

    def test_rejects_primary_register_drift_and_companion_rows(self) -> None:
        cases = {
            "status": (readme_text(status="Accepted"), "register status"),
            "title": (readme_text(title="Wrong title"), "register title"),
            "target": (readme_text(parent_target="missing.md"), "register target"),
            "companion row": (
                readme_text(
                    extra_rows=(
                        f"| [RFC-0001-CCD-01]({COMPANION_NAME}) "
                        "| Draft | Companion |\n"
                    )
                ),
                "orphan or companion row RFC-0001-CCD-01",
            ),
        }
        for label, (readme, message) in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                documents["README.md"] = readme
                self.assert_rejected(documents, message)

    def test_rejects_live_one_space_indented_duplicates(self) -> None:
        duplicate_heading = valid_documents()
        duplicate_heading[PARENT_NAME] += "\n # RFC-0001 - Example proposal\n"
        self.assert_rejected(
            duplicate_heading, "expected exactly one H1 heading, found 2"
        )

        duplicate_row = valid_documents()
        live_row = f"| [RFC-0001]({PARENT_NAME}) | Draft | Example proposal |"
        duplicate_row["README.md"] = duplicate_row["README.md"].replace(
            live_row,
            live_row
            + f"\n | [RFC-0001]({PARENT_NAME}) | Draft | Example proposal |",
        )
        self.assert_rejected(
            duplicate_row, "primary register has duplicate rows for RFC-0001"
        )

    def test_requires_live_register_and_inventory_table_structure(self) -> None:
        cases = {
            "register header": (
                lambda docs: docs.__setitem__(
                    "README.md",
                    docs["README.md"].replace(
                        "| ID | Status | Proposal |\n|---|---|---|\n", ""
                    ),
                ),
                "must contain exactly one primary RFC register table",
            ),
            "inventory header": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        "| ID | Drift | Correction | Gates |\n"
                        "|---|---|---|---|\n",
                        "",
                    ),
                ),
                "must contain exactly one controlled correction inventory table",
            ),
            "malformed register row": (
                lambda docs: docs.__setitem__(
                    "README.md",
                    docs["README.md"].replace(
                        f"| [RFC-0001]({PARENT_NAME}) | Draft | Example proposal |",
                        f"| [RFC-0001]({PARENT_NAME}) | Draft | Example proposal |\n"
                        "| RFC-9999 | Accepted | Orphan proposal |",
                    ),
                ),
                "malformed primary RFC register row",
            ),
            "malformed inventory row": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        correction_rows(),
                        correction_rows()
                        + "\n| **RFC-0001-C25** | Drift. | Fix. | `A` |",
                    ),
                ),
                "malformed correction row IDs: RFC-0001-C25",
            ),
            "non-ID inventory row": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        correction_rows(),
                        correction_rows() + "\n| Not an ID | Drift. | Fix. | `A` |",
                    ),
                ),
                "malformed correction row IDs: Not an ID",
            ),
        }
        for label, (mutate, message) in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                mutate(documents)
                self.assert_rejected(documents, message)

    def test_ignores_commented_out_register_rows(self) -> None:
        live_row = f"| [RFC-0001]({PARENT_NAME}) | Draft | Example proposal |"
        replacements = {
            "closed": f"<!--\n{live_row}\n-->",
            "unterminated": f"<!--\n{live_row}",
        }
        for label, replacement in replacements.items():
            with self.subTest(label=label):
                documents = valid_documents()
                documents["README.md"] = documents["README.md"].replace(
                    live_row, replacement
                )
                self.assert_rejected(
                    documents, "primary register is missing RFC-0001"
                )

    def test_ignores_commented_out_h1_and_decision_status(self) -> None:
        documents = valid_documents()
        visible = (
            "# RFC-0001 - Example proposal\n\n"
            "## Decision status\n\n"
            "This RFC is a **Draft**. It does not authorise product source."
        )
        documents[PARENT_NAME] = documents[PARENT_NAME].replace(
            visible, f"<!--\n{visible}\n-->"
        )

        self.assert_rejected(documents, "expected exactly one H1 heading, found 0")

    def test_rejects_missing_reciprocal_or_readme_companion_links(self) -> None:
        cases = {
            "README": (
                lambda docs: docs.__setitem__(
                    "README.md",
                    docs["README.md"].replace(
                        f"[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                        "RFC companion",
                    ),
                ),
                "README must link companion",
            ),
            "duplicate README": (
                lambda docs: docs.__setitem__(
                    "README.md",
                    docs["README.md"]
                    + f"\n[`RFC-0001-CCD-01`](wrong-{COMPANION_NAME})\n",
                ),
                "README must link companion",
            ),
            "escaped README": (
                lambda docs: docs.__setitem__(
                    "README.md",
                    docs["README.md"].replace(
                        f"[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                        f"\\[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                    ),
                ),
                "README must link companion",
            ),
            "inline-code README": (
                lambda docs: docs.__setitem__(
                    "README.md",
                    docs["README.md"].replace(
                        f"[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                        f"``[`RFC-0001-CCD-01`]({COMPANION_NAME})``",
                    ),
                ),
                "README must link companion",
            ),
            "image README": (
                lambda docs: docs.__setitem__(
                    "README.md",
                    docs["README.md"].replace(
                        f"[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                        f"![`RFC-0001-CCD-01`]({COMPANION_NAME})",
                    ),
                ),
                "README must link companion",
            ),
            "parent": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        f"[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                        "Companion pending.",
                    ),
                ),
                "RFC-0001 must link companion",
            ),
            "escaped parent": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        f"[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                        f"\\[`RFC-0001-CCD-01`]({COMPANION_NAME})",
                    ),
                ),
                "RFC-0001 must link companion",
            ),
            "companion": (
                lambda docs: docs.__setitem__(
                    COMPANION_NAME,
                    docs[COMPANION_NAME].replace(
                        "[RFC-0001 - Example proposal]"
                        f"({PARENT_NAME}#controlled-correction-inventory)",
                        "Parent pending.",
                    ),
                ),
                "must link parent RFC-0001",
            ),
            "inline-code companion": (
                lambda docs: docs.__setitem__(
                    COMPANION_NAME,
                    docs[COMPANION_NAME].replace(
                        "[RFC-0001 - Example proposal]"
                        f"({PARENT_NAME}#controlled-correction-inventory)",
                        "`[RFC-0001 - Example proposal]"
                        f"({PARENT_NAME}#controlled-correction-inventory)`",
                    ),
                ),
                "must link parent RFC-0001",
            ),
            "multiline-code companion": (
                lambda docs: docs.__setitem__(
                    COMPANION_NAME,
                    docs[COMPANION_NAME].replace(
                        "[RFC-0001 - Example proposal]"
                        f"({PARENT_NAME}#controlled-correction-inventory)",
                        "``\n[ RFC-0001 - Example proposal]"
                        f"({PARENT_NAME}#controlled-correction-inventory)\n``",
                    ),
                ),
                "must link parent RFC-0001",
            ),
        }
        for label, (mutate, message) in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                mutate(documents)
                self.assert_rejected(documents, message)

    def test_rejects_raw_html_and_reference_style_link_hiding(self) -> None:
        link = (
            "[RFC-0001 - Example proposal]"
            f"({PARENT_NAME}#controlled-correction-inventory)"
        )
        cases = {
            "raw HTML": (f"<div>\n{link}\n</div>", "raw HTML tags are unsupported"),
            "reference": (
                "[RFC-0001 - Example proposal][parent]\n"
                f"[parent]: {PARENT_NAME}#controlled-correction-inventory",
                "reference-style Markdown links are unsupported",
            ),
        }
        for label, (replacement, message) in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                documents[COMPANION_NAME] = documents[COMPANION_NAME].replace(
                    link, replacement
                )
                self.assert_rejected(documents, message)

    def test_rejects_broken_relative_file_link(self) -> None:
        links = {
            "bare": "[Missing evidence](missing-evidence.md)",
            "angle": "[Missing evidence](<missing evidence.md>)",
        }
        for label, link in links.items():
            with self.subTest(label=label):
                documents = valid_documents()
                documents[PARENT_NAME] += f"\n- {link}\n"
                self.assert_rejected(
                    documents, "local link target does not exist"
                )

    def test_rejects_stale_next_identifier(self) -> None:
        documents = valid_documents()
        documents["README.md"] = readme_text(next_identifier="RFC-0003")

        self.assert_rejected(
            documents, "next unallocated identifier must be RFC-0002"
        )

    def test_rejects_missing_extra_duplicate_or_reordered_crosswalk_ids(self) -> None:
        variants = {
            "missing": CORRECTION_IDS[:-1],
            "extra": (*CORRECTION_IDS, "RFC-0001-C25"),
            "duplicate": (*CORRECTION_IDS, CORRECTION_IDS[-1]),
            "reordered": (
                *CORRECTION_IDS[:1],
                CORRECTION_IDS[2],
                CORRECTION_IDS[1],
                *CORRECTION_IDS[3:],
            ),
        }
        for label, identifiers in variants.items():
            with self.subTest(label=label):
                documents = valid_documents()
                documents[COMPANION_NAME] = companion_text(headings=identifiers)
                self.assert_rejected(
                    documents,
                    "RFC-0001-CCD-01 proposed deltas must be exactly C01 through C24",
                )

    def test_rejects_parent_crosswalk_drift(self) -> None:
        documents = valid_documents()
        documents[PARENT_NAME] = parent_text(rows=CORRECTION_IDS[:-1])

        self.assert_rejected(
            documents,
            "RFC-0001 controlled correction inventory must be exactly C01 through C24",
        )

    def test_rejects_crosswalk_comment_malformed_and_duplicate_cases(
        self,
    ) -> None:
        cases = {
            "commented companion headings": (
                lambda docs: docs.__setitem__(
                    COMPANION_NAME,
                    docs[COMPANION_NAME].replace(
                        correction_headings(),
                        f"<!--\n{correction_headings()}\n-->",
                    ),
                ),
                "proposed deltas must be exactly C01 through C24",
            ),
            "malformed parent row": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        correction_rows(),
                        correction_rows() + "\n| `RFC-0001-C1` | Drift. | Fix. | `A` |",
                    ),
                ),
                "malformed correction row IDs: RFC-0001-C1",
            ),
            "malformed companion heading": (
                lambda docs: docs.__setitem__(
                    COMPANION_NAME,
                    docs[COMPANION_NAME].replace(
                        correction_headings(),
                        correction_headings()
                        + "\n\n### RFC-0001-C1 — Invalid\n\nInvalid delta.",
                    ),
                ),
                "malformed correction heading IDs: RFC-0001-C1",
            ),
            "foreign parent row": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        correction_rows(),
                        correction_rows()
                        + "\n | `RFC-0002-C01` | Drift. | Fix. | `A` |",
                    ),
                ),
                "malformed correction row IDs: RFC-0002-C01",
            ),
            "foreign companion heading": (
                lambda docs: docs.__setitem__(
                    COMPANION_NAME,
                    docs[COMPANION_NAME].replace(
                        correction_headings(),
                        correction_headings()
                        + "\n\n ### RFC-0002-C01 — Foreign\n\nForeign delta.",
                    ),
                ),
                "malformed correction heading IDs: RFC-0002-C01",
            ),
            "duplicate parent section": (
                lambda docs: docs.__setitem__(
                    PARENT_NAME,
                    docs[PARENT_NAME].replace(
                        "## Alternatives",
                        "### Controlled correction inventory\n\n"
                        "| ID | Drift | Correction | Gates |\n"
                        "|---|---|---|---|\n"
                        "| `RFC-0001-C25` | Drift. | Fix. | `A` |\n\n"
                        "## Alternatives",
                    ),
                ),
                "must contain exactly one Controlled correction inventory",
            ),
            "duplicate companion section": (
                lambda docs: docs.__setitem__(
                    COMPANION_NAME,
                    docs[COMPANION_NAME].replace(
                        "## References",
                        "## Proposed exact deltas\n\n"
                        "### RFC-0001-C25 — Extra\n\nExtra.\n\n"
                        "## References",
                    ),
                ),
                "must contain exactly one Proposed exact deltas",
            ),
        }
        for label, (mutate, message) in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                mutate(documents)
                self.assert_rejected(documents, message)

    def test_ignores_correction_ids_in_fenced_examples(self) -> None:
        documents = valid_documents()
        documents[COMPANION_NAME] = documents[COMPANION_NAME].replace(
            "## References",
            "```markdown\n### RFC-0001-C25 — Example only\n```\n\n## References",
        )

        result = self.run_checker(documents)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_comment_marker_inside_fence_does_not_hide_live_heading(self) -> None:
        documents = valid_documents()
        documents[PARENT_NAME] += (
            "\n```markdown\n<!--\n```\n"
            "# RFC-9999 - Visible extra heading\n"
            "-->\n```\n"
        )

        self.assert_rejected(documents, "expected exactly one H1 heading, found 2")

    def test_rejects_live_setext_heading_forms(self) -> None:
        documents = valid_documents()
        documents[PARENT_NAME] += (
            "\nDuplicate live H1\n=================\n"
            "Decision status\n----------------\n"
            "Accepted and authoritative.\n"
        )

        self.assert_rejected(documents, "setext headings or thematic rules")

    def test_rejects_requirement_mismatch_duplicates_and_unknown_ids(self) -> None:
        cases = {
            "mismatch": (
                DEFAULT_REQUIREMENTS,
                DEFAULT_REQUIREMENTS[:-1],
                "affected_requirements must exactly match",
            ),
            "duplicate": (
                (*DEFAULT_REQUIREMENTS, DEFAULT_REQUIREMENTS[0]),
                (*DEFAULT_REQUIREMENTS, DEFAULT_REQUIREMENTS[0]),
                "duplicate affected requirement IDs",
            ),
            "unknown": (
                (*DEFAULT_REQUIREMENTS, "VOX-NOT-999"),
                (*DEFAULT_REQUIREMENTS, "VOX-NOT-999"),
                "unknown affected requirement IDs",
            ),
        }
        for label, values in cases.items():
            with self.subTest(label=label):
                parent_requirements, companion_requirements, message = values
                documents = valid_documents()
                documents[PARENT_NAME] = parent_text(
                    requirements=parent_requirements
                )
                documents[COMPANION_NAME] = companion_text(
                    requirements=companion_requirements
                )
                self.assert_rejected(documents, message)

    def test_rejects_matching_records_with_incomplete_adr_union(self) -> None:
        documents = valid_documents()
        incomplete = DEFAULT_REQUIREMENTS[:-1]
        documents[PARENT_NAME] = parent_text(requirements=incomplete)
        documents[COMPANION_NAME] = companion_text(requirements=incomplete)

        self.assert_rejected(
            documents,
            "affected_requirements must equal the composed ADR union",
        )

    def test_rejects_draft_companion_effectiveness_claims(self) -> None:
        cases = {
            "authority": (
                {"authority": "Accepted authority"},
                "authority must be exactly 'Non-authoritative proposal'",
            ),
            "delta status": (
                {"delta_status": "Accepted"},
                "approval field 'Delta status'",
            ),
            "revision": (
                {"effective_revision": "0.1.2"},
                "approval field 'Effective revision set'",
            ),
            "commit": (
                {"effective_commit": "abc123 / 2026-08-03"},
                "approval field 'Effective commit/date'",
            ),
        }
        for label, (arguments, message) in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                documents[COMPANION_NAME] = companion_text(**arguments)
                self.assert_rejected(documents, message)

    def test_requires_live_companion_approval_table(self) -> None:
        documents = valid_documents()
        documents[COMPANION_NAME] = documents[COMPANION_NAME].replace(
            "| Field | Current value |\n|---|---|\n",
            "",
        )

        self.assert_rejected(
            documents, "must contain exactly one approval record table"
        )

    def test_rejects_unsupported_acceptance_or_status_spelling(self) -> None:
        cases = {
            "Accepted": "Accepted",
            "lowercase Draft": "draft",
        }
        for label, status in cases.items():
            with self.subTest(label=label):
                documents = valid_documents()
                documents[PARENT_NAME] = parent_text(status=status)
                documents["README.md"] = readme_text(status=status)
                self.assert_rejected(documents, "only non-authoritative Draft")

    def test_rejects_primary_authority_drift(self) -> None:
        documents = valid_documents()
        documents[PARENT_NAME] = documents[PARENT_NAME].replace(
            'authority: "Non-authoritative proposal"',
            'authority: "Accepted authority"',
        )

        self.assert_rejected(
            documents, "authority must be exactly 'Non-authoritative proposal'"
        )

    def test_rejects_decision_status_drift(self) -> None:
        documents = valid_documents()
        documents[PARENT_NAME] = documents[PARENT_NAME].replace(
            "This RFC is a **Draft**.",
            "This RFC is awaiting review.",
        )

        self.assert_rejected(
            documents,
            "Decision status section must begin with 'This RFC is a **Draft**'",
        )


if __name__ == "__main__":
    unittest.main()

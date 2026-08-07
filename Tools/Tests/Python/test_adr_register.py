from __future__ import annotations

import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CHECKER = ROOT / "Tools/Scripts/check_adr_register.py"
LOGICAL_SECTIONS = (
    "Context",
    "Decision",
    "Alternatives",
    "Consequences",
    "Affected modules",
    "Validation impact",
    "Migration",
    "Supersession",
)
DEFAULT_HEADINGS = {
    "Context": "Context",
    "Decision": "Decision",
    "Alternatives": "Alternatives considered",
    "Consequences": "Consequences",
    "Affected modules": "Affected modules",
    "Validation impact": "Validation impact",
    "Migration": "Migration",
    "Supersession": "Supersession",
}


def required_sections(
    *,
    headings: dict[str, str] | None = None,
    omitted: set[str] | None = None,
    empty: set[str] | None = None,
    contents: dict[str, str] | None = None,
    order: tuple[str, ...] = LOGICAL_SECTIONS,
) -> str:
    headings = {**DEFAULT_HEADINGS, **(headings or {})}
    omitted = omitted or set()
    empty = empty or set()
    contents = contents or {}
    parts: list[str] = []

    for logical_name in order:
        if logical_name in omitted:
            continue
        content = contents.get(logical_name, f"{logical_name} content.")
        if logical_name in empty:
            content = ""
        parts.append(f"## {headings[logical_name]}\n\n{content}")

    return "\n\n".join(parts)


def adr_text(
    document_id: str = "ADR-0042",
    title: str = "Example decision",
    *,
    separator: str = "-",
    body: str | None = None,
    extra_body: str = "",
) -> str:
    body = required_sections() if body is None else body
    return f'''---
document_id: "{document_id}"
title: "{title}"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REP-004"
---

# {document_id} {separator} {title}

{body}

{extra_body}'''


class ADRRegisterTests(unittest.TestCase):
    def run_checker(
        self, documents: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            decisions = Path(directory)
            for name, text in documents.items():
                (decisions / name).write_text(text, encoding="utf-8")
            self.write_register(decisions, documents)
            return subprocess.run(
                ["python3", str(CHECKER), "--decisions-dir", str(decisions)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def write_register(self, decisions: Path, documents: dict[str, str]) -> None:
        """Write the register the checker's index validation requires.

        `ADR-0282` added `check_readme_index`, which requires every `ADR-NNNN`
        file to have a linking row and the next-unallocated counter to be
        correct. These fixtures are synthetic directories of records, so they
        need a matching register or the index check fails them for a reason that
        has nothing to do with what they test.

        Generating it here rather than hand-writing one per test means the
        fixtures also exercise the index check, and cannot drift from it.
        """
        identifiers = sorted(
            int(name[4:8])
            for name in documents
            if re.fullmatch(r"ADR-\d{4}-.*\.md", name)
        )
        rows = "".join(
            f"| [ADR-{number:04d}]"
            f"({next(n for n in documents if n.startswith(f'ADR-{number:04d}'))}) "
            "| Accepted | Fixture |\n"
            for number in identifiers
        )
        following = (identifiers[-1] + 1) if identifiers else 21
        (decisions / "README.md").write_text(
            "# Architecture Decision Records\n\n"
            f"The next unallocated numeric identifier is `ADR-{following:04d}`.\n\n"
            "| ID | Status | Decision |\n|---|---|---|\n" + rows,
            encoding="utf-8",
        )

    def test_accepts_numeric_and_milestone_identifiers(self) -> None:
        result = self.run_checker(
            {
                "ADR-0042-example-decision.md": adr_text(),
                "ADR-M4-001-milestone-decision.md": adr_text(
                    "ADR-M4-001",
                    "Milestone decision",
                    separator="—",
                    body=required_sections(
                        headings={
                            "Alternatives": "Alternatives",
                            "Migration": "Migration impact",
                            "Supersession": "Supersession links",
                        },
                        order=tuple(reversed(LOGICAL_SECTIONS)),
                    ),
                    extra_body="## Security impact\n\nNo impact.",
                ),
            }
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("passed for 2 records", result.stdout)

    def test_repository_records_pass(self) -> None:
        result = subprocess.run(
            ["python3", str(CHECKER)],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        expected_count = len(
            [
                path
                for path in (ROOT / "docs/architecture/decisions").glob("*.md")
                if path.name != "README.md"
            ]
        )
        self.assertIn(f"passed for {expected_count} records", result.stdout)

    def test_rejects_missing_and_empty_required_fields(self) -> None:
        base = adr_text()
        cases = {
            "missing status": base.replace('status: "Proposed"\n', ""),
            "missing date": base.replace('date: "2026-08-02"\n', ""),
            "empty title": base.replace(
                'title: "Example decision"',
                'title: ""',
            ),
            "empty owners": base.replace(
                'owners:\n  - "Voxelia Project"',
                "owners:",
            ),
            "empty requirements": base.replace(
                'affected_requirements:\n  - "VOX-REP-004"',
                "affected_requirements:",
            ),
        }

        for label, text in cases.items():
            with self.subTest(label=label):
                result = self.run_checker({"ADR-0042-example-decision.md": text})
                self.assertNotEqual(result.returncode, 0)

    def test_rejects_duplicate_front_matter_key(self) -> None:
        text = adr_text().replace(
            'status: "Proposed"',
            'status: "Proposed"\nstatus: "Accepted"',
        )

        result = self.run_checker({"ADR-0042-example-decision.md": text})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("duplicate field status", result.stdout)

    def test_rejects_invalid_date(self) -> None:
        text = adr_text().replace("2026-08-02", "2026-02-30")

        result = self.run_checker({"ADR-0042-example-decision.md": text})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("real ISO YYYY-MM-DD", result.stdout)

    def test_rejects_unsupported_identifier_forms(self) -> None:
        for document_id in (
            "ADR-m4-001",
            "ADR-M4",
            "ADR-1",
            "ADR-0042-EXTRA",
            "ADR-FOO",
        ):
            with self.subTest(document_id=document_id):
                result = self.run_checker(
                    {
                        f"{document_id}-example-decision.md": adr_text(
                            document_id,
                        )
                    }
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("ADR-0001 or ADR-M4-001 form", result.stdout)

    def test_rejects_missing_filename_slug_and_identifier_mismatch(self) -> None:
        for name in ("ADR-0042.md", "ADR-0043-example-decision.md"):
            with self.subTest(name=name):
                result = self.run_checker({name: adr_text()})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("filename must be", result.stdout)

    def test_rejects_markdown_file_with_non_adr_filename(self) -> None:
        result = self.run_checker({"decision.md": adr_text()})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("filename must be", result.stdout)

    def test_rejects_heading_identifier_or_title_mismatch(self) -> None:
        cases = {
            "identifier": adr_text().replace(
                "# ADR-0042 - Example decision",
                "# ADR-0043 - Example decision",
            ),
            "title": adr_text().replace(
                "# ADR-0042 - Example decision",
                "# ADR-0042 - Different decision",
            ),
        }

        for label, text in cases.items():
            with self.subTest(label=label):
                result = self.run_checker({"ADR-0042-example-decision.md": text})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("H1 heading must exactly match", result.stdout)

    def test_rejects_duplicate_file_backed_identifier(self) -> None:
        result = self.run_checker(
            {
                "ADR-0042-first.md": adr_text(),
                "ADR-0042-second.md": adr_text(),
            }
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("duplicate document_id ADR-0042", result.stdout)

    def test_ignores_identifier_mentions_in_body_text(self) -> None:
        result = self.run_checker(
            {
                "ADR-M4-001-example-decision.md": adr_text(
                    "ADR-M4-001",
                    extra_body=(
                        "This discusses ADR-0001 and proposed ADR-0025.\n"
                    ),
                )
            }
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ignores_h1_examples_inside_fenced_code(self) -> None:
        result = self.run_checker(
            {
                "ADR-0042-example-decision.md": adr_text(
                    extra_body=(
                        "```markdown\n"
                        "# ADR-9999 - Embedded example\n"
                        "```\n"
                    )
                )
            }
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_rejects_missing_front_matter_delimiter(self) -> None:
        text = adr_text().replace("\n---\n\n#", "\n#", 1)

        result = self.run_checker({"ADR-0042-example-decision.md": text})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing closing front matter", result.stdout)

    def test_rejects_malformed_front_matter_line(self) -> None:
        text = adr_text().replace(
            'status: "Proposed"',
            'status: "Proposed"\n  malformed yaml',
        )

        result = self.run_checker({"ADR-0042-example-decision.md": text})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsupported or malformed syntax", result.stdout)

    def test_rejects_each_missing_required_section(self) -> None:
        for logical_name in LOGICAL_SECTIONS:
            with self.subTest(logical_name=logical_name):
                result = self.run_checker(
                    {
                        "ADR-0042-example-decision.md": adr_text(
                            body=required_sections(omitted={logical_name})
                        )
                    }
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(
                    f"missing required section {logical_name}",
                    result.stdout,
                )

    def test_rejects_each_empty_required_section(self) -> None:
        for logical_name in LOGICAL_SECTIONS:
            with self.subTest(logical_name=logical_name):
                result = self.run_checker(
                    {
                        "ADR-0042-example-decision.md": adr_text(
                            body=required_sections(empty={logical_name})
                        )
                    }
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(
                    f"required section {logical_name} must have nonblank content",
                    result.stdout,
                )

    def test_rejects_duplicate_section_and_mixed_aliases(self) -> None:
        cases = {
            "same heading": (
                required_sections() + "\n\n## Context\n\nDuplicate content."
            ),
            "mixed aliases": (
                required_sections() + "\n\n## Alternatives\n\nDuplicate content."
            ),
        }

        for label, body in cases.items():
            with self.subTest(label=label):
                result = self.run_checker(
                    {
                        "ADR-0042-example-decision.md": adr_text(body=body)
                    }
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("appears more than once", result.stdout)

    def test_fenced_section_does_not_satisfy_requirement(self) -> None:
        body = (
            "```markdown\n"
            "## Context\n\n"
            "Embedded example.\n"
            "```\n\n"
            + required_sections(omitted={"Context"})
        )

        result = self.run_checker(
            {"ADR-0042-example-decision.md": adr_text(body=body)}
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing required section Context", result.stdout)

    def test_fence_with_trailing_text_does_not_close_code_block(self) -> None:
        body = (
            "```markdown\n"
            "```not-a-close\n"
            "## Context\n\n"
            "Embedded example.\n"
            "```\n\n"
            + required_sections(omitted={"Context"})
        )

        result = self.run_checker(
            {"ADR-0042-example-decision.md": adr_text(body=body)}
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing required section Context", result.stdout)

    def test_rejects_placeholder_only_section_content(self) -> None:
        placeholders = {
            "HTML comment": "<!-- TODO: complete this section -->",
            "empty fence": "```swift\n```",
        }

        for label, placeholder in placeholders.items():
            with self.subTest(label=label):
                result = self.run_checker(
                    {
                        "ADR-0042-example-decision.md": adr_text(
                            body=required_sections(
                                contents={"Context": placeholder}
                            )
                        )
                    }
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(
                    "required section Context must have nonblank content",
                    result.stdout,
                )

    def test_accepts_commonmark_closing_hashes_on_h2_headings(self) -> None:
        headings = {
            logical_name: f"{DEFAULT_HEADINGS[logical_name]} ##"
            for logical_name in LOGICAL_SECTIONS
        }

        result = self.run_checker(
            {
                "ADR-0042-example-decision.md": adr_text(
                    body=required_sections(headings=headings)
                )
            }
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CHECKER = ROOT / "Tools/Scripts/check_adr_register.py"


def adr_text(
    document_id: str = "ADR-0042",
    title: str = "Example decision",
    *,
    separator: str = "-",
    body: str = "",
) -> str:
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

{body}'''


class ADRRegisterTests(unittest.TestCase):
    def run_checker(
        self, documents: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            decisions = Path(directory)
            for name, text in documents.items():
                (decisions / name).write_text(text, encoding="utf-8")
            return subprocess.run(
                ["python3", str(CHECKER), "--decisions-dir", str(decisions)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def test_accepts_numeric_and_milestone_identifiers(self) -> None:
        result = self.run_checker(
            {
                "ADR-0042-example-decision.md": adr_text(),
                "ADR-M4-001-milestone-decision.md": adr_text(
                    "ADR-M4-001",
                    "Milestone decision",
                    separator="—",
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
        self.assertIn("passed for 5 records", result.stdout)

    def test_rejects_missing_and_empty_required_fields(self) -> None:
        base = adr_text()
        cases = {
            "missing status": base.replace('status: "Proposed"\n', ""),
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
                    body="This discusses ADR-0001 and proposed ADR-0025.\n",
                )
            }
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ignores_h1_examples_inside_fenced_code(self) -> None:
        result = self.run_checker(
            {
                "ADR-0042-example-decision.md": adr_text(
                    body=(
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


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "Tools/Scripts/generate_requirement_index.py"
BASELINE = ROOT / "docs/project/Voxelia_Requirements_Baseline_v0.1.1.md"
INDEX = ROOT / "docs/releases/v0.1.1/Requirements_Traceability_Index.json"

SPEC = importlib.util.spec_from_file_location("generate_requirement_index", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
GENERATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GENERATOR)


class RequirementIndexTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = BASELINE.read_text(encoding="utf-8")
        cls.requirements = GENERATOR.parse_requirements(cls.text)

    def test_baseline_summaries_match_normative_rows(self) -> None:
        self.assertEqual(len(self.requirements), 486)
        self.assertEqual(GENERATOR.validate_baseline(self.text, self.requirements), [])

    def test_detects_milestone_count_drift(self) -> None:
        stale = self.text.replace("| M0 | 46 |", "| M0 | 45 |", 1).replace(
            "| M3 | 37 |",
            "| M3 | 38 |",
            1,
        )
        self.assertNotEqual(stale, self.text)

        errors = GENERATOR.validate_baseline(
            stale,
            GENERATOR.parse_requirements(stale),
        )

        self.assertTrue(any("milestone M0" in error for error in errors), errors)
        self.assertTrue(any("milestone M3" in error for error in errors), errors)

    def test_detects_priority_count_drift(self) -> None:
        stale = self.text.replace("| P0 | 398 |", "| P0 | 397 |", 1)
        self.assertNotEqual(stale, self.text)

        errors = GENERATOR.validate_baseline(
            stale,
            GENERATOR.parse_requirements(stale),
        )

        self.assertTrue(any("priority P0" in error for error in errors), errors)

    def test_detects_category_count_drift(self) -> None:
        stale = self.text.replace(
            "| `GOV` | Project governance and scope control | 10 | 7 | 3 | 0 |",
            "| `GOV` | Project governance and scope control | 9 | 7 | 2 | 0 |",
            1,
        )
        self.assertNotEqual(stale, self.text)

        errors = GENERATOR.validate_baseline(
            stale,
            GENERATOR.parse_requirements(stale),
        )

        self.assertTrue(any("category GOV" in error for error in errors), errors)

    def test_detects_malformed_normative_row(self) -> None:
        match = GENERATOR.ROW_PATTERN.search(self.text)
        self.assertIsNotNone(match)
        assert match is not None
        malformed_row = match.group(0).replace(" | P0 |", " | PX |", 1)
        stale = self.text.replace(match.group(0), malformed_row, 1)

        errors = GENERATOR.validate_baseline(
            stale,
            GENERATOR.parse_requirements(stale),
        )

        self.assertTrue(any("malformed normative" in error for error in errors), errors)

    def test_detects_declared_total_drift(self) -> None:
        stale = self.text.replace("requirement_count: 486", "requirement_count: 485", 1)
        self.assertNotEqual(stale, self.text)

        errors = GENERATOR.validate_baseline(
            stale,
            GENERATOR.parse_requirements(stale),
        )

        self.assertTrue(
            any("front matter requirement count" in error for error in errors),
            errors,
        )

    def test_detects_duplicate_summary_key(self) -> None:
        stale = self.text.replace("| M1 | 53 |", "| M1 | 53 |\n| M1 | 53 |", 1)
        self.assertNotEqual(stale, self.text)

        errors = GENERATOR.validate_baseline(
            stale,
            GENERATOR.parse_requirements(stale),
        )

        self.assertTrue(
            any("milestone summary contains duplicate keys" in error for error in errors),
            errors,
        )

    def test_detects_duplicate_identifier(self) -> None:
        requirements = [*self.requirements, dict(self.requirements[0])]

        errors = GENERATOR.validate_baseline(self.text, requirements)

        self.assertTrue(
            any("duplicate requirement identifiers" in error for error in errors),
            errors,
        )

    def test_checked_in_index_is_current(self) -> None:
        self.assertEqual(
            INDEX.read_text(encoding="utf-8"),
            GENERATOR.render_index(self.requirements),
        )


if __name__ == "__main__":
    unittest.main()

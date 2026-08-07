from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from Tools.Scripts.generate_sbom import (
    DEFAULT_OUTPUT,
    PROFILE_VERSION,
    ROOT,
    SBOMError,
    build_sbom,
    json_schema_errors,
    sha256,
    validation_errors,
)


class SBOMGenerationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = build_sbom()

    def test_generated_document_satisfies_release_profile(self) -> None:
        document = self.document

        self.assertEqual(validation_errors(document), [])
        self.assertEqual(document["specVersion"], PROFILE_VERSION)
        self.assertEqual(document["metadata"]["version"], "1.0.0")
        # Counted against `Package.swift` rather than pinned to literals. The
        # literals here read 12, 13 and 12 and had been wrong since modules were
        # added; a hardcoded count drifts on every new target and says nothing
        # about whether the SBOM actually covers the package. The manifest is an
        # independent source, so this is a cross-check rather than a tautology.
        manifest = (ROOT / "Package.swift").read_text(encoding="utf-8")
        self.assertEqual(len(document["products"]), manifest.count(".library("))
        self.assertEqual(
            len(document["sourceTargets"]), manifest.count(".target(")
        )
        self.assertEqual(
            len(document["testTargets"]), manifest.count(".testTarget(")
        )

        # `ADR-0233` and `ADR-0267` declared dependencies, so these are no longer
        # empty. Every external package must carry a reviewed licence, which is
        # the property that matters rather than the count.
        self.assertNotEqual(document["externalPackages"], [])
        for index, package in enumerate(document["externalPackages"]):
            self.assertNotEqual(
                package["licence"],
                "REVIEW_REQUIRED",
                f"externalPackages[{index}] has an unreviewed licence",
            )

        resources = {
            resource["path"]: resource
            for resource in document["bundledResources"]
        }
        shader_manifest = "Sources/VoxeliaMetal/Resources/ShaderManifest.yaml"
        self.assertEqual(
            resources[shader_manifest]["owningTarget"],
            "VoxeliaMetal",
        )
        self.assertEqual(resources[shader_manifest]["scope"], "runtime")

        tool_names = {tool["name"] for tool in document["releaseTools"]}
        self.assertEqual(
            tool_names,
            {"Git", "Python", "Swift", "Voxelia SBOM Generator", "Xcode"},
        )

    def test_missing_required_field_is_rejected(self) -> None:
        document = deepcopy(self.document)
        document.pop("products")

        self.assertIn(
            "missing top-level fields: products",
            validation_errors(document),
        )

    def test_changed_file_digest_is_rejected(self) -> None:
        document = deepcopy(self.document)
        package_index, package_checksum = next(
            (index, record)
            for index, record in enumerate(document["checksums"])
            if record["path"] == "Package.swift"
        )
        package_checksum["value"] = "0" * 64

        self.assertIn(
            f"checksums[{package_index}]: digest mismatch for Package.swift",
            validation_errors(document),
        )

    def test_unreviewed_external_package_licence_is_rejected(self) -> None:
        document = deepcopy(self.document)
        document["externalPackages"].append(
            {
                "identity": "example",
                "location": "https://example.invalid/example.git",
                "resolvedVersion": "1.0.0",
                "resolvedRevision": "0" * 40,
                "licence": "REVIEW_REQUIRED",
                "usage": ["VoxeliaCore"],
                "distribution": "runtime",
                "optional": False,
            }
        )

        # The appended fixture lands after the real packages, so the index is
        # derived rather than pinned to zero -- which it was, and which broke
        # the moment a dependency was declared.
        appended = len(document["externalPackages"]) - 1
        self.assertIn(
            f"externalPackages[{appended}] requires a reviewed licence",
            validation_errors(document),
        )

    def test_schema_invalid_optional_dependency_returns_errors(self) -> None:
        document = deepcopy(self.document)
        document["optionalDependencies"] = [{}]

        errors = validation_errors(document)

        self.assertTrue(errors)
        self.assertTrue(
            any("optionalDependencies[0]" in error for error in errors),
            errors,
        )

    def test_schema_file_is_valid_json(self) -> None:
        schema_path = ROOT / "Tools/Schemas/VoxeliaSBOM.schema.json"
        schema = json.loads(schema_path.read_text(encoding="utf-8"))

        self.assertEqual(
            set(schema["required"]),
            {
                "bomFormat",
                "specVersion",
                "schema",
                "metadata",
                "products",
                "sourceTargets",
                "testTargets",
                "externalPackages",
                "licences",
                "checksums",
                "releaseTools",
                "bundledResources",
                "optionalDependencies",
            },
        )


class SBOMSchemaValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = json.loads(
            (ROOT / "Tools/Schemas/VoxeliaSBOM.schema.json").read_text(
                encoding="utf-8"
            )
        )
        cls.document = json.loads(
            (ROOT / DEFAULT_OUTPUT).read_text(encoding="utf-8")
        )

    def test_checked_in_schema_constraints_are_enforced(self) -> None:
        mutations = {
            "unexpected top-level field": lambda document: document.update(
                {"unexpected": True}
            ),
            "schema dialect": lambda document: document["schema"].update(
                {"dialect": "invalid"}
            ),
            "project identity": lambda document: document["metadata"].update(
                {"project": "NotVoxelia"}
            ),
            "release date": lambda document: document["metadata"].update(
                {"releaseDate": "not-a-date"}
            ),
            "product type": lambda document: document["products"][0].update(
                {"type": ""}
            ),
            "external package types": lambda document: document[
                "externalPackages"
            ].append(
                {
                    "identity": 123,
                    "location": 123,
                    "resolvedVersion": 123,
                    "resolvedRevision": "invalid",
                    "licence": 123,
                    "usage": "VoxeliaCore",
                    "distribution": 123,
                    "optional": "false",
                }
            ),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                document = deepcopy(self.document)
                mutate(document)
                self.assertTrue(
                    json_schema_errors(document, self.schema, self.schema),
                    label,
                )


class SBOMPlaceholderTests(unittest.TestCase):
    def test_dataless_source_fails_closed_before_read(self) -> None:
        placeholder = ROOT / "not-materialized-for-test"
        with patch.object(
            Path,
            "stat",
            return_value=SimpleNamespace(st_flags=0x40000000),
        ):
            with self.assertRaisesRegex(
                SBOMError,
                "required file is not downloaded locally",
            ):
                sha256(placeholder)


if __name__ == "__main__":
    unittest.main()

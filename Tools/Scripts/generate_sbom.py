#!/usr/bin/env python3
"""Generate and validate the Voxelia release SBOM profile."""
from __future__ import annotations

import argparse
from datetime import date
import hashlib
import json
import os
import platform
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
PROFILE_VERSION = "1.0.0"
SCHEMA_PATH = "Tools/Schemas/VoxeliaSBOM.schema.json"
DEFAULT_OUTPUT = "docs/releases/v0.1.1/SBOM.scaffold.generated.json"
SF_DATALESS = 0x40000000
REQUIRED_TOP_LEVEL = {
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
}


class SBOMError(RuntimeError):
    """Raised when source metadata cannot produce trustworthy release evidence."""


def require_materialized(path: Path) -> None:
    """Reject cloud placeholders instead of waiting indefinitely for hydration."""
    try:
        flags = getattr(path.stat(), "st_flags", 0)
    except OSError as error:
        raise SBOMError(f"cannot inspect required file {path}: {error}") from error
    if flags & SF_DATALESS:
        raise SBOMError(
            f"required file is not downloaded locally: {path}. "
            "Materialize the repository and retry."
        )


def read_utf8(path: Path) -> str:
    require_materialized(path)
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        raise SBOMError(f"cannot read required file {path}: {error}") from error


def command_output(root: Path, *command: str) -> str:
    environment = os.environ.copy()
    environment.update(
        {
            "GIT_TERMINAL_PROMPT": "0",
            "GIT_CONFIG_COUNT": "1",
            "GIT_CONFIG_KEY_0": "credential.helper",
            "GIT_CONFIG_VALUE_0": "",
        }
    )
    try:
        return subprocess.check_output(
            command,
            cwd=root,
            env=environment,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=60,
        ).strip()
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
        detail = getattr(error, "output", "") or str(error)
        raise SBOMError(
            f"command failed ({' '.join(command)}): {detail.strip()}"
        ) from error


def sha256(path: Path) -> str:
    require_materialized(path)
    digest = hashlib.sha256()
    try:
        with path.open("rb") as source:
            for block in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(block)
    except OSError as error:
        raise SBOMError(f"cannot hash required file {path}: {error}") from error
    return digest.hexdigest()


def checksum_record(root: Path, relative_path: str) -> dict[str, str]:
    return {
        "path": relative_path,
        "algorithm": "SHA-256",
        "value": sha256(root / relative_path),
    }


def product_type(product: dict[str, Any]) -> str:
    value = product.get("type")
    if isinstance(value, str):
        return value
    if isinstance(value, dict) and len(value) == 1:
        return str(next(iter(value)))
    raise SBOMError(f"unsupported product type for {product.get('name')!r}")


def dependency_name(dependency: Any) -> str:
    if not isinstance(dependency, dict) or len(dependency) != 1:
        raise SBOMError(f"unsupported target dependency: {dependency!r}")
    value = next(iter(dependency.values()))
    if isinstance(value, list) and value and isinstance(value[0], str):
        return value[0]
    if isinstance(value, str):
        return value
    raise SBOMError(f"unsupported target dependency: {dependency!r}")


def target_path(target: dict[str, Any]) -> str:
    declared_path = target.get("path")
    if isinstance(declared_path, str):
        return declared_path
    prefix = "Tests" if target.get("type") == "test" else "Sources"
    return f"{prefix}/{target['name']}"


def target_record(target: dict[str, Any]) -> dict[str, Any]:
    path = target_path(target)
    if target["type"] == "test":
        scope = "test"
    elif path.startswith("Tests/"):
        scope = "test-support"
    else:
        scope = "runtime"
    return {
        "name": target["name"],
        "type": target["type"],
        "scope": scope,
        "path": path,
        "dependencies": sorted(
            dependency_name(item) for item in target.get("dependencies", [])
        ),
    }


def bundled_resources(
    root: Path,
    targets: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for target in targets:
        owner_path = Path(target_path(target))
        scope = "test" if owner_path.parts[0] == "Tests" else "runtime"
        for declaration in target.get("resources", []):
            relative_resource = owner_path / declaration["path"]
            resource_path = root / relative_resource
            if resource_path.is_dir():
                files = sorted(path for path in resource_path.rglob("*") if path.is_file())
            elif resource_path.is_file():
                files = [resource_path]
            else:
                raise SBOMError(
                    f"declared resource does not exist: {relative_resource.as_posix()}"
                )
            rule = declaration.get("rule", {})
            rule_name = next(iter(rule), "unknown") if isinstance(rule, dict) else "unknown"
            for path in files:
                relative_path = path.relative_to(root).as_posix()
                records.append(
                    {
                        "owningTarget": target["name"],
                        "path": relative_path,
                        "scope": scope,
                        "processingRule": rule_name,
                        "checksum": {
                            "algorithm": "SHA-256",
                            "value": sha256(path),
                        },
                    }
                )
    return sorted(records, key=lambda record: (record["owningTarget"], record["path"]))


def build_sbom(root: Path = ROOT) -> dict[str, Any]:
    package = json.loads(command_output(root, "swift", "package", "dump-package"))
    release = json.loads(read_utf8(root / "RELEASE.json"))
    version = read_utf8(root / "VERSION").strip()
    if release.get("version") != version:
        raise SBOMError(
            "VERSION and RELEASE.json disagree: "
            f"{version!r} != {release.get('version')!r}"
        )
    if package.get("dependencies"):
        raise SBOMError(
            "external Swift packages require reviewed licence, resolution, "
            "usage and optionality metadata before SBOM generation"
        )

    all_targets = package["targets"]
    source_targets = [
        target_record(target)
        for target in all_targets
        if target.get("type") == "regular"
    ]
    test_targets = [
        target_record(target)
        for target in all_targets
        if target.get("type") == "test"
    ]
    products = [
        {
            "name": product["name"],
            "type": product_type(product),
            "targets": product["targets"],
        }
        for product in package["products"]
    ]

    checksum_paths = [
        "LICENSE",
        "Package.swift",
        "RELEASE.json",
        "THIRD_PARTY_NOTICES.md",
        "Tools/Schemas/VoxeliaSBOM.schema.json",
        "Tools/Scripts/generate-sbom.sh",
        "Tools/Scripts/generate_sbom.py",
        "VERSION",
    ]
    if (root / "Package.resolved").is_file():
        checksum_paths.append("Package.resolved")

    git_status = command_output(
        root,
        "git",
        "status",
        "--porcelain",
        "--untracked-files=all",
    )
    revision = command_output(root, "git", "rev-parse", "HEAD")
    generator_checksum = checksum_record(
        root,
        "Tools/Scripts/generate_sbom.py",
    )
    licence_checksum = checksum_record(root, "LICENSE")

    return {
        "bomFormat": "Voxelia-Release-SBOM",
        "specVersion": PROFILE_VERSION,
        "schema": {
            "dialect": "https://json-schema.org/draft/2020-12/schema",
            "path": SCHEMA_PATH,
            "profileVersion": PROFILE_VERSION,
        },
        "metadata": {
            "project": package["name"],
            "version": version,
            "release": release["release"],
            "releaseDate": release["date"],
            "sourceRevision": {
                "commit": revision,
                "workingTreeDirty": bool(git_status),
                "scope": (
                    "Checked-out source revision observed before writing the "
                    "generated SBOM artifact."
                ),
            },
            "platformPolicy": release["platformPolicy"],
        },
        "products": sorted(products, key=lambda product: product["name"]),
        "sourceTargets": sorted(
            source_targets,
            key=lambda target: target["name"],
        ),
        "testTargets": sorted(test_targets, key=lambda target: target["name"]),
        "externalPackages": [],
        "licences": [
            {
                "component": package["name"],
                "spdxIdentifier": "MIT",
                "source": "LICENSE",
                "checksum": {
                    "algorithm": licence_checksum["algorithm"],
                    "value": licence_checksum["value"],
                },
            }
        ],
        "checksums": [
            checksum_record(root, path) for path in sorted(checksum_paths)
        ],
        "releaseTools": [
            {
                "name": "Voxelia SBOM Generator",
                "version": PROFILE_VERSION,
                "path": generator_checksum["path"],
                "checksum": {
                    "algorithm": generator_checksum["algorithm"],
                    "value": generator_checksum["value"],
                },
            },
            {
                "name": "Git",
                "version": command_output(root, "git", "--version"),
                "role": "source revision",
            },
            {
                "name": "Python",
                "version": platform.python_version(),
                "role": "SBOM profile generation and validation",
            },
            {
                "name": "Swift",
                "version": command_output(root, "swift", "--version"),
                "role": "Swift package metadata",
            },
            {
                "name": "Xcode",
                "version": " | ".join(
                    command_output(root, "xcodebuild", "-version").splitlines()
                ),
                "role": "Apple release toolchain",
            },
        ],
        "bundledResources": bundled_resources(root, all_targets),
        "optionalDependencies": [],
    }


def resolved_repository_file(root: Path, value: str) -> Path | None:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        return None
    candidate = (root / path).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate if candidate.is_file() else None


def validate_checksum(
    root: Path,
    record: Any,
    label: str,
) -> list[str]:
    if not isinstance(record, dict):
        return [f"{label}: checksum record must be an object"]
    if record.get("algorithm") != "SHA-256":
        return [f"{label}: checksum algorithm must be SHA-256"]
    value = record.get("value")
    if not isinstance(value, str) or re.fullmatch(r"[0-9a-f]{64}", value) is None:
        return [f"{label}: checksum value must be 64 lowercase hexadecimal digits"]
    return []


def resolve_local_schema_reference(root_schema: dict[str, Any], reference: str) -> Any:
    if not reference.startswith("#/"):
        raise SBOMError(f"unsupported non-local JSON Schema reference: {reference}")
    resolved: Any = root_schema
    for raw_component in reference[2:].split("/"):
        component = raw_component.replace("~1", "/").replace("~0", "~")
        if not isinstance(resolved, dict) or component not in resolved:
            raise SBOMError(f"unresolvable JSON Schema reference: {reference}")
        resolved = resolved[component]
    return resolved


def json_type_matches(value: Any, expected: str) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "boolean":
        return isinstance(value, bool)
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if expected == "null":
        return value is None
    raise SBOMError(f"unsupported JSON Schema type: {expected}")


def json_schema_errors(
    value: Any,
    schema: Any,
    root_schema: dict[str, Any],
    location: str = "$",
) -> list[str]:
    """Validate the checked-in profile using its dependency-free schema subset."""
    if isinstance(schema, bool):
        return [] if schema else [f"{location}: value is forbidden by schema"]
    if not isinstance(schema, dict):
        raise SBOMError(f"invalid JSON Schema node at {location}")

    errors: list[str] = []
    reference = schema.get("$ref")
    if isinstance(reference, str):
        errors.extend(
            json_schema_errors(
                value,
                resolve_local_schema_reference(root_schema, reference),
                root_schema,
                location,
            )
        )

    for subschema in schema.get("allOf", []):
        errors.extend(json_schema_errors(value, subschema, root_schema, location))

    expected_type = schema.get("type")
    if isinstance(expected_type, str) and not json_type_matches(value, expected_type):
        return errors + [f"{location}: expected {expected_type}"]

    if "const" in schema and value != schema["const"]:
        errors.append(f"{location}: expected constant {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{location}: value is not in the allowed set")

    if isinstance(value, str):
        minimum_length = schema.get("minLength")
        if isinstance(minimum_length, int) and len(value) < minimum_length:
            errors.append(f"{location}: string is shorter than {minimum_length}")
        pattern = schema.get("pattern")
        if isinstance(pattern, str) and re.search(pattern, value) is None:
            errors.append(f"{location}: string does not match {pattern!r}")
        if schema.get("format") == "date":
            try:
                parsed = date.fromisoformat(value)
            except ValueError:
                errors.append(f"{location}: expected an RFC 3339 full-date")
            else:
                if parsed.isoformat() != value:
                    errors.append(f"{location}: expected an RFC 3339 full-date")

    if isinstance(value, dict):
        required = schema.get("required", [])
        for name in required:
            if name not in value:
                errors.append(f"{location}: missing required property {name!r}")
        properties = schema.get("properties", {})
        if isinstance(properties, dict):
            for name, subschema in properties.items():
                if name in value:
                    errors.extend(
                        json_schema_errors(
                            value[name],
                            subschema,
                            root_schema,
                            f"{location}.{name}",
                        )
                    )
            if schema.get("additionalProperties") is False:
                unexpected = sorted(set(value) - set(properties))
                if unexpected:
                    errors.append(
                        f"{location}: unexpected properties: {', '.join(unexpected)}"
                    )

    if isinstance(value, list):
        minimum_items = schema.get("minItems")
        if isinstance(minimum_items, int) and len(value) < minimum_items:
            errors.append(f"{location}: requires at least {minimum_items} item(s)")
        if schema.get("uniqueItems") is True:
            for index, item in enumerate(value):
                if item in value[:index]:
                    errors.append(f"{location}: array items must be unique")
                    break
        item_schema = schema.get("items")
        if item_schema is not None:
            for index, item in enumerate(value):
                errors.extend(
                    json_schema_errors(
                        item,
                        item_schema,
                        root_schema,
                        f"{location}[{index}]",
                    )
                )

    return errors


def validation_errors(
    document: Any,
    root: Path = ROOT,
) -> list[str]:
    if not isinstance(document, dict):
        return ["SBOM root must be an object"]

    try:
        profile_schema = json.loads(read_utf8(root / SCHEMA_PATH))
    except json.JSONDecodeError as error:
        raise SBOMError(f"cannot parse SBOM schema {SCHEMA_PATH}: {error}") from error
    if not isinstance(profile_schema, dict):
        raise SBOMError(f"SBOM schema root must be an object: {SCHEMA_PATH}")

    errors = json_schema_errors(document, profile_schema, profile_schema)
    missing = sorted(REQUIRED_TOP_LEVEL - set(document))
    if missing:
        errors.append(f"missing top-level fields: {', '.join(missing)}")

    if document.get("bomFormat") != "Voxelia-Release-SBOM":
        errors.append("bomFormat must be Voxelia-Release-SBOM")
    if document.get("specVersion") != PROFILE_VERSION:
        errors.append(f"specVersion must be {PROFILE_VERSION}")

    schema = document.get("schema")
    if not isinstance(schema, dict):
        errors.append("schema must be an object")
    else:
        if schema.get("path") != SCHEMA_PATH:
            errors.append(f"schema.path must be {SCHEMA_PATH}")
        if schema.get("profileVersion") != PROFILE_VERSION:
            errors.append(f"schema.profileVersion must be {PROFILE_VERSION}")

    metadata = document.get("metadata")
    if not isinstance(metadata, dict):
        errors.append("metadata must be an object")
    else:
        version_path = root / "VERSION"
        if version_path.is_file():
            expected_version = read_utf8(version_path).strip()
            if metadata.get("version") != expected_version:
                errors.append(
                    f"metadata.version must match VERSION ({expected_version})"
                )
        revision = metadata.get("sourceRevision")
        if not isinstance(revision, dict):
            errors.append("metadata.sourceRevision must be an object")
        else:
            commit = revision.get("commit")
            if not isinstance(commit, str) or re.fullmatch(
                r"[0-9a-f]{40,64}",
                commit,
            ) is None:
                errors.append(
                    "metadata.sourceRevision.commit must be a full hexadecimal commit"
                )
            if not isinstance(revision.get("workingTreeDirty"), bool):
                errors.append(
                    "metadata.sourceRevision.workingTreeDirty must be boolean"
                )

    collection_names = (
        "products",
        "sourceTargets",
        "testTargets",
        "externalPackages",
        "licences",
        "checksums",
        "releaseTools",
        "bundledResources",
        "optionalDependencies",
    )
    for name in collection_names:
        if not isinstance(document.get(name), list):
            errors.append(f"{name} must be an array")

    source_targets = document.get("sourceTargets")
    products = document.get("products")
    if isinstance(source_targets, list):
        source_names = [
            item.get("name")
            for item in source_targets
            if isinstance(item, dict) and isinstance(item.get("name"), str)
        ]
        if not source_names or len(source_names) != len(source_targets):
            errors.append("sourceTargets must contain named target objects")
        elif len(source_names) != len(set(source_names)):
            errors.append("sourceTargets contains duplicate names")
    else:
        source_names = []

    if isinstance(products, list):
        product_names = [
            item.get("name")
            for item in products
            if isinstance(item, dict) and isinstance(item.get("name"), str)
        ]
        if not product_names or len(product_names) != len(products):
            errors.append("products must contain named product objects")
        elif len(product_names) != len(set(product_names)):
            errors.append("products contains duplicate names")
        for product in products:
            if not isinstance(product, dict):
                continue
            targets = product.get("targets")
            if not isinstance(targets, list) or not targets:
                errors.append(f"product {product.get('name')!r} has no targets")
                continue
            if any(not isinstance(target, str) for target in targets):
                errors.append(
                    f"product {product.get('name')!r} targets must be strings"
                )
                continue
            unknown = sorted(set(targets) - set(source_names))
            if unknown:
                errors.append(
                    f"product {product.get('name')!r} has unknown targets: "
                    f"{', '.join(unknown)}"
                )

    checksum_paths: set[str] = set()
    checksums = document.get("checksums")
    if isinstance(checksums, list):
        for index, record in enumerate(checksums):
            label = f"checksums[{index}]"
            if not isinstance(record, dict):
                errors.append(f"{label} must be an object")
                continue
            path_value = record.get("path")
            if not isinstance(path_value, str):
                errors.append(f"{label}.path must be a string")
                continue
            if path_value in checksum_paths:
                errors.append(f"duplicate checksum path: {path_value}")
            checksum_paths.add(path_value)
            errors.extend(validate_checksum(root, record, label))
            source = resolved_repository_file(root, path_value)
            if source is None:
                errors.append(f"{label}: invalid or missing path {path_value!r}")
            elif record.get("value") != sha256(source):
                errors.append(f"{label}: digest mismatch for {path_value}")

    resource_paths: set[str] = set()
    resources = document.get("bundledResources")
    if isinstance(resources, list):
        for index, resource in enumerate(resources):
            label = f"bundledResources[{index}]"
            if not isinstance(resource, dict):
                errors.append(f"{label} must be an object")
                continue
            path_value = resource.get("path")
            owner = resource.get("owningTarget")
            if not isinstance(path_value, str):
                errors.append(f"{label}.path must be a string")
                continue
            if path_value in resource_paths:
                errors.append(f"duplicate bundled resource path: {path_value}")
            resource_paths.add(path_value)
            if owner not in source_names:
                errors.append(f"{label}: unknown owning target {owner!r}")
            checksum = resource.get("checksum")
            errors.extend(validate_checksum(root, checksum, f"{label}.checksum"))
            source = resolved_repository_file(root, path_value)
            if source is None:
                errors.append(f"{label}: invalid or missing path {path_value!r}")
            elif isinstance(checksum, dict) and checksum.get("value") != sha256(source):
                errors.append(f"{label}: digest mismatch for {path_value}")

    licences = document.get("licences")
    if isinstance(licences, list):
        if not licences:
            errors.append("licences must identify the Voxelia project licence")
        for index, licence in enumerate(licences):
            if not isinstance(licence, dict):
                errors.append(f"licences[{index}] must be an object")
                continue
            if not licence.get("spdxIdentifier"):
                errors.append(f"licences[{index}] lacks an SPDX identifier")
            checksum = licence.get("checksum")
            errors.extend(
                validate_checksum(root, checksum, f"licences[{index}].checksum")
            )
            source_value = licence.get("source")
            source = (
                resolved_repository_file(root, source_value)
                if isinstance(source_value, str)
                else None
            )
            if source is None:
                errors.append(
                    f"licences[{index}]: invalid or missing source {source_value!r}"
                )
            elif isinstance(checksum, dict) and checksum.get("value") != sha256(source):
                errors.append(
                    f"licences[{index}]: digest mismatch for {source_value}"
                )

    tools = document.get("releaseTools")
    if isinstance(tools, list):
        tool_names = {
            tool.get("name")
            for tool in tools
            if isinstance(tool, dict) and isinstance(tool.get("name"), str)
        }
        required_tools = {"Git", "Python", "Swift", "Voxelia SBOM Generator", "Xcode"}
        absent_tools = sorted(required_tools - tool_names)
        if absent_tools:
            errors.append(f"missing release tools: {', '.join(absent_tools)}")
        for index, tool in enumerate(tools):
            if not isinstance(tool, dict):
                errors.append(f"releaseTools[{index}] must be an object")
                continue
            if not tool.get("name") or not tool.get("version"):
                errors.append(
                    f"releaseTools[{index}] requires name and version"
                )
            path_value = tool.get("path")
            if path_value is None:
                continue
            checksum = tool.get("checksum")
            errors.extend(
                validate_checksum(
                    root,
                    checksum,
                    f"releaseTools[{index}].checksum",
                )
            )
            source = (
                resolved_repository_file(root, path_value)
                if isinstance(path_value, str)
                else None
            )
            if source is None:
                errors.append(
                    f"releaseTools[{index}]: invalid or missing path "
                    f"{path_value!r}"
                )
            elif isinstance(checksum, dict) and checksum.get("value") != sha256(source):
                errors.append(
                    f"releaseTools[{index}]: digest mismatch for {path_value}"
                )

    external = document.get("externalPackages")
    optional = document.get("optionalDependencies")
    if isinstance(external, list) and isinstance(optional, list):
        identities = {
            item.get("identity")
            for item in external
            if isinstance(item, dict) and isinstance(item.get("identity"), str)
        }
        unknown_optional = sorted(
            item
            for item in optional
            if isinstance(item, str) and item not in identities
        )
        if unknown_optional:
            errors.append(
                "optionalDependencies contains unknown packages: "
                f"{', '.join(unknown_optional)}"
            )
        for index, package in enumerate(external):
            if not isinstance(package, dict):
                errors.append(f"externalPackages[{index}] must be an object")
                continue
            required = {
                "identity",
                "location",
                "resolvedVersion",
                "resolvedRevision",
                "licence",
                "usage",
                "distribution",
                "optional",
            }
            absent = sorted(required - set(package))
            if absent:
                errors.append(
                    f"externalPackages[{index}] missing: {', '.join(absent)}"
                )
            licence_value = package.get("licence")
            if not isinstance(licence_value, str) or licence_value in {
                "",
                "UNKNOWN",
                "REVIEW_REQUIRED",
            }:
                errors.append(
                    f"externalPackages[{index}] requires a reviewed licence"
                )

    return errors


def load_document(path: Path) -> Any:
    try:
        return json.loads(read_utf8(path))
    except (SBOMError, json.JSONDecodeError) as error:
        raise SBOMError(f"cannot read SBOM {path}: {error}") from error


def validate_or_raise(document: Any, root: Path = ROOT) -> None:
    errors = validation_errors(document, root)
    if errors:
        raise SBOMError("\n".join(f"- {error}" for error in errors))


def parse_arguments(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--validate",
        metavar="PATH",
        help="validate an existing SBOM instead of generating one",
    )
    arguments = parser.parse_args(argv)
    if arguments.validate and arguments.output != DEFAULT_OUTPUT:
        parser.error("output and --validate are mutually exclusive")
    return arguments


def main(argv: list[str] | None = None) -> int:
    arguments = parse_arguments(argv if argv is not None else sys.argv[1:])
    try:
        if arguments.validate:
            path = Path(arguments.validate)
            validate_or_raise(load_document(path))
            print(f"SBOM profile validation passed: {path}")
            return 0

        output = Path(arguments.output)
        if not output.is_absolute():
            output = ROOT / output
        document = build_sbom()
        validate_or_raise(document)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(output.relative_to(ROOT) if output.is_relative_to(ROOT) else output)
        return 0
    except SBOMError as error:
        print(f"SBOM generation failed:\n{error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

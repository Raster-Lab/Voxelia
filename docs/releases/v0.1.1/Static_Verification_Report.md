---
document_id: "VOXELIA-REL-0.1.1-STATIC-VERIFY"
title: "Voxelia Repository and Package Scaffold v0.1.1 Static Verification Report"
version: "0.1.1"
status: "Static Verification Passed - Apple Execution Pending"
document_type: "Verification Report"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
---

# Voxelia Repository and Package Scaffold v0.1.1 Static Verification Report

## Scope

This report records verification that can be performed without making a build, compatibility or validation claim for any excluded platform. No non-Apple Swift build or runtime evidence is included.

Formal M0 execution evidence remains restricted to an approved Apple Silicon Mac with Xcode and the declared Apple platform SDKs.

## Release inventory

| Item | Count |
|---|---:|
| Repository files before final checksum refresh | 283 |
| Markdown files | 107 |
| Controlled project documents | 7 |
| Swift files | 51 |
| Python repository tools and tests | 9 |
| Shell scripts | 12 |
| YAML files | 31 |
| GitHub workflow definitions | 10 |
| Requirements indexed | 486 |
| Public source targets with compile-time Apple gates | 12 |

## Passed static checks

- Required repository files and directories are present.
- The declared M0 package dependency graph matches the approved acyclic graph.
- Prohibited framework imports are absent from canonical targets.
- The Apple platform policy checker passes.
- Every public root package target contains an Apple operating-system and ARM64 compile-time gate.
- Auxiliary validation, benchmark, repository-tool and test-support targets contain the same platform gate.
- `VoxeliaMetal` imports Metal unconditionally.
- All workflow runner declarations require Voxelia-labelled self-hosted Apple Silicon macOS runners.
- No alternate-platform runner or generic build destination is configured in active build paths.
- YAML front matter passes for all 7 controlled project documents.
- Documentation text checks pass for 46 Markdown files under `docs/`.
- All 486 requirements are extracted into the v0.1.1 traceability index.
- All 12 shell scripts pass shell syntax validation.
- All Python repository tools and tests compile successfully.
- The repository-script regression suite passes its available static tests and records the Apple-host execution test as pending.
- All 31 YAML files parse successfully.
- Corrective action M0-001 is implemented in source.

## Corrective action M0-001

The malformed inline Python block has been removed from `validate-docs.sh`. Documentation text validation now resides in `check_document_text.py`, and the repository contains a regression test that executes the shell wrapper when running on the supported Apple Silicon macOS host.

Static evidence confirms:

- the wrapper contains no inline Python here-document;
- both Python document checkers execute successfully;
- the wrapper passes shell syntax validation; and
- the supported-host execution test is present.

## Apple-only platform controls

The release includes:

- `PLATFORM_SUPPORT.md`;
- accepted ADR-0001;
- revised Apple-only platform clauses in all seven governing documents;
- `assert-apple-platform.sh` for repository commands;
- compile-time Apple OS and ARM64 gates;
- Apple Silicon self-hosted runner labels; and
- a static policy checker.

## Pending Apple Silicon execution evidence

The following are intentionally not claimed by this report and must be run on an approved Apple Silicon Mac:

- root package debug and release builds;
- root package tests;
- Validation, Benchmarks and Tools package builds and tests;
- execution of `validate-docs.sh` and the complete repository-script suite;
- SwiftPM dynamic package graph verification;
- macOS, iOS, iPadOS, tvOS and visionOS ARM64 builds;
- Swift 6 strict-concurrency diagnostics under Xcode;
- Metal resource-bundle verification;
- DocC archive generation;
- SBOM generation from SwiftPM resolved target data;
- GitHub branch protection, DCO and CODEOWNERS enforcement; and
- self-hosted runner isolation review.

## Conclusion

The v0.1.1 source archive passes its static corrective-release checks and contains the controls required to prevent accidental non-Apple build or CI expansion. It is ready for Apple Silicon M0 execution and formal acceptance review. This report does not declare M0 accepted.

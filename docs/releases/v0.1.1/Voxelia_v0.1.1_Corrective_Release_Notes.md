---
document_id: "VOXELIA-REL-0.1.1"
title: "Voxelia Repository and Package Scaffold v0.1.1 Corrective Release Notes"
version: "0.1.1"
status: "Corrective Release"
document_type: "Release Notes"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
---

# Voxelia Repository and Package Scaffold v0.1.1

## Purpose

This release corrects the M0-001 documentation-validation defect and makes Apple Silicon hardware plus Apple operating systems the exclusive Voxelia development and execution baseline.

## Corrected

- Replaced the malformed inline Python in `Tools/Scripts/validate-docs.sh` with `check_document_text.py`.
- Added shell-syntax, Python-compilation and documentation-validation regression tests.
- Added the `test-repository-scripts.sh` release gate.

## Platform enforcement

- Added `PLATFORM_SUPPORT.md` and accepted ADR-0001.
- Added compile-time Apple operating-system and ARM64 gates to public package targets.
- Made Metal a mandatory import in `VoxeliaMetal`.
- Added an Apple Silicon macOS assertion to repository scripts.
- Changed CI to Voxelia-labelled self-hosted Apple Silicon macOS runners.
- Revised all seven governing documents to v0.1.1 and removed any ambiguity that could be interpreted as an alternate processor, operating-system, hosted-toolchain or renderer target.

## Validation status

Static repository, document, manifest, script and archive checks are included with this release. Swift, Xcode, DocC, Metal and platform-matrix execution evidence shall be produced only on an approved Apple Silicon Mac and remains required for formal M0 acceptance.

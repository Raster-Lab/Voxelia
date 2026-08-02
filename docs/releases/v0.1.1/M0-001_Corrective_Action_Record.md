---
document_id: "VOXELIA-CAR-M0-001"
title: "M0-001 Documentation Validation Script Corrective Action"
version: "0.1.1"
status: "Implemented - Apple Execution Confirmation Pending"
document_type: "Corrective Action Record"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
---

# M0-001 - Documentation validation script

## Problem

The v0.1 `Tools/Scripts/validate-docs.sh` contained a malformed inline Python newline expression. The shell parsed, but Python execution failed.

## Root cause

A generated here-document embedded an escaped newline incorrectly, converting the intended `"\n"` expression into a literal source-line break inside a quoted string.

## Correction

- Removed inline Python from the shell script.
- Added `Tools/Scripts/check_document_text.py` as a dedicated, independently compilable checker.
- Made `validate-docs.sh` call the front-matter and document-text checkers.
- Added `Tools/Tests/Python/test_repository_scripts.py`.
- Added `Tools/Scripts/test-repository-scripts.sh` to the test and validation gates.

## Preventive controls

- Every shell script receives `bash -n` validation.
- Every Python repository tool receives byte-code compilation.
- Documentation validation is invoked by the regression suite.
- Corrective scripts are required files under the M0 scaffold check.

## Closure condition

M0-001 is fully closed after the corrected script and regression suite pass on the approved Apple Silicon macOS CI environment.

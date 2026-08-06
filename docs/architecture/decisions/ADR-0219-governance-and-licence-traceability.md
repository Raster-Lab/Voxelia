---
document_id: "ADR-0219"
title: "Governance and licence traceability"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DOC-008"
  - "VOX-GOV-001"
  - "VOX-GOV-002"
  - "VOX-GOV-004"
  - "VOX-GOV-007"
  - "VOX-GOV-008"
  - "VOX-LIC-001"
  - "VOX-LIC-003"
  - "VOX-LIC-004"
  - "VOX-LIC-006"
  - "VOX-LIC-007"
  - "VOX-LIC-008"
  - "VOX-LIC-009"
  - "VOX-PLT-010"
  - "VOX-PLT-012"
  - "VOX-REP-005"
  - "VOX-REP-009"
  - "VOX-SEC-004"
  - "VOX-SEC-007"
  - "VOX-DOC-001"
  - "VOX-REL-001"
  - "VOX-REL-002"
  - "VOX-ADP-005"
  - "VOX-HLS-011"
  - "VOX-DST-010"
---

# ADR-0219 - Governance and licence traceability

## Context

`ADR-0218` took the traceability debt to 53 rows and predicted the governance,
licence and repository block as the next tractable one: mostly artefacts that
already exist, so the work is citing what satisfies each row and which check
holds it true.

That prediction was half right. The artefacts do exist. What the inspection also
found is that two of the project's most consequential properties — its
zero-dependency licence posture and its SPDX coverage — were **held true by
nothing at all**.

## Findings

### Satisfied by artefacts already enforced

- **`VOX-LIC-001`** (MIT licence) and **`VOX-LIC-004`**
  (`THIRD_PARTY_NOTICES.md`): both files are present at the root and
  `check_required_files.py` enforces their presence.
- **`VOX-SEC-007`** (published vulnerability reporting process): `SECURITY.md`
  is present and required.
- **`VOX-GOV-001`**, **`VOX-GOV-002`** and **`VOX-GOV-004`** (standalone
  open-source toolkit, DICOM Workstation as first reference application,
  material changes governed): stated in `README.md` and `GOVERNANCE.md`, both
  required files.
- **`VOX-DOC-001`** (documentation stored with source and version controlled):
  the entire `docs/` tree is in the repository and covered by
  `check_document_text.py`.
- **`VOX-REP-005`** (requirements, algorithms, validation and benchmark
  documentation versioned with source): `docs/project`, `docs/algorithms`,
  `docs/architecture`, `Benchmarks` and `Validation` are all tracked.
- **`VOX-LIC-006`** (contribution provenance via the Developer Certificate of
  Origin): `DCO.txt` is present, `CONTRIBUTING.md` requires it, and **every
  commit in this project's history carries a `Signed-off-by` trailer** — the
  practice, not only the policy.
- **`VOX-REL-001`** (Semantic Versioning) and **`VOX-REL-002`** (breaking 0.x
  changes documented): `RELEASE.json` declares `0.1.1` and `CHANGELOG.md` is a
  required file.
- **`VOX-PLT-010`** (SwiftPM as the primary package mechanism, **I,D**):
  `Package.swift` is the build definition and the whole toolchain runs through
  it. Only **Inspection** is claimed; the Demonstration half is a distribution
  act.
- **`VOX-PLT-012`** (Swift Testing as the default framework, **I,T**): measured
  — **185 test files import `Testing` and none imports `XCTest`**.

### Prohibition rows, satisfied by absence and partly enforced

- **`VOX-ADP-005`** (Core Image not the canonical engine): enforced —
  `CoreImage` is in the prohibited-import set of every backend-neutral module.
- **`VOX-GOV-007`** and **`VOX-GOV-008`** (no PACS, VNA, reporting, hanging
  protocols or authentication; no drop-in-replacement claim): satisfied by
  absence, and the scope statements live in `README.md` and `GOVERNANCE.md`.
- **`VOX-SEC-004`** (no embedded credentials or unauthenticated network
  services), **`VOX-HLS-011`** (no embedded HTTP, WebSocket or WebRTC server)
  and **`VOX-DST-010`** (no worker discovery or cluster membership): satisfied
  by absence — **no source file imports `Network`, `NIO`, `Vapor`,
  `FoundationNetworking` or uses `URLSession`**, and the package has no
  dependency that could supply one.

### The enforcement gap this inspection exists to have found

**Four accepted requirements are satisfied for exactly one reason, and nothing
was checking it.** `VOX-LIC-007` (no strong-copyleft dependencies),
`VOX-LIC-008` (restrictive dependencies isolated in optional modules),
`VOX-LIC-009` (dependency licences checked for compatibility) and
`VOX-REP-009` (external dependencies attached only to targets needing them) all
hold today because `Package.swift` declares **`dependencies: []`**.

One added line would have invalidated all four at once, silently, with every
check in the repository still green — and third-party dependencies are reserved
to the project owner. This is the fourth instance of the `ADR-0196` pattern, and
the most consequential: it is the project's entire supply-chain posture resting
on an unguarded fact.

**`VOX-LIC-003`** (SPDX identifiers) was the same story on a smaller scale: all
395 Swift sources carry `SPDX-License-Identifier: MIT`, and nothing verified it.

## Decision

1. **A new check enforces both**, `Tools/Scripts/check_licence_policy.py`,
   wired into `validate-docs.sh`: the package-level dependency list must remain
   empty, and every Swift source must carry the SPDX identifier.
2. **These are clean gates, not ratchets.** Both properties hold *completely*
   today, so there is no debt to freeze — unlike `ADR-0216`'s traceability
   check, where a clean gate would have been red on arrival.
3. **The dependency gate names the requirements it protects in its own failure
   message**, so whoever trips it learns why the line matters rather than
   deleting the check.
4. **Both gates were verified by breaking them**: adding a package dependency
   fails the first, and removing one SPDX header fails the second. A gate that
   has never been seen to fail is not known to work.
5. **Twenty-four rows are traced by this record**, each to the artefact,
   measurement or enforcing check that satisfies it.
6. **Partial verification methods are claimed as such.** `VOX-PLT-010` declares
   `I,D` and only Inspection is claimed.
7. **No product source changes.** The additions are one tooling script and one
   line in the documentation validation script.

## Alternatives considered

### Trace the licence rows and leave the dependency fact unguarded

Rejected. Recording that four requirements depend on one unguarded line, and
then not guarding it, would be the least defensible outcome available — the
inspection's whole value is that it noticed.

### Make the dependency check a ratchet with an allowlist

Rejected; see decision 2. There is nothing to allow: the list is empty. An
allowlist would only create a place to quietly add the first dependency.

### Enforce SPDX headers through the formatter instead

Rejected. `swift format` enforces layout, not licence policy, and a licence
property belongs with the licence check where a reader looking for it will find
it.

### Claim `VOX-PLT-010`'s Demonstration half because SwiftPM builds the project

Rejected; see decision 6. Building is not distributing.

## Consequences

The traceability debt falls from 53 rows to 29. The project's supply-chain
posture is now enforced rather than assumed: adding an external dependency fails
a check that explains which four requirements it bears on, which is exactly the
conversation that should happen before one is added.

The remaining 29 rows include the eighteen owner-gated `VOX-CMP` and `VOX-DCM`
entries, which stay until the owner answers.

## Affected modules

Tooling and documentation only. No product source changes.

## Compatibility impact

None for existing code. A future external dependency now requires an accepted
record and the owner's decision before the check will pass.

## Security impact

Positive: the absence of network and credential handling is now backed by the
dependency gate, since no dependency can arrive unnoticed to supply one.

## Performance and memory impact

The check reads one manifest and 395 source files; it runs in well under a
second.

## Validation impact

`check_licence_policy.py` passes. Both of its gates were verified to fail when
violated. `check_requirement_traceability.py` reports the reduced debt.

## Migration

1. Add the check and wire it into documentation validation.
2. The remaining traceability debt is 29 rows, eighteen of them owner-gated.

## Supersession

This record supersedes nothing. It labels existing artefacts and closes the
fourth enforcement gap of the shape `ADR-0196` first recorded.

## References

- [ADR-0196 - Geometry acceleration architecture assessment](ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0216 - Requirement traceability sweep](ADR-0216-requirement-traceability-sweep.md)
- [ADR-0217 - Vertical slice traceability](ADR-0217-vertical-slice-traceability.md)
- [ADR-0218 - Execution and CPU traceability](ADR-0218-execution-and-cpu-traceability.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

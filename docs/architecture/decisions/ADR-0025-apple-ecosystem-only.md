---
document_id: "ADR-0025"
title: "Apple Silicon and Apple operating systems only"
status: "Accepted"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PLT-001"
  - "VOX-PLT-002"
  - "VOX-PLT-003"
  - "VOX-PLT-004"
  - "VOX-PLT-005"
  - "VOX-PLT-006"
  - "VOX-PLT-007"
---

# ADR-0025 - Apple Silicon and Apple operating systems only

## Identifier migration record

This accepted decision was originally recorded as `ADR-0001` at the exact
former path `docs/architecture/decisions/ADR-0001-apple-ecosystem-only.md`
under the title "Apple Silicon and Apple operating systems only". It was
re-identified as `ADR-0025` on 2026-08-04 under the authority of accepted
[`ADR-0024`](ADR-0024-decision-register-reconciliation.md), because the
Master Technical Architecture Appendix A register canonically assigns
`ADR-0001` to its independent canonical-data-model decision. The substantive
decision, Accepted status, original date, owners and affected-requirement
mapping are unchanged. Historical v0.1.1 release records continue to refer
to this decision as `ADR-0001`.

## Context

Voxelia is intended to exploit Apple Silicon Unified Memory Architecture, Metal, Swift concurrency and Apple-native frameworks as foundational architecture. Treating those capabilities as optional would weaken the design and create validation matrices that do not serve the product programme.

## Decision

Voxelia shall support only Apple Silicon ARM64 hardware running Apple operating systems. The active operating-system families are macOS, iOS, iPadOS, visionOS and tvOS.

Development, CI, validation, benchmarking, release preparation, diagnostic-reference execution, headless rendering and distributed workers shall use Apple Silicon hardware and the Apple developer toolchain.

Intel, x86/x64, non-Apple operating systems and non-Apple-hosted Swift toolchains are excluded. No compatibility layer, alternate renderer, CI job, release artefact or future portability commitment shall be introduced without a formal revision of the Project Foundation.

## Consequences

- Package manifests declare only Apple platforms.
- Source targets contain compile-time Apple operating-system and ARM64 gates.
- Repository scripts fail outside Apple Silicon macOS.
- CI uses labelled Apple Silicon macOS runners.
- Metal is a required Voxelia platform framework.
- Platform-neutral scientific interfaces are retained for architectural quality, not portability.
- Validation and benchmark evidence applies only to declared Apple Silicon capability classes.

## Affected modules

This decision applies to every Swift target and executable product because all
Voxelia code is built and validated only for Apple operating systems on Apple
Silicon. It also applies to the Validation, Benchmarks and Tools packages and
to CI, documentation, benchmark and release workflows. It changes no target
ownership or dependency edge.

## Alternatives considered

### Portable CPU core with multiple platform backends

Rejected because it dilutes the Apple-native programme and creates unsupported validation obligations.

### Apple-primary with best-effort additional hosts

Rejected because best-effort hosts rapidly become de facto compatibility commitments.

## Validation impact

All M0 and later platform claims require execution on an approved Apple Silicon Mac. iOS, iPadOS, visionOS and tvOS build and device evidence remains part of the Apple platform matrix.

## Migration

The v0.1.1 corrective scaffold completed this decision's repository migration
through package platform declarations, compile-time platform gates,
Apple-Silicon-only repository scripts, self-hosted ARM64 workflow
configuration, platform documentation and static policy checks. It requires no
source, binary, wire-format or persisted-data migration.
Accepted [ADR-0024](ADR-0024-decision-register-reconciliation.md)
re-identified this same accepted record as `ADR-0025` on 2026-08-04; the
identifier migration changed no platform policy. A future platform-policy
change would require a formal Project Foundation revision and its own
controlled migration.

## Supersession

This ADR does not supersede another file-backed ADR and has not been
superseded. It supersedes only earlier non-normative wording that described
non-Apple support as a possible future direction. Accepted
[ADR-0024](ADR-0024-decision-register-reconciliation.md) reconciles identifiers
and does not supersede this platform decision.

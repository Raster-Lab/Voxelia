---
document_id: "ADR-0001"
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

# ADR-0001 - Apple Silicon and Apple operating systems only

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

## Alternatives considered

### Portable CPU core with multiple platform backends

Rejected because it dilutes the Apple-native programme and creates unsupported validation obligations.

### Apple-primary with best-effort additional hosts

Rejected because best-effort hosts rapidly become de facto compatibility commitments.

## Validation impact

All M0 and later platform claims require execution on an approved Apple Silicon Mac. iOS, iPadOS, visionOS and tvOS build and device evidence remains part of the Apple platform matrix.

## Supersession

This ADR supersedes any earlier wording that described non-Apple support as a possible future direction.

---
document_id: "ADR-0408"
title: "The release policy"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-API-012"
  - "VOX-REL-003"
  - "VOX-REL-004"
  - "VOX-REL-006"
  - "VOX-REL-007"
  - "VOX-REL-008"
  - "VOX-REL-009"
  - "VOX-REL-010"
  - "VOX-DOC-012"
  - "VOX-ERR-009"
  - "VOX-SEC-008"
  - "VOX-SEC-009"
---

# ADR-0408 - The release policy

## Context

The `ADR-0405` queue's last arc: thirteen `I,R` policy rows spanning
versioning, deprecation, diagnostic-change discipline, publication
contents, known limitations, dependency security, reproducibility and
the ABI posture. The engineering half is writing the policy and the
artefacts it names; the acceptance half is the owner's release
session. Much substance already existed — the release gate, the SBOM,
`RELEASE.json`, the supply-chain identity allowlist — and the arc
consolidates rather than invents.

## Decision

1. **`docs/releases/release-policy.md` is the policy**, covering: major
   semantic version for incompatible public API changes after 1.0;
   deprecation before removal except urgent security or correctness
   fixes; explicit identification of diagnostic-output-affecting
   changes in release notes with updated validation evidence required
   (the frozen-model discipline makes the trigger mechanical: a model
   version bump); the published platform matrix; published test,
   benchmark and validation status (the `ADR-0407` records);
   known limitations; the SBOM dependency inventory with exact pinned
   versions as the vulnerability-assessment artefact; toolchain
   recording in `RELEASE.json` with reproducibility where practical;
   exact-version pinning plus advisory monitoring per release cycle
   with vulnerable dependencies blocking release absent an owner
   waiver; and **source-package compatibility as the commitment, with
   no binary ABI promise** — consistent with `ADR-0403`.

2. **`docs/releases/known-limitations.md` is the honest list**,
   organised by operation, format and platform as the baseline
   demands, seeded with the current truth (version-one admissions,
   unevaluated deformable fields, the landmark-only portfolio, the
   single-scattering approximation, adapter seams without shipped
   readers, the reference-hardware determinism envelope).

3. **Every `R` half of these rows is the owner's release session** —
   the session reviews and accepts this policy, the limitations list,
   the SBOM and the evidence set at each stable release, starting with
   1.0.

4. **With this record, M10's engineering is complete.** Every row of
   every entered milestone is discharged or carries only its
   owner-reserved half. The loop's queue is exhausted; the loop stops
   and surfaces the accumulated owner batch.

## Alternatives considered

### Deferring the policy text to the 1.0 session

Rejected. The session accepts or amends a written policy; drafting in
session wastes the owner's time and hides the defaults.

## Consequences

The loop ends. The owner batch is surfaced in the ledger's closing
entry.

## Affected modules

Documentation only.

## Compatibility impact

None.

## Security impact

The dependency-security posture is now written policy.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, both documents and the register updates, in the same
   increment.
2. **Next**: stop the loop; surface the owner batch.

## Supersession

This record supersedes nothing.

## References

- [ADR-0405 - The M10 queue](ADR-0405-the-m10-queue.md)
- [ADR-0407 - Benchmark reporting and instrumentation](ADR-0407-benchmark-reporting-and-instrumentation.md)
- [ADR-0403 - Runtime plug-ins not introduced](ADR-0403-runtime-plug-ins-not-introduced.md)
- [Voxelia release policy](../../releases/release-policy.md)
- [Known limitations](../../releases/known-limitations.md)

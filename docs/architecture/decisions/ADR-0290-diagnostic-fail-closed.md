---
document_id: "ADR-0290"
title: "Diagnostic fail closed"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ERR-004"
---

# ADR-0290 - Diagnostic fail closed

## Context

`ADR-0289` closed the tooling arc and left the next action to be re-derived. A mechanical
sweep of the requirement baseline found **23 rows in entered milestones with no record, no
test and no source mention**. `VOX-ERR-004` is the oldest `P0` among them declaring `T`
alone, needs no owner decision and no reference hardware:

> Unsupported diagnostic behaviour shall fail explicitly rather than silently select
> preview behaviour.

## Reading the row precisely

"Preview behaviour" reads as a vague adjective until the baseline is searched for the word.
**`VOX-EXE-011`** names four execution policies — *reference, diagnostic, interactive and
preview* — and `ProvenanceValidationClaim` names `preview` beside `diagnosticReady`.

So the row is specific: when a **diagnostic** request cannot be served, the answer is a
typed refusal, never a quieter substitute served under the same name. That is a
fail-closed property with two distinct faces, and both already exist in the product.

## What the product already does

The vocabulary is systematic rather than incidental: **38 typed `unsupported*` cases**
across the modules, none of them carrying a payload and none paired with a fallback.

Two are the row's own subject:

- **`VolumeRaySampler`** admits exactly one registered quality token and throws
  `unsupportedQualityPolicy` for anything else. It does not sample more coarsely under a
  degraded policy; it refuses.
- **`ProvenanceValidationClaim`** makes the second face *structural*: `preview` carries no
  evidence and `diagnosticReady(ValidationEvidenceID)` cannot be constructed without it. A
  preview result therefore cannot be relabelled as diagnostic-ready by changing a case,
  because there is nothing to change it to.

Neither was tested as this property. The row's `T` is what this increment supplies.

## Decision

1. **`VOX-ERR-004` is discharged** by six tests asserting the property at both faces.
2. **Every refusal is paired with the nearest supported input.** A sampler that rejected
   every quality string would satisfy the refusal assertions and satisfy nothing about
   discrimination, so the registered token is asserted to succeed in the same suite.
3. **The accepted token is asserted exact, not a prefix or a family.** Four near misses —
   a suffixed version, an uppercased form, a truncation and a leading space — are each
   refused. A prefix or case-insensitive match would let a near-miss name select the
   diagnostic path by accident, which is the same hazard approached from the other side and
   the one a later "be more forgiving" change would introduce.
4. **The claim vocabulary is asserted non-`Comparable`, with a positive control.**
   `ADR-0057` states no ordering exists between claim cases; if the type were `Comparable`
   a caller could write `max(preview, diagnosticReady)` and select the stronger claim
   arithmetically. `Int` is asserted to *be* `Comparable` in the same test, because a
   negative conformance assertion that can never fire proves nothing.
5. **The refusal is asserted to throw rather than yield a default.** An operation returning
   an optional or a default-constructed value would let a caller proceed with something
   other than what it asked for. There is no value to proceed with, and the test shows
   none escapes.
6. **No source changed.** The property was implemented; it was untested.
7. **No algorithm specification and no oracle.** No numeric boundary is fixed.

## Scope, stated rather than implied

This suite covers the rendering and claim faces, which are where "preview" is a named
policy. The same fail-closed shape appears in other modules — `unsupportedBitDepth` in the
compression adapter, `normalsMissing` refusing a facet-normal fallback, `unsupportedProjection`
refusing to render a perspective camera orthographically — and each is already tested where
it lives, by the increment that built it.

What was missing was not coverage of individual refusals but a test that names the
**property** and would fail if a fallback were introduced. That is what this adds, and it
is deliberately placed where the row's own vocabulary lives rather than spread thinly
across every module that happens to refuse something.

## Alternatives considered

### Enumerate all 38 `unsupported*` cases in one suite

Rejected. Most are already exercised by the increments that introduced them, a second
assertion of the same throw adds no evidence, and a suite that must be edited whenever a
case is added would rot exactly as the SBOM counts in `ADR-0289` did.

### Assert the property by scanning source for fallback patterns

Rejected. A grep for `default:` or `??` cannot distinguish a legitimate total function from
a silent substitution, and a check that cannot tell those apart would either pass always or
fail constantly.

### Read "preview behaviour" as informal and test any typed refusal

Rejected. `VOX-EXE-011` names it as one of four policies, so the row has a specific subject
and testing a generic refusal would discharge it on the wrong evidence.

### Defer the row as already satisfied by construction

Rejected, for the reason this project has refused it before: a property worth having is
worth making fail visibly when someone removes it. The exact-token and non-`Comparable`
assertions are precisely the guards a plausible future change would trip.

## Consequences

`VOX-ERR-004` is discharged, and the fail-closed property it names now has a test that
fails if a degraded policy is silently served or a claim becomes orderable.

**22 entered-milestone rows remain untouched**, enumerated in the ledger for the next
derivation.

## Affected modules

None. `VoxeliaRenderingTests` gains one suite of six tests; no source changed.

## Compatibility impact

None.

## Security impact

Indirect and positive. The row protects against a diagnostic request being served by a
lower-fidelity path under the same name, which is a correctness hazard with clinical
consequences rather than a disclosure one.

## Performance and memory impact

None.

## Validation impact

```text
swift build && swift test
swift test --filter "DiagnosticFailClosed"
swift format lint --strict Tests/VoxeliaRenderingTests/DiagnosticFailClosedTests.swift
Tools/Scripts/validate-docs.sh
Tools/Scripts/test-repository-scripts.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1158 tests in 208 suites pass, up from 1152 in 207.

## Migration

1. This record and its tests.
2. **Next**: the derived queue's remaining 22 rows. `VOX-R2D-003` (signed and unsigned
   integer input) and `VOX-MPR-014` (measurements use authoritative physical geometry) are
   the next `P0`, `T`-only rows with no gate.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **tests a property `ADR-0057` and `VOX-EXE-011` already
established** and that the product already implements.

## References

- [ADR-0057 - Provenance claim leaf shapes](ADR-0057-provenance-claim-leaf-shapes.md)
- [ADR-0199 - Surface vertex projection design](ADR-0199-surface-vertex-projection-design.md)
- [ADR-0202 - Surface shading design](ADR-0202-surface-shading-design.md)
- [ADR-0289 - Repository self test recovery](ADR-0289-repository-self-test-recovery.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

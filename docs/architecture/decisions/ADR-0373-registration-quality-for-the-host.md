---
document_id: "ADR-0373"
title: "Registration quality for the host"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-009"
---

# ADR-0373 - Registration quality for the host

## Context

`VOX-REG-009` (P1, `T`, M7): registration quality metrics shall be
available to the host application. Two quality surfaces already half
exist: the `ADR-0370` metrics evaluate similarity over sample pairs, and
the landmark machinery holds correspondences. What is missing is the
geometric quality measure hosts actually quote — residual distances
under the estimated transform — as a typed, host-facing report.

## Decision

1. **`RegistrationQuality.evaluate`** (`VOXELIA-ALG-0073`,
   `registration-quality/binary64-v1`) maps moving landmarks through an
   admitted rigid or affine transform and reports a
   `RegistrationQualityReport`: per-landmark residual distances in
   landmark order, their root mean square and their maximum, all frozen
   and bit-pinned.

2. **The caller declares what the landmarks mean.** Residuals over the
   fitting set measure fit; residuals over a held-out set measure target
   registration error. The report records numbers, not the claim — the
   distinction lives in the host's protocol, and pretending otherwise
   would fabricate a validation the library did not perform.

3. **Spaces validate at the face**: moving landmarks must live in the
   transform's source space and fixed landmarks in its destination
   space, the same typed refusal as the landmark registration faces.

4. **Deformable transforms refuse typed.** Their evaluation does not
   exist yet (`ADR-0365` deferred it); a quality number computed from a
   matrix a deformable transform does not have would be fabrication.

5. **Similarity-metric quality is already served** by `ADR-0370`
   evaluations, whose visible counts make them honest host-facing
   numbers; this record adds the geometric surface and does not wrap the
   existing one in another type.

## Alternatives considered

### A combined quality report bundling metric evaluations and residuals

Rejected. The two surfaces have different inputs (sample pairs versus
landmark pairs) and different availability; bundling would force hosts
to fabricate one to obtain the other.

### Naming the report "target registration error"

Rejected — decision 2. TRE is a claim about *which* landmarks were used,
and only the host knows.

## Consequences

Hosts quote residual quality from a typed report; the arc's remaining
row is the reference-implementation row.

## Affected modules

`VoxeliaCore` gains `RegistrationQuality`,
`RegistrationQualityReport` and their error family.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(N)` per evaluation.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0373-registration-quality-oracle.py
swift test --filter RegistrationQualityTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0073`, the types, the fixture suite and the
   register updates, in the same increment.
2. **Next**: the reference-implementation row, closing the arc's
   unblocked queue.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0073 - Registration quality](../../algorithms/VOXELIA-ALG-0073-registration-quality.md)
- [ADR-0370 - The registration metric architecture](ADR-0370-the-registration-metric-architecture.md)
- [ADR-0372 - Explicit registration failure](ADR-0372-explicit-registration-failure.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

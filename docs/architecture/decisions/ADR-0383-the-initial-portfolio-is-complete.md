---
document_id: "ADR-0383"
title: "The initial portfolio is complete"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-005"
---

# ADR-0383 - The initial portfolio is complete

## Context

`VOX-REG-005` (P0, `T`, M7): the **initial** registration portfolio
shall include landmark, rigid and affine registration. `ADR-0368` and
`ADR-0369` built the landmark affine and landmark rigid members and
held the row open pending "intensity-driven members". Closing the M7
queue forced the question that phrasing had deferred: **what does the
row's text actually demand?**

## Decision

1. **The row is discharged by what exists.** The portfolio contains
   landmark registration (both estimators), rigid registration
   (`LandmarkRigidRegistration` producing the rigid category) and
   affine registration (`LandmarkAffineRegistration` producing the
   affine category) — each with bit-pinned oracle fixtures, typed
   admissions, and the end-to-end `ADR-0374` reference witness driving
   the whole chain. That is landmark, rigid and affine registration:
   the row's three named members, in its own words.

2. **Intensity-driven iterative registration is a future capability,
   not this row's debt.** No M7 row demands an optimiser: the metric
   architecture row asked for metrics (built, `ADR-0370`), the pyramid
   row for pyramids (built, `ADR-0371`), and this row for an *initial*
   portfolio. Reading "initial" as "iterative" was this ledger's own
   inflation, and recording the correction is cheaper than building to
   it. When intensity registration is wanted, the metrics, pyramids,
   outcome seam and result record are its prepared substrate — that
   was the point of building them row by row.

3. **With this record, every M7 row is discharged or owner-reserved.**
   The owner batch now holds, in one place: the `ADR-0351` questions
   (VTK/ITK scope, the segmentation reference adapter, DICOMKit
   fix-what-surfaces), the `ADR-0374` Metal-acceptance half, and the
   `ADR-0382` validated-distribution and diagnostic-policy halves.

## Alternatives considered

### Building gradient-descent intensity registration to "finish" the row

Rejected. It would be scope the baseline did not ask for, taken
autonomously — the exact shape `ADR-0338` d10 exists to prevent.

## Consequences

M7's engineering is complete. M8 opens next.

## Affected modules

None; this is a completion record.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "LandmarkAffineTests|LandmarkRigidTests|RegistrationReferenceTests"
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record and the ledger entry, in the same increment.
2. **Next**: derive and open the M8 queue.

## Supersession

This record closes what `ADR-0368` and `ADR-0369` held open.

## References

- [ADR-0368 - Landmark affine registration](ADR-0368-landmark-affine-registration.md)
- [ADR-0369 - Landmark rigid registration](ADR-0369-landmark-rigid-registration.md)
- [ADR-0374 - Registration references before Metal](ADR-0374-registration-references-before-metal.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

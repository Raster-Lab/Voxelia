---
document_id: "ADR-0374"
title: "Registration references before Metal"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REG-010"
---

# ADR-0374 - Registration references before Metal

## Context

`VOX-REG-010` (P0, `T,R`, M7): reference registration implementations
shall be available before Metal acceleration is accepted into a
diagnostic profile. The arc built its registration paths — landmark
estimation, composition, metrics, pyramid, outcome, quality — every one
a CPU reference with oracle-pinned determinism, and **no Metal
registration path exists in the tree**. The row's ordering constraint
holds today; the `T` half must witness it in a way that keeps holding.

## Decision

1. **An end-to-end reference witness**: one validation test drives the
   whole reference chain — landmark rigid and affine registration,
   composition across the space seam, a result record, outcome
   classification and residual quality — and checks the pinned values.
   That the test runs at all is the row's precondition: the references
   are available, on CPU, deterministic.

2. **A registry tripwire**: the same suite asserts that no Metal-backend
   registry entry names a registration operation. Today that is
   vacuously true; the day someone registers one, the test fails until
   this row's ordering is re-confirmed — the constraint outlives this
   increment instead of expiring with it.

3. **The `R` half joins the owner batch**: whether and when Metal
   registration acceleration enters a diagnostic profile is an
   acceptance decision, owner-reserved alongside the batch surfaced in
   `ADR-0351`. Nothing here pre-empts it; this record only makes the
   precondition checkable.

4. **This closes the registration arc's engineering**: every arc row is
   discharged or advanced to its owner-reserved half
   (the portfolio's intensity-driven members await the optimiser design
   that composes `ADR-0370`; the arc's structural rows are done).

## Alternatives considered

### A prohibited-import gate for Metal in registration files

Rejected. Registration lives in `VoxeliaCore`/`VoxeliaSpatial`, where
Metal is already prohibited by the existing per-target gate; a second
spelling of the same prohibition adds a register without a row demanding
one (`ADR-0338` d10).

### Treating the row as blocked on the owner

Rejected. The `T` half is buildable now and makes the `R` decision
checkable instead of rhetorical.

## Consequences

The registration arc's engineering closes. The curved-planar and DICOM
tails arc opens next per the `ADR-0351` order.

## Affected modules

`VoxeliaValidation` tests only; no source module changes.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter RegistrationReferenceTests
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the witness suite and the register updates, in the same
   increment.
2. **Next**: open the curved-planar/DICOM-tails arc.
3. **Owner**: the Metal-acceptance half of this row, batched with
   `ADR-0351`'s open questions.

## Supersession

This record supersedes nothing.

## References

- [ADR-0365 - The registration transform categories](ADR-0365-the-registration-transform-categories.md)
- [ADR-0373 - Registration quality for the host](ADR-0373-registration-quality-for-the-host.md)
- [ADR-0351 - The M7 queue](ADR-0351-the-m7-queue.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

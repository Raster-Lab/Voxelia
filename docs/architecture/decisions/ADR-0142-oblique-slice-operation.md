---
document_id: "ADR-0142"
title: "Oblique slice operation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-MPR-003"
  - "VOX-MPR-004"
  - "VOX-SPA-004"
  - "VOX-ERR-001"
---

# ADR-0142 - Oblique slice operation

## Context

Accepted `ADR-0141` froze the `oblique-slice-sampling/binary64-v1`
model with python-verified fixtures. This record implements it as the
ninth registered operation. It was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **`ObliqueSliceOperation` joins `VoxeliaExecution`** under the
   accepted assembly pattern: typed admission, one budgeted
   coordinated read, the frozen model, the digested parameter
   schema, the derivation recipe and the subject-bound record with
   its parent edge. The operation mints no identifiers and acquires
   no clock. `org.voxelia.op.oblique-slice` opens at 1.0.0.
2. **Sampling runs only through the accepted authorities.** World
   positions evaluate in the claimed forward form; the
   `AffineWorldToIndexMap` composition supplies continuous volume
   indices; the trilinear reduction and support rule follow the
   specification exactly. No ad-hoc inverse exists in the operation.
3. **Admission is typed and payload-free**: the version-one value
   domain (rank-three eight-bit single-component intensity, no value
   transform), an uncalibrated volume, a volume mapping that does not
   cover all three axes, a request mapping other than the canonical
   slot order, a foreign-space request and an out-of-bounds output
   extent each reject their own case. Everything else surfaces as
   the audited typed error of the underlying accepted contract.
4. **The parameters are the request.** The frozen schema digests the
   sixteen request matrix elements, the coordinate space and the
   output extents — the full reproduction recipe of `VOX-MPR-004` —
   and the output claims the request geometry verbatim with fresh
   index-only axes, because the claimed geometry is the one
   calibration authority.

## Alternatives considered

Deriving regular axis sampling from the request columns was
rejected: the spacings would need square roots outside the frozen
model, and the geometry claim already carries the calibration
exactly. Extending the multiplanar coordinator in the same increment
was rejected to keep the increment atomic; its oblique surface
follows.

## Consequences

Oblique reconstruction exists as a registered, provenance-complete
operation; `VOX-MPR-003`'s remainder is discharged at the operation
level.

## Affected modules

`VoxeliaExecution`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One full-volume coordinated read and one inverse construction per
execution; eight taps and seven fused-free arithmetic steps per
output sample.

## Validation impact

New suite `ObliqueSliceOperationTests` reproduces all four frozen
fixtures, proves the integer-coordinate identity against a stored
plane, verifies the verbatim geometry claim and provenance assembly,
and rejects every typed admission.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0141`; no record is superseded.

## References

- [ADR-0141 - Oblique extraction design](ADR-0141-oblique-extraction-design.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling binary64-v1](../../algorithms/VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [ADR-0138 - World-to-index mapping](ADR-0138-world-to-index-mapping.md)

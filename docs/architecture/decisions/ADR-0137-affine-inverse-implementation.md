---
document_id: "ADR-0137"
title: "Affine inverse implementation"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-004"
  - "VOX-MPR-005"
  - "VOX-INT-006"
---

# ADR-0137 - Affine inverse implementation

## Context

Accepted `ADR-0136` froze the `affine-inverse/binary64-v1` model on
paper — the one frozen cofactor form, the row-zero determinant
expansion, the no-epsilon admission and an elementwise bound stated
with a measurement obligation. This record implements the frozen
model and discharges those obligations. It was authored and accepted
on 2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **`AffineSpatialInverse` lives in `VoxeliaSpatial`.** The type
   inverts the upper-left three-by-three spatial block of a validated
   `Matrix4x4Double` in exactly the specification's frozen order and
   exposes the nine row-major inverse entries beside the computed
   determinant. Reusing the validated matrix type leaves exactly one
   typed rejection: `AffineSpatialInverseError.singularMatrix` for a
   computed determinant magnitude below `leastNormalMagnitude`.
2. **The bound ships beside the value.** The specification's
   conservative elementwise bounds are computed at construction from
   the same rounded intermediates, internal to the module, so the
   harness measures exactly what the implementation claims — the
   `ADR-0087` evidence form.
3. **The obligations are discharged by measurement.** The harness
   reproduces all three conformance fixtures exactly, rejects
   sub-threshold determinants typed, and verifies the elementwise
   bound against an exact rational python oracle over ten thousand
   seeded-LCG strictly diagonally dominant matrices across four
   magnitude regimes, reporting the maximum observed ratio with
   headroom.
4. **Composition stays out.** The world-to-index mapping that
   consumes this inverse is its own increment per the design record;
   no `apply` surface exists here.

## Alternatives considered

Placing the type in `VoxeliaImaging` beside the MPR coordinator was
rejected: the inverse is a property of the spatial matrix itself and
both the interaction and imaging arcs consume it. Verifying the bound
in-process against a binary64 reference was rejected: the oracle must
be independent and exact, and host-python rational arithmetic is the
accepted pattern.

## Consequences

Oblique crosshair mapping and world-point picking gain their frozen,
measured foundation; the design record's prohibition on ad-hoc
inverses is now enforceable by pointing at the one authority.

## Affected modules

`VoxeliaSpatial`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One construction computes nine cofactors, one determinant, nine
divisions and nine bounds; no allocation beyond the two nine-element
stores.

## Validation impact

New suite `AffineSpatialInverseTests` covers the three fixtures,
bit-identical repetition, both typed rejections and the measured
bound with recorded evidence output.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0136`; no record is superseded.

## References

- [ADR-0136 - Affine inverse design](ADR-0136-affine-inverse-design.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse binary64-v1](../../algorithms/VOXELIA-ALG-0016-affine-inverse.md)
- [ADR-0087 - Float transform error bounds](ADR-0087-float-transform-error-bounds.md)

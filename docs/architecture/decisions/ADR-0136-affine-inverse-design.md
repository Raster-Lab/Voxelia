---
document_id: "ADR-0136"
title: "Affine inverse design"
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

# ADR-0136 - Affine inverse design

## Context

Oblique crosshair mapping and world-point picking on obliquely
oriented volumes need the inverse of an affine geometry's spatial
matrix — a numeric model with real rounding behaviour that must not
appear incidentally inside a consumer. Per the plan-first discipline
this record freezes the model and its obligations before any
implementation exists. It was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **The model is frozen on paper first.** `VOXELIA-ALG-0016` fixes
   the adjugate-over-determinant evaluation with one frozen cofactor
   form, the declared row-zero determinant expansion, no fused
   multiply-add, the no-epsilon determinant admission, and three
   exact fixtures cross-checked against a rational oracle.
2. **The bound is stated with a measurement obligation.** The
   elementwise gamma-style bound composes the cofactor,
   determinant-accumulation and division errors over magnitude sums;
   its conservative constants are stated in the specification and the
   implementing increment must verify them by measurement — the
   harness computes the bound beside every entry against an exact
   rational oracle over at least ten thousand seeded diagonally
   dominant matrices and reports the maximum ratio with headroom, per
   the `ADR-0087` precedent. A bound asserted without measurement
   would be a claim without evidence.
3. **Implementation follows separately.** The Swift model, its typed
   surface, the harness and the consuming world-to-index operation
   are their own increments, and no consumer may embed an ad-hoc
   inverse in the meantime.

## Alternatives considered

Gaussian elimination was rejected: pivot selection is data-dependent
branching, and the adjugate form is branch-free with one frozen
order. Deriving tight constants analytically before implementation
was rejected: the measured-headroom discipline has caught wrong
fixtures before and is the accepted evidence form.

## Consequences

The inverse model is registrable without design debt; oblique mapping
and picking gain their planned foundation.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in the specification's validation
section and bind the implementing increment.

## Migration

None; implementation follows as its own increment.

## Supersession

Plans the remaining opening of the geometry-bearing arc; no record is
superseded.

## References

- [VOXELIA-ALG-0016 - Affine spatial inverse binary64-v1](../../algorithms/VOXELIA-ALG-0016-affine-inverse.md)
- [ADR-0087 - Float transform error bounds](ADR-0087-float-transform-error-bounds.md)

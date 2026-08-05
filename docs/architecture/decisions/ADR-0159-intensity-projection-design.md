---
document_id: "ADR-0159"
title: "Intensity projection design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-006"
  - "VOX-MPR-007"
  - "VOX-MPR-008"
  - "VOX-MPR-009"
  - "VOX-MPR-010"
---

# ADR-0159 - Intensity projection design

## Context

The M6 assessment queues the intensity-projection arc first:
thick-slab reconstruction with maximum, minimum and average
projection and the declared treatment of padding, missing samples
and out-of-bounds regions. Per the plan-first discipline this record
freezes the model before implementation. It was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **One operation with a closed mode vocabulary.**
   `VOXELIA-ALG-0020` fixes maximum, minimum and average projection
   along one axis as one model; the three modes share identical
   admission, ray semantics, padding rule and provenance shape, so
   three operations would triplicate every register row for a
   one-token difference. The mode is a digested parameter and the
   claim records which ran. The display-inversion precedent split
   because its row demanded structural independence; these rows are
   siblings of one projection concern.
2. **The model is exact.** Maximum and minimum are integer extremes;
   the average accumulates an exact integer sum in ascending ray
   order and rounds the exact rational half to even — no
   floating-point step exists anywhere, so the operation claims the
   exact precision policy.
3. **Thick-slab reconstruction is composition.** The accepted
   extraction operation selects the slab with its typed region
   admission; projection then removes the axis — `VOX-MPR-006` by
   composition, exactly as the axis-aligned slice already composes
   extraction and squeeze. A slab-selecting projection parameter was
   rejected: it would duplicate the extraction operation's admission
   inside a second surface.
4. **The `VOX-MPR-010` treatments are declared, never coerced**:
   padding sentinels exclude under the accepted rule with
   all-excluded rays outputting exactly zero, missingness is
   declared absent from the admitted domain and arrives as sentinels
   with adapters, and out-of-bounds slabs are the extraction's typed
   rejection.
5. **Implementation follows separately** as the tenth registered
   operation under the accepted assembly pattern.

## Alternatives considered

Floating-point averaging was rejected: the exact rational
half-to-even round is computable in integers and keeps the whole
model exact. Emitting the projected axis as a singleton — deferring
removal to squeeze — was rejected: every consumer wants the plane,
and the squeeze convention is already the accepted shape for removed
axes.

## Consequences

The reconstruction arc gains its projection model with exact
fixtures; the implementing increment is mechanical.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The obligations are recorded in the specification and bind the
implementing increment.

## Migration

None; implementation follows as its own increment.

## Supersession

Opens the M6 reconstruction arc; no record is superseded.

## References

- [VOXELIA-ALG-0020 - Intensity projection exact-v1](../../algorithms/VOXELIA-ALG-0020-intensity-projection.md)
- [ADR-0113 - Pixel padding exclusion](ADR-0113-pixel-padding-exclusion.md)
- [ADR-0117 - Multiplanar slice coordinator](ADR-0117-mpr-slice-coordinator.md)

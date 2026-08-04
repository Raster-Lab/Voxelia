---
document_id: "ADR-0065"
title: "Window-level operation"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-EXE-006"
  - "VOX-IMG-001"
  - "VOX-DAT-014"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0065 - Window-level operation

## Context

The exact region extraction operation (`ADR-0064`) exercised the
assembled chain without a numeric model. The first value-producing
operation needs the discipline `ADR-0026` established: a versioned
algorithm specification freezing the exact arithmetic model, rounding
and fixtures before any source. Window-level is the canonical
radiology intensity mapping and its fixtures have named this
operation's tokens since the claim shapes were accepted. This record
was authored and accepted on 2026-08-04 under the project owner's
recorded autonomous delegation, following the owner's explicit
instruction to build the window-level operation.

## Decision

`VoxeliaExecution` gains the window-level operation:

1. **Registration.** Operation token `org.voxelia.op.window-level`,
   semantic version `1.0.0`; implementation token
   `org.voxelia.impl.window-level.cpu`, version `1.0.0`; algorithm
   `window-level-linear/binary64-v1` per `VOXELIA-ALG-0002`, which
   freezes the DICOM-derived linear model, the exact binary64
   evaluation order, `roundTiesToEven` with a modelled clamp, the
   totality of the degenerate unit-width window and the byte-order
   resolution rule.
2. **Frozen parameter schema.** One metadata collection with exactly
   the keys `org.voxelia.op.window-level/center` and `…/width`, each
   a finite binary64 metadata floating-point value, privacy class
   technical; the `parameterDigest` is the registered
   operation-parameters identity of its canonical `VCMJ-1` bytes. A
   width below one is a typed admission rejection, never a clamped or
   substituted value.
3. **Version-one admission.** Stored sample types `uint8` and
   `int16`; exactly one scalar-interpreted component; intensity
   semantic; no value transform — windowing over transformed real
   values requires the transform-composition decision — each
   violation its own typed rejection. Spatial geometry, axes,
   sampling and metadata pass through unchanged because no sample
   moves.
4. **Output assembly.** The full input region is read through the
   budgeted coalescing `StorageReadCoordinator`; the mapped `uint8`
   samples stage into a fresh owned contiguous provider. The output
   descriptor keeps the shape, axes and geometry with the eight-bit
   scalar format in the platform byte order, intensity semantic, no
   value transform and no units — the display range is dimensionless.
   Identity, derivation recipe, provenance record with the graph-node
   parent edge and the frozen execution claim (precision policy
   `org.voxelia.precision.binary64-strict`, approximation `exact`
   because the registered model is the semantic) follow the
   `ADR-0064` pattern exactly, with caller-supplied identifiers,
   instant and software.

## Alternatives considered

Applying the window after the value transform was rejected for
version one: it composes two numeric models and belongs to its own
decision. Admitting every scalar type was rejected: each type is a
registered extension with its own exact-conversion argument, and
`uint8` plus `int16` cover the display and CT cases. Nearest-or-away
rounding was rejected in favour of ties-to-even, matching the
platform's default IEEE-754 attribute and avoiding directional bias.

## Consequences

Voxelia produces its first computed sample values under a frozen
reproducible numeric model, with the complete parameter, identity and
provenance discipline attached.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Samples are decoded under exact bounded rules; parameters are finite
validated values; all read budgets and typed payload-free failures of
the underlying contracts apply; the operation mints no identifiers
and acquires no clock.

## Performance and memory impact

One coordinated full read, one linear mapping pass and one
content-identity hash pass, bounded by the coordinator budget.

## Validation impact

Tests must reproduce every `VOXELIA-ALG-0002` conformance fixture —
both sample types and the degenerate unit-width window — byte for
byte through the full operation, reproduce the parameter digest
independently from the frozen schema, admit input and output records
into a complete graph, prove determinism, and reject a sub-one width,
an unsupported scalar type, a non-scalar component layout, a
non-intensity semantic, a present value transform and an insufficient
read budget, all typed.

## Migration

Implemented in this increment.

## Supersession

This ADR registers the second operation and supersedes nothing.

## References

- [VOXELIA-ALG-0002 - Window-level linear mapping binary64-v1](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [ADR-0026 - Ray axis-aligned bounds intersection](ADR-0026-ray-axis-aligned-bounds-intersection.md)
- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)

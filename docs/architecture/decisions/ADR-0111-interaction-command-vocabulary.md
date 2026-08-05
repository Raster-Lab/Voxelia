---
document_id: "ADR-0111"
title: "Interaction command vocabulary"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-001"
  - "VOX-INT-002"
  - "VOX-INT-004"
  - "VOX-INT-009"
---

# ADR-0111 - Interaction command vocabulary

## Context

The M4 opening assessment found the `VoxeliaInteraction` scaffold
empty while its foundational rows are pure value models, executable
with no external dependency: UI-framework-neutral interaction state
and the ten-concern command vocabulary of `VOX-INT-002`. This record
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation; the M4 assessment itself is
recorded in the progress ledger beside this increment.

## Decision

`VoxeliaInteraction` opens with the closed command vocabulary and its
validated payloads:

1. **UI-framework neutrality.** No member references SwiftUI, AppKit,
   UIKit or RealityKit; commands are `Sendable` `Hashable` values
   over already-validated Voxelia types, discharging `VOX-INT-001`.
2. **The ten concerns, validated payloads.** `InteractionCommand`
   covers window-level (the accepted `GreyscaleWindowFunction`), pan
   (`PanDelta`, finite), zoom (`ZoomFactor`, finite positive), scroll
   (a slice delta), rotate (`RotationAngle`, finite), crosshair
   (`CrosshairState` over one physical `Point3D`, discharging
   `VOX-INT-004` — the space travels with the point), picking
   (`PickTarget`, non-negative viewport coordinates), clipping
   (`ClipBox`, one validated axis-aligned physical-space box with
   strictly ordered bounds in one coordinate space), cropping (the
   accepted `RenderCrop`) and measurement construction.
3. **Measurement construction per the registered model.**
   `MeasurementConstruction` preserves the exact ordered input points
   — non-empty, one shared coordinate space — and carries the derived
   physical length computed once under `VOXELIA-ALG-0010`,
   discharging `VOX-INT-009`; the command side is the closed
   `MeasurementCommand` — begin, add point, complete.
4. **Semantics stay future.** Commands are vocabulary, not behaviour:
   the state machine that consumes them, render-generation coupling
   and viewport synchronisation arrive with their own decisions.

## Alternatives considered

Payload-free command names were rejected: an unvalidated payload
surfaced later would push validation to every consumer. A clip
toggle without a model was rejected as vacuous — the validated box is
a real physical-space value. Computing measurement length lazily was
rejected: the derived result is part of the record per `VOX-INT-009`
and computing once removes drift.

## Consequences

M4 opens on its dependency-free rows; `VOX-INT-001/002/004/009` are
discharged at the vocabulary level, and the DICOMKit-dependent rows
remain gated on the owner's supply-chain approval.

## Affected modules

`VoxeliaInteraction` only; the existing dependency on
`VoxeliaRendering` is used, none added.

## Compatibility impact

Purely additive.

## Security impact

Values carry coordinates, deltas and window parameters only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must construct every command case, reproduce the
`VOXELIA-ALG-0010` fixtures through measurement construction, and
reject non-finite or non-positive payloads, mixed-space or empty
measurements and unordered clip bounds, all typed.

## Migration

Implemented in this increment.

## Supersession

Opens the M4 interaction arc; no record is superseded.

## References

- [VOXELIA-ALG-0010 - Polyline length binary64-v1](../../algorithms/VOXELIA-ALG-0010-polyline-length.md)
- [ADR-0082 - Rendering camera and viewport](ADR-0082-rendering-camera-and-viewport.md)

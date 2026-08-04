---
document_id: "ADR-0082"
title: "Rendering camera and viewport models"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-ERR-001"
  - "VOX-SEC-011"
---

# ADR-0082 - Rendering camera and viewport models

## Context

`VoxeliaRendering` owns the backend-neutral scene, camera, viewport,
layer, transfer-function, quality, request and result models
(`VOX-ARC-008`) and has held only scaffold since M0. The camera and
viewport are the geometric core every other rendering model
references, so the arc opens with them. This record was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

`VoxeliaRendering` gains the first backend-neutral rendering values:

1. **`ViewportSize`.** Positive pixel width and height with an
   inclusive per-dimension ceiling of 16,384 — a hard admission
   bound, not a device claim; device texture limits remain runtime
   capability evidence.
2. **`CameraProjection`.** A closed two-case description:
   `orthographic` with a positive finite view-plane height in world
   units, and `perspective` with a vertical field of view in radians
   strictly between zero and pi. Parameters are admitted at camera
   construction, the owning aggregate, following the axis-sampling
   precedent.
3. **`RenderCamera`.** A validated look-at camera: position and
   target points and an up vector that must share one coordinate
   space; a degenerate view direction (target equal to position) and
   a degenerate up direction (zero, or parallel to the view direction
   with the cross-product magnitude below the smallest normal
   binary64 value — the accepted no-epsilon rule) are typed
   rejections. The camera is a description of intent: no
   float-precision derivation happens here, because `VOX-SPA-004`
   admits rendering-specific float transforms only after verified
   error bounds, which remain a recorded gate.
4. **No wire.** Stable coding for rendering values is owned by a
   future presentation-provenance projection decision.

## Alternatives considered

Reusing platform simd camera types was rejected: the model is
backend-neutral by requirement. Storing a view matrix was rejected:
matrices are derived artefacts whose float error bounds are the gated
`VOX-SPA-004` work; the model stores intent exactly in binary64.

## Consequences

The rendering arc has its geometric core; layers, transfer functions,
quality, requests and results can now reference validated cameras and
viewports.

## Affected modules

`VoxeliaRendering` only; no dependency change.

## Compatibility impact

Purely additive.

## Security impact

Bounded validated values with typed payload-free rejections; no
device or backend detail enters the model.

## Performance and memory impact

Constant-size immutable values.

## Validation impact

Tests must prove the viewport bounds, both projection admissions and
their parameter rejections, the coordinate-space rule, the degenerate
view and up rejections including the near-parallel cross-product
bound, and exact value identity.

## Migration

Implemented in this increment.

## Supersession

This ADR opens the rendering model arc and supersedes nothing.

## References

- [ADR-0043 - Spatial descriptor admission boundary](ADR-0043-spatial-descriptor-admission-boundary.md)
- [ADR-0079 - Metal execution context boundary](ADR-0079-metal-execution-context-boundary.md)

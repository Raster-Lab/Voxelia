---
document_id: "ADR-0096"
title: "Layer compositing Metal kernel"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PLT-011"
  - "VOX-VAL-007"
  - "VOX-ERR-001"
---

# ADR-0096 - Layer compositing Metal kernel

## Context

The registered `VOXELIA-ALG-0009` blend executes on the CPU only,
while the window-level stage already has a measured device path. A
device composite stage needs its own shader family with its own
measured evidence — window-level agreement says nothing about
iterated composite-over accumulation in `float32`. This record was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **A second shader family.** The embedded
   `voxelia_composite_layers` kernel mirrors the registered uniform
   composite-over structure in `float32` over packed equally sized
   `uint8` layers with one demoted opacity per layer, bounded by the
   explicit element count. The shader manifest gains the
   `composite-layers` family at 1.0.0 with its own pinned source
   digest and the `org.voxelia.kernel.composite-layers` token; claims
   remain `binary32-device` with `approximate` status — `MSL` has no
   64-bit floating type, and the device accumulation may contract
   multiplications and additions, which the approximation claim
   honestly covers.
2. **The kernel boundary.** `MetalCompositeKernel` compiles the
   pinned source, exposes the kernel component reference for honest
   claims, and blends through shared-storage buffers with its own
   payload-free error surface — ragged layers and malformed opacity
   lists reject typed before anything touches the device.
3. **Measured evidence.** The differential harness measures the
   device against the frozen binary64 model over deterministic
   seeded-LCG layer stacks — including the 64-layer scene ceiling —
   asserts the one-display-level bound and the 99 percent exact
   floor, anchors the registered fixtures, and prints the measured
   exact count as single-device evidence; a device composite
   operation behind this kernel is the natural next increment.

## Alternatives considered

Reusing the window-level family was rejected: one family, one model —
the blend is a different registered model with different evidence.
Claiming exactness from the window-level measurements was rejected as
unmeasured. Forbidding contraction via compiler flags was rejected:
the claim is `approximate`, and the differential measures the shipped
arithmetic rather than legislating it.

## Consequences

Both registered presentation value models now have digest-pinned,
evidence-carrying device kernels.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive; one manifest family added.

## Security impact

In-kernel thread bound; typed payload-free rejections; digest-pinned
source.

## Performance and memory impact

One packed shared-storage buffer of layer-count times element-count
bytes per blend.

## Validation impact

Tests must verify the pinned digest and manifest rows, anchor the
registered `VOXELIA-ALG-0009` fixtures within one display level,
measure the differential over seeded-LCG stacks including the
64-layer ceiling with counts printed and the 99 percent floor
asserted, prove repeated execution bit-identical, and reject ragged
layers and malformed opacity lists typed.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0080` kernel governance to a second family; no
record is superseded.

## References

- [ADR-0090 - Layer compositing operation](ADR-0090-layer-compositing-operation.md)
- [ADR-0080 - Window-level Metal kernel](ADR-0080-window-level-metal-kernel.md)

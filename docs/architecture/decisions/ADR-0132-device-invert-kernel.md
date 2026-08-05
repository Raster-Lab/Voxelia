---
document_id: "ADR-0132"
title: "Device invert kernel"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PLT-011"
  - "VOX-MTL-016"
  - "VOX-ERR-001"
---

# ADR-0132 - Device invert kernel

## Context

Display inversion is the registered `VOXELIA-ALG-0011` involution —
pure unsigned eight-bit integer arithmetic. Unlike the floating-point
kernel families, an `MSL` implementation of it involves no
approximation at all, so a device path can claim exactness honestly
for the first time. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **The third shader family, integer-exact.** The embedded
   `voxelia_invert_display_u8` kernel computes `255 - x` in unsigned
   eight-bit integer arithmetic; the manifest gains the
   `invert-display` family at 1.0.0 with its pinned digest, the
   `org.voxelia.kernel.invert-display` token, the `exact` precision
   policy and `exact` approximation status — and the manifest note is
   corrected to distinguish floating-point families, which must claim
   approximation, from integer-exact families, which must not.
2. **The kernel boundary.** `MetalInvertKernel` acquires its pipeline
   through the accepted cache, delivers `ADR-0107` telemetry through
   the host-owned sink, and carries its own payload-free error
   surface.
3. **Exactness is asserted, not bounded.** The evidence obligation is
   the exhaustive involution: all 256 input values must equal the
   registered model exactly and double inversion must reproduce the
   input — a single deviation would falsify the exact claim, so the
   suite asserts equality rather than a tolerance.

## Alternatives considered

A float32 implementation was rejected: it would manufacture an
approximation where none exists. Folding into the window family was
rejected: one family, one model.

## Consequences

All three registered display value models have device kernels; the
device invert operation composes next, and the renderer's
invert-stage injection follows with it.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive; one manifest family added and one note corrected.

## Security impact

In-kernel thread bound; typed payload-free rejections; digest-pinned
source.

## Performance and memory impact

One shared-storage dispatch per inversion.

## Validation impact

Tests must verify the pinned digest and manifest rows, assert the
exhaustive 256-value involution exactly equal to the registered model
with double inversion reproducing the input, and prove repeated
execution bit-identical.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0080` kernel governance to a third family; no record
is superseded.

## References

- [VOXELIA-ALG-0011 - Display inversion exact-v1](../../algorithms/VOXELIA-ALG-0011-display-inversion.md)
- [ADR-0096 - Layer compositing Metal kernel](ADR-0096-composite-metal-kernel.md)

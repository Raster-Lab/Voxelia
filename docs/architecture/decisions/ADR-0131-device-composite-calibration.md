---
document_id: "ADR-0131"
title: "Device composite calibration"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-013"
  - "VOX-EXE-002"
  - "VOX-ERR-001"
---

# ADR-0131 - Device composite calibration

## Context

`ADR-0128` widened the registered compositing contract to 1.2.0 with
the calibration equality rule while the device implementation stayed
at the geometry-free 1.1.0 contract, so calibrated scenes could blend
on the CPU but not the device. The blend itself is value arithmetic —
calibration admission and passthrough are host-side — so the device
implementation can serve the full contract without touching the
kernel. This record was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

`MetalCompositeLayersOperation` adopts the `ADR-0128` equality rule
verbatim — every layer's axes and geometry exactly equal, mismatches
the typed `layerCalibrationMismatch` — carries the shared calibration
through to the output descriptor, and claims operation contract 1.2.0
with the implementation advanced to 1.1.0 under the established
widening rule. The kernel, its claims and its measured evidence are
unchanged: the device blends values, the host owns descriptors.

## Alternatives considered

Keeping the device at 1.1.0 was rejected once the gap had no
substance: the claim-what-you-implement rule cuts both ways, and an
implementation that serves the full contract should claim it.

## Consequences

Calibrated scenes blend identically on both backends; the CPU and
device composite recipes differ only in implementation reference and
claim, as designed.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Admission widening under the established version bumps; geometry-free
behaviour byte-identical.

## Security impact

Unchanged budgets; typed payload-free rejections.

## Performance and memory impact

Per-layer descriptor equality checks.

## Validation impact

Tests must blend identically calibrated layers on the real device
with the calibration carried through and both widened versions in the
recipe, and reject a calibration mismatch typed.

## Migration

Implemented in this increment.

## Supersession

Extends `ADR-0098` to the 1.2.0 contract; no record is superseded.

## References

- [ADR-0128 - Composite calibration passthrough](ADR-0128-composite-calibration-passthrough.md)
- [ADR-0098 - Device composite operation](ADR-0098-device-composite-operation.md)

---
document_id: "ADR-0400"
title: "Headless output capabilities"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-HLS-005"
  - "VOX-HLS-006"
  - "VOX-HLS-007"
  - "VOX-HLS-010"
---

# ADR-0400 - Headless output capabilities

## Context

The `ADR-0397` capabilities arc's remaining rows: explicit SDR/HDR
output descriptors where the backend supports them, optional depth and
object-identifier outputs, an optional Apple media-buffer adapter, and
media-encoding isolation. They are one vocabulary: what a headless
output *is*, what a backend *declares it can produce*, and what may
only arrive through an *optional adapter*.

## Decision

1. **Dynamic range is a declared capability, requested explicitly**
   (`VOX-HLS-006`): `OutputDynamicRange` is a closed two-case
   vocabulary (`sdr`, `hdr`); a backend declares its supported set in
   `HeadlessOutputCapabilities`, and a `HeadlessOutputDescriptor`
   requesting a range the backend did not declare refuses typed —
   "where the backend supports them" is an admission check, not a
   silent downgrade.

2. **Auxiliary outputs are a declared, optional selection**
   (`VOX-HLS-007`): `AuxiliaryOutput` is closed (`depth`,
   `objectIdentifier`); the empty selection is valid (optional means
   optional), and requesting an undeclared auxiliary refuses typed —
   never silently omitted from the result, because a missing depth
   buffer a host believed it requested is a measurement error waiting
   downstream.

3. **Media buffers arrive only through an optional adapter protocol**
   (`VOX-HLS-005`): `MediaBufferAdapter` follows the `ADR-0378`
   shape — an associated buffer type, an adapter identity, and a
   conversion from raw pixel bytes plus their descriptor. Core modules
   never name `CVPixelBuffer`; a CoreVideo-backed conformance lives in
   an adapter package when a host wants one, and the stub conformance
   witnesses the boundary.

4. **Media-encoding isolation is enforced, not promised**
   (`VOX-HLS-010`): `AVFoundation` and `VideoToolbox` join the
   prohibited imports for `VoxeliaRendering`, `VoxeliaMetal`,
   `VoxeliaInteraction` and `VoxeliaPhotorealistic`, negative-tested
   both ways. No encoder exists in the tree; when one arrives it
   arrives as an optional module outside these targets, and the gate
   makes the row's "shall be isolated" a CI fact.

## Alternatives considered

### Silent downgrade from HDR to SDR

Rejected — decision 1. A downgrade the host did not choose is a
clinical presentation change made silently.

### Naming CVPixelBuffer in the core protocol

Rejected — decision 3; the associated type keeps CoreVideo out of the
render stack entirely.

## Consequences

M9 arc 2 closes. The distributed-descriptions arc is next.

## Affected modules

`VoxeliaRendering` gains the vocabulary and the adapter protocol; the
import gate widens.

## Compatibility impact

Additive only.

## Security impact

Strengthened: media frameworks cannot enter the render stack unnoticed.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
swift test --filter HeadlessOutputTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the gate widening, the vocabulary, the witness suite
   and the register updates, in the same increment.
2. **Next**: the distributed-descriptions arc.

## Supersession

This record supersedes nothing.

## References

- [ADR-0398 - The headless foundation](ADR-0398-the-headless-foundation.md)
- [ADR-0378 - DICOM adapter capabilities](ADR-0378-dicom-adapter-capabilities.md)
- [ADR-0397 - The M9 queue](ADR-0397-the-m9-queue.md)

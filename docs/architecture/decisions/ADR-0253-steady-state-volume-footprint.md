---
document_id: "ADR-0253"
title: "Steady state volume footprint"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-018"
---

# ADR-0253 - Steady state volume footprint

## Context

`VOX-VS1-018` requires the first vertical slice to demonstrate **no unnecessary
full-volume CPU-to-GPU duplicate after steady state**, declaring `A,T`. It is the
last first-slice row with claimable work.

The plan's §59.2 gives the criterion: "at steady state, the retained complete
decoded sample footprint shall be one full logical volume allocation. Any
additional complete representation shall be identified and justified." §59.4 adds
a leak criterion: retained memory returns to the documented cache baseline after
release.

## The Analysis half: there is no full-volume upload to duplicate

The row asks about a **CPU-to-GPU** duplicate. In the first vertical slice, no
full volume ever reaches the GPU.

`MultiplanarRenderCoordinator` extracts an axis-aligned plane on the CPU and hands
the renderer a **two-dimensional** scene layer; `MetalSliceRenderer` uploads that
slice, not the volume. Neither references `ExactVolumeRenderer`, which is the
direct-volume-rendering path and is not part of this slice. So the quantity the
row is about — a complete second copy of the volume, on the device — **does not
exist because the transfer that would create it does not happen**.

Where a full volume would reach the GPU, `ADR-0081`'s residency model already
answers it: on unified memory both `.automatic` and `.shared` select `.shared`
storage, so the device reads the same allocation and there is no copy to
duplicate. That covers the DVR path when it arrives; it is recorded rather than
claimed here, because this slice does not exercise it.

## The Test half, measured on the owner's real volume

A **fresh process** performing exactly one import of the 899-frame series, so peak
resident size is attributable:

| Quantity | Value |
|---|---|
| Baseline peak before any import | `8 MiB` |
| One full logical volume | `449 MiB` |
| Peak resident after import | `466 MiB` |
| **Ratio to one volume** | **`1.04x`** |

One volume, plus four percent for the process, the frame source's URL map and one
frame's bytes at a time. **No second complete representation exists at any point**,
transient or retained.

The read-retention accounting confirms the same property at the storage boundary:
a full-volume read charges exactly `449 MiB` and releases to exactly `0`, which is
§59.4's leak criterion measured directly rather than inferred from process memory.

## The finding: a suspected transient duplicate does not exist

`CTVolumeStorageBuilder` calls `ContiguousImageStorage(binding:bytes: Array(buffer.bytes))`,
converting the buffer's `ContiguousArray<UInt8>` into an `Array<UInt8>`. That reads
like a full-volume copy, and on a 449 MiB volume it would show as a peak near
`2.0x` while the session still holds the buffer.

**Measurement refutes it: the peak is `1.04x`.** The conversion does not
materialise a second allocation — the buffer is uniquely referenced and not used
after the storage is built, so the bytes move rather than copy.

This is worth recording for two reasons. First, the obvious "optimisation" —
changing `CTVolumeByteBuffer.bytes` to `[UInt8]` to make the conversion trivially
free — would have been a public-API change to a frozen type buying **nothing**.
Second, it is the same shape as `ADR-0249` stage two, where a suspected copy *was*
real and cost `5.4x`. Two suspicions, two measurements, opposite answers. The
reasoning was identical in both cases and was right once; only the measurement
distinguished them.

## Decision

1. **`VOX-VS1-018` is discharged in both declared methods.** Analysis: the first
   slice performs no full-volume CPU-to-GPU transfer, so there is no duplicate to
   avoid, and `ADR-0081`'s residency model covers the case where one would occur.
   Test: measured `1.04x` of one volume on real data, with retention accounting
   returning to zero.
2. **The measurement is taken in a fresh process, and the reason is recorded.**
   `ru_maxrss` is a high-water mark, so measuring inside the long-running
   demonstration harness reported a `0 MiB` delta that says only "this import
   stayed below an earlier peak". Reporting that as evidence of no duplication
   would have been a false conclusion drawn from a real number.
3. **No `[UInt8]` conversion is optimised away**, because measurement shows there
   is nothing to optimise. The suspicion is recorded so a later reader does not
   re-derive it.
4. **§59.2's equality is added as a repository test**, not only a harness run: the
   imported volume's storage byte count equals the layout's exactly, a full-volume
   read charges exactly that, and release returns to zero. Existing retention tests
   use 24-byte fixtures; this one is volume-shaped, which is the case the
   requirement is about.
5. **§59.3's stress cases are not claimed.** A `512x512x1024` volume, repeated
   dataset replacement, repeated open/close cycles and off-screen export during
   interactive rendering are listed there; the last needs the owner-gated
   interactive path, and the others are a benchmark exercise belonging to
   `VOX-VS1-021`'s validation and benchmark reports rather than to this row.
   Cancellation during import is already covered by `ADR-0249`.
6. **No algorithm specification and no oracle.** Nothing numeric is frozen.

## Alternatives considered

### Claim the row by argument alone, since no volume reaches the GPU

Rejected. The row declares `A,T`; the analysis is sound but the `T` half needs a
measurement, and "there is nothing to measure" would be a convenient reading of a
requirement that asks for an allocation trace.

### Change `CTVolumeByteBuffer.bytes` to `[UInt8]`

Rejected on evidence; see the finding. It would be a public-API change to a frozen
type for a copy that does not happen.

### Measure inside the existing demonstration harness

Rejected; see decision 2. The high-water mark makes the number meaningless there.

### Run the §59.3 stress volume now

Deferred, not rejected. `512x512x1024` signed 16-bit is `1 GiB`, and the
interesting question is peak behaviour under memory pressure, which is a benchmark
with its own report rather than a pass/fail row. It belongs with `VOX-VS1-021`.

## Consequences

**Every first-vertical-slice requirement with claimable work is now discharged.**
The rows that remain open are `VOX-VS1-010`'s Demonstration half — owner-gated on
the interactive draw loop — and `VOX-VS1-021`, the validation and benchmark
reports.

## Affected modules

None. `VoxeliaImagingTests` gains one test; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None added. Measured and recorded above: `1.04x` of one volume for a real
899-frame import.

## Validation impact

```text
swift test --filter "CTImportSession"
swift test
swift format lint --strict Tests/VoxeliaImagingTests/CTImportSessionTests.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1024 tests in 191 suites pass. Plus the fresh-process measurement recorded in
`docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`.

## Migration

1. This record and its test.
2. **Open, owner-gated**: `VOX-VS1-010`'s Demonstration half.
3. **Open**: `VOX-VS1-021`, validation and benchmark reports, which is where
   §59.3's stress volume and the tolerance profile belong.

## Supersession

This record supersedes nothing.

## References

- [ADR-0081 - Metal residency strategy](ADR-0081-metal-residency-strategy.md)
- [ADR-0221 - Multiplanar render path](ADR-0221-multiplanar-render-path.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0252 - CPU Metal three-view differential](ADR-0252-cpu-metal-three-view-differential.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

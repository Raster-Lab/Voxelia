---
document_id: "ADR-0264"
title: "Range replacement frame transfer"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
  - "VOX-VS1-001"
  - "VOX-VS1-004"
---

# ADR-0264 - Range replacement frame transfer

## Context

`ADR-0263` measured that the frame transfer's cost depended `9.2x` on which
`Collection<UInt8>` a caller supplied, and proposed making
`CTVolumeByteBuffer.write` `@inlinable` as the one remedy the Swift safety policy
permits.

**That remedy was not needed, and it would not have worked.** `@inlinable` requires a
body to touch only public or `@usableFromInline` members, and `write` mutates `bytes`
and `writtenSlices`, both of which have private setters — so it would have forced
this type to expose the internals its invariants depend on.

The actual remedy is one line.

## Decision

1. **The element-wise byte loop is replaced by a single
   `bytes.replaceSubrange(start..<end, with: frameBytes)`.** Both are memory-safe;
   the difference is that the standard library's implementation is already
   specialised where a generic loop in this module is not.
2. **No pointer API, no `@inlinable`, no encapsulation change, no ABI commitment.**
   The private setters stay private. This is entirely within the accepted safety
   policy.
3. **The measured improvement is `30x` on the transfer stage** and `7.1x` on the
   complete real-data import. See below.
4. **`ADR-0235`'s framing is corrected.** That record's performance section stated
   that the options for the `120 MiB/s` element-wise copy were "an upstream DICOMKit
   decode-into-destination entry point or a governed exception to the safety policy,
   and neither is taken here". **Both were unnecessary.** A standard-library range
   replacement is `30x` faster than the figure it recorded, needs no upstream change
   and no exception. The correction is recorded here rather than by editing that
   record.
5. **`ADR-0261`'s compute-bound conclusion is narrowed.** It found the import
   compute-bound — cold only `1.21x` the warm median — and concluded "effort spent on
   faster file access would buy almost nothing". That was **true of the code it
   measured**, and the code was compute-bound for an avoidable reason. After this
   change the cold/warm ratio is `1.95x`, so file access is now a much larger share
   of a much smaller total.
6. **No algorithm specification and no oracle.** The transfer freezes no numeric
   rule; `VOXELIA-ALG-0050` governs the addressing and is untouched.

## Measurements

Same machine, same release build, same real 899-frame 449 MiB series, 3 warm-ups and
100 measured repetitions under `ADR-0261`'s method.

| Stage | Before (p50) | After (p50) | Improvement |
|---|---:|---:|---:|
| **Total import** | `1.515` s | **`0.214` s** | **`7.1x`** |
| Metadata scan | `0.091` s | `0.086` s | unchanged |
| **Decode and transfer** | `1.417` s | **`0.123` s** | **`11.5x`** |

Transfer throughput: **`3,650 MiB/s`** against the `120 MiB/s` `ADR-0235` recorded —
**`30.4x`**.

The synthetic 512 MiB stress volume, which `ADR-0263` used to isolate the
byte-collection effect:

| Byte collection | Before | After | Improvement |
|---|---:|---:|---:|
| `ContiguousArray<UInt8>` | `13.397` s | **`0.069` s** | **`194x`** |
| `Data` | `1.453` s | **`0.017` s** | **`85x`** |

**The `9.2x` type-dependence is gone**, because the specialisation now happens inside
the standard library rather than failing to happen in this module.

Peak resident is unchanged: `464`–`466 MiB` against 449 MiB, still `1.04x`.

## Correctness was verified before the improvement was claimed

A result this large is a reason for suspicion, not celebration. Three checks, in
increasing strength:

1. **Unit suites**: `CTVolumeByteBuffer`, `CTVolumeBridgeComposition` and
   `CTImportSession` — 25 tests, all passing.
2. **Full suite**: 1067 tests in 198 suites passing.
3. **The definitive check, re-run on real data**: every assembled slice compared
   byte-for-byte against DICOMKit's own frame bytes —
   **`899` of `899` byte-exact, `0` mismatched.**

The `VOX-VS1-014` sample inspections also reproduce their earlier values exactly:
centre `8232` → `40.0` HU, outside the reconstruction circle `0` → `-8192.0` HU,
mid-left `7237` → `-955.0` HU. Three independent voxels across the volume, identical
before and after.

## What this says about the earlier reasoning

`ADR-0235` decision 3 chose the element-wise loop over `withUnsafeBytes`, correctly,
because the pointer API collides with two accepted policies. It then measured the
result and framed the remaining options as upstream change or policy exception.

**The gap was that a third option was never considered: a safe standard-library
operation that does the same job.** The record reasoned carefully about the two
options it had in view and did not ask whether the standard library already solved
it. `ADR-0263` then compounded this by proposing `@inlinable` — a remedy that would
not have compiled without weakening encapsulation.

Both records measured honestly and both drew the conclusion their option set allowed.
The lesson is about the option set: **before accepting a performance cost as inherent
to a safety constraint, check whether the standard library offers a specialised
operation for the same work.** A hand-written loop in a generic context is the slow
path precisely because it cannot specialise, and the stdlib's equivalent already has.

## Alternatives considered

### Make `write` `@inlinable`, as `ADR-0263` proposed

Rejected, and it is worth recording that it was not merely inferior but
**unavailable**: `@inlinable` bodies may only use public or `@usableFromInline`
members, and this one mutates two privately-set properties. Adopting it would have
required exposing the state the type's invariants rest on.

### Take a governed exception for `withUnsafeBytes`

Rejected, and now clearly unnecessary. `replaceSubrange` reaches `3,650 MiB/s`
without one.

### Ask for an upstream DICOMKit decode-into-destination entry point

Still available as an owner option and now much less valuable: the copy it would
remove costs `0.123` s per 449 MiB volume rather than `1.417` s.

### Keep the loop because it is more obviously correct

Rejected. `replaceSubrange` with an exact-length source is the same operation stated
once instead of stepwise, and correctness is established by test rather than by the
code reading like a proof — 899 of 899 slices byte-exact.

## Consequences

The complete real-data import is **`7.1x` faster**, the transfer stage `11.5x`, with
identical output verified byte-for-byte and unchanged memory.

`VOXELIA-BEN-0001`'s figures are superseded by this change and must be re-measured
before it is reviewed; the report is at version 0.2 and unapproved, so no approved
baseline is invalidated.

`ADR-0235`'s stated option set is corrected, and `ADR-0261`'s compute-bound
conclusion is narrowed to the code it measured.

## Affected modules

`VoxeliaImaging` only: one statement in `CTVolumeByteBuffer.write` and its
documentation. No signature, no dependency and no public surface changes.

## Compatibility impact

None. Same signature, same admissions, same output.

## Security impact

Unchanged and still positive. No pointer API is introduced; the destination range is
still checked before the write, and `replaceSubrange` on a checked range cannot
overrun.

## Performance and memory impact

`30.4x` on the transfer stage, `7.1x` on the complete import, memory unchanged.

## Validation impact

```text
swift build && swift test
swift test --filter "CTVolumeByteBuffer|CTVolumeBridge|CTImportSession"
python3 Tools/Scripts/check_swift_safety.py
swift format lint --strict Sources/VoxeliaImaging/Public/CTVolumeByteBuffer.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1067 tests in 198 suites pass, and the real-data byte-exactness check reports 899 of
899.

## Migration

1. This record.
2. **`VOXELIA-BEN-0001` needs re-measuring** before owner review, since its latency
   figures predate this change.
3. **Owner decisions, unchanged**: the six from `ADR-0254` and the two from
   `ADR-0255`.

## Supersession

This record supersedes nothing. It **corrects `ADR-0235`'s option set** and
**narrows `ADR-0261`'s conclusion**, recording both here rather than editing those
records.

## References

- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0261 - Benchmark repetition method](ADR-0261-benchmark-repetition-method.md)
- [ADR-0263 - Stress volume and byte collection cost](ADR-0263-stress-volume-and-byte-collection-cost.md)
- [VOXELIA-ALG-0050 - CT volume sample layout](../../algorithms/VOXELIA-ALG-0050-volume-sample-layout.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

---
document_id: "ADR-0274"
title: "Codec destination API analysis"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-008"
---

# ADR-0274 - Codec destination API analysis

## Context

`VOX-CMP-008` requires that "the decode path shall support caller-provided or reusable
destination storage **where the codec API permits it**". It declares `T,A`.

`ADR-0260` discharged the `T` by building `DecodeDestination` — caller-allocated,
admitted before a decode, reusable, refusing partial and over-long fills. Its decision 9
then deferred the `A` explicitly and honestly:

> Whether any codec accepts a caller-provided destination is not verified, and this
> record says so plainly.

At that point no codec was linked. `ADR-0268` has since declared `J2KSwift 11.0.2` and
built an adapter against it, so the question is now answerable by reading the API rather
than by reasoning about it. This record answers it.

## The reachable surface

Voxelia links two products, `J2KCodec` and `J2K3D`. Their target closure is
`J2KCodec`, `J2K3D`, `J2KCore`, `J2KCodecNEON`, `J2KMetal` and `CompressionFamily`.

`J2KFileFormat` is **not** in that closure, so `decodeAnyFormat(_:)` and
`decodeFile(at:)` are not available here — an earlier count of this surface included
them and was over-broad by two.

`J2KMetal` **is** in the closure, reached transitively through `J2KCodec`'s target
dependencies even though `Package.swift` names no `J2KMetal` product.
`check_prohibited_imports.py` forbids `VoxeliaCompression` from *importing* it, which
remains true and remains the thing that gate governs; linkage and import are different
facts and only the second is constrained.

## The answer: no entry point permits it

**22 public decode entry points** exist in the reachable closure — 14 in `J2KCodec`, 8 in
`J2K3D`, and none in `J2KCore`, `J2KCodecNEON`, `J2KMetal` or `CompressionFamily`.

| Family | Count | Returns |
|---|---:|---|
| `J2KDecoder.decode` / `decodeGPU` / `decodeWithGPUHT` | 9 | a fresh `J2KImage` |
| `decodePartial` / `decodeRegion` / `decodeResolution` / `decodeQuality` | 4 | a fresh `J2KImage` |
| `MJ2VideoToolbox.decode(sampleBuffer:)` | 1 | a fresh `J2KImage` |
| `JP3DDecoder.decode` (four overloads) | 4 | a fresh `JP3DDecoderResult` or `JP3DROIDecoderResult` |
| `JP3DROIDecoder.decode` | 1 | a fresh `JP3DROIDecoderResult` |
| `JP3DMultiSpectralDecoder.decode` | 1 | a fresh `JP3DMultiSpectralVolume` |
| `JP3DProgressiveDecoder.decode` | 1 | `Void`; results arrive by callback as fresh values |
| `JP3DHTJ2K.decodeTile` | 1 | a fresh `[Float]` |

**Every one allocates its own result.** Four independent checks agree:

1. **No decode entry point takes a destination parameter** — no `into:`, `destination:`,
   `buffer:` or `output:` in a destination role.
2. **The package declares no public `inout` parameter at all**, on any function.
3. **`JP3DDecoderResult` has `let` storage and no public initialiser**, so a caller
   cannot even preallocate the container to be filled. `J2KImage` and `J2KVolume` do have
   public initialisers, but no decoder accepts one, so the ability to construct them
   buys nothing.
4. **`J2KImageBuffer` is a red herring.** It is mutable and exposes
   `withUnsafeMutableBytes`, which makes it look like the intended reuse type. It is
   referenced nowhere outside its own file and a documentation cross-reference: no
   function in the reachable closure accepts one. It is a container offered to callers,
   not a decode destination.

**A near-miss worth recording.** A name-based search for a buffer parameter matched
`decode(sampleBuffer: CMSampleBuffer)`, which takes an *input* video buffer and returns a
fresh image. Searching by parameter name finds inputs; the enumeration has to go by
parameter **role**. My first pass over this surface used a single-line pattern and
reported zero matches, and the second reported one — the discrepancy is what prompted
checking, and the match was spurious. Both conclusions happened to be right; only the
second was arrived at reliably.

## What the gap costs, measured

Because no destination can be supplied, `J2KVolumeAdapter` must copy the codec's owned
`Data` into a `ContiguousArray<UInt8>` at
[`J2KVolumeAdapter.swift:191`](../../../Sources/VoxeliaCompression/Public/J2KVolumeAdapter.swift).
That copy is what a destination API would eliminate, so its cost is what
`VOX-CMP-008`'s unmet conditional is worth:

| Volume | Copy time | Throughput | Peak resident increase |
|---:|---:|---:|---:|
| 32 MiB | `0.006` s | 5,314 MiB/s | `32.1` MiB |
| 64 MiB | `0.008` s | 7,833 MiB/s | `64.0` MiB |
| 128 MiB | `0.012` s | 10,879 MiB/s | `128.0` MiB |
| 256 MiB | `0.020` s | 12,518 MiB/s | `256.0` MiB |
| 449 MiB | `0.035` s | — | — |

**The missing capability costs memory, not time.** The 449 MiB copy is `0.035` s against
the `6.23` s HTJ2K full decode `VOXELIA-BEN-0002` measured — **0.6 per cent**. But the
resident increase is **exactly the volume**, every time: a full transient duplicate.

That inverts the expectation this project had reason to hold. `ADR-0264` found a
thirtyfold win by replacing a hand-written byte loop with a standard-library range
replacement, so a byte copy in a hot path looked like a place to find time again. It is
not the same problem: this copy is *already* the standard library's path and runs at
memory bandwidth. There is no time to recover here — only an allocation.

## Decision

1. **`VOX-CMP-008`'s `A` is discharged with the answer "the codec API does not permit
   it".** The row's conditional is reported as **unmet by the pinned codec**, which is a
   discharge of the analysis, not of the capability.
2. **`DecodeDestination` stays exactly as `ADR-0260` built it.** It is not dead code: it
   serves callers who own their storage and want a decode admitted against it, and it is
   the piece that would be wired through on the day a codec offers a destination. What
   changes is that the record now says *why* nothing is wired through it.
3. **The cost of the gap is recorded as a measurement, not an adjective**, because
   "an extra copy" and "a full duplicate of the volume in peak memory, for 0.6 per cent
   of the decode time" support different decisions.
4. **Both declared dependencies behave the same way, and that is a pattern rather than a
   coincidence.** `ADR-0235` established that DICOMKit's `pixelData()` and
   `frameData(at:)` both return an owned `Data` with no caller-destination entry point.
   Two for two, and any future dependency should be assumed to allocate until its API is
   read.
5. **No algorithm specification, no oracle, and no product change.** This increment reads
   an API and measures a copy.

## An option recorded and deliberately not taken

`DecodedSamples.bytes` is a `ContiguousArray<UInt8>`. If it were a `Data`, the adapter
could retain the codec's buffer under copy-on-write and the duplicate would disappear
entirely — no codec destination API required, and the full volume of peak memory
measured above recovered.

It is not done here for two reasons, and neither is that it would not work:

- It puts **Foundation in `VoxeliaCompression`'s public API**, which is a module-boundary
  question `ADR-0256` owns rather than something to settle inside an analysis increment.
- It changes a type **accepted by `ADR-0259`**, so it needs its own record and its own
  consideration of what else holds `DecodedSamples`.

Recorded with its measured benefit so the decision is available rather than rediscovered.

## Alternatives considered

### Report the row as satisfied because `DecodeDestination` exists

Rejected. The requirement is conditional on the codec API, and reading the API is the
whole task. Declaring satisfaction from Voxelia-side machinery alone would answer a
question nobody asked.

### Report the row as blocked or not applicable

Rejected. "Analysed, and the answer is no" is a discharge; the analysis was the
deliverable. Marking it blocked would imply work outstanding that no longer is.

### Ask the owner to add a destination API to `J2KSwift`

Not taken as this record's action, though the owner owns that library. The measurement
says the benefit is peak memory rather than throughput, and the `DecodedSamples` change
above would capture the same benefit **without** a dependency change. Raising a
dependency request whose benefit is obtainable locally would be the wrong order.

### Measure the copy on the owner's real data instead of a synthetic buffer

Rejected as unnecessary. A copy's cost depends on length and memory bandwidth, not on
content, and using synthetic buffers keeps the measurement free of the patient-data path
entirely.

## Consequences

`VOX-CMP-008` is fully discharged. **Every M5 compression requirement row is now
discharged in both halves**: `002`, `003`, `004`, `005`, `006` (`I,T`), `007`, `008`,
`009`, `010`, `011`, `012` (`T`), `013`, `014`.

**The compression arc's only remaining items are the two owner Reviews**, for
`VOX-CMP-006` and `VOX-CMP-012`. No implementation work remains on it.

A quantified option for removing a full-volume transient allocation is on the record, and
a second data point establishes that this project's dependencies allocate their outputs
by default.

## Affected modules

None. No source changes.

## Compatibility impact

None.

## Security impact

None. The copy is bounded by the length the adapter already validated against the
component's own dimensions and bit depth.

## Performance and memory impact

None added. Measured and reported above: the unavoidable copy costs `0.6` per cent of a
full decode in time and one full duplicate of the volume in peak resident memory.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1116 tests in 202 suites pass, unchanged — this increment adds no code. The API
enumeration is a read of the resolved checkout at the pinned version; the copy
measurements are a recorded harness run over synthetic buffers, touching no patient
data.

## Migration

1. This record.
2. **Next**: the compression arc has no implementation work left. The interactive
   draw-loop arc is next and needs its own architectural record before any code —
   target shape, platform surface, `RenderGeneration` wiring (which ends `ADR-0122`
   decision 3's deferral), and what evidence discharges a Demonstration half.
3. **Owner**: `VOX-CMP-006`'s and `VOX-CMP-012`'s Reviews, the five `J2KSwift` items from
   `ADR-0272` and `ADR-0273`, and the five decisions already open.

## Supersession

This record supersedes nothing. It **answers the question `ADR-0260` decision 9
deferred**, and confirms `ADR-0235`'s finding generalises to a second dependency.
Neither record is edited.

## References

- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0256 - Compression module boundary](ADR-0256-compression-module-boundary.md)
- [ADR-0259 - Cancellable decode session](ADR-0259-cancellable-decode-session.md)
- [ADR-0260 - Compressed scope and destination](ADR-0260-compressed-scope-and-destination.md)
- [ADR-0264 - Range replacement frame transfer](ADR-0264-range-replacement-frame-transfer.md)
- [ADR-0268 - J2K volume adapter](ADR-0268-j2k-volume-adapter.md)
- [VOXELIA-BEN-0002 - Compression benchmark](../../benchmarks/VOXELIA-BEN-0002-compression-benchmark.md)

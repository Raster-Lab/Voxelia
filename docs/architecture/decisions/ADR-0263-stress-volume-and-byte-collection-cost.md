---
document_id: "ADR-0263"
title: "Stress volume and byte collection cost"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-018"
  - "VOX-VS1-021"
---

# ADR-0263 - Stress volume and byte collection cost

## Context

Plan §59.3 lists six memory stress cases, and `ADR-0253` recorded them as not
claimed. This record assesses all six, runs the one that was outstanding and
runnable, and reports a performance finding that came out of it.

## An arithmetic correction first

**The stress volume is 512 MiB, not the "~1 GiB" an earlier ledger entry stated.**
`512 x 512 x 1024` samples at two bytes is `536,870,912` bytes — exactly 512 MiB, and
only `1.14x` the owner's real 449 MiB series. The earlier figure was wrong by a
factor of two and the case is a more modest step up than it implied.

## The six cases, assessed

| §59.3 case | Status |
|---|---|
| `512x512x1024` signed 16-bit volume | **Run here** (synthetic; see below) |
| Rapid three-view interaction | **Owner-gated** — needs the interactive draw loop |
| Repeated dataset replacement | **Substantially covered** by `ADR-0261` |
| Cancellation during import | **Covered** by `ADR-0249` |
| Repeated open/close cycles | **Substantially covered** by `ADR-0261` |
| Off-screen export during interactive rendering | **Owner-gated** — needs the interactive path |

Two of the six were already covered and had not been credited. `ADR-0261`'s
repetition method ran **104 sequential imports in one process**, each allocating a
449 MiB volume, with peak resident unchanged at `467 MiB` throughout — which is what
"repeated dataset replacement" and "repeated open/close cycles" are asking about. The
measurement was taken for a latency distribution and covers these cases as a
by-product.

"Substantially" rather than "fully": both plan cases arguably also want a *published*
object released between cycles, and `ADR-0261`'s loop published nothing. The
distinction is recorded rather than smoothed over.

## The stress volume: real data cannot supply it, and that is itself a finding

The owner's corpus was searched for a series with at least 1,024 instances. **One
exists — 2,580 instances** — and importing it is **refused with
`geometryRejected`**.

That refusal is informative rather than a dead end. The series assembled as a
*single* series by identity, so it is not a grouping problem; its geometry is
irregular at `exact` tolerance. So **the largest real series in the corpus that
Voxelia can admit is the 899-slice one already used**, and §59.3's stress case cannot
be sourced from real data until the geometry-tolerance owner gate is settled. That
links a benchmark case to a gate nobody had connected to it.

The case was therefore run **synthetically and is labelled synthetic**: 1,024 frames
of `512x512` **`int16`**, regular half-millimetre spacing, imported through the real
`CTImportSession`.

| Quantity | Value |
|---|---|
| Volume | `512x512x1024` `int16`, 512 MiB |
| Geometry verdict | `representable` at `exact` tolerance |
| Peak resident | `523 MiB` |
| **Ratio to one volume** | **`1.02x`** |

**The footprint property holds at scale**, and this run also exercises **signed**
samples end to end — the owner's scanner writes `uint16`, so `int16` had only ever
been exercised by fixtures.

## The finding: the byte-collection type costs 9.2x, and it refines `ADR-0235`'s measurement

The first synthetic run took `13.397` s for 512 MiB **with no file I/O at all**,
against `1.841` s for 449 MiB read from disk in `VOXELIA-BEN-0001`. A synthetic run
being seven times slower per byte than one that reads files is not a plausible
result, so it was investigated rather than reported.

`CTImportSession` is generic over `Bytes: Collection<UInt8>` — a signature
`ADR-0259`'s predecessor introduced precisely to avoid a forced `Array` copy. The
real DICOM path supplies `Data`; the synthetic run naturally supplied
`ContiguousArray`. Running the **same import twice, differing only in that type**:

| Byte collection | Elapsed | Peak |
|---|---:|---:|
| `ContiguousArray<UInt8>` | `13.397` s | `523 MiB` |
| `Data` | **`1.453` s** | `525 MiB` |

**A `9.2x` difference from the caller's choice of conforming type**, with identical
code, identical volume and an identical element-wise copy.

**This refines an accepted measurement.** `ADR-0235`'s performance section recorded
the element-wise transfer at "about 120 MiB/s" and framed the options as an upstream
DICOMKit entry point or a governed safety-policy exception. That framing attributed
the cost to element-wise writing. **Part of it is not**: with `Data` the same
element-wise loop moves 512 MiB in `1.453` s — about `352 MiB/s`, nearly three times
`ADR-0235`'s figure — so a large share of what looked like an inherent copy cost is
generic non-specialisation of the byte iteration.

**No fix is applied here, and the reason is a real constraint rather than caution.**
The obvious remedy is a contiguous fast path via `withContiguousStorageIfAvailable`,
which both types support — and it yields an `UnsafeBufferPointer`, which
`-strict-memory-safety` diagnoses and the Swift safety policy forbids outright. The
available safe remedy is making the write `@inlinable` so the loop specialises at the
call site, which changes a public API's inlining contract and deserves its own record
rather than a footnote in a stress-test increment.

## Decision

1. **The `512x512x1024` stress case is run and recorded as synthetic**, with the
   reason real data cannot serve it stated rather than left implicit.
2. **The footprint property is confirmed at 512 MiB**: `1.02x` of one volume.
3. **Two of §59.3's six cases are credited to `ADR-0261`**, with "substantially"
   rather than "fully" and the residual difference named.
4. **Two cases remain owner-gated** on the interactive draw loop and are not claimed.
5. **The byte-collection cost is recorded as a measured finding, not fixed.** A
   caller passing `ContiguousArray` where `Data` would do pays `9.2x`, and nothing
   in the API says so.
6. **`ADR-0235`'s 120 MiB/s figure is refined, not contradicted.** It was correct for
   the path measured; this record shows the same loop reaching `352 MiB/s` with a
   different conforming type, so the cost is not wholly inherent to element-wise
   writing.
7. **No algorithm specification and no oracle.** Nothing numeric is frozen.

## Alternatives considered

### Report the 13.4 s figure as the stress result

Rejected, and it would have been easy: the number was real and the run completed.
Reporting it without investigating a seven-fold anomaly against an existing
measurement would have published a figure that says more about a harness's choice of
collection type than about Voxelia.

### Apply the `withContiguousStorageIfAvailable` fast path now

Rejected on policy, not preference; see above. It produces an
`UnsafeBufferPointer`, and the safety policy admits no exception for a performance
gain.

### Make the write `@inlinable` in this increment

Deferred. It is the available safe remedy and it changes a public API's inlining
contract, which belongs in a record about that decision rather than inside a stress
test.

### Synthesise a volume large enough to stress memory pressure, say 8 GiB

Rejected. §59.3 names a specific size, and exceeding it would measure the machine's
swap behaviour rather than Voxelia's footprint discipline.

### Treat the 2,580-instance refusal as a defect

Rejected. `exact` tolerance rejecting an irregular series is the accepted behaviour
`ADR-0229` chose deliberately, and `ADR-0234` characterised. The finding is that it
blocks a benchmark case, not that it is wrong.

## Consequences

Plan §59.3 is fully assessed: one case run, two credited to existing evidence, two
owner-gated, one already covered.

**A performance finding is on the table that no requirement asked for**: the import's
throughput depends `9.2x` on a caller's collection type, and `ADR-0235`'s recorded
figure understates what the same code achieves.

The geometry-tolerance owner gate now has one more consequence attached to it: it
blocks sourcing the stress case from real data.

## Affected modules

None. Assessment and measurement only; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

Measured and reported above. Nothing changed.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The measurements are recorded harness runs; no repository test reads the owner's
data.

## Migration

1. This record.
2. **Its own record**: whether `CTVolumeByteBuffer.write` becomes `@inlinable` so the
   byte loop specialises at the call site, with `ADR-0235`'s figure re-measured
   afterwards.
3. **Owner decisions, unchanged**: the six from `ADR-0254` and the two from
   `ADR-0255`. The geometry tolerance now additionally blocks a real-data stress
   volume.

## Supersession

This record supersedes nothing. It **refines `ADR-0235`'s performance measurement**
without contradicting it, recording the refinement here rather than editing that
record.

## References

- [ADR-0229 - CT series geometry validation](ADR-0229-ct-series-geometry-validation.md)
- [ADR-0234 - Geometry tolerance source assessment](ADR-0234-geometry-tolerance-source-assessment.md)
- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0253 - Steady state volume footprint](ADR-0253-steady-state-volume-footprint.md)
- [ADR-0261 - Benchmark repetition method](ADR-0261-benchmark-repetition-method.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

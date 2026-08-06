---
document_id: "ADR-0271"
title: "Compression benchmark and random access"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-003"
  - "VOX-CMP-004"
  - "VOX-CMP-014"
---

# ADR-0271 - Compression benchmark and random access

## Context

`VOX-CMP-014` requires compression benchmarks reporting ratio, encode time, decode
time, random-access cost, memory use and output equality. `ADR-0269` measured four of
those six while evaluating JP3D and HTJ2K. This record adds the two it did not —
**random-access cost and memory** — and reports the result in
`VOXELIA-BEN-0002`.

## The finding: random access reverses the practical conclusion, not the measurement

`ADR-0269` found JP3D and HTJ2K poor **whole-volume caches**: full decode of the
449 MiB volume takes `6.2` to `9.9` s against `0.216` s to re-import from the original
DICOM, so the cache is 29 to 46 times slower than the thing it caches.

That measurement stands. **What changes is what it implies**, because a viewer rarely
wants a whole volume — it wants planes.

HTJ2K region decode, 256-slice volume:

| Request | Time | Voxels | Speedup vs full decode |
|---|---:|---:|---:|
| **One axial plane** | **`0.014` s** | 0.4 % | **`115.6x`** |
| 128-cube brick | `0.247` s | 3.1 % | `6.6x` |
| 64-slice slab | `0.314` s | 25.0 % | `5.2x` |

**Fourteen milliseconds for one axial plane, from a store holding 55 per cent less
data than the uncompressed volume.**

So the same artefact is a poor product under one access pattern and a good one under
another. `ADR-0269` explicitly named this as a condition that would change its
conclusion — "a compressed resident representation with region decode ... is a
different proposition from a whole-volume cache" — and the condition holds. That
record is **qualified rather than corrected**: its numbers and its whole-volume
verdict are unchanged.

## Decision

1. **`VOX-CMP-014` is discharged** by `VOXELIA-BEN-0002`, reporting all six required
   metrics.
2. **The random-access result is recorded as qualifying `ADR-0269`, not overturning
   it.** Whole-volume caching remains a poor trade; random-access serving is a good
   one. Both statements are true of the same measurements and neither is dropped.
3. **Tile geometry, not voxel count, sets random-access cost.** A plane touching 0.4
   per cent of voxels costs 4 of 64 tiles; a brick touching 3.1 per cent costs 8. Any
   future use of region decode should align requests to tile boundaries, and this is
   recorded because the naive expectation — cost proportional to voxels — is wrong by
   an order of magnitude.
4. **Memory is measured in a clean process**, because a combined run retains several
   encodes and decodes and its peak is a harness artefact. Encoding costs roughly
   **4.3x the volume** in working set; full decode adds about **2.1x**; **region
   decode adds nothing measurable**.
5. **Lossy modes are deliberately not measured.** `lossy(psnr:)` and
   `targetBitrate(_:)` exist, no requirement asks for lossy diagnostic data, and
   benchmarking them here would invite reading the numbers as an endorsement.
6. **No algorithm specification and no oracle.** These are measurements.

## What this implies for `VOX-CMP-003`, recorded and not acted on

`VOX-CMP-003` requires support for compressed sources, slices, slabs and **bricks**,
and `ADR-0260` built the scope vocabulary for all four without a codec behind it.
These figures show the brick case is not merely expressible but *cheap* — and that a
brick-shaped request costs what its tile coverage costs, not what its voxel count
suggests.

That is a design input for whichever increment wires scopes to region decode. It is
not acted on here, because this record's job is to measure.

## Alternatives considered

### Report random access as simply reversing `ADR-0269`

Rejected. The whole-volume figures are correct and remain the right answer to the
question that record asked. Presenting the new measurement as a reversal would imply
the earlier one was wrong, when what differed was the access pattern.

### Measure random access on the full 899-slice volume

Deferred. The 256-slice measurement already shows a 115x gap, and the tile-geometry
explanation predicts the plane cost stays roughly constant as the volume lengthens
because a plane always touches one tile layer. Confirming that prediction is worth
doing when region decode is actually wired up, against the real access pattern.

### Report the contaminated memory peaks from the combined run

Rejected. `1,809 MiB` was real and meaningless — the harness held four encodes and
their decodes. The same discipline `ADR-0265` applied to a cold-cache figure applies
here.

### Benchmark the lossy modes for completeness

Rejected; see decision 5.

## Consequences

`VOX-CMP-014` is discharged. Compression rows now stand at `002`, `003`, `004`,
`005`, `007`, `009`, `010`, `012` (`T`), `013`, `014`, and `008` (`T`).

**Remaining: `VOX-CMP-006` and `VOX-CMP-011`**, plus `008`'s `A` half and `012`'s
Review.

A design input for region-decode wiring is on the record, and a naive cost model for
it is pre-emptively corrected.

## Affected modules

None. Measurement and reporting only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None added; measured and reported in `VOXELIA-BEN-0002`.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

Measurements are recorded harness runs against the owner's data; no repository test
reads that path.

## Migration

1. This record and `VOXELIA-BEN-0002`.
2. **Next**: `VOX-CMP-006`, which should also answer `ADR-0269`'s `levelsZ` question
   and is the row where interoperability with other implementations belongs; then
   `VOX-CMP-011`'s adversarial work last.
3. **Owner**: the five open decisions, plus `VOX-CMP-012`'s Review.

## Supersession

This record supersedes nothing. It **qualifies `ADR-0269`'s practical conclusion**
without altering its measurements, recording the qualification here rather than
editing that record.

## References

- [VOXELIA-BEN-0002 - Compression benchmark](../../benchmarks/VOXELIA-BEN-0002-compression-benchmark.md)
- [ADR-0260 - Compressed scope and destination](ADR-0260-compressed-scope-and-destination.md)
- [ADR-0261 - Benchmark repetition method](ADR-0261-benchmark-repetition-method.md)
- [ADR-0265 - Cold cache measurement correction](ADR-0265-cold-cache-measurement-correction.md)
- [ADR-0269 - JP3D and HTJ2K evaluation](ADR-0269-jp3d-and-htj2k-evaluation.md)

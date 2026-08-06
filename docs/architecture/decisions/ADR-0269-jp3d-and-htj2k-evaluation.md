---
document_id: "ADR-0269"
title: "JP3D and HTJ2K evaluation"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-004"
  - "VOX-CMP-005"
  - "VOX-CMP-006"
---

# ADR-0269 - JP3D and HTJ2K evaluation

## Context

Two rows, both `A,T`, both asking for an evaluation rather than an implementation:

- `VOX-CMP-004`: lossless JPEG 2000 Part 10 three-dimensional compression **shall be
  evaluated as an internal volume-cache representation**.
- `VOX-CMP-005`: HTJ2K **shall be evaluated** for high-throughput lossless decoding
  and encoding.

An earlier note said these would need test codestreams the project does not have.
**That was wrong** — `J2KSwift` ships `JP3DEncoder`, so the right evaluation input is
the owner's own 449 MiB CT volume rather than a borrowed fixture. The question both
rows ask is about *Voxelia's* data.

## Measurements

Real 899-frame `512x512` `uint16` CT volume, 449 MiB, imported through
`CTImportSession` and encoded from its actual samples. Release build, Apple M5.

| Mode | Encoded | Ratio | Encode | Decode | Byte-exact round trip |
|---|---:|---:|---:|---:|:---:|
| JP3D lossless | 195 MiB | **2.30:1** | `15.47` s (29 MiB/s) | `9.93` s (45 MiB/s) | **yes** |
| HTJ2K lossless | 203 MiB | **2.21:1** | **`3.45` s (130 MiB/s)** | **`6.23` s (72 MiB/s)** | **yes** |

Both report `isLossless: true`, and in both cases that flag was **verified rather
than trusted**: the decoded bytes were compared against the source volume and matched
exactly. A lossless claim that is only a flag is not evidence.

`ADR-0268`'s adapter admitted both decodes — its first exposure to real codec output
rather than constructed fixtures.

## `VOX-CMP-004`: JP3D is not a viable internal volume cache

A cache exists to make re-access faster than regenerating the thing. Measured against
the path it would replace:

| Getting the volume back | Time |
|---|---:|
| Re-import from the original DICOM (warm median, `ADR-0265`) | **`0.216` s** |
| Decode from a JP3D cache | `9.93` s — **46x slower** |
| Decode from an HTJ2K cache | `6.23` s — **29x slower** |

**A cache that is twenty-nine to forty-six times slower than re-reading the source is
not a cache.** It saves 55–57 per cent of disk and costs an order of magnitude and a
half in read latency, which is the wrong trade for a workstation with fast local
storage and enough memory to hold the volume.

So the evaluation `VOX-CMP-004` asks for returns **no**, and the row is discharged by
that answer. "Evaluated" permits a negative result, and reporting a positive one here
would have required ignoring the comparison that matters.

**The conditions under which this would flip are stated rather than left implicit**,
because the conclusion is about this workload and not about JP3D:

- If the source instances were themselves compressed, a decode would be paid either
  way and the comparison changes entirely.
- If storage were remote or slow, transferring 55 per cent less data could dominate
  the decode cost.
- If volumes did not fit in memory, a compressed resident representation with
  region decode — which `JP3DDecoder.decode(_:region:)` supports — is a different
  proposition from a whole-volume cache.

## `VOX-CMP-005`: HTJ2K's high-throughput claim holds

Against JP3D on identical input: **`4.5x` faster to encode**, **`1.6x` faster to
decode**, for **4 per cent** worse ratio. At 128 slices the encode advantage measured
`4.9x` and the decode advantage `2.2x`, so the direction is consistent across sizes.

The row asks whether HTJ2K delivers high-throughput lossless coding, and on real CT
data it does. **Where a compressed lossless representation is wanted at all — archival,
transmission, or the memory-constrained case above — HTJ2K is the mode to use**, and
the 4 per cent ratio cost is not close to material against a `4.5x` encode saving.

That conclusion stands independently of `VOX-CMP-004`'s negative one: HTJ2K is better
than JP3D at the same job, and both are still poor whole-volume caches for this
workload.

## The evaluation checked that it was not under-selling JP3D

`JP3DEncoderConfiguration` defaults `levelsZ` to **1**, which would largely disable
the inter-slice decorrelation that is a three-dimensional codec's whole advantage over
a stack of two-dimensional ones. Evaluating JP3D at that default risked measuring it
with its main feature turned down.

Re-running at `levelsZ: 3` produced **byte-identical encoded sizes** — `2.53:1` for
JP3D and `2.41:1` for HTJ2K at both settings, on the same 128-slice input.

Identical output size means the parameter is not changing the encode. Whether it is
unimplemented, overridden by `zDeltaMode: .auto`, or genuinely without benefit on this
data **cannot be distinguished from outside the library**, and this record does not
guess. It is recorded as a question for `VOX-CMP-006`, whose subject is exactly
documenting actual codec behaviour.

What matters for these two rows is that the check was made: the evaluation is not
penalising JP3D for a switch left off.

## The timings are single measurements, and that is stated

Decode times varied by up to roughly **2x between runs** of the same configuration —
JP3D at 128 slices measured `1.73` s and `2.33` s on separate runs. These are single
measurements without warm-up or repetition, and `ADR-0261` established that a single
run is a reference point rather than a distribution.

- **The ratios are exact**, being byte counts, and are unaffected.
- **The HTJ2K encode advantage (`4.5x`) is far larger than the observed variance** and
  survives it comfortably.
- **The decode advantage (`1.6x`) is closer to the noise** and should be treated as
  directional rather than precise.
- **The cache conclusion is robust**: it rests on a 29–46x gap, which no plausible
  variance closes.

Applying `ADR-0261`'s hundred-repetition method here would mean roughly half an hour
of encoding for a conclusion the current spread already supports, so it is recorded as
available rather than performed.

## Decision

1. **`VOX-CMP-004` is discharged with a negative evaluation.** Lossless JP3D is not a
   viable internal volume-cache representation for this workload, on the measured
   ground that decoding it is 46x slower than re-importing the source.
2. **`VOX-CMP-005` is discharged positively.** HTJ2K delivers high-throughput lossless
   coding on real CT: `4.5x` encode and `1.6x` decode over JP3D for 4 per cent ratio.
3. **Losslessness is verified by byte-exact comparison, never by the codec's flag.**
4. **The conditions that would reverse decision 1 are recorded**, so a later reader
   does not mistake a workload-specific answer for a property of the format.
5. **`levelsZ` having no measurable effect is referred to `VOX-CMP-006`** rather than
   explained. It is a statement about the library that only that row is chartered to
   make.
6. **No algorithm specification and no oracle.** Nothing numeric is frozen; these are
   measurements.

## Alternatives considered

### Report JP3D as viable because 2.3:1 lossless is a good ratio

Rejected. The ratio is respectable and irrelevant to the question the row asks, which
is about a *cache*. Reporting the flattering half of a measurement would be the
failure this project's evidence discipline exists to prevent.

### Evaluate against synthetic volumes

Rejected. Compression ratio depends entirely on the data, and synthetic volumes would
have produced a number about the generator.

### Use the shipped `ct512_*.j2k` fixtures instead

Rejected as the primary input, though they remain useful for `VOX-CMP-006`: they are
someone else's data at someone else's settings, and the rows ask about Voxelia's
volumes.

### Run the full `ADR-0261` repetition method

Deferred; see above. Half an hour of encoding to tighten figures whose conclusion the
spread already supports is not proportionate, and the record says the method is
available rather than pretending the numbers are distributions.

### Test `region:` decode now, since it bears on the memory-constrained case

Deferred to `VOX-CMP-003`'s brick work, which is where region decode belongs. Noted
here because it is the one configuration that could make a compressed resident
representation attractive.

## Consequences

Two more compression rows discharged: `002`, `003`, `004`, `005`, `007`, `009`, `010`,
`013`, and `008` in `T`. Remaining: `006`, `011`, `012`, `014`, and `008`'s `A` half.

`ADR-0268`'s adapter is validated against real codec output.

A question about `levelsZ` is on `VOX-CMP-006`'s docket.

## Affected modules

None. Evaluation only; no source changed.

## Compatibility impact

None.

## Security impact

None. Both decodes ran with `tolerateErrors: false` per `ADR-0268`.

## Performance and memory impact

None added; measured and reported.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The measurements are recorded harness runs against the owner's data; no repository
test reads that path.

## Migration

1. This record.
2. **Next**: `VOX-CMP-012` (original preservation) and `VOX-CMP-014` (benchmarks),
   neither of which needs new codec capability; then `VOX-CMP-006`, which should
   answer the `levelsZ` question; then `VOX-CMP-011`'s adversarial work last.
3. **Owner decisions still open**: the remaining five.

## Supersession

This record supersedes nothing.

## References

- [ADR-0261 - Benchmark repetition method](ADR-0261-benchmark-repetition-method.md)
- [ADR-0265 - Cold cache measurement correction](ADR-0265-cold-cache-measurement-correction.md)
- [ADR-0267 - Direct codec declaration](ADR-0267-direct-codec-declaration.md)
- [ADR-0268 - J2K volume adapter](ADR-0268-j2k-volume-adapter.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

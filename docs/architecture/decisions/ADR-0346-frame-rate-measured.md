---
document_id: "ADR-0346"
title: "Frame rate measured"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PER-004"
---

# ADR-0346 - Frame rate measured

## Context

`VOX-PER-004` — conventional 512-cubed volume rendering targeting 30-60 frames
per second, P1, `T,D`, M6 — was characterised by `ADR-0330` as unmeasured, with
the four constraints a valid measurement needs fixed in advance. All four are
now satisfiable: `ADR-0338` decision 1 named the reference device, and
`ADR-0343`'s levels supply the quality profiles. This record takes the
measurement and records its verdict.

## Decision

1. **The measurement is taken under all four `ADR-0330` constraints** — the
   named device (`Mac17,4`, Apple M5), the row's own 512-cubed case, a clean
   release-build process (`voxelia-benchmark --frames`, per `ADR-0271`
   decision 4), and the quality labelled: full-precision execution in every
   frame, profiled across representation levels 0, 1 and 2.

2. **The result is recorded as a miss, not softened**: 0.068 frames per second
   at full resolution, 0.194 at level 1, 0.415 at level 2 — roughly 440x from
   the target's lower bound. `VOXELIA-BEN-0003` carries the raw values, the
   attribution (CPU-exact reference renderer, no device DVR kernel, per-frame
   full read, no acceleration engaged) and the conditions that would reverse
   the conclusion (a device DVR kernel with resident textures under the same
   claims discipline).

3. **`VOX-PER-004`'s `T` is discharged by the measurement, and the target
   standing is the owner's release matter.** The row targets 30-60 frames per
   second "depending on quality profile and reference hardware capability";
   the measurement now exists against the named hardware and labelled
   profiles, which is what `T` verifies. Whether version one ships with the
   target missed — the honest reading of a reference-correctness architecture
   whose device DVR kernel is future work — is a release acceptance judgement,
   surfaced to the owner with the pending Reviews rather than decided here.

4. **No performance work is started on this row's authority.** A device DVR
   kernel is a designed arc of its own; producing one under a measurement
   record would repeat the inline-invention failure this project has refused
   throughout.

## Alternatives considered

### Withhold the number until it can pass

Refused. `ADR-0330` refused fabricating a favourable number; withholding an
unfavourable one is the same dishonesty reversed. The row asked for a
measurement against named hardware, and it now has one.

### Measure only the fastest profile

Rejected. The row says "depending on quality profile"; one profile would
answer a narrower question than the row asks. All three levels are measured
and the representation lever's real effect (6.1x) is recorded beside its
insufficiency.

## Consequences

Every M6 engineering row is now discharged or measured. What remains to the
finish line is the `Examples` reference application and release assembly, plus
the owner's demonstrations and reviews — including this row's target standing.

## Affected modules

The benchmark package gains the frames scenario and a `VoxeliaMetal` product
dependency. No product source changes.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

This record measures; it changes nothing.

## Validation impact

```text
cd Benchmarks && swift build -c release && ./.build/release/voxelia-benchmark --frames
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push; the benchmark
package builds and runs clean.

## Migration

1. This record with `VOXELIA-BEN-0003`.
2. **Next**: the `Examples` reference application, then release assembly.
3. **Owner**: the target standing at release review; the `D` half joins the
   demonstrations.

## Supersession

This record supersedes nothing. It completes the measurement `ADR-0330`
specified and defers the acceptance judgement to the owner it belongs to.

## References

- [VOXELIA-BEN-0003 - Frame rate baseline](../../benchmarks/VOXELIA-BEN-0003-frame-rate-baseline.md)
- [ADR-0271 - Compression benchmark and random access](ADR-0271-compression-benchmark-and-random-access.md)
- [ADR-0330 - Frame rate target needs its hardware](ADR-0330-frame-rate-target-needs-its-hardware.md)
- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [ADR-0343 - Open the progressive refinement arc](ADR-0343-open-the-progressive-refinement-arc.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

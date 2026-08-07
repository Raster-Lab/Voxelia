---
document_id: "ADR-0343"
title: "Open the progressive refinement arc"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-009"
  - "VOX-DVR-013"
---

# ADR-0343 - Open the progressive refinement arc

## Context

`VOX-BRK-009` — interactive rendering shall be able to use a lower-resolution
level while higher-resolution bricks are loading — and `VOX-DVR-013` —
interactive quality shall refine towards requested diagnostic quality after
interaction stops — are the two P0 rows `ADR-0329` recorded as unbuilt **by an
accepted decision**: `ADR-0103` made version one single-pass, the *"both
qualities execute identically"* test guards that position, and `SceneSnapshot`'s
documentation names the degraded path as future work claiming its own quality
tokens through its own decisions. `ADR-0338` decision 3 is that decision: the
owner approved building the superseding version. This record opens the arc,
fixes its order, and designs the first increment — because before anything can
*use* a lower-resolution level, a lower-resolution level has to exist, and
`BrickResolutionLevel` is vocabulary with no generator.

## The arc, in order

1. **This increment**: the level representation — `LevelSelectOperation`
   generating a lower-resolution volume under `VOXELIA-ALG-0056`'s frozen
   selection and geometry scaling.
2. **The interactive path**: rendering from the level while level-zero bricks
   load, claiming `org.voxelia.quality.interactive` with the level recorded —
   the `VOX-BRK-009` discharge, composing the study-cache stage.
3. **Refinement**: the full-quality pass after interaction stops, converging
   bit-exactly to the single-pass full render — the `VOX-DVR-013` discharge.
4. **The guard replacement, conscious and last**: the `ADR-0103` equivalence
   test is replaced by per-quality claims **in the same increment that makes the
   qualities diverge**, per `ADR-0329` decision 3 — never deleted earlier, so
   the old position stays guarded until the new one is tested.

Both rows' `D` halves remain owner-witnessed at release.

## Decision

1. **A level's samples are SELECTED, never averaged** (`VOXELIA-ALG-0056`):
   level sample `(j0, j1, j2)` is the verbatim level-zero stored value at
   `(j0*f0, j1*f1, j2*f2)`, extents `ceil(e/f)` per axis. Every interactive
   pixel therefore shows a real acquired sample — no synthesised intensity
   enters the diagnostic path, the same no-fabrication line the padding and
   halo rules already hold. The trade — aliasing under decimation rather than
   smoothing — is accepted and recorded here; an averaged pyramid would be a
   separate representation with an approximation claim, and nothing in this
   arc precludes a future record adding one beside this.

2. **The level's geometry scales the index-step columns by the factors**,
   translation verbatim, so a level sample's centre **is** its selected
   sample's centre — no half-voxel shift to explain, and for the practical
   power-of-two factors the scaled-matrix and scaled-index routes agree
   bit-exactly (oracle witness). The output claims the scaled geometry as its
   own calibration authority, the request-verbatim pattern.

3. **`LevelSelectOperation` in `VoxeliaExecution`**, the registered-operation
   pattern verbatim: token `org.voxelia.op.level-select`, CPU implementation
   token, version `1.0.0`, the sampler's value domain (rank-three `uint8`
   scalar intensity, affine-calibrated, slot-complete mapping), budgeted
   coordinated full read, parameter document carrying the level index and the
   three factors. The parameter is a `BrickResolutionLevel` with index at
   least one — level zero *is* the volume, and an identity copy would mint a
   duplicate object while looking like work (`invalidDownsamplingLevel`).

4. **The operation's claim is `exact`.** Selection copies admitted bytes and
   the geometry scaling is the recorded derivation; nothing is approximated
   *by this operation*. The interactive **render** from the level is where a
   quality claim below full belongs — arc step 2's business, through the claim
   vocabulary `ADR-0103` already routes.

5. **Factors are bounded by the sibling ceiling** — each factor in
   `1...16384` through `BrickResolutionLevel`'s own admission plus the
   operation's level check; a factor above an extent collapses that axis to
   one sample through the ordinary arithmetic, fixture-verified.

## Alternatives considered

### Average the block instead of selecting

Rejected for this representation; see decision 1. Averaging synthesises
intensities that were never acquired, which forces an approximation claim onto
every downstream consumer and buys smoothness the interactive use does not need
to be honest. Selection keeps the level inside the study's own sample set.

### Generate levels inside the study-cache sweep

Rejected. The sweep decodes what exists; deriving new representations is an
operation with provenance, identity and a parameter digest. Composing them
stays possible — a caller can sweep level zero and then run this operation —
without welding two contracts together.

### Start the arc at the renderer

Rejected. The renderer increment would have to invent the level inline,
undesigned — exactly the "fix a design against a consumer nobody specified"
failure `ADR-0314` refused for priority. The representation is the smallest
freestanding piece, so it goes first.

## Consequences

The arc is open with its order fixed, and after this increment a
lower-resolution level is a real, provenance-carrying volume the interactive
path can render. `VOX-BRK-009` and `VOX-DVR-013` remain open until arc steps 2
and 3 discharge them; nothing is claimed early.

## Affected modules

`VoxeliaExecution` gains the operation; `VoxeliaCPU` registers it (eighteen
implementations; the combined registry twenty-one).

## Compatibility impact

Additive only. `RenderQuality`, the renderers and the `ADR-0103` guard test are
untouched by this increment, per the arc order.

## Security impact

None.

## Performance and memory impact

One full-volume coordinated read and one reduced output allocation; selection
is a single pass in canonical order.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0343-level-select-oracle.py
swift test --filter "LevelSelectOperationTests|CPUBackendRegistrationsTests|CombinedRegistryTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The full suite must show the literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0056` and the oracle.
2. The operation, its registration and the fixture tests, in the same
   increment.
3. **Next**: arc step 2 — the interactive render path over the level.
4. **Owner**: both `D` halves join the release demonstrations.

## Supersession

This record supersedes nothing yet. The arc it opens will supersede
`ADR-0103`'s single-pass position at step 4, consciously, with the guard test
replaced in that same increment — and not before.

## References

- [VOXELIA-ALG-0056 - Level selection downsampling](../../algorithms/VOXELIA-ALG-0056-level-selection-downsampling.md)
- [ADR-0103 - Interactive quality equivalence](ADR-0103-interactive-quality-equivalence.md)
- [ADR-0329 - Interactive refinement is deferred](ADR-0329-interactive-refinement-is-deferred.md)
- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [ADR-0341 - Study cache generation and priority](ADR-0341-study-cache-generation-and-priority.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

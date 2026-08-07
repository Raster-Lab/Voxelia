---
document_id: "ADR-0391"
title: "Progressive convergence exposure"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-011"
  - "VOX-PRR-012"
---

# ADR-0391 - Progressive convergence exposure

## Context

`VOX-PRR-011` (P1, `T,D`, M8): the progressive mode shall expose
convergence or variance information. `VOX-PRR-012` (P0, `T`, M8):
temporal accumulation shall be reset or reprojected safely when scene,
camera, transfer function or source data changes. The two rows are one
mechanism seen from two sides: an accumulator that knows how converged
it is, and a guard that knows when its accumulation stopped being
about the same picture.

## Decision

1. **`ProgressiveAccumulator` is Welford's running mean and unbiased
   variance** (`VOXELIA-ALG-0080`, frozen order, bit-pinned). The
   variance is **absent below two samples** — a variance nobody
   measured is not reported as certainty — and a non-finite sample
   refuses typed rather than poisoning the running state. Convergence
   information is these three numbers: count, mean, variance; no
   invented "percent converged" score.

2. **Accumulation is keyed to a declared scene fingerprint**:
   `SceneStateFingerprint` carries four caller-declared identity
   strings — scene, camera, transfer function, source data — exactly
   the row's four change triggers, compared by equality.
   `TemporalAccumulation.accumulate(value:under:)` **resets before
   accumulating** when the fingerprint differs from the one the
   accumulation started under, and reports which happened in a closed
   two-case outcome. Stale accumulation is unrepresentable, not
   discouraged.

3. **Reset, not reprojection, in v1**: the row offers both;
   reprojection is an approximation with its own error story and
   belongs to a future model if a row demands it. The safe branch is
   taken and recorded.

## Alternatives considered

### Exposing a normalised convergence score

Rejected — decision 1. A score would bake a threshold policy into the
library; hosts read the variance and decide.

### Detecting scene changes inside the module

Rejected. The module cannot know what the host's scene state is;
declared fingerprints make the trigger set explicit and testable.

## Consequences

The determinism arc closes with the presentation arc's rows next; the
validation arc has count/mean/variance to test convergence against.

## Affected modules

`VoxeliaPhotorealistic` gains the accumulator, the fingerprint and the
guard.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(1)` per accumulated sample.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0391-progressive-variance-oracle.py
swift test --filter ProgressiveAccumulationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0080`, the types, the fixture suite and
   the register updates, in the same increment.
2. **Next**: the presentation and integrity arc.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0080 - Progressive variance](../../algorithms/VOXELIA-ALG-0080-progressive-variance.md)
- [ADR-0390 - Deterministic reference seeds](ADR-0390-deterministic-reference-seeds.md)

---
document_id: "ADR-0396"
title: "Photorealistic validation witnesses"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-VAL-015"
  - "VOX-PRR-017"
---

# ADR-0396 - Photorealistic validation witnesses

## Context

The `ADR-0384` validation arc: `VOX-VAL-015` (P0, `T,R`, M8) —
statistical convergence, reproducibility and diagnostic-feature
preservation; `VOX-PRR-017` (P0, `T,R`, M8) — presets tested for
preservation of thin structures and high-value intensity ranges. The
arc's engineering halves are witnessable now because everything they
measure is already pinned: the seeded sequence, the accumulator and
the single-scattering composition.

## Decision

1. **Convergence is witnessed deterministically**: a seeded sample
   stream accumulates, and the variance of the mean
   (`variance/count`) strictly decreases across order-of-magnitude
   checkpoints — a deterministic fact for a declared seed, not a
   statistical hope.

2. **Reproducibility is bit-equality**: two accumulations from the
   same seed agree in count, mean and variance exactly; a different
   seed diverges. This is the reference mode's whole promise, witnessed
   at the state level.

3. **Feature preservation is contrast through the composition**: a
   one-sample-thin bright structure embedded in background retains
   strictly positive contrast through the single-scattering
   composition, and a high-value emission is carried monotonically —
   the preset under test is the declared light set and albedo mapping,
   and the witness pins exact values, so a future preset change that
   washes out the thin structure fails the suite.

4. **Both `R` halves join the owner batch**: the acceptance session
   for photorealistic validation evidence and the clinical preset
   review are owner decisions; these witnesses are what that session
   reviews.

5. **With this record, M8's engineering is complete** — every M8 row
   is discharged or carries only its owner-reserved half.

## Alternatives considered

### Stochastic convergence tests with tolerance bands

Rejected. The seeded sequence makes convergence a deterministic
fixture; a tolerance band would reintroduce the flakiness the
determinism arc exists to prevent.

## Consequences

M9 opens next per the finish plan.

## Affected modules

Test witnesses only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter PhotorealisticValidationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the witness suite and the register updates, in the
   same increment.
2. **Next**: open M9.
3. **Owner**: the validation-acceptance and preset-review halves,
   batched.

## Supersession

This record supersedes nothing.

## References

- [ADR-0389 - The documented scattering approximation](ADR-0389-the-documented-scattering-approximation.md)
- [ADR-0390 - Deterministic reference seeds](ADR-0390-deterministic-reference-seeds.md)
- [ADR-0391 - Progressive convergence exposure](ADR-0391-progressive-convergence-exposure.md)

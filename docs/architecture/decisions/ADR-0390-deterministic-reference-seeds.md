---
document_id: "ADR-0390"
title: "Deterministic reference seeds"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-010"
---

# ADR-0390 - Deterministic reference seeds

## Context

The `ADR-0384` determinism arc opens. `VOX-PRR-010` (P0, `T`, M8): the
reference mode shall support deterministic random seeds — the property
the whole validation arc later leans on, so it comes first.

## Decision

1. **SplitMix64 is the sequence** (`VOXELIA-ALG-0079`,
   `deterministic-sequence/v1`): exact wrapping 64-bit integer
   arithmetic, no rounding anywhere, fixtures pinned word for word.
   Platform-independent by construction — no system generator, no
   `SystemRandomNumberGenerator`, no hidden entropy.

2. **The seed is caller-declared and defaultless.** A default seed
   would make "deterministic" mean "accidentally reproducible";
   reference renders declare their seed and record it, which is what
   makes them reference renders.

3. **Unit samples are exact**: the top 53 bits scaled by `2⁻⁵³`, an
   exact binary64 in `[0, 1)` — the sampling arcs consume doubles
   without a rounding story of their own.

## Alternatives considered

### The standard library's random API

Rejected. Its generator is unspecified and platform-dependent —
exactly what the row prohibits.

### A cryptographic generator

Rejected. Statistical quality for sampling, not unpredictability, is
the requirement; SplitMix64 is fixture-pinnable in ten lines of
oracle.

## Consequences

Progressive accumulation and the validation arc's reproducibility row
have their sequence.

## Affected modules

`VoxeliaPhotorealistic` gains the sequence.

## Compatibility impact

Additive only.

## Security impact

None; the generator is deliberately non-cryptographic and documented
as such.

## Performance and memory impact

`O(1)` per word.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0390-deterministic-sequence-oracle.py
swift test --filter DeterministicSequenceTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, `VOXELIA-ALG-0079`, the sequence, the fixture suite
   and the register updates, in the same increment.
2. **Next**: progressive convergence exposure and temporal reset.

## Supersession

This record supersedes nothing.

## References

- [VOXELIA-ALG-0079 - Deterministic sample sequence](../../algorithms/VOXELIA-ALG-0079-deterministic-sequence.md)
- [ADR-0384 - The M8 queue](ADR-0384-the-m8-queue.md)

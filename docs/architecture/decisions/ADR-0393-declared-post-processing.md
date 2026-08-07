---
document_id: "ADR-0393"
title: "Declared post-processing"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-013"
  - "VOX-PRR-014"
---

# ADR-0393 - Declared post-processing

## Context

`VOX-PRR-013` (P0, `T`, M8): denoising shall be explicit, versioned and
recorded in provenance. `VOX-PRR-014` (P0, `I,T,R`, M8): generative
reconstruction shall not be applied implicitly to photorealistic
output. The two rows are one vocabulary: everything that happens to a
rendered image after integration is a **declared** step or it did not
happen.

## Decision

1. **`PostProcessDeclaration` is the closed vocabulary**: a step is
   `denoising` or `generativeReconstruction`, each carrying the
   processor's `SoftwareIdentity` — the accepted provenance vocabulary,
   name and version required (`ADR-0381`'s discipline) — and a
   non-empty method identifier. Anonymous or unversioned post-
   processing is unrepresentable.

2. **`PhotorealisticOutputRecord` carries the ordered declaration
   list**, and constructing it is the only way to claim an output.
   "Implicit generative reconstruction" is therefore not a policy
   violation but a type error: output that went through a generative
   step either declares it or the record lies at construction, and
   nothing in this module constructs records on the caller's behalf.

3. **The inspection half is the module's contents**: no denoiser and
   no generative model exists anywhere in `VoxeliaPhotorealistic` —
   there is nothing to apply implicitly. When implementations arrive
   they arrive as declared steps behind this vocabulary. The `R` half
   — host policy for *accepting* declared generative output into
   clinical presentation — joins the owner batch beside the
   diagnostic-selection `R`s.

## Alternatives considered

### A boolean `wasDenoised` flag

Rejected. A flag without identity and version is exactly the implicit
processing both rows prohibit, spelled as a bool.

## Consequences

The validation arc and hosts can read exactly what touched an image;
the owner batch gains the generative-acceptance policy question.

## Affected modules

`VoxeliaPhotorealistic` gains the vocabulary and the record.

## Compatibility impact

Additive only.

## Security impact

Strengthened: undeclared post-processing is unrepresentable.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter PostProcessDeclarationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the vocabulary, the fixture suite and the register
   updates, in the same increment.
2. **Next**: side-by-side scene-state binding.

## Supersession

This record supersedes nothing.

## References

- [ADR-0381 - Implementation provenance](ADR-0381-implementation-provenance.md)
- [ADR-0384 - The M8 queue](ADR-0384-the-m8-queue.md)

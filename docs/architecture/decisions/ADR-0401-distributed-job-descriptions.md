---
document_id: "ADR-0401"
title: "Distributed job descriptions"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-DST-001"
  - "VOX-DST-002"
  - "VOX-DST-003"
  - "VOX-DST-004"
  - "VOX-DST-005"
  - "VOX-PRR-016"
  - "VOX-INT-003"
---

# ADR-0401 - Distributed job descriptions

## Context

The `ADR-0397` distributed-descriptions arc: transport-neutral
serialisable job descriptions carrying identity, versions, parameters
and input identities; compatibility requirements; partitioning by
tile, frame range, brick set or sample range; deterministic seeds; the
photorealistic partitioning row; and camera serialisation. One
vocabulary serves all seven rows, and nearly every part already
exists — the description composes, it does not invent.

## Decision

1. **`DistributedJobDescription` is `Codable` with revalidating
   decode** (`VOX-DST-001`): transport-neutral means JSON through the
   ordinary coder, and every decode passes the same throwing admission
   as construction — the frame-geometry precedent. It carries the job
   identifier, the operation token and version, the canonical
   parameters `ContentID` (`ADR-0054`'s projection — parameters travel
   as their digest, not as re-encoded structures) and the required
   input identities as object-identifier/content-digest pairs
   (`VOX-DST-002`).

2. **Compatibility is the `ADR-0380` contract, verbatim**
   (`VOX-DST-003`): the row asks for scalar formats, geometry, quality
   and device capabilities — exactly the declared implementation
   contract's fields, so the description embeds
   `DeclaredImplementationContract` rather than inventing a second
   spelling. The contract vocabulary gains `Codable` (revalidating) to
   travel; `ExecutionClaimToken`, `DerivationOperationToken` and
   `DerivationImplementationReference` gain the same.

3. **`WorkPartition` is the closed four-case vocabulary**
   (`VOX-DST-004`): `imageTile` (validated non-negative origin,
   positive extents), `frameRange` (non-negative closed range),
   `brickSet` (non-empty identifiers) and `sampleRange` (positive
   count) — the row's four shapes verbatim, and the photorealistic
   partitioning row (`VOX-PRR-016`) is served by `imageTile` and
   `sampleRange`, witnessed by a photorealistic job fixture.

4. **A sample-range partition requires a seed** (`VOX-DST-005`):
   sample ranges exist for stochastic accumulation, and stochastic
   work without a declared `VOXELIA-ALG-0079` seed refuses typed —
   "where stochastic rendering is used" is an admission rule, not a
   convention.

5. **`RenderCamera` becomes `Codable` with revalidating decode**
   (`VOX-INT-003`): the existing camera vocabulary serialises through
   its own throwing admission — off-screen and distributed rendering
   snapshot the same validated type, no parallel snapshot struct.

## Alternatives considered

### A parallel compatibility schema for transport

Rejected — decision 2. Two spellings of one contract diverge.

### Optional seeds everywhere

Rejected — decision 4.

## Consequences

Arc 4 (integrity: checksummed partials, merges, reductions, worker
rejection) builds against these descriptions.

## Affected modules

`VoxeliaCore` (token/reference `Codable`), `VoxeliaExecution` (the
description, partitions, contract `Codable`), `VoxeliaRendering`
(camera `Codable`).

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission; decode revalidates everything.

## Performance and memory impact

Negligible.

## Validation impact

```text
swift test --filter DistributedJobTests
swift test --filter CameraSerialisationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the conformances, the description, the witness suites
   and the register updates, in the same increment.
2. **Next**: the distributed-integrity arc.

## Supersession

This record supersedes nothing.

## References

- [ADR-0380 - The registration declaration contract](ADR-0380-the-registration-declaration-contract.md)
- [VOXELIA-ALG-0079 - Deterministic sample sequence](../../algorithms/VOXELIA-ALG-0079-deterministic-sequence.md)
- [ADR-0397 - The M9 queue](ADR-0397-the-m9-queue.md)

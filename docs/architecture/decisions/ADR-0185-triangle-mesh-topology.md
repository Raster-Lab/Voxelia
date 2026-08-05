---
document_id: "ADR-0185"
title: "Triangle mesh topology"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GEO-003"
  - "VOX-GEO-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
---

# ADR-0185 - Triangle mesh topology

## Context

Accepted `ADR-0184` froze the independently unblocked topology prerequisite of
the M6 geometry arc. This record implements it without crossing the unresolved
`VoxeliaGeometry`-to-`VoxeliaSpatial` package boundary. It was authored and
accepted on 2026-08-05 under the project owner's continuation mandate.

## Decision

1. **`TriangleMeshTopology` joins `VoxeliaGeometry` exactly as designed.** The
   immutable `Sendable`, `Hashable` value owns the nonnegative vertex-domain
   count and flattened logical `UInt64` triangle indices, with exact
   `triangleCount` projection and no `Codable` claim.
2. **Construction applies the fixed fail-closed precedence.** Negative vertex
   count, incomplete triple and complete-sequence bounds failures map to the
   three payload-free `TriangleMeshTopologyError` cases. Empty topology is
   valid; repeated indices, degeneracy, order and multiplicity are preserved.
3. **No physical representation leaks into logical identity.** `IndexType`
   remains the later buffer-width choice; topology retains `UInt64` ordinals
   even when a consumer can safely narrow them.

## Alternatives considered

Recorded in `ADR-0184`; implementation exposed no new choice.

## Consequences

Every accepted `TriangleMeshTopology` contains complete in-bounds independent
triangles. The coordinate-bearing mesh can compose this value after its package
dependency is resolved explicitly.

## Affected modules

`VoxeliaGeometry`.

## Compatibility impact

Additive public API before 1.0.

## Security impact

The three public failures carry no counts or indices, and all indices validate
before the topology value is published.

## Performance and memory impact

One linear bounds-validation pass with constant auxiliary storage; the supplied
`ContiguousArray` value is retained without a deliberate duplicate allocation.

## Validation impact

`TriangleMeshTopologyTests` executes seven focused tests: empty and ordinary
admission, both validation-precedence boundaries, every bounds category, exact
order/multiplicity/degeneracy preservation, the host vertex-domain boundary,
and `Sendable`/`Hashable`/payload-free behavior. The owning target and direct
dependants compile as part of the focused SwiftPM build. The wider repository
Swift-safety inventory was also run and failed on ten pre-existing
`@unchecked Sendable` conformances outside this increment; that gate is
recorded red in the progress ledger and is the next recovery action. A
pre-existing `OrthographicRayGenerator` duplicate-argument-label warning also
remains outside this increment; no new warning is introduced.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0184`; no record is superseded.

## References

- [ADR-0183 - Geometry extraction arc](ADR-0183-geometry-arc.md)
- [ADR-0184 - Triangle mesh topology design](ADR-0184-triangle-mesh-topology-design.md)

---
document_id: "ADR-0154"
title: "Bricked storage design"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-STO-005"
  - "VOX-BRK-001"
  - "VOX-ERR-001"
---

# ADR-0154 - Bricked storage design

## Context

The M5 actionable queue is closed and its honest remainder is
`VOX-STO-005` itself: no storage implementation yet serves the
accepted region-read contract from bricks. Per the plan-first
discipline this record freezes the design before implementation. It
was authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **`BrickedImageStorage` conforms to the accepted contract.** The
   provider carries the full-volume snapshot binding and serves
   `read(region:)` through the accepted transaction machinery —
   admission, bounded monotonic fill and commit are the existing
   authorities, not new machinery. Consumers see the same contract
   the contiguous provider serves; brickedness is invisible at the
   boundary, which is exactly `VOX-BRK-001`'s storage half: a volume
   is processable without one complete resident copy being the only
   representation.
2. **Construction is write-once from a complete brick set.** The
   caller supplies the full-volume binding, a grid descriptor whose
   rank and volume extents must equal the binding's shape — typed
   mismatch — and one payload per grid coordinate holding exactly
   the brick's core-region bytes in canonical packed axis-zero-fastest
   order, with typed rejections for a missing coordinate, a foreign
   coordinate and a payload whose byte count is not the core
   region's. The halo is a fetch policy for processing and is
   deliberately absent from storage. After construction the value is
   immutable, per the snapshot contract.
3. **Assembly is frozen integer arithmetic.** A read walks the same
   axis-zero-run odometer the accepted contiguous loop uses; each
   run intersects consecutive bricks along axis zero through the
   grid authority's core regions, and each sub-run copies from the
   brick's own local layout — boundary bricks' smaller extents come
   from the same authority, never recomputed. No new ceilings exist:
   the binding bounds construction structurally and the coordinated
   read boundary already budgets consumption.
4. **The binding obligation is byte identity.** The implementing
   increment must prove `read(region:)` byte-identical to the
   contiguous provider over one volume stored both ways — the full
   region, a cross-brick interior region, a boundary-brick region
   and a single-sample region — on a grid with boundary bricks on
   every axis, plus every typed construction rejection.

## Alternatives considered

Serving halo-inclusive brick payloads was rejected: storage would
hold duplicated voxels whose provenance is the neighbouring brick's,
and the design already places halo at fetch time. A per-brick lazy
provider map was rejected for version one: the write-once complete
set keeps the snapshot contract's immutability trivially true, and
laziness belongs to the cache tier that already exists.

## Consequences

`VOX-STO-005` becomes implementable with one increment; the tiled
representation composes the existing transaction, vocabulary and
cache authorities.

## Affected modules

Documentation only in this increment.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None in this increment.

## Validation impact

The byte-identity obligation and typed rejections above bind the
implementing increment.

## Migration

None; implementation follows as its own increment.

## Supersession

Continues the M5 arc; no record is superseded.

## References

- [ADR-0148 - Brick vocabulary](ADR-0148-brick-vocabulary.md)
- [ADR-0042 - Storage API name, wire and limit freeze](ADR-0042-storage-api-name-wire-and-limit-freeze.md)

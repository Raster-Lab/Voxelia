---
document_id: "ADR-0125"
title: "Index-space pick resolution"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-INT-006"
  - "VOX-ERR-001"
---

# ADR-0125 - Index-space pick resolution

## Context

`VOX-INT-006` requires picking to identify the rendered layer, source
data and physical position. The presentation claims now state exactly
what the pipeline did — crop, scaling policy, layers — so a pure
value resolver can invert them; physical position additionally needs
geometry-bearing volumes, which the pipeline does not yet present.
This record was authored and accepted on 2026-08-05 under the
project owner's recorded broadened autonomous delegation.

## Decision

`VoxeliaInteraction` gains `PickResolver.resolve`, a pure function
from a `PickTarget` and a `PresentationProvenance` to a
`PickResolution`:

1. **The claims are the map.** The target must lie inside the claimed
   viewport — outside is the typed `pickOutsideViewport` — and the
   resolver inverts the scaling claim to the presented index:
   identity is the index itself; nearest-neighbour is the exact
   inverse of the registered `VOXELIA-ALG-0008` forward map, the
   source sample the displayed pixel actually came from; bilinear
   resolves the dominant tap — the source centre nearest the
   pixel-centre-aligned coordinate — an interpretation this record
   freezes, because a blended pixel has four contributors and a pick
   must name one. A claimed crop then offsets the presented index by
   its lower bounds, because cropping ran before scaling.
2. **Every contributing layer.** The resolution carries the claimed
   layer list in order — a composited pixel blends every layer, so
   the pick identifies all of them with their object identifiers —
   with the resolved source index shared, because every layer was
   presented through the same geometry-free pipeline.
3. **Physical position stays gated.** No presentation claim carries
   spatial geometry today; the physical-position half of the row
   arrives with geometry-bearing presentation through its own
   decisions, recorded here.

## Alternatives considered

Resolving against live pipeline state was rejected: the claims are
the honest record and the resolver stays a pure value function.
Returning all four bilinear taps was rejected for version one: the
consumer asks where a pick landed, and the dominant-tap rule is the
frozen deterministic answer.

## Consequences

The index-space halves of `VOX-INT-006` — layer and source-data
identification with source position — are discharged; the physical
half is recorded with its gate.

## Affected modules

`VoxeliaInteraction` only; no dependency change.

## Compatibility impact

Purely additive; one new typed error case.

## Security impact

Values carry indices and already-claimed identifiers only.

## Performance and memory impact

Negligible.

## Validation impact

Tests must resolve picks through identity, nearest-neighbour and
bilinear claims with independently computed source indices, apply the
crop offset, carry every claimed layer, and reject an outside-viewport
target typed.

## Migration

Implemented in this increment.

## Supersession

Extends the `ADR-0111` interaction vocabulary; no record is
superseded.

## References

- [ADR-0124 - Display policy selection](ADR-0124-display-policy-selection.md)
- [ADR-0100 - Presentation scaling claim](ADR-0100-presentation-scaling-claim.md)

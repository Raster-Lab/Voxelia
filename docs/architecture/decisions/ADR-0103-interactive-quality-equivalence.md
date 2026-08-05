---
document_id: "ADR-0103"
title: "Interactive quality equivalence"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ARC-008"
  - "VOX-VS1-019"
---

# ADR-0103 - Interactive quality equivalence

## Context

`ADR-0084` gave requests a closed `RenderQuality`, and every stage
claim carries the `org.voxelia.quality.full` policy token — yet
nothing recorded how the interactive request relates to those claims,
leaving it open to read `interactive` as an implied degradation that
does not exist. This record was authored and accepted on 2026-08-05
under the project owner's recorded broadened autonomous delegation.

## Decision

1. **Equivalence is the version-one semantics.** The accepted
   pipeline is deterministic and single-pass; `interactive` and
   `full` requests execute identically, and this equivalence is now
   documented on the type rather than left implicit.
2. **Claims record what ran.** Stage records claim
   `org.voxelia.quality.full` under either request, because that is
   the quality that executed; the requested quality is deliberately
   not recorded in the presentation provenance per the `ADR-0100`
   rule — provenance claims what was done, and an identically
   executed request leaves nothing distinct to claim.
3. **Degradation is a future operation property.** When a degraded
   interactive path exists, the operations it actually degrades will
   carry their own quality-policy tokens and approximation statuses
   through their own decisions; the request enum stays a hint until
   an execution difference exists to claim.

## Alternatives considered

Recording the requested quality in `PresentationProvenance` was
rejected: it would enshrine a request with no observable effect as a
provenance claim. Making interactive renders claim an interactive
quality token today was rejected as false: nothing degrades.

## Consequences

The quality vocabulary is honest end to end: requests are hints,
claims are executions, and the equivalence is proven rather than
assumed.

## Affected modules

`VoxeliaRendering` documentation only; test evidence in
`VoxeliaMetal`.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

Tests must render one scene under both qualities and prove the
published bytes and the stage quality-policy claims identical.

## Migration

Implemented in this increment.

## Supersession

Clarifies `ADR-0084`; no record is superseded.

## References

- [ADR-0084 - Render quality, layer and scene models](ADR-0084-render-quality-layer-and-scene.md)
- [ADR-0100 - Presentation scaling claim](ADR-0100-presentation-scaling-claim.md)

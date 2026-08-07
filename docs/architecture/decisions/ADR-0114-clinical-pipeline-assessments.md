---
document_id: "ADR-0114"
title: "Clinical pipeline assessments"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-META-011"
  - "VOX-SPA-013"
  - "VOX-R2D-012"
---

# ADR-0114 - Clinical pipeline assessments

## Context

Three M4 rows assert properties the delivered pipeline must already
hold; none had a recorded assessment binding the row to its evidence.
Per the `ADR-0037` documentation-only precedent, this record performs
and records those assessments without new source. It was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **`VOX-META-011` — provenance carries no patient-identifying
   metadata unless the host supplies it.** Discharged structurally.
   A provenance record's members are a closed set of validated
   grammar-bounded tokens, digests, versions, instants and
   host-supplied identifiers; the `ADR-0052` warning schema has no
   free-text member, proven by reflection in its suite; image
   metadata never enters a provenance record — operations pass bundle
   metadata beside, not inside, the record; and the `VCPJ-1` emitter
   is fixed-schema with golden byte-equality fixtures pinning every
   byte of representative documents, so no unaccounted field can
   serialise. The one deliberate opening is the row's own second arm:
   host-supplied identifiers and software identity are the host's
   explicit content, and hosts that embed identifying text in an
   object identifier have exercised exactly the permission the row
   reserves to them.
2. **`VOX-SPA-013` — frame-of-reference identities preserved through
   derivation.** Discharged by construction. Every operation either
   passes spatial geometry through unchanged — extraction under the
   `VOXELIA-ALG-0006` translation rules with its coordinate space
   intact, window-level untouched — or rejects geometry-bearing
   input typed before executing, as resampling, compositing and
   inversion do; no path drops a frame-of-reference silently, and the
   extraction suite pins the geometry arithmetic.
3. **`VOX-R2D-012` — quantitative inspection preserved before display
   transforms.** Discharged by the publication discipline. The
   registry is append-only with nothing evicted or replaced; stored
   origin objects remain published and byte-readable beside every
   display-transformed stage, as the pipeline suites exercise by
   reading origins after full renders, and every display stage is a
   distinct published object rather than a mutation.

## Alternatives considered

New closure tests were considered and deferred: the golden
byte-equality fixtures already pin representative documents exactly,
and a string-closure sweep adds value chiefly when the emitter grows
members — recorded as a candidate alongside future emitter revisions.

## Consequences

`VOX-META-011`, `VOX-SPA-013` and `VOX-R2D-012` carry recorded
assessments bound to existing proven evidence.

## Affected modules

Documentation only; no source change.

## Compatibility impact

None.

## Security impact

The privacy assessment is recorded; the host-supplied-identifier arm
is explicit.

## Performance and memory impact

None.

## Validation impact

No new obligations; the cited suites remain the evidence.

## Migration

None.

## Supersession

Records assessments; no record is superseded.

## References

- [ADR-0052 - Provenance warning schema](ADR-0052-provenance-warning-schema.md)
- [ADR-0060 - Canonical provenance record projection](ADR-0060-canonical-provenance-record-projection.md)
- [ADR-0077 - Retention and enrichment lifecycle](ADR-0077-retention-and-enrichment-lifecycle.md)

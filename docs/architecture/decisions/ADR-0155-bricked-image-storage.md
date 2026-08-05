---
document_id: "ADR-0155"
title: "Bricked image storage"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-STO-005"
  - "VOX-BRK-001"
  - "VOX-ERR-001"
---

# ADR-0155 - Bricked image storage

## Context

Accepted `ADR-0154` froze the bricked storage design with the
byte-identity obligation. This record implements it. It was authored
and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation.

## Decision

1. **`BrickedImageStorage` joins `VoxeliaStorage`** conforming to
   the accepted contract exactly as designed: write-once
   construction validates the grid against the binding's shape,
   requires one payload per grid coordinate holding exactly the
   core-region bytes, and rejects a foreign coordinate by exact
   cover — each with its own payload-free case.
2. **The representation vocabulary gains the decoded composite
   case.** The bricked layout is fully decoded and region-readable
   but is not the canonical strided profile, and the opaque case
   means not directly readable — the compression vocabulary's
   meaning, which the transaction's admission rightly rejects. So
   `StorageRepresentationDescriptor` gains
   `decodedComposite(DecodedCompositeRepresentation)` — format tag,
   fragment count, sample byte order and known byte count — and the
   transaction admits it for reads while continuing to reject
   opaque. Claiming the strided profile instead was rejected as
   misreporting the layout; the provider admits the composite case
   tagged `org.voxelia.storage.bricked-v1`. Image-data admission
   still requires the strided profile; a bricked-backed image
   aggregate is its own recorded future increment.
3. **Reads mirror the accepted loop.** The read walks the same
   axis-zero-run odometer as the contiguous provider through the
   same transaction machinery; each run splits across consecutive
   bricks through the grid authority's core regions, with the
   sub-run's local offset computed against the brick's own core
   extents. An impossible missing payload after admission surfaces
   the contract-violation case rather than trapping.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

`VOX-STO-005` is discharged for the in-memory uncompressed tier;
`VOX-BRK-001`'s storage half holds — a volume serves the full read
contract with no complete contiguous copy anywhere.

## Affected modules

`VoxeliaStorage`.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

One grid-authority derivation per brick sub-run; no allocation
beyond the transaction's own fill.

## Validation impact

New suite `BrickedImageStorageTests` proves byte identity against
the contiguous provider over a boundary-bricks-on-every-axis layout
for the full region, a cross-brick interior region, a boundary-brick
region and a single sample, and rejects every typed construction
case.

## Migration

None; the surface is new.

## Supersession

Implements accepted `ADR-0154`; no record is superseded.

## References

- [ADR-0154 - Bricked storage design](ADR-0154-bricked-storage-design.md)
- [ADR-0148 - Brick vocabulary](ADR-0148-brick-vocabulary.md)

---
document_id: "ADR-0156"
title: "Bricked image aggregate"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-STO-005"
  - "VOX-BRK-001"
  - "VOX-IMG-001"
---

# ADR-0156 - Bricked image aggregate

## Context

Accepted `ADR-0155` delivered the bricked provider and recorded the
bricked-backed image aggregate as its own future increment: image
admission still required the canonical strided profile, so a bricked
volume could serve reads but could not be an image. This record
closes that gap. It was authored and accepted on 2026-08-05 under
the project owner's recorded broadened autonomous delegation.

## Decision

1. **Image admission accepts the decoded composite representation
   beside the strided profile.** The byte-order coherence check
   reads the composite descriptor's declared order; every other
   check — shape, scalar type, component count, provenance
   coherence — is representation-independent and stays unchanged.
   The opaque case stays outside image admission: an image is
   decoded samples, and opaque means not directly readable.
2. **Nothing downstream changes.** Operations read through the
   coordinated boundary against the erased contract, which the
   bricked provider already serves; brickedness is invisible through
   the whole pipeline, completing `VOX-BRK-001`'s storage half at
   the aggregate level.

## Alternatives considered

A separate bricked-image aggregate type was rejected: the aggregate's
coherence rules are representation-independent, and a parallel type
would fork every consuming surface for no admission difference.

## Consequences

Bricked volumes are first-class images; the operation pipeline
serves them unmodified.

## Affected modules

`VoxeliaCore`.

## Compatibility impact

Additive admission widening; no admitted aggregate changes meaning.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

The image suite gains the composite-backed construction; the storage
suite proves the end-to-end story — the region-extraction operation
over a bricked-backed input produces output byte-identical to the
contiguous-backed equivalent.

## Migration

None.

## Supersession

Closes the future increment recorded by `ADR-0155`; no record is
superseded.

## References

- [ADR-0155 - Bricked image storage](ADR-0155-bricked-image-storage.md)

---
document_id: "ADR-0404"
title: "Apple adapter seams and energy"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ADP-001"
  - "VOX-ADP-002"
  - "VOX-ADP-004"
  - "VOX-PER-013"
---

# ADR-0404 - Apple adapter seams and energy

## Context

The `ADR-0397` queue's last arc: optional RealityKit integration that
never defines canonical models, spatial presentation of surface and
annotation data where platform capability permits, Core Image
integration limited to two-dimensional workflows, and the energy
measurement row. The adapter rows take the `ADR-0378`/`ADR-0400`
shape; the energy row takes a disposition.

## Decision

1. **RealityKit optionality is already enforced and now recorded**
   (`VOX-ADP-001`): every canonical module prohibits the `RealityKit`
   import — the existing gate is the row's "shall not define the
   canonical scene, camera, geometry or measurement model" made
   structural. Integration happens only through the seam below, in an
   adapter package outside the gate's targets.

2. **`SpatialPresentationAdapter` is the RealityKit-facing seam**
   (`VOX-ADP-002`): an associated entity type (core modules never name
   RealityKit types), an adapter identity, availability as a declared
   property — "where platform capability permits" is the adapter's own
   report, not a canonical-module `#if` — and two conversions:
   canonical `TriangleMesh` to entity, and a labelled anchor point to
   entity. The stub conformance witnesses the seam; a real
   RealityKit-backed package conforms when a host wants one.

3. **`TwoDimensionalMediaAdapter` is the Core Image-facing seam**
   (`VOX-ADP-004`), and its **limitation is its signature**: the input
   is two-dimensional raw pixels with width and height — no volume, no
   scene, no camera exists in the type, so "limited to suitable
   two-dimensional compositing, export, thumbnail or media workflows"
   is not a policy to audit but the only thing expressible.

4. **Energy measurement is dispositioned, not staged**
   (`VOX-PER-013`, P2, "should … where practical"): the analysis half
   is recorded — sustained-workload energy on Apple platforms is
   measured externally (`powermetrics` alongside the benchmark
   harness) rather than by an in-process API the platform does not
   offer — and the measured campaign belongs to the owner's
   reference-hardware session, batched with the other hardware items.
   Nothing in-tree pretends to measure what it cannot.

## Alternatives considered

### A RealityKit-conditional target in this package

Rejected. The supply-chain and platform gates stay clean; the seam is
the deliverable, conformances live with hosts.

### An in-process energy estimator

Rejected — decision 4. An estimate presented as measurement is the
prohibited shape.

## Consequences

**M9's queue is complete**: every M9 row is discharged or carries only
its owner-reserved half. M10 — the publication tail — is next.

## Affected modules

`VoxeliaRendering` gains the two seams.

## Compatibility impact

Additive only.

## Security impact

None beyond the existing import gates.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter AppleAdapterSeamTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the seams, the witness suite and the register updates,
   in the same increment.
2. **Next**: derive and open the M10 queue.
3. **Owner**: the energy measurement campaign, batched with the
   hardware session.

## Supersession

This record supersedes nothing.

## References

- [ADR-0378 - DICOM adapter capabilities](ADR-0378-dicom-adapter-capabilities.md)
- [ADR-0400 - Headless output capabilities](ADR-0400-headless-output-capabilities.md)
- [ADR-0397 - The M9 queue](ADR-0397-the-m9-queue.md)

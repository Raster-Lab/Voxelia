---
document_id: "ADR-0397"
title: "The M9 queue"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-API-009"
  - "VOX-HLS-002"
  - "VOX-HLS-003"
  - "VOX-HLS-004"
  - "VOX-HLS-005"
  - "VOX-HLS-006"
  - "VOX-HLS-007"
  - "VOX-HLS-008"
  - "VOX-HLS-009"
  - "VOX-HLS-010"
  - "VOX-DST-001"
  - "VOX-DST-002"
  - "VOX-DST-003"
  - "VOX-DST-004"
  - "VOX-DST-005"
  - "VOX-DST-006"
  - "VOX-DST-007"
  - "VOX-DST-008"
  - "VOX-DST-009"
  - "VOX-DST-011"
  - "VOX-DST-012"
  - "VOX-PRR-016"
  - "VOX-INT-003"
  - "VOX-EXT-007"
  - "VOX-EXT-008"
  - "VOX-EXT-009"
  - "VOX-ADP-001"
  - "VOX-ADP-002"
  - "VOX-ADP-004"
  - "VOX-PER-013"
---

# ADR-0397 - The M9 queue

## Context

M8's engineering is complete (`ADR-0396`). M9 is the platform,
headless and distributed milestone — thirty rows across seven
families. As with `ADR-0351` and `ADR-0384`, the queue is derived
once, dependency-ordered, so later increments take rows from a
recorded plan.

## Decision

The M9 rows order into six arcs:

1. **Headless foundation** — off-screen public APIs, headless
   rendering on Apple Silicon macOS, one scene description for both
   modes, raw pixel output. Much of this is *witnessable over existing
   substance*: the renderers already run windowless under the test
   suite, so this arc is expected to be records and witnesses more
   than new machinery — and where that is true, the records must say
   so rather than invent parallel code.

2. **Headless capabilities** — the optional media-buffer adapter,
   explicit SDR/HDR output descriptors, optional depth and
   object-identifier outputs, progressive intermediate frames with
   generation and convergence metadata (composing the existing render
   generations and the `ADR-0391` accumulator), cancellation without
   stale publication, and media-encoding isolation (structural, as
   with every optional-module row).

3. **Distributed descriptions** — transport-neutral serialisable job
   descriptions carrying identity, algorithm versions, parameters and
   input identities; compatibility requirements composing the
   `ADR-0380` declared contract; partitioning by tile, frame range,
   brick set or sample range (with the photorealistic partitioning
   row); deterministic seeds composing `VOXELIA-ALG-0079`; and camera
   serialisation.

4. **Distributed integrity** — partial results with checksums,
   provenance and partition identity; merges detecting missing,
   duplicated or incompatible partitions; order-independent mergeable
   accumulators (a Welford merge with its analysis half); declared
   reduction semantics; worker-side rejection of incompatible jobs;
   and pre-emption/cancellation.

5. **Runtime plug-ins** — the three rows are conditional ("if
   introduced") or negotiation rows: the expected shape is a decision
   record that runtime binary plug-ins are **not** introduced at M9,
   with the capability-negotiation vocabulary recorded against the
   source-package mechanism and the out-of-process question documented;
   the `R` half joins the owner batch.

6. **Apple adapters and energy** — optional RealityKit and Core Image
   adapters under the `ADR-0378`-style capability discipline
   (platform-gated, never defining canonical models), and the energy
   measurement row, whose "where practical" clause likely routes its
   measured half to the owner's hardware session.

## Alternatives considered

### Interleaving M9 rows with M10 publication rows

Rejected. M10's rows are release-process rows over whatever M9 built;
ordering discipline has carried three milestones and stays.

## Consequences

The loop takes arc 1 first. The baseline shrinks by the queue's
newly-traced rows; traced is not satisfied, and the ledger tracks
discharge.

## Affected modules

Planning only.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

Each arc's increments carry their own verification.

## Migration

1. This record, then arc 1's first increment.

## Supersession

This record extends the `ADR-0351`/`ADR-0384` queue into M9.

## References

- [ADR-0384 - The M8 queue](ADR-0384-the-m8-queue.md)
- [ADR-0396 - Photorealistic validation witnesses](ADR-0396-photorealistic-validation-witnesses.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

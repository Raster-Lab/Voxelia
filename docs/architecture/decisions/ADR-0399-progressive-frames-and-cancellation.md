---
document_id: "ADR-0399"
title: "Progressive frames and cancellation"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-HLS-008"
  - "VOX-HLS-009"
---

# ADR-0399 - Progressive frames and cancellation

## Context

The `ADR-0397` capabilities arc: `VOX-HLS-008` (P1, `T,D`, M9) —
progressive renderers publish intermediate frames with generation and
convergence metadata; `VOX-HLS-009` (P0, `T`, M9) — render requests are
cancellable and never publish stale final output. The substance exists:
`ADR-0122`'s generations order scene versions and the presenter already
drops stale frames; `ADR-0391` defined convergence as count and
variance. The rows compose them.

## Decision

1. **`ProgressiveFrameMetadata` is generation plus convergence**: the
   `ADR-0122` generation and the `ADR-0391` triple's transportable
   half — sample count (at least one) and optional finite variance,
   absent below two samples. The mean is the frame itself; a metadata
   copy of it would invite divergence.

2. **`ProgressiveRenderSession` composes the counter and the presenter
   unchanged**: intermediate and final frames publish through the same
   stale-drop, and a **final frame is not special** — a stale final is
   dropped exactly like a stale intermediate, which is the whole of
   `VOX-HLS-009`'s "shall not publish stale final output".

3. **Cancellation is a generation advance.** `cancel()` mints the next
   generation, instantly staling every in-flight frame of the
   cancelled request — no flags to poll, no race between a
   cancellation flag and a final publish, because staleness is decided
   at the presentation seam by one comparison. This is `ADR-0122`'s
   contract doing the row's work, recorded rather than re-invented.

4. **The `D` half**: this record and the session's documentation state
   the publication contract — intermediate frames carry their
   convergence honestly, and a host reading variance decides when to
   stop, exactly as `ADR-0391` left it.

## Alternatives considered

### A cancellation flag on the request

Rejected. A flag races the final publish; the generation comparison at
the presentation seam cannot.

### Embedding the running mean in metadata

Rejected — decision 1.

## Consequences

Progressive headless consumers page frames with honest convergence;
the remaining arc rows (descriptors, auxiliary outputs, adapters,
encoding isolation) follow.

## Affected modules

`VoxeliaInteraction` gains the metadata and the session.

## Compatibility impact

Additive only.

## Security impact

None beyond typed admission.

## Performance and memory impact

`O(1)` per publication.

## Validation impact

```text
swift test --filter ProgressiveFrameTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the types, the witness suite and the register updates,
   in the same increment.
2. **Next**: the remaining headless-capability rows.

## Supersession

This record supersedes nothing; `ADR-0122`'s contract is unchanged.

## References

- [ADR-0122 - Render generations](ADR-0122-render-generations.md)
- [ADR-0391 - Progressive convergence exposure](ADR-0391-progressive-convergence-exposure.md)
- [ADR-0397 - The M9 queue](ADR-0397-the-m9-queue.md)

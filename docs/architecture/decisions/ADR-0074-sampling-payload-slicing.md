---
document_id: "ADR-0074"
title: "Sampling payload slicing"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-EXE-002"
  - "VOX-IMG-001"
  - "VOX-ERR-001"
---

# ADR-0074 - Sampling payload slicing

## Context

Accepted `ADR-0071` lifted the extraction operation's geometry and
regular-sampling admission and left irregular, categorical and
externally defined samplings typed rejections pending their own
slicing models. Irregular coordinates and categorical labels carry
per-index payloads whose crop is exact array slicing with no
arithmetic, so no algorithm specification is required. This record was
authored and accepted on 2026-08-05 under the project owner's recorded
broadened autonomous delegation.

## Decision

1. **Alignment rule.** Nothing in the accepted descriptors binds a
   sampling payload count to its axis extent, so a mismatched payload
   is representable; slicing is therefore defined only when the
   payload count equals the source axis extent, and a mismatch is its
   own typed rejection — never a guessed alignment.
2. **Slicing.** For an aligned axis with region bounds
   `[lower, upper)`, irregular coordinates and categorical labels crop
   to the exact element copies at `[lower, upper)`, preserving order
   and values; rebuilt axes revalidate through their accepted
   constructing initializers. Externally defined sampling stays a
   typed rejection: an external definition's slicing semantics are not
   knowable here.
3. **Version bump.** The operation and implementation versions
   advance to `1.2.0`; previously admitted inputs stay bit-identical.

## Alternatives considered

Clamping or padding mismatched payloads was rejected as silent
substitution. Treating the payload as authoritative over the shape was
rejected: the shape owns extents throughout the accepted model.

## Consequences

Irregularly sampled and categorical axes crop exactly, closing the
extraction operation's sampling admission except for the honestly
unknowable external case.

## Affected modules

`VoxeliaExecution` only; no dependency change.

## Compatibility impact

Previously rejected inputs become admitted; everything else is
bit-identical under the advanced version tokens.

## Security impact

Exact element copies of already-validated payloads; the alignment rule
prevents out-of-bounds slicing by construction; existing budgets and
typed payload-free failures apply.

## Performance and memory impact

One payload slice copy per irregular or categorical axis.

## Validation impact

Tests must crop an irregular axis and a categorical axis to the exact
expected payload slices in one execution, prove the advanced version
tokens, reject a misaligned payload typed and keep the externally
defined rejection.

## Migration

Implemented in this increment.

## Supersession

This ADR discharges the `ADR-0071` slicing deferral for the two
knowable samplings and supersedes nothing.

## References

- [ADR-0071 - Geometry-preserving region extraction](ADR-0071-geometry-preserving-region-extraction.md)
- [ADR-0064 - Exact region extraction operation](ADR-0064-exact-region-extraction-operation.md)

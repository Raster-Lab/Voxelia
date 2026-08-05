---
document_id: "ADR-0106"
title: "Pipeline state caching"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-005"
  - "VOX-REP-008"
---

# ADR-0106 - Pipeline state caching

## Context

`VOX-MTL-005` requires shader libraries and pipeline states cached by
stable shader and configuration identities; every kernel construction
recompiled its embedded source and rebuilt its pipelines. The stable
identities already exist — the kernel token, the pinned source digest
and the entry-point name. This record was authored and accepted on
2026-08-05 under the project owner's recorded broadened autonomous
delegation.

## Decision

1. **One per-context cache.** `MetalExecutionContext` owns a
   `MetalPipelineCache`: compiled libraries keyed by the exact source
   digest, pipeline states keyed by kernel token, source digest and
   entry point — the stable identities, never source text comparison
   at lookup, because the digest is pinned to the text by the
   manifest discipline. The class is unchecked-`Sendable` on the
   recorded justification that a lock guards the maps and Metal
   pipeline objects are documented thread-safe.
2. **Kernels acquire through the cache.** Both kernel families fetch
   their pipelines through the cache and map its typed failures into
   their own error surfaces; repeated kernel construction on one
   context reuses compiled state.
3. **Build counts are evidence.** The cache exposes its library and
   pipeline build counts per the coalescing-evidence precedent, so
   reuse is proven by observed counts rather than assumed.

## Alternatives considered

A process-global cache was rejected: pipeline states are
device-bound, and the context is the device boundary. Keying by
source text was rejected: the digest is the registered stable
identity and the manifest pins it to the text. Time-based eviction
was rejected: the compiled set is small and bounded by the closed
family registry; eviction policy would be a governed decision.

## Consequences

`VOX-MTL-005` is discharged for the version-one families; repeated
planner and kernel construction on one context stops recompiling.

## Affected modules

`VoxeliaMetal` only; no dependency change.

## Compatibility impact

Purely additive; kernel error surfaces unchanged.

## Security impact

No new surface; digests stay out of filenames and logs per the
existing sensitivity rule — build counts are integers.

## Performance and memory impact

One compiled library and pipeline set retained per context per
family.

## Validation impact

Tests must construct both kernel families twice on one context and
prove by the exposed build counts that the second constructions
compiled nothing, that distinct entry points hold distinct pipelines,
and that the counts print as evidence.

## Migration

Implemented in this increment.

## Supersession

Extends `ADR-0079` and the `ADR-0080` kernel governance; no record is
superseded.

## References

- [ADR-0080 - Window-level Metal kernel](ADR-0080-window-level-metal-kernel.md)
- [ADR-0105 - Device capability model](ADR-0105-device-capability-model.md)

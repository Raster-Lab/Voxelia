---
document_id: "ADR-0394"
title: "Side-by-side scene binding"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PRR-015"
---

# ADR-0394 - Side-by-side scene binding

## Context

`VOX-PRR-015` (P0, `T,D`, M8): side-by-side comparison with
conventional rendering **using the same authoritative scene state**.
The clinical risk the row names is divergence: two panes that quietly
render different cameras or transfer functions invite conclusions
about the *renderers* that are actually about the *inputs*.

## Decision

1. **`SideBySideComparison` binds both panes to one
   `SceneStateFingerprint` by construction**: the initialiser takes one
   fingerprint and two pane modes (conventional, and a photorealistic
   quality mode), and there is no API that accepts two fingerprints.
   Divergent side-by-side state is unrepresentable, not audited.

2. **The fingerprint is the `ADR-0391` vocabulary** — scene, camera,
   transfer function, source data — so the same identity that gates
   temporal accumulation gates comparison; one notion of "the same
   picture" across the module.

3. **Rendering is not performed here**: the binding hands each pane an
   identical fingerprint alongside its mode; the panes' renderers
   consume it under their own contracts. The comparison object is the
   seam, and the seam is the row.

## Alternatives considered

### Comparing two independently configured render requests

Rejected — the divergence the row exists to prevent would be one
constructor call away.

## Consequences

Hosts build comparison views that cannot desynchronise their inputs.

## Affected modules

`VoxeliaPhotorealistic` gains the binding.

## Compatibility impact

Additive only.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter SideBySideTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the binding, the fixture suite and the register
   updates, in the same increment.
2. **Next**: the multi-dimensional transfer-function row.

## Supersession

This record supersedes nothing.

## References

- [ADR-0391 - Progressive convergence exposure](ADR-0391-progressive-convergence-exposure.md)
- [ADR-0385 - The optional photorealistic module](ADR-0385-the-optional-photorealistic-module.md)

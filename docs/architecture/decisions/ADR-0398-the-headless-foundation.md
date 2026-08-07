---
document_id: "ADR-0398"
title: "The headless foundation"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-API-009"
  - "VOX-HLS-002"
  - "VOX-HLS-003"
  - "VOX-HLS-004"
---

# ADR-0398 - The headless foundation

## Context

The `ADR-0397` queue's first arc: off-screen public APIs, headless
rendering on Apple Silicon macOS, one scene description for both
modes, raw pixel output. The queue's planning note predicted this arc
would be records and witnesses over existing substance, and the survey
confirms it: **no rendering module imports a window system**, the
`SliceRenderer` contract is pure data in and data out, and every
pixel-producing test in the suite already runs windowless on Apple
Silicon macOS. This record says so instead of inventing parallel code.

## Decision

1. **Headlessness is now enforced, not observed**: `SwiftUI`, `AppKit`
   and `UIKit` join the prohibited imports for `VoxeliaRendering` and
   `VoxeliaMetal` (matching `VoxeliaInteraction`, which already carried
   them), and the `VoxeliaPhotorealistic` target — absent from the
   gate since its creation — gains its full entry. The widened gate was
   negative-tested both ways. The rows demanded this boundary; the gate
   is the `ADR-0338` d10 exception working as intended, and it also
   catches that omission honestly.

2. **One description serves both modes by construction**
   (`VOX-HLS-003`): `RenderRequest` over `SceneSnapshot` is the only
   scene description; the interactive coordinators and any headless
   caller consume the same value, and no headless-specific type exists
   to diverge. The witness drives the `SliceRenderer` contract with the
   same request an interactive path records in its provenance.

3. **Raw pixels are the existing publication path** (`VOX-HLS-004`):
   the witness drives a real display mapping through the public
   operation surface and reads the produced sample bytes back through
   the storage contract — raw pixel data, no view, no layer, no
   surface. `VOX-HLS-002`'s `T` is the suite itself — every one of its
   render and pixel tests executes headless on Apple Silicon macOS —
   and this record plus the module notes are the `D`.

4. **`VOX-API-009` is discharged by the same facts**: the public APIs
   the witnesses drive are the public APIs, and nothing in them can
   demand a window without failing the import gate.

## Alternatives considered

### A dedicated headless renderer type

Rejected. It would duplicate the render contract to prove a property
the contract already has; the honest artefact is the gate plus the
witnesses.

## Consequences

Arc 2 builds capabilities on a boundary that cannot silently regress.

## Affected modules

The import gate; witnesses in `VoxeliaRenderingTests`.

## Compatibility impact

None.

## Security impact

Strengthened: window-system coupling in the render stack now fails CI.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
swift test --filter HeadlessFoundationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the gate widening, the witnesses and the register
   updates, in the same increment.
2. **Next**: arc 2, headless capabilities.

## Supersession

This record supersedes nothing.

## References

- [ADR-0397 - The M9 queue](ADR-0397-the-m9-queue.md)
- [ADR-0385 - The optional photorealistic module](ADR-0385-the-optional-photorealistic-module.md)

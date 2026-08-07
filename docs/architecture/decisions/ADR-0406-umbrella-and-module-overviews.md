---
document_id: "ADR-0406"
title: "Umbrella and module overviews"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-REP-007"
  - "VOX-DOC-004"
---

# ADR-0406 - Umbrella and module overviews

## Context

The `ADR-0405` queue's first arc. The umbrella row demands the
`Voxelia` product re-export the stable general-purpose modules and not
auto-re-export the optional integrations; the survey found the
umbrella **imports** its eight modules without re-exporting them, so
`import Voxelia` alone granted nothing — the row's `T` half caught a
real gap. The module-overview row demands purpose, dependencies,
supported platforms and diagnostic status for every public module; the
survey found two modules undocumented and every overview stale at "M0
scaffold".

## Decision

1. **The umbrella genuinely re-exports its eight stable modules**
   (`VOX-REP-007`): `@_exported import` for `VoxeliaSpatial`,
   `VoxeliaCore`, `VoxeliaStorage`, `VoxeliaExecution`,
   `VoxeliaImaging`, `VoxeliaGeometry`, `VoxeliaRendering` and
   `VoxeliaInteraction` — the same set the target has always depended
   on. The optional integrations (`VoxeliaCPU`, `VoxeliaMetal`,
   `VoxeliaCompression`, `VoxeliaDICOMKit`, `VoxeliaPhotorealistic`,
   `VoxeliaValidation`) are **not dependencies of the umbrella
   target**, so non-re-export is structural, exactly as `ADR-0385`
   preserved for the photorealistic module. The witness imports only
   `Voxelia` and uses types from every re-exported module.

2. **Every public module's overview states the four required facts**
   (`VOX-DOC-004`): purpose, direct dependencies, supported platforms
   (Apple Silicon `arm64` on macOS 15+, iOS 18+, tvOS 18+ and
   visionOS 2+, per the manifest and the platform gate) and
   **diagnostic status** — which is a per-module honesty line, not
   boilerplate: the CPU reference paths are the diagnostic
   implementations; Metal entries are approximate or exact per their
   registrations with diagnostic selection owner-gated; the
   photorealistic module is explicitly non-diagnostic presentation.
   The two undocumented modules gain overviews.

## Alternatives considered

### Public typealiases instead of exported imports

Rejected. A typealias catalogue drifts from the modules it mirrors;
the exported import is the tool's mechanism for exactly this row.

## Consequences

`import Voxelia` is now the one-line stable surface the baseline
promised; the overviews are current.

## Affected modules

`Sources/Voxelia` and `docs/architecture/modules/`.

## Compatibility impact

Additive for consumers of `Voxelia`; no other module changes.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter UmbrellaExportTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the exports, the overviews, the witness and the
   register updates, in the same increment.
2. **Next**: the instrumentation and benchmark-reporting arc.

## Supersession

This record supersedes nothing.

## References

- [ADR-0405 - The M10 queue](ADR-0405-the-m10-queue.md)
- [ADR-0385 - The optional photorealistic module](ADR-0385-the-optional-photorealistic-module.md)

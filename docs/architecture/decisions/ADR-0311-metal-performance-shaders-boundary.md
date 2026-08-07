---
document_id: "ADR-0311"
title: "Metal performance shaders boundary"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ADP-006"
---

# ADR-0311 - Metal performance shaders boundary

## Context

`VOX-ADP-006` requires that "Voxelia shall permit Metal Performance Shaders only behind
validated Voxelia operations without leaking MPS types into general APIs". P1, **`I,T`**,
milestone M3, from `ADR-0290`'s sweep.

## The measurement

**Zero** occurrences of `MetalPerformanceShaders`, `MPSImage`, `MPSKernel` or any `MPS`-prefixed
type across `Sources/` and `Tests/`, and the framework is not declared in `Package.swift`.

**`MetalPerformanceShaders` was not in `check_prohibited_imports.py` at all.** So the property
held because nobody had used MPS, and any target could have imported it tomorrow without a
gate objecting — the eighth instance in this arc of a rule that existed with nothing running
it.

## The rule is a boundary, not a ban

The row's wording matters and was nearly misread. It says MPS is **permitted** — *only behind
validated Voxelia operations*. Forbidding it outright would be simpler to enforce and would
answer a different requirement, the same trap `ADR-0302` avoided with temporary files.

The boundary that expresses the row is **the module**. `VoxeliaMetal` may import MPS, because
it is the one target where a validated operation wrapping it would live. **Every other target
refuses it**, and that is what keeps MPS types out of general APIs: a type a module cannot
import is a type it cannot name in a signature — the same structural argument `ADR-0308` made
for windows.

## Decision

1. **`MetalPerformanceShaders` and `MetalPerformanceShadersGraph` are prohibited in every
   target except `VoxeliaMetal`.**
2. **The exemption is one module, not one file.** A narrower rule would have to name the file
   a future operation lives in, which is a rule that is wrong the moment the operation moves.
3. **No Swift test is written.** There is no MPS code to test, and a test asserting that an
   unused framework stays unused would assert what the gate already refuses to allow.
4. **`VOX-ADP-006`'s `I` and `T` are discharged** — the `I` by the boundary, the `T` by the
   two-directional proof below, which is evidence rather than assertion.

## The gate is proven in both directions

Both were run before the change was kept, because a one-directional proof would not
distinguish a boundary from a ban:

```text
import MetalPerformanceShaders in VoxeliaRendering -> failed, named by path   (exit 1)
import MetalPerformanceShaders in VoxeliaMetal     -> passed                  (exit 0)
```

The second is the one that matters. A gate that failed on both would have enforced a
prohibition the requirement does not state.

## Alternatives considered

### Forbid MPS everywhere

Rejected; see above. The row permits it behind an operation, and a stricter rule is not a
better answer to a requirement that says otherwise.

### Permit it in `VoxeliaCPU` as well

Rejected. `VoxeliaCPU` already refuses `Metal` itself, so admitting a Metal acceleration
framework there would contradict a boundary that predates this record.

### Wait until MPS is actually used

Rejected, for the eighth time in this arc. The gate costs two lines now; after the first use it
would be a refactor, and the leak it prevents is exactly the kind that arrives with the first
use.

## Consequences

`VOX-ADP-006` is discharged, and MPS can only ever enter through the one module where a
validated operation could wrap it.

**7 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. One gate change. No source file changed.

## Compatibility impact

None. No target imports MPS today.

## Security impact

None directly.

## Performance and memory impact

None. The gate is unchanged in cost.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record and the gate change.
2. **Next**: the derived queue's remaining 7 rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **adds a boundary** the prohibited-import gate had never
carried.

## References

- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0302 - Declared temporary file sites](ADR-0302-declared-temporary-file-sites.md)
- [ADR-0303 - Headless rendering enforced](ADR-0303-headless-rendering-enforced.md)
- [ADR-0308 - Public API needs no window](ADR-0308-public-api-needs-no-window.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

---
document_id: "ADR-0303"
title: "Headless rendering enforced"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-HLS-001"
---

# ADR-0303 - Headless rendering enforced

## Context

`VOX-HLS-001` requires that "Voxelia shall support off-screen rendering without an
application window". P0, **`T,D`**, milestone M4, from `ADR-0290`'s sweep.

## The measurement

`Sources/` was scanned for every way a window or a view enters a Swift target — `import
AppKit`, `import UIKit`, `import SwiftUI`, `import MetalKit`, and the `CAMetalLayer`,
`NSWindow`, `UIWindow` and `MTKView` types.

**Zero hits.** The product is headless in fact, and the byte-exact off-screen renders in the
slice, volume and multiplanar suites — twenty-one tests, now tagged `[Pipeline]` by
`ADR-0301` — are what demonstrates it.

## The finding, after a correction

The first pass at reading `check_prohibited_imports.py` reported `VoxeliaMetal` as forbidding
**nothing**. That was wrong: it forbids `DICOMKit`, `RealityKit`, `ModelIO`, `CoreImage` and
`VoxeliaCompression`. The entry spans several lines and a single-line pattern missed it, which
is why it was read directly before anything was written about it.

The real gap is narrower and sharper. Every other target forbids `MetalKit`; **`VoxeliaMetal`
does not** — and it is the one target that talks to the GPU and the one where an `MTKView`
would plausibly be reached for. `AppKit`, `UIKit` and `SwiftUI` were forbidden in
`VoxeliaInteraction` alone, so any other target could have imported them freely.

So the row's property held, and was enforced everywhere except where it mattered most.

## Decision

1. **Every product target refuses `AppKit`, `UIKit`, `SwiftUI` and `MetalKit`.** The four are
   applied uniformly on top of each target's existing prohibitions rather than being pasted
   into eleven separate sets, so a target added later cannot be given a windowing exemption by
   forgetting to type one.
2. **`VoxeliaMetal` is included, deliberately and by name.** It is the target the omission
   actually mattered for.
3. **`VOX-HLS-001`'s `T` is discharged** by the existing byte-exact off-screen renders, now
   backed by a gate that keeps them off-screen.
4. **Its `D` is not claimed.** The standing rule in this project's ledger is explicit:
   *byte-exact off-screen renders discharge Test, never Demonstration.* A demonstration is an
   owner-witnessed activity and no test can supply it.

## The gate is proven able to fail

`import MetalKit` was added to `MetalSliceRenderer.swift`, the check reported it by path, and
the file was restored:

```text
Prohibited import check failed:
- Sources/VoxeliaMetal/Public/MetalSliceRenderer.swift imports MetalKit
```

Before this change that import would have passed.

## Alternatives considered

### Add the four frameworks to each target's set individually

Rejected. Eleven near-identical edits are eleven chances to omit one, and the omission this
record fixes is exactly that failure mode having already happened once.

### Also forbid `QuartzCore`

Rejected as too broad. `CAMetalLayer` lives there, but so does much that has nothing to do
with windowing, and a prohibition that has to be argued about at every use is one that gets
relaxed. No target imports it today, and adding one would be visible in review.

### Claim the `D` from the off-screen renders

Refused. The ledger rule that forbids exactly this predates this increment, and human
verification methods are recorded as gaps in this project rather than treated as passing.

### Treat the row as satisfied because nothing imports a window

Rejected, for the sixth time in this arc. A property that holds by accident is not a property
the project maintains.

## Consequences

`VOX-HLS-001`'s test obligation is discharged, and the headless property is enforced at the
rendering target rather than everywhere except it.

The row stays open on its `D`, alongside `VOX-VAL-006`'s `R`.

**12 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. One gate change. No source file changed.

## Compatibility impact

None. No existing import is affected, because none of the four is used.

## Security impact

None directly. A windowing dependency would widen the product's surface, and it can no longer
appear unnoticed.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
Tools/Scripts/validate-docs.sh
Tools/Scripts/test-repository-scripts.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1229 tests in 217 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record and the gate change.
2. **Next**: the derived queue's remaining 12 rows.
3. **Owner**: **one new item** — `VOX-HLS-001`'s Demonstration, which a test cannot supply.

## Supersession

This record supersedes nothing. It **extends** `check_prohibited_imports.py` to the target its
windowing prohibition had omitted.

## References

- [ADR-0256 - Compression module boundary](ADR-0256-compression-module-boundary.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0301 - Enforce the test level taxonomy](ADR-0301-enforce-the-test-level-taxonomy.md)
- [ADR-0302 - Declared temporary file sites](ADR-0302-declared-temporary-file-sites.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

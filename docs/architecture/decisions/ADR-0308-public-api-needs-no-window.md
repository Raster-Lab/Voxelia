---
document_id: "ADR-0308"
title: "Public API needs no window"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-008"
---

# ADR-0308 - Public API needs no window

## Context

`VOX-API-008` requires that "public APIs shall not require an interactive window, SwiftUI view
or AppKit view". P0, **`I,T,D`**, milestone M3, from `ADR-0290`'s sweep.

`ADR-0303` discharged the neighbouring `VOX-HLS-001` two increments ago. The rows are not the
same claim, and separating them is the first thing this record has to do.

## The two rows are different claims

- **`VOX-HLS-001`** is a **capability**: off-screen rendering is supported.
- **`VOX-API-008`** is an **absence of a precondition**: no public entry point *requires* a
  window to be called at all.

A library could satisfy the first and fail the second — by offering an off-screen path beside
a public API whose signature still demands a view. So the same evidence bears on both, and
each needs its own reading of it.

## The measurement

Two facts, and the second is the sharper one:

1. **No target imports `AppKit`, `UIKit`, `SwiftUI` or `MetalKit`**, and since `ADR-0303` none
   can. A module that cannot import a framework cannot name its types in a public signature,
   so the prohibition is structural rather than a convention.
2. **No public API returns or accepts a drawable.** `drawable` and `Drawable` appear **zero**
   times across `Sources/`. This matters independently of the first: a renderer returning a
   `CAMetalDrawable` would require a layer to exist even in a module that imported nothing
   from AppKit, because the drawable comes from the layer.

The first fact rules out naming a view. The second rules out needing one.

## Decision

1. **`VOX-API-008`'s `I` is discharged.** The property is enforced by `ADR-0303`'s uniform
   import prohibition, and the drawable-free surface means no public type carries a window
   requirement in disguise.
2. **Its `T` is discharged by the existing off-screen renders**, read for *this* row rather
   than borrowed from `VOX-HLS-001`: those twenty-one `[Pipeline]` tests call the public
   rendering API in a process where no window, view or layer exists at all. If any public entry
   point required one, they could not run.
3. **No new test is written.** A test asserting "this API can be called without a window" in a
   suite where no window can exist would assert nothing the suite does not already assert by
   running.
4. **No new gate is written.** A scan for UI type names in public signatures would duplicate
   `check_prohibited_imports.py`, which already makes those names unreachable. The one thing it
   would add — catching a drawable — is worth stating rather than automating: `MTLDrawable`
   comes from `Metal`, which `VoxeliaMetal` legitimately imports, so a gate would have to
   allow the import and forbid one type from it, which is a rule that gets relaxed the first
   time it is inconvenient.
5. **Its `D` is not claimed**, consistent with `VOX-HLS-001` and `VOX-MTL-009`.

## Alternatives considered

### Treat this row as already discharged by `ADR-0303`

Rejected. That record claims `VOX-HLS-001`, and the two rows make different claims; folding
them would leave `VOX-API-008` discharged by a record that never mentions it, which is the
untraceability `ADR-0300` had to untangle.

### Add a gate forbidding `MTLDrawable` in public signatures

Rejected; see decision 4. The absence is recorded here and is visible in review, and a
single-type prohibition inside an allowed framework is a rule with a short life.

### Write a test that calls a public API with no window

Rejected; see decision 3. Every test in the repository already does this, because no test
creates a window.

## Consequences

`VOX-API-008`'s implementation and test obligations are discharged on evidence read for this
row, and the distinction between a capability and an absent precondition is written down.

The row stays open on its `D`.

**10 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. This record adds no code and no gate.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining 10 rows.
3. **Owner**: **one new item** — `VOX-API-008`'s Demonstration.

## Supersession

This record supersedes nothing. It **claims** a row that `ADR-0303`'s gate had already made
true without naming it.

## References

- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0300 - CPU Metal differential references](ADR-0300-cpu-metal-differential-references.md)
- [ADR-0303 - Headless rendering enforced](ADR-0303-headless-rendering-enforced.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

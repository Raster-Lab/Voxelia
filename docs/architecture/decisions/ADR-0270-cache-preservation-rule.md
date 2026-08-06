---
document_id: "ADR-0270"
title: "Cache preservation rule"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
  - "VOX-CMP-012"
---

# ADR-0270 - Cache preservation rule

## Context

`VOX-CMP-012` requires that original DICOM instances are preserved when JP3D or other
toolkit-native cache formats are generated. It declares `T,R`.

The row is **conditional** — "when ... are generated" — and Voxelia generates no
caches. `ADR-0269` has just evaluated JP3D as a volume cache and found decoding one
slower than re-importing the source, so none is planned either.

That makes "vacuously satisfied" the tempting answer, and it is the wrong one. A
safety constraint on a capability is worth making enforceable **before** the
capability exists, not after; and this project has repeatedly found that "nothing
does X yet" is a reason to write the rule down in code rather than a reason to skip
it.

## The finding: the accepted identity model permits exactly what this row forbids

`DataIdentity`'s admission is an **or**:

```swift
guard contentID != nil || !sourceIdentities.isEmpty || derivation != nil
else { throw DataIdentityError.missingClaims }
```

So an identity carrying **a derivation and no source identities at all** is perfectly
legal. A cache published that way would record which operation produced it while
losing every trace of which patient instances it came from — precisely the detachment
`VOX-CMP-012` exists to prevent.

**The accepted model is not wrong.** It admits many kinds of object, most with no
DICOM ancestry, and tightening a Core-wide admission would refuse legitimate ones. The
preservation obligation is specific to caches generated from imported instances, so it
belongs at the boundary that knows it applies.

A test constructs the detached identity successfully and then shows only this rule
refusing it, so the gap is demonstrated rather than asserted.

## Decision

1. **`CachePreservationRule.admit(cache:generatedFrom:)` enforces preservation at the
   compression boundary**, not by changing `DataIdentity`.
2. **A cache must carry every source identity the original carried.** A **superset is
   permitted** — one cache may legitimately span several imported series — and a
   **subset is refused**, because it has dropped instances the original accounted for.
   The subset case is the subtler one: such a cache looks properly attributed until
   someone notices an instance is missing.
3. **A cache must declare a derivation naming at least one input.** Source identities
   alone say which instances it relates to, not that it was generated from them.
4. **A cache must not claim the original's object identifier.** An object published
   under its source's own name replaces it in the registry, which is the deletion this
   row prevents arriving as an update rather than as a delete.
5. **The rule inspects and never mutates.** A test asserts the original is unchanged,
   because preservation that altered the thing being preserved would be
   self-defeating.
6. **`VOX-CMP-012`'s `T` is discharged; its `R` is left to the owner.** Review is not
   this project's to perform, following `ADR-0254`'s handling of `VOX-VS1-021`.
7. **No algorithm specification and no oracle.** The rule is set comparison and
   equality.

## The empty-derivation case is reachable, and only one way

`DerivationIdentity` already refuses an empty input sequence unless
`declaresZeroInputGenerator` is set. So `derivationNamesNoInput` fires only for a
cache that declares itself a zero-input generator while in fact having an input —
which is a lie about its own provenance, and worth catching rather than a dead branch.

## What building this cost, and what it caught

Two fixture attempts were refused by the accepted model before the tests ran:

- `DerivationInputRole` is a validated string struct, not an enum with a `.primary`
  case.
- `parameterDigest` requires the **operation-parameters** projection; a
  `sampleBytesIdentity` is refused with `unsupportedParameterProjection`.

Both refusals are the model keeping claim kinds distinct, and both are recorded
because they are the sort of thing a later reader would otherwise rediscover.

## Alternatives considered

### Declare the row vacuously satisfied, since no cache generation exists

Rejected. It is true and useless, and it would leave a P0 safety constraint with
nothing enforcing it at the moment someone adds cache generation.

### Tighten `DataIdentity` to require source identities alongside a derivation

Rejected. Many derived objects legitimately have no DICOM ancestry — a rendered slice
derived from a synthetic volume, for instance — and a Core-wide rule would refuse
them. The obligation is contextual, so the check is too.

### Also require the cache to be published before admitting it

Rejected. The rule is about identity structure, and coupling it to publication would
make it untestable without a coordinator and would fire too late — after the object
existed.

### Require an exact match of source identities rather than a superset

Rejected; see decision 2. It would refuse a legitimate multi-series cache, and the
hazard is dropping instances, not gaining them.

## Consequences

`VOX-CMP-012`'s `T` is discharged and its `R` is outstanding with the owner.

A gap in the accepted identity model is documented: a derivation with no source
identities is admissible, and any future path that publishes derived objects from
imported instances should consider whether it needs this rule too.

Compression rows discharged: `002`, `003`, `004`, `005`, `007`, `009`, `010`, `012`
(`T`), `013`, and `008` (`T`). Remaining: `006`, `011`, `014`, plus the `A` and `R`
halves noted.

## Affected modules

`VoxeliaCompression` gains `CachePreservationRule` and its failure family. No other
module changes; nothing new is imported.

## Compatibility impact

Additive.

## Security impact

Positive. The specific harm — a cache that severs the link between derived pixel data
and the patient instances it came from — is now refused rather than merely
discouraged, and the replacement-by-identifier case is refused with it.

## Performance and memory impact

Two set constructions per admission, over source-identity lists.

## Validation impact

```text
swift build && swift test
swift test --filter "CachePreservationRule"
python3 Tools/Scripts/check_swift_safety.py
swift format lint --strict Sources/VoxeliaCompression/Public/CachePreservationRule.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1086 tests in 200 suites pass.

## Migration

1. This record.
2. **Next**: `VOX-CMP-014` benchmarks, then `VOX-CMP-006` — which should also answer
   `ADR-0269`'s `levelsZ` question — then `VOX-CMP-011`'s adversarial work last.
3. **Owner**: `VOX-CMP-012`'s Review, alongside the five decisions already open.

## Supersession

This record supersedes nothing. It **documents a permissive case** in `ADR-0042`-era
identity admission rather than changing it.

## References

- [ADR-0254 - First slice validation and benchmark reports](ADR-0254-first-slice-validation-and-benchmark-reports.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0269 - JP3D and HTJ2K evaluation](ADR-0269-jp3d-and-htj2k-evaluation.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

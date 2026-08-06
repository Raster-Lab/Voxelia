---
document_id: "ADR-0257"
title: "Toolkit native representation labelling"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-CMP-013"
---

# ADR-0257 - Toolkit native representation labelling

## Context

`ADR-0255` decision 4 called this the most consequential correctness rule in the
compression arc: **a toolkit-native representation must never be represented as a
standard DICOM transfer syntax** (`VOX-CMP-013`, `I,T`). Mislabelling a JP3D cache
as a DICOM transfer syntax would make Voxelia emit objects claiming
interoperability they do not have.

`ADR-0256` deliberately gave `CompressedPayload` **no** format identifier, because
adding one before this rule existed is how the distinction gets lost. This
increment supplies the rule, so an identifier can exist safely.

## Decision

1. **The two kinds are made provably disjoint by one predicate used in opposite
   directions.** A standard transfer syntax admits only UID-shaped identifiers; a
   toolkit-native name admits only identifiers that are **not** UID-shaped. So
   `standard ⟹ UID-shaped` and `toolkitNative ⟹ not UID-shaped`, and no identifier
   can be admitted as both. Disjointness is a consequence of the admissions rather
   than a convention, and a test asserts it over the same identifier set from both
   sides.
2. **A conservative UID *shape* test is frozen, and it is not a UID validator.**
   `DICOMUIDShape.isUIDShaped` answers only "could this be mistaken for a transfer
   syntax UID?". The frozen predicate: non-empty, at most 64 characters, only ASCII
   digits and full stops, at least two components, no empty component.
3. **Leading zeros are deliberately not rejected**, so `"01.02"` counts as
   UID-shaped. The test's job is to *refuse* toolkit names that look UID-like, so
   over-inclusiveness is the safe direction. It would only be a hazard if this test
   also authorised the standard case — it does not; it gates an identifier's shape,
   never its meaning.
4. **A toolkit-native value yields no transfer syntax UID at all.**
   `declaredTransferSyntaxUID` is `nil` for it. A caller writing a DICOM header
   cannot obtain a UID for a toolkit-native cache even by mistake, because none
   exists to obtain.
5. **Naming a syntax is not supporting it.** The standard case records what a
   *source declared*; no codec is linked, so the property is named
   `declaredTransferSyntaxUID` rather than anything implying capability.
6. **The storage is private and the only construction paths are the throwing
   factories** — see the finding below.
7. **No algorithm specification and no oracle.** The predicate is lexical, not
   arithmetic; no numeric boundary is frozen. `ADR-0209` set the precedent for a
   vocabulary increment carrying no `ALG`.

## The finding: my first version's enforcement was not structural, and compiling the bypass proved it

The type was first written as a **public enum** with cases
`.standard(declaredTransferSyntaxUID:)` and `.toolkitNative(name:)`, plus throwing
factory methods that enforced the disjointness. Its documentation claimed the
requirement was enforced structurally.

**It was not.** Public enum cases are constructible directly, so a caller could
write:

```swift
CompressedRepresentation.toolkitNative(name: "1.2.840.10008.1.2.4.201")
```

and obtain a toolkit-native value carrying the HTJ2K lossless transfer syntax UID,
bypassing every admission. The disjointness held only for callers who chose to use
the factories — which is precisely the "asking the reader to be careful" that
`ADR-0256` decision 2 rejected.

**The six tests all passed, because every one of them used the factories.** A test
suite that only exercises the intended path cannot find an unintended one. The hole
was found by writing the bypass in a scratch package and **compiling it**, which
succeeded.

The fix is a `struct` with a private nested `Kind`, a private initialiser, and the
throwing factories as the only construction paths. Recompiling the same bypass now
fails with "type 'CompressedRepresentation' has no member 'toolkitNative'".

**Generalisation worth keeping:** when a record claims an invariant is *structural*,
the check is not whether the tests pass — it is whether the violation still
compiles. For a value type, that means asking whether every construction path runs
the admission, and public enum cases never do.

## Alternatives considered

### Keep the public enum and rely on the factories

Rejected; see the finding. It makes the invariant a convention, and the record would
have overstated it.

### Validate the standard case's UID against a list of known transfer syntaxes

Rejected. Voxelia links no codec, so a list would either claim support it does not
have or reject syntaxes a source legitimately declared. The shape test carries no
such claim.

### Reject leading zeros, matching conformant UID component rules

Rejected; see decision 3. It would make the predicate *less* inclusive and therefore
admit `"01.02"` as a toolkit name — the wrong direction for a test whose purpose is
refusal.

### Require at least three components, since real transfer syntax UIDs are long

Rejected. It would admit `"1.2"` as a toolkit name, and an identifier that reads as
a UID prefix is exactly the sort of thing that later gets extended into one.

### Put the labelling on `CompressedPayload` directly

Deferred, not rejected. Attaching a representation to a payload is a shape decision
belonging to increment (e) (`VOX-CMP-003`, `VOX-CMP-008`); this increment supplies
the vocabulary that makes such an attachment safe.

## Consequences

`VOX-CMP-013` is discharged in both declared methods: inspection of the disjoint
admissions and the absent accessor, and tests over both identifier sets.

A format identifier can now exist in this arc without the mislabelling hazard
`ADR-0256` decision 3 avoided by omitting one.

## Affected modules

`VoxeliaCompression` gains `CompressedRepresentation`, `DICOMUIDShape` and a
failure family. No other module changes; nothing new is imported.

## Compatibility impact

Additive.

## Security impact

Positive. Emitting a toolkit-native cache labelled as a standard transfer syntax
would produce an object that other systems would attempt to decode as
interoperable. That is now impossible through this type rather than merely
discouraged.

## Performance and memory impact

None. One bounded string scan per admission.

## Validation impact

```text
swift build && swift test
swift test --filter "CompressedRepresentation"
python3 Tools/Scripts/check_swift_safety.py
swift format lint --strict Sources/VoxeliaCompression/Public/CompressedRepresentation.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1037 tests in 193 suites pass. The bypass was compiled before the fix (it built)
and after (it fails to compile), which is the evidence for decision 6.

## Migration

1. This record.
2. Increment (c): `VOX-CMP-010`, adapter admission of dimensions, component formats
   and decoded byte counts, with the destination ceiling that narrows
   `VOX-CMP-011`.
3. Then (d) `VOX-CMP-009` cancellation, and (e) `VOX-CMP-003` and `VOX-CMP-008`
   shapes, where a representation becomes attached to a payload.
4. **Owner decisions, unchanged**: reconciling the six blocked rows, and whether a
   codec may be declared a direct dependency.

## Supersession

This record supersedes nothing.

## References

- [ADR-0209 - Display colour vocabulary](ADR-0209-display-colour-vocabulary.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0256 - Compression module boundary](ADR-0256-compression-module-boundary.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

---
document_id: "ADR-0307"
title: "First useful image is unbuilt"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PER-006"
---

# ADR-0307 - First useful image is unbuilt

## Context

`VOX-PER-006` requires that "the first useful image shall be available before full study cache
generation completes". P0, **`T,D`**, milestone M4, from `ADR-0290`'s sweep.

## The measurement, and how this row differs from the last six

The six rows before this one were all the same shape: a property that held, designed for and
unevidenced. **This one is different, and saying so is the point of the record.**

- **There is no study cache.** The only caches in the product are
  `CachePreservationRule` (compression), `BrickResultCache` and `ContentResultCache`
  (execution). None of them is a study-level artefact whose *generation* has a completion to
  be earlier than.
- **There is no incremental publication.** `CTImportSession.importVolume` returns a single
  `CTImportedVolume` when every stage has finished. A caller receives one value or an error.

So the row is **unbuilt**, not unenforced. There is nothing to evidence, and a test written
today could only assert that the property is absent.

## The tension worth recording before anyone builds it

`CTImportSession` already has seven checkpoints — `metadataRead(n)`, `grouping`,
`frameValidation`, `decode(n)`, `assembly`, `identity`, `final` — and they look like
publication points. **They are not.** They are cancellation probes, and `ADR-0249` decision 7
made the last one load-bearing: *a caller cannot publish what it never receives*, which is
what makes "cancellation prevents publication" structural rather than a rule the caller has to
remember.

An increment that satisfied `VOX-PER-006` by emitting a partial volume at `decode(n)` would
**dismantle that guarantee**, and it would do so in a way that looks like reuse of an existing
seam. The two properties are compatible — cancellation-safety is about what a caller receives
after cancelling, progressive availability is about what it receives while succeeding — but
only if the progressive path is built as its own thing rather than by relaxing a checkpoint.

## Decision

1. **`VOX-PER-006` is not discharged, and no test is written.** A test asserting that a
   progressive path behaves correctly, when there is no progressive path, would be a test of
   the test.
2. **The row is recorded as unbuilt** rather than untested, so its cost is not mistaken for a
   tagging exercise like `VOX-VAL-006`'s.
3. **`ADR-0249` decision 7 is not to be relaxed to satisfy this row.** Any progressive
   publication is a new surface that must preserve "a cancelled import publishes nothing",
   and a future record has to say how.
4. **Two things must be defined before implementation**, and neither is decided here:
   - what a **study cache** is, since the row's clock starts at its generation;
   - what makes an image **useful**, since "first" is meaningless without it — a single decoded
     frame, a full plane, or a volume at reduced resolution are three different answers with
     three different costs.
5. **The `D` remains an owner item** regardless, as with `VOX-HLS-001` and `VOX-MTL-009`.

## Alternatives considered

### Write a test against `CTImportSession`'s checkpoints

Rejected; see decision 1 and the tension above. The checkpoints are cancellation probes, and a
test treating them as publication points would encode exactly the misreading this record
exists to prevent.

### Declare the row satisfied because import is already streamed frame by frame

Rejected. Reading frames one at a time is not the same as *publishing* an image before the
import finishes, and the aggregate return type makes the difference observable: there is no
value a caller can hold before the end.

### Open an arc with an implementation plan

Rejected as premature. The two definitions in decision 4 are the owner's to shape — "useful"
in particular is a clinical judgement about what a radiologist can act on, not an engineering
one — and an arc opened before them would encode a guess as a frozen boundary.

## Consequences

`VOX-PER-006` is recorded as unbuilt with its blocking definitions named, and the guarantee a
naive implementation would break is written down before the implementation exists.

**11 entered-milestone rows remain** from `ADR-0290`'s sweep — unchanged.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining rows. `VOX-PER-006` resumes only after decision 4's
   two definitions exist.
3. **Owner**: **two new items** — what constitutes a study cache, and what makes an image
   useful. Both gate this row; the second is a clinical judgement rather than an engineering
   one.

## Supersession

This record supersedes nothing. It **records a row as unbuilt** and protects `ADR-0249`'s
cancellation guarantee from being spent to satisfy it.

## References

- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0305 - Open the residency duplication row](ADR-0305-open-the-residency-duplication-row.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

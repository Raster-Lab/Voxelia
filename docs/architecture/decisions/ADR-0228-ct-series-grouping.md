---
document_id: "ADR-0228"
title: "CT series grouping"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-004"
  - "VOX-DCM-009"
  - "VOX-VS1-002"
---

# ADR-0228 - CT series grouping

## Context

`ADR-0226` decomposed the DICOM ingest arc; `ADR-0227` performed increment (a),
the neutral `CTFrameDescription`. This record performs increment (b): grouping
frames into series and ordering them, for `VOX-DCM-004` and `VOX-VS1-002`.

The arc's ledger entry set an expectation for this increment — that grouping
should use only rules needing no tolerance, and hand every approximate judgement
to increment (c) — and said that if the split turned out not to hold, the
finding belonged in the record rather than in a silently widened rule. The split
does hold. Something else did not.

## The finding: `ADR-0227` cannot say which series a frame belongs to

`CTFrameDescription` carries a `sourceIdentity` naming **the frame** and an
optional `frameOfReference`. Neither identifies a series:

- `sourceIdentity` is per-frame by construction — it is what distinguishes one
  slice from the next.
- A frame of reference is shared across **every** series in a study that was
  acquired without moving the patient. Two separate acquisitions routinely share
  one, so it cannot separate them.

So a set of descriptions from two co-located acquisitions is, to increment (a)'s
vocabulary, indistinguishable from one acquisition with duplicated geometry. No
grouping rule over the accepted fields can separate them, and geometry alone
never can: the whole point of two co-located scans is that they occupy the same
space.

**`ADR-0227` therefore has an omission, found by building the increment that
consumes it.** It is recorded here rather than by editing that accepted record.

`VOX-DCM-004` is worth reading precisely on this point: it requires assembly
"using spatial position and orientation rather than filename or instance number
**alone**". A series identity is neither a filename nor an instance number; it
is identity supplied by the source. The requirement forbids leaning on ordinal
accidents, not on identity.

## Decision

1. **`CTFrameDescription` gains a required `seriesIdentity: SourceIdentity`.**
   It is additive, it is a fact about the source in exactly the sense
   `ADR-0227` decision 3 means, and it sits beside the existing per-frame
   `sourceIdentity` as its series-level sibling. `ADR-0227` is **not edited**;
   this record carries the correction, and the commit message states it.
2. **The grouping key is identity only: series identity, coordinate space, and
   frame of reference.** Both frame-of-reference-absent groups together; absent
   never matches present, following the accepted `SourceIdentity` treatment of
   an absent version.
3. **No scanner-supplied approximate value takes part in the key** — not
   orientation, not spacing, not position, not the grid extents, not the scalar
   format, not the presentation terms. This is the record's central decision and
   it is not a preference. Scanners emit orientation and spacing as decimal
   strings, and two spellings of one intended value can parse to doubles
   differing in the last bit. Keyed on orientation, such a series **splits into
   single-frame groups**, each internally consistent, and the pipeline builds
   several volumes where it should have reported one irregular series. Excluding
   it delivers the near-agreeing frames to increment (c) as **one group**, which
   is the only place a tolerance may be decided.
4. **The grid extents and scalar format are excluded for the same reason, and
   this is deliberate even though a volume plainly requires a uniform grid.**
   Mixed extents make a group invalid, and "invalid" is increment (c)'s verdict
   to return. Keying on them would convert a rejectable series into two
   accepted volumes, which is the worse failure by a wide margin.
5. **The coordinate space is in the key despite being spatial**, because it is a
   Voxelia-assigned tag rather than scanner-supplied data. It cannot nearly
   agree, and the projection stage has no defined meaning across two spaces. The
   distinction from decision 3 is the provenance of the value, not its subject.
6. **Ordering is by projection on a reference normal**, frozen by
   `VOXELIA-ALG-0047` with an independent oracle: an unnormalised cross product
   of the anchor frame's row and column directions, then a dot product with each
   image position, in a fixed expression order with no fused multiply-add, no
   epsilon and no square root.
7. **The anchor is the member first in exact `SourceIdentity` byte order**, so
   the entire result is a pure function of the **set** of frames rather than of
   their arrival sequence. Ties in projection break the same way. Because
   orientation is not part of the key, a group may hold frames whose normals
   differ; choosing one member's axis is a **stated choice, not a claim that the
   group is coherent**.
8. **Three facts are reported and none is an error here**: a degenerate
   reference normal from parallel directions, a non-finite normal, and a
   non-finite projection. When any holds, ordering by projection has no meaning
   and falls back to identity order, with the projections still reported as the
   evidence. Rejecting or warning is `ADR-0226` decision 7's assignment to
   increment (c).
9. **The normal is not normalised.** A square root would add a magnitude
   threshold to argue about and would leave the ordering unchanged, since
   positive scaling preserves it.
10. **Duplicate detection is not performed here.** Equal projections tie and are
    ordered deterministically; whether a tie means a duplicate is
    `VOX-DCM-009`'s question and increment (c)'s verdict.

## Alternatives considered

### Key the grouping on orientation and spacing

Rejected; see decision 3. It is the intuitive design and it fails in the
direction that produces plausible wrong volumes instead of diagnostics.

### Key on the grid extents, since a volume needs a uniform grid

Rejected; see decision 4.

### Derive a series identity from `sourceMetadata`

Rejected. It would require this code to know DICOM-specific metadata keys,
putting a parser's vocabulary inside a type whose whole purpose is to be
neutral, and `ADR-0226` decision 5 keeps DICOM knowledge out of increments (a)
through (d).

### Take the grouping key from the caller as a closure or parallel array

Rejected. It moves an accepted invariant out of the value that carries it, and
no accepted type in this project takes its identity from a side channel.

### Edit `ADR-0227` to add the field

Rejected. It is accepted, and the standing rule is to implement the corrected
rule and record the correction. A record that quietly grows a field it never
decided is worth less than one that is visibly amended by its successor.

### Normalise the reference normal

Rejected; see decision 9.

### Order by the z coordinate, or by any single positional axis

Rejected, and fixture F4 of `VOXELIA-ALG-0047` exists to catch it: with an
oblique orientation the correct order is not the order of any coordinate.

### Let increment (b) reject degenerate or non-finite geometry

Rejected; see decision 8 and `ADR-0226` decisions 6 and 7. Rejection needs a
tolerance policy this increment is explicitly not allowed to set.

## Consequences

Increment (c) receives groups that may be invalid, and that is the intent: a
near-agreeing series arrives whole, so the validator can reject it as one thing
and name the frames responsible.

`CTFrameDescription` gains a stored member, so a clean rebuild is required
before verification per the standing cross-module layout rule.

The `ADR-0227` omission is now recorded in two places — this record and the
implementing commit — rather than in an edited record that would read as though
it had always been right.

## Affected modules

`VoxeliaImaging`: `CTFrameDescription` gains `seriesIdentity`, and the module
gains the series-assembly type, its group value and its observation set. No
module's dependencies change. No third-party dependency is added.

## Compatibility impact

`CTFrameDescription`'s initialiser gains a required parameter. The type is one
increment old, is not in a released tag, and has no source callers outside its
own tests, so no accepted consumer breaks.

## Security impact

None. The failure family stays payload-free, and the reported observations name
conditions rather than values.

## Performance and memory impact

Grouping is one pass building the key map; ordering is one sort per group. The
cross product is computed once per group, not once per frame.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0228-series-grouping-oracle.py
rm -rf .build && swift build && swift test
swift format lint --strict <touched Swift files>
python3 Tools/Scripts/check_swift_safety.py
python3 Tools/Scripts/generate_requirement_index.py --check
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This increment: `VOXELIA-ALG-0047`, its oracle, and this record.
2. Next: the `seriesIdentity` field and the series-assembly implementation,
   verified against every frozen fixture, with a clean rebuild first.
3. Increment (c): irregular-geometry rejection, which decides every tolerance
   this record deliberately withheld.

## Supersession

This record supersedes nothing. It performs increment (b) of `ADR-0226` and
records an omission in `ADR-0227` without editing it.

## References

- [ADR-0226 - DICOM ingest arc](ADR-0226-dicom-ingest-arc.md)
- [ADR-0227 - Neutral CT frame description](ADR-0227-neutral-ct-frame-description.md)
- [VOXELIA-ALG-0047 - CT series grouping and slice ordering](../../algorithms/VOXELIA-ALG-0047-series-grouping-and-ordering.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

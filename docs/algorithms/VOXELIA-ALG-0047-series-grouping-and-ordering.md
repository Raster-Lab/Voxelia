---
document_id: "VOXELIA-ALG-0047"
title: "CT series grouping and slice ordering binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# CT series grouping and slice ordering binary64-v1

## Purpose

This specification defines `series-grouping/binary64-v1`, the deterministic
assembly of neutral CT frame descriptions into ordered series, selected by
accepted
[`ADR-0228`](../architecture/decisions/ADR-0228-ct-series-grouping.md).
It fixes which frames belong together, in what order they sit, and which facts
about a group are reported rather than judged.

It serves `VOX-DCM-004` and `VOX-VS1-002`: a series is assembled from spatial
position and orientation, not from a filename or an instance number.

## The grouping key is identity only

Two frames join the same group when, and only when, all three of the following
match exactly:

1. the **series identity**, as the exact accepted `SourceIdentity` tuple, with
   an absent version distinct from every present version;
2. the **coordinate space** identifier, as exact UTF-8 bytes;
3. the **frame of reference** — both absent, or both present and exactly equal
   in namespace and identifier. Absent never matches present.

**Nothing scanner-supplied and approximate takes part in the key.** Row and
column directions, both spacings, the image position, the grid extents, the
scalar format and every presentation term are deliberately excluded.

This exclusion is the specification's central rule, and it exists because the
alternative fails silently. Real scanners emit orientation and spacing as
decimal strings, and two spellings of the same intended value can parse to
doubles that differ in the last bit. If orientation were part of the key, such a
series would be **split into several single-frame groups**, each internally
consistent, and the pipeline would build several volumes instead of reporting
one irregular series. Excluding it means the near-agreeing frames arrive at the
geometry validator as **one group**, which is the only place a tolerance may be
decided.

The coordinate space is in the key despite being spatial, because it is a
Voxelia-assigned tag rather than scanner-supplied data: it cannot "nearly
agree", and the projection stage below has no defined meaning across two spaces.

## Groups are emitted in a deterministic order

Groups are ordered by their key: series namespace bytes, then series identifier
bytes, then the version rank (absent before present) and its bytes, then the
coordinate-space bytes, then the frame-of-reference rank (absent before present)
and its namespace and identifier bytes.

## The reference normal

Ordering needs one axis per group. Because orientation is not part of the key, a
group may contain frames whose orientations differ, so the axis must be chosen
by a stated rule rather than assumed unique.

The **anchor** is the group member that is first in exact `SourceIdentity` byte
order. The reference normal is the cross product of that member's row and column
directions, in this frozen expression order, with no fused multiply-add:

```text
nx = (ry * cz) - (rz * cy)
ny = (rz * cx) - (rx * cz)
nz = (rx * cy) - (ry * cx)
```

The normal is **not normalised**. Normalising would require a square root and a
zero-magnitude threshold, adding two numeric boundaries to argue about, and it
would change nothing: scaling a normal by a positive constant leaves the
ordering below identical.

Choosing the anchor by identity rather than by arrival makes the whole result a
pure function of the **set** of frames. Choosing it at all is a stated choice,
not a claim that the group is coherent — a group whose members disagree on
orientation is ordered against one member's axis and is expected to be
**rejected** by the geometry validator.

## The projection

For each member, the ordering key is the projection of its image position on the
reference normal, in this frozen expression order, with no fused multiply-add:

```text
t = ((px * nx) + (py * ny)) + (pz * nz)
```

The projection is absolute, not relative to a group origin. Differences between
projections — which is where slice spacing lives — belong to the geometry
validator, not here.

## The order

Members are sorted by ascending `t`. Ties — equal `t` under IEEE-754 numeric
comparison, which treats `+0` and `-0` as equal — are broken by exact
`SourceIdentity` byte order.

No epsilon is applied. Two frames whose projections differ by one bit are
ordered, not merged; two frames whose projections are equal tie, and whether
that means a duplicate is the geometry validator's judgement.

## Reported observations, never judgements

Three facts about a group are computed and reported. None is an error here.

| Observation | Condition |
|---|---|
| `degenerateReferenceNormal` | `nx`, `ny` and `nz` are each exactly zero |
| `nonFiniteReferenceNormal` | any of `nx`, `ny`, `nz` is not finite |
| `nonFiniteProjection` | any member's `t` is not finite |

A degenerate normal arises from parallel row and column directions, which
`ADR-0227` admits by design. A non-finite normal or projection arises from
overflow in the products above; the accepted spatial types guarantee finite
inputs but not finite products.

When any observation holds, **ordering by projection has no defined meaning**,
and the member order falls back to exact `SourceIdentity` byte order. The
projections are still reported, including infinities, because they are the
evidence for the observation. Rejecting or warning is
[`ADR-0226`](../architecture/decisions/ADR-0226-dicom-ingest-arc.md)
decision 7's assignment to the geometry validator.

## Numeric rules

- IEEE-754 binary64 throughout, in the frozen expression order above.
- No fused multiply-add, no reassociation, no vectorised reduction.
- No epsilon, no tolerance, no normalisation, no square root.
- No rounding: every value is either an exact product-sum or a comparison.

## Frozen fixtures

Computed by the independent oracle at
`docs/progress/evidence/ADR-0228-series-grouping-oracle.py`. Values are the
exact binary64 results a conforming implementation reproduces bit-for-bit.

### Grouping

| Fixture | Input | Groups |
|---|---|---|
| F11 | Two series identities, one frame of reference | 2 |
| F12 | One absent and one present frame of reference | 2 |
| F13 | Two coordinate spaces | 2 |
| F14 | One series, two disagreeing orientations | **1** |

F14 is the specification's point: the group is not split, so the validator can
reject it.

### Ordering and projection

| Fixture | Reference normal | Ordered members and `t` |
|---|---|---|
| F1 | `(0, 0, 1)` | `f1` = `0x0.0p+0`, `f2` = `0x1.4000000000000p+1`, `f3` = `0x1.4000000000000p+2` |
| F2 | `(0, 0, 1)` | identical to F1 from shuffled input |
| F3 | `(0, 0, -1)` | `f3` = `-0x1.4000000000000p+2`, `f2` = `-0x1.4000000000000p+1`, `f1` = `0x0.0p+0` |
| F4 | `(0x1.6a09e667f3bccp-1, -0x1.6a09e667f3bcdp-1, 0)` | `f2` = `-0x1.6a09e667f3bd0p-1`, `f1` = `-0x1.6a09e667f3bcep-1` |
| F5 | `(0, 0, 0x1.0p-1)` | `f2` = `0x1.0000000000000p-1`, `f1` = `0x1.0000000000000p+1` |
| F10 | `(0, 0, -0x1.cd2b297d889bcp-54)` | `f2` = `-0x1.cd2b297d889bcp-53`, `f1` = `-0x1.cd2b297d889bcp-54` |

F4 is retained because its ordering is **not** the ordering of the positions:
`f2` sits at `(4, 5, 6)` and `f1` at `(1, 2, 3)`, yet `f2` comes first, because
the reference normal has a negative `y` component. An implementation that sorted
by any positional coordinate would pass F1 and fail here.

F10 is retained because the cross product nearly cancels: the normal is
`-1e-16`, and the projections differ only in their exponent. Any epsilon large
enough to look reasonable would merge these two distinct slices.

### Observations

| Fixture | Input | Normal | Observations |
|---|---|---|---|
| F6 | Parallel directions `(1,0,0)`, `(2,0,0)` | exactly zero | `degenerateReferenceNormal` |
| F7 | `(1e200,0,0) x (0,1e200,0)` | `(0, 0, inf)` | `nonFiniteReferenceNormal`, `nonFiniteProjection` |
| F8 | `(1e100,0,0) x (0,1e100,0)`, position `z = 1e200` | `(0, 0, 0x1.4e718d7d7625ap+664)` | `nonFiniteProjection` only |

F8 separates the two non-finite observations: the normal is finite and the
projection overflows, so an implementation that reported one condition for both
would fail it.

### Ties

| Fixture | Input | Result |
|---|---|---|
| F9 | Two co-located frames `fb`, `fa` | `fa` then `fb`, both `t` = `0x1.8000000000000p+1` |

### A discharged case

F15 in the oracle applies a `-0.0` z coordinate. It is retained as a **discharged
concern rather than a live fixture**: `Point3D` canonicalises signed zero to
positive zero on construction, so a negative zero coordinate cannot reach this
algorithm through the accepted type. The oracle records that the arithmetic
would be safe regardless — `(0 + 0) + (-0)` is `+0` under IEEE-754 — so no rule
is needed for it.

## Conformance

An implementation conforms when, for every fixture above, it reproduces the
group count, the group order, the reference normal bit-for-bit, the member order,
each projection bit-for-bit, and the exact observation set.

## References

- [ADR-0226 - DICOM ingest arc](../architecture/decisions/ADR-0226-dicom-ingest-arc.md)
- [ADR-0227 - Neutral CT frame description](../architecture/decisions/ADR-0227-neutral-ct-frame-description.md)
- [ADR-0228 - CT series grouping](../architecture/decisions/ADR-0228-ct-series-grouping.md)

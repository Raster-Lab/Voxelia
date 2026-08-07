---
document_id: "ADR-0313"
title: "Arbitrary oblique reconstruction"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MPR-002"
---

# ADR-0313 - Arbitrary oblique reconstruction

## Context

`VOX-MPR-002` requires that "Voxelia shall support arbitrary oblique reconstruction". P0,
**`T,D`**, milestone M6 — which the traceability gate records as entered, so the row is due.

## The measurement

`ObliqueSliceOperation` reconstructs a plane from a volume through `AffineWorldToIndexMap` and
a trilinear reduction. Its admission constrains **structure**, not **orientation**:

- the volume must map all three axes, `{0, 1, 2}`;
- the request must present two, `[0, 1]`;
- the coordinate spaces must match;
- the output extents must be within `1...16,384`.

**Nothing constrains the direction cosines.** Any invertible affine is admitted, which is what
"arbitrary" asks for.

The evidence is already in place and was produced two increments ago by `ADR-0297`: a plane
whose in-plane step is `(1, 0.5, 0)` in patient space — not axis-aligned — reconstructed with
its expected value available **in closed form**, `10 + 2u - v`, asserted with `==` over the
whole plane and no tolerance. Every odd output column lands half way between two volume rows,
so it is a genuine trilinear blend rather than a lookup.

That test also falsifies the failure this row cares about: a pipeline ignoring the in-plane
`y` step would publish `10 + u - v`, differing at every column past the first.

## The constraint on "arbitrary" that is worth stating

`ADR-0297` found it and this row is where it belongs: **a planar request whose out-of-plane
column is zero is refused as singular.**

The sampling loop reads only slots `0` and `1`, so a caller assembling a request from two
direction cosines — the natural DICOM way — will leave slot `2` empty and get
`singularTransform`. The fix is to supply the plane normal, which moves not a single sample.

This does **not** limit which orientations are reconstructable: every orientation remains
available, and the third column is derivable from the two in-plane vectors by their cross
product. It is a calling convention, and an undocumented one until now.

## Decision

1. **`VOX-MPR-002`'s `T` is discharged** by `ADR-0297`'s oblique reconstruction and
   `ObliqueSliceOperationTests`, read for this row.
2. **"Arbitrary" is read as *any orientation*, not *any request shape*.** The structural
   admissions above are about rank and extents; none of them excludes an orientation.
3. **The out-of-plane column requirement is documented here rather than removed.** Defaulting
   it to the cross product inside the operation would be a convenience that silently accepts a
   request the caller did not fully specify, and this project's discipline is to refuse an
   under-specified input rather than complete it.
4. **Its `D` is not claimed**, consistent with `VOX-HLS-001`, `VOX-MTL-009` and `VOX-API-008`.

## Alternatives considered

### Default the out-of-plane column to the cross product

Rejected; see decision 3. It would make `AffineGridGeometry` mean something different
depending on how it was built, and the singular refusal is the geometry type's own invariant
rather than the operation's.

### Write a new oblique test for this row

Rejected. `ADR-0297`'s test reconstructs a non-axis-aligned plane against a closed form and
falsifies the axis-aligned reading; a second test would restate it with a different rotation
and add no discrimination.

### Read "arbitrary" as including non-planar or curved reconstruction

Rejected as over-reading. The row sits among the multiplanar requirements, and curved
reconstruction is a distinct capability that would need its own row, algorithm and record.

## Consequences

`VOX-MPR-002`'s test obligation is discharged, and the one calling convention that constrains
how an arbitrary orientation is *expressed* is written down where a reader of this row will
find it.

**5 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. This record adds no code and no test.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "ObliqueSlice"
swift test --filter "PhantomPipelineTests"
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining 5 rows.
3. **Owner**: **one new item** — `VOX-MPR-002`'s Demonstration.

## Supersession

This record supersedes nothing. It **claims** a row on evidence `ADR-0297` produced, and
records the calling convention that evidence exposed.

## References

- [ADR-0142 - Oblique slice operation](ADR-0142-oblique-slice-operation.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0297 - Phantoms through the shipped pipelines](ADR-0297-phantoms-through-the-shipped-pipelines.md)
- [ADR-0312 - Canonical two dimensional pipeline](ADR-0312-canonical-two-dimensional-pipeline.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

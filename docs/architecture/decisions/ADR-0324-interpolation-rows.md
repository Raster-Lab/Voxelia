---
document_id: "ADR-0324"
title: "Interpolation rows"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-IMG-003"
  - "VOX-IMG-004"
---

# ADR-0324 - Interpolation rows

## Context

`ADR-0319`'s rederived queue lists three M2 rows about interpolation. This claims the two that
name an interpolation kind. The third, `VOX-IMG-008`, is left with its reason stated.

## The measurement

**`VOX-IMG-003`** — "Voxelia shall provide nearest-neighbour interpolation".
`ResampleNearestOperation` is a registered operation, `org.voxelia.op.resample-nearest`,
implementing `VOXELIA-ALG-0008`'s whole-sample selection, with three tests.

**`VOX-IMG-004`** — "Voxelia shall provide linear interpolation for supported scalar types".
`ResampleLinearOperation` is registered as `org.voxelia.op.resample-linear`, implementing
`VOXELIA-ALG-0015`'s `bilinear-resampling/binary64-v1` model, with three tests.

Both are stronger than the rows require: each names a **frozen algorithm specification** rather
than an implementation choice, so what "nearest" and "linear" mean here is a registered model
with conformance fixtures rather than whatever the code happens to do.

## Decision

1. **`VOX-IMG-003` and `VOX-IMG-004` are claimed and their `T` discharged.**
2. **`VOX-IMG-008` is not claimed**, and the reason is recorded rather than the omission. That
   row asks for "resampling between explicit source and target grids". Both operations resample
   between explicit **extents**, and whether a *grid* — extents together with a geometry — is
   what they accept was not established. The two are not the same: resampling between extents
   is a pixel operation, and resampling between grids is a spatial one. Claiming the row on the
   operations' existence would assert the second from evidence for the first.
3. **No new test.** Six tests across two registered operations with frozen models is what the
   rows ask for, and a seventh asserting that nearest-neighbour is available would restate the
   registry.

## Alternatives considered

### Claim all three together

Rejected; see decision 2. It is the third time in this queue that adjacent evidence would have
carried a row it does not address — `VOX-SPA-010` and `VOX-MTL-013` were the others — and the
pattern is consistent enough now to treat as a standing hazard rather than a coincidence.

### Read `VOX-IMG-008` as satisfied by `ObliqueSliceOperation`

Rejected as speculation. That operation resamples onto a plane from a volume through an affine,
which is closer to what the row describes than the resample operations are, and "closer" is not
a reading — it is a hypothesis for the increment that takes the row.

## Consequences

Two M2 rows are claimed on frozen models, and the third's ambiguity is named.

**7 rows remain unclaimed** under `ADR-0319`'s criterion, recomputed rather than decremented.

## Affected modules

None. This record adds no code.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "Resample"
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: `VOX-IMG-008`, beginning with whether the resample operations accept a grid or only
   extents.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **claims** two rows delivered without a record naming them.

## References

- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0322 - Canonical shape rows](ADR-0322-canonical-shape-rows.md)
- [ADR-0323 - Spatial bounds half built](ADR-0323-spatial-bounds-half-built.md)
- [VOXELIA-ALG-0008 - Nearest neighbour resampling](../../algorithms/VOXELIA-ALG-0008-nearest-neighbour-resampling.md)
- [VOXELIA-ALG-0015 - Bilinear resampling](../../algorithms/VOXELIA-ALG-0015-bilinear-resampling.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

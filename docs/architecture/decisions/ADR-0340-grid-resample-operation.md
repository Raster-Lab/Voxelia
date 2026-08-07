---
document_id: "ADR-0340"
title: "Grid resample operation"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-IMG-008"
---

# ADR-0340 - Grid resample operation

## Context

`VOX-IMG-008` — image resampling between explicit source and target grids, P0, `T`,
M2 — was measured unbuilt by `ADR-0325`: the extents-based operations take two
integers and cannot express a target grid, and the one grid-taking operation is a
rank reduction claimed by another row. That record named the boundary the builder
starts from: a target `AffineGridGeometry`, a frozen sample-mapping rule, and the
out-of-source question. `ADR-0338` decision 7 supplied the answer — zero padding,
recorded in provenance. `VOXELIA-ALG-0055` freezes the arithmetic; this record
designs the operation.

## Decision

1. **`GridResampleOperation` in `VoxeliaExecution`**, the registered-operation
   pattern verbatim: token `org.voxelia.op.grid-resample`, CPU implementation
   `org.voxelia.impl.grid-resample.cpu`, version `1.0.0`, budgeted coordinated
   full read, minted-nothing discipline, parameter document carrying the complete
   reproduction recipe (all sixteen target matrix elements, the coordinate space,
   three output extents).

2. **The request is the output's own rank-three `AffineGridGeometry`** and the
   output claims it verbatim as its spatial geometry, exactly as the oblique slice
   claims its plane — one calibration authority, no derived rescale.

3. **The sample chain composes accepted authorities only**: the target forward
   evaluation in the `VOXELIA-ALG-0017` request order extended by the third slot
   term (frozen in `VOXELIA-ALG-0055`, chosen so a depth-one grid equals an
   oblique slice byte-for-byte), the `ADR-0138` world-to-index composition, the
   slot-to-axis reorder, and `ObliqueSliceOperation.sample` — the one public
   sampling authority per `ADR-0174` — with its built-in exact zero padding.

4. **The support predicate is extracted, not restated.** The support test moves
   from the body of `sample` into a public
   `ObliqueSliceOperation.supports(_:extents:)` that `sample` itself now calls,
   so the resample can count padded samples against the same expressions that
   decide padding. The oblique fixtures prove the extraction changed nothing.

5. **Padding is recorded in provenance as an aggregated warning**:
   `org.voxelia.warn.grid-resample-padding`, schema `1.0`, severity
   `qualityAffecting` — padded samples are synthetic, not measured — with the
   padded-sample count as occurrence count, present only when the count is at
   least one (the padding-entry precedent, and `ProvenanceWarning`'s own
   admission). The padding **value** is frozen in the model, not a parameter: a
   constant parameter would add a digest entry that cannot vary.

6. **Two explicit ceilings**: the sibling per-dimension ceiling `16384`, and a
   total-sample ceiling of `1073741824` — exactly `1024^3` — because three
   dimensions at the per-dimension ceiling would admit a four-terabyte output.
   Distinct typed rejections (`invalidOutputExtent`, `outputBudgetExceeded`)
   keep the two failures attributable.

7. **The value domain is the sampler's**: rank-three `uint8` scalar intensity,
   affine-calibrated, no value transform — the domain `ADR-0142` froze for the
   authority this operation composes. Widening the domain is the sampler's
   decision to make, not this record's.

8. **`VOX-IMG-008` is discharged by this increment**: the row's capability —
   a caller-specified explicit target grid — now has a surface, verified by
   oracle fixtures, a cross-contract equivalence, and typed admission evidence.

## Alternatives considered

### Translation-last forward evaluation

Rejected. `VOXELIA-ALG-0052` and `VOXELIA-ALG-0054` compose translation last, and
matching them was the obvious default — but this operation's nearest accepted
relative is the sampler's own request evaluation, and matching *it* buys a
byte-for-byte cross-check against `ObliqueSliceOperation` that a merely-equivalent
order would reduce to an argument. Consistency within the consumer family beats
consistency across families.

### An interpolation parameter

Rejected for version one. The row asks for resampling between grids, not for a
choice of kernels; the accepted three-dimensional rule is `VOXELIA-ALG-0017`'s
trilinear reduction, and nearest-neighbour selection over a grid would need its
own design against `VOXELIA-ALG-0026` (whose interpolation-footprint hazard
`ADR-0182` recorded). A second kernel is an additive future record.

### Count padded samples inside the sampling authority

Rejected. Returning a flag from `sample` would change a frozen public signature
consumed elsewhere; the extracted predicate keeps one set of support expressions
and leaves the authority's shape untouched.

### Record padding as a parameter-document entry

Rejected. The parameter document is the reproduction recipe — inputs, not
outcomes. The padded count is an observable of one execution over one volume, and
the provenance warning vocabulary exists precisely for aggregated execution
observations.

## Consequences

`VOX-IMG-008` is discharged; every M2 row is accounted for. The operation registry
grows to seventeen implementations. Future consumers (isotropic reformats, cache
grids for `VOX-PER-006`) compose the operation without new numeric decisions.

## Affected modules

`VoxeliaExecution` gains the operation and one public predicate on the sampling
authority; `VoxeliaCPU` registers the implementation.

## Compatibility impact

Additive. `ObliqueSliceOperation.sample`'s behaviour and signature are unchanged;
its support test is now also callable.

## Security impact

None. The ceilings bound the output allocation before any read.

## Performance and memory impact

One full-volume coordinated read and one output allocation, like the sibling
operations. The support predicate is evaluated twice per padded-region sample for
counting; the CPU reference path takes legibility over the redundant comparison.

## Validation impact

```text
python3 docs/progress/evidence/ADR-0340-grid-resample-oracle.py
swift test --filter "GridResampleOperationTests|ObliqueSliceOperationTests"
swift test
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

The oblique suite re-runs against the extraction; the full suite must show the
literal pass line before push.

## Migration

1. This record with `VOXELIA-ALG-0055` and the oracle.
2. The predicate extraction, the operation, the registration, and the fixture,
   cross-contract and admission tests, in the same increment.
3. **Next**: the remaining unblocked rows per `ADR-0338`'s migration order.

## Supersession

This record supersedes nothing. It builds what `ADR-0325` measured absent, under
the padding answer `ADR-0338` decision 7 supplied.

## References

- [VOXELIA-ALG-0055 - Grid resampling](../../algorithms/VOXELIA-ALG-0055-grid-resampling.md)
- [VOXELIA-ALG-0017 - Oblique slice sampling](../../algorithms/VOXELIA-ALG-0017-oblique-slice-sampling.md)
- [ADR-0142 - Oblique slice operation](ADR-0142-oblique-slice-operation.md)
- [ADR-0174 - Volume render vocabulary](ADR-0174-volume-render-vocabulary.md)
- [ADR-0325 - Grid resampling is unbuilt](ADR-0325-grid-resampling-is-unbuilt.md)
- [ADR-0338 - The owner decision batch](ADR-0338-the-owner-decision-batch.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

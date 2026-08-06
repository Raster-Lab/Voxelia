---
document_id: "ADR-0285"
title: "Shading normal space design"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SUR-004"
---

# ADR-0285 - Shading normal space design

## Context

`ADR-0280` found that `SurfaceVertexProjector` transforms vertex **positions** through
`SurfaceLayer.objectToWorld` while `SurfaceShader` reads vertex **normals** straight from
the mesh — object space — and dots them against the camera's **world-space** forward. It
quantified the composed error at `1.000000` where `0.000000` is correct, under a pure
rotation: the maximum possible for a value bounded in `[0, 1]`.

`ADR-0284` supplied `AffineTransformAlgebra.transformNormal`, so the correction is now
unblocked. This is its design increment.

## What is and is not wrong

**`VOXELIA-ALG-0036`'s arithmetic is correct and is not being changed.** Its input domain
names "three unit vertex normals" and "the camera's forward unit axis" and **gives neither
a space**. The model is right for same-space inputs; the composition supplied inputs from
two different spaces. The defect is in what reaches the shader, not in what the shader
does with it.

So the correction transforms the normals before they arrive. `ADR-0202` and `ALG-0036` are
untouched.

## The numeric boundary this uncovered

A transformed normal is no longer unit. `ALG-0036` states its inputs are unit "by
construction" and does not re-admit them, so something has to restore that.

**Where the normalisation happens changes the answer materially.** Interpolating the raw
transformed normals and letting `ALG-0036`'s renormalisation clean up afterwards is not the
same as normalising each transformed normal first. Measured under `objectToWorld =
diag(1, 1, 5)` — a thin-slice CT shape — over three distinct unit object-space normals with
weights `(0.25, 0.35, 0.40)`:

| | direction |
|---|---|
| interpolate raw, then renormalise | `(0.7153996067895155, 0.5109997191353682, 0.47653193979940256)` |
| normalise each, then interpolate | `(0.513983226502988, 0.36713087607356293, 0.7752652208805941)` |

**22.37 degrees apart**, and the shading intensities they produce against a world-space
forward differ by **`0.29873328108119157`** — nearly thirty per cent of the full `[0, 1]`
range.

No accepted specification covers this. `VOXELIA-ALG-0052` decision 7 deliberately does not
normalise, leaving it to the consumer; `ALG-0036` renormalises the *interpolated* direction
and assumes unit inputs. The gap is exactly between them, and this record closes it.

## Decision

1. **Each transformed normal is normalised before interpolation.** That is what keeps
   `ALG-0036` inside its own stated input domain, which says unit normals and says the
   model does not re-admit them. Feeding it non-unit vectors would leave the arithmetic
   working while violating a stated precondition — the kind of quiet domain breach this
   project treats as a defect even when the numbers survive.
2. **The normalisation rule is `VOXELIA-ALG-0030`'s**, composed rather than restated:
   scale by `max(|x|, |y|, |z|)`, divide, take the length of the scaled triple, divide
   again. It is already accepted, already registered, and already the shape `ALG-0036`'s
   own renormalisation uses.
3. **A transformed normal whose scale is exactly zero is passed through as the zero
   direction, not failed.** `ALG-0030` fails the whole operation for an undefined *published*
   vertex normal, and `ADR-0202` deliberately chose the opposite for presentation —
   "shading is presentation, not measurement, so this yields positive zero rather than
   failing an entire render". This is presentation, so it composes `ADR-0202`'s position.
   `ALG-0036` already returns intensity zero for an interpolated zero direction, so the
   case is handled downstream rather than needing a new branch.
4. **The correction is a new operation, not a changed one.** `SurfaceShader.normals(of:facetOrdinal:)`
   keeps its behaviour and its `normalsMissing` rejection; a sibling that also takes
   `objectToWorld` returns world-space normals. Nothing that exists today changes its
   output.
5. **No new failure case.** The family is `normalsMissing`, inherited from the existing
   reader, and `singularMatrix`, inherited from `VOXELIA-ALG-0016` through
   `transformNormal`. Both already exist and both are already tested.
6. **`ADR-0202` and `VOXELIA-ALG-0036` are not edited.** The correction is recorded here, in
   the implementing commit and in the ledger, per the standing discipline that a flaw found
   in an accepted record is fixed in a successor rather than by rewriting the record.
7. **No new algorithm specification.** Every step is an accepted rule — `ALG-0052`'s
   transformation, `ALG-0030`'s normalisation, `ALG-0036`'s shading — and this record
   freezes only the **order** in which they compose. The order is the whole content of the
   decision, which is why the measurement above is registered with it.

## What the implementing increment must show

- The registered 22.37-degree divergence reproduced, so the ordering decision is evidenced
  rather than asserted.
- `ADR-0280`'s finding as a test: under a pure rotation, object-space normals give
  `1.000000` and world-space normals give `0.000000` against the same forward.
- That `ALG-0036`'s own conformance fixtures still pass **unchanged**, since its arithmetic
  is untouched.
- That the identity `objectToWorld` leaves the shading bit-identical to the existing path,
  which is what makes "nothing that exists today changes" checkable rather than claimed.

## Alternatives considered

### Interpolate the raw transformed normals and let `ALG-0036` renormalise

Rejected, and it is the cheaper implementation. It violates `ALG-0036`'s stated input
domain and, per the measurement, shifts the shading by up to `0.299` of the full range.
"The arithmetic still runs" is not the same as "the model was used as specified".

### Normalise inside `AffineTransformAlgebra.transformNormal`

Rejected. `ADR-0283` decision 7 settled that deliberately: normalising there would break the
correspondence between transforming twice and transforming by the composition, and would
impose a presentation rule on a spatial primitive. The consumer that needs unit vectors is
this one, so this is where it belongs.

### Transform the camera's forward into object space instead

Rejected, and it is worth naming because it is cheaper still — one direction transformed
per facet instead of three. It fails for the same reason it looks attractive: each layer has
its own `objectToWorld`, so the forward would become per-layer, and any later operation
mixing layers or comparing against world-space geometry would be comparing directions from
different spaces again. It moves the defect rather than removing it.

### Change `SurfaceShader.normals(of:facetOrdinal:)` to require a transform

Rejected as a change to existing behaviour where an addition suffices. It would also force
every caller to have a matrix even where object space is what they want.

### Fix it inside `ALG-0036` by taking a matrix

Rejected outright. It is an accepted frozen specification, its arithmetic is correct, and
the defect is in its caller.

## Consequences

The correction has a frozen order and a measured justification for it, and the measurement
is the kind that would otherwise be discovered as a shading discrepancy nobody could
attribute.

`ALG-0036`'s stated input domain is restored rather than quietly widened.

Nothing is discharged by this record. `VOX-SUR-004`'s test half was discharged by
`ADR-0202`'s increment and stays discharged; this corrects a composition defect that row's
tests could not see, because `SurfaceShader` has no production caller and no test composed
it with a non-identity `objectToWorld`.

## Affected modules

None yet. The implementing increment will touch `VoxeliaRendering`.

## Compatibility impact

None yet. Decision 4 keeps the existing reader and its behaviour.

## Security impact

None.

## Performance and memory impact

Three normal transformations and three normalisations per facet, each composing operations
that already exist. `ALG-0016`'s inverse is computed once per layer rather than per facet if
the implementation hoists it, which the implementing increment should do and record.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_adr_register.py
python3 Tools/Scripts/check_release_integrity.py --write
```

1145 tests in 206 suites pass, unchanged — this record adds no code. The divergence
measurement is a recorded independent Python computation.

## Migration

1. This record.
2. **Next**: the implementation in `VoxeliaRendering`, showing the four things listed above.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **corrects a composition defect** `ADR-0280` found
between `VOXELIA-ALG-0033` and `VOXELIA-ALG-0036`, without editing either.

## References

- [ADR-0202 - Surface shading design](ADR-0202-surface-shading-design.md)
- [ADR-0280 - Open the affine transform arc](ADR-0280-open-the-affine-transform-arc.md)
- [ADR-0283 - Affine composition and direction design](ADR-0283-affine-composition-and-direction-design.md)
- [ADR-0284 - Affine algebra implementation](ADR-0284-affine-algebra-implementation.md)
- [VOXELIA-ALG-0030 - Triangle area weighted vertex normals](../../algorithms/VOXELIA-ALG-0030-triangle-area-weighted-vertex-normals.md)
- [VOXELIA-ALG-0036 - Surface diagnostic shading](../../algorithms/VOXELIA-ALG-0036-surface-diagnostic-shading.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](../../algorithms/VOXELIA-ALG-0052-affine-composition-and-directions.md)

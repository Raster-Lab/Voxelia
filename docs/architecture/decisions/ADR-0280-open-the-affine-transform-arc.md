---
document_id: "ADR-0280"
title: "Open the affine transform arc"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-008"
  - "VOX-SPA-009"
  - "VOX-SUR-004"
---

# ADR-0280 - Open the affine transform arc

## Context

`ADR-0279` closed the draw-loop arc's unblocked tier and committed to re-deriving the next
action rather than assuming it. That derivation queried every baseline row for those with
no decision record, no test and no source mention, and surfaced one that does not belong
where it was found:

**`VOX-SPA-008` is P0, declares `T`, and sits in milestone M1** — the oldest entered
milestone. "Affine transforms shall support composition, inversion and point, vector and
normal transformation."

## Assessment: three of five capabilities are absent

Searched by capability rather than by the requirement's vocabulary, following `ADR-0248`'s
lesson that a name-based search stops at the first plausible symbol.

| Capability | State |
|---|---|
| **Inversion** | **Exists and is frozen.** `AffineSpatialInverse`, specified by `VOXELIA-ALG-0016` and accepted by `ADR-0136`, inverts the upper-left three-by-three block through the adjugate with a frozen expression order and no fused multiply-add. |
| **Point transformation** | **Exists, per consumer.** `AffineWorldToIndexMap` (`ADR-0138`) subtracts the translation and applies the inverse with its own frozen accumulation order. |
| **Composition** | **Absent** — and deliberately so. `ALG-0016` states that "composition with a world offset is the consuming operation's own frozen step per the specification". |
| **Vector transformation** | **Absent.** No symbol distinguishes a direction from a point. |
| **Normal transformation** | **Absent.** Nothing in `Sources` names `transformNormal` or `inverseTranspose`. |

`Matrix4x4Double`'s entire public surface is `elements`, two initialisers and `Codable`
conformance. It is a validated container, not an algebra.

**`VOX-SPA-009`** — "singular or non-invertible transforms shall produce typed errors",
also P0 and M1 — is **implemented and untraced**. `AffineSpatialInverseError.singularMatrix`
is thrown on a determinant below `Double.leastNormalMagnitude`, which is the accepted
no-epsilon admission. It needs a test carrying its row, not new code.

## The finding: two accepted contracts assume different spaces, and neither says so

`SurfaceLayer` carries `objectToWorld: Matrix4x4Double` and validates **only** that the
bottom row is `[0, 0, 0, 1]`. Any rotation, scale or shear in the upper three-by-three is
admitted.

- `SurfaceVertexProjector` (`ALG-0033`) transforms vertex **positions** through
  `objectToWorld` into world space, then into the camera basis.
- `SurfaceShader` (`ALG-0036`) reads the three vertex **normals** directly from
  `mesh.vertexAttributes` — object space, since `objectToWorld` is what maps the mesh out
  of it — and dots the interpolated result against the camera's `forward`, which is built
  from `camera.target - camera.position` and is therefore **world space**.

Nothing transforms the normal between those two points.

**Neither record states which space the shading normal inhabits.** `ADR-0202`'s only
mentions of "space" concern colour. So this is an unstated assumption on which two
contracts differ, rather than a decision that was made and made wrongly — a distinction
worth keeping, because it changes who was mistaken and what needs correcting.

### Quantified rather than described

Computed independently, with explicit arithmetic:

| Configuration | As composed | Correct | Error |
|---|---:|---:|---:|
| `objectToWorld` = rotation 90° about X | `1.000000` | `0.000000` | **`1.000000`** |
| `objectToWorld` = scale `(1, 1, 5)`, normal `(0,0,1)` | `1.000000` | `1.000000` | `0.000000` |

The first is the **maximum possible error** for a quantity bounded in `[0, 1]`: a facet
squarely facing the camera would shade as fully unlit. The second is included because it
does **not** diverge — a normal aligned with a principal axis survives an axis-aligned
scale, since renormalisation absorbs it. The defect is real but not universal, and
reporting only the first figure would overstate it.

And the case that shows why the inverse-transpose is required rather than the matrix
itself — normal `(0, 1, 1)` under scale `(1, 1, 5)`:

- transformed as a **vector**: `(0, 0.196116, 0.980581)`
- transformed as a **normal**: `(0, 0.980581, 0.196116)`
- **67.38 degrees apart**

Thin-slice CT is strongly anisotropic, so this is the shape of transform the project will
actually meet, not a contrived one.

### It is latent, not shipping

**`SurfaceShader` has no production caller.** Every reference outside its own file is in
`SurfaceShaderTests`. No image Voxelia can currently produce is wrong.

Recorded precisely, because the temptation is to call this a bug in shipped code and it is
not. It is the third of the three separate questions this project keeps distinguishing:
the capability exists, the wiring does not, and the composition has never been verified.

## Decision

1. **The affine transform arc opens**, with `VOX-SPA-008` as its subject and
   `VOX-SPA-009` discharged early as a tagged test over existing behaviour.
2. **Composition, vector transformation and normal transformation are numeric boundaries**
   and each gets design-first treatment: an ADR, a `VOXELIA-ALG` specification with a
   frozen expression order, and an independent Python oracle with registered fixtures,
   before any implementation. This is the pattern every geometry increment used.
3. **`ALG-0016`'s per-consumer position is respected, not overturned.** That specification
   deliberately left composition to consumers, and `ADR-0138` shows why: the consuming
   operation freezes its own accumulation order. A general composition operation must
   therefore justify itself as *additional* vocabulary rather than as a replacement, and
   must not silently change any existing consumer's bits.
4. **The surface-shading space mismatch is in scope for this arc but is not fixed by this
   record.** Fixing it needs the normal transformation this arc will build, so the order
   is: build the capability, then wire it, then verify the composition against an oracle.
5. **No accepted record is edited.** `ADR-0202` and `ALG-0036` stand; the correction, when
   it lands, is recorded in a successor record and in the implementing commit, as
   `ADR-0194` decision 13 and `ADR-0195` decision 17 established.
6. **`VOX-SUR-004` is named here** because the shading row is where the mismatch will be
   corrected, and a later reader tracing that row should find this assessment.

## Alternatives considered

### Treat `VOX-SPA-008` as satisfied by the per-consumer frozen steps

Rejected. Inversion and point transformation exist, but composition, vector and normal
transformation are three of the five capabilities the row names, and two of them have no
implementation anywhere. A row is not satisfied by the subset of it that was convenient.

### Fix the shading space now, without building the transform vocabulary

Rejected. The fix *is* a normal transformation, so doing it inline would put an
inverse-transpose in a renderer with no specification, no oracle and no registered
fixtures — exactly what the project's design-first rule exists to prevent. It would also
create the second implementation of an operation this arc is about to specify.

### Report the shading mismatch as a defect in shipped code

Rejected as inaccurate. `SurfaceShader` has no production caller, so nothing renders
wrongly today. Overstating it would also misdirect the fix toward urgency rather than
toward the missing capability.

### Add a general composition operation that existing consumers adopt

Deferred to the arc's own design, and flagged now because it is the tempting move.
`ADR-0138`'s world-to-index step is a *frozen* accumulation order with registered
fixtures; rewriting it to call a general composition would change bits unless the general
operation happened to freeze the identical order. Any such adoption must re-run the
existing oracles and show the digests unchanged, as `ADR-0202`'s swap flag and
`ADR-0204`'s world position both did.

## Consequences

An arc opens on a P0 row in the oldest entered milestone, with three of five named
capabilities absent.

A latent composition defect is on the record with exact figures rather than a warning, and
with its limits stated: maximum error under rotation, no error for an axis-aligned normal
under an axis-aligned scale, and 67.38 degrees between the vector and normal treatments of
one realistic case.

`VOX-SPA-009` is identified as implemented-but-untraced and needs a test rather than code.

Nothing is discharged by this record.

## Affected modules

None yet. The arc will touch `VoxeliaSpatial`, and its correction step will touch
`VoxeliaRendering`.

## Compatibility impact

None yet. Decision 3 constrains the arc not to change any existing consumer's bits without
re-running that consumer's oracle.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1129 tests in 204 suites pass, unchanged — this record adds no code. The quantification is
an independent Python computation over explicit arithmetic, reproducible by inspection.

## Migration

1. This record.
2. **Next**: `VOX-SPA-009`'s test over the existing typed singular error — the cheapest
   real discharge available and a check that the arc's assessment is accurate before
   larger work depends on it.
3. Then the design increment: an ADR and a `VOXELIA-ALG` specification with an independent
   oracle for composition, vector transformation and normal transformation.
4. Then the surface-shading correction, verified against that oracle.
5. **Owner**: unchanged — the application-location decision from `ADR-0275`, reference
   hardware, §28.4's padding-aware interpolation rule, `VOX-CMP-006`'s and
   `VOX-CMP-012`'s Reviews, the five `J2KSwift` items, and the four other open decisions.

## Supersession

This record supersedes nothing. It **assesses** `VOX-SPA-008` and records an unstated
assumption shared by `ALG-0033` and `ALG-0036`. No accepted record is edited.

## References

- [ADR-0136 - Affine inverse design](ADR-0136-affine-inverse-design.md)
- [ADR-0138 - World to index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0197 - Surface rendering arc](ADR-0197-surface-rendering-arc.md)
- [ADR-0202 - Surface shading design](ADR-0202-surface-shading-design.md)
- [ADR-0279 - Interactive responsiveness](ADR-0279-interactive-responsiveness.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

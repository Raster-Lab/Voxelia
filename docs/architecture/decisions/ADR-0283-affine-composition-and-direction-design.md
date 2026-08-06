---
document_id: "ADR-0283"
title: "Affine composition and direction design"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SPA-008"
---

# ADR-0283 - Affine composition and direction design

## Context

`ADR-0280` opened the affine transform arc, finding three of `VOX-SPA-008`'s five named
capabilities absent: composition, vector transformation and normal transformation.
`ADR-0281` discharged the sibling row `VOX-SPA-009` and confirmed the assessment.

This is the design increment. It accepts `VOXELIA-ALG-0052`,
`affine-composition/binary64-v1`, and freezes every numeric boundary before any Swift is
written.

## Decision

1. **Composition means "A after B".** `compose(A, B)` produces `C` with `C × p` equal to
   `A × (B × p)`. Voxelia multiplies column vectors, so this is the matrix product `A·B`
   and the reading follows from the convention rather than being chosen independently of
   it.
2. **The affine structure is used rather than multiplied through.** Only the upper
   three-by-four is computed, and the bottom row is set to the literal `0, 0, 0, 1`.
   Multiplying admitted values by known zeros contributes signed zeros to sums that are
   otherwise exact, and both operands are affine by admission, so the literal is correct by
   construction.
3. **The translation term is added last.** `Ct[r]` accumulates three products and then adds
   `At[r]`. Stated because the alternative grouping is equally natural and would produce
   different bits.
4. **Vector transformation reuses `ADR-0138`'s expression order.** A row traversal,
   ascending, left-associative — deliberately identical to the accepted world-to-index
   step so the two agree where they overlap rather than merely resembling each other.
5. **Normal transformation is a column traversal of `VOXELIA-ALG-0016`'s inverse**, which
   is what expresses the transpose. The specification says explicitly that it must not be
   rewritten as a row traversal, because that would silently compute `Inv × n` and
   reintroduce the exact error the operation exists to prevent.
6. **The inverse is composed, not reimplemented.** `VOXELIA-ALG-0016` is accepted, frozen
   and already carries its own error bounds; a second inverse would be a second thing to
   keep correct.
7. **The result of a normal transformation is deliberately not normalised.** Normalisation
   is a separate accepted rule — `ALG-0030` publishes unit normals and `ALG-0036`
   renormalises before use — and applying it here would duplicate that rule and make a
   chain of transformations differ from the composition of its matrices. A result that
   underflows to zero is therefore a value, not a failure, and no failure case is carried
   for it.
8. **Two failure cases only**: `nonAffineOperand`, and `singularMatrix` composed from
   `ALG-0016` on the normal path. **No representability failure**, because
   `Matrix4x4Double` admits only finite elements and neither `ALG-0016` nor `ADR-0138`
   carries one. Adding a branch the accepted siblings lack would be a claim about
   arithmetic they do not make.
9. **Non-associativity is registered rather than left to be discovered.** A consumer would
   reasonably assume `(X∘Y)∘Z` equals `X∘(Y∘Z)`, and in binary64 it does not. Fixture 5
   is the witness.
10. **`VOXELIA-ALG-0033`'s prohibition on folding object-to-world with world-to-view stays
    in force.** Supplying composition is not authorising a fold that an accepted record
    keeps separate, and the specification says so, because a new general operation is
    exactly what would tempt someone to "optimise" that chain.
11. **No existing consumer is changed.** `ADR-0280` decision 3 constrained this arc not to
    alter any accepted frozen step, and nothing here replaces one: `ALG-0016` and
    `ADR-0138` are composed and cited, not rewritten.

## The distinction that motivated the arc, stated precisely

`ADR-0280` measured a composed shading path giving `1.000000` where `0.000000` was
correct, under a pure rotation. Fixture 4 here shows the vector and normal rules agreeing
**exactly** under a pure rotation.

Both are true and they answer different questions:

- **Whether to transform a direction at all** is decided by which space its consumer works
  in. Not transforming is wrong for any non-identity transform, rotation included — that is
  `ADR-0280`'s finding.
- **Which of the two rules to use** is decided by whether the direction is a vector or a
  normal. That only matters when the transform is not orthonormal — fixture 3 shows
  `(0, 1, 5)` against `(0, 1, 0.2)` under `diag(1, 1, 5)`.

Recorded together because reading either finding alone invites the wrong correction.

## The oracle

Written independently in Python, in the frozen expression order, with no fused
multiply-add and with `ALG-0016`'s adjugate reproduced rather than imported. All five
fixtures came out exactly representable, so each is registered as an exact value and none
needs a tolerance.

Fixture 1 checks the composition **against staged application** — `C × p` against
`A × (B × p)` — rather than against a hand-computed matrix, so it tests the property the
operation exists for rather than a transcription.

## Alternatives considered

### Define composition as "A then B"

Rejected. Voxelia multiplies column vectors, so `A·B` applied to `p` is `A × (B × p)` and
"A after B" is what the convention already means. Naming it the other way would put the
documentation at odds with the arithmetic.

### Compute the full four-by-four product

Rejected; see decision 2. It multiplies by known zeros and ones, and the extra terms can
change a signed zero without changing any value that matters.

### Normalise the transformed normal

Rejected; see decision 7. It duplicates an accepted rule and breaks the correspondence
between transforming twice and transforming by the composition.

### Add a representability failure for overflow

Rejected; see decision 8. Neither accepted sibling has one, inputs are admitted finite, and
an unreachable-in-practice branch is one this project has repeatedly declined to carry.

### Specify a general four-by-four algebra on `Matrix4x4Double`

Rejected as scope. `VOX-SPA-008` asks for affine transforms, the admission is affine, and a
general algebra would need its own decisions about projective divides that nothing
requires.

### Fold the surface-shading correction into this record

Rejected. This increment freezes the numbers; the correction consumes them. Keeping them
separate is what lets the correction cite a specification that already existed rather than
one written to justify it.

## Consequences

`VOXELIA-ALG-0052` is accepted with five exactly-representable fixtures and no tolerance
anywhere.

`VOX-SPA-008` is **not** discharged by this record — the implementation is the next
increment, and the row declares `T`.

A hazard a consumer would not expect, non-associativity, is on the record with a witness.

## Affected modules

None yet. The implementing increment will add to `VoxeliaSpatial`.

## Compatibility impact

None. Nothing existing changes.

## Security impact

None.

## Performance and memory impact

None yet. The specified operations are nine and three multiply-accumulate chains
respectively, plus `ALG-0016`'s existing inverse on the normal path.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_adr_register.py
python3 Tools/Scripts/check_release_integrity.py --write
```

1134 tests in 205 suites pass, unchanged — this record adds no code. The fixtures are a
recorded independent Python computation.

## Migration

1. This record and `VOXELIA-ALG-0052`.
2. **Next**: the implementation in `VoxeliaSpatial`, reproducing all five fixtures exactly
   and confirming no existing consumer's digests change.
3. Then the surface-shading correction `ADR-0280` quantified, consuming the normal
   transformation specified here.
4. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **extends** `VOXELIA-ALG-0016` with the operations
`ADR-0280` found absent, composing that specification rather than altering it.

## References

- [ADR-0138 - World to index mapping](ADR-0138-world-to-index-mapping.md)
- [ADR-0280 - Open the affine transform arc](ADR-0280-open-the-affine-transform-arc.md)
- [ADR-0281 - Singular transform typed errors](ADR-0281-singular-transform-typed-errors.md)
- [VOXELIA-ALG-0016 - Affine spatial inverse](../../algorithms/VOXELIA-ALG-0016-affine-inverse.md)
- [VOXELIA-ALG-0052 - Affine composition and directions](../../algorithms/VOXELIA-ALG-0052-affine-composition-and-directions.md)

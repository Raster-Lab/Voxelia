---
document_id: "ADR-0251"
title: "Off-screen equivalence reading"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-014"
  - "VOX-VS1-016"
---

# ADR-0251 - Off-screen equivalence reading

## Context

`VOX-VS1-016` requires the first vertical slice to "provide off-screen output
using the same presentation semantics as the interactive viewport", declaring `T`
alone. Three records have now deferred it as needing "a reading, not code"
(`ADR-0245`, `ADR-0247`, `ADR-0248`), on the observation that no `offScreen`
symbol exists anywhere in `Sources`. This record supplies the reading and the
tests it implies.

## The problem the reading has to solve

The plan is specific about what equivalence means. §35.1 lists nine semantics
off-screen output must share with interactive output, and §35.3 requires the two
render targets to be "byte-identical or differ only by an explicitly validated
final display conversion".

**Both halves of that comparison need to exist, and one of them does not.**
Voxelia has no interactive viewport: no draw loop, no presentation surface, no
frame pacing to a display. The interactive draw loop is the standing owner gate
that the Demonstration halves of `VOX-SUR-001`–`006`, `VOX-SUR-008`, `VOX-MPR-011`
and others already wait on.

So the naive readings both fail. "Satisfied, because everything is off-screen" is
true but vacuous — it claims equivalence with something absent. "Blocked on the
draw loop" would be consistent with the other gated rows, but it is wrong for a
row whose declared method is `T` and whose deliverable is the off-screen output
Voxelia already produces.

## The reading: equivalence reduces to purity of the render path

`SliceRenderer`'s entire contract is `render(_ request: RenderRequest) async
throws -> RenderResult`. There is exactly one entry point, and both backends
implement it. Therefore:

> If a render's output is a pure function of its request, then any future
> interactive caller issuing the same request **necessarily** receives the same
> bytes. Equivalence with the interactive viewport does not need the viewport to
> exist; it needs the render path to have no other input.

That converts an untestable comparison into a testable property, and it is the
same move `ADR-0206` made for annotation registration, where **statelessness is
the requirement** and the intuitive stabilising behaviours are exactly what would
break it.

Checking §35.1's nine semantics against `RenderRequest`, eight travel in the
request itself:

| §35.1 semantic | Where it travels |
|---|---|
| Viewport request | `RenderRequest.viewport` |
| Plane geometry | `scene`'s layer geometry |
| Interpolation | `RenderRequest.interpolation` |
| Value transformation | the layer's transfer function |
| Windowing | the transfer function's `greyscaleWindow` |
| MONOCHROME handling | the transfer function's polarity |
| Output colour descriptor | `colourOutput`, `colourTransform`, `outputColourSpace` |
| Shader or CPU implementation | the `SliceRenderer` conformer chosen |

## The finding: the ninth semantic does not travel in the request

**Padding policy is not expressible in a `RenderRequest`.** It reaches the
pipeline through the renderer's injected `windowStage`, and
`ExactSliceRenderer`'s convenience initialiser hard-codes `paddingValue: nil`.

So the purity claim is not quite the one it is tempting to write. Output is a pure
function of **the request and the renderer's injected stages** — not of the
request alone. Two callers that construct their renderers differently can
legitimately diverge, and §35.1 lists padding precisely because that divergence
matters clinically: a windowed render of padded CT maps padding values as if they
were tissue.

The equivalence is therefore stated **conditionally**: identical requests through
identically constructed renderers produce identical output. That is the true
statement, it is what the tests verify, and it names the one channel a future
interactive viewport must not diverge on. Writing the unconditional version would
have been shorter and wrong.

## The second finding: identifiers must differ, so equivalence cannot include them

The first version of the equivalence test rendered the same request twice through
one renderer and failed with `duplicateObjectIdentifier`.

That is the naming contract working correctly rather than a defect.
`ADR-0117`-style naming makes identifiers the host's to mint, and the test's
naming closure was a pure function of the stage, so the second render re-minted
the first render's object identifiers and `PublicationCoordinator` refused them.
A real viewport drawing repeatedly must mint fresh identifiers per frame.

The consequence for this row is substantive: **off-screen and interactive output
can never be identical in identity**, only in bytes and presentation claims. So
equivalence is defined over `RenderResult.presentation` and the published sample
bytes, and explicitly not over `outputObjectID`. A record asserting "byte
identical results" without that distinction would be describing something
unachievable.

## Decision

1. **`VOX-VS1-016` is discharged, on the reading that equivalence with the
   interactive viewport is purity of the render path with respect to its request.**
   The row's `T` method is satisfied by tests, not by inspection alone.
2. **The equivalence is conditional on identical renderer construction**, because
   padding policy travels through the injected stage rather than the request. The
   condition is stated rather than assumed away.
3. **Equivalence is defined over published sample bytes and
   `PresentationProvenance`, never over object identifiers**, which differ by
   design per the naming contract.
4. **Three tests, each proving something the others cannot.** One request rendered
   twice is byte-identical; an intervening materially different render does not
   change a repeat of the first, which is what makes the claim about the renderer
   *instance* rather than a single call; and two independently constructed
   renderers agree exactly, which is the case that actually models an export path
   and a viewport each building their own.
5. **Non-vacuity is asserted, not assumed.** Each test pins the byte count, because
   two empty arrays also compare equal. This follows `ADR-0249` stage three's
   lesson that a passing comparison is not evidence until its operands are known
   to be real.
6. **No `offScreen` symbol is introduced.** There is nothing for it to distinguish:
   a flag whose only value is "off-screen" would claim a distinction the code does
   not make, and the reading above is what makes the distinction unnecessary.
7. **§35.3's final-display-conversion clause is not claimed.** It concerns a
   colour conversion between render target and display, which needs a display —
   and `ADR-0209` already holds that declaring a colour space grants no conversion
   authority. Nothing here converts, so nothing needs validating.
8. **No algorithm specification and no oracle.** No numeric boundary is fixed; the
   tests compose accepted operations and compare bytes.

## Alternatives considered

### Claim the row is satisfied because all output is off-screen

Rejected as vacuous. It is true and it establishes nothing about equivalence with
a viewport, which is the whole content of the requirement.

### Defer the row to the owner-gated draw loop

Rejected. The row declares `T` and its deliverable is off-screen output, which
exists. Deferring it would park a testable property behind a gate it does not
depend on — and the purity reading shows the comparison can be made without an
interactive path at all.

### Add an `offScreen` flag or a separate off-screen entry point

Rejected; see decision 6. Two entry points would create the very divergence the
requirement forbids, and a flag with one reachable value is a false distinction.

### Make padding part of `RenderRequest` so the purity claim becomes unconditional

**Deferred rather than rejected, and it is the right eventual answer.** Padding is
a presentation semantic that §35.1 lists alongside eight others that do travel in
the request, so its absence is an asymmetry rather than a design choice. Making it
a request field would need a padding policy vocabulary — the plan's §28.4 offers
two candidate rules and says the choice is "separately approved" — so it needs its
own record and is not smuggled into this one.

## Consequences

The first vertical slice stands at **seventeen of twenty** rows. `010` (Metal
three-view differential) and `018` (steady-state GPU memory) remain.

The render path now has an explicit, tested statelessness guarantee, which is
what a future interactive viewport will rely on.

One asymmetry is named for its own record: padding policy does not travel in the
render request.

## Affected modules

None. `VoxeliaMetalTests` gains three tests and one helper; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "ExactSliceRenderer"
swift test
swift format lint --strict Tests/VoxeliaMetalTests/ExactSliceRendererTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1022 tests in 191 suites pass.

## Migration

1. This record and its tests.
2. **Open, its own record**: a padding policy in `RenderRequest`, choosing between
   the plan's §28.4 candidate rules, which would make the equivalence
   unconditional.
3. Remaining first-slice rows: `010` Metal three-view differential, `018`
   steady-state GPU memory measurement.

## Supersession

This record supersedes nothing. It **answers the question** `ADR-0245`,
`ADR-0247` and `ADR-0248` each recorded as open, and corrects none of them — they
deferred the reading rather than getting it wrong.

## References

- [ADR-0085 - Render request, result and protocol](ADR-0085-render-request-result-and-protocol.md)
- [ADR-0206 - Annotation registration design](ADR-0206-annotation-registration-design.md)
- [ADR-0209 - Display colour vocabulary](ADR-0209-display-colour-vocabulary.md)
- [ADR-0245 - Downstream slice requirement assessment](ADR-0245-downstream-slice-requirement-assessment.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

---
document_id: "ADR-0252"
title: "CPU Metal three-view differential"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VS1-010"
---

# ADR-0252 - CPU Metal three-view differential

## Context

`ADR-0248` sized `VOX-VS1-010` as "present; needs a differential run". The first
half of that was right and **the second half overstated the remaining work**:
`ADR-0221` already discharged the row's Test half through
`MultiplanarRenderCoordinator`, and correctly left the Demonstration half on the
owner-gated interactive draw loop. Nothing claimable remains on the row.

What *is* missing is a comparison the plan's §53 validation table requires and no
suite performs: CPU against Metal, on all three planes. This record adds that
evidence to an already-discharged row rather than re-discharging it.

## What the two renderers actually are

`MetalSliceRenderer` **is** `ExactSliceRenderer` with different stages injected.
The window, invert and composite stages execute Metal operations with
`binary32-device`, `approximate` claims; the **resample stage remains the accepted
exact CPU operation**, because whole-sample selection has no device approximation
to claim.

Two consequences follow, and both matter more than the test result.

**First, the differential compares the window stage, not interpolation.** The
plan's table has a row for "Metal linear interpolation — CPU differential bounded
numerical equality". **That row cannot be exercised today**, because there is no
GPU resample: the resample is the same CPU operation in both renderers, so a
resample differential would compare CPU against CPU and pass vacuously. The
comparison this record performs is the one that is genuinely backend-divergent.

**Second, it independently confirms `ADR-0251`'s conditional framing.** That record
stated render-path purity as conditional on identical renderer construction,
because padding travels through the injected `windowStage`. `MetalSliceRenderer`
turns out to be the same pipeline distinguished *only* by its injected stages — so
"same request, different stages, different backend" is not a hypothetical channel
for divergence, it is how backend selection is implemented. The conditional
framing was load-bearing rather than pedantic.

## The result

Same volume, same request, all three planes, both backends, compared byte for
byte. Anisotropic extents (`2x3x4`) so a transposed or duplicated plane cannot
pass:

| Plane | Bytes | CPU vs Metal |
|---|---|---|
| Axial | 6 | **identical** |
| Coronal | 8 | **identical** |
| Sagittal | 12 | **identical** |

The GPU path genuinely ran: `MetalWindowLevelKernel` builds a command buffer,
encodes a compute pass and dispatches, and the renderer's own documentation
records that there is no silent fallback in either direction.

## The honest limit of that result

**Exact agreement here does not establish exact agreement in general, and the
record says so rather than banking the stronger claim.**

The Metal window stage claims `binary32-device` and `approximate`. This fixture
uses `uint8` samples with a window centre of `12` and width of `24` — small
integers where binary32 arithmetic is exact — so the two paths have nothing to
disagree about. The kernels agree **where the arithmetic is unambiguous**, which
is worth knowing and is not the same as agreeing everywhere.

The `approximate` claim therefore remains correct, and the plan's general
expectation for 8-bit output — "exact preferred; maximum difference ≤ 1 code value
if the rounding path is approved" — remains the right one for inputs where
binary32 is not exact.

## Decision

1. **No tolerance is introduced, and the test asserts exact equality.** The plan's
   §54 tolerance profile is explicitly provisional, "to be approved as
   `voxelia.m4.ct.diagnostic` version `1.0.0` before acceptance". Asserting the
   plan's stated preference — exact — needs no threshold and touches no gate. If
   the backends ever diverge by even one code value this test fails, which makes
   the tolerance an owner question rather than something a test quietly absorbed.
2. **`VOX-VS1-010` is not re-discharged.** `ADR-0221` claimed its Test half; its
   Demonstration half stays on the owner-gated draw loop. `ADR-0248`'s sizing of
   this row is corrected here.
3. **The result is scoped to the window stage and to exactly representable
   inputs**, per the limit above. A general CPU–Metal equivalence claim is not
   made.
4. **The absent GPU resample is recorded rather than worked around.** The plan's
   Metal-interpolation differential row has nothing to test until a device
   resample exists, and building one purely to satisfy a validation row would add
   a second sampling path — the refusal `ADR-0221` already makes.
5. **Non-vacuity is asserted**: each plane's byte count is pinned, so an empty read
   cannot pass, and the anisotropic volume means a transposed plane cannot either.
6. **No algorithm specification and no oracle.** Nothing new is frozen.

## Alternatives considered

### Assert `≤ 1` code value, as the plan's provisional profile allows

Rejected. The measurement is exact, so a tolerance would be looser than the
evidence supports, and §54 is unapproved. Asserting exactness makes any future
divergence visible instead of pre-absorbed.

### Add a differing-viewport case so interpolation participates

Rejected as evidence. The resample is the same CPU operation in both renderers, so
such a case would compare CPU against CPU and pass while appearing to test the
GPU. That is precisely the vacuous-pass failure `ADR-0249` stage three was written
to avoid.

### Build a GPU resample so the plan's interpolation row can be exercised

Rejected; see decision 4, and `ADR-0221`'s refusal of a second sampling predicate.

### Extend the differential to the real CT volume

Not rejected, and deliberately not done here. It would strengthen the evidence,
but the interesting inputs are ones where binary32 is *inexact* — and on those the
comparison needs the tolerance profile that is still an owner gate. Running it and
reporting a difference would produce a number nobody is yet authorised to accept
or reject.

## Consequences

The plan's CPU–Metal three-view comparison now exists, with its scope and limits
stated.

`ADR-0248`'s sizing is corrected: `010` had no claimable work left.

The first vertical slice's only row with claimable work remaining is `VOX-VS1-018`
(steady-state GPU memory, `A,T`), whose `A` half is already argued from unified
memory selecting shared storage.

## Affected modules

None. `VoxeliaMetalTests` gains one test and two helpers; no source changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "Multiplanar"
swift test
swift format lint --strict Tests/VoxeliaMetalTests/MultiplanarRenderCoordinatorTests.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record and its test.
2. **Owner gate, unchanged**: the `voxelia.m4.ct.diagnostic` tolerance profile,
   which a differential over inexact inputs would require.
3. **Open**: `VOX-VS1-018`'s steady-state measurement — the last first-slice row
   with claimable work.

## Supersession

This record supersedes nothing. It **corrects `ADR-0248`'s sizing** of
`VOX-VS1-010`, recording the correction here rather than editing that record.

## References

- [ADR-0221 - Multiplanar render path](ADR-0221-multiplanar-render-path.md)
- [ADR-0248 - Linked crosshair verification](ADR-0248-linked-crosshair-verification.md)
- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0251 - Off-screen equivalence reading](ADR-0251-off-screen-equivalence-reading.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

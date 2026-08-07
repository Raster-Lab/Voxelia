---
document_id: "ADR-0300"
title: "CPU Metal differential references"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-VAL-006"
---

# ADR-0300 - CPU Metal differential references

## Context

`VOX-VAL-006` requires that "diagnostic Metal kernels shall be compared against analytical,
CPU or approved independent references". P0, **`T,R`**, milestone M3, from `ADR-0290`'s sweep.

## The assessment, which is not what the sweep suggested

`ADR-0290` listed this row as untouched. That is true of the **records** and false of the
**tests**: all three diagnostic Metal kernels already had an analytical comparison.

| Kernel | Existing reference | Tagged to |
|---|---|---|
| `MetalWindowLevelKernel` | `VOXELIA-ALG-0002` binary64 model, anchored to registered fixtures | `VOX-PLT-011`, `VOX-REP-008` |
| `MetalInvertKernel` | `255 - x` over the whole 256-value domain | `VOX-PLT-011`, `VOX-MTL-016` |
| `MetalCompositeKernel` | `VOXELIA-ALG-0009` binary64 model over seeded stacks | `VOX-VAL-007`, `VOX-EXE-003` |

So the row's letter was already met, by tests tagged to other requirements, and no record
claimed it. Reporting this row as unverified would have been as wrong as reporting it as
discharged without looking.

**What was genuinely missing is the CPU leg.** Every one of those comparisons is against a
model **transcribed into the test file**. If a transcription and the shipped CPU operation
drifted apart, the Metal suite would keep passing while the product disagreed with itself —
and nothing anywhere compared `WindowLevelOperation` against `MetalWindowLevelOperation`,
`InvertDisplayOperation` against `MetalInvertDisplayOperation`, or `CompositeLayersOperation`
against `MetalCompositeLayersOperation`.

## Decision

1. **The two backends are compared at the operation level**, not the kernel level. The kernel
   suites already cover the kernels; what had no coverage is the pair of shipped operations
   agreeing on the same input.
2. **The input is an analytical phantom**, so a third independent leg is available. CPU equals
   GPU proves *consistency*; both equalling the phantom's closed form is what makes it
   *correctness*. Under the identity window a stored value maps to itself, so the phantom's
   own values are the reference.
3. **Window and level, and invert, are asserted byte-equal.** No tolerance, because none is
   needed: both are exact integer models.
4. **Composite is deliberately not asserted equal.** The GPU composites in float32 and the CPU
   in binary64. `ADR-0096` already measured that difference and bounded it at one code value
   with a ninety-nine per cent exact floor, so this test **composes that accepted bound**
   rather than inventing a tolerance. It is the only tolerance in the suite and the record it
   comes from is named.
5. **The differential is shown able to fail.** A test asserting equality is evidence only if
   unequal inputs give unequal outputs, so two windows that genuinely disagree are run through
   the same comparison and required to differ on both backends.
6. **`VOX-VAL-006`'s `T` is discharged.** Its **`R` is not**, and this record does not claim
   it — see below.

## The `R` is an owner action, and is recorded as outstanding

The row declares `T,R`. Review is a human judgement, and no test can supply it. It joins the
outstanding owner decisions rather than being quietly folded into the `T`.

Concretely, what the owner is being asked to review is the **composite tolerance**: whether a
one-code-value divergence between the CPU and GPU composite paths is acceptable for
diagnostic use. The evidence is in place — `ADR-0096`'s measurement, and now an
operation-level differential — and the judgement is not mine to make.

## Alternatives considered

### Report the row as untested because no record claimed it

Rejected. The tests exist and they do what the row asks; the gap was in the record trail and
in the CPU leg. Writing "untested" would have been the easier claim and the false one.

### Assert composite byte-equality

Rejected because it is not true. Asserting it would have produced a red test, and weakening it
to a tolerance invented here — rather than composed from `ADR-0096` — would have hidden that
the divergence is a known, measured property.

### Compare at the kernel level instead

Rejected. The kernels are already compared against analytical models. The operations are what
callers use, and they are where a drift between the shipped CPU path and the shipped GPU path
would actually reach a reader.

### Discharge the `R` on the strength of the `T`

Refused. Human approvals are recorded as explicit evidence gaps in this project, never treated
as passing.

## Consequences

`VOX-VAL-006`'s test obligation is discharged, and the three shipped operation pairs now have
a differential that the kernel-level analytical suites cannot provide.

The row stays open on its `R`, which is one more item for the owner-decision list rather than
a blocked piece of work.

**15 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. Five tests in `VoxeliaValidationTests`; no source file changes.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None to the product. The suite dispatches a handful of small kernels.

## Validation impact

```text
swift build && swift test
swift test --filter "CPUMetalDifferentialTests"
swift format lint --strict Tests/VoxeliaValidationTests/CPUMetalDifferentialTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1229 tests in 217 suites pass, up from 1224 in 216.

The Metal tests require a device. They run on this Apple-silicon host; a machine without one
would fail rather than skip, which is the existing behaviour of every Metal suite in the
repository and is not changed here.

## Migration

1. This record and five tests. No source changed.
2. **Next**: the derived queue's remaining 15 rows.
3. **Owner**: **one new decision** — whether the measured one-code-value CPU-to-GPU composite
   divergence is acceptable for diagnostic use, which is this row's `R`.

## Supersession

This record supersedes nothing. It **adds the CPU leg** to comparisons that already had an
analytical one, and claims `VOX-VAL-006`'s test obligation which no record had.

## References

- [ADR-0096 - Composite Metal kernel](ADR-0096-composite-metal-kernel.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0294 - Linear ramp phantom](ADR-0294-linear-ramp-phantom.md)
- [VOXELIA-ALG-0002 - Window level linear](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0009 - Overlay alpha compositing](../../algorithms/VOXELIA-ALG-0009-overlay-alpha-compositing.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

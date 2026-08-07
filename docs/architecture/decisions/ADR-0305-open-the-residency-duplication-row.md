---
document_id: "ADR-0305"
title: "Open the residency duplication row"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-009"
---

# ADR-0305 - Open the residency duplication row

## Context

`VOX-MTL-009` requires that "the backend shall minimise full-volume CPU-to-GPU duplication".
P0, **`A,T,D`** — analysis, test **and** demonstration — milestone M4, from `ADR-0290`'s
sweep.

Three verification methods is the most any row in this sweep has carried, and this record
does **not** discharge it. It measures what exists, states what each method needs, and names
the next increment.

## The measurement

The mechanism exists and is precise. `MetalResidencyManager.selection(for:)` maps the declared
`ResidencyPolicy` vocabulary onto a storage class:

| Policy | Selection | Condition |
|---|---|---|
| `.automatic` | `.shared` | device reports unified memory, else `sharedStorageUnavailable` |
| `.shared` | `.shared` | same |
| `.gpuOptimised` | `.privateDevice` | always |
| `.cpuOnly` | — | `policyRequiresNoDeviceResidency` |
| `.streamed`, `.sparse` | — | `unsupportedResidencyPolicy` |

**That mapping is the row's subject.** On unified memory a `.shared` buffer is one allocation
the CPU and GPU both address, so a full-volume copy never exists; `.privateDevice` is the case
where a duplicate does exist and is chosen deliberately for repeated GPU access. The manager
"never mutates a declared policy: every unfulfillable request is a typed rejection", so a
caller asking for no duplication cannot be silently given one.

## The finding

**Nothing measures duplication.** `ResidencyPolicyTests` covers the vocabulary and its
`Sendable` conformance, and its tests are tagged `MTA-18.2` — a milestone-task identifier, not
a requirement. No test names `VOX-MTL-009`, no test asserts that the `.automatic` path avoids
a copy, and no benchmark reports the working-set cost of a volume render.

So the row is in the same position as five others this arc has found: the property is designed
for, plausibly true, and **unevidenced**.

## Decision

1. **`VOX-MTL-009` is not discharged**, and this record claims none of its three methods.
2. **What each method needs is fixed here**, so the next increment is not free to redefine
   them:
   - **`A` (analysis)** — a written argument from the selection table above that the
     `.automatic` path allocates once on unified memory, together with the case where it
     cannot: `supportsUnifiedMemory == false`, where the row's guarantee is a typed refusal
     rather than a silent copy.
   - **`T` (test)** — assertions that `.automatic` and `.shared` select `.shared` on this
     host, that `.gpuOptimised` selects `.privateDevice`, and that the three refusing policies
     refuse by their own distinct case. Tagged to the requirement, unlike today's.
   - **`D` (demonstration)** — an owner-witnessed activity. It is **not** dischargeable by
     test, exactly as `VOX-HLS-001`'s is not.
3. **The measurement must not be a bare peak-memory figure.** `ADR-0271` established that a
   combined benchmark run retains several intermediates and its peak is a harness artefact; a
   duplication claim measured that way would be measuring the harness.
4. **No source changes here.** Opening a row is a reading and a decision, not a diff.

## Alternatives considered

### Discharge `A` now from the selection table

Rejected, narrowly. The table is the analysis's raw material, not the analysis: it says what
is selected, not what is allocated, and the difference is the whole requirement. Writing the
argument and citing this table would be a short increment and it deserves to be its own.

### Retag `ResidencyPolicyTests` to the requirement and call `T` done

Rejected, and it is the tempting shortcut. Those tests assert the vocabulary exists and is
`Sendable`. Neither fact bears on duplication, and relabelling them would put a requirement's
name on evidence that does not address it — which is precisely the defect `ADR-0300` had to
untangle in the other direction.

### Fold this into the next increment rather than record it

Rejected. The three methods needed defining before the work, or the increment doing the work
would have defined them to suit itself.

## Consequences

`VOX-MTL-009` is opened with its three verification methods scoped, and the sixth instance of
a designed-for-but-unevidenced property is recorded.

**11 entered-milestone rows remain** from `ADR-0290`'s sweep — unchanged, because this record
discharges nothing.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. This record measures nothing and changes nothing.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1229 tests in 217 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the `A` and `T` above, in one increment, since the test is what the analysis
   would otherwise have to assert in prose.
3. **Owner**: **one new item** — `VOX-MTL-009`'s Demonstration, which a test cannot supply.

## Supersession

This record supersedes nothing. It **opens** a row and fixes the meaning of its three
verification methods before any evidence is produced for them.

## References

- [ADR-0081 - Metal residency strategy](ADR-0081-metal-residency-strategy.md)
- [ADR-0271 - Compression benchmark and random access](ADR-0271-compression-benchmark-and-random-access.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0300 - CPU Metal differential references](ADR-0300-cpu-metal-differential-references.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

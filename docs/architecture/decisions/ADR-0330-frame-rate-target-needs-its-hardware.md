---
document_id: "ADR-0330"
title: "Frame rate target needs its hardware"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-PER-004"
---

# ADR-0330 - Frame rate target needs its hardware

## Context

`VOX-PER-004` requires that "conventional 512³ volume rendering shall target 30–60 frames per
second". P1, `T,D`, M6 — the last row in `ADR-0319`'s rederived queue.

## The measurement

**No frame-rate measurement exists.** `docs/benchmarks/` holds two records —
`VOXELIA-BEN-0001`, the first vertical slice baseline, and `VOXELIA-BEN-0002`, the compression
benchmark. Neither reports frames per second, and no test does.

## Why this row cannot be discharged here, and it is not for want of effort

**A frame rate is a number about a machine.** This host is an Apple-silicon Mac; a figure
measured on it would be a fact about this laptop, and the row's target is not qualified by
"on whatever hardware happened to run the suite".

**The reference hardware has not been named**, and it has been on the owner's decision list
since before this arc began. Until it is, a measurement has nothing to be measured against:
30–60 frames per second is either met or missed depending on the device, and both answers
would be equally true and equally useless.

Producing a number anyway would be the most tempting possible fabrication — it would look like
progress, it would be arithmetically honest, and it would answer a question nobody asked.

## Decision

1. **`VOX-PER-004` is not discharged, and no benchmark is run.**
2. **What a valid measurement needs is fixed here**, so the increment that takes it starts from
   the constraint rather than the harness:
   - the **named reference device**, from the owner;
   - a **512³ volume**, the row's own conventional case, rather than whatever fixture is
     convenient;
   - a **clean process**, per `ADR-0271` decision 4 — that record established that a combined
     run's peak is a harness artefact, and the same hazard applies to frame timing measured
     beside other work;
   - the **quality the frames were rendered at**, because `ADR-0329` records that interactive
     and full currently execute identically, so a frame rate today is a *full-quality* frame
     rate and must say so.
3. **The row is `P1`.** It is the only `P1` in the queue, and its blocking decision is one the
   owner already holds — so it is correctly last rather than neglected.

## Alternatives considered

### Benchmark on this host and report it as indicative

Rejected. "Indicative" is how a number about a laptop becomes a number about the product. If
the figure would not be cited in the validation report, it should not be produced under the
row's name.

### Pick a plausible reference device and measure against it

Refused. Choosing the reference hardware is the owner's decision, and selecting one to unblock
a row would spend that decision to make my own work look finished.

### Record the row as unbuilt

Rejected as the wrong category. The renderer exists and renders; what is missing is the
*criterion*, not the capability. `VOX-IMG-008` and `VOX-CON-008` are unbuilt; this row is
unmeasured.

## Consequences

`VOX-PER-004` is characterised, and with it **every requirement row in an entered milestone is
now claimed, discharged, characterised, or recorded as unbuilt with its blocking question
named.** `ADR-0319`'s queue is exhausted.

What remains is not a queue of unexamined rows but a list of **owner decisions**, each attached
to the row it blocks.

## Affected modules

None.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None. This record deliberately measures nothing.

## Validation impact

```text
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: `ADR-0319`'s criterion is rerun rather than assumed exhausted, since new rows enter
   as milestones open.
3. **Owner**: unchanged. The reference-hardware decision now visibly blocks a named row.

## Supersession

This record supersedes nothing. It **characterises** the last row in the rederived queue.

## References

- [ADR-0271 - Compression benchmark and random access](ADR-0271-compression-benchmark-and-random-access.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0329 - Interactive refinement is deferred](ADR-0329-interactive-refinement-is-deferred.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

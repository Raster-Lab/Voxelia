---
document_id: "VOXELIA-ALG-0046"
title: "Progress observation sequence v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# Progress observation sequence v1

## Purpose

This specification defines `progress-observation/v1`, the deterministic
reporting sequence selected by accepted
[`ADR-0222`](../architecture/decisions/ADR-0222-progress-reporting-design.md).
It fixes what a long-running operation reports, when it reports it, and what a
consumer may rely on.

## Progress is counts, never a fraction

An observation is a pair: how many units are complete, and how many there are.
A fraction would force a division and a rounding decision at every checkpoint —
two more numeric boundaries to freeze — and would discard the information a
consumer needs to display "3 of 128". Counts compose: a caller that wants a
percentage divides, with its own rounding, at the one place it is displayed.

## The cadence is the accepted one, reused verbatim

Observations are emitted at the **cancellation-checkpoint cadence** the accepted
algorithms already froze: every sixty-four facets or triangles, every four
thousand and ninety-six vertices, attributes or fragments. Inventing a second
cadence would mean two places for one decision to drift, and would make progress
density a new tunable nobody asked for.

## The frozen rule

```text
1. reject a negative total
2. reject a cadence below one
3. for completed = 0, cadence, 2*cadence, ... while completed < total:
       emit (completed, total)
4. emit (total, total)
```

## The four guarantees

A consumer may rely on exactly these, and the oracle checks every fixture
against all four:

1. **The total never changes** within one operation.
2. **Completed never decreases.**
3. **Completed never exceeds the total.**
4. **The final observation is exactly `(total, total)`** — always, including for
   zero work.

Guarantee 4 is why step 4 is unconditional. A consumer never has to infer
completion, and a progress display always terminates.

## Edge behaviour, all registered

- **Zero work reports exactly one observation**, `(0, 0)`, so "nothing happened"
  needs no special case in any consumer.
- **Work below one cadence step reports two**, the opening zero and the final
  total — never a single silent jump.
- **An exact multiple of the cadence does not duplicate the final count**: the
  loop stops strictly before the total, and the final observation closes it.
  The registered `exact-multiple` fixture pins `128` at a cadence of `64` to
  three observations, not four.
- **A partial last step is reported at its true count**, not rounded up to a
  cadence boundary.
- **A cadence of one** reports every unit and still terminates exactly once.

## Progress cannot change a result

The observation is delivered to a `Void`-returning observer, so it cannot
influence control flow. This is the deliberate asymmetry with the cancellation
probe, which returns `Bool` precisely because it *is* allowed to stop the work.
An operation's output is therefore bit-identical whether or not an observer is
attached, and the migration proves it.

## Determinism and failure classification

The sequence is a pure function of the total and the cadence. The failure
family is exactly two payload-free cases, `negativeTotal` and `invalidCadence`.
There is no other failure, because the sequence is generated rather than
supplied.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0222-progress-observation-oracle.py`](../progress/evidence/ADR-0222-progress-observation-oracle.py).
It records thirteen fixtures: zero work; work below one step; an exact multiple;
a partial last step; a single unit; the three counts around a cadence boundary;
a dense cadence of one; the vertex cadence at one past its boundary; a negative
total; and a zero and a negative cadence.

The registered output is:

```text
fixtureSHA256=cbe6f376b55cdb20b2b9791d8dcfbd638096d034a3fd1d20c4094359a1c27e39
sequenceSHA256=521642346b28883ab7813dbb316ac845fc488ad7ef166c9dc71c776c846850db
fixtures=13 reported=10 rejected=3
units=counts fraction=never cadence=accepted-checkpoint
monotone=guaranteed final=always totalChanges=never
```

## Complexity and exclusions

`O(total / cadence)` observations, each `O(1)`.

Time estimates, throughput rates, nested or weighted sub-progress, cancellation
through the observer, progress for unbounded work, and delivery across a
concurrency boundary remain separate contracts.

## References

- [ADR-0222 - Progress reporting design](../architecture/decisions/ADR-0222-progress-reporting-design.md)
- [VOXELIA-ALG-0028 - Freudenthal surface extraction](VOXELIA-ALG-0028-freudenthal-surface-extraction.md)
- [VOXELIA-ALG-0031 - Triangle mesh total facet area](VOXELIA-ALG-0031-triangle-mesh-total-facet-area.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)

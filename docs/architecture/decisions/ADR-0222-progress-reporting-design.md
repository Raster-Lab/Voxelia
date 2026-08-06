---
document_id: "ADR-0222"
title: "Progress reporting design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-NUM-001"
  - "VOX-EXE-008"
---

# ADR-0222 - Progress reporting design

## Context

`ADR-0218` found `VOX-EXE-008` — "execution shall support progress reporting as
an asynchronous stream or equivalent non-blocking mechanism", **P0**, M2 —
genuinely unbuilt: no progress API exists in any module, and the only textual
matches were an unrelated storage access mode.

`ADR-0221`'s ledger entry set the selection rule for what to take next: pick by
whether an item is **unblocked and has a consumer**, not by list order. Of the
five gaps the traceability sweep surfaced, three are blocked behind gated
measurement workloads. This one is neither blocked nor speculative: it is P0, it
needs no hardware, and the structural hook already exists — **seven accepted
cancellation probes already fire at frozen checkpoints inside the long-running
kernels**, which is exactly where progress would be reported.

`VOX-DVR-014` was considered first and set aside: it is already an affected
requirement of accepted `ADR-0175`, and the volume-rendering arc is closed.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0046` defines `progress-observation/v1`.
2. **The mechanism is an observer closure, not an `AsyncStream`.** The
   requirement says "asynchronous stream **or equivalent non-blocking
   mechanism**", and the closure is the equivalent this project already uses in
   mirror form: every long-running kernel takes a
   `@Sendable (Checkpoint) -> Bool` cancellation probe. A
   `@Sendable (Progress) -> Void` observer is its symmetric counterpart, adds no
   concurrency machinery to a deterministic kernel, and cannot suspend one.
3. **An `AsyncStream` was rejected for a specific reason, not a stylistic
   one.** It would introduce a buffering policy, a termination semantic and a
   continuation lifetime into every accepted kernel — and under any bounded
   buffering policy a dropped or coalesced element would make the observed
   sequence depend on consumer speed. A model whose output depends on how fast
   somebody reads it cannot be frozen or oracle-tested.
4. **Progress cannot change a result, and the type says so.** The observer
   returns `Void`, so it cannot influence control flow. This is the deliberate
   asymmetry with the cancellation probe, which returns `Bool` precisely because
   it *is* allowed to stop the work.
5. **Progress is counts, never a fraction.** A fraction forces a division and a
   rounding decision at every checkpoint — two more numeric boundaries — and
   discards what a consumer needs to show "3 of 128". The caller divides once,
   where it displays.
6. **The cadence is the accepted cancellation-checkpoint cadence, reused
   verbatim**: every sixty-four facets or triangles, every four thousand and
   ninety-six vertices, attributes or fragments. A second cadence would be a
   second place for one decision to drift, and would make progress density a
   tunable nobody requested.
7. **A final observation is always emitted, including for zero work.** A
   consumer never infers completion, and a progress display always terminates.
   Zero work reports exactly one observation.
8. **An exact multiple of the cadence does not duplicate the final count**: the
   loop stops strictly before the total. A registered fixture pins `128` at
   cadence `64` to three observations rather than four, because an
   implementation that emits the boundary and then the total is the obvious
   off-by-one here.
9. **Four guarantees are frozen and oracle-checked on every fixture**: the
   total never changes, completed never decreases, completed never exceeds the
   total, and the final observation is exactly `(total, total)`.
10. **The failure family is exactly two payload-free cases**, `negativeTotal`
    and `invalidCadence`. There is no other failure, because the sequence is
    generated rather than supplied.
11. **Independent analytical evidence is registered now**: thirteen fixtures,
    ten reported and three rejected, with two SHA-256 digests frozen in
    `ALG-0046`.

## Alternatives considered

### Use `AsyncStream`

Rejected; see decision 3.

### Report a fraction in `0...1`

Rejected; see decision 5. It would also make the zero-work case ill-defined,
since `0/0` has no value the model could publish.

### Let the observer return a `Bool` so it can cancel

Rejected; see decision 4. Cancellation already has an accepted mechanism, and
giving progress a second one would mean two places that can stop the work and
two orderings to reason about.

### Invent a progress-specific cadence, denser than the checkpoint cadence

Rejected; see decision 6.

### Emit no observation for zero work

Rejected; see decision 7. Every consumer would need the same special case, and
a progress display would hang on an empty operation.

## Consequences

The migration can add one small value type, one observer type and the sequence
rule, then thread the observer through the long-running kernels at the
checkpoints that already exist. `VOX-EXE-008` becomes dischargeable, and it
declares **T** alone, so a green migration closes it completely.

The deliberate limitations are no time estimates, no throughput rates, no nested
or weighted sub-progress, no progress for unbounded work, and no delivery across
a concurrency boundary.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the vocabulary to `VoxeliaExecution` and threads it through the
kernels that already carry a cancellation probe. No dependency edge changes.

## Compatibility impact

None in this design-only increment. The migration must not change any existing
kernel's output, and the suite will prove it.

## Security impact

Observations carry two counts and no content; errors are payload-free.

## Performance and memory impact

One closure call per checkpoint, at a cadence that already exists for
cancellation.

## Validation impact

The oracle registers:

```text
fixtureSHA256=cbe6f376b55cdb20b2b9791d8dcfbd638096d034a3fd1d20c4094359a1c27e39
sequenceSHA256=521642346b28883ab7813dbb316ac845fc488ad7ef166c9dc71c776c846850db
fixtures=13 reported=10 rejected=3
```

Migration must reproduce all thirteen fixtures bit-exactly, prove the four
guarantees, prove the exact-multiple case does not duplicate the final
observation, prove zero work still reports once, and **prove that attaching an
observer leaves an existing kernel's output byte-identical** — the claim that
progress cannot change a result.

## Migration

1. Add the progress vocabulary and sequence to `VoxeliaExecution`.
2. Thread the observer through one long-running kernel as the first consumer,
   with the byte-identity proof.

## Supersession

This record supersedes nothing. It fills a gap `ADR-0218` recorded.

## References

- [ADR-0175 - Exact volume renderer](ADR-0175-exact-volume-renderer.md)
- [ADR-0218 - Execution and CPU traceability](ADR-0218-execution-and-cpu-traceability.md)
- [ADR-0221 - Multiplanar render path](ADR-0221-multiplanar-render-path.md)
- [VOXELIA-ALG-0046 - Progress observation sequence](../../algorithms/VOXELIA-ALG-0046-progress-observation.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

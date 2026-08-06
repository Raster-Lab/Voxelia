---
document_id: "ADR-0259"
title: "Cancellable decode session"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-SEC-001"
  - "VOX-CMP-009"
---

# ADR-0259 - Cancellable decode session

## Context

Compression increment (d). `VOX-CMP-009` requires codec adapters to support
cancellation **and** to not publish partial data as complete output, declaring `T`.

`ADR-0255` decision 4 bound this increment in advance: it must compose `ADR-0249`'s
accepted cancellation shape rather than invent a second model. That shape is a
checkpoint enum, an injected `@Sendable (Checkpoint) -> Bool` probe, and a `.final`
check immediately before the aggregate is returned.

## Decision

1. **`ADR-0249`'s shape is reused, not reinvented.** Four checkpoints —
   `.destination`, `.decode`, `.validation`, `.final` — an injected probe, and the
   same rule at every site: throw `cancelled` and return nothing.
2. **`.decode` is checked immediately *before* the decode call, not after.** That
   is the last site at which cancellation costs nothing; past it the work is spent
   whether or not the result is used. A test asserts the decode closure did **not**
   run when cancelled there, paired with a control proving the same closure does run
   otherwise — so the zero is cancellation rather than a closure that never fires.
3. **The checkpoint set covers only the stages the session performs**, per
   `ADR-0249` decision 5. A documented-but-unreached checkpoint would be a false
   claim about where cancellation is honoured, and a test asserts the visited sites
   are exactly the documented ones, in order.
4. **`.final` is what makes "no partial data published as complete" structural.**
   The decode has completed and every check has passed, and the caller still
   receives nothing: the throw replaces the return, so there is no partial aggregate
   to publish by mistake.
5. **`ADR-0258`'s checks are composed, not restated.** A self-consistent report that
   disagrees with the payload's declarations is refused with the *validator's* own
   case, and the ceiling is admitted before the decode runs. A test asserts a
   refused ceiling leaves the decode closure unrun, which is the ceiling's whole
   purpose.
6. **The decode is a caller-supplied closure**, so the session is testable with no
   codec linked — the same source-agnostic shape `ADR-0249` and `ADR-0258` used, and
   the reason this increment proceeds while the arc's supply-chain questions are
   open.
7. **No algorithm specification and no oracle.** No numeric boundary is frozen.

## The finding: a decode's report can lie about its own bytes, and `ADR-0258` could not catch it

`ADR-0258`'s validator compares a `DecodedSampleClaim` against a payload's
declarations. **The bytes were never part of that comparison**, because the
validator takes only the report.

So a decode that returns forty bytes while reporting forty-eight passes the
validator completely: the report matches the declarations exactly, and the
disagreement is between the report and *itself*. Admitting it would publish
uninitialised or stale destination bytes as samples — precisely the "partial data as
complete output" `VOX-CMP-009` forbids.

The session therefore checks `claim.byteCount == bytes.count` **before** invoking
the validator, with its own error case rather than reusing
`decodedByteCountMismatch`: the two are different failures and a caller should be
able to tell a lying codec from a mismatched one. Both directions are tested.

**This is a composition gap found by building the next layer, not by reviewing the
last one.** `ADR-0258` is not wrong — a validator over a report can only check the
report — but its guarantee was narrower than it reads, and the narrowing only became
visible when bytes appeared alongside the claim. Worth generalising: when a later
stage introduces a value an earlier admission never saw, ask what the earlier
admission was silently assuming about it.

## Alternatives considered

### Check the report against its bytes inside `ADR-0258`'s validator

Rejected, though it is tempting. The validator's input is a report; giving it the
bytes as well would widen its contract to cover a check that belongs where bytes
first exist, and would make it impossible to validate a report before a decode
allocates.

### Reuse `decodedByteCountMismatch` for the self-disagreement

Rejected; see the finding. A codec whose report disagrees with its own output is a
different fault from one whose output disagrees with a source's declarations, and
collapsing them would lose the distinction a caller needs to attribute the problem.

### Check `.decode` after the call, so cancellation covers the decode itself

Rejected. Cancellation cannot interrupt a synchronous codec call, so a check after
it would discard completed work while reporting cancellation — which reads as
responsiveness the session does not have. The honest position is that `.decode` is
the last free site, and the record says so.

### Add a per-tile or per-band checkpoint inside the decode

Deferred rather than rejected. It would make cancellation genuinely responsive
during a long decode, but it requires a codec API that reports progress, and no
codec is linked. It belongs with whichever increment first wraps a real codec.

## Consequences

`VOX-CMP-009` is discharged. **Five of the compression arc's seven buildable rows
are done**: `002`, `007`, `009`, `010`, `013`. Increment (e) — `VOX-CMP-003` and
`VOX-CMP-008` — is the remainder.

A decode's report is now checked against itself as well as against its
declarations.

## Affected modules

`VoxeliaCompression` gains `CompressedDecodeSession`, its checkpoint vocabulary,
`DecodedSamples` and a failure family. No other module changes.

## Compatibility impact

Additive.

## Security impact

Positive. A cancelled decode publishes nothing, and a codec that misreports its own
output length cannot have stale destination bytes admitted as samples. The refusals
disclose neither figure.

## Performance and memory impact

Four closure calls per decode, and one integer comparison. The `.decode` checkpoint
placement means a cancelled decode does no codec work at all.

## Validation impact

```text
swift build && swift test
swift test --filter "CompressedDecodeSession"
python3 Tools/Scripts/check_swift_safety.py
swift format lint --strict Sources/VoxeliaCompression/Public/CompressedDecodeSession.swift
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1053 tests in 195 suites pass.

## Migration

1. This record.
2. Increment (e): `VOX-CMP-003` and `VOX-CMP-008` — the source, slice, slab and
   brick shapes, and caller-provided destination storage, where a
   `CompressedRepresentation` becomes attached to a payload.
3. **Deferred**: an in-decode progress checkpoint, once a real codec API can report
   progress.
4. **Owner decisions, unchanged**: reconciling the six blocked rows, and whether a
   codec may be declared a direct dependency.

## Supersession

This record supersedes nothing. It **records a narrowing** of `ADR-0258`'s
validator guarantee — that it cannot see a report's own bytes — rather than editing
that record.

## References

- [ADR-0249 - Cancellable CT import session](ADR-0249-cancellable-ct-import-session.md)
- [ADR-0255 - Open the compression arc](ADR-0255-open-the-compression-arc.md)
- [ADR-0258 - Compressed decode admission](ADR-0258-compressed-decode-admission.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

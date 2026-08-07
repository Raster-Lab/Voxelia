---
document_id: "ADR-0312"
title: "Canonical two dimensional pipeline"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-R2D-001"
---

# ADR-0312 - Canonical two dimensional pipeline

## Context

`VOX-R2D-001` requires that "Voxelia shall provide a canonical diagnostic two-dimensional
presentation pipeline". P0, **`I,T`**, milestone M3, from `ADR-0290`'s sweep.

## The measurement

**No record in the repository mentions `VOX-R2D-001`.** The only occurrences are the
requirements baseline itself, the traceability index and the progress ledger.

The pipeline exists, and three things make it *canonical* rather than merely present:

1. **One protocol.** `SliceRenderer` declares the contract, and `ExactSliceRenderer` is its
   only shipped conformance. A second presentation path would have to conform to the same
   protocol or be visibly outside it.
2. **One entry point.** `render(_ request: RenderRequest) async throws -> RenderResult` — a
   caller supplies a request and receives a result; there is no alternate route that skips
   stages.
3. **Named stages.** `RenderPublicationStage` gives the pipeline's steps a vocabulary, so a
   render's provenance says which stages ran rather than leaving it to be inferred.

Its tests are the thirteen `[Pipeline]` cases in `ExactSliceRendererTests` — end-to-end
rendering, cropping before windowing, every stage cached, both qualities executing
identically, inverted polarity, and a differing viewport resampling both stages. All of them
were tagged to `VOX-VS1-017`, `VOX-VS1-019`, `VOX-ARC-008` and the other `VOX-R2D` rows, and
none to this one.

So this is the third row in this sweep — after `VOX-VAL-006` and `VOX-ARC-009` — whose
evidence existed while the record trail pointed elsewhere.

## Decision

1. **`VOX-R2D-001`'s `I` is discharged** on the protocol, its single conformance and the named
   publication stages.
2. **Its `T` is discharged** by the thirteen `[Pipeline]` tests, read for this row.
3. **"Canonical" is read as *one contract with one shipped path*, not *one implementation
   forever*.** A second conformance is permitted by the protocol and would not by itself
   breach the row; what would breach it is a presentation route that bypassed the contract.
   `ADR-0300` is the evidence that the two backends behind that contract do not diverge:
   the CPU and Metal window, invert and composite operations agree byte for byte, or within
   `ADR-0096`'s measured bound for composite.
4. **No new test and no new gate.** The pipeline is exercised end to end thirteen times, and
   `check_package_graph.py` already pins which module may own it.

## Alternatives considered

### Add a gate asserting only one `SliceRenderer` conformance exists

Rejected; see decision 3. It would forbid something the protocol deliberately allows, and it
would be enforcing a reading of "canonical" that the requirement does not carry.

### Retag the thirteen tests to this row

Rejected. They genuinely evidence the rows they name; adding this row's identifier to all of
them would make the tag a list of everything a test touches rather than what it is for. The
record is the right place for the reading.

### Treat the row as covered because `VOX-R2D-005`, `008`, `013` and `014` are

Rejected. Those are properties *of* the pipeline — polarity, resampling claims, padding.
`VOX-R2D-001` is the claim that a canonical pipeline exists at all, and it is the one that
would still be unmet if the others were satisfied by four unrelated code paths.

## Consequences

`VOX-R2D-001` is discharged, and the reading of "canonical" it rests on is written down rather
than assumed.

**6 entered-milestone rows remain** from `ADR-0290`'s sweep.

## Affected modules

None. This record adds no code, no test and no gate.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter "ExactSliceRenderer"
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, unchanged — this record adds no code.

## Migration

1. This record.
2. **Next**: the derived queue's remaining 6 rows.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **claims** a row whose implementation and tests were
delivered without any record naming it.

## References

- [ADR-0096 - Composite Metal kernel](ADR-0096-composite-metal-kernel.md)
- [ADR-0290 - Diagnostic fail closed](ADR-0290-diagnostic-fail-closed.md)
- [ADR-0300 - CPU Metal differential references](ADR-0300-cpu-metal-differential-references.md)
- [ADR-0304 - Interaction state ownership](ADR-0304-interaction-state-ownership.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

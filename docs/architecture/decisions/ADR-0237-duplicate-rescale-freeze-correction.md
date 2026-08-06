---
document_id: "ADR-0237"
title: "Duplicate rescale freeze correction"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-006"
  - "VOX-VS1-006"
---

# ADR-0237 - Duplicate rescale freeze correction

## Context

`ADR-0236` and `VOXELIA-ALG-0051` froze CT stored-value interpretation, including
the rescale `(slope * value) + intercept`. Planning the next increment — bridging
the ingested volume into the existing published-image pipeline — surfaced that
this boundary **was already frozen**.

## The finding: one boundary, two written specifications

`VOXELIA-ALG-0003 - Linear stored-to-real value mapping binary64-v1` has been
accepted since milestone M1. It states its purpose includes "rescale", freezes

```text
r = (x * scale) + offset
```

forbids a fused multiply-add for the same reason, and carries a worked fixture at
`scale = 1, offset = -1024` described as **"the CT rescale"**. `WindowLevelOperation`
has evaluated it in that order since it was written.

`VOXELIA-ALG-0051` restated the same computation with the operands in the opposite
textual order. So the register now holds **two specifications of one numeric
boundary**, which is precisely the drift risk an algorithm register exists to
prevent.

## The results are identical, and that was verified rather than assumed

IEEE-754 multiplication is commutative, so `(x * s)` and `(s * x)` produce the same
bit pattern for every pair of operands. That is a theoretical claim, so it was
checked: **all thirteen `VOXELIA-ALG-0051` fixture triples plus two million random
cases** — spanning subnormals, signed zeros, `1e-300`, `1e300`, zero scale and
negative scale — produced **zero bit-pattern differences**.

**So there is no numerical defect and no wrong result was ever produced.** What
exists is a governance defect: a second frozen statement of a boundary that
already had one.

## Why it was missed, which is the more useful part

The duplicate was not found because the search was in the wrong place. Before
freezing `VOXELIA-ALG-0051`, the codebase was searched for an existing *evaluator*
of a linear transform — and one was found, in `WindowLevelOperation` — but its
governing **specification** was never traced. The algorithm register is the
authoritative index of frozen boundaries, and it was not consulted.

**The rule this yields: before freezing a numeric boundary, search the algorithm
register for that boundary, not the source for its callers.** A boundary can be
frozen and have no evaluator yet; an evaluator can exist and cite a specification
by number that a code search will not reveal.

## Decision

1. **`VOXELIA-ALG-0003` governs the rescale.** `VOXELIA-ALG-0051`'s rescale clause
   is **superseded** by this record and is no longer the authority for that step.
   `VOXELIA-ALG-0051` retains what is genuinely new — see decision 3.
2. **The implementation is written in `VOXELIA-ALG-0003`'s order**,
   `(Double(value) * slope) + intercept`, so the code matches the governing
   specification textually as well as numerically. The change is behaviour-preserving
   by the verification above, and the existing fixtures continue to pass unchanged.
3. **`VOXELIA-ALG-0051` keeps the three stages `VOXELIA-ALG-0003` does not
   cover**, and those are the increment's real contribution:
   - little-endian container assembly from a sample's bytes;
   - masking to `bitsStored` and sign extension, where a twelve-bit signed
     `0x0FFF` is `-1`;
   - padding compared on the **stored** value, before the rescale, which
     fixture V10 exists to protect.
4. **Neither accepted record is edited.** `VOXELIA-ALG-0051` stays as accepted and
   this record narrows its authority, following the practice `ADR-0233` and
   `ADR-0234` used for the same situation.
5. **No fixture is deleted.** `VOXELIA-ALG-0051`'s rescale fixtures still verify
   the implementation; they now verify conformance to `VOXELIA-ALG-0003` instead
   of to a duplicate. Removing them would reduce coverage to make a bookkeeping
   point.

## A second finding: the existing pipeline refuses narrowed bit counts

While tracing this, the treatment of `ScalarFormat.validBitCount` across the
accepted modules turned out to be uniform and restrictive: `LabelledSurfaceSourceAdapter`
and `TriangleMeshVertexNormalGeneration` **refuse** a narrowed valid bit count, and
every other operation constructs formats with `validBitCount: nil`. **Nothing in
the project masks by it.**

So `VOXELIA-ALG-0051`'s masking and sign-extension stages are not duplicates —
they are the only place a narrowed CT format is handled at all. It also means a
published CT volume declaring `validBitCount = 12` would be **refused** by some
existing operations, which is a real compatibility constraint for the bridge
increment. The real corpus does not hit it (its Bits Stored equals the container
width, so `validBitCount` is `nil`), but a twelve-bit CT would, and the bridge
must decide what to do rather than discover it.

## Alternatives considered

### Leave both specifications in place

Rejected. They agree today, and two written statements of one boundary is exactly
how they stop agreeing later — a future amendment to one would not be applied to
the other.

### Edit `VOXELIA-ALG-0051` to remove the rescale clause

Rejected. It is accepted, and the standing practice is to narrow authority in a
successor rather than rewrite history.

### Withdraw `VOXELIA-ALG-0051` entirely and reissue

Rejected. Three of its four stages are new, needed and verified; withdrawing it
would discard genuine work to tidy one clause.

### Change nothing in the code, since the results match

Rejected. They match, and the code should still read as an implementation of the
specification that governs it. A reader comparing the two would otherwise have to
rediscover the commutativity argument this record makes once.

## Consequences

One boundary, one specification. The rescale is governed by `VOXELIA-ALG-0003` as
it always should have been, and `VOXELIA-ALG-0051` covers the DICOM-specific
decoding that nothing else does.

The bridge increment inherits a stated compatibility constraint about narrowed bit
counts instead of meeting it by surprise.

## Affected modules

`VoxeliaImaging`: one expression in `CTValueInterpreter` is written in the
governing order. No behaviour changes.

## Compatibility impact

None. Verified bit-identical across the fixtures and two million random cases.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter CTValueInterpreter    # unchanged fixtures still pass
swift test
python3 Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

## Migration

1. This record, and the expression-order alignment.
2. **Next**: the bridge from an ingested CT volume to a published `ImageData`,
   which must decide the narrowed-bit-count question above and carries
   `VOX-VS1-019`'s provenance obligation.

## Supersession

This record **supersedes the rescale clause of `VOXELIA-ALG-0051`**, which is
governed by `VOXELIA-ALG-0003` instead. It supersedes nothing else, and edits no
accepted record.

## References

- [ADR-0236 - Stored value interpretation](ADR-0236-stored-value-interpretation.md)
- [VOXELIA-ALG-0003 - Linear stored-to-real value mapping](../../algorithms/VOXELIA-ALG-0003-linear-value-transform.md)
- [VOXELIA-ALG-0051 - CT stored-value interpretation](../../algorithms/VOXELIA-ALG-0051-stored-value-interpretation.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

---
document_id: "ADR-0210"
title: "VOI lookup design"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-API-003"
  - "VOX-ERR-001"
  - "VOX-NUM-001"
  - "VOX-R2D-002"
  - "VOX-R2D-007"
---

# ADR-0210 - VOI lookup design

## Context

`ADR-0208` decision 2(b) makes VOI LUT application the arc's second increment,
governed by `VOX-R2D-007`: "The pipeline shall support VOI LUT application."
The row declares **T** alone, so a green migration discharges it completely.

An earlier M6 opening assessment recorded `VOX-R2D-007` as "partially discharged
pending verification at implementation", on the grounds that "the accepted
lookup-table composition largely covers" its shape. `ADR-0208` decision 1
required that judgement to be tested rather than inherited. It does not hold.

## The finding: the accepted table model is the modality stage, not this one

`VOXELIA-ALG-0004` describes itself as "the DICOM-derived table form of the
**modality** mapping". It differs from a VOI lookup in three substantive ways,
any one of which would be enough:

1. **Position.** `ALG-0004` maps a stored value to a real value whose output
   then *feeds* the window. A VOI lookup sits **where the window sits** — it is
   the tabular alternative to `VOXELIA-ALG-0002`, not an input to it.
2. **Output domain.** `ALG-0004` produces real values carrying an optional
   measurement unit. A VOI lookup produces **display** values with no unit and
   no physical meaning.
3. **Input domain.** `ALG-0004` indexes on a stored *integer*. A VOI lookup
   indexes on the modality stage's output, which is binary64 and may be
   fractional — so an index-derivation rule must be frozen, and there is none
   to inherit.

The earlier assessment was reasonable on the surface and wrong underneath. The
composition covers the modality LUT; `VOX-R2D-007` asks for the VOI LUT.

## Decision

1. **The numerical identity is separately frozen.** Accepted
   `VOXELIA-ALG-0042` defines `voi-lookup-mapping/binary64-v1`.
2. **This model is the tabular sibling of `ALG-0002`, and replaces it when a
   table is supplied.** It occupies the same pipeline position, takes the same
   input and produces the same eight-bit display output, so a caller chooses
   between a window and a table rather than composing both.
3. **Two jobs use two different accepted rounding rules, deliberately.** Index
   selection rounds **half away from zero**, the rule `ALG-0026` froze and
   `ALG-0037` already reused for choosing a colour-table entry. Output
   quantisation rounds **ties to even**, the rule `ALG-0002` froze for the very
   stage this replaces. Picking one rule for both jobs would have meant
   overruling an accepted rule in the other. A registered fixture pins a case
   where the two disagree.
4. **The inherited round-half-away quirk is registered, not corrected.** For the
   double immediately below one half, `floor(x + 0.5)` yields one rather than
   zero, because the sum is exactly representable as `1.0`. Correcting it here
   would create a second, divergent rounding rule in the project — a worse
   outcome than a known quirk that is written down and fixtured. It is
   observable only near zero.
5. **Out-of-range clamps at both ends, inheriting `ALG-0004`'s reasoning
   unchanged**, including the overflow argument: an overflowing difference lies
   beyond the representable range on the side opposite the origin's sign and
   clamps to that same end. Both signed-integer origin extremes are fixtured.
6. **An infinite input clamps; it is not a failure.** It compares beyond an end
   of the table and pins there, which is total and needs no branch. This matters
   because a non-finite input is genuinely reachable: a linear modality
   transform with a finite scale and a finite stored value can overflow to
   infinity.
7. **NaN is rejected typed.** It compares false against everything, so no clamp
   can decide it, and silently mapping it to an end would invent a display
   value for a value that has none.
8. **Table outputs are display values and are clamped, never normalised.** No
   measurement unit travels with them. An entry outside `0...255` saturates.
9. **The failure family is exactly two payload-free cases**, `emptyTable` and
   `valueNotRepresentable`. An empty table defines no output, which is the same
   admission `ALG-0004` already requires of its receiver.
10. **There is no cancellation checkpoint**, because one lookup is `O(1)`.
    The operation that applies this per sample owns its own cadence.
11. **Stored values are untouched.** This is a display-stage mapping, so
    `VOX-R2D-002`'s separation of stored from displayed values and
    `ADR-0208` decision 6 both hold without a special rule.
12. **Independent analytical evidence is registered now**: twenty-three
    fixtures, twenty-one mapped and two rejected, with two SHA-256 digests
    frozen in `ALG-0042`.

## Alternatives considered

### Treat `ALG-0004` as already discharging `VOX-R2D-007`

Rejected; see the finding. It is the modality stage, in a different position,
with a different output domain and a different input domain.

### Round the index with ties-to-even for consistency with `ALG-0002`

Rejected; see decision 3. Consistency with the neighbouring stage is the weaker
argument; consistency with the accepted rule for *this job* — table index
selection — is the stronger one, and `ALG-0037` already set that precedent.

### Truncate rather than round when deriving the index

Rejected. Truncation is a third rule the project has not accepted anywhere, and
it biases every fractional value towards the table's origin.

### Fix the just-below-half rounding quirk in this model

Rejected; see decision 4.

### Reject an infinite input alongside NaN

Rejected; see decision 6. The clamp already answers it, and a rejection would be
an error path with a perfectly good total answer available.

### Normalise table outputs into the display range

Rejected; see decision 8. The entries of a VOI LUT *are* display values.
Normalising them would rescale a table the source author already calibrated.

### Extend `LookupTableDescriptor` with a bit depth

Rejected for version one. This model's output range is eight bits because
`ALG-0002`'s is, and a bit-depth parameter with no second value to take is a
parameter with nothing to vary. Other output depths are a recorded exclusion.

## Consequences

The migration can implement one bounded, exact reference with no remaining
choice about the index rule, the clamp, the output rule or the failure family.
`VOX-R2D-007` becomes fully dischargeable, verification method included, because
it declares Test alone.

The deliberate limitations are a single table, no interpolation between entries,
no sequence selection, no presentation LUT stage, no sigmoid or other non-linear
VOI function, and eight-bit output only.

## Affected modules

Documentation and the independent Python oracle only in this increment.
Migration adds the reference to `VoxeliaExecution`, beside the window operation
whose position it shares. No dependency edge changes.

## Compatibility impact

None in this design-only increment. Nothing existing changes: the window model
is untouched and remains the default when no table is supplied.

## Security impact

No allocation beyond one output value; errors are payload-free and disclose no
values, table contents or indices.

## Performance and memory impact

`O(1)` per sample.

## Validation impact

The oracle registers:

```text
fixtureSHA256=a88c27632f2f73645243ca5dda7b365665a8e80f79c9877a50304664d48d34c7
outputSHA256=e8f03a49b1f9fdc024827f77ebbc489628f453acd11168de60ea7de3d35781f8
fixtures=23 mapped=21 rejected=2
```

Migration must reproduce all twenty-three fixtures bit-exactly, prove the index
rule where it disagrees with ties-to-even, prove the inherited just-below-half
behaviour rather than silently differing from it, prove both clamp ends and both
signed-integer origin extremes, prove that infinity clamps while NaN is
rejected, and prove the output quantisation at `0.5`, `1.5` and `2.5`.

## Migration

1. Add the VOI lookup reference to `VoxeliaExecution` with every fixture from
   `ALG-0042`.
2. `ADR-0208` increment (c) designs palette-colour presentation.

## Supersession

This record executes `ADR-0208` decision 2(b) and supersedes no accepted record.
It corrects, without editing, an earlier ledger assessment that treated the
accepted modality-table composition as covering the VOI stage.

## References

- [ADR-0065 - Window-level operation](ADR-0065-window-level-operation.md)
- [ADR-0069 - Lookup-table composition](ADR-0069-lookup-table-composition.md)
- [ADR-0208 - Colour and overlay arc](ADR-0208-colour-and-overlay-arc.md)
- [ADR-0209 - Display colour vocabulary](ADR-0209-display-colour-vocabulary.md)
- [VOXELIA-ALG-0002 - Window-level linear mapping](../../algorithms/VOXELIA-ALG-0002-window-level-linear.md)
- [VOXELIA-ALG-0004 - Lookup-table stored-to-real value mapping](../../algorithms/VOXELIA-ALG-0004-lookup-table-value-transform.md)
- [VOXELIA-ALG-0042 - VOI lookup display mapping](../../algorithms/VOXELIA-ALG-0042-voi-lookup-mapping.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

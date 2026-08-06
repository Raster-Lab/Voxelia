---
document_id: "ADR-0241"
title: "CT volume storage binding"
status: "Accepted"
date: "2026-08-06"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-DCM-003"
  - "VOX-SEC-001"
  - "VOX-VS1-004"
---

# ADR-0241 - CT volume storage binding

## Context

`ADR-0238` increment (b): bind the transferred volume bytes to the accepted
storage contract so a descriptor and a snapshot can be published together.

This is the arc's smallest increment, and `ADR-0238` predicted as much:
`ContiguousImageStorage(binding:bytes:)` already accepts exactly what
`CTVolumeByteBuffer` holds. The work is admission, not transformation — and the
one substantive decision is what to refuse.

## Decision

1. **An incomplete volume is refused.** This is the increment's real content.
   `ADR-0235` decision 7 added written-slice tracking precisely so that a volume
   missing a slice is a *fact* rather than a silence: the gap would read as zeros,
   which are plausible bytes and the wrong volume. A volume is complete or it is
   not published.
2. **The descriptor and the buffer are checked against each other, not assumed to
   agree.** They derive their byte counts independently — the binding from the
   descriptor's shape, scalar type and component count, the buffer from
   `VOXELIA-ALG-0050`'s layout — so comparing them is a genuine check rather than
   a restatement. A mismatch is refused with one case.
3. **The scalar type is compared as well as the byte count.** Two formats of the
   same width would agree on bytes and disagree on meaning; `uint16` and `int16`
   are exactly that pair, and they are the two `VOX-DCM-005` admits.
4. **The storage provider's own admission failure is not surfaced.** It is
   collapsed into one case, because its diagnostics name byte counts and this
   arc's failure families are payload-free throughout.
5. **`ContiguousImageStorage` is used rather than `BrickedImageStorage`.** The
   volume is already one contiguous allocation from the transfer, so bricking it
   would copy 449 MiB to gain a residency strategy nothing in this arc requests.
   Choosing the bricked provider is a decision for whoever needs it.

## Consequences

An ingested volume can now present both halves of what `ImageData` requires: a
descriptor from `ADR-0240` and a snapshot from here, with the agreement between
them checked.

What remains before publication is provenance and identity.

## Alternatives considered

### Allow an incomplete volume and let the caller decide

Rejected; see decision 1. It would make the written-slice tracking decorative.

### Trust the descriptor and buffer to agree, since both come from one layout

Rejected; see decision 2. They *should* agree, and the check costs one comparison
and catches every future path that builds them separately.

### Compare only the byte count

Rejected; see decision 3.

### Move the volume's bytes rather than copying into the provider

Not taken here. `ContiguousImageStorage` takes an `[UInt8]`, so a copy occurs at
the boundary. Avoiding it means either an ownership-transferring provider or an
`inout` handover, both of which change accepted storage API. `ADR-0235` measured
this class of copy at about 120 MiB/s, so it is a real cost — recorded, and left
to a record that changes storage rather than smuggled into a bridge.

## Affected modules

`VoxeliaImaging` gains `CTVolumeStorageBuilder` and its failure family, and now
imports `VoxeliaStorage`, which is already in its dependency chain. No accepted
type is modified and no module's declared dependencies change.

## Compatibility impact

Additive.

## Security impact

Positive: `VOX-SEC-001` is served by the byte count being checked against the
descriptor rather than trusted, so a wrong descriptor cannot bind a buffer of a
different size.

## Performance and memory impact

One copy of the volume's bytes into the provider, for the reason in the
alternatives. No other allocation.

## Validation impact

```text
swift build && swift test
swift test --filter CTVolumeStorageBuilder
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/build-docc.sh
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

A test reads the whole region back through the erased provider and compares it to
the transferred bytes, so the binding is verified by round trip rather than by
construction.

## Migration

1. This increment.
2. Provenance for an ingested volume — `ADR-0238` increment (d), and its largest.
3. Identity and publication, then end-to-end slice extraction on the real series.

## Supersession

This record supersedes nothing. It performs increment (b) of `ADR-0238`.

## References

- [ADR-0235 - Frame sample transfer](ADR-0235-frame-sample-transfer.md)
- [ADR-0238 - Published volume bridge arc](ADR-0238-published-volume-bridge-arc.md)
- [ADR-0240 - CT volume descriptor](ADR-0240-ct-volume-descriptor.md)
- [VOXELIA-ALG-0050 - CT volume sample layout](../../algorithms/VOXELIA-ALG-0050-volume-sample-layout.md)

---
document_id: "ADR-0146"
title: "Padded device window"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-R2D-009"
  - "VOX-MTL-004"
  - "VOX-ERR-001"
---

# ADR-0146 - Padded device window

## Context

Accepted `ADR-0113` delivered pixel-padding exclusion at the CPU
operation and advanced the window contract to 1.5.0, while the
device implementation kept its honest 1.4.0 claim because claiming a
rule it lacked would be false; the recorded debt named a padded
device path as its own increment. This record closes it. It was
authored and accepted on 2026-08-05 under the project owner's
recorded broadened autonomous delegation.

## Decision

1. **The shader family advances to 1.2.0** with the sentinel rule in
   every entry point: an enabled sentinel compares against the
   stored sample as integers — before any float conversion, so the
   exclusion itself is exact on the device even though the window
   map is approximate — and an excluded sample writes exactly zero.
   The manifest re-pins the new source digest.
2. **The kernel takes the sentinel typed.** `mapSamples` gains an
   explicit `Int32?` sentinel with absence stated at every call
   site — no permissive default — and the kernel reference advances
   to 1.2.0.
3. **The device operation claims contract 1.5.0** with
   implementation 1.2.0: it validates sentinel representability per
   scalar type exactly as the CPU operation and reuses its typed
   case, digests the identical parameter document including the
   padding entry, and the metal registrations and their pins advance
   to the closed contract gap — the claim-what-you-implement rule
   cutting both ways.
4. **Renderer wiring still passes no sentinel**, per the `ADR-0113`
   row reading: the adapter that supplies padding values is gated,
   and absence stays explicit at the call sites.

## Alternatives considered

Comparing the sentinel after float conversion was rejected: 32-bit
float cannot represent every 16-bit sentinel-adjacent value
distinctly and the exclusion would misfire; the integer compare is
exact. Keeping the device at 1.4.0 with a wrapper-side exclusion was
rejected: the kernel is the entire device numeric path and splitting
the rule across layers would misreport what ran.

## Consequences

The device window serves the full current contract; the recorded
contract gap is closed with differential evidence over all three
scalar types, labelled single-device as always.

## Affected modules

`VoxeliaMetal`.

## Compatibility impact

The kernel and device-operation signatures gain the explicit
sentinel parameter; absence is stated at every existing call site.

## Security impact

None.

## Performance and memory impact

One integer compare per sample when a sentinel is enabled; none when
absent.

## Validation impact

The kernel suite re-pins the new digest and adds the padded
differential against the CPU 1.5.0 operation across uint8, int16 and
uint16, asserting exact zeros at sentinel positions and the
established differential agreement elsewhere.

## Migration

Call sites add the explicit absent sentinel.

## Supersession

Closes the contract gap recorded by `ADR-0113`; no record is
superseded.

## References

- [ADR-0113 - Pixel padding exclusion](ADR-0113-pixel-padding-exclusion.md)
- [ADR-0093 - Sixteen-bit device window level](ADR-0093-sixteen-bit-device-window-level.md)

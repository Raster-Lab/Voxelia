---
document_id: "VOXELIA-ALG-0004"
title: "Lookup-table stored-to-real value mapping binary64-v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-04"
owner: "Voxelia Project"
---

# Lookup-table stored-to-real value mapping binary64-v1

## Purpose

This specification defines the versioned reference operation
`lookup-table-value-transform/binary64-v1` selected by accepted
[`ADR-0069`](../architecture/decisions/ADR-0069-lookup-table-composition.md).
It evaluates a validated lookup-table value transform — the
DICOM-derived table form of the modality mapping — from one stored
integer sample value to its real value, composing with downstream
value-domain models exactly as `VOXELIA-ALG-0003` composes the linear
form.

## Supported formats

Every integer stored sample type admitted by the consuming operation.
Table outputs are the descriptor's validated finite binary64 values; a
non-empty table is a consuming-operation admission requirement, since
an empty table defines no output.

## Model

For a stored integer sample value `x` and a table with
`firstMappedValue` `f` and `n >= 1` output values:

```text
index = clamp(x - f, 0, n - 1)
r     = values[index]
```

`x - f` is evaluated in 64-bit signed integer arithmetic. When that
subtraction overflows, the mathematical difference lies beyond the
representable range on the side opposite to `f`'s sign: with `f`
negative the difference exceeds the maximum and clamps to the last
entry, and with `f` positive it falls below the minimum and clamps to
the first entry. Clamping at both ends is the DICOM-derived
out-of-range rule: values below the first mapped value take the first
output, values beyond the table take the last output.

## Composition and units

The real value `r` feeds a downstream value-domain model — the
`VOXELIA-ALG-0002` window — unchanged, so that model's parameters are
expressed in the table's output domain. The descriptor's optional
output unit describes that domain and is never converted or
interpreted by this mapping.

## Determinism and failure classification

The mapping is a pure function of the stored value and the table:
repeated evaluation is bit-identical. Table values are validated
finite at construction; no branch of the model itself can fail, and an
empty table is a typed admission failure in the receiver.

## Conformance fixtures

Independently computed and composed with the `VOXELIA-ALG-0002`
window model: `uint8` stored samples `0...11` under the table
`firstMappedValue = 2`, `values = [-100, 0, 50.5, 200]`, windowed with
`c = 25`, `w = 300` in the table's output domain:
`[21, 21, 21, 107, 150, 255, 255, 255, 255, 255, 255, 255]` — the
first three samples clamp below the table, the fractional entry maps
to `150`, and the tail clamps to the last entry.

## References

- [ADR-0069 - Lookup-table composition](../architecture/decisions/ADR-0069-lookup-table-composition.md)
- [VOXELIA-ALG-0003 - Linear stored-to-real value mapping binary64-v1](VOXELIA-ALG-0003-linear-value-transform.md)

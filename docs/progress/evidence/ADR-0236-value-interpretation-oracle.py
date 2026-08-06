#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Independent oracle for VOXELIA-ALG-0051: CT stored-value interpretation.

Computed from the algorithm specification's prose alone. Two distinct kinds of
arithmetic appear and are kept apart deliberately:

  * stored-value decoding is EXACT integer work -- byte assembly, masking and
    sign extension. No rounding is possible.
  * the rescale is IEEE-754 binary64 in a frozen expression order with no fused
    multiply-add.

Python's int is unbounded, so the integer boundaries are checked explicitly
rather than inherited from the language.
"""

from __future__ import annotations

# --------------------------------------------------------------------------
# Stage 1: assemble the container from little-endian bytes.
# --------------------------------------------------------------------------


def container(byte_values: list[int], byte_count: int) -> int:
    """Little-endian assembly. DICOM explicit VR little endian is what the
    adapter records, and no other byte order is claimed."""
    assert len(byte_values) == byte_count
    result = 0
    for index in range(byte_count):
        result |= byte_values[index] << (8 * index)
    return result


# --------------------------------------------------------------------------
# Stage 2: extract the stored value, with sign extension.
# --------------------------------------------------------------------------


def stored_value(raw: int, bits_stored: int, bit_count: int, signed: bool) -> int:
    """The stored value occupying the low `bits_stored` bits of the container.

    Only the case `highBit == bitsStored - 1` is modelled -- the stored value in
    the low bits. Any other High Bit is REFUSED by the specification rather than
    guessed at, so it does not appear here.

    Sign extension is the boundary this fixture set exists for: a 12-bit signed
    value of 0x0FFF is -1, not 4095.
    """
    mask = (1 << bits_stored) - 1
    value = raw & mask
    if not signed:
        return value
    sign_bit = 1 << (bits_stored - 1)
    if value & sign_bit:
        return value - (1 << bits_stored)
    return value


# --------------------------------------------------------------------------
# Stage 3: padding, compared on the STORED value, before any rescale.
# --------------------------------------------------------------------------


def is_padding(value: int, padding: int | None) -> bool:
    return padding is not None and value == padding


# --------------------------------------------------------------------------
# Stage 4: the rescale, in frozen order, no FMA.
# --------------------------------------------------------------------------


def rescaled(value: int, slope: float, intercept: float) -> float:
    return (slope * float(value)) + intercept


def interpret(
    byte_values: list[int],
    byte_count: int,
    bits_stored: int,
    signed: bool,
    slope: float,
    intercept: float,
    padding: int | None,
):
    raw = container(byte_values, byte_count)
    value = stored_value(raw, bits_stored, byte_count * 8, signed)
    if is_padding(value, padding):
        return ("padding", value, None)
    return ("measured", value, rescaled(value, slope, intercept))


# --------------------------------------------------------------------------
# Fixtures.
# --------------------------------------------------------------------------

FIXTURES = [
    # (label, bytes, byteCount, bitsStored, signed, slope, intercept, padding)
    ("V1 signed 16-bit, air at -1000 HU", [0x18, 0xFC], 2, 16, True, 1.0, 0.0, None),
    ("V2 unsigned 16-bit with -1024 intercept", [0x18, 0x00], 2, 16, False, 1.0, -1024.0, None),
    ("V3 12-bit signed, 0x0FFF is -1 not 4095", [0xFF, 0x0F], 2, 12, True, 1.0, 0.0, None),
    ("V4 12-bit signed, 0x0800 is the most negative", [0x00, 0x08], 2, 12, True, 1.0, 0.0, None),
    ("V5 12-bit signed, 0x07FF is the most positive", [0xFF, 0x07], 2, 12, True, 1.0, 0.0, None),
    ("V6 12-bit UNsigned, 0x0FFF is 4095", [0xFF, 0x0F], 2, 12, False, 1.0, 0.0, None),
    ("V7 high bits above bitsStored are masked away", [0xFF, 0xFF], 2, 12, False, 1.0, 0.0, None),
    ("V8 non-unit slope", [0x64, 0x00], 2, 16, False, 2.5, -1024.0, None),
    ("V9 a padding value is excluded before rescale", [0x30, 0xF8], 2, 16, True, 1.0, -1024.0, -2000),
    ("V10 a value equal to padding only AFTER rescale is measured", [0x00, 0x00], 2, 16, True, 1.0, -2000.0, -2000),
    ("V11 zero slope collapses every value to the intercept", [0x64, 0x00], 2, 16, False, 0.0, -1024.0, None),
    ("V12 8-bit unsigned", [0x7F], 1, 8, False, 1.0, 0.0, None),
    ("V13 8-bit signed, 0xFF is -1", [0xFF], 1, 8, True, 1.0, 0.0, None),
    ("V14 a non-integral slope shows the rescale is binary64", [0x03, 0x00], 2, 16, False, 0.1, 0.0, None),
]


def show(value) -> str:
    if isinstance(value, float):
        return f"{value!r} ({value.hex()})"
    return str(value)


def main() -> None:
    print("VOXELIA-ALG-0051 oracle - CT stored-value interpretation")
    print("=" * 78)
    for label, byte_values, byte_count, bits_stored, signed, slope, intercept, padding in FIXTURES:
        kind, value, real = interpret(
            byte_values, byte_count, bits_stored, signed, slope, intercept, padding
        )
        print()
        print(label)
        print(
            "  bytes: "
            + " ".join(f"0x{b:02X}" for b in byte_values)
            + f"   bitsStored: {bits_stored}   signed: {signed}"
        )
        print(f"  slope: {show(slope)}   intercept: {show(intercept)}   padding: {padding}")
        print(f"  stored value: {value}")
        print(f"  result: {kind}" + (f"   value: {show(real)}" if real is not None else ""))


if __name__ == "__main__":
    main()

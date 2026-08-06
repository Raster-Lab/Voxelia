#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Exhaustive verification for ADR-0239: stored-sample normalisation.

This is not a fixture oracle. The property under test is small enough to check
COMPLETELY, so it is checked completely: every 8-bit and 16-bit container value,
every Bits Stored width from 1 to the container width, and both signedness
choices. 2,101,248 cases, no sampling.

The property: re-encoding a stored value as a full-width container and then
reading it at full width must yield the same stored value as reading the original
container at its narrower Bits Stored. If that holds, a published descriptor may
declare `validBitCount: nil` -- which the accepted operations accept -- without
misreading a narrowed signed sample.
"""

from __future__ import annotations


def stored_value(raw: int, bits: int, signed: bool) -> int:
    """VOXELIA-ALG-0051 stage 2: mask to `bits`, then sign extend."""
    mask = (1 << bits) - 1
    value = raw & mask
    if signed and (value & (1 << (bits - 1))):
        value -= 1 << bits
    return value


def normalised(raw: int, bits: int, container_bits: int, signed: bool) -> int:
    """Re-encode the stored value as a full-width container.

    Two's complement truncation to the container width. For an unsigned narrowed
    format this is a mask; for a signed one it is the sign extension made
    permanent in the bytes.
    """
    return stored_value(raw, bits, signed) & ((1 << container_bits) - 1)


def main() -> None:
    print("ADR-0239 exhaustive verification - stored-sample normalisation")
    print("=" * 78)

    failures: list[tuple] = []
    total = 0
    identities = 0
    changed = 0

    for container_bits in (8, 16):
        for bits in range(1, container_bits + 1):
            for signed in (False, True):
                for raw in range(1 << container_bits):
                    total += 1
                    expected = stored_value(raw, bits, signed)
                    actual = stored_value(
                        normalised(raw, bits, container_bits, signed),
                        container_bits,
                        signed,
                    )
                    if expected != actual:
                        failures.append(
                            (container_bits, bits, signed, raw, expected, actual)
                        )
                    if normalised(raw, bits, container_bits, signed) == raw:
                        identities += 1
                    else:
                        changed += 1

    print(f"cases checked:            {total:,}")
    print(f"property failures:        {len(failures)}")
    print(f"containers left unchanged {identities:,}")
    print(f"containers rewritten:     {changed:,}")
    for failure in failures[:8]:
        print("   FAILURE", failure)

    # The identity case matters for cost: when Bits Stored equals the container
    # width, normalisation must be a no-op, so a full-width series pays nothing.
    print()
    print("Identity check at full width (normalisation must be a no-op):")
    for container_bits in (8, 16):
        for signed in (False, True):
            noop = all(
                normalised(raw, container_bits, container_bits, signed) == raw
                for raw in range(1 << container_bits)
            )
            print(
                f"  container {container_bits} bits, signed={signed}: "
                + ("no-op for every value" if noop else "NOT a no-op")
            )

    # Worked examples, for the record's prose.
    print()
    print("Worked examples:")
    for raw, bits, signed, label in [
        (0x0FFF, 12, True, "12-bit signed 0x0FFF is -1"),
        (0x0FFF, 12, False, "12-bit unsigned 0x0FFF is 4095"),
        (0xFFFF, 12, False, "junk high bits are discarded"),
        (0x0800, 12, True, "12-bit signed most negative"),
        (0x0001, 1, True, "1-bit signed 1 is -1"),
    ]:
        value = stored_value(raw, bits, signed)
        container = normalised(raw, bits, 16, signed)
        print(
            f"  {label}: raw 0x{raw:04X} -> stored {value} -> container 0x{container:04X}"
        )


if __name__ == "__main__":
    main()

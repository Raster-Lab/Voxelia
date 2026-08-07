#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0079 deterministic-sequence/v1.

SplitMix64 over exact 64-bit integer arithmetic: every value below is
the exact word the Swift implementation must reproduce, and the unit
doubles are exact binary64 values by construction (53 explicit bits).
"""

MASK = (1 << 64) - 1


class SplitMix64:
    def __init__(self, seed):
        self.state = seed & MASK

    def next_word(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (z ^ (z >> 31)) & MASK

    def next_unit(self):
        return (self.next_word() >> 11) * (2.0**-53)


s = SplitMix64(0)
print("seed 0 words:", [hex(s.next_word()) for _ in range(4)])
s = SplitMix64(0xDEADBEEF)
print("seed deadbeef words:", [hex(s.next_word()) for _ in range(4)])
s = SplitMix64(42)
units = [s.next_unit() for _ in range(3)]
print("seed 42 units:", units)
print("  hex =", [u.hex() for u in units])

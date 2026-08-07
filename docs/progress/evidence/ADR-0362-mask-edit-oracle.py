#!/usr/bin/env python3
"""Independent oracle for VOXELIA-ALG-0066 mask editing.

The three closed verbs over aligned 0/1 masks: union is OR, subtract is
base AND NOT edit, intersect is AND. Pure boolean; exact.
"""

base = [1, 1, 0, 0]
edit = [1, 0, 1, 0]
print("union:", [a | b for a, b in zip(base, edit)])
print("subtract:", [a & (1 - b) for a, b in zip(base, edit)])
print("intersect:", [a & b for a, b in zip(base, edit)])

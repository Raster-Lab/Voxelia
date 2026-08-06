---
document_id: "VOXELIA-ALG-0041"
title: "GPU-produced geometry byte representation v1"
version: "1.0"
status: "Accepted"
document_type: "Algorithm Specification"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-06"
owner: "Voxelia Project"
---

# GPU-produced geometry byte representation v1

## Purpose

This specification defines `gpu-geometry-representation/v1`, the deterministic
byte layout and decode selected by accepted
[`ADR-0207`](../architecture/decisions/ADR-0207-gpu-geometry-representation-assessment.md).
It converts an owned byte payload — the shape a Metal compute kernel writes into
a shared buffer — into the canonical `TriangleMesh` value, without any GPU type
entering the geometry model.

## The layout is the contract, not the buffer

A producer conforms by emitting these bytes. Nothing in this specification names
Metal, a device, a buffer or a command queue, and the decode is a pure function
from bytes to a canonical value. That is what keeps a GPU buffer from becoming
canonical: the buffer is a transport, the layout is the contract, and the
canonical mesh is the only authority.

## The frozen layout

```text
positions: vertexCount x 3 x binary32, little-endian, tightly packed
           (12 bytes per vertex, no padding, no interleaved attributes)
indices:   triangleCount x 3 x UInt32, little-endian
           (12 bytes per triangle)
```

Positions are **packed**, not aligned. MSL's `float3` occupies sixteen bytes
with four bytes of padding; `packed_float3` occupies twelve and is already this
layout. A producer using the aligned type must pack before writing. This is the
single most likely way for a conforming-looking producer to be wrong, so it is
stated rather than implied.

Little-endian is load-bearing and registered: the four bytes `00 00 80 3F` are
exactly `1.0`, and the same bytes read big-endian are `4.6006e-41`.

## Counts arrive out of band

`vertexCount` and `triangleCount` are supplied by the caller, not read from a
header inside the payload. A length-bearing header would let the payload decide
its own allocation, and the caller already knows what it dispatched. The byte
counts must then match **exactly**:

```text
positionByteCount == vertexCount * 12
indexByteCount    == triangleCount * 12
```

Both products are taken against the host signed-integer ceiling before use, so a
count that could not address its own payload is rejected before any allocation.

## The coordinate space is never carried in the payload

A buffer cannot declare a coordinate space, and letting bytes name one would be
exactly the relabelling `ADR-0183` decision 4 forbids. The caller supplies the
`CoordinateSpaceDescriptor`, as it does for every other geometry it constructs.

## Widening is exact, and no precision is invented

Every finite binary32 is exactly representable in binary64, so widening is
lossless and introduces no rounding. The honest consequence is registered: a
producer writing decimal `0.1` as a binary32 yields `0.10000000149011612`, and
that is the value the decode publishes. It is not `0.1`, and the decode does not
pretend the geometry has more precision than the producer gave it.

The registered `binary32-extremes` fixture pins the least subnormal
(`0x1p-149`), the least normal (`0x1p-126`) and the greatest finite value
(`0x1.fffffep+127`). The `negative-zero` fixture pins that a negative zero
survives as a negative zero, distinguishable only by its bit pattern.

## The decode carries no geometric rule

Its own failures are exactly four, all of them about bytes:

```text
negativeCount
countNotRepresentable
positionByteCountMismatch
indexByteCountMismatch
```

Every **geometric** rejection — a non-finite position, an out-of-range index —
belongs to the canonical value's own admission and is not restated here. That
separation is the architectural claim made operational: the canonical gate is
what admits, so the bytes are never authoritative.

Two canonical cases are moreover **unreachable** through this path, and
deliberately so. `incompleteVertex` and `incompleteTriangle` cannot arise
because the byte-count check is strictly stronger: a payload whose length
matches its count exactly can never be a partial vertex or a partial triangle.

An empty payload is an empty mesh rather than a failure, and vertices without
triangles decode as well — the layout does not require topology.

## Determinism and conformance

The decode is stateless, allocation-bounded by the checked counts, and depends
only on its inputs. Any producer emitting this layout is representable; a
producer that pads, interleaves, reorders bytes or embeds counts does not
conform and must not be adapted silently.

## Conformance fixtures

The independent standard-library oracle is
[`ADR-0207-gpu-geometry-representation-oracle.py`](../progress/evidence/ADR-0207-gpu-geometry-representation-oracle.py).
It records eighteen fixtures: a whole triangle; the byte-order proof; exact
binary32 widening; the binary32 extremes; negative zero; an empty payload;
vertices without triangles; two triangles sharing an edge; infinite and NaN
positions; an out-of-range index; short and long position payloads; short and
long index payloads; both negative counts; and a count too large to address its
own payload.

The registered output is:

```text
fixtureSHA256=055eddda7b501f397741194f7ca2dbc038e0191c87c9e8634f298561d4ae079c
valueSHA256=fc52599c92900bc37cbea6dc206f481a4ee419347628634a67cf5da476ab04c4
fixtures=18 decoded=8 rejected=10
layout=packed-binary32-le counts=out-of-band space=caller-supplied
widening=exact geometricAdmission=canonical
```

## Complexity and exclusions

`O(vertexCount + triangleCount)`.

Vertex attributes beyond position, index widths other than `UInt32`, a
CPU-to-GPU encode, strided or interleaved layouts, geometry-producing compute
kernels themselves, and any published artefact remain separate contracts.

## References

- [ADR-0183 - Geometry arc](../architecture/decisions/ADR-0183-geometry-arc.md)
- [ADR-0186 - Governed Metal buffer transfer](../architecture/decisions/ADR-0186-governed-metal-buffer-transfer.md)
- [ADR-0196 - Geometry acceleration architecture assessment](../architecture/decisions/ADR-0196-geometry-acceleration-architecture-assessment.md)
- [ADR-0197 - Surface rendering arc](../architecture/decisions/ADR-0197-surface-rendering-arc.md)
- [ADR-0207 - GPU-produced geometry representability assessment](../architecture/decisions/ADR-0207-gpu-geometry-representation-assessment.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)

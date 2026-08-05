---
document_id: "ADR-0152"
title: "Brick cache vocabulary"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-BRK-008"
  - "VOX-CCH-007"
  - "VOX-CCH-009"
  - "VOX-ERR-001"
---

# ADR-0152 - Brick cache vocabulary

## Context

Accepted `ADR-0151` froze the brick cache design; this record
implements its values — the eviction consideration with the one
ordering authority, the cache format version and the closed event
set — ahead of the instrumented cache actor. It was authored and
accepted on 2026-08-05 under the project owner's recorded broadened
autonomous delegation.

## Decision

1. **`BrickEvictionConsideration` joins `VoxeliaStorage`** with the
   designed inputs: the last-access generation ordinal, the
   caller-measured reconstruction cost, the byte count and the
   insertion ordinal as unsigned values — negativity structurally
   unrepresentable — the visibility flag, and the active-reference
   count typed nonnegative. `isEvictable` is false exactly when
   active references exist.
2. **`evictsBefore(_:)` is the one ordering authority**, defined for
   evictable entries under the frozen lexicographic order: invisible
   before visible, then oldest access generation, then cheapest
   reconstruction, then largest byte count, then the insertion
   ordinal — the deterministic tie-break the design fixed. The
   never-evict rule is the future cache actor's filter; the
   comparator documents its evictable-only domain.
3. **`CacheFormatID` and `CacheFormatVersion`** carry a validated
   format identifier under the accepted string-identifier protocol
   beside a semantic version, binding future persistence per the
   design.
4. **`BrickCacheEvent` is the closed five-case set** — hit, miss,
   eviction, decode and recomputation — with payloads of brick
   identities, byte counts and caller-measured cost units only, and
   `BrickCacheEventSink` is the explicit optional host-owned closure
   type, absent by default at every future call site.

## Alternatives considered

Recorded in the design; nothing new arose during implementation.

## Consequences

The instrumented cache actor has its values and its one ordering
authority.

## Affected modules

`VoxeliaStorage`.

## Compatibility impact

Additive only.

## Security impact

The event payload shapes enforce the recorded exclusion rules
structurally — no field can carry image bytes, metadata values or
digests.

## Performance and memory impact

Constant-time comparisons; no allocation.

## Validation impact

New suite `BrickCacheVocabularyTests` covers every lexicographic
rank including the tie-break, the never-evictable rule, the typed
negative-reference rejection and the format and event values.

## Migration

None; the surface is new.

## Supersession

Implements the value half of accepted `ADR-0151`; no record is
superseded.

## References

- [ADR-0151 - Brick cache design](ADR-0151-brick-cache-design.md)

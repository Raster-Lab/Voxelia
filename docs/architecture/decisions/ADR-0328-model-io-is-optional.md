---
document_id: "ADR-0328"
title: "Model I/O is optional"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-ADP-003"
---

# ADR-0328 - Model I/O is optional

## Context

`VOX-ADP-003` requires that "Model I/O integration shall be optional and shall be used for
asset interchange and mesh preparation rather than as the canonical scientific data model".
P0, **`I,T`**, milestone M6, from `ADR-0319`'s queue.

The row has two clauses and they pull in different directions: Model I/O is **permitted** for
two named purposes and **forbidden** as the canonical model. A gate that only did one of those
would answer half the row.

## The measurement

**Zero occurrences** of `ModelIO`, `MDLAsset` or `MDLMesh` across `Sources/`, `Tests/` and the
manifest. It is optional in the strongest available sense: absent.

`check_prohibited_imports.py` forbade it in **nine of eleven** targets. The two exceptions:

| Target | Forbidden | Reading |
|---|---|---|
| `VoxeliaCPU` | no | **Correct.** It computes surface extraction, facet area and vertex normals — *mesh preparation*, which the row explicitly permits. |
| `VoxeliaInteraction` | no | **An omission.** Interaction state and commands are neither asset interchange nor mesh preparation. |

Every target holding the canonical model — `VoxeliaCore`, `VoxeliaSpatial`, `VoxeliaStorage`,
`VoxeliaGeometry` — already forbade it, so the row's second clause was protected. The first
clause was under-enforced in exactly one place.

## Decision

1. **`ModelIO` is added to `VoxeliaInteraction`'s prohibition.** That target has no
   asset-interchange or mesh-preparation role, so the exception had no rationale behind it.
2. **`VoxeliaCPU` stays permitted, deliberately and on the record.** It is where mesh
   preparation lives, and the row names mesh preparation as a permitted use. Forbidding it
   would enforce the row's second clause by breaking its first — the same inversion `ADR-0311`
   avoided for Metal Performance Shaders.
3. **`VOX-ADP-003` is claimed and its `I` and `T` discharged** — the `I` by the prohibition
   set, the `T` by the two-directional proof below.

## The gate is proven in both directions

```text
import ModelIO in VoxeliaInteraction -> failed, named by path   (exit 1)
import ModelIO in VoxeliaCPU         -> passed                  (exit 0)
```

The second is the load-bearing one. A gate failing on both would have made Model I/O
unavailable for the purposes the row permits, which is a stricter rule than the requirement and
therefore a different one.

## Alternatives considered

### Forbid Model I/O everywhere

Rejected; see decision 2. The row permits it for two named purposes, and enforcing only the
prohibition half would make the permission unusable.

### Leave `VoxeliaInteraction` unforbidden

Rejected. Nine of eleven targets forbade it and the two exceptions were not distinguished by
anything; one had a reason and one did not, and that is exactly the shape `ADR-0320` found in
the required-file list.

### Add a positive requirement that Model I/O be used

Rejected as inverting the row. It says integration shall be **optional**; requiring its use
would contradict the first word of the requirement.

## Consequences

`VOX-ADP-003` is claimed, and the one target whose exemption had no rationale is closed while
the one that has a rationale keeps it, recorded.

**3 rows remain unclaimed** under `ADR-0319`'s criterion, all M6 and all `T,D`:
`VOX-BRK-009`, `VOX-DVR-013` and `VOX-PER-004`. Each carries a Demonstration, so none can be
fully discharged without the owner.

## Affected modules

None. One gate entry. No source file changed.

## Compatibility impact

None. No target imports Model I/O today.

## Security impact

None.

## Performance and memory impact

None.

## Validation impact

```text
python3 Tools/Scripts/check_prohibited_imports.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1238 tests in 219 suites pass, unchanged — this increment adds no Swift.

## Migration

1. This record and one prohibition entry.
2. **Next**: the three remaining M6 rows, each of which needs an owner Demonstration.
3. **Owner**: unchanged.

## Supersession

This record supersedes nothing. It **completes** a prohibition that covered nine targets of
eleven, and records why the tenth stays open.

## References

- [ADR-0311 - Metal performance shaders boundary](ADR-0311-metal-performance-shaders-boundary.md)
- [ADR-0319 - Rederive the unclaimed queue](ADR-0319-rederive-the-unclaimed-queue.md)
- [ADR-0320 - Repository baseline rows](ADR-0320-repository-baseline-rows.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

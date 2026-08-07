---
document_id: "ADR-0183"
title: "Geometry extraction arc"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-GEO-004"
  - "VOX-GEO-006"
  - "VOX-GEO-007"
  - "VOX-GEO-008"
  - "VOX-GEO-009"
  - "VOX-GEO-010"
  - "VOX-GEO-011"
---

# ADR-0183 - Geometry extraction arc

## Context

The M6 opening assessment queues the geometry arc after the now-drained
actionable direct-volume-rendering arc. The requirements call for scalar and
label surface extraction, a validated marching-cubes-class reference,
deterministic normals, explicit coordinate space and provenance, authoritative
measurement and an acceleration-neutral architecture. The existing
`VoxeliaGeometry` surface deliberately stops at the accepted geometry,
attribute, primitive and index vocabularies; it has no canonical mesh
aggregate, extraction operation or numeric model to which an implementation
can conform.

This record opens the arc with its decomposition and binding rules only, under
the established assess-then-design-then-implement discipline. It does not
select a case table, ambiguity rule, normal formula, mesh storage layout or
public extraction API. Each of those choices requires a separately frozen
contract and independent fixtures. It was authored and accepted on 2026-08-05
under the project owner's instruction to continue the autonomous work and push
the resulting verified increment.

## Decision

1. **Extracted geometry is authoritative derived scientific data.** Its
   positions and physical calculations use `Double`; its coordinate space is
   explicit; its provenance binds the exact source, operation, parameters and
   implementation; and its immutable published value is independent of Metal,
   RealityKit, Model I/O and physical buffer residency. Rasterised presentation
   output is never an input to geometry measurement, discharging the arc-wide
   meaning of `VOX-GEO-010` before any renderer is allowed to consume a mesh.
2. **The arc advances in dependency order, design-first at every numeric or
   lifetime boundary:**
   - a canonical validated triangle-mesh value, including position and
     attribute domains, checked index topology, explicit coordinate space and
     immutable ownership;
   - a scalar-surface extraction specification selecting the exact
     marching-cubes-class method, sample and equality conventions, ambiguous
     case resolution, boundary treatment, vertex/topology order, precision,
     limits and golden fixtures;
   - the CPU reference extraction over the accepted image-read boundary, with
     one atomic publication of mesh, identity and matching provenance;
   - labelled-surface extraction, reusing the canonical mesh and publication
     boundaries but freezing label membership and adjacency separately rather
     than pretending they are scalar interpolation;
   - deterministic reference normal generation with its own orientation,
     degeneracy and normalisation rules;
   - authoritative mesh measurement and the operation/registry evidence needed
     by downstream consumers; and
   - backend-specific acceleration adapters derived from the canonical mesh,
     never embedded in its identity or treated as authoritative geometry.
3. **Topology is validated before publication.** Every referenced index must be
   within the published vertex domain; triangle topology must be complete;
   attribute cardinality must match its declared interpolation domain; all
   counts, products and byte requirements are overflow-checked before
   allocation. A renderer or adapter may not discover malformed canonical
   topology for the first time.
4. **Coordinate-space and provenance changes are explicit.** Extraction emits
   positions in the source image geometry's declared coordinate space. Any
   later transform publishes a distinct mesh and records the source and target
   spaces rather than relabelling existing coordinates. Every operation
   preserves the source relationship through the accepted identity and
   provenance chain.
5. **The reference is the validation oracle, not an optimisation sketch.** The
   extraction specification must include independently generated analytic or
   enumerated fixtures for topology, coordinates and ambiguous cases;
   deterministic repetition; scalar and labelled edge cases; malformed-input,
   cancellation, overflow and resource-limit tests; and differential checks
   for every accelerated implementation. No optimisation may change the
   canonical reference result silently.
6. **Surface rendering follows the canonical mesh and extraction contracts.**
   `VOX-SUR-*` work becomes assessable only after a valid mesh can be published;
   it is not folded into this arc. Colour/overlay work remains the separate M6
   queue item recorded by the opening assessment.

## Alternatives considered

Implementing a conventional 256-case marching-cubes table immediately was
rejected: the governing documents do not settle ambiguous faces, equality at
the isovalue, boundary cells, vertex deduplication or output order, and each
choice affects reproducible topology. Selecting marching tetrahedra in this arc
was also rejected: it may satisfy the marching-cubes-class requirement, but its
diagonal convention and topology still need an explicit numeric specification
and fixtures. Publishing a GPU-native mesh was rejected because it would make
one residency representation canonical and violate `VOX-GEO-011` and the
approved package boundary.

## Consequences

The geometry queue now has an ordered, reviewable path whose first executable
increment is the canonical triangle-mesh design. The arc-wide authority,
coordinate, provenance, validation and acceleration rules bind every following
record without guessing the unresolved numeric model.

## Affected modules

Documentation only in this increment. Later increments will primarily affect
`VoxeliaGeometry` and `VoxeliaCPU`, with operation publication composing the
accepted Core, Storage and Execution boundaries and optional acceleration in
backend modules.

## Compatibility impact

None in this increment. Later public values are additive before 1.0 and require
their own compatibility assessment.

## Security impact

The arc requires payload-free typed diagnostics and checked admission for
hostile counts and indices; no source is added here.

## Performance and memory impact

None in this increment. The mesh and extraction designs must establish checked
resource ceilings, bounded intermediate storage and cancellation cadence before
implementation. Acceleration remains derived and non-authoritative.

## Validation impact

This documentation increment requires front-matter, decision-register,
requirement-reference, manifest and release-integrity validation. Each
implementing increment carries the focused numerical, topology, concurrency,
memory and differential obligations listed above.

## Migration

None; the canonical triangle-mesh design follows as a separate increment.

## Supersession

Opens the M6 geometry extraction arc from the accepted M6 assessment; no record
is superseded.

## References

- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [ADR-0040 - Normalized logical sample and representation projection boundary](ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md)
- [ADR-0058 - Provenance record aggregate](ADR-0058-provenance-record-aggregate.md)
- [ADR-0063 - Image data aggregate](ADR-0063-image-data-aggregate.md)
- [ADR-0143 - Area and volume measurement design](ADR-0143-area-volume-measurement-design.md)
- [ADR-0165 - Volume rendering arc](ADR-0165-volume-rendering-arc.md)

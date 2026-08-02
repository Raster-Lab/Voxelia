---
document_id: "ADR-0022"
title: "Coordinate convention public shape"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ARC-002"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-SPA-001"
  - "VOX-SPA-005"
  - "VOX-SPA-006"
  - "VOX-SPA-007"
---

# ADR-0022 - Coordinate convention public shape

## Context

The Master Technical Architecture section 10.2 and Core Data Model
Specification section 21.3 define incompatible public
`CoordinateConvention` enums.

The architecture defines right-handed Cartesian, DICOM patient LPS,
neuroimaging RAS and `custom(name:)`. The detailed data-model specification
adds left-handed Cartesian and image-display conventions, and changes the
extension case to `custom(namespace:name:)`. Both definitions require
`Sendable`, `Hashable` and `Codable`.

The requirements demand explicit coordinate spaces and convention conversion,
including DICOM LPS and application-defined spaces. Validation must detect
accidental LPS/RAS and image/display reversal. The conflict therefore cannot be
hidden behind undocumented flips or an unqualified custom string.

This proposal selects one enum shape and its type-level encoding for review.
Its Proposed status does not authorize implementation or resolve the separate
`CoordinateSpaceDescriptor` unit policy.

## Decision

If this ADR is accepted, `VoxeliaSpatial` will own this public vocabulary:

```swift
public enum CoordinateConvention: Sendable, Hashable, Codable {
    case cartesianRightHanded
    case cartesianLeftHanded
    case dicomPatientLPS
    case neuroimagingRAS
    case imageDisplay
    case custom(namespace: String, name: String)
}
```

Built-in cases will encode as the exact strings `cartesianRightHanded`,
`cartesianLeftHanded`, `dicomPatientLPS`, `neuroimagingRAS` and
`imageDisplay`. The custom case will encode as:

```json
{"custom":{"namespace":"example.namespace","name":"example-name"}}
```

Decoding will reject unknown tags, wrong value shapes, missing fields and
distinct extra fields. Raw duplicate-key rejection remains the responsibility
of the canonical-JSON byte-ingress layer because Swift `Decoder` may collapse
duplicate keys before a type sees them.

Custom namespace and name values are opaque, case-sensitive declaration
vocabulary. Until a registry defines equivalence, accepted spelling will be
preserved and equality and hashing will compare exact UTF-8 bytes. This ADR
does not invent a nonblank rule that a directly constructible enum case cannot
enforce.

A convention identifies an axis-orientation convention, not a coordinate-space
instance, unit, transform or external frame. `CoordinateSpaceID`,
`MeasurementUnit` and `ExternalFrameReference` remain separate values.
Convention conversion always requires an explicit transform.

The built-in handedness implications are:

- right-handed: `cartesianRightHanded`, `dicomPatientLPS` and
  `neuroimagingRAS`;
- left-handed: `cartesianLeftHanded`; and
- unresolved by the convention alone: `imageDisplay` and `custom`.

`CoordinateHandedness.unspecified` is not a contradiction, but an operation
that requires resolved handedness must reject it explicitly. No handedness or
unit will be inferred for `imageDisplay` or `custom`.

Acceptance will require a controlled correction to Master Technical
Architecture section 10.2. No implementation may rely on this proposal while
its status remains Proposed.

## Alternatives considered

### Keep the four-case architecture enum

This is the smallest surface. It is not recommended because left-handed
Cartesian and image-display conventions would become unqualified custom names,
and `custom(name:)` cannot avoid namespace collisions.

### Adopt the detailed six-case enum

This is the proposed choice. It retains every architecture case, makes the two
additional specified conventions explicit and uses a namespaced extension point
consistent with other Voxelia taxonomies.

### Add a validated custom payload struct

A separate `CustomCoordinateConvention` could reject blank fields by
construction. It is not recommended for M1 because neither governing
definition contains that type, and it would create a third public shape and a
new error contract.

### Remove handedness-specific convention cases

Handedness could live only on `CoordinateSpaceDescriptor`. This is not
recommended because it diverges from both governing definitions and removes
stable built-in orientation vocabulary without resolving conversion policy.

### Replace the enum with a registry-backed value

An open registry would improve extension evolution but discard exhaustive
built-in cases and introduce identity and registry lifecycle decisions outside
M1 scope.

## Consequences

- DICOM LPS, RAS, left-handed Cartesian and image-display meanings are explicit
  and cannot be silently collapsed into generic names.
- Namespaced custom values avoid collisions while remaining declaration-only.
- Type-level Codable has a stable explicit tag shape, but this alone does not
  satisfy all canonical-JSON or digest requirements.
- Future built-ins can initially use namespaced custom values; adding enum cases
  remains a source-compatibility decision.
- The architecture document requires correction after acceptance.
- `CoordinateSpaceDescriptor` remains blocked until ordinary-physical,
  `imageDisplay` and custom-unit validity rules are approved.

## Affected modules

If accepted, this decision affects `VoxeliaSpatial` as owner and implementation
site of `CoordinateConvention`. Existing downstream modules are affected only
as consumers through current dependency edges; no dependency edge or other
module ownership changes. This proposal does not authorize the blocked
`CoordinateSpaceDescriptor`.

## Compatibility impact

No public `CoordinateConvention` implementation exists, so accepting this
proposal would not migrate a released symbol. The chosen wire tags will become
a compatibility contract once implemented and must not be changed casually.

## Security impact

Custom strings remain untrusted input and must not be interpreted as a unit,
frame UID or transform. External frame identity must use
`ExternalFrameReference`; adapters remain responsible for validating their own
namespace syntax and privacy policy.

## Performance and memory impact

Built-ins carry no payload. Custom values store two strings and require exact
UTF-8 comparison and hashing. No registry lookup, coordinate conversion or
allocation beyond value storage is introduced by the declaration.

## Validation impact

After acceptance and implementation, focused evidence must cover:

- every built-in case and exact string tag;
- structured custom round trips and exact UTF-8 identity;
- rejection of unknown, malformed, missing and distinct extra fields;
- the complete built-in handedness contradiction matrix;
- explicit LPS/RAS and image/display conversion paths; and
- a static dependency check confirming ownership in `VoxeliaSpatial`.

Descriptor unit-policy tests and DICOM adapter geometry tests remain separate
follow-on evidence and are not claimed by the enum slice.

## Migration

After acceptance:

1. correct Master Technical Architecture section 10.2;
2. implement the enum and explicit type-level encoding in `VoxeliaSpatial`;
3. add focused identity, Codable and malformed-input tests;
4. approve the remaining `CoordinateSpaceDescriptor` unit policy; and
5. update traceability and release-integrity evidence.

No migration step may begin while this ADR remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. If accepted, it resolves the cited coordinate-convention conflict through
the controlled architecture correction in the Migration section without
replacing either governing document. While Proposed, it has no supersession
effect.

## References

- [Voxelia Master Technical Architecture v0.1.1, sections 2.3 and 10.2](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 2, 21 and 55](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, sections 6.5 and 6.8](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1, section 25.4](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1, spatial and DICOM geometry sections](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

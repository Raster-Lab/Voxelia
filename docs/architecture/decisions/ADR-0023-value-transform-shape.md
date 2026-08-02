---
document_id: "ADR-0023"
title: "Value transform public shape"
status: "Proposed"
date: "2026-08-02"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-ARC-003"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-DAT-015"
  - "VOX-IMG-002"
  - "VOX-ERR-001"
  - "VOX-DCM-006"
  - "VOX-VS1-006"
---

# ADR-0023 - Value transform public shape

## Context

The Master Technical Architecture section 9.9 and Core Data Model
Specification section 18 define incompatible `ValueTransform` shapes.

Both documents distinguish stored decoded values from authoritative values and
presentation values. Both include identity, linear, lookup-table and composed
transforms. The detailed specification additionally includes
`piecewiseLinear(PiecewiseLinearDescriptor)`, changes composition storage from
`[ValueTransform]` to `ContiguousArray<ValueTransform>`, requires first-to-last
application, and requires finite linear and table parameters.

`PiecewiseLinearDescriptor` is referenced but never defined. The governing
documents do not specify its knots, ordering, duplicate-input behavior,
continuity, endpoint inclusion, extrapolation, units, identity or wire format.
No baseline requirement specifically mandates piecewise-linear support.

Directly constructible enum payloads also cannot enforce the required finite
linear parameters or nonempty composition invariant. This proposal selects a
validated declaration model for review while leaving transform execution and
undefined piecewise behavior outside the decision. Its Proposed status does not
authorize implementation.

## Decision

If this ADR is accepted, `VoxeliaCore` will own these public value types:

```swift
public struct LinearValueTransformDescriptor:
    Sendable,
    Hashable,
    Codable
{
    public let scale: Double
    public let offset: Double

    public init(scale: Double, offset: Double) throws
}

public struct ValueTransformComposition:
    Sendable,
    Hashable,
    Codable
{
    public let transforms: ContiguousArray<ValueTransform>

    public init<Transforms: Collection>(transforms: Transforms) throws
    where Transforms.Element == ValueTransform
}

public enum ValueTransform: Sendable, Hashable, Codable {
    case identity
    case linear(LinearValueTransformDescriptor)
    case lookupTable(LookupTableDescriptor)
    case composed(ValueTransformComposition)
}
```

`LinearValueTransformDescriptor` will use a throwing initializer that rejects
non-finite scale or offset with `DataModelError.invalidValueTransform`. Zero
scale is valid because neither governing source requires invertibility. Signed
zero will canonicalize to positive zero so equality, hashing and encoding share
one representation.

`ValueTransformComposition` will accept a generic collection, materialize one
immutable `ContiguousArray`, preserve first-to-last order, and reject an empty
collection with `DataModelError.invalidValueTransform`. It will not flatten
nested compositions, remove identity members or collapse a one-element
composition without a separately approved canonicalization rule.

Type-level Codable will use these explicit tags and payload fields:

```json
"identity"
{"linear":{"scale":2.0,"offset":-1024.0}}
{"lookupTable":{"firstMappedValue":0,"values":[],"outputUnit":null}}
{"composed":{"transforms":["identity"]}}
```

Decoding will reject unknown tags, wrong value shapes, missing fields and
distinct extra fields, and will revalidate every descriptor invariant. Raw
duplicate-key rejection remains the responsibility of the canonical-JSON
byte-ingress layer.

The lookup-table case will preserve the existing validated
`LookupTableDescriptor` contract, including its currently permitted empty
table. This ADR does not define lookup application, missing-entry behavior,
interpolation or extrapolation and does not claim executable lookup semantics.

`piecewiseLinear` will remain deferred until an approved descriptor and
evaluation contract define every material behavior. Display windows, VOI LUTs,
transfer functions and colour maps remain presentation-stage values and must
not enter `ValueTransform`.

Acceptance will require controlled corrections to both conflicting transform
declarations. No implementation may rely on this proposal while its status
remains Proposed.

## Alternatives considered

### Implement the architecture enum verbatim

This is the smallest four-case declaration. It is not recommended because
direct linear and array payloads bypass finite-value and nonempty-composition
invariants required by the detailed specification.

### Implement the detailed enum verbatim

This preserves the larger case set from the detailed specification. It is not
viable because
`PiecewiseLinearDescriptor` is undefined, and its direct linear and composition
payloads still permit invalid standalone values.

### Validate only when binding an ImageDescriptor

Binding-time checks would avoid new payload types. It is not recommended
because invalid standalone and decoded `ValueTransform` values could circulate,
hash and serialize before binding.

### Define piecewise-linear behavior now

This could complete the larger case set but would invent every consequential
knot, continuity and extrapolation rule. It is deferred until a focused
specification or accepted ADR supplies those contracts.

### Defer every value transform

This is safest while governance is pending, but it blocks M1 image descriptors
and later DICOM rescale-slope/intercept preservation. The proposed validated
four-case intersection provides a bounded path after approval.

## Consequences

- Invalid non-finite linear parameters and empty compositions cannot enter a
  canonical value through public initialization or decoding.
- Composition order is explicit and stable without implicit simplification.
- Two small validated payload types are added even though neither draft enum
  names them; this is the minimum deviation needed to enforce stated
  invariants by construction.
- Piecewise-linear transforms remain unavailable rather than acquiring
  speculative scientific behavior.
- Lookup-table declarations remain possible, but lookup evaluation stays
  blocked on its own domain and extrapolation policy.
- Both governing transform declarations require correction after acceptance.

## Affected modules

If accepted, this decision affects `VoxeliaCore` as owner and implementation
site of `LinearValueTransformDescriptor`, `ValueTransformComposition` and
`ValueTransform`. Existing downstream modules are affected only as consumers
through current dependency edges; no dependency edge or backend-module
ownership changes.

## Compatibility impact

No public `ValueTransform`, `LinearValueTransformDescriptor` or
`ValueTransformComposition` implementation exists. Once implemented, the case
tags, payload field names and composition order become compatibility contracts.

## Security impact

Rejecting NaN and infinity prevents non-finite values from entering comparison
or downstream conversion decisions through a declared linear transform.
Decoders remain untrusted-input boundaries and must enforce depth and resource
limits outside these value-level invariants.

## Performance and memory impact

Linear validation is constant-time. Composition construction and validation are
linear in transform count and materialize one contiguous array. Nested
composition depth is preserved; execution and decoding layers must apply their
own recursion and resource limits.

## Validation impact

After acceptance and implementation, focused evidence must cover:

- finite extreme, subnormal, signed-zero and zero-scale linear values;
- every non-finite scale and offset position;
- nonempty, ordered, nested and one-element compositions;
- empty-composition rejection and high transform counts;
- exact explicit tags, strict fields and decode-time revalidation;
- separation from display windows and transfer functions; and
- static ownership and strict-concurrency builds for Core and direct consumers.

Lookup execution and piecewise-linear tests remain separate follow-on evidence
and are not claimed by this declaration slice.

## Migration

After acceptance:

1. correct the transform declarations in the Master Technical Architecture and
   Core Data Model Specification;
2. implement both validated payload types and `ValueTransform` in
   `VoxeliaCore`;
3. add focused invariant, identity and Codable tests;
4. specify lookup execution and piecewise-linear behavior separately; and
5. update traceability and release-integrity evidence.

No migration step may begin while this ADR remains Proposed.

## Supersession

This Proposed ADR neither supersedes nor is superseded by another file-backed
ADR. If accepted, it resolves the cited value-transform declaration conflict
through the controlled corrections in the Migration section without replacing
either governing document. While Proposed, it has no supersession effect.

## References

- [Voxelia Master Technical Architecture v0.1.1, sections 2.3 and 9.9](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 2, 18, 55 and 58](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, data, imaging, error, DICOM and vertical-slice requirements](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Existing LookupTableDescriptor implementation](../../../Sources/VoxeliaCore/Public/LookupTableDescriptor.swift)

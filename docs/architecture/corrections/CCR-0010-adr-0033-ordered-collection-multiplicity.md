# CCR-0010 - Controlled correction for ADR-0033 ordered collection multiplicity

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0010` |
| Authority | Accepted [`ADR-0033`](../decisions/ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0033`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0010-A - Core Data Model Specification section 34.5 collection

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.5 collection sketch.

The baseline collection reads:

> ```swift
> public struct MetadataCollection: Sendable, Hashable, Codable {
>     public let entries: ContiguousArray<MetadataEntry>
> }
> ```

The corrected collection is the accepted `ADR-0033` boundary: the ordered
immutable sequence with throwing unique-only ordinary construction, a
second throwing initializer taking an explicit
`MetadataMultiplicityPolicy`, `CodableWithConfiguration` conformance using
that same policy type for configured encoding and decoding, the payload-free
`MetadataCollectionError` vocabulary and the five hard version-one
ceilings: 1,048,576 entries, 1,048,576 aggregate logical structural
elements, 67,108,864 aggregate logical variable payload bytes, 1,048,576
supplied multiplicity-policy keys and 67,108,864 supplied
multiplicity-policy logical key bytes, all under checked `UInt64`
accounting that maps overflow to the corresponding typed limit failure.
Construction preserves every entry in exact input order and never sorts,
groups, flattens, deduplicates or rewrites entries; the policy is a
bounded immutable exact-key allow-list that is never stored or serialised.

### CCR-0010-B - Core Data Model Specification section 34.6 invariants

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.6 invariants, as already corrected by `CCR-0008` and `CCR-0009`.

The baseline invariant reads:

> duplicate keys shall be rejected unless the namespace schema explicitly permits multiplicity;

The corrected invariant binds admission to explicit caller context:

> duplicate collection keys shall be rejected by exact `AnyMetadataKey`
> identity under ordinary context-free construction and coding; repeated
> occurrences of an exact key shall be admitted only when an explicit
> caller-supplied bounded immutable multiplicity policy lists that exact
> key, retaining every occurrence and its privacy declaration in input
> order; the policy is a caller assertion of prior external schema
> selection, is never derived from the bytes being decoded, never appears
> on the wire and never participates in collection identity; and entry
> order is semantic for collection equality, hashing and type-level
> encoding.

### CCR-0010-C - Core Data Model Specification section 34.7 typed access

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.7 typed access.

The corrected section additionally records the fixed cardinality rule for
future typed reads: a single-value read with no exact-key match returns a
typed payload-free missing-value failure; a single-value read with more
than one exact-key match returns a typed payload-free multiple-values
failure even when multiplicity was permitted; a single match whose erased
case cannot produce the requested type returns a typed payload-free
type-mismatch failure; and a future multi-value read preserves match order
and validates every element, never coercing or dropping a mismatch. The
concrete accessor and error names remain governed by Proposed `ADR-0034`.

### CCR-0010-D - Core Data Model Specification section 34.8 admission scope

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.8 privacy classification, as already corrected by `CCR-0009`.

The corrected section additionally records that multiplicity admission is
structural only: the collection stores no aggregate privacy class,
comparison, join, maximum or effective-class cache; every entry
declaration, including every `hostDefined` occurrence, is preserved
exactly; and no deduplication step may discard a differently classified
or unresolved occurrence.

### CCR-0010-E - Core Data Model Specification section 37.2 binding

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 37.2 binding validation ("metadata uniqueness").

The corrected item reads:

> metadata validity under unique-only ordinary admission or explicit
> caller-asserted configured multiplicity admission, rather than
> unconditional key uniqueness or independent proof that a namespace
> schema permits a repeat.

### CCR-0010-F - Core Data Model Specification section 55.3 type-level wire

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 55.3 canonical JSON requirements ("rejection of duplicate keys"),
as already corrected for enum tags by `CCR-0008`.

The corrected requirement distinguishes the layers: the semantic
type-level collection wire is the one-field `entries` object whose
ordinary path is unique-only, whose ordinary encoding fails with a typed
error before obtaining an encoder container when the value contains a
repeat, and whose configured path requires the explicit policy at the call
site without ever serialising it; rejection of duplicate raw JSON member
names, schema-version binding, lexical rules and canonical member order
remain canonical-ingress obligations governed by Proposed `ADR-0035`.

### CCR-0010-G - Core Data Model Specification section 58.1 error surface

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 58.1 common data-model error (`duplicateMetadataKey`).

The corrected reading assigns collection-originated construction and
coding failures to the dedicated payload-free `MetadataCollectionError`
vocabulary selected by accepted `ADR-0033`. The shared
`DataModelError.duplicateMetadataKey` case remains reserved for future
aggregate binding surfaces and is not the collection boundary's
construction error.

### CCR-0010-H - Core Data Model Specification section 64.6 validation

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 64.6 metadata and provenance validation ("duplicate keys"), as
already corrected by `CCR-0009`.

The corrected item expands to the accepted evidence obligations: exact
input-order preservation with order-sensitive equality and hashing;
second-occurrence rejection by exact key under ordinary construction;
configured admission of only allow-listed exact keys retaining every
occurrence and privacy class in order; policy, entry, aggregate structural
and aggregate payload ceilings at maximum, maximum plus one and
checked-overflow boundaries with per-occurrence charging of repeated
shared subtrees; unique-only ordinary round trips and pre-container
ordinary encoding failure for duplicate-rich values; configured round
trips with revalidation under wrong or narrower policies; absence of the
policy from the wire; strict one-field decoding with fixed model-relative
paths and no caller path, entry index, count, key, value, privacy class,
policy text or arbitrary child error in failures.

### CCR-0010-I - Core Data Model Specification section 70.5 acceptance

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 70.5 metadata and provenance acceptance criteria ("Duplicate-key
behaviour is defined.").

The corrected criterion records that duplicate-key behaviour is defined by
accepted `ADR-0033`: unique-only ordinary admission, explicit bounded
configured multiplicity, ordered no-deduplication retention and the fixed
typed-read cardinality failures.

## Scope and limits

- The multiplicity policy is a caller assertion, not schema identity or an
  authenticated capability; canonical schema authentication, adapter
  trust, host privacy, authorisation and audit remain outside `VoxeliaCore`.
- The collection ceilings are representation-safety contracts accepted on
  local Apple Silicon boundary evidence; measured lowest-resource
  supported-device evidence remains an explicit open gap recorded in the
  progress ledger alongside the recursive-value gap.
- Swift hashes remain process-randomised and are never a digest; any
  order-insensitive or schema-normalised identity requires a separately
  named reviewed projection.
- These corrections do not authorise typed accessors, canonical byte
  ingress, persistent digest identity or logging/export APIs, which remain
  governed by `ADR-0034` through `ADR-0036` and host policy.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0033` migration steps.

## References

- [ADR-0033 - Ordered metadata collection and explicit multiplicity policy](../decisions/ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md)
- [ADR-0032 - Required metadata-entry privacy attachment](../decisions/ADR-0032-required-metadata-entry-privacy-attachment.md)
- [ADR-0031 - Bounded recursive metadata value boundary](../decisions/ADR-0031-bounded-recursive-metadata-value-boundary.md)
- [CCR-0008 - Bounded recursive metadata value correction](CCR-0008-adr-0031-bounded-recursive-metadata-value.md)
- [CCR-0009 - Required entry privacy attachment correction](CCR-0009-adr-0032-required-entry-privacy-attachment.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 34, 37.2, 55, 58, 64.6, 70.5 and Appendix A](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)

# CCR-0011 - Controlled correction for ADR-0034 closed typed read boundary

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0011` |
| Authority | Accepted [`ADR-0034`](../decisions/ADR-0034-closed-exact-case-typed-metadata-read-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0034`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim.

## Corrections

### CCR-0011-A - Core Data Model Specification section 34.1 key role

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.1 metadata key, and the matching sketch in Master Technical
Architecture section 12.1.

The baseline phantom key sketch is unchanged in fields, initializer,
constraints, equality, hashing and runtime layout. The corrected sections
additionally record its read-boundary role: the generic `Value` parameter
identifies a caller-expected type at compile time only; runtime identity
remains the exact accepted UTF-8 namespace/name pair; any `Sendable`
specialisation remains constructible, but only the eleven supported
specialisations of the closed `ADR-0034` table participate in typed reads,
and unsupported specialisations fail overload resolution at compile time
rather than acquiring a runtime error case.

### CCR-0011-B - Core Data Model Specification section 34.7 typed access

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 34.7 typed access, as already corrected for cardinality by
`CCR-0010`.

The baseline requirement reads:

> Typed accessors shall validate that stored values match the expected type.
>
> A failed typed read shall return a typed metadata error, not silently coerce unrelated values.

The corrected section binds the accessor surface to the accepted closed
mapping: `MetadataCollection` publishes exactly two concrete overloads,
`entry(for:)` and `entries(for:)`, for each of the eleven corrected value
cases (`Bool`, `Int64`, `UInt64`, `MetadataFloatingPoint`, `String`,
`MetadataBinary`, `CanonicalInstant`, `MeasurementUnit`, `CodedConcept`,
`MetadataArray`, `MetadataObject`); extraction pattern-matches the stored
case and returns its exact associated value without parsing, normalising,
widening, narrowing, bridging, unwrapping, flattening or unit conversion;
key matching compares exact ordered UTF-8 namespace and name bytes;
single reads decide exact-key cardinality before inspecting any stored
case; plural reads return every match in original occurrence order after
a complete case preflight and fail atomically on any mismatch without
publishing a valid prefix; a successful read returns the classified
`TypedMetadataEntry` retaining the typed key, the exact payload and that
occurrence's exact privacy class; and no optional, defaulted,
first-matching, privacy-filtered or bare-value convenience exists in
version one.

### CCR-0011-C - Core Data Model Specification section 58 read errors

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 58 error model, as already corrected for the collection surface by
`CCR-0010`.

The corrected reading assigns typed-read failures to the dedicated
non-generic payload-free `MetadataReadError` vocabulary (`missingValue`,
`multipleValues`, `typeMismatch`). Its cases carry no key, requested or
actual type, value, privacy class, match count, index, order, policy or
underlying error, and read operations emit no logs or telemetry on
success or failure.

### CCR-0011-D - Core Data Model Specification sections 66 and 67 limits

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 66 ("metadata lookup may be indexed internally") and section 67
("avoid copying descriptor collections on every read").

The corrected reading records the accepted version-one baseline: typed
lookup is a linear scan in O(entries + examined key bytes) with constant
auxiliary memory for single reads and one count/type preflight plus one
materialisation pass for plural reads; returned results share immutable
copy-on-write backing rather than deep-copying recursive payloads; and a
future private index must map complete exact keys to source-order
position lists, remain immutable and outside public identity, hashing and
wire, and requires focused evidence against this linear oracle.

### CCR-0011-E - Core Data Model Specification section 64.6 validation

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 64.6 metadata and provenance validation ("typed access"), as
already corrected by `CCR-0009` and `CCR-0010`.

The corrected item expands to the accepted evidence obligations: exact
extraction for all eleven table rows under both read families;
compile-negative proof for representative unsupported specialisations;
unchanged phantom-key construction and pair identity; exact UTF-8
cross-form key matching; zero, one and repeated cardinality decided
before case inspection, including a mixed-case duplicate returning
`multipleValues` rather than selecting the matching occurrence; plural
empty success, exact order, all five privacy classes, unresolved
`hostDefined` and late-mismatch atomic failure; exact wrapper
preservation without bridging or Codable routes; absence of bare-value,
optional, privacy-filtered, public-converter, public result-initializer,
Codable and safe-display surfaces; and payload-free error rendering.

### CCR-0011-F - Core Data Model Specification section 70.5 acceptance

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 70.5 metadata and provenance acceptance criteria ("Typed access
is tested.").

The corrected criterion records that typed access is defined by accepted
`ADR-0034` — the closed exact-case overload family with classified
results and count-first cardinality — and is tested by the focused owning
Core evidence recorded in the progress ledger.

## Scope and limits

- A successful typed read proves only exact key identity and exact stored
  case; it is not read, logging, export, disclosure or declassification
  authorisation, and `TypedMetadataEntry` has no safe-display claim.
- Typed reads accept no multiplicity policy, privacy policy, resolver,
  principal, purpose or destination and never re-authenticate the caller
  assertion used during configured collection construction.
- Adding a mapping for a future metadata case requires a reviewed additive
  overload decision; custom semantic conversion belongs in explicit
  adapter operations after an exact typed read.
- These corrections do not authorise optional or defaulted reads,
  write/update APIs, canonical byte ingress, persistent digest identity
  or logging/export APIs, which remain governed by their own decisions,
  including `ADR-0035` and `ADR-0036`.
- This record grants no authority beyond the corrections above: it does not
  accept any other Proposed ADR, alter any requirement row, or authorise
  source outside the accepted `ADR-0034` migration steps.

## References

- [ADR-0034 - Closed exact-case typed metadata read boundary](../decisions/ADR-0034-closed-exact-case-typed-metadata-read-boundary.md)
- [ADR-0033 - Ordered metadata collection and explicit multiplicity policy](../decisions/ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md)
- [ADR-0032 - Required metadata-entry privacy attachment](../decisions/ADR-0032-required-metadata-entry-privacy-attachment.md)
- [CCR-0009 - Required entry privacy attachment correction](CCR-0009-adr-0032-required-entry-privacy-attachment.md)
- [CCR-0010 - Ordered collection multiplicity correction](CCR-0010-adr-0033-ordered-collection-multiplicity.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 34, 58, 64.6, 66, 67 and 70.5](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, section 12.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)

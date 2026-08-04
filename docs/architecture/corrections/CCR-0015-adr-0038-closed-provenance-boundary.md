# CCR-0015 - Controlled correction for ADR-0038 closed provenance boundary

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0015` |
| Authority | Accepted [`ADR-0038`](../decisions/ADR-0038-closed-provenance-record-and-graph-admission-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0038`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim. This correction
authorises no provenance aggregate source: the accepted decision's
eleven-item source gate remains closed until its prerequisites receive
their own decisions.

## Corrections

### CCR-0015-A - Ownership language

Target: `docs/project/Voxelia_Master_Technical_Architecture_v0.1.1.md`,
sections 12.2 and 12.4, and the module-ownership prose read as type
dependencies.

The corrected reading distinguishes claim values from behaviour: “Core owns
provenance types” means `VoxeliaCore` owns immutable backend-neutral
**claim records** only; “Execution owns execution provenance” means
`VoxeliaExecution` owns runtime capture, projection from live Execution
state, assembly and atomic publication. No dependency from Core to
Execution, Storage or Validation exists or is added; live profile, backend,
device, command-buffer, validation-report, storage-handle, resolver, key or
policy objects are never stored in a Core provenance value. Presentation
provenance has the same boundary: a future Rendering-owned typed,
content-addressed extension contract projects presentation details without
making Core import Rendering. Storage reports representation integrity but
never authors operation, execution or validation claims; a future
Execution or host coordinator stages storage output, metadata, identity and
provenance and publishes the coherent bundle atomically.

### CCR-0015-B - Core Data Model Specification section 36.1 record target

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 36.1 provenance record.

The baseline open-optional record (arbitrary `createdAt: String`, an
unlabelled `sources` array, independently optional `operation` and
`execution`, and undeclared `ProvenanceReference` and execution types) is
replaced by the accepted closed logical target: an explicit
`subject: DataIdentityReference` binding the described output snapshot; a
`createdAt: CanonicalInstant` claim; a closed
`ProvenanceActivity` state (`origin`, or `operation` carrying both the
operation and execution claims); ordered role-bearing
`ProvenanceInput` values whose `(role, occurrence)` pairs are unique, each
binding one input data-identity claim and at most one non-recursive parent
reference (`graphNode(ProvenanceID)` or
`externalRecord(id:recordContentID:)`); bounded machine-readable warnings;
and a validation **claim**. Order of inputs and warnings is semantic and
participates in exact record identity; nothing is sorted or deduplicated
silently. No reference case embeds a record, graph or resolver. Every
named type in the target requires its own accepted shape, wire and limits
before source; the target closes relationships, not the source gate.

### CCR-0015-C - Core Data Model Specification section 36.2 activity table

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 36.2 provenance kinds.

The corrected interpretation binds the eleven kinds to the closed activity
state: `source` admits only `origin` (no operation, execution or inputs);
`imported`, `decoded`, `viewed`, `transformed`, `processed`, `segmented`,
`registered`, `rendered`, `materialised` and `cached` require `operation`
plus at least one input. An operation without execution, an execution
without operation, a non-origin record without inputs and an origin with
inputs are all invalid; an empty input array never silently means
“generator”, and zero-input generators require a future registered
contract. A cache retrieval or materialisation never becomes an origin,
never inherits new validation authority and never rewrites history.

### CCR-0015-D - Core Data Model Specification sections 36.6/36.7 claims

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
sections 36.6 validation status and 36.7 warnings.

The corrected reading records `validated(evidenceID:)` and
`diagnosticReady(evidenceID:)` as freely serialisable **claims** whose
evidence references need their own bounded non-recursive shapes and
accepted canonical identity; decoded values are never proof, absence or
decode failure is never interpreted as validated, and preview behaviour is
never substituted for a diagnostic request. `deprecated(reason:)` is
recorded as lifecycle state that must move to a separately governed
lifecycle reference or bounded reason code before source; its arbitrary
string is a privacy and stable-identity hazard. The displayed warning
`message: String` is not authorised as portable Core provenance: the
future warning contract requires a bounded namespaced code with schema
version, a closed severity, structured typed arguments with privacy
classification, deterministic order/occurrence semantics and strict
tagged coding. `WarningSeverity` has no governed cases and no standalone
enum source is authorised.

### CCR-0015-E - Graph admission and identifier restrictions

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
section 36 graph prose and the `ProvenanceID` leaf's permitted use.

The corrected reading records the accepted bounded transactional
admission: one immutable candidate node table and one pinned snapshot;
checked arithmetic before allocation; rejection of duplicate or
conflicting record IDs, duplicate roots, duplicate `(role, occurrence)`
pairs and self-edges; exact record-content verification for resolved
external references with conflicting repeated claims rejected; visit-once
iterative cycle detection and depth computation; the node table equal to
the exact resolved closure of the declared roots; owner-retained record-ID
consistency across snapshots; and publication only after complete
admission, with failure leaving the prior graph byte-for-byte unchanged.
Complete and compact admissions carry explicitly different authority, and
a compact ancestry is never described as verified or cycle-free. The
existing `ProvenanceID` is restricted to local claim identification: it is
not authorised for durable or untrusted graph use until an accepted
correction supplies bounded exact-byte identity, grammar, strict decoding
and lifecycle rules. Exact hard ceilings are deferred until
supported-device, hostile-input, cancellation-latency and
allocation-failure evidence exists. External signed manifests remain
deferred; an unkeyed digest is not authentication, and `ADR-0036`'s
metadata-record projection must not be reused for provenance records.

## Scope and limits

- This correction resolves ownership language, the closed record target
  and admission semantics only; every type named by the target retains its
  own source gate, and no provenance aggregate, graph builder, canonical
  codec, digest, resolver, signature verifier or publication integration
  source is authorised.
- Provenance remains sensitive-derived: IDs, digests, timestamps, source
  references, warnings and build data stay out of logs, telemetry, error
  descriptions and exports without explicit host policy.
- The atomic publication contract (output, identity, single matching
  provenance root, admitted graph state and authorised cache aliases in
  one commit) is recorded as the Execution-owned target; its
  implementation remains gated on the execution/cache contracts.
- This record grants no authority beyond the corrections above: it does
  not accept any other Proposed record, alter requirement rows beyond the
  recorded readings, or authorise source outside the accepted `ADR-0038`
  documentation boundary.

## References

- [ADR-0038 - Closed provenance record and graph admission boundary](../decisions/ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](../decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](../decisions/ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0028 - Canonical instant boundary](ADR-0028-canonical-instant-boundary.md)
- [CCR-0014 - Claim-bearing data identity correction](CCR-0014-adr-0037-claim-bearing-data-identity.md)
- [Voxelia Core Data Model Specification v0.1.1, section 36](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 12.2 and 12.4](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)

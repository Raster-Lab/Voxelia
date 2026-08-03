---
document_id: "ADR-0038"
title: "Closed provenance record and graph admission boundary"
status: "Proposed"
date: "2026-08-03"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-003"
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-GOV-009"
  - "VOX-GOV-010"
  - "VOX-ARC-001"
  - "VOX-ARC-003"
  - "VOX-ARC-004"
  - "VOX-ARC-005"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-010"
  - "VOX-DAT-014"
  - "VOX-RGN-007"
  - "VOX-RGN-008"
  - "VOX-META-003"
  - "VOX-META-004"
  - "VOX-META-005"
  - "VOX-META-006"
  - "VOX-META-007"
  - "VOX-META-008"
  - "VOX-META-009"
  - "VOX-META-010"
  - "VOX-META-011"
  - "VOX-EXE-002"
  - "VOX-EXE-003"
  - "VOX-EXE-004"
  - "VOX-EXE-006"
  - "VOX-EXE-007"
  - "VOX-EXE-009"
  - "VOX-EXE-011"
  - "VOX-EXE-012"
  - "VOX-EXE-013"
  - "VOX-EXE-014"
  - "VOX-EXE-015"
  - "VOX-EXE-016"
  - "VOX-CON-001"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-CCH-004"
  - "VOX-CCH-005"
  - "VOX-CCH-007"
  - "VOX-CCH-008"
  - "VOX-ERR-001"
  - "VOX-ERR-002"
  - "VOX-ERR-003"
  - "VOX-ERR-005"
  - "VOX-ERR-007"
  - "VOX-SEC-006"
  - "VOX-SEC-010"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-010"
  - "VOX-VAL-011"
  - "VOX-VAL-016"
  - "VOX-PER-007"
  - "VOX-REL-005"
  - "VOX-VS1-017"
  - "VOX-VS1-019"
---

# ADR-0038 - Closed provenance record and graph admission boundary

## Context

Voxelia's controlled documents require provenance to be serialisable, to link
derived results to source identities and to form a directed acyclic graph. The
Core Data Model Specification assigns `ProvenanceRecord` to `VoxeliaCore`, but
its displayed record is an open bag of optionals and undefined dependencies:

```swift
public struct ProvenanceRecord: Sendable, Hashable, Codable {
    public let id: ProvenanceID
    public let kind: ProvenanceKind
    public let createdAt: String
    public let software: SoftwareIdentity
    public let sources: ContiguousArray<ProvenanceReference>
    public let operation: OperationProvenance?
    public let execution: ExecutionProvenance?
    public let warnings: ContiguousArray<ProvenanceWarning>
    public let validation: ValidationStatus
}
```

`ProvenanceReference`, `ExecutionProfileDescriptor`, `BackendDescriptor`,
`ApproximationStatus`, `WarningSeverity`, `ProvenanceContext` and
`ProvenanceRequirements` are not declared in any controlled document or
product target. `ValidationStatus` is displayed, but its arbitrary
`evidenceID` and `reason` strings have no grammar, limit, resolver, evidence
binding, privacy classification or trust semantics. The record therefore
permits, among other invalid states:

- a derived result with no input, operation or implementation claim;
- an execution claim without an operation claim;
- a source record that silently carries an execution;
- a cached result that appears to acquire a new validation status;
- ancestry without input roles or output identity binding;
- recursively embedded records and unbounded decoding;
- an unresolved graph being mistaken for a complete acyclic graph; and
- arbitrary warning or deprecation text containing patient, path or host data.

Synthesised `Codable` and `Hashable` would make those states transportable and
comparable. They would not make them valid, canonical, bounded, private,
cycle-free or verified.

The ownership sketches also conflict if read as type dependencies. The Master
Technical Architecture says that Core owns metadata and provenance types while
Execution owns execution provenance and provenance assembly. The live package
graph is:

```text
VoxeliaExecution -> VoxeliaStorage -> VoxeliaCore -> VoxeliaSpatial
```

Core cannot import an Execution-owned profile or backend descriptor without
reversing that graph. Core likewise cannot import Storage integrity state or
Validation evidence types. The viable interpretation is that Core owns only
immutable backend-neutral claim values, while Execution owns the mutable
capture, assembly and publication behaviour that creates them. Storage owns
persistence integrity. Validation evaluates evidence. The host owns policy,
privacy, authentication, signatures and external retrieval.

The controlled graph text is also incomplete. It says that compact records may
reference externally stored parents by ID and digest but does not define a
provenance-record digest projection. Proposed `ADR-0036` registers only the
complete `VCMJ-1` metadata-record projection; it is not a provenance digest.
Proposed `ADR-0037` defines a logical non-recursive data-identity reference but
intentionally leaves its exact wire and limits unresolved. Neither proposal
authorises reuse of its identifiers for provenance by analogy.

An ID or digest in provenance is a claim. A decoded `validated` case is also a
claim. None proves that bytes were read, that an operation ran, that a result
matches its subject identity, that a graph is complete, that a signature is
trusted or that the result is diagnostically suitable. Those conclusions need
runtime evidence bound to an exact snapshot and policy context.

The current `ProvenanceID` leaf is sufficient only as a local declaration
vocabulary. It accepts any non-blank, unbounded Swift string, preserves unsafe
text in default reflection and compares through Swift `String` equality, which
collapses some distinct Unicode spellings. It is not yet a safe untrusted,
persistent or distributed graph key.

Provenance is sensitive-derived even when it contains no direct pixel values.
Source identifiers, SOP instance identifiers, paths, record and content
digests, timestamps, build identifiers, warnings and validation references can
identify a patient, dataset, site, device or confidential build. Permission to
retain provenance does not imply permission to log, export, put it in a URL or
deduplicate it across privacy domains.

This proposal defines the closed conceptual state, ownership and admission
rules needed before the aggregate can become product source. It does not
approve a public record, graph builder, canonical codec, digest, signature,
resolver or validation-evidence implementation while its dependencies and
controlled corrections remain Proposed or undefined.

## Decision

If accepted, Voxelia will interpret “Core owns provenance types” as ownership
of immutable backend-neutral **claim records** only. It will interpret
“Execution owns execution provenance” as ownership of runtime capture,
projection from live Execution state, assembly and atomic publication. No
dependency from Core to Execution, Storage or Validation will be added.

The displayed `ProvenanceRecord` will be replaced by a closed logical target
that binds its subject, uses an explicit activity state and carries ordered
role-bearing inputs. The following sketch is explanatory, not authorised API:

```swift
public struct ProvenanceRecord: Sendable, Hashable, Codable {
    public let id: ProvenanceID
    public let kind: ProvenanceKind
    public let createdAt: CanonicalInstant
    public let subject: DataIdentityReference
    public let software: SoftwareIdentity
    public let activity: ProvenanceActivity
    public let inputs: ContiguousArray<ProvenanceInput>
    public let warnings: ContiguousArray<ProvenanceWarning>
    public let validationClaim: ProvenanceValidationClaim
}

public enum ProvenanceActivity: Sendable, Hashable, Codable {
    case origin
    case operation(OperationProvenance, ExecutionProvenanceClaim)
}

public struct ProvenanceInput: Sendable, Hashable, Codable {
    public let role: ProvenanceInputRole
    public let occurrence: UInt32
    public let identity: DataIdentityReference
    public let parent: ProvenanceParentReference?
}

public enum ProvenanceParentReference: Sendable, Hashable, Codable {
    case graphNode(ProvenanceID)
    case externalRecord(
        id: ProvenanceID,
        recordContentID: ContentID
    )
}
```

Every named type in that target needs its own accepted shape, wire and limits
before source. `CanonicalInstant` is Proposed in `ADR-0028`; `ContentID` and a
provenance-record projection are not accepted; `DataIdentityReference` is a
logical deferred target in `ADR-0037`; and the execution, warning, validation,
role and persistent-ID shapes remain unresolved here. The sketch closes the
relationships and responsibilities; it does not bypass those gates.

### Provenance vocabulary

The following terms are normative for this decision:

- **subject claim** identifies the immutable output snapshot the record is
  asserted to describe;
- **activity claim** says whether the subject is an origin or the completed
  result of an asserted operation and execution;
- **input claim** binds one explicit operation role and occurrence to an input
  data-identity claim and, when known, one parent provenance record;
- **parent edge** is the non-recursive reference from one record to another;
- **record claim** is an immutable exact-field value; successful construction
  or decoding proves only structural validity;
- **resolved subgraph** contains the records currently available to a graph
  validator;
- **complete graph** has every transitive parent resolved for the admitted root
  set and passes the bounded graph checks in one pinned snapshot;
- **compact graph** is structurally valid but has at least one deliberately
  unresolved external parent;
- **graph evidence** is runtime evidence that an exact pinned graph snapshot
  passed a stated validator and limits profile;
- **validation claim** is a serialisable assertion referring to separately
  governed validation evidence; and
- **publication** is Execution's single linearisation point that makes output,
  data identity, completed provenance and authorised cache aliases visible.

The unqualified terms “verified provenance”, “trusted provenance” and
“validated record” must not be used for a decoded value. Documentation must
name the exact evidence, snapshot, purpose and policy that support a runtime
conclusion.

### Ownership and dependency boundary

| Responsibility | Owner | Rule |
|---|---|---|
| Immutable subject, activity, input, warning and validation claim values | `VoxeliaCore` | Backend-neutral values only; no import of Execution, Storage or Validation. |
| Live operation/profile/backend/device/kernel state | `VoxeliaExecution` and backend modules | Project approved state into Core-owned claims; do not expose live objects through Core. |
| Provenance capture, assembly and result publication | `VoxeliaExecution` | Actor-isolated or equivalently serialised, cancellation-aware and generation-pinned. |
| Record and graph persistence integrity | `VoxeliaStorage` or host store | Verify bytes against an accepted provenance projection before resolving durable references. |
| Scientific and diagnostic evidence evaluation | `VoxeliaValidation` plus approved governance | Produce runtime assurance; never mutate a decoded claim into proof. |
| External retrieval, authentication, signatures, trust anchors, privacy and export policy | Host application/service | Outside Core; transport or signature validity grants no scientific or disclosure authority. |

An Execution profile, backend registration object, Metal device, command
buffer, validation report, storage handle, resolver, key or policy object must
never be stored in a Core provenance value. Core-neutral execution claims need
stable IDs, exact versions and output-affecting fields. Their final declaration
must include at least profile and profile version, backend and implementation
version, precision policy, quality policy, approximation status, capability
class when relevant, and kernel/shader identity when relevant. Undefined live
descriptor types are not acceptable substitutes.

Presentation provenance has the same dependency boundary. Scene, camera,
viewport, transfer-function and rendering request types belong downstream of
Core. This decision covers only the foundational subject, activity, input and
execution claim envelope. A future Rendering-owned, typed and content-addressed
extension contract must project presentation details without making Core
import Rendering and without placing an untyped dictionary or arbitrary blob
in the foundational record.

The CDMS storage-builder sketch is also ambiguous because `commit` accepts a
provenance value while adjacent prose says that commit creates provenance.
Storage must not invent operation, execution or validation claims. A future
Execution or host coordinator stages storage output, metadata, identity and
provenance, asks each owner to validate its boundary and publishes the coherent
bundle atomically. Storage may report representation integrity; it does not
author scientific execution history.

### Subject and activity completeness

Every published record has exactly one subject `DataIdentityReference`. A
record next to an `ImageData.identity` value is valid only if the subject and
published identity are the same exact claim under the accepted reference
profile. Positional adjacency, equal object IDs or matching optional digests do
not establish that binding.

The activity state is closed:

| Activity | Operation | Execution | Inputs | Structural meaning |
|---|---:|---:|---:|---|
| `origin` | absent | absent | zero | The subject is asserted to be an origin record. No operation or execution is implied. |
| `operation` | required | required | one or more | The record contains the operation and execution claims for the completed result. |

An operation without execution, execution without operation or either partial
combination is invalid for a complete record. Imported partial assertions need
a separately tagged incomplete-record contract; graph compactness must not be
used to make an incomplete node appear complete. A non-origin record without
an input is invalid in the first closed profile. Zero-input generators require
a future explicit registered generator/source contract; an empty array must
not silently mean “generator”. An origin with an input, operation or execution
is invalid.

For the existing eleven `ProvenanceKind` values, the initial interpretation is:

- `source` admits only `origin`; and
- `imported`, `decoded`, `viewed`, `transformed`, `processed`, `segmented`,
  `registered`, `rendered`, `materialised` and `cached` require `operation`
  plus at least one input.

This table is a proposed controlled correction, not current source authority.
An import can name a technical source through its input data-identity claim
without having a parent provenance record. A cache retrieval or materialisation
does not become an origin and does not inherit new validation authority; it
must retain an explicit input link. A cache hit may reuse the original record
or add a separately defined access/materialisation record, but it may not
rewrite history.

The record kind classifies the asserted activity. It does not prove that the
activity occurred or that a particular algorithm, backend or validation level
is suitable.

### Ordered roles and input occurrences

`inputs` is an ordered sequence. Order participates in exact record identity
and canonical bytes. It must not be sorted, inferred from source order or
silently deduplicated.

Every input contains an explicit bounded role identifier and an explicit
zero-based occurrence. The pair `(role, occurrence)` is unique within one
record. Repeated use of the same input is valid only through distinct role or
occurrence pairs. The same parent may therefore appear for `fixed` and
`moving`, or for two declared variadic occurrences, without being collapsed.

The exact role grammar, byte cap and registry are deferred to a controlled
operation-contract decision. A role is not derived from a Swift parameter
label, dictionary iteration order, display text, localized text or array
position alone. Unknown roles at an operation boundary require explicit
versioned operation-schema handling; Core does not resolve their semantics.

Each input identity binds the data consumed for that role. `parent` is
optional because a source identity can be known when its upstream provenance
record is unavailable. A present parent asserts ancestry for that same input;
ancestry must never be guessed from a global source list or matching digest.
When a parent resolves, its exact subject claim must match the input identity
under the explicitly selected reference profile. Object identity and separately
verified content equivalence are not silently interchangeable comparison modes.

### Flat non-recursive references

No reference case contains a `ProvenanceRecord`, graph, arbitrary recursive
metadata value or resolver closure. Complete provenance is a bounded flat node
table plus root IDs, not a recursively nested record tree.

The two logical reference cases have distinct authority:

- `graphNode(id)` resolves only in the exact pinned graph snapshot being
  admitted. It is not portable by itself and an absent local node is invalid;
- `externalRecord(id, recordContentID)` may remain unresolved in a compact
  graph. If resolved, the supplied record's exact canonical provenance-record
  identity must match the claim before it contributes to completeness or cycle
  evidence.

Every occurrence of one unresolved external record ID in a candidate graph
must carry the same exact record-content claim and the same expected subject
identity. A disagreement is a conflicting claim, not two independent missing
parents. Resolution must recheck both bindings before replacing compact
authority with complete authority.

A durable external reference needs an accepted domain-separated provenance-
record projection, exact digest tuple, bounded persistent `ProvenanceID` and
strict tagged wire. None exists yet. Proposed `ADR-0036`'s metadata-record
profile must not be reused. `Codable` bytes, `hashValue`, a file checksum, an
object ID or a naked digest are not a provenance-record identity.

A reference to the record's own ID is rejected before graph admission,
regardless of tag. Two nodes with one ID are rejected even if their values are
equal. Reuse of one ID with different exact record claims is a conflict, never
an update. Enrichment or correction publishes a new immutable record and ID.

The record's exact `ContentID` is an envelope/link claim about the canonical
record bytes, not a field inside those same bytes. Placing it inside its own
digest preimage would be circular. `ProvenanceID` remains a distinct opaque
node identifier; making it equal to a digest of bytes that themselves contain
that ID would likewise require a separately designed non-circular scheme and
is not authorised.

The current `ProvenanceID` is not authorised for durable or untrusted use until
an accepted correction supplies exact bounded-byte identity, an allowed
grammar, strict decoding, stable redacted diagnostics and a lifecycle/generation
rule. Local adapters must apply an explicit host cap until then and must not
claim portable graph identity.

### Record exactness and canonical identity

Provenance record equality is exact record equality, not operation-semantic,
scientific-result or validation equivalence. Accepted spelling and sequence
order are preserved. Every field emitted in the record's canonical wire must
participate in exact identity.

The existing `SemanticVersion` intentionally ignores build metadata in
ordinary equality and hashing while preserving it in coding. Synthesised
record equality would therefore collapse software or implementation records
whose encoded build metadata differs. A future provenance value must either
use a separate exact version-record type or implement exact field comparison
and hashing that includes build metadata. It must not use ordinary
`SemanticVersion ==` as record equality when build metadata is present.

`createdAt`, software name/version, commit, build identifier, operation and
implementation identities, backend/profile/device/kernel values, warnings and
validation references are claims. Their presence does not establish clock
authenticity, source control cleanliness, build reproducibility, device
attestation, execution or validation.

The displayed single `software` field is insufficiently scoped for a pipeline
that may involve a source adapter, codec, Voxelia release, operation
implementation, compiler and backend library. A future correction must define
whether it identifies the record assembler only or replace it with a bounded
ordered role-bearing component list. Callers must not concatenate several
identities into one display string.

An accepted provenance canonical profile must define strict tags, field order,
null/absence behavior, exact string and integer forms, limits, unknown-field
policy, record and graph schema versions, and a domain-separated content
projection. Synthesised `Codable` is not that profile. Until it exists,
external record digests, signed manifests and distributed provenance remain
source-blocked.

### Operation and execution claim boundary

`OperationProvenance` must bind exact operation and implementation IDs and
versions plus a `ContentID` produced by a separately registered canonical
parameter projection. Proposed `ADR-0036` does not register that projection.
The parameter claim must cover every output-affecting option; an omitted
quality, precision, boundary, interpolation, seed, tolerance or approximation
choice cannot be repaired by a later warning.

`ExecutionProvenanceClaim` is a Core-owned snapshot projected from Execution's
live state. It must cover the requirements in `VOX-META-006` and, where
applicable, `VOX-META-007` through `VOX-META-009`. It does not contain live
profile/backend descriptors. Stable Core-neutral reference shapes and exact
versions remain a prerequisite.

Approximation status is distinct from execution quality and validation:

- quality/profile describes the requested or achieved execution policy;
- precision describes arithmetic and representation policy;
- approximation describes known deviation from an exact/reference semantic;
- warnings describe interpretation-relevant conditions; and
- validation claims refer to evidence about an implementation/configuration.

None may be inferred from another. A diagnostic profile cannot silently erase
an approximation, a warning cannot silently downgrade diagnostic behavior and
a preview result cannot be relabelled diagnostic-ready because its numbers
look plausible.

### Warning boundary

Portable provenance warnings are stable machine-readable claims. At minimum a
future warning contract needs:

- a bounded namespaced code and code-schema version;
- a closed interpretation-oriented severity;
- explicit structured argument types and units where arguments are required;
- privacy classification for every non-constant argument;
- deterministic order and repetition semantics; and
- exact limits and strict tagged coding.

The displayed arbitrary `message: String` is not authorised as portable Core
provenance. Library-generated display text should be rendered from a trusted
code catalogue outside record identity. Host-supplied free text requires
explicit privacy classification, storage permission and disclosure policy; it
must not enter logs, telemetry or exported provenance by default.

Warning order is preserved and participates in exact record identity. There is
no implicit sorting or deduplication. Repeated warnings need an explicit
occurrence or structured affected-input context in their future schema. The
future constructor rejects an exact duplicate structured warning key; two
occurrences are representable only when their explicit occurrence or context
differs. The key is code plus affected input and occurrence; conflicting
severity or arguments under one key is rejected rather than treated as a
second warning. A fatal condition is a typed failure, not a high-severity
warning attached to a published success.

`WarningSeverity` has no governed cases, ordering or wire. No standalone enum
source is authorised by this proposal.

### Validation claims and runtime assurance

`validated(evidenceID:)` and `diagnosticReady(evidenceID:)` are freely
serialisable assertions. They are not proof and must be renamed or documented
as claims. The evidence reference needs its own bounded non-recursive shape and
accepted canonical identity.

Runtime assurance for an exact provenance record must separately bind, as
applicable:

- evidence schema and content identity;
- requirement, tolerance, algorithm and dataset versions;
- operation and exact implementation versions;
- parameter, input-domain and output claims;
- execution profile, quality and precision policy;
- backend, capability class, device constraints and shader/library identity;
- toolchain, operating-system and Voxelia release context;
- approval scope, policy purpose and privacy domain; and
- freshness, expiry and revocation state.

Missing, mismatched, expired, revoked, cross-release, cross-device,
cross-profile or cross-policy evidence fails closed for that purpose. It does
not mutate or delete the original claim record.

`deprecated(reason:)` is not validation evidence. Deprecation is capability or
schema lifecycle state governed by release policy. An arbitrary reason string
is also a privacy and stable-identity hazard. The displayed case must be moved
to a separately governed lifecycle reference or replaced by a bounded reason
code before source.

`unknown`, `experimental` and `preview` remain explicit claim states. A host
must never interpret absence or decode failure as validated, and it must not
substitute preview behavior for a diagnostic request.

### Bounded graph admission

Graph admission operates over one immutable candidate node table and one
pinned resolver/store snapshot. It is iterative and transactional. Before
publication it performs all of the following:

1. validate the limits profile and use checked arithmetic for every count and
   byte total before allocation or traversal;
2. reject zero mandatory limits and every hard-cap, record-count, input-edge-
   count, logical-byte, identifier and per-field violation; zero is permitted
   only for the unresolved-external-reference cap, where it means none may be
   admitted;
3. reject duplicate record IDs, conflicting claims and duplicate root IDs;
4. reject duplicate `(role, occurrence)` pairs and every self-edge;
5. resolve every `graphNode` in the candidate table;
6. for each available `externalRecord`, verify the exact record-content claim
   before treating it as resolved;
7. require each resolved parent's subject to match the data identity on the
   exact input edge under the selected comparison profile;
8. reject conflicting content or expected-subject claims for repeated
   unresolved external IDs;
9. distinguish absent permitted external parents from resolved parents;
10. perform visit-once iterative cycle detection over every resolved edge;
11. compute maximum resolved ancestry depth without recursive call-stack use or
   exponential re-traversal of diamond graphs; and
12. require the supplied node table to equal the exact resolved closure of the
    declared roots, rejecting every unrelated or unreachable record; and
13. before replacing an owner snapshot, check the owner's bounded retained
    record-ID registry and reject any previously admitted ID whose exact record
    value differs, including IDs absent from the immediately current root
    closure; and
14. publish the new immutable graph snapshot only after the entire admission
    succeeds.

The graph owner rejects two- and multi-node cycles, not only direct self-
references. A depth limit is measured over the longest resolved parent chain.
Node and edge counts are logical counts; a diamond is visited once per node and
edge, not once per path. Unknown arithmetic, overflow, allocation failure,
cancellation or resolver failure is a typed failure.

The unresolved-external-reference count is per input-edge occurrence, not per
unique external record ID. Two roles that name one absent record therefore
consume two units as well as two edge units. The separate consistency map for
external IDs is bounded by that occurrence count and cannot weaken the ordinary
total-edge ceiling.

The exact public hard ceilings are deferred until supported-device, hostile-
input, cancellation-latency and allocation-failure evidence exists. A future
caller-selected limits value must be capped by implementation hard maxima; a
caller cannot request “unlimited”. Probe-only limits are not production
defaults.

The per-snapshot node cap and the owner's lifetime retained-record cap are
separate immutable limits. The owner, not an untrusted replacement candidate,
selects the latter within an implementation hard maximum and at least large
enough for the initial snapshot. Exhaustion is a typed transactional failure:
it neither evicts a prior ID claim nor publishes the candidate. Production
retention/deletion, durable-history and project-lifecycle semantics remain a
Storage/governance prerequisite; deletion must never make changed reuse of an
immutable ID valid.

Admission modes are explicit:

| Mode | Unresolved local parent | Unresolved external parent | Result authority |
|---|---:|---:|---|
| Complete | reject | reject | Resolved graph is structurally acyclic under the exact admitted snapshot and limits; scientific and authenticity assurance remain separate. |
| Compact | reject | retain as unresolved | Only the resolved subgraph is known acyclic. The complete ancestry must not be described as verified or cycle-free. |

The selected admission mode is policy, not the resulting resolution state. A
compact-mode admission with no unresolved parent is classified complete; a
graph is classified compact only while at least one permitted external parent
remains unresolved.

An unresolved compact parent can later be resolved only through a new
transaction against a pinned snapshot. Resolution failure or a newly exposed
cycle leaves the earlier compact graph unchanged.

Importing records one at a time and publishing before cycle checking is
forbidden. Failed insertion, replacement, resolution or composition leaves the
previous graph byte-for-byte unchanged. A mutable graph service, if introduced,
must be actor-isolated or equivalently serialised.

### Signed external manifests

The MTA permits a signed external provenance manifest, but no signature
contract exists. It remains deferred. An unkeyed digest is not authentication.

A future signed statement must bind at least its canonical format/projection
version, graph root set, every included node or graph content identity,
external reference closure rules, signer and key identity, signature algorithm,
policy purpose/privacy domain and relevant freshness data. Verification also
requires host-owned trust anchors, key rotation and revocation policy.

A valid signature proves only that a holder of the signing key signed the
bound bytes. It does not prove that an operation ran, that inputs were
authentic, that the result is scientifically correct, that a validation claim
is current or that the recipient may view/export the record. Nested or linked
manifests do not inherit signature authority unless the signed statement
explicitly binds them.

Core will not own credentials, network retrieval, trust stores, certificate
policy or authorisation.

### Privacy-safe diagnostics

Provenance-owned validation and graph errors are payload-free cases with fixed
value-redacted descriptions. They may identify a field category or failure
class, but do not retain or interpolate:

- record, data, source, evidence, operation, implementation or content IDs;
- warning text, deprecation reasons or host policy values;
- paths, URLs, UIDs, commit/build identifiers or decoder payloads;
- input bytes, underlying errors or arbitrary coding paths; or
- patient, study, series, site, device or tenant details.

Core provenance code emits no logs or telemetry. An owning adapter may attach
safe structured context after applying host privacy policy. `String(describing:)`,
`String(reflecting:)`, error descriptions and debug views of claim values must
remain redacted by default. Safe storage permission is independent from log,
telemetry, UI, filename, URL, cross-tenant comparison and export permission.

Digests and IDs remain sensitive-derived. They are not automatically
de-identified and must not be used as unkeyed pseudonyms.

### Atomic result publication

Core records are immutable. Execution assembles a tentative record and graph
off to the side. The successful result linearisation point atomically publishes
one coherent bundle containing:

- the immutable output;
- its exact `DataIdentity` snapshot;
- exactly one provenance root whose subject matches that identity; this single-
  output contract requires the admitted graph root set to be that singleton,
  while any later multi-output publication needs an explicit output-to-root
  map;
- every newly admitted provenance record/edge required by the selected graph
  mode;
- runtime assurance references that were separately authorised for the
  publication purpose; and
- any explicitly authorised result-cache alias.

Immediately before the commit, Execution rechecks cancellation, task outcome,
generation/revision, pinned inputs and resolver/store snapshot, target lifetime,
independently verified output-to-identity binding, identity/provenance binding
and purpose-specific validation requirements. Every attached assurance is
checked against an Execution-owned authorised publication context even when
assurance is optional; “required” controls only whether absence is permitted.
Every cache alias requires a separate owner-issued authorisation bound to the
exact output, identity, root record, admitted graph, generation, snapshot and
cache policy.
Stale generation, changed input, cancelled work, backend failure, validation
failure, digest mismatch, graph admission failure, target removal or duplicate
completion publishes none of the bundle.

No success provenance ID, edge, graph snapshot, output, cache entry, external
name, log or telemetry field becomes visible early. Successful commit occurs
once. Cancellation after that point applies to future work and does not rewrite
the completed immutable history.

Attempt, cancellation and failure audit events, if retained, are separate
host-governed records. They must not masquerade as successful result
provenance. Cache-hit handling independently verifies the stored output,
identity and exact admitted provenance graph against owner-issued read evidence
for the authorised cache policy; it does not manufacture a stronger validation
claim.

### Source gate

This proposal authorises documentation and isolated evidence only. Product
source remains blocked until every dependency actually retained by the target
is accepted. An accepted controlled correction may remove a dependency from
scope; merely deferring it continues to block every dependent field and type:

1. `ADR-0028` and the `CanonicalInstant` controlled correction;
2. `ADR-0036`, a corrected general `ContentID` boundary and a separately
   registered provenance-record canonical projection;
3. `ADR-0037` plus exact bounded `DataIdentityReference` and subject/input wire;
4. a bounded exact-byte persistent `ProvenanceID` contract;
5. exact software, operation, implementation, role and parameter-projection
   identities, including build-metadata equality;
6. Core-neutral execution-profile, backend, capability, precision, quality,
   kernel/shader and approximation claim shapes;
7. warning code/severity/argument/privacy schemas and limits;
8. validation-evidence and lifecycle references with trust semantics;
9. record and graph canonical wires, hard resource ceilings, cancellation and
   hostile-input evidence;
10. atomic Execution publication and cache integration contracts; and
11. controlled MTA, CDMS, Requirements Baseline, type-inventory and milestone
    reconciliation plus required review and approval.

No independently safe aggregate or undefined leaf becomes implementable merely
because its relationship is described here. Existing `ProvenanceKind` remains
an exact taxonomy and existing `ProvenanceID` remains a local claim identifier;
neither proves aggregate readiness.

### Milestone interpretation

After acceptance and prerequisite closure, M1 may own immutable foundational
claim declarations and pure bounded complete-graph validation. M2 owns actual
derived-data operation/execution capture, provenance assembly, generation-aware
publication and demonstrated cache/identity binding. M3 adds governed Metal
shader/library and backend-capability claims plus the Rendering-owned typed,
content-addressed extension contract and behavior required by `VOX-META-008`.
M4 exercises the accepted import and render-provenance behavior in the first
vertical slice. M8 adds the downstream typed
`VoxeliaPhotorealisticRendering` provenance extension for seed, sampling,
accumulation, convergence and denoising claims required by `VOX-META-009`;
those details do not move into Core. M9 owns stable distributed record/manifest
wires and external-service contracts.

Earlier declaration must not accidentally freeze the M9 wire through
synthesised `Codable`. Later milestone targets likewise do not authorise
earlier unsafe placeholders. Public data-model source requires the project RFC,
controlled-document corrections and designated maintainer/security/validation
review in addition to accepting the prerequisite ADRs.

## Alternatives considered

### Implement the displayed optional record directly

Rejected. It represents invalid activity combinations, lacks subject/role
binding and imports undefined types. Later validation would not remove invalid
public states or serialised ambiguity.

### Move all provenance types into Execution

Rejected. Canonical data handles and cross-module records need backend-neutral
claim values, and the controlled model assigns those values to Core. Execution
owns behavior and assembly, not every immutable claim type.

### Make Core depend on Execution descriptors

Rejected. It reverses the approved live dependency graph and couples canonical
records to live scheduling/backend objects.

### Store Execution objects behind protocols or type erasure

Rejected. Type erasure hides the cycle rather than defining stable,
serialisable, backend-neutral provenance. Runtime object identity is not a
persistent claim contract.

### Keep `sources` as an unlabelled record array

Rejected. It cannot bind input roles or occurrences, does not directly name the
input data identity and encourages ancestry inference from array position.

### Recursively embed parent records

Rejected. Recursive values amplify hostile input, duplicate diamond ancestry,
make cycle-safe decoding difficult and prevent compact/external graphs.

### Treat every syntactically valid record as a complete DAG

Rejected. Structural validity of one node says nothing about unresolved
parents or cycles exposed after resolution.

### Reject compact graphs

Rejected. Controlled architecture explicitly permits compact provenance.
Compact status must remain explicit and weaker than complete-graph evidence.

### Silently sort or deduplicate inputs and warnings

Rejected. Role/occurrence order and warning occurrence can be semantically
meaningful and participate in exact record identity.

### Use `ProvenanceID` alone for durable references

Rejected. An opaque ID does not bind exact record content and the current leaf
has no bounded persistent identity profile.

### Use the metadata-record digest for provenance records

Rejected. `ADR-0036`'s domain and projection bind complete VCMJ metadata bytes,
not provenance bytes. Cross-domain reuse defeats the purpose of separation.

### Trust `validated(evidenceID:)` after decoding

Rejected. Any sender can serialise the case. Assurance requires independently
resolved, matched, current and policy-authorised evidence.

### Keep deprecation reasons and warning messages as unrestricted strings

Rejected. They are unstable portable identity and privacy hazards and are not
needed for machine-readable Core claims.

### Consider a valid signature sufficient proof

Rejected. Signature verification establishes signer-controlled bytes under a
trust policy, not execution, scientific correctness, validation status or
disclosure permission.

### Publish provenance before the output finishes

Rejected. Cancellation, stale generations or later validation failure could
leave successful provenance pointing to absent or incomplete results.

## Consequences

- The Core/Execution dependency direction is preserved.
- The provenance record gains an explicit subject, closed activity state and
  role-bearing inputs before it can become public.
- Source and derived records cannot occupy arbitrary optional combinations.
- Complete and compact graphs have explicit, different authority.
- Flat references and iterative bounded admission prevent recursive graph
  amplification and call-stack failure.
- A record claim, validation claim, graph assessment, content verification,
  signature verification and scientific assurance remain separate facts.
- Warnings and diagnostics default to machine-readable, bounded and redacted
  forms rather than arbitrary portable text.
- Execution must commit output, identity, provenance and authorised cache state
  atomically.
- The proposal adds substantial prerequisite work and intentionally leaves the
  aggregate source-blocked rather than freezing unsafe API.

## Affected modules

- `VoxeliaCore`: future immutable provenance claims, exact record state,
  non-recursive references and pure structural validation surfaces.
- `VoxeliaExecution`: runtime projection, provenance assembly, graph admission
  coordination, cancellation/generation checks and atomic publication.
- `VoxeliaStorage`: persistent record/graph bytes, snapshot resolution and
  integrity verification under an accepted provenance projection.
- `VoxeliaValidation`: evidence evaluation and purpose-specific runtime
  assurance, without becoming a Core dependency.
- `VoxeliaImaging`, `VoxeliaGeometry`, `VoxeliaRendering`, `VoxeliaCPU` and
  `VoxeliaMetal`: future suppliers of exact operation, parameter, backend,
  precision, approximation and shader claims.
- `VoxeliaPhotorealisticRendering`: future supplier of typed downstream seed,
  sampling, accumulation, convergence and denoising provenance claims without
  making Core depend on the optional renderer.
- Host adapters/applications: source identity, privacy policy, external
  retrieval, authentication, signatures, trust and export decisions.

## Compatibility impact

No `ProvenanceRecord`, reference, operation, execution, warning or validation
aggregate exists in product source, so the corrected target moves no compiled
symbol or serialised fixture. Existing `ProvenanceKind` raw values are retained.

The current `ProvenanceID` API remains unchanged by this documentation-only
increment, but it is explicitly restricted from untrusted/persistent graph use
until corrected. Future correction may be source-breaking and requires its own
review because tightening an already-public string initializer changes accepted
inputs and equality expectations.

The controlled CDMS record, MTA ownership wording, Requirements Baseline and
type inventory require correction before implementation. Any earlier external
prototype using synthesised record `Codable`, recursive parents or free-text
warnings is not a compatible Voxelia provenance format.

## Security impact

The decision reduces confused-deputy and data-disclosure risk by separating
claims from evidence, requiring bounded flat graph admission, keeping trust
outside decoded values and preventing partial publication.

It does not make provenance non-sensitive. IDs, digests, timestamps, source
references, warnings, evidence references and build data may enable patient,
dataset, site or device correlation. Storage, logging, telemetry, export,
cross-tenant comparison and deletion/retention need separate host policy.

External manifests remain unauthenticated until a signature profile and
host-owned trust policy are accepted. A digest is neither a MAC nor a
signature. Neither graph completeness nor signature validity proves scientific
correctness.

A conforming implementation must make every untrusted ingress bounded,
checked, cancellable and transactional. Resource exhaustion, cycle
amplification, Unicode aliasing, resolver substitution and stale-snapshot
publication require focused adversarial tests before that guarantee is made.

## Performance and memory impact

Record construction is O(i + w) in input and warning counts after bounded leaf
validation. Graph admission is O(n + e) in resolved nodes and edges and uses
O(n + e) bounded temporary state. Iterative traversal avoids recursive stack
growth. Visit-once accounting prevents exponential work for diamond graphs.

Exact hard maxima are not selected here. A later implementation must measure
the lowest-resource supported Apple devices, hostile wide/deep graphs,
cancellation latency, checked-count overhead and recoverable allocation
failure before choosing them. Limits must be enforced before large allocation
or resolution work.

Canonical record hashing, signature verification, resolver I/O and validation
evidence evaluation are separately budgeted operations. None may run implicitly
inside ordinary `Hashable`, equality, description or decoding.

## Validation impact

Acceptance requires focused evidence for at least:

- every valid and invalid subject/activity/kind combination;
- missing subject, operation, execution and required input claims;
- exact version equality including build metadata;
- strict non-recursive tagged local and external references;
- ordered roles, occurrences, repeated parents and duplicate role rejection;
- self, two-node and multi-node cycle rejection;
- duplicate and conflicting record IDs;
- complete versus compact unresolved-reference behavior;
- external record-content mismatch and parent substitution;
- checked node, edge, depth, byte and identifier limits;
- wide fan-out, deep chains and diamond visit-once behavior;
- cancellation and fault injection during validation/resolution;
- decoded validation claims remaining unassured;
- missing, mismatched, expired, revoked and cross-policy evidence denial;
- no PHI sentinel in errors, descriptions, reflection, logs or telemetry;
- transactional graph failure leaving the previous snapshot unchanged;
- cancellation, failure, stale generation/snapshot, input change, target
  removal, duplicate completion and validation failure publishing no output,
  provenance or cache state;
- one successful atomic publication and independent cache-hit revalidation;
- strict Swift concurrency, format lint and supported-destination compilation;
  and
- static proof that Core imports no Execution, Storage or Validation module.

The isolated probe accompanying this proposal demonstrates only the closed
state, bounded graph algorithm, claim/evidence separation and atomic failure
behavior. Its small limits, toy content claims and in-memory actor are not
product API, cryptography, canonical coding, a store, a resolver, a signature
system or production device evidence.

No complete Swift package suite is required for the proposal increment because
product source and package topology do not change. The focused probe plus
document, ADR-register, manifest and release-integrity checks cover the changed
surface.

## Migration

If accepted:

1. correct the MTA and CDMS ownership language to distinguish Core claim values
   from Execution capture/assembly behavior;
2. correct the displayed record to bind a subject and use a closed activity
   plus ordered role-bearing inputs;
3. correct `createdAt` to the accepted `CanonicalInstant` target;
4. resolve `DataIdentityReference`, `ContentID`, persistent `ProvenanceID`,
   exact version/identifier and parameter-projection prerequisites;
5. define Core-neutral execution, warning and validation/lifecycle claim
   records with exact strict tagged coding and privacy rules;
6. register a versioned canonical provenance-record and graph format plus
   domain-separated content projections;
7. select hard limits only after supported-device and hostile-input evidence;
8. implement the immutable Core records and focused construction/coding tests;
9. implement iterative transactional graph admission and focused graph/fault
   tests without adding prohibited dependencies;
10. implement Execution capture and the atomic result/identity/provenance/cache
    commit with cancellation and stale-generation evidence;
11. add Storage resolution/integrity and Validation assurance only through
    their owning modules; and
12. leave signatures, external retrieval, credentials, privacy and export
    policy host-owned under separate accepted contracts.

Until those gates are accepted, no provenance aggregate, graph builder,
canonical codec, digest, resolver, signature verifier, validation-assurance
bridge or publication integration source is authorised.

## Supersession

This proposal refines the incomplete provenance record and graph sketches in
the MTA and CDMS. It does not supersede `ADR-0028`'s time profile,
`ADR-0036`'s metadata-record identity or `ADR-0037`'s data-identity claim and
cache-admission boundary. It composes downstream of them and records additional
requirements they intentionally left unresolved.

It does not define general execution profiles, backend registration, warning
catalogues, capability release status, validation packages, signatures,
storage integrity, cache keys, privacy policy or distributed transport.

## References

- [Voxelia Project Foundation v0.1.1](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0028 - Canonical instant boundary](ADR-0028-canonical-instant-boundary.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0038 closed-record and graph-admission probe](../../progress/evidence/ADR-0038-provenance-record-graph-admission-probe.swift)

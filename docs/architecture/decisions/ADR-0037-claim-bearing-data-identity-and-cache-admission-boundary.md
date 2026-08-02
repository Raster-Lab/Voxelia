---
document_id: "ADR-0037"
title: "Claim-bearing data identity and cache-admission boundary"
status: "Proposed"
date: "2026-08-03"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-003"
  - "VOX-GOV-005"
  - "VOX-GOV-006"
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
  - "VOX-RGN-009"
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
  - "VOX-ERR-007"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-011"
---

# ADR-0037 - Claim-bearing data identity and cache-admission boundary

## Context

Voxelia's controlled documents agree that an immutable data object needs a
stable identity for caching and provenance, but they do not agree that a full
content digest is immediately available. The Master Technical Architecture
section 11.3 first says that every immutable object has a content identity and
then permits a large remote object to begin with a source identity and acquire
a content digest only after validation. The Core Data Model Specification
sections 32.5 and 33 instead state the operational rule directly: a large
object may retain source or derivation identity while its full digest is
pending and must not claim that the digest is complete. `VOX-RGN-007` likewise
requires stable content **or derivation** identity at M2.

The displayed Core records do not close that boundary:

```swift
public struct SourceIdentity: Sendable, Hashable, Codable {
    public let namespace: String
    public let identifier: String
    public let version: String?
    public let contentID: ContentID?
}

public struct DerivationIdentity: Sendable, Hashable, Codable {
    public let operationID: String
    public let operationVersion: SemanticVersion
    public let implementationID: String?
    public let inputIdentities: ContiguousArray<DataIdentityReference>
    public let parameterDigest: ContentID
}

public struct DataIdentity: Sendable, Hashable, Codable {
    public let objectID: DataObjectID
    public let contentID: ContentID?
    public let sourceIdentities: ContiguousArray<SourceIdentity>
    public let derivation: DerivationIdentity?
}
```

`DataIdentityReference` is not declared anywhere. The records have no
construction rule for an object with no content, source or derivation claim;
no duplicate-source rule; no source ordering semantics; no distinction between
a decoded digest claim and verified bytes; and no publication rule for lazy
completion. Synthesised `Codable` and `Hashable` would make the fields
serialisable and comparable but would not provide those invariants.

The displayed derivation record is also not the result-cache key required by
MTA section 21.3 and `VOX-CCH-004`. It omits an exact implementation version,
execution profile, backend and capability class, precision policy, shader or
kernel identity and relevant environment version. Its parameter digest has no
registered canonical parameter projection. Its input roles and zero-input
generator semantics are unstated. The existing `SemanticVersion` additionally
preserves build metadata in coding while excluding it from ordinary equality
and hashing, so synthesising equality for a persistent derivation record would
collapse records whose encoded fields differ.

Proposed `ADR-0036` corrects the logical `ContentID` record and registers one
domain-separated SHA-256 projection, but only for the exact complete `VCMJ-1`
metadata record. That digest has scope `serialisedObject`. It is not an image
`descriptorAndSamples` digest, a storage checksum, a canonical operation-
parameter digest or a derivation-record identifier. `ADR-0036` is itself
Proposed and depends on the Proposed metadata chain.

A further distinction is security-critical. A well-shaped `ContentID`, a
source record's optional `contentID`, an object-store key, a provenance field
or a content-addressed URL is a **claim**. Decoding or receiving it does not
prove that the corresponding bytes were read, that the source is immutable,
that a remote party is authentic, or that the claimed scope and projection
match the object. A serialised `trusted: true` flag would merely create a
forgeable claim about a claim.

Identity is also not authorisation. Source locators and digests may themselves
be sensitive. None of these records grants permission to log, export, compare
across tenants or privacy domains, resolve a schema, de-identify data, or treat
an unkeyed digest as a MAC or signature.

This proposal closes the conceptual state and admission rules needed before a
public record can be reviewed. It deliberately does not approve product source
while `ADR-0036`, the required projections, exact identifier profiles and the
execution/cache contracts remain unresolved.

## Decision

If accepted, the controlled MTA sentence will be interpreted and corrected to
say:

> Every immutable data object shall have a stable data identity. A data
> identity contains object identity plus at least one content, source or
> derivation claim. Full-content identity exists only after an accepted
> content projection has been generated or verified.

Acceptance also requires controlled Requirements Baseline correction.
`VOX-RGN-007` will require a stable content, source **or** derivation claim
suitable for the admitted cache/provenance purpose. `VOX-RGN-008` will state
that a versioned source may support provisional data identity under explicit
host trust policy, while a full logical-content projection binds accepted data
bytes, descriptor semantics and every relevant transform. A source locator by
itself never becomes a full-content digest.

`VoxeliaCore` will own immutable identity claim values. Verification evidence,
trust policy, lazy work coordination, cache admission and publication are
separate responsibilities and are not inferred from the values.

### Identity vocabulary

The following terms are normative for this decision:

- **object identity** identifies one immutable Voxelia object instance or
  published record. It does not establish content equality;
- **content claim** is a structurally valid `ContentID` tuple supplied or
  computed for an asserted projection. Presence does not establish assurance;
- **source claim** names an external or generated source and optional version,
  and may carry a content claim whose scope is the source object;
- **derivation claim** records how an object is asserted to have been produced;
- **assurance evidence** is host-validated runtime evidence, not decoded from
  the identity claim record, that the host accepts for a stated purpose,
  snapshot and policy context; and
- **cache admission** is an owning cache's explicit decision that a claim plus
  assurance and execution context is sufficient for a particular cache scope.

The unqualified phrase “verified `ContentID` value” must not be used. The value
is a claim; verification is evidence associated with an exact claim and object
snapshot.

### Closed `DataIdentity` state model

Let `C` mean a present top-level content claim, `S` a non-empty source array and
`D` a present derivation claim. `objectID` is always required.

| C | S | D | Structural state | Validity and authority |
|---|---|---|---|---|
| 0 | 0 | 0 | object only | Invalid as a published `DataIdentity`; object identity alone does not satisfy the controlled lineage rule. |
| 0 | 1 | 0 | source only | Valid provisional claim record; no content or cache assurance is implied. |
| 0 | 0 | 1 | derivation only | Valid lineage record; determinism and input assurance are not implied. |
| 0 | 1 | 1 | mixed lineage | Valid record preserving source and derivation claims; the combination grants no additional trust. |
| 1 | 0 | 0 | content only | Valid content-claim record; decoding or construction does not verify it. |
| 1 | 1 | 0 | content plus source | Valid claim with source lineage. Source and top-level content scopes may differ. |
| 1 | 0 | 1 | content plus derivation | Valid claim with derivation lineage. |
| 1 | 1 | 1 | content plus mixed lineage | Valid claim with both lineage forms. |

Source-only validity is structural and provisional. It does not by itself
satisfy the M2 cache/provenance behavior in corrected `VOX-RGN-007`; that
requires a purpose-specific host attestation for the exact versioned source or
later content/derivation assurance.

Mixed lineage is retained because the controlled aggregate explicitly carries
both fields and an imported result may preserve technical source lineage while
also recording a Voxelia derivation. It is not evidence that the derivation
consumed every listed source directly. Immediate input roles belong to the
derivation record and complete ancestry belongs to provenance. A future
controlled correction may narrow this after real import and graph evidence;
implementations must not silently discard one lineage form now.

This table defines structural completeness only. It does not contain a
`verified`, `trusted`, `cacheable` or `complete` Boolean. Those properties
depend on purpose, snapshot and policy and therefore cannot be safely encoded
as intrinsic facts on the claim value.

### Source identity invariants

`SourceIdentity` remains the four-field controlled record, subject to these
rules before construction or decoding can be authorised:

1. `namespace` and `identifier` are non-empty, non-blank, bounded opaque
   strings. A present `version` is likewise non-empty and non-blank. Exact byte
   ceilings and an allowed-character profile require a controlled correction;
   no public initializer is authorised without them.
2. Accepted spelling is preserved. There is no case folding, Unicode
   normalisation, URI resolution, filesystem standardisation, DICOM
   canonicalisation or namespace aliasing.
3. The source-locator key is the exact accepted UTF-8 tuple
   `(namespace, identifier, version)`, with `nil` distinct from any present
   version. This explicit byte identity is not Swift `String.==`.
4. Within one `DataIdentity`, repeated locator keys are rejected. An exact
   repeated record is redundant; the same locator carrying two different
   content claims is a conflict. Neither case is silently deduplicated or made
   last-write-wins.
5. Accepted source order is preserved and participates in exact record
   equality. It is lineage record order only. Acquisition order, spatial order
   and display order require separately named fields such as the CT import
   contract's `sourceOrder` and `spatialOrder`.
6. `SourceIdentity.contentID` is an optional source-content claim. It can cover
   `storageObject` or `compressedRepresentation` while the top-level content
   claim covers a future `descriptorAndSamples` projection. Different scopes
   are not compared, substituted or treated as a mismatch.

An identifier being globally unique within its source system does not make the
source authentic or immutable. Namespace strings, DICOM UIDs, paths, URLs,
object-store keys and digest-shaped names never establish trust by themselves.

### Derivation identity invariants and deferral

A derivation record is a semantic recipe and provenance claim, not an
execution-cache key. Its future corrected contract must provide:

- a bounded, exact operation identifier and semantic operation version;
- a separately identified exact implementation version when implementation
  behavior affects the output;
- a registered, versioned canonical parameter projection whose digest binds
  every output-affecting semantic parameter;
- a positional input sequence with operation-defined roles;
- preservation of repeated inputs when multiplicity or roles make them
  meaningful;
- explicit permission for an empty input sequence only for a declared
  zero-input generator; and
- exact record comparison that includes every stored version field, including
  `SemanticVersion.buildMetadata`, even though ordinary semantic-version
  precedence equality excludes build metadata.

The `org.voxelia.metadata-complete-record` projection from proposed
`ADR-0036` must be rejected for `parameterDigest`; it identifies a different
domain. No parameter or derivation-record projection is registered here.

Derivation determinism is runtime capability evidence, not a property inferred
from a record. Even a well-formed claim is not cache-admissible until the
selected implementation declares determinism for the exact execution profile
and every input has independently sufficient assurance.

The displayed `DerivationIdentity` public shape is therefore deferred. It may
not be implemented by filling the missing cache dimensions into ad hoc strings
or by treating Foundation/Swift `Codable` output as canonical bytes.

### Non-recursive `DataIdentityReference`

`DataIdentityReference` will be a closed, explicitly tagged and bounded
non-recursive reference. Its intended semantic cases are:

```swift
public enum DataIdentityReference: Sendable, Hashable, Codable {
    case object(DataObjectID)
    case content(ContentID)
    case source(SourceIdentity)
    case derivation(DerivationRecordID)
}
```

This is a logical target, not an authorised declaration. `DerivationRecordID`
does not yet exist and requires its own registered canonical projection. Exact
one-of wire coding, aggregate limits and case-specific resolution rules also
remain open.

The cases have deliberately different authority:

- `.object` names a local or explicitly resolved immutable record. It is not a
  persistent or distributed cache key;
- `.content` is a content claim until associated assurance verifies that exact
  tuple;
- `.source` is admissible only under explicit host source policy; and
- `.derivation` identifies a canonical derivation record but does not by itself
  prove determinism or verify its inputs.

The reference must not recursively embed `DataIdentity` or
`DerivationIdentity`. Recursive embedding would permit cycles, unbounded
decode work and amplification. No initializer may silently choose a “best”
case, and a consumer must switch exhaustively on the explicit tag.

### Equality and persistent identity

Ordinary `DataIdentity` equality means exact record equality: object claim,
content claim, ordered source records and derivation claim. It does not mean
same object, verified same content, same source locator, same semantic recipe
or same provenance graph. Those comparisons must be separately named.

Two exact records may be unequal while their independently verified content is
equal. Conversely, equal decoded claim records remain untrusted until admitted.
Swift `Hasher` output is process-randomised and must never be persisted,
distributed or used as a content or derivation identifier.

The existing `DataObjectID` uses Swift `String` equality and rejects only blank
input. Canonically equivalent Unicode spellings can therefore compare equal
despite different UTF-8 bytes, and no resource ceiling is selected. That is an
explicit blocker to persistent exact reference coding; this ADR does not
retroactively change the implemented leaf.

### Assurance is runtime evidence

Assurance is maintained outside the Codable identity records. At minimum, an
admission decision distinguishes:

1. **generated content**: trusted code generated the claim from an accepted
   projection over one pinned immutable logical snapshot;
2. **locally verified content**: recomputation over one pinned snapshot matched
   an expected complete content tuple; and
3. **host-attested source**: host policy authenticated and admitted an immutable
   source version for a stated purpose.

Generated or verified content evidence binds the exact object, pinned snapshot,
content tuple and tenant/privacy/security/purpose policy context. It cannot be
restamped into another context. A content-addressed cached representation may
be reused only after that representation's own bytes and current snapshot are
independently admitted inside the target policy partition; doing so does not
retroactively verify an unrelated source object that merely supplied the same
claim.

Host source attestation binds provider authority, source locator and version,
tenant/privacy/security domain, purpose, policy version, validity period and
revocation state. It is not encoded as `SourceIdentity.trusted`. A policy
change, expiry or revocation requires re-admission.

An unversioned source cannot be a persistent or distributed cache authority.
A host may admit it only to a bounded process/session cache after pinning the
exact source snapshot and accepting the risk under an explicit policy.

`VOX-RGN-008`'s phrase “data bytes or trusted source identity” is read as two
ways to establish stable data identity while work is pending. It does not
authorise hashing a namespace/identifier string and labelling the result as a
full-content digest. A source-derived key remains visibly source-keyed.

### Lazy content calculation and publication

Identity values contain no task, lock, mutable digest slot or global resolver.
Lazy work follows this state machine:

1. publish or receive an immutable source- or derivation-backed claim snapshot;
2. the owner pins one immutable logical storage/source snapshot and one exact
   registered projection;
3. Execution coordinates bounded, cancellable work; Storage supplies snapshot-
   consistent bytes or a separately scoped candidate checksum;
4. compute the complete content tuple and compare any expected claim without
   publishing intermediate state;
5. revalidate snapshot identity and generation immediately before commit; and
6. publish a new immutable identity snapshot plus its assurance as one
   coordinated commit. Only if separately accepted cache and provenance
   contracts authorise their side effects may that same staged commit also
   publish a cache alias or provenance success; digest completion alone does
   not authorise either one.

The lifecycle decision whether enrichment preserves `objectID` remains
deferred. No code may assume either answer. Maps and single-flight work must
not use `objectID` alone; a candidate work key must bind object identity,
pinned snapshot generation and projection tuple.

The isolated probe therefore injects the completion `objectID` from outside the
publisher and exercises both preservation and replacement. Those fixtures
demonstrate that publication can remain atomic under either future policy; they
do not select one.

Caller cancellation does not cancel shared work still required by another
authorised waiter. When all waiters cancel, cancellation is requested and the
worker observes it at bounded intervals. Cancellation, failure, stale
generation, source mutation, target removal or allocation failure publishes no
new identity, cache alias, integrity success or provenance success. The prior
immutable claim remains unchanged.

If expected and computed content differ, the operation fails closed with a
payload-free typed mismatch. It must not fall back to source trust, overwrite
the expected claim, attach the observed digest to the original claimed object
or use last-write-wins. The source/cache association is invalidated or
quarantined under host policy. Re-importing observed content is an explicit new
operation.

### Cache-admission boundary

`DataIdentity` has no implicit `cacheKey` and no “best available identity”
algorithm. An owning cache makes an explicit, purpose-specific admission in
this preference order:

1. a generated or locally verified complete content claim for the exact
   algorithm, scope, projection and projection version;
2. a deterministic derivation with independently verified input content
   identities and a full execution result-cache key; or
3. a versioned source identity admitted by explicit host policy.

The full execution result-cache key remains separate from
`DerivationIdentity`. MTA section 21.3 specifically requires input **content**
identities; with `VOX-CCH-004`, the key binds operation ID and semantic version,
exact implementation version, canonical parameters, verified input content
identities, execution profile, backend and capability class, precision policy,
shader or kernel version and relevant environment version. Changing any
result-affecting discriminator causes a miss. A future source/derivation input
reference would require an explicit controlled correction and equally strong
admission; this ADR does not attribute that broadening to the current MTA.
Quality and precision incompatibility cannot be overridden by equal lineage
claims.

Cache key spaces are partitioned by identity kind and the host's tenant,
privacy and security domain. Source-policy identity and version are part of
source admission, and revocation removes that authority. A `content` key can
never alias a `source` key merely because their displayed digest bytes happen
to match.

Persistent entries additionally require an independent format version, atomic
write/rename or an equivalent complete-publication primitive, corruption
detection and an independently stored output-integrity identity. A source
locator or derivation recipe can select only a candidate entry; neither can
cryptographically verify the loaded output bytes. Before publication, the
cache verifies the actual representation against a complete content tuple when
that projection is available, or against a separately scoped representation
checksum or authenticated manifest until content verification completes.
Partial or cancelled work populates neither positive nor negative results.
Promotion from an admitted source/derivation entry to a verified-content alias
is atomic. Conflicting aliases are invariant failures, not last-write-wins.

SHA-256 provides collision resistance under its stated security assumption; it
does not “detect collisions” in an absolute sense. A content-tier lookup
validates the complete content tuple, representation format, expected size and
compatible descriptor/scope before publishing a hit. A source- or derivation-
tier lookup validates its independent representation checksum or authenticated
manifest and never relabels that evidence as full-content verification.
`sampleBytes`, `storageObject`, `compressedRepresentation`,
`serialisedObject` and future `descriptorAndSamples` identities are never
interchangeable.

### Provenance, integrity and security boundaries

A provenance record preserves claims and how work was asserted to occur. Its
presence does not verify the claim or grant cache admission. This ADR does not
select the undefined `ProvenanceReference`, input-role record or graph builder.
Their later audit must avoid recursive value embedding, preserve explicit
operation roles and place cycle/resource checks in the owning graph builder;
the logical `DataIdentityReference` target here is not silent authority to
implement those provenance contracts.

Storage checksum verification, canonical logical-content verification,
authenticated source attestation, diagnostic validation and signature
verification are independent axes. This proposal records, but does not resolve,
the conflict with CDMS section 59's single `DataIntegrityState` enum. Its total
ordering cannot safely be assumed, and `failed(reason: String)` can retain
paths, source identifiers or patient information. A separate accepted
integrity decision and controlled correction must select the exact public
shape; until then no aggregate is authorised. Public failure codes in this
identity boundary remain typed and payload-free, with privileged details in
host-governed channels.

An unkeyed content digest is neither authentication nor de-identification.
MACs, authenticated cache manifests, signatures and keyed pseudonyms require
separate nominal types, domain-separated statements and host-owned key
management. They must not be encoded as `.sha256`, `.custom` or naked digest
bytes. A future signature statement must bind the complete content tuple,
relevant lineage claim, signer/key identity and policy context.

Identity values and references are treated as sensitive-derived by default.
Error descriptions, reflection, logs and ordinary cache telemetry exclude
digests, DICOM UIDs, paths, URLs, object keys and metadata. Safe correlation
uses host-controlled opaque event identifiers.

### Ownership and milestone interpretation

- `VoxeliaCore` owns immutable claim values, registered content projections and
  payload-free common errors;
- `VoxeliaStorage` owns snapshot-consistent reads, storage checksums and
  storage/cache representation integrity;
- `VoxeliaExecution` owns work scheduling, single-flight coordination,
  cancellation, generation checks, determinism evidence, result-cache keys and
  result publication; and
- the host owns source authentication, tenant/privacy policy, credentials,
  revocation, export authority and key management.

M1 may design and, after acceptance, declare cycle-free identity value records.
The cache- and provenance-suitability requirements in `VOX-RGN-007` and
`VOX-RGN-008` remain M2 behavioral obligations. A declaration at M1 cannot be
reported as completion of those M2 requirements.

### Source gate

This ADR is Proposed and authorises documentation plus isolated evidence only.
It authorises no `SourceIdentity`, `DerivationIdentity`, `DataIdentity`,
`DataIdentityReference`, trust, cache or lazy-digest production source.

Before any identity value source is added:

1. `ADR-0036`, this ADR and their required value dependencies must be accepted
   or superseded;
2. the public API/data-model RFC, controlled MTA/CDMS/Requirements corrections
   and required maintainer approvals must complete;
3. each exact bounded source, operation or implementation identifier profile
   actually stored by that declaration must be approved;
4. `DataObjectID` exact persistent identity and byte ceiling must be resolved
   before `DataIdentity` or an object-reference case is declared;
5. every projection used by the value being implemented must be registered;
6. `DataIdentityReference` lifecycle, exact tagged wire and aggregate limits
   must be approved before that reference or a dependent derivation is added;
   and
7. identity enrichment and `objectID` lifecycle must be decided before lazy
   enrichment source is added.

Before a lazy resolver or verifier is added, its exact projection,
snapshot/lifecycle rules and Core/Storage/Execution ownership contract must be
accepted, with focused strict-concurrency, cancellation, source-mutation,
fault-injection and supported-device resource evidence.

Before result-cache integration is added, the complete derivation/execution
cache-key split and owning Storage/Execution cache contracts must be accepted.
A persistent cache additionally requires independent format, atomicity,
corruption and output-integrity evidence.

Before provenance integration is added, the separate reference, role, graph,
resource and publication contract must be accepted. Before any aggregate
integrity state is added, the separate CDMS section 59 correction must be
accepted. These later behavioral gates do not silently block an unrelated,
otherwise accepted M1 value declaration, and an M1 declaration does not
satisfy them.

## Alternatives considered

### Require a full content digest before any object exists

Rejected. It contradicts the controlled lazy-identity and remote-source rules,
can require an unbounded eager read of large data and would prevent useful
source- or derivation-backed provenance while validation is pending.

### Treat any present `ContentID` as verified

Rejected. Decoders and remote sources can construct claims. Structural
validity proves neither byte coverage nor authenticity and would permit cache
poisoning.

### Add `trusted` or `verified` Booleans to Codable identity records

Rejected. Those flags are forgeable, lose policy/snapshot/purpose context and
become stale under revocation or source mutation.

### Hash a trusted source locator and expose it as content identity

Rejected. This hides the identity kind and falsely claims byte or semantic
coverage. Source-keyed cache admission remains explicitly source-keyed.

### Use `DerivationIdentity` directly as the result-cache key

Rejected. The controlled record omits result-affecting implementation,
precision, backend, shader/kernel and environment dimensions and has no
canonical parameter projection.

### Recursively embed complete identities in derivation inputs

Rejected. It permits cycles and unbounded encoded graphs. References are
closed, tagged and non-recursive; provenance graph resolution owns cycle and
resource checks.

### Sort source identities or silently deduplicate them

Rejected for this record generation. Sorting would invent order-insensitive
semantic identity, while silent deduplication would conceal conflicts. Exact
input order is retained and duplicate locator keys fail construction.

### Reject every source-plus-derivation record

Rejected for now. The controlled aggregate permits both and real imported
derived data can preserve both forms of lineage. The combination remains a
claim only and does not replace immediate derivation inputs or provenance.

### Implement the records now and add verification later

Rejected. Public `Codable`/`Hashable` records without closed construction,
reference and authority rules would create persistent compatibility and
security obligations that the controlled documents do not yet satisfy.

## Consequences

- Lazy remote and derived data can have structurally valid identity without
  pretending a full digest exists.
- Content claims, assurance, cache admission and authorisation become separate
  concepts with explicit owners.
- Existing controlled sketches require correction before product source.
- A future implementation needs more types than the three displayed records,
  including registered parameter/derivation projections and runtime admission
  evidence.
- Source and derivation records remain useful for provenance even when no cache
  admits them.
- Callers must request named comparisons instead of relying on aggregate
  equality for every identity question.

## Affected modules

- `VoxeliaCore`: identity claims, exact references, projections and common
  errors after the source gate closes.
- `VoxeliaStorage`: pinned snapshot reads and representation integrity.
- `VoxeliaExecution`: lazy work, determinism, cache keys, cancellation and
  atomic publication.
- Adapter modules: source claims without embedded trust or credentials.
- Host applications: source authentication, tenancy/privacy policy,
  revocation, disclosure and key management.

No module dependency edge changes in this proposal.

## Compatibility impact

The proposal corrects the MTA's absolute content-identity sentence, supplies
the missing state semantics and requires correction of the displayed
derivation/reference sketches before they become API. No shipped public source
changes because the affected aggregates do not exist.

Future wire formats must use an explicit versioned one-of reference tag,
explicit presence/null rules, strict unknown/missing/duplicate-field rejection
and bounded iterative ingress. Ordinary `Codable` bytes are not canonical
digest bytes.

## Security impact

The decision prevents untrusted digest and source claims from becoming cache
authority by shape alone. It requires policy-domain partitioning, revocation,
snapshot pinning, fail-closed mismatch handling and zero publication on
cancellation or failure. It also keeps credentials, authenticity, signatures,
de-identification and export permission outside Core claim records.

Identity-bearing diagnostics and telemetry are redacted by default. Exact
source locators and digests may disclose patient, dataset, tenant or equality
information and are not harmless identifiers.

## Performance and memory impact

Lazy calculation avoids mandatory eager scans. The future worker must stream
bounded chunks, use checked byte counts, observe cancellation at a documented
cadence and pin exactly one logical snapshot without an unnecessary second
full-sample allocation.

Single-flight coordination may share one computation across waiters, but the
work key must include snapshot and projection identity. Caches remain bounded
and use independently versioned persistent formats. This decision selects no
chunk size, memory ceiling or eviction algorithm; those require supported-
device evidence.

## Validation impact

Focused isolated evidence for this proposal covers:

- all eight `C/S/D` combinations, rejecting only the object-only state;
- content-claim presence remaining orthogonal to verification;
- duplicate and conflicting source locator rejection without normalisation;
- ordered source and derivation-input identity, repeated derivation inputs and
  permitted declared zero-input generators;
- distinct source and top-level content scopes;
- exact derivation comparison when semantic versions differ only in build
  metadata;
- exhaustive non-recursive reference tags and object-only cache rejection;
- execution-key inequality and derivation-admission denial when any required
  execution or policy discriminator changes;
- lazy success publishing once under both externally selected object-ID
  lifecycle fixtures, with cache/provenance counters changing only under
  separately injected authorisation, and cancellation, failure, existing-claim
  mismatch or stale generation publishing nothing;
- payload-free error descriptions and reflection-safe records; and
- strict Swift 6 concurrency checking for the isolated publication model.

Acceptance of lazy resolver, verification or cache integration additionally
requires adversarial raw-ingress tests, source mutation during hashing,
partial- and all-waiter cancellation, cancellation storms, priority changes,
process restart, policy expiry/revocation, corrupted and torn cache entries,
conflicting aliases, fault injection, memory pressure and the supported-device
evidence listed in the integration gate. These later behavioral tests are not
represented as evidence for a value-only declaration.

## Migration

1. Review this proposal with Core, Storage, Execution, Security and Validation
   maintainers.
2. Complete the public API/data-model RFC and required maintainer approvals.
3. Reconcile the controlled MTA, CDMS and Requirements Baseline wording and
   displayed records, while keeping the separate integrity-state correction
   explicitly blocked.
4. Resolve or supersede the `ADR-0036` dependency chain.
5. Register parameter, derivation-record and future image projections without
   reusing the complete VCMJ record projection.
6. Approve exact identifier, reference, lifecycle and cache-key contracts.
7. Implement leaf records with narrow construction/Codable/equality tests.
8. Implement lazy verification and cache admission with concurrency and fault
   evidence at M2.

Until those steps complete, retain the current declaration leaves and do not
add the blocked aggregate source.

## Supersession

This ADR does not supersede an accepted decision. If accepted, it refines
proposed `ADR-0036` downstream and supplies the proposed correction for MTA
section 11.3, CDMS sections 32.5 and 33 and Requirements `VOX-RGN-007`/
`VOX-RGN-008`. It records but does not select the CDMS section 59 correction.
A later accepted identity-lifecycle, derivation-projection, integrity or cache-
format decision may refine the explicitly deferred areas without changing the
claim-versus-assurance separation.

## References

- [ADR-0036 - Domain-separated complete canonical metadata record identity](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [Core Data Model Specification sections 5.7-5.8, 32-33, 47-48, 57 and 59](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Master Technical Architecture sections 11.3, 15.6, 19.4, 19.8, 20.5 and 21.3-21.5](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Requirements Baseline `VOX-RGN-007`-`009`, `VOX-CON-007` and `VOX-CCH-004`-`008`](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Validation and Benchmark Strategy identity and concurrency evidence](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0037 closed-state probe](../../progress/evidence/ADR-0037-data-identity-cache-admission-probe.swift)

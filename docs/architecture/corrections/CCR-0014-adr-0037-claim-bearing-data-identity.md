# CCR-0014 - Controlled correction for ADR-0037 claim-bearing data identity

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0014` |
| Authority | Accepted [`ADR-0037`](../decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md) |
| Approved by | Project owner |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction required by accepted `ADR-0037`. The
`v0.1.1` baseline files remain immutable and unedited; wherever a statement
quoted below conflicts with this record, this record is authoritative for
implementation, traceability and review. A future coordinated `v0.1.2`
revision set shall incorporate the corrected text verbatim. This correction
authorises no identity value source: the accepted decision's source gate
remains closed until its enumerated prerequisites receive their own
decisions.

## Corrections

### CCR-0014-A - Master Technical Architecture section 11.3 identity rule

Target: `docs/project/Voxelia_Master_Technical_Architecture_v0.1.1.md`,
section 11.3 content identity.

The baseline sentence reads:

> Every immutable data object shall have a content identity.

The corrected sentence reads:

> Every immutable data object shall have a stable data identity. A data
> identity contains object identity plus at least one content, source or
> derivation claim. Full-content identity exists only after an accepted
> content projection has been generated or verified.

The corrected section additionally records the normative vocabulary: a
structurally valid `ContentID` tuple is a **claim** whose presence never
establishes assurance; **assurance evidence** is host-validated runtime
evidence bound to an exact object, pinned snapshot, content tuple and
tenant/privacy/security/purpose policy context, held outside the Codable
identity records; and **cache admission** is an owning cache's explicit,
purpose-specific decision. The unqualified phrase "verified `ContentID`
value" must not be used. No `verified`, `trusted`, `cacheable` or
`complete` Boolean may be encoded on a claim value.

### CCR-0014-B - Core Data Model Specification sections 32.5 and 33 states

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
sections 32.5 lazy content identity and 33 source and derivation identity.

The corrected reading binds the displayed records to the accepted closed
`C/S/D` state model: `objectID` is always required; of the eight
content/source/derivation combinations only the object-only state is
invalid as a published `DataIdentity`; source-only records are valid but
provisional and satisfy no cache or provenance behaviour by themselves;
and mixed source-plus-derivation lineage is retained as claims without
additional trust. `SourceIdentity` construction requires the accepted
invariants: non-blank bounded opaque fields with exact accepted spelling,
the exact UTF-8 `(namespace, identifier, version)` locator key with `nil`
distinct from any present version, rejection of repeated locator keys
within one record (redundant or conflicting, never silently deduplicated
or last-write-wins), preserved accepted source order as lineage record
order only, and source-content claims whose scopes are never compared with
or substituted for the top-level content claim. Lazy completion follows
the accepted publication state machine: pinned snapshot and projection,
no intermediate publication, revalidation before commit, one coordinated
atomic commit, and fail-closed payload-free mismatch handling with no
fallback to source trust.

### CCR-0014-C - Deferred derivation and reference sketches

Target: `docs/project/Voxelia_Core_Data_Model_Specification_v0.1.1.md`,
sections 33.2 and 33.3 displayed records.

The displayed `DerivationIdentity` sketch is recorded as a semantic recipe
claim, not the execution result-cache key, and is deferred: its corrected
contract must add the exact implementation version, a registered versioned
canonical parameter projection (for which the
`org.voxelia.metadata-complete-record` projection must be rejected),
positional input roles, repeated-input preservation, declared zero-input
generators and exact comparison including `SemanticVersion.buildMetadata`.
The undeclared `DataIdentityReference` is recorded as a closed, explicitly
tagged, bounded and non-recursive reference whose `DerivationRecordID`
case target does not yet exist. Neither record may be implemented by
filling missing dimensions into ad hoc strings or by treating ordinary
`Codable` bytes as canonical. The `DataObjectID` leaf's Swift-`String`
equality and missing byte ceiling are recorded as an explicit blocker to
persistent exact reference coding.

### CCR-0014-D - Requirements Baseline VOX-RGN-007 and VOX-RGN-008 readings

Target: `docs/project/Voxelia_Requirements_Baseline_v0.1.1.md`, rows
`VOX-RGN-007` and `VOX-RGN-008`.

The corrected `VOX-RGN-007` reading requires a stable content, source
**or** derivation claim suitable for the admitted cache/provenance
purpose; source-only validity is structural, and the cache/provenance
suitability obligations remain M2 behavioural requirements that an M1
declaration cannot report as complete. The corrected `VOX-RGN-008`
reading states that a versioned source may support provisional data
identity under explicit host trust policy, while a full logical-content
projection binds accepted data bytes, descriptor semantics and every
relevant transform; a source locator by itself never becomes a
full-content digest, and hashing a namespace/identifier string must never
be labelled a full-content digest.

### CCR-0014-E - Cache-admission boundary

Target: `docs/project/Voxelia_Master_Technical_Architecture_v0.1.1.md`,
sections 21.3 through 21.5 cache interpretation.

The corrected reading records the accepted admission order — a generated
or locally verified complete content claim for the exact tuple, then a
deterministic derivation with independently verified input content
identities and the full execution result-cache key (operation ID and
semantic version, exact implementation version, canonical parameters,
verified input content identities, execution profile, backend and
capability class, precision policy, shader or kernel version and relevant
environment version), then a versioned source admitted by explicit host
policy — with cache key spaces partitioned by identity kind and the
host's tenant, privacy and security domain, content keys never aliasing
source keys, persistent entries requiring independent format versioning,
atomic publication, corruption detection and independently stored output
integrity, and scope tuples never interchangeable across `sampleBytes`,
`storageObject`, `compressedRepresentation`, `serialisedObject` and
future `descriptorAndSamples` identities.

## Scope and limits

- This correction resolves conceptual boundaries and controlled wording
  only; the CDMS section 59 `DataIntegrityState` conflict is recorded but
  deliberately unresolved, and no aggregate integrity state is authorised.
- No `SourceIdentity`, `DerivationIdentity`, `DataIdentity`,
  `DataIdentityReference`, trust, cache or lazy-digest production source
  is authorised; the accepted source gate's enumerated prerequisites
  (identifier profiles, `DataObjectID` resolution, reference lifecycle,
  registered projections, `objectID` enrichment lifecycle and the
  execution/cache contracts) each require their own future decisions.
- Identity values and references remain sensitive-derived by default;
  digests, DICOM UIDs, paths, URLs and object keys stay out of logs,
  telemetry and error descriptions.
- This record grants no authority beyond the corrections above: it does
  not accept any other Proposed ADR or RFC, alter any requirement row
  text beyond the recorded readings, or authorise source outside the
  accepted `ADR-0037` documentation boundary.

## References

- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](../decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](../decisions/ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [CCR-0013 - Content identifier record correction](CCR-0013-adr-0036-content-identifier-record.md)
- [Voxelia Master Technical Architecture v0.1.1, sections 11.3 and 21.3 through 21.5](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1, sections 32 and 33](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, VOX-RGN-007 and VOX-RGN-008](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

---
document_id: "RFC-0001"
title: "Storage contract and logical data-model composition"
status: "Draft"
date: "2026-08-03"
authors:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-003"
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-GOV-009"
  - "VOX-GOV-010"
  - "VOX-PLT-008"
  - "VOX-PLT-009"
  - "VOX-REP-010"
  - "VOX-ARC-001"
  - "VOX-ARC-003"
  - "VOX-ARC-004"
  - "VOX-ARC-005"
  - "VOX-ARC-007"
  - "VOX-ARC-011"
  - "VOX-ARC-012"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-API-005"
  - "VOX-API-007"
  - "VOX-API-010"
  - "VOX-API-011"
  - "VOX-DAT-001"
  - "VOX-DAT-004"
  - "VOX-DAT-009"
  - "VOX-DAT-010"
  - "VOX-DAT-011"
  - "VOX-DAT-012"
  - "VOX-DAT-013"
  - "VOX-DAT-014"
  - "VOX-DAT-015"
  - "VOX-RGN-001"
  - "VOX-RGN-002"
  - "VOX-RGN-003"
  - "VOX-RGN-004"
  - "VOX-RGN-006"
  - "VOX-RGN-007"
  - "VOX-RGN-008"
  - "VOX-STO-001"
  - "VOX-STO-002"
  - "VOX-STO-003"
  - "VOX-STO-004"
  - "VOX-STO-005"
  - "VOX-STO-006"
  - "VOX-STO-007"
  - "VOX-STO-008"
  - "VOX-STO-009"
  - "VOX-STO-010"
  - "VOX-STO-011"
  - "VOX-STO-012"
  - "VOX-BRK-002"
  - "VOX-BRK-005"
  - "VOX-EXE-007"
  - "VOX-EXE-009"
  - "VOX-CON-001"
  - "VOX-CON-003"
  - "VOX-CON-006"
  - "VOX-CON-007"
  - "VOX-CON-009"
  - "VOX-CON-010"
  - "VOX-ERR-001"
  - "VOX-ERR-002"
  - "VOX-ERR-003"
  - "VOX-ERR-007"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
  - "VOX-SEC-006"
  - "VOX-SEC-011"
  - "VOX-VAL-007"
  - "VOX-VAL-011"
  - "VOX-VAL-016"
  - "VOX-PER-007"
  - "VOX-PER-008"
  - "VOX-META-001"
  - "VOX-META-002"
  - "VOX-META-011"
  - "VOX-IMG-001"
  - "VOX-IMG-002"
  - "VOX-IMG-009"
  - "VOX-IMG-015"
  - "VOX-DCM-003"
  - "VOX-DCM-005"
  - "VOX-DCM-006"
  - "VOX-DCM-008"
  - "VOX-DCM-010"
  - "VOX-DCM-013"
  - "VOX-DOC-008"
  - "VOX-DOC-009"
  - "VOX-DOC-010"
  - "VOX-VS1-005"
  - "VOX-VS1-006"
  - "VOX-VS1-008"
  - "VOX-VS1-014"
  - "VOX-VS1-017"
  - "VOX-VS1-018"
  - "VOX-VS1-019"
  - "VOX-VS1-020"
---

# RFC-0001 - Storage contract and logical data-model composition

## Decision status

This RFC is a **Draft** for architecture, Core, Storage, Execution, Metal,
validation, security, privacy and memory-lifetime review. It composes three
Proposed ADRs for review; it does not accept them, revise a controlled document,
record maintainer approval or authorise product source.

The current controlled documents and accepted ADRs remain authoritative. RFC
acceptance would approve only the directional composition and selected mapped-
storage schedule; it would not make a controlled correction or ADR effective
and would not authorise source. A Draft-to-Accepted status change must record
reviewers, the selected schedule, the proposed correction owners/revisions and
the exact Proposed ADR revisions to be reconciled. Those corrections and ADRs
must then be approved through their own processes. Absence of an objection is
not approval.

The front-matter requirement list is the traceability union of the composed
proposals and their directly discussed downstream contracts. Inclusion records
impact only; it does not expand source scope, milestone completion or diagnostic
status.

## Summary

Voxelia needs one coherent public review boundary for the storage contract and
the logical data model that storage serves. This draft composes:

- proposed `ADR-0039`, which separates backend-neutral Core contracts from
  concrete Storage providers and replaces mixed capability claims with exact
  characteristics and retained operation witnesses;
- proposed `ADR-0040`, which separates decoded logical sample identity from
  source-bit interpretation and physical representation; and
- proposed `ADR-0041`, which defines a complete owned read transaction,
  checked type erasure, cancellation/commit linearisation and owner-retaining
  scoped byte access.

If the complete package is accepted, `VoxeliaCore` will own backend-neutral
descriptor, snapshot, read, lease, error and erasure contracts plus private
result-target admission/adoption; `VoxeliaStorage` will own concrete providers,
owners, source/mapping allocations, I/O and resource release;
`VoxeliaExecution` or an explicit host/import coordinator will own coherent
`ImageData` publication; and `VoxeliaMetal` will own dynamic per-device
residency. The package graph will not change.

This draft intentionally does not freeze public Swift names, canonical wires,
production resource limits or an unsafe/no-copy implementation. It also does
not settle the controlled M1-versus-Phase-5 memory-mapping conflict. Those are
approval gates, not implementation details.

## Motivation

The controlled baseline currently contains mutually incompatible sketches:

- the Master Technical Architecture assigns storage protocols and type erasure
  to Core and concrete implementations to Storage, while the Core Data Model
  Specification assigns descriptors, capabilities, erasure and region reading
  to Storage;
- `ImageData` is Core-owned but contains `AnyImageStorage`; implementing a
  Storage-owned erased type would require the prohibited `Core -> Storage`
  dependency or duplicate contract families;
- a raw capability `OptionSet` mixes immutable representation facts, optional
  callable operations, locality, mapping, mutability and dynamic residency;
- the displayed read destination carries a mutable unsafe buffer through an
  asynchronous method without a complete ownership, cancellation or
  publication contract;
- logical descriptors include source/physical byte order, valid-bit and
  component-layout fields even though logical equality and content identity are
  required to be independent of physical representation; and
- the Foundation schedules memory-mapped storage in Phase 5, while
  `VOX-STO-004` requires an implementation at M1 and the MTA implementation
  sequence and proposed `ADR-0039` also place mapped storage in the early
  storage stage.

These are architecture and public-contract questions, so `VOX-GOV-005` and
`VOX-GOV-006` require ADR and RFC review before implementation. A convenient
first type or passing toy probe cannot resolve the contradictions.

## Scope

### Included

This RFC proposes one reviewable composition for:

- module ownership and the unchanged dependency direction;
- the boundary between logical sample semantics and physical representation;
- immutable snapshot/provider authority and exact operation admission;
- complete bounded region reads and committed owned results;
- cancellation, invalidation, replay and stale-generation behaviour;
- checked type erasure and owner-retaining contiguous/mapped byte scopes;
- separation of representation integrity, logical identity, provenance,
  publication, residency and diagnostic assurance;
- compatibility and pre-1.0 migration of existing declaration-only leaves;
- a complete controlled-document correction inventory;
- the unresolved memory-mapped milestone decision and its safe options; and
- the evidence and approval gates that must precede source.

### Excluded

This RFC does not define or authorise:

- final public Swift type, member, operation or error names;
- a canonical storage, descriptor, identity or capability wire;
- a complete canonical `ImageDescriptor` projection;
- general component-role, colour-space, pixel-padding or value-transform
  identity;
- persistent `ContentID`, `DataIdentity`, metadata or provenance source;
- `ImageData` construction or publication source;
- mutable storage, builders, writable leases or transactional editing;
- real file descriptors, VM mapping, raw pointers, custom lifetime attributes,
  no-copy ownership bridges or allocator implementations;
- tiled, bricked, compressed, multi-resolution, callback, remote or sequential
  provider source;
- integrity verification, authentication, signatures, transport, credentials,
  cache policy or secure deletion;
- Metal resources or residency; or
- diagnostic-ready status for any storage capability.

## Governing authority and composition rules

The Foundation is the highest project-specific authority. The MTA governs
technical architecture; Requirements, RPSS, CDMS and FVSP govern their allocated
scopes. An accepted ADR may resolve a lower-level discrepancy only when
consistent with the Foundation. An RFC records a reviewed proposal, decision
and approval route but does not supersede a controlled artefact by itself.

The Foundation wins any lower-level conflict unless it is formally revised.
Proposed ADRs and this Draft RFC are review artefacts, not live authority. The
composition therefore follows these rules:

- no proposal becomes accepted merely because another proposal references it;
- a controlled correction must be approved and effective before source relies
  on it;
- no package edge may be reversed to preserve a displayed sketch;
- a runtime capability claim is not completion, integrity, authorisation,
  residency or diagnostic evidence;
- a storage result is not an `ImageData` publication; and
- a focused probe proves only its stated in-memory model, not production API or
  platform behaviour.

## Proposed design

### Module ownership

If this RFC and its dependencies are accepted, ownership will be:

| Responsibility | Owner | Boundary |
|---|---|---|
| Logical sample, representation, characteristic, optional-operation, snapshot, read-result, lease, error and erasure contracts, including erasure/witness boxes | `VoxeliaCore` | Backend-neutral; imports neither Storage, Execution nor Metal. |
| Contract admission, one nonforgeable read-authority domain per admitted provider lineage and private result-target adoption | `VoxeliaCore` | Core composes authority with the exact logical binding, representation descriptor, owner, snapshot, generation and witness; it owns admitted writable logical capacity and its budget token. |
| Concrete contiguous/mapped owners, provider bases, source/mapping allocations, I/O, mapping, fill work and synchronous resource release | `VoxeliaStorage` | Implements Core witnesses; never controls Core's private result target or publishes `ImageData`. |
| Coherent storage/descriptor/identity/metadata/provenance/cache publication | `VoxeliaExecution` or an explicit host/import coordinator | Later generation-pinned bundle authority; not part of one storage read. |
| Dynamic device capability and generation-qualified residency observations | `VoxeliaMetal` with Execution coordination | Never encoded as an immutable storage bit. |
| Source translation and source-bit interpretation | Owning optional adapter, such as `VoxeliaDICOMKit` or a codec adapter | Produces explicit decoded values and representation evidence; does not redefine Core logical semantics. |
| Limits, file/transport policy, locators, credentials, authentication, authorisation and privacy | Host/application | Host policy supplies cross-provider ceilings; the final host-versus-Execution coordination/enforcement split remains unresolved. None is reusable-toolkit authority or canonical identity. |
| Purpose-specific validation and diagnostic assurance | `VoxeliaValidation` plus designated reviewers | Separate from structural admission and checksums. |

The existing dependency direction remains textual and unambiguous:

- `VoxeliaExecution` depends on `VoxeliaStorage`;
- `VoxeliaStorage` depends on `VoxeliaCore`;
- `VoxeliaCore` depends on `VoxeliaSpatial`; and
- `VoxeliaMetal` depends on `VoxeliaExecution` and `VoxeliaRendering`.

Concrete providers are implementations inside or behind `VoxeliaStorage`; they
implement Core contracts without adding another target edge.

Core owns the private result target's admission, writable logical capacity,
budget token and adoption. A safe Core allocator or separately admitted
allocation service constructs it before provider invocation; the provider never
controls it. Storage owns concrete provider bases and source/mapping allocations.
Here, **exact capacity** means exact writable logical capacity, not an assertion
about the allocator's physical footprint.

No `Core -> Storage` edge, duplicate Core/Storage contract family or Metal type
in a canonical storage contract is permitted.

### Contract layers

The contract is deliberately layered:

1. **Logical binding** states shape, exact decoded scalar type, component count
   and logical component ordinals.
2. **Representation descriptor** states exact physical addressing or an opaque
   representation, together with organisation, locality/backing, persistence,
   length, alignment and optional integrity claim.
3. **Immutable snapshot handle** binds one Core authority domain to the exact
   logical sample-layout binding, representation descriptor, retained owner,
   snapshot, generation and callable witnesses.
4. **Optional operation admission** exposes only closed operations backed by
   exact retained witnesses.
5. **Runtime result/evidence** establishes a completed read, scoped lease,
   frozen snapshot, digest observation or residency observation for its exact
   scope.
6. **Publication authority** may later assemble a coherent `ImageData` bundle
   after all independent identity, provenance, metadata and freshness checks.

No layer inherits the authority of a later layer. In particular, descriptor
equality does not establish provider equality, a digest claim is not verified
integrity, and verified representation bytes are not logical identity or
diagnostic assurance.

### Immutable authority and snapshot binding

For one Core admission of one provider lineage into one budget domain, Core
mints one nonforgeable authority object. Every handle, re-erasure and generation
derived from that admission co-retains it. Global cross-admission uniqueness is
not claimed. The provider supplies its exact logical binding, representation
descriptor, strong owner, snapshot, generation and callable witness for
composition, but neither provider nor caller can inject, clone or replace Core
authority.

An admitted handle denotes one immutable logical snapshot. A later generation
does not mutate or relabel an existing handle. Reads select one of two semantics:

| Freshness mode | Rule |
|---|---|
| Bound snapshot | The exact historical snapshot may complete while its owner remains retained. A newer generation does not make its historical bytes unsafe or relabel them as current. |
| Require current | The request carries a non-caller-mintable permit from the same Core authority. The sole current-generation install transition invalidates affected pending/prepared transactions before a newer handle is exposed as current. |

The runtime authority and source stamp are in-process values. They are not
persistent identity, provenance, authentication, signature or canonical wire.

### Characteristics, operations and evidence

The current mixed `StorageCapabilities` bag will not be the invariant-bearing
public shape. The accepted design will distinguish:

- immutable characteristics such as organisation, locality/origin, backing,
  persistence and resolution description;
- closed optional operation identifiers with exact retained witnesses;
- runtime results/evidence; and
- dynamic downstream state such as device residency.

Candidate closed cross-milestone registry categories are scoped contiguous byte
access, mapped representation access, builder acquisition, region enumeration,
native tile access, native brick access, compressed representation access,
resolution-level access, prefetch hints and scoped digest access. Listing or
reserving a category does not admit it at M1 or authorise its witness/source.
Final public names and any wire remain approval items.

No operation implies another. Mapping does not imply decoded direct bytes,
local origin, mutability, verification or residency. Prefetch does not imply
completion. A digest operation does not imply that a digest exists, is current,
was verified or proves authenticity. A bit or label without the exact admitted
witness is not callable authority.

### Descriptor admission

The representation descriptor will be tagged rather than an optional-field bag.
The initial conceptual tags are:

- decoded strided representation with checked base offset, one positive stride
  per logical axis, positive component stride, scalar container width, explicit
  byte order for persistent, external or mapped bytes, complete component
  arrangement, exact initialised length and optional alignment; and
- opaque representation with an exact typed tag and optional known initialised
  length.

Admission checks every external/wider value against `Int.max` and a stricter
host limit before conversion. Rank, extents, component counts, products, sums,
offsets, upper bounds, addressed span, lengths and alignment use checked
arithmetic before allocation or access. Decoded addressing must prove complete,
injective, non-overlapping in-bounds coverage. The first profile rejects packed
or storage-defined direct layouts without a complete tagged packing contract.
Multi-byte `.native` order is permitted only for process-local owned decoded
memory; persistence, external storage and mapping require an explicit order.

One large logical dataset is not rejected merely because it cannot fit in one
allocation. Logical size, representation length, one read and one authority's
active target/result-backing budget have independent limits. Independent copies,
provider scratch allocation and other authority domains require separate
host/Execution aggregate policy.

### Complete region-read transaction

The initial safe read profile returns one complete owned immutable result. It
does not expose a caller-owned mutable destination across suspension.

Its decoded result representation is packed interleaved, has base offset zero,
uses the admitted exact scalar and logical component layout, and has exactly the
checked expected length. Those result bytes are not automatically the canonical
logical identity byte stream. This positive-capacity profile rejects an empty
region before reservation or provider invocation; a zero-byte/no-op profile
would require separate approval.

Before provider invocation, Core validates:

- exact authority/logical-binding/representation/owner/snapshot/generation/
  witness binding;
- freshness mode and current permit where required;
- region rank, containment and checked expected logical value/byte counts;
- result layout compatibility;
- exact request-count and active-plus-retained-result byte-budget admission and
  reservation.

After the pending reservation is recorded, a safe Core allocator or separately
admitted allocation service attempts construction of one private exact-
writable-logical-capacity backing outside the gate and co-locates its byte-
budget token with that backing. Recoverable allocation failure invokes no
provider, terminalises only that transaction as allocation failure and releases
its reservation exactly once after any private allocation state is retired. On
success, the provider receives only a weak/non-owning bounded fill capability.
It does not receive the request seal, authoritative binding, backing object,
budget token or commit capability.

Fill is monotonic. Every write begins at the exact current cursor and remains
within capacity. Duplicate, overlapping, gapped, out-of-order, concurrent out-
of-order, after-close or overrun writes poison the private fill. Success requires
exact complete coverage.

The coordinator uses one state machine:

```text
unstarted -> pending
  -> prepared(internally stamped record;
              frozen owner remains in the read scope)
    -> committed(tombstone; result owns transferred byte budget)
    | cancelled(draining)
    | stale(draining)
    | failed(draining)
    | abandoned(draining)
  | cancelled(draining)
  | stale(draining)
  | failed(draining)
  | abandoned(draining)

draining -> drained(tombstone)
```

Invalid region, unsupported operation, and resource/policy-limit rejection occur
while unstarted: they create no request seal, enter no pending slot and do not
invoke the provider. The first terminal event after admission wins.
Cancellation or invalidation blocks commit immediately, but provider work and
its backing reservation remain charged until the provider drains and the
private buffer is destroyed. Late completion, foreign binding, replay,
duplicate completion and completion after a recycled tombstone publish nothing.

Pre-admission rejection and an unknown or foreign seal create no transaction
transition. A non-commit public read returns only after provider drain and
private-owner retirement.

Authority state never retains the candidate/result buffer and never invokes
provider, allocator, user callback or destructor work while its synchronisation
domain is held. Terminal tombstones are bounded and safely recyclable. The
live-byte budget ledger is independent of tombstone or transaction-slot reuse,
so a retained result releases exactly its own token after the last alias dies.

### Scoped contiguous and mapped byte access

The source-gated candidate lease shape retains an owning immutable
`Foundation.Data` value and passes that owner into a synchronous scope. The
caller derives
`Data.span` or `Data.bytes` at the use site. Voxelia does not custom-forward or
return a bare `Span`, `RawSpan`, pointer or unsafe buffer.

The final closure-result shape remains source-gated. An arbitrary escapable
generic result may copy the lent `Data` and share its backing. Byte-bearing
escape is permitted only after the concrete backing proves that every alias co-
retains the same resource and accounting token; otherwise the result must be a
proved independent copy charged to explicit caller ownership. A token held only
by an outer wrapper is insufficient.

Direct mapped access requires an immutable stable mapping snapshot for the
whole lease. An externally mutable file cannot supply an authoritative direct
view based only on before/after metadata checks. Such a provider may copy into
private staging and fail closed after revalidation, but that is not direct
mapped-lease evidence.

Every mapped scope is admitted from the exact handle's authority, logical
binding, representation descriptor, owner, snapshot and generation; none is
substitutable. It additionally binds exact file identity, mapped offset and
length, page/alignment constraints, external-change policy and a strong mapping
owner for the complete borrowed-`Data` scope.

Actual mapping, no-copy allocation and deallocator bridges remain blocked on
supported-destination builds, strict memory-safety checking, fault/pressure
evidence and independent lifetime/security review.

### Publication and residency

A committed region result carries only a coordinator-authenticated immutable
source stamp sufficient to state commit from the exact in-process runtime
binding. It is not a resource binding, persistent identity, origin/provenance,
current-generation permit or `ImageData`.

Storage may freeze an unpublished immutable snapshot and report separate
representation evidence. It does not attach metadata or provenance, assign
logical identity, claim diagnostic assurance, publish a cache alias or return
`ImageData`. Execution or an explicit host/import coordinator will later own
the one generation-pinned bundle-publication point after its dependent identity
and provenance contracts are accepted.

Metal residency is generation- and device-qualified dynamic state owned by
Metal with Execution coordination. It is never a static storage operation bit.
Compressed/mapped, decoded CPU/shared and GPU-optimised resources have
independent eviction and accounting.

### Milestone boundary

The following boundary is agreed by the proposals, except for the explicitly
unresolved mapped-provider schedule:

| Milestone | Proposed responsibility |
|---|---|
| M1 | Backend-neutral logical/representation, immutable snapshot, complete read and checked erasure contracts/evidence, plus one verified owned contiguous provider implementation subject to the listed source gates; structural storage/data-handle compatibility after dependencies are accepted. |
| M2 | Operation-wide cancellation/generation, canonical logical identity, provenance and cache/publication dependencies. |
| M3 | Metal-owned generation-qualified residency evidence. |
| M5 | Tiled, bricked, compressed and multi-resolution providers; representation integrity; independent eviction; production large-volume mapping under the Foundation schedule unless the Foundation is revised. |
| M9 | Callback, remote and sequential providers with host-owned transport/authentication. |

Memory-mapped storage is not settled by this table. The governed options are:

1. preserve the Foundation schedule by correcting `VOX-STO-004` from M1 to M5,
   treating mapped work at M1 as contract and isolated lifetime evidence only,
   retaining one verified owned contiguous implementation, and amending the MTA
   Stage-3/proposed `ADR-0039` wording accordingly; or
2. retain a production mapped provider in M1 only through a formal Foundation
   revision that moves or explicitly duplicates that deliverable, followed by
   aligned MTA, Requirements, CDMS and evidence changes.

This Draft recommends option 1 because it follows the current highest-level
authority and keeps unsafe/mapping implementation behind actual platform and
memory evidence. The recommendation is not approval. Until the option is
governed, no mapped product source is authorised.

## Public API

If accepted with the effective correction package and dependent ADRs, this RFC
would fix the following semantic roles; this Draft freezes neither semantics
nor Swift spelling. The final API review must name these categories without
weakening their invariants:

| Conceptual category | Required semantics | Still gated |
|---|---|---|
| Logical sample binding | Exact shape, decoded scalar type, component count and logical ordinals; storage-independent. | Final type names and complete descriptor projection. |
| Representation descriptor | Tagged, fully checked physical or opaque representation plus orthogonal characteristics. | Final cases, wire and production limits. |
| Snapshot handle | Immutable exact authority/provider/logical-binding/representation/owner/snapshot/generation/witness binding. | Admission factory and visibility. |
| Optional operation set | Closed admitted operations mirrored by retained witnesses. | Public names and any versioned wire. |
| Owned read result | Complete immutable bytes/layout plus non-authoritative source stamp and co-retained budget token. | Container/API spelling and alias rules. |
| Contiguous/mapped lease | Synchronous owner-retaining `Data` scope; immutable read-only view; no unaccounted byte-bearing escape. | Final closure-result shape, platform availability and real mapping evidence. |
| Checked erasure | One checked witness dispatch with typed incompatible/unsupported failure; no fallback. | Box layout and performance thresholds. |
| Typed failure | Closed payload-minimised errors for validation, limits, allocation, unsupported operation, cancellation, stale state, provider failure and contract violation. | Final hierarchy and public diagnostic context. |

Public APIs must document ownership, mutability, thread safety, freshness,
cancellation, memory cost, error precedence, unsupported cases and diagnostic
status. No caller can mint authority through public labels, raw bits, generation
numbers or booleans. This RFC authorises no Voxelia-authored
`@unchecked Sendable` conformance, experimental lifetime attribute or public
unsafe pointer.
Standard-library or Foundation conformances, including `RawSpan`'s unchecked
conformance, do not establish backing lifetime, mapping stability or task-escape
authority.

## Data and spatial semantics

Logical indices enumerate axis zero fastest, followed by increasing axes, and
components enumerate in logical ordinal order at each image index. For positive
rank `r`, extents `e[0...r-1]`, index `i` and component ordinal `c`, the exact
relations are:

```text
sampleOrdinal = i[r - 1]

for a from r - 2 down through 0:
    sampleOrdinal =
        checkedAdd(checkedMultiply(sampleOrdinal, e[a]), i[a])

valueOrdinal =
    checkedAdd(checkedMultiply(sampleOrdinal, componentCount), c)
```

For rank one, the loop is empty and `sampleOrdinal == i[0]`. The implementation
may use an equivalent checked streaming cursor. It may not depend on physical
stride order or allocation padding.

Logical scalar identity uses the exact decoded supported `ScalarType` bit
pattern in a versioned most-significant-byte-first encoding. This fixes the
sample-byte relation but does not register a complete canonical identity wire.
It does not arithmetically normalise floating signed zero, NaN payloads,
infinities or subnormals. Numeric equivalence and algorithm tolerances are
separate validation relations.

Source byte order, source valid-bit interpretation, sign/zero extension,
physical component arrangement and packing belong to source/representation
decoding. Physical allocation/row/plane padding, alignment gaps, tile halos,
compressed headers and slack are not logical samples. Uninitialised bytes enter
neither export nor digest.

Pixel padding is different: it is source-derived semantic metadata and an
operation/presentation policy. It is not allocation padding and is never
silently converted to zero, black, air or an ordinary CT value. Complete image
identity remains blocked until an accepted typed pixel-validity/padding
projection and the full descriptor projection exist.

A representation is compatible only when exact shape, decoded scalar bits,
component ordinals, bounded addressing, complete coverage and snapshot binding
are all established. A complete one-to-one physical-to-logical component map is
representation decoding. Changing the logical ordinal sequence requires an
explicit operation and new logical result. Numeric cast, saturation, signedness
reinterpretation, rescale, LUT, unit or colour-space conversion and packed-layout
guessing otherwise require an explicit operation or fail.

Representation integrity, logical sample sequence, complete descriptor-and-
samples identity and source/derivation identity use separate versioned domains.
Ordinary `Hashable`, synthesised `Codable`, raw bytes or a provider checksum are
not persistent identity.

## Concurrency

Immutable descriptors, bindings, witnesses, handles, results and lease wrappers
must be checked `Sendable`. Mutable provider, transaction, mapping and
publication state is actor-isolated or protected by a checked synchronisation
primitive with one documented domain and lock ordering.

Standard-library or Foundation unchecked conformances do not make a borrowed
byte view, backing owner or mapped resource safe to escape its admitted scope.

The Core read gate is the sole local linearisation point for cancellation,
invalidation, preparation and commit. Operation-wide cancellation propagation
and result-generation authority remain M2 Execution responsibilities under
`VOX-EXE-007` and `VOX-EXE-009`; the local read gate does not claim to implement
them.

Correctness does not depend on asynchronous `deinit`. Explicit close/cancel
owns semantic termination. Strong ownership remains acyclic, and synchronous
idempotent release occurs only after the last handle, in-flight read, private
fill owner, result alias or lease scope releases its owner/token.

Unstructured detached work is not part of the contract. A provider that does
not promptly cooperate with cancellation remains charged until drain rather
than freeing capacity for an unbounded cancellation storm.

## Storage and memory

The first owned read uses one private target with exact writable logical
capacity and fills it in place. Commit does not require a second complete
backing. Request and byte budgets cover both active transactions and caller-
retained result aliases.

Within one authority, those budgets cover active targets and aliases of
authority-owned result backing. Proved independent deep copies, unrelated
provider scratch allocations and other authority domains require aggregate host
policy; the final host-versus-Execution coordination and enforcement split
remains unresolved.

Host admission policy supplies positive ceilings for:

- rank, extents, component count and one logical region byte count;
- representation length, addressed span, alignment and allocation size;
- concurrent reads and active-plus-retained-result bytes;
- contiguous/mapped lease count and length;
- terminal bookkeeping/tombstones; and
- cancellation-observation cadence for nontrivial providers.

The policy is runtime admission context, not canonical wire or identity.
Production values must be derived from hostile-input, lowest-resource supported
Apple device, memory-pressure and recoverable-allocation-failure evidence. Probe
limits are not defaults.

No optimisation may publish prefixes, expose uninitialised bytes, validate
after access, drop owner/token retention, hide a complete copy, change logical
ordering or weaken cancellation/stale checks. The M4 vertical slice's one-full-
decoded-allocation steady-state goal remains downstream validation, not evidence
that this M1 contract already supplies a Metal bridge.

## Security

Threats include malformed dimensions/strides, arithmetic overflow, allocation
denial of service, use-after-free, externally mutable mapping TOCTOU,
cross-provider substitution, replay, stale publication, capability downgrade,
digest-scope confusion and diagnostic leakage.

The contract mitigates detectable cases through pre-allocation limits, checked
addressing, nonforgeable authority, exact retained witnesses, private staging,
one-shot terminal state, immutable mapping policy, budget retention and fail-
closed typed errors.

It does not authenticate a provider, locator, file or digest; authorise file or
network access; provide transport security; prove clinical meaning; or guarantee
denial-of-service freedom. Credentials, trust, access control, tenant/cache
partitioning and detailed privacy policy remain host-owned.

Default errors, descriptions, reflection, dumps, logs and telemetry exclude
sample bytes/values, component/source names, paths, URLs, provider/owner/file
identity, snapshot/generation values, request seals, offsets, addresses and
digests. Detailed operational context requires an explicit privacy-authorised
sink. Logical and representation digests are sensitive equality oracles and do
not de-identify image content.

Actual unsafe/no-copy/mapping code requires minimal scope, explicit ownership
and deallocation documentation, strict memory-safety compilation, hostile
fault/pressure testing, sanitiser/race evidence where supported and independent
security/lifetime review.

## Performance

Descriptor and region validation are O(rank) except a conservative stride-
separation proof may be O(rank log rank). Candidate fill and logical projection
are O(requested value count). Optional operation admission is bounded, and type
erasure adds one checked dynamic dispatch.

Logical projection may stream in canonical order with O(rank) cursor state and
bounded decode/hash buffers. It does not require a second full image. Direct
leases may avoid a copy only for a stable compatible representation after their
separate evidence gate.

Performance claims require correctness first. No shortcut may hash physical
padding as logical samples, skip or reorder values, perform implicit conversion,
weaken binding/freshness, or retain an unreported complete duplicate. Final
dispatch, allocation and cancellation-cadence thresholds remain unresolved.

## Validation

### Existing proposal evidence

The current evidence is deliberately isolated and non-production:

| Proposal | Evidence | Demonstrated scope | Explicitly not demonstrated |
|---|---|---|---|
| `ADR-0039` | [`ADR-0039-storage-capability-descriptor-admission-probe.swift`](../progress/evidence/ADR-0039-storage-capability-descriptor-admission-probe.swift) | Toy closed operation wire, exact provider/descriptor/owner/snapshot/generation witness binding, checked descriptor/layout admission, bounded complete region bytes, claim/evidence separation and actor-isolated freeze. | Product API/wire, production provider, general future-schema forwarding, unsafe/no-copy access, production limits or complete integrity/authentication. |
| `ADR-0040` | [`ADR-0040-logical-sample-projection-probe.swift`](../progress/evidence/ADR-0040-logical-sample-projection-probe.swift) | Exact logical ordering and scalar bytes across toy endian, interleaved/planar/padded representations; checked bounds and redaction. | Complete `ImageDescriptor`/content-ID wire, source decoder, pixel-padding/semantic-role closure, persistent identity, production streaming or cancellation. |
| `ADR-0041` | [`ADR-0041-storage-read-lifetime-probe.swift`](../progress/evidence/ADR-0041-storage-read-lifetime-probe.swift) | Toy Core authority, exact-capacity monotonic fill, prepare/commit/cancel/stale/drain state, independent live-budget ledger, recyclable tombstones, checked erasure, owner-retaining copied `Data` scopes and custom-returned-span negative builds. | Production admission factory, real allocator/OOM, actual file/VM mapping or complete authority/logical-binding/representation/owner/snapshot/generation/file/offset/length/alignment/change-policy/mapping-owner binding, no-copy/unsafe ownership, arbitrary provider allocation control, supported-destination matrix or OS cancellation cadence. |

The evidence does not approve the proposals. This RFC does not change any
evidenced invariant, so its Draft increment need not rerun the probes. Document,
link, register, graph/import, manifest and release-integrity checks cover the
changed surface.

Any negative lifetime gate relied upon for source must run through SIL/code
generation with `swiftc -c`; `-typecheck` alone may false-green. The matrix must
cover custom forwarding, lexical escape, escaping-closure return, `Task`,
`Task.detached`, task-group child and `async let` capture. The checked-in probe
currently proves only its documented custom-returned `Span`/`RawSpan` cases.

### Acceptance evidence required before API/source

Directional RFC acceptance requires:

- architecture, Core, Storage, Execution, Metal, API, concurrency, security,
  privacy, validation and memory-lifetime review of this exact revision;
- explicit governed selection of the mapped-storage milestone option;
- a complete correction delta with controlled owners, proposed revisions and
  approval routes;
- reconciliation of proposed `ADR-0039`'s M1 mapped-provider wording with the
  selected option;
- confirmation that the package graph remains acyclic and prohibited imports
  remain enforced;
- explicit record that final API names, wires, limits and source remain gated;
  and
- maintainer approval recorded by an RFC status change, not inferred from this
  Draft.

Before the first contract/provider source, the project additionally requires:

- accepted mutually consistent revisions of `ADR-0039` and `ADR-0040`, followed
  by accepted `ADR-0041`;
- the complete logical descriptor, component-role and pixel-padding decisions
  needed by the implemented surface;
- final public API/error names and any canonical/operational wire;
- a production nonforkable Core provider-admission factory;
- reviewed positive production limits and recoverable allocation-failure paths;
- focused Core contract/erasure/read-state tests and Storage provider/lifetime/
  fault tests;
- full-compilation negative lifetime cases for every API shape relied upon;
- strict Swift 6 concurrency and strict memory-safety builds on every supported
  Apple destination used by the surface;
- actual mapping/no-copy/fault/pressure/sanitiser/race evidence before those
  implementations are enabled; and
- privacy-redaction and typed-diagnostic validation.

Milestone acceptance remains broader. A narrow contract test cannot prove M1,
M4 or release completion, and unavailable SDK/device or human-review evidence
must remain explicitly open.

## Compatibility and migration

### Controlled correction inventory

The table below is the proposed correction package inventory. It identifies
what must be made mutually consistent; it does not edit or approve the named
controlled documents.

Gate classes are cumulative where listed:

- `A`: correction/disposition is effective before dependent ADR acceptance;
- `S`: the remaining implementation/evidence gate closes before relevant
  product source;
- `I`: the remaining identity/provenance gate closes before `ImageData`
  publication; and
- `M`: the remaining mapping gate closes before mapped product source.

| ID | Controlled artefact and current issue | Proposed correction or governed disposition | Gate |
|---|---|---|---|
| `RFC-0001-C01` | [Foundation Phase 1](../project/Voxelia_Project_Foundation_v0.1.1.md#phase-1--core-data-and-spatial-model) delivers storage abstractions, while [Phase 5](../project/Voxelia_Project_Foundation_v0.1.1.md#phase-5--compression-and-large-volume-storage) explicitly delivers memory-mapped storage. | No Foundation text change is needed for option 1: preserve M1 abstractions/contiguous implementation and M5 production mapping. Option 2 requires a formal Foundation revision before any lower-level alignment. | `A`, `M` |
| `RFC-0001-C02` | [MTA module ownership](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md#82-module-responsibilities) correctly puts protocols/erasure in Core and implementations in Storage, but [storage architecture](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md#151-storage-abstraction) and [Appendix D](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md#d1-storage-type-erasure) display the mixed capability bag and async writable destination. | Retain ownership; replace sketches with the layered descriptor, exact witness, complete owned read and checked erasure semantics. Keep final spelling in the later API freeze. | `A`, `S` |
| `RFC-0001-C03` | [MTA Stage 3](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md#stage-3--storage) lists mapped storage without distinguishing contract evidence from a production provider; [MTA §44.5](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md#445-required-components) also permits “contiguous or mapped storage” for M4. | Align both sections with the governed `C01` option. Under option 1, contiguous storage is the M4 baseline and mapped storage is available only after the mapping milestone/evidence gates. | `A`, `M` |
| `RFC-0001-C04` | [CDMS module ownership](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#6-module-ownership) and [Appendix A](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#appendix-a--core-type-inventory) assign backend-neutral descriptor/capability/protocol/erasure/read types to Storage, while Core-owned `ImageData` contains the erased handle. | Move or replace backend-neutral contract roles in Core before aggregate source; leave concrete provider/resource roles in Storage. Do not add `Core -> Storage` or duplicate types. | `A`, `S`, `I` |
| `RFC-0001-C05` | [CDMS ImageData](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#37-image-data-handle) mixes logical and physical compatibility checks and does not name publication authority. | Keep the structural data handle in Core, bind it to Core erasure, validate exact logical compatibility and reserve atomic identity/metadata/provenance/cache publication for Execution or an explicit host/import coordinator. | `A`, `S`, `I` |
| `RFC-0001-C06` | [CDMS storage descriptor](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#38-storage-descriptor) is one optional-field/kind bag that mixes logical scalar/component fields with physical layout. | Replace it through a lossless staged migration with separate logical binding, tagged representation and orthogonal characteristics; reject ambiguous old values. | `A`, `S`, `I` |
| `RFC-0001-C07` | [CDMS capabilities](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#39-storage-capabilities) use caller-mintable raw bits for operations, facts, locality and residency. | Separate closed optional operations backed by exact retained witnesses, immutable characteristics, runtime evidence and Metal-owned residency. Any wire is custom, versioned and fail-closed. | `A`, `S` |
| `RFC-0001-C08` | [CDMS storage protocol](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#40-storage-protocol) passes an unsafe mutable buffer through async code and leaves erasure exactness open. | Replace the public destination shape with the Core-private exact-capacity bounded fill and complete owned-result transaction; adopt checked single-witness erasure and owner-retaining `Data` scopes. | `A`, `S` |
| `RFC-0001-C09` | [CDMS compatibility/contiguous/mapped sections](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#41-storage-compatibility) conflate source fields with decoded logical equality and do not enforce immutable direct mapping policy. | Apply exact logical/representation compatibility, explicit source decoding and immutable-snapshot-only direct mapped access. Align mapped schedule with `C01`. | `A`, `S`, `M` |
| `RFC-0001-C10` | [CDMS builders](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#48-storage-builders-and-editing) accept metadata/provenance, create provenance and return `ImageData`; [M1 checklist](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#706-storage) repeats that publication. | Storage builder/freeze, under a separate accepted contract, returns only an unpublished immutable snapshot and representation evidence. Execution or explicit host/import authority performs coherent publication. | `A`, `S`, `I` |
| `RFC-0001-C11` | [CDMS concurrency/lifetime](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#57-concurrency-and-ownership), common errors, validation, memory and open-decision sections are too broad for the selected transaction and lease shape. | Record exact checked `Sendable`, synchronous owner retention, no async-deinit dependency, typed/redacted failures, budgets and the focused lifetime/fault matrix; keep unresolved final names honest. | `A`, `S` |
| `RFC-0001-C12` | [RPSS product/graph](../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md#11-initial-public-products) correctly fixes `Storage -> Core`, but describes Storage as owning “cache abstractions”. | Preserve every target edge and prohibited-import rule. Clarify Core owns backend-neutral contracts while Storage owns concrete storage/cache implementations and services. | `A` |
| `RFC-0001-C13` | Requirements `VOX-ARC-003`/`004`, `VOX-DAT-013`/`014`, `VOX-STO-001`/`002` and M1 wording do not fully express contract/provider, logical/representation, publication and residency separation. | Align requirements with the ownership table, storage-independent logical descriptor, Core erasure, structural-versus-coherent publication staging and Metal-owned dynamic residency. Preserve every P0 safety/correctness obligation. | `A`, `S`, `I` |
| `RFC-0001-C14` | `VOX-STO-004` requires a mapped implementation at M1, contrary to Foundation Phase 5; proposed `ADR-0039` also repeats M1 mapped storage while proposed `ADR-0041` leaves the conflict unresolved. | Select `C01` option 1 or 2 explicitly. If option 1, retarget production mapped implementation/evidence to M5 and keep only contract/lifetime evidence at M1; amend `ADR-0039` before acceptance. | `A`, `M` |
| `RFC-0001-C15` | `VOX-STO-002` treats mapping/locality/compression/residency as one capability contract, and M1 erasure/builder checklist wording can imply later runtime evidence. | Split static characteristics, optional callable operations and runtime evidence; place residency in M3, integrity/independent eviction in M5, remote/sequential work in M9, and remove builder publication from the M1 storage checklist. | `A`, `S` |
| `RFC-0001-C16` | [FVSP module participation](../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md#14-module-participation) assigns concrete storage to Storage and cancellation/publication to Execution, but its allocation path says “publish ... through `VoxeliaStorage`”. | Clarify that Storage exposes/finalises an unpublished immutable provider snapshot and the import coordinator publishes the coherent Core data bundle; preserve one-full-decoded-allocation evidence and Metal separation. | `A`, `S`, `I` |
| `RFC-0001-C17` | [`VoxeliaCore` overview](../architecture/modules/VoxeliaCore.md), [Core DocC](../../Sources/VoxeliaCore/VoxeliaCore.docc/VoxeliaCore.md), [`VoxeliaStorage` overview](../architecture/modules/VoxeliaStorage.md), [Storage DocC](../../Sources/VoxeliaStorage/VoxeliaStorage.docc/VoxeliaStorage.md), [`VoxeliaExecution` overview](../architecture/modules/VoxeliaExecution.md) and [Execution DocC](../../Sources/VoxeliaExecution/VoxeliaExecution.docc/VoxeliaExecution.md) omit or misassign backend-neutral contracts/publication. | Describe Core contract/erasure ownership, Storage concrete provider/resource ownership, Execution publication and current experimental/diagnostic status consistently. | `A`, `S` |
| `RFC-0001-C18` | Current Core `ScalarFormat`/`ComponentDescriptor` and Geometry attribute declarations embed byte order, valid bits or component layout in values later used as logical descriptors. | Introduce lossless explicit compatibility projections first; preserve every old field or fail ambiguity; deprecate/remove misplaced fields only in a documented later 0.x step with changelog and downstream Core/Geometry review. | `A`, `S`, `I` |
| `RFC-0001-C19` | [FVSP canonical CT descriptor](../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md#18-canonical-ct-image-descriptor) says the descriptor includes technical metadata and “source scalar format”, while MTA/CDMS keep metadata outside the eight-field descriptor. | Put technical metadata in `MetadataCollection`; bind the descriptor to the exact decoded scalar type; retain source byte-order/valid-bit facts in adapter representation metadata and provenance. | `A`, `S`, `I` |
| `RFC-0001-C20` | FVSP frame access allows caller destinations, owned/borrowed frames or streamed rows without one common ownership/cancellation/partial-publication contract. | Keep them as planning inputs only. Any direct final fill must use a separately accepted bounded fill/builder contract; borrowed input must be consumed/copied before owner release; no public async writable pointer. | `A`, `S`, `I` |
| `RFC-0001-C21` | `VOX-RGN-004` can be read as requiring every M1 region read to be no-copy, while the safe initial result is owned. | Clarify that region-read correctness uses complete owned output; copy avoidance is conditional through validated logical views or scoped leases when exact layout/lifetime permits it. It is not a universal success guarantee. | `A`, `S` |
| `RFC-0001-C22` | `VOX-STO-010` and the CDMS M1 checklist can imply a mutable builder implementation in this contract, while `ADR-0041` excludes builders. | Preserve explicit exclusivity/concurrency requirements for any future mutable storage, but limit this RFC's first source profile to immutable reads. Schedule builder acquisition/freeze under a separate accepted contract and remove builder-returned `ImageData`. | `A`, `S`, `I` |
| `RFC-0001-C23` | [MTA content identity](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md#113-content-identity), Requirements `VOX-RGN-007`/`008`, [CDMS content identity](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#32-content-identity) and [CDMS source/derivation identity](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md#33-source-and-derivation-identity) wording can let source identity, provider checksum, read source stamp or pending digest appear to satisfy immutable content identity. | Separate representation claims/evidence, logical sample claims, complete descriptor-and-samples identity, source/derivation claims and runtime assurance. A read source stamp is historical transaction evidence only. | `A`, `S`, `I` |
| `RFC-0001-C24` | `VOX-DAT-014` places the full descriptor/storage/identity/metadata/provenance handle at M1, while operation provenance, generation and cache publication are M2 responsibilities. | Distinguish M1 structural storage/data-handle compatibility design from M2 coherent claim-bearing publication. Either defer public construction or use an explicitly unpublished internal binding; never publish a partial `ImageData`. | `A`, `I` |

The correction package must cite exact effective document revisions and owners.
“Addressed by RFC-0001” is not enough; every row requires an actual approved
change or explicit governed no-change disposition.

Draft companion [`RFC-0001-CCD-01`](RFC-0001-controlled-correction-delta.md)
expands these rows into proposed target revisions, owners, exact deltas and
conditional branches. It is review material only and closes no gate.

### Compatibility rules

No public aggregate storage API exists, so the directional RFC itself changes
no ABI or persistent wire. Existing declaration-only `StorageKind`,
`StoragePersistence`, scalar and component leaves remain live until a later
accepted migration.

That migration must:

- introduce corrected Core logical/representation/operation roles before
  removing or moving any old leaf;
- provide explicit lossless conversion for every old case/field and fail when
  the projection is ambiguous;
- resolve process-local `.native` byte order before persistence or fail;
- preserve old ordinary `Codable` bytes only as their old schema, never
  reinterpret them as the new canonical logical wire;
- migrate directly affected Core and Geometry consumers together;
- document deprecation and the later 0.x breaking removal in the changelog;
- avoid duplicate lookalike Core/Storage types; and
- never use a compatibility adapter to re-expose the unsafe async destination.

### Migration and approval order

1. Review and accept the directional RFC and select the mapped-storage schedule
   through the authority route described by `C01`/`C14`.
2. Draft, review and make effective the complete controlled correction package;
   do not edit source in the same approval step.
3. Reconcile all three Proposed ADRs, then accept `ADR-0039`, `ADR-0040` and
   `ADR-0041` in that dependency order. The accepted `ADR-0041` revision must
   make its Core-owned seal/stamping and drain model authoritative over
   `ADR-0039`'s older provider/destination read-probe shape.
4. Freeze final public API/error names, operational/canonical wires and
   production limits through the required focused review/decision artefacts.
5. Introduce lossless logical/representation compatibility projections with
   directly affected Core/Geometry tests.
6. Implement checked Core descriptors, admission authority, operation set,
   transaction gate, owned result and erasure with focused tests.
7. Implement one owned contiguous Storage provider with bounds, cancellation,
   allocation-failure, race, lifetime and release tests.
8. Implement direct leases or any mapped provider only after their separate
   platform/lifetime/unsafe evidence gates and the selected milestone.
9. Design builders under a separate accepted contract.
10. Integrate `ImageData` identity/metadata/provenance/cache publication only
    after those independent dependencies and the Execution/import publication
    authority are accepted.
11. Run broader module, platform and milestone gates only at the corresponding
    source/milestone boundary.

Until the applicable step is approved, the previous step grants no implied
source authority.

## Alternatives

### Make Core depend on Storage

Rejected. It violates the controlled acyclic graph and makes the canonical data
model depend on physical implementations.

### Keep contracts and erasure in Storage

Rejected for the Core-owned `ImageData` shape. It either creates the same cycle,
moves canonical data handles upward or requires duplicate contract types.

### Duplicate Core-facing and Storage-facing descriptors

Rejected. Parallel lookalike types invite drift, lossy conversion and confused
identity. Core owns one backend-neutral contract family; Storage implements it.

### Keep the raw capability bag and async writable pointer

Rejected. Caller-mintable bits are not callable authority, and a mutable pointer
across suspension has no complete lifetime/publication proof. Compatibility
cannot preserve an unsafe semantic shape.

### Let providers stamp completion or publish `ImageData`

Rejected. A provider must not echo/mint Core authority or combine storage with
identity, metadata and provenance. Core stamps the read transaction; Execution
or explicit host/import authority publishes the later coherent bundle.

### Treat all installed generations as stale

Rejected. Historical bound-snapshot reads remain exact and memory-safe; only a
current-required permit is invalidated by the sole generation transition.

### Always deep-copy and permanently exclude leases

Rejected as a final architecture because it prevents the required copy-avoiding
views and large-volume paths. The first read result is owned for safety, while
direct leases remain separately gated optimisations with identical semantics.

### Accept the ADRs without controlled corrections

Rejected. Proposed ADR text cannot silently override the controlled baseline,
and `ADR-0039` itself conflicts with `ADR-0041`/Foundation on mapped scheduling.

### Resolve the mapping schedule as an implementation detail

Rejected. The contradiction changes a P0 requirement and Foundation roadmap
deliverable. It requires explicit governed resolution before source.

## Implementation plan

This Draft increment is documentation-only:

1. allocate `RFC-0001` and register it as Draft;
2. record the authority, composition, correction inventory, evidence limits and
   unresolved decisions;
3. run documentation/front-matter/link, ADR-register, package-graph/import,
   manifest and release-integrity checks only;
4. obtain independent governance, API, concurrency, storage, security, privacy
   and lifetime review; and
5. leave product source and proposal statuses unchanged.

The next implementation increment after this Draft should prepare the exact
controlled correction proposal set and reconcile the mapping conflict in
`ADR-0039`; it should not begin storage source.

## Unresolved questions

The following are explicit approval gates:

1. Which governed mapped-storage option is selected: Foundation-preserving M5
   production mapping or a formal Foundation revision for M1?
2. What are the final public names and visibility of the Core logical binding,
   representation descriptor, snapshot handle, operation set, read result,
   lease and erasure?
3. Does the optional-operation set need a persistent operational wire in M1;
   if so, what exact schema/version/unknown-forwarding contract is accepted?
4. What is the complete canonical `ImageDescriptor` projection, including
   semantic component roles, spatial/value fields and typed pixel-padding/
   validity policy?
5. What production ceilings apply per authority domain and across providers on
   each supported Apple capability class?
6. What concrete Core provider-admission factory proves one nonforkable
   authority per lineage/budget domain?
7. Which public errors retain which bounded diagnostic context, and what
   privacy-authorised sink receives sensitive operational detail?
8. Which supported OS/toolchain destinations provide the required stable
   `Data.span`/`Data.bytes` behaviour, and what final closure-input/result shape
   prevents or accounts for shared-backing CoW escape without custom lifetime
   forwarding?
9. What actual allocation/no-copy/mapping implementation, exact mapping-binding
   tuple and deallocator model pass fault, pressure, race, lifetime and external-
   change review?
10. What production cancellation-observation cadence is required for each
    nontrivial provider class?
11. What separate builder/freeze contract is accepted, and how does it hand an
    unpublished snapshot to the later publication authority?
12. At what accepted dependency point can structural Core `ImageData` exist
    without falsely claiming complete content identity, metadata, provenance or
    publication?
13. What exact representation-integrity projection and verifier/policy authority
    are introduced at M5?
14. How are host-supplied cross-provider aggregate memory/work ceilings and their
    enforcement split between the host and Execution coordinator?

None may be resolved implicitly by the first convenient implementation.

## References

- [RFC-0001-CCD-01 - Controlled-correction delta](RFC-0001-controlled-correction-delta.md)
- [Voxelia Project Foundation v0.1.1](../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0036 - Domain-separated complete canonical metadata record identity](../architecture/decisions/ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md)
- [ADR-0037 - Claim-bearing data identity and cache-admission boundary](../architecture/decisions/ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md)
- [ADR-0038 - Closed provenance record and graph admission boundary](../architecture/decisions/ADR-0038-closed-provenance-record-and-graph-admission-boundary.md)
- [ADR-0039 - Closed storage capability and descriptor admission boundary](../architecture/decisions/ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md)
- [ADR-0040 - Normalized logical sample and representation projection boundary](../architecture/decisions/ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md)
- [ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary](../architecture/decisions/ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md)

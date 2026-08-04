# CCR-0016 - Controlled corrections for the RFC-0001 storage composition

## Status

| Field | Value |
|---|---|
| Correction ID | `CCR-0016` |
| Authority | Accepted [`ADR-0039`](../decisions/ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md), [`ADR-0040`](../decisions/ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md) and [`ADR-0041`](../decisions/ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md), composed for review by `RFC-0001` |
| Approved by | Project owner (directional `RFC-0001` approval and mapped-storage schedule selection recorded 2026-08-04) |
| Approval date | 2026-08-04 |
| Effective commit | The Git commit that introduces this record |
| Baseline revision | `v0.1.1` (immutable, not edited by this record) |

This record is the controlled correction package required by the three
accepted storage-composition ADRs. The `v0.1.1` baseline files remain
immutable and unedited; wherever a statement quoted below conflicts with
this record, this record is authoritative for implementation, traceability
and review. A future coordinated `v0.1.2` revision set shall incorporate
the corrected text verbatim. The `RFC-0001` register file deliberately
remains `Draft` because the RFC validator fails closed on every other
status until a machine-readable approval schema is governed; the project
owner's 2026-08-04 directional approval, schedule selection and
reconciliation choices are recorded here, in the three accepted ADRs and
in the progress ledger. This correction authorises no storage, descriptor,
erasure, lease, builder or `ImageData` source: the accepted ADRs' source
gates and the `RFC-0001` approval-order steps 4 through 11 remain closed.

## Corrections

### CCR-0016-A - Storage ownership reconciliation

Target: the MTA module-ownership prose and the CDMS storage sections that
assign descriptors, capabilities, type erasure and region reading to
`VoxeliaStorage`.

The corrected assignment follows accepted `ADR-0039`: `VoxeliaCore` owns
the backend-neutral logical/representation, operation, snapshot,
read-result, lease, error and safe-erasure contracts, including
erasure/witness boxes, plus contract admission, one nonforgeable read
authority per admitted provider lineage and private result-target
adoption. `VoxeliaStorage` owns concrete providers, builders, mappings,
source/mapping allocations, I/O, codecs, caches and resource lifetime,
implementing Core witnesses without ever controlling Core's private
result target. `VoxeliaExecution` or an explicit host/import coordinator
owns the one generation-pinned atomic `ImageData` publication point.
`VoxeliaMetal` owns per-device residency as dynamic generation-qualified
evidence, never a static storage bit. Hosts own locators, credentials,
transport, privacy, authentication and storage policy. The live package
direction (`Execution -> Storage -> Core -> Spatial`) is unchanged;
Core-owned `ImageData` referencing an erased storage value therefore
resolves through Core-owned contracts, and no `Core -> Storage` edge or
duplicate contract family is permitted.

### CCR-0016-B - Capability taxonomy replacement

Target: the CDMS `StorageCapabilities` `OptionSet` sketch.

The corrected model separates the mixed bag into four non-interchangeable
categories: immutable characteristics (organisation, locality/origin,
backing, persistence, resolution description); closed optional operation
identifiers mirrored by exact retained witnesses; runtime results and
evidence (completed reads, scoped leases, frozen snapshots, digest and
residency observations for their exact scopes); and dynamic downstream
state such as device residency. No operation implies another; a bit or
label without the exact admitted witness is not callable authority; and a
digest operation implies neither existence, currency, verification nor
authenticity of any digest.

### CCR-0016-C - Logical/representation separation

Target: the CDMS logical-descriptor sketches that embed source/physical
byte order, valid-bit and component-layout fields.

The corrected model follows accepted `ADR-0040`'s four layers: the
logical sample-layout binding (shape, exact decoded scalar type,
component count, exact logical ordinals) is storage-independent and
carries no physical byte order or source-bit fields; source value
interpretation belongs to owning adapters with backend-neutral claim
values in Core where required; storage representation (bytes, strides,
arrangement, padding, compression, tiling, lifetime) is a Core contract
with concrete implementations in Storage; and persistent
identity/evidence is a versioned projection claim plus separately
admitted runtime evidence over one immutable snapshot. Logical equality
and content identity are independent of physical representation, and no
layer acquires another's authority because byte counts or labels match.

### CCR-0016-D - Read-transaction replacement

Target: the CDMS displayed region-read API carrying a caller-owned
mutable unsafe buffer through an asynchronous method.

The corrected target follows accepted `ADR-0041`: the initial safe read
profile returns one complete owned immutable result with packed
interleaved layout, base offset zero and exactly the checked expected
length, produced through Core-validated admission, a pending byte-budget
reservation, a private Core-owned exact-capacity backing whose fill
capability is the only thing the provider receives, monotonic
poison-on-violation fill, one internally stamped commit linearisation
point and draining terminal states that publish nothing. `ADR-0041`'s
Core-owned seal/stamping and drain model is authoritative over
`ADR-0039`'s older provider/destination read-probe shape. Scoped
contiguous and mapped access uses synchronous owner-retaining immutable
`Foundation.Data` lease scopes; no bare span, pointer or unsafe buffer is
returned, and byte-bearing escape requires proved co-retention or an
independently charged copy.

### CCR-0016-E - Mapped-storage schedule (Foundation-preserving option)

Target: `docs/project/Voxelia_Requirements_Baseline_v0.1.1.md` row
`VOX-STO-004` and the MTA Stage-3 wording, reconciling the Foundation's
Phase-5 mapped-storage schedule.

The project owner selected the Foundation-preserving option on
2026-08-04. The corrected `VOX-STO-004` reading moves the production
memory-mapped provider deliverable from M1 to M5; M1 retains the mapped
contract semantics and isolated lifetime evidence plus one verified owned
contiguous provider implementation, subject to the accepted source gates.
The MTA Stage-3 and `ADR-0039` milestone wording are read under this
correction. Actual mapping, no-copy allocation and deallocator bridges
remain blocked on supported-destination builds, strict memory-safety
checking, fault/pressure evidence and independent lifetime/security
review regardless of milestone.

## Scope and limits

- The `RFC-0001` directional composition is approved as reviewed; its
  fourteen unresolved questions (final public names, operational wires,
  canonical `ImageDescriptor` projection, production ceilings, admission
  factory, error context, `Data.span` platform behaviour, mapping
  implementation, cancellation cadence, builder contract, structural
  `ImageData` point, integrity projection and host/Execution ceiling
  split) remain explicit approval gates.
- No storage, descriptor, operation, erasure, lease, builder, provider,
  mapping or `ImageData` source is authorised by this record; the
  `RFC-0001` approval order grants no implied source authority from one
  approved step to the next.
- This record grants no authority beyond the corrections above: it does
  not alter requirement rows beyond the recorded readings, accept any
  other record, or reopen the accepted metadata, identity or provenance
  boundaries.

## References

- [RFC-0001 - Storage contract and logical data-model composition](../../rfcs/RFC-0001-storage-contract-and-logical-data-model-composition.md)
- [RFC-0001-CCD-01 - Controlled correction delta companion](../../rfcs/RFC-0001-controlled-correction-delta.md)
- [ADR-0039 - Closed storage capability and descriptor admission boundary](../decisions/ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md)
- [ADR-0040 - Normalized logical sample and representation projection boundary](../decisions/ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md)
- [ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary](../decisions/ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1, VOX-STO-004](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)

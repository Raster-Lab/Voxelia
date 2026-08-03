---
document_id: "ADR-0041"
title: "Safe storage read transaction and type-erasure lifetime boundary"
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
  - "VOX-PLT-008"
  - "VOX-PLT-009"
  - "VOX-REP-010"
  - "VOX-ARC-001"
  - "VOX-ARC-003"
  - "VOX-ARC-004"
  - "VOX-ARC-005"
  - "VOX-ARC-011"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-005"
  - "VOX-API-007"
  - "VOX-API-010"
  - "VOX-API-011"
  - "VOX-DAT-004"
  - "VOX-DAT-013"
  - "VOX-DAT-014"
  - "VOX-RGN-001"
  - "VOX-RGN-002"
  - "VOX-RGN-003"
  - "VOX-RGN-004"
  - "VOX-RGN-006"
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
  - "VOX-VS1-017"
  - "VOX-VS1-018"
  - "VOX-VS1-020"
---

# ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary

## Context

Voxelia needs a safe M1 region-read and lifetime contract before it can add
`ImageStorage`, `AnyImageStorage`, contiguous storage or mapped storage product
source.

The controlled documents agree on required behaviour:

- published image content is immutable for one snapshot;
- successful region reads are complete and partial bytes are not success;
- reads validate rank, bounds, scalar/component compatibility and allocation
  size before access;
- cancellation remains distinct from failure and cannot publish incomplete or
  stale output;
- storage views retain their backing owner for the complete read lifetime;
- unsafe byte access, if any, stays closure-scoped and its pointer cannot
  escape;
- canonical descriptors and safe handles are `Sendable` while mutable services
  are isolated;
- `@unchecked Sendable` requires explicit justification, independent review
  and stress evidence.

The sketches do not supply an implementable safe API. The Master Technical
Architecture assigns backend-neutral storage protocols and type erasure to
Core and concrete resources to Storage. The live package graph preserves
`VoxeliaStorage -> VoxeliaCore`. The Core Data Model Specification instead
assigns descriptors, capabilities, erasure and region reading to Storage while
placing `AnyImageStorage` inside Core-owned `ImageData`; implementing that
literally would require a prohibited reverse dependency.

The CDMS read sketch also passes an `UnsafeMutableRawBufferPointer` through an
async destination method whose destination descriptor, state transitions,
ownership and cancellation semantics are undefined. CDMS explicitly lists the
safe destination-buffer API and exact erasure as open decisions. A pointer
whose lexical closure returns before suspended provider work completes cannot
be made safe by a comment or by declaring the destination `Sendable`.

Proposed `ADR-0039` selects the ownership direction, exact provider binding,
closed operation registry, complete read and one-shot destination concepts,
but deliberately source-gates the destination/lease/erasure lifetime shape.
Its evidence probe returns owned staging and an actor-owned copied view; it
does not prove a real scoped contiguous or mapped lease, task-cancellation
linearisation, checked type erasure or deinitialisation. Its destination has no
private prepared-versus-committed race window, its provider call does not
suspend, and it does not bound aggregate caller-retained result storage. Those
are intentional limits of the earlier conceptual probe, not transaction proof.
Proposed `ADR-0040` separates logical values from representation bytes but
repeats the same lifetime source gate.

If accepted with its dependencies and controlled corrections, this proposal
would close that conceptual gate narrowly. It does not accept its upstream
proposals, create the required public RFC or controlled corrections, implement
actual mapping/unsafe access, publish `ImageData`, or authorise product source.

The controlled milestone text is itself inconsistent: the Requirements
Baseline assigns an initial memory-mapped implementation to M1, while the
higher-authority Foundation places memory-mapped storage in Phase 5. This
proposal records the safe semantics but does not silently select either
schedule. A controlled correction or approved interpretation must reconcile
an M1 contract/evidence boundary with any later production large-volume
provider before mapped product source is authorised.

## Decision

If accepted, Voxelia will use an immutable snapshot-bound erased handle, a
complete owned region-read transaction and synchronous owner-retaining byte
lease scopes. The initial safe profile favours explicit ownership and one
linearisation point over caller-owned mutable destinations.

### Authority and ownership

The live package direction remains unchanged:

| Responsibility | Owner | Rule |
|---|---|---|
| Backend-neutral snapshot/read/lease/erasure contracts | `VoxeliaCore` | No dependency on Storage, Execution or Metal. |
| Concrete provider/mapping owners, backing allocation, I/O and resource release | `VoxeliaStorage` | Implements Core witnesses and retains provider physical resources. |
| Complete read transaction authority | One Core-owned coordinator/gate | It alone mints request seals, owns/closes fill targets, stamps prepared records, arbitrates binding/freshness/cancellation/budget and publishes a committed owned result. |
| `ImageData`, provenance, identity and cache publication | `VoxeliaExecution` or explicit host/import coordinator | Later atomic bundle publication; a region-read result is not `ImageData`. |
| Dynamic per-device residency | `VoxeliaMetal` with Execution coordination | Never inferred from a lease or static storage capability. |
| File policy, locators, credentials and authorisation | Host/application | Not reusable-toolkit storage authority. |

The Core contract names behavior, immutable binding and the sole result-
adoption coordinator. Storage owns the backing class/reference, fills only the
Core-supplied bounded target, returns an outcome through its exact retained
witness and owns any synchronised resource close implementation. A Storage
provider never stamps
an authoritative completion or publishes a result. Neither module imports
upward to recover missing semantics.

### Immutable snapshot-bound handle

One erased storage handle binds exactly one retained tuple:

```text
opaque Core read-authority/provider-lineage identity and strong authority
exact logical and representation descriptor binding
opaque backing-owner identity and strong owner
snapshot identity
generation
mandatory complete region-read witness
zero or more exact optional-operation witnesses
```

At provider admission, Core mints/selects the nonforgeable lineage authority
and its identity. The provider supplies only its descriptor/owner/snapshot/
generation/witness portion for composition under that existing authority; it
cannot issue, inject or replace the Core authority. Opaque identities are
compared by identity, not caller-mintable labels. The composed tuple is runtime
authority, not persistent identity, provenance, authenticity or canonical wire.

One nonforgeable Core read authority exists per admitted provider lineage and
budget domain. Every handle generation and erased copy for that lineage co-
retains the same authority object. Re-erasure cannot inject, clone or replace a
gate; its authority identity is also the provider-lineage identity used for
binding. This prevents equal provider wrappers from forking current-permit
state or multiplying the domain's budgets. Totals below are per admitted
authority domain; a later host/Execution aggregate policy may impose stricter
cross-provider limits.

An existing handle never changes the logical snapshot it denotes. A mutable
provider/cache may prepare a new generation and proposed handle, but one Core-
gate install transition is the sole current-generation displacement point. It
atomically changes the current binding/permit table and invalidates affected
transactions before the provider or coordinator may expose the new handle as
current. The old handle and its leases remain memory-safe while strongly
retained.

Every read explicitly selects one of two freshness semantics:

| Freshness | Rule |
|---|---|
| Bound snapshot | The immutable handle remains historically readable while its owner is retained; installing a newer generation does not relabel or stale this read. |
| Require current | The request carries a non-caller-mintable current-generation permit issued by the same Core authority. Displacing that exact binding atomically makes its pending/prepared transactions stale before commit. |

Downstream current-only publication must use the second form or independently
revalidate through its later Execution bundle authority. A retained historical
result carries a coordinator-authenticated immutable historical source stamp,
not the exact resource-owning binding, and cannot be relabelled as the new
current snapshot.

The strong ownership graph is acyclic:

```text
erased handle -> exact witness/box -> snapshot owner -> resource
              -> Core read authority
read scope    -> exact witness/box -> snapshot owner -> resource
              -> Core read authority
lease scope   -> exact witness/box -> snapshot owner -> resource
```

No resource holds the erased handle, read scope or lease closure. A weak owner,
textual token, pointer address, deallocator function without an owner, or
separately supplied binding field is not lifetime evidence.

### Initial complete read result

The first M1 region-read profile returns one immutable owned packed-interleaved
result for the requested logical region. It does not expose a caller-owned
mutable destination across suspension.

After charging the exact expected length, the Core coordinator creates one
private fixed-capacity final backing owner and co-locates its idempotent byte-
budget token before invoking the provider. The provider receives only a
checked bounded fill capability; it never receives the bare backing, mutable
pointer, result or budget token. Writes beyond capacity are recorded and
rejected without allocation.

The initial fill is serialized and monotonic. Each synchronous chunk names its
checked start offset, which must equal the current initialized cursor; the
capability checked-adds the chunk length before copying and advances once.
Duplicate, overlapping, gapped/out-of-order, concurrent-out-of-order,
after-close or overrun writes poison the target and can never be repaired into
success by later writes. Thus exact final cursor plus no poison proves complete
coverage of `[0, expectedLength)`.

On provider return, the coordinator closes the capability outside its
transaction gate, so a retained late writer cannot mutate the frozen
candidate. The capability is read-scope-bounded and does not own a transferable
backing; retaining the sealed capability cannot extend the final backing/
resource lifetime.

The provider returns only an outcome. The closed target's own initialized count
and overrun state determine complete/short/overrun status. An exactly filled
target becomes one immutable candidate owner that remains in the structured
read scope, private and unpublishable, until the transaction authority adopts
it. Commit moves that same owner into the result without a second byte copy.
The returned result carries the exact request region, decoded scalar/component
layout, expected length and coordinator-authenticated source stamp.

The result's immutable source stamp is not a binding, read witness or current-
generation permit. Its owned bytes no longer require the physical source owner after
commit; releasing the last handle/read/lease may therefore release that source
while retained result bytes remain valid. Any opaque identity token carried by
the result has no back-reference to the provider resource.

A result must not expose a bare copy-on-write byte container whose backing can
outlive the result while its budget lease dies. Every alias of shared result
backing either co-retains the same byte-budget lease, or the API returns a
proved independent deep copy charged to caller ownership. The result may keep
its container private and offer bounded reads/copies; ordinary CoW value
copying is not proof of independence.

Later destination-owned staging may optimise allocation only if it preserves
the same ownership and commit rules without returning a pointer, span or
mutable storage across `await`. Mutable builders and writable leases are not
part of this decision.

### Read transaction state machine

One request has one non-caller-mintable identity seal, one semantic terminal
transition and a separate resource-drain phase:

```text
unstarted
  -> pending(seal, binding, freshness, region, format, expectedLength,
             activeProviderAndByteReservation)
       -> prepared(internallyStampedRecord;
                   frozenBufferOwner remains in read scope)
            -> committed(tombstone; result owns transferredByteBudget)
             | cancelled(draining)
             | stale(draining)
             | failed(boundedCode, draining)
             | abandoned(draining)
        | cancelled(draining)
        | stale(draining)
        | failed(boundedCode, draining)
        | abandoned(draining)

draining -> drained(tombstone) only after provider return/stop acknowledgement
            and private buffer destruction outside the gate
```

`abandoned` is an internal scope-teardown state used when a provider violates
the completion contract or a read scope exits unexpectedly. It is not a public
retry state. A semantic terminal state immediately prevents commit but does not
pretend suspended provider work or its private fill target has disappeared.
Failure, cancellation, stale and abandoned requests keep their request/byte reservation
until the invocation returns or acknowledges stop and all private fill state is
removed then released outside the gate. Commit transfers the byte reservation
to the immutable result's shared backing; it is released synchronously only
after the last qualifying result alias releases that backing. No semantic
terminal state reopens, retries or changes into another terminal state, and
resource retirement occurs exactly once.

Before `pending` is created, the authority checks in this order:

1. lossless platform conversion and host limits for every external count;
2. rank, non-empty-region policy, checked bounds and byte-count arithmetic;
3. exact descriptor, scalar, component and initial destination-result profile;
4. exact provider binding and mandatory region-read witness; and
5. per-request, total active-plus-retained-result byte and concurrent-request
   budgets.

Failure before reservation creates no seal, candidate or published state.
The total byte ceiling accounts for both active candidates and committed owned
results still retained by callers. Charging only active provider work would
allow callers to retain successive results and bypass the memory bound.

After reservation and before provider work, the read scope creates the exact-
capacity buffer owner with its one idempotent byte-budget lease outside the
gate. If that can fail recoverably, the exact transaction fails before invoking
the provider. The scope retains that owner through suspension. Failure,
cancellation, stale or abandon marks the semantic outcome but releases the
reservation only when the owner is destroyed during later resource retirement.
Commit moves the same owner/lease into the immutable result. There is no
fallible allocation after the committed transition.

The authority retains only bounded transaction records/tombstones, never a
candidate or committed result buffer. The structured read scope retains the
single private buffer owner. On commit the gate changes only its stamped record,
records the tombstone and returns a transfer grant after unlocking. The
ownership path is `private/result buffer owner -> budget lease -> authority`;
there is no reverse authority-to-buffer edge and therefore no result-budget
retain cycle.

Active/draining records are bounded by the concurrent-request limit and are
never evicted. After a scope is drained or committed, its terminal record may
enter a bounded recent-tombstone queue. Admission evicts the oldest retired
tombstone when that queue is full; request seals are never reused. A later
candidate bearing an evicted seal is simply unknown and is rejected without
mutating any live record. Thus a finite tombstone limit bounds diagnostics/
replay history without permanently exhausting a long-lived authority.

Byte-budget retirement is independent of that queue and its reusable slots.
Each private backing receives a nonforgeable, never-reused live-budget token
record in a separate authority ledger. The token identity, not a transaction
slot or tombstone, releases resident bytes exactly once. A committed tombstone
may therefore be evicted/reused while a result remains alive; the eventual
result backing `deinit` removes only its token-ledger entry and cannot alter a
new transaction occupying a recycled slot.

The Core coordinator invokes the exact strongly retained witness. The provider
request carries admitted region/format semantics and the bounded fill
capability, but not the coordinator's seal, authoritative binding or bare
storage. The provider returns only a closed outcome: completed fill,
cancellation or bounded provider failure. Target allocation failure occurs
recoverably before provider invocation.

After the provider returns outside the gate, the coordinator closes the fill
capability and derives count/overrun from its private owner. It alone stamps an
exact complete owner with its private seal/retained binding and attempts the
`prepared` record transition. Short/overrun targets terminalise without
preparation. The initial profile permits no uncharged scratch allocation; any
future scratch path obtains a separate bounded reservation before allocation.
A provider cannot mint a generation, substitute a value-equal peer provider,
construct an authoritative candidate or publish/retain the final backing.

The coordinator cannot prevent arbitrary in-process provider code from
allocating unrelated memory in violation of that contract, so this is not a
denial-of-service-freedom claim. Such memory is never accepted as result
backing; production providers require allocation and memory-pressure evidence.

### Cancellation, invalidation and commit linearisation

One Core read authority owns one synchronous checked-`Sendable` gate containing
transaction states, its current-generation permits, concurrent-request counts,
active/retained-result byte reservations and commit reservation. There is no
second commit oracle. A check on one actor followed by an `await` and a commit
on another actor is rejected as a time-of-check/time-of-use gap.

Provider calls, allocation, user callbacks, diagnostics and deallocation never
run while this gate is held. The gate stores no candidate/buffer owner. Read-
scope owners and any objects removed from auxiliary state are retained locally
and released after unlocking, so buffer destruction or a result-budget lease
`deinit` cannot re-enter the same gate. Provider-internal locks and the private
fill-capability lock are never nested inside the Core gate.

The async read scope uses a cancellation handler whose synchronous cancellation
path competes on that same domain. Provider suspension or cancellation-handler
delivery never needs an async `deinit` or queued actor message to make the
transaction safe.

Cancellation or current invalidation terminalises publication immediately but
does not release capacity until the structured provider invocation drains. A
provider that ignores cancellation therefore remains charged and can cause new
admission to fail closed; it cannot create unbounded overlapping work by
cycling cancellation/generation. Production providers need a bounded
cancellation cadence and may be quarantined after a governed stop deadline,
but capacity is never reclaimed merely because a timer elapsed.

The first terminal transition under the synchronization domain wins:

- cancellation first means no result, even if bytes arrive later;
- invalidation first makes a pending or prepared `require current` request
  stale, while a bound-snapshot read remains valid;
- commit first returns a complete immutable result; later cancellation or
  invalidation cannot corrupt that historical owned result; and
- provider failure first is a failure unless cancellation or invalidation has
  already terminalised the request.

Commit atomically releases the request-count reservation and transfers the
already-charged byte reservation to an all-immutable checked-`Sendable` result
buffer owner. Copies of the result share that owner and one idempotent budget
lease co-located in the backing owner. Its synchronous `deinit` releases the
byte reservation exactly once; it never launches asynchronous cleanup. The
already-owned buffer is moved from the read scope into the returned value or
released only after unlocking; commit itself invokes no allocator.

For a non-commit terminal outcome, the gate records the fixed semantic error
immediately while the structured read scope retains its drain responsibility.
The public async call returns that error after the provider invocation drains.
When provider work returns, the scope closes/discards any late fill, retires
the prepared record under the gate without storing/destroying its buffer there,
then releases the private owner outside the gate. An
uncooperative invocation that never returns remains bounded but can
intentionally hold its admitted capacity.

After any suspension and immediately before preparation and commit, the read
scope observes task cancellation and attempts the same synchronous
cancellation transition. Preparation and final commit are separate await-free
gate operations, intentionally permitting cancellation/invalidation to win
after provider completion but before publication. Commit revalidates the exact
seal/binding, freshness permit, private prepared state and buffer count under
the same domain.

This defines a race by its lock/atomic linearisation order, not by scheduler
timing. It does not promise that cancellation retroactively revokes a result
whose commit already won.

### Completion mismatch, replay and failure precedence

The initial provider-facing API cannot construct a stamped candidate. At the
private coordinator boundary, an unknown or foreign seal/binding is rejected
without consuming or poisoning any transaction. An exact seal paired with an
impossible mismatched internally stamped binding is a local contract breach
and abandons only that exact transaction. A short/overrun fill, matching
allocation/provider failure or provider cancellation consumes only its exact
transaction into the corresponding terminal state. A second exact completion
after any terminal state is a replay and cannot expose bytes.

Public storage-read failures are bounded categories:

| Public category | Meaning |
|---|---|
| invalid request | Rank, bounds, shape, scalar/component or result-profile admission failed. |
| unsupported operation | The exact retained witness is absent. |
| resource limit | A platform/host/request/active-or-retained limit or checked arithmetic admission failed. |
| allocation failure | The admitted exact-capacity result target failed recoverably before provider invocation. |
| cancelled | Cancellation won before commit. |
| stale snapshot | Snapshot invalidation won before commit. |
| incomplete read | The closed bounded fill was short or recorded an overrun attempt. |
| provider failure | The bound provider reported a storage/I/O failure. |
| provider contract violation | Seal, binding, replay or completion invariants failed. |

Internal tests may distinguish foreign, duplicate, replay and abandoned states,
but their identifiers are not public diagnostic payloads. For already-
terminal races, the recorded first terminal state wins. For a still-pending or
prepared exact `require current` transaction, current-permit validity precedes
provider outcome. A bound-snapshot transaction has no currentness check. In
both forms, the internally stamped seal/binding precedes closed-target count/
overrun state, and an exact complete target precedes commit.

### Checked type erasure

The initial erased handle retains one exact region-read witness/box that is
itself checked `Sendable`. Optional operations are separately typed retained
witness values. Construction derives the advertised operation set from those
values once; callers cannot provide bits or rediscover a different base later.
Every erased copy co-retains the binding's existing Core read authority;
erasure exposes no initializer that substitutes a fresh gate or budget domain.

The selected evidence shape is a single `Sendable` protocol existential or a
final all-immutable checked-`Sendable` box around one `Sendable` base. A bag of
unrelated closures, weak captures, mutable logical data, caller-supplied
binding fields and `@unchecked Sendable` are rejected. The witness strongly
retains the exact owner for every async call and lease scope.

The Core coordinator invokes that retained existential directly and stamps a
prepared record from its private closed fill and transaction record. Erasure
never reconstructs authority from a provider-returned ID, descriptor, label or
generation. Concrete and erased dispatch therefore share the same adopter and
terminal-state oracle.

Type erasure preserves exact typed failures. It does not catch an unsupported
operation and silently fall back to another representation/provider.

### Scoped contiguous and mapped bytes

Direct decoded bytes and mapped representation bytes remain different optional
operations:

| Scope | Bytes | Required binding |
|---|---|---|
| Contiguous decoded | Exact admitted decoded representation bytes, with scalar order/layout/length/alignment. | Snapshot binding plus strong backing owner. |
| Mapped representation | Exact read-only mapped representation bytes, which may be encoded/compressed and are not implied logical samples. | Snapshot/file identity, offset, length, page/alignment, change policy and strong mapping owner. |

The Swift 6 baseline-safe evidence shape is an owned Foundation `Data` lease.
A synchronous nonescaping `withContents` closure borrows that retained owner;
the caller derives read-only `Span<UInt8>` through `Data.span` or `RawSpan`
through `Data.bytes` while the owner remains borrowed. A mapped scope also
passes its exact mapping binding alongside the borrowed owner. It does not
custom-forward a bare span whose dependence on the owner would be lost.

The selected contract closure contains no `await`; no view is stored in the
handle and no custom span/lease value is returned. The closure may return an
ordinary escapable result such as an owned copy or checksum, but that result is
not the lease or mapped authority; any byte container satisfies the alias-token
or proved-deep-copy rule below. Swift can preserve an owner-dependent view
across some direct suspension in one activation, so this synchronous rule is a
Voxelia resource-lifetime boundary rather than a claim that every `await` is a
compiler error. Capturing the view in an unstructured task, child task,
`async let` or escaping closure is rejected.

The current compiler rejects custom returned or forwarded `Span`/`RawSpan`
views without stable lifetime annotations. Experimental `@_lifetime` syntax is
not accepted product API and is not enabled to bypass that rejection. The
checked-in full-`swiftc -c` compile-negative configurations preserve the
custom returned `Span` and `RawSpan` boundary. `-typecheck` alone is
insufficient because it can miss lifetime escapes diagnosed during SIL
generation; separate lexical/escaping-task cases remain part of the later
supported-destination acceptance matrix.

`Span` nonescapability and `RawSpan`'s standard-library `@unchecked Sendable`
conformance are not resource authority. The lease scope also strongly retains
the exact witness/owner, and concrete mapping code must prove that the resource
cannot unmap or mutate for the closure duration. Evidence uses `Data.bytes`
rather than the `@unsafe` `Span.bytes` adapter and compiles with strict memory-
safety checking. No public unsafe pointer, mutable span or async lease closure
is authorised.

`Data` is itself copy-on-write. A copied `Data` owner may escape safely only
when every alias of its shared backing also retains the same mapping/resource
and budget token until the backing's final release. Otherwise the operation
must return a proved independent deep copy, not a bare alias. A token held only
by an outer lease wrapper is insufficient. The isolated probe demonstrates the
borrow syntax with owned copied bytes; actual no-copy/mapped alias-token
co-location remains source-gated evidence.

### Mapped external-change policy

The initial direct mapped lease requires immutable snapshot semantics: the
mapped bytes and mapping lifetime remain stable for every admitted lease.

An externally mutable file cannot supply an authoritative direct `RawSpan`
merely by checking metadata before and after the closure; arbitrary closure
side effects cannot be rolled back after mutation is detected. A mutable-file
policy may support copied private staging followed by final validation and
fail-closed invalidation, but that is not direct mapped lease evidence and its
implementation remains deferred.

Verified-snapshot mappings depend on the later representation-integrity
contract. Page invalidation, remapping and cache eviction must not unmap a
resource still retained by an existing lease. New generations may invalidate
future publication while old strongly retained immutable mappings remain
memory-safe.

### Deinitialisation and release

Correctness never depends on async `deinit`. Explicit cancellation/close owns
semantic transaction termination. Resource release is synchronous, idempotent
and occurs only after the last erased handle, pending read, private fill owner
or lease scope releases its strong owner.

The committed result's byte-budget lease is resource accounting, not semantic
cancellation. Its shared buffer owner releases that lease synchronously after
the last result copy dies. Source-owner lifetime and result-buffer lifetime are
separate, acyclic ownership paths.

The implementation must avoid cycles such as box -> closure -> box,
owner -> lease -> owner or destination -> provider -> destination. Cancellation
releases unpublished owned staging. Deinitialising the caller's erased wrapper
does not revoke work or bytes still retained by an in-flight structured task or
active lease.

Actual file descriptors, VM mappings, aligned allocations and deallocator
bridges require separate concrete Storage review. This decision proves the
contract shape, not unsafe resource implementation.

### Bounds and resource policy

Every external unsigned/wider value is checked against `Int.max` and a stricter
field/host limit before conversion. All additions and multiplications for
regions, expected bytes, offsets, spans, request counts and aggregate active-
plus-retained-result bytes use checked arithmetic before allocation/access.

Host policy supplies positive limits for:

- rank, extents and one region's logical byte count;
- concurrent read count and total active-plus-retained-result owned bytes;
- contiguous and mapped lease length/count;
- completion/tombstone bookkeeping; and
- cancellation work cadence for nontrivial providers.

The policy is admission context, not image identity or canonical wire. These
totals apply to one nonforkable Core authority domain; cross-provider aggregate
ceilings belong to later host/Execution coordination. Probe ceilings are
fixtures. Production ceilings require supported-device, memory-pressure,
recoverable allocation-failure and hostile-input evidence.

### Diagnostics, privacy and concurrency

Default errors, descriptions, debug descriptions, reflection, dump, logs and
telemetry exclude sample bytes, paths, file identity, owner/provider identity,
snapshot/generation values, request seals, offsets, addresses and digests.
Detailed operational diagnostics require an explicit privacy-authorised sink.

Bindings, witnesses, erased handles, candidates, owned results and lease
wrappers are immutable and checked `Sendable`. Mutable transaction and mapping
state uses an actor or checked synchronisation primitive with a documented
single-domain invariant. The evidence uses no unsafe pointer, global mutable
state, detached work or Voxelia-authored `@unchecked Sendable`; standard-
library conformances do not replace the lifetime proof.

### Milestone and source gate

M1 owns the immutable snapshot/read/lease/erasure contract and focused
contract evidence. The Requirements Baseline also names initial contiguous and
memory-mapped implementations at M1, but the Foundation places memory-mapped
storage in Phase 5. This Proposed ADR does not override that higher-authority
conflict: the acceptance package must adopt a controlled correction or an
approved interpretation that distinguishes the M1 semantic/evidence boundary
from any later production large-volume mapping provider. Until that happens,
no mapped product source is authorised.

M2/Execution owns operation-wide scheduling and generation-aware `ImageData`/
identity/provenance/cache publication. M3/Metal owns dynamic residency. M5
owns tile/brick/compression/integrity and any production mapping scope assigned
there by the corrected baseline. M9 owns callback/remote/sequential sources
and transport coordination.

`VOX-EXE-007` and `VOX-EXE-009` are affected downstream guardrails only. This
local transaction gate neither implements nor closes M2 operation-wide
cancellation propagation or operation-generation authority.

While this ADR is Proposed, review work is limited to documentation and
isolated evidence; the proposal itself grants no authority. It does not
authorise:

- public storage/read/lease/erasure/result types;
- changes to `StorageKind`/`StoragePersistence` ownership;
- actual allocation, mmap, file descriptors, raw pointers or no-copy source;
- mutable destination/builder/writable lease source;
- callback, remote, sequential, tile, brick, compressed or multiresolution
  source;
- digest/integrity verification or dynamic residency;
- `ImageData`, metadata, provenance, identity, cache or bundle publication; or
- Voxelia-authored `@unchecked Sendable`.

Product source requires acceptance of proposed `ADR-0039`, `ADR-0040` and this
proposal; the public storage/data-model RFC; controlled Foundation/MTA/CDMS/
RPSS/Requirements/module-overview corrections; final API and error names;
production limits; actual allocation/mapping and failure evidence; affected
Core/Storage/Execution tests; strict builds on every supported Apple
destination; and designated API, concurrency, security, privacy and memory-
lifetime review.

## Alternatives considered

### Keep the async writable-pointer destination sketch

Rejected. A pointer/borrow cannot cross arbitrary suspension safely, and the
sketch does not define ownership, state, exact length, cancellation or commit.

### Let the provider publish directly

Rejected. Provider completion, cancellation, stale invalidation and downstream
publication would have competing linearisation points. Provider output is only
an outcome; the Core-owned fill target remains unpublishable until commit.

### Check current generation on one actor and commit on another

Rejected. The intervening suspension creates a stale-publication TOCTOU.
Binding validity and terminal transition must arbitrate together.

### Store a bag of `@Sendable` closures

Rejected. Unrelated captures can refer to different owners/generations and
capabilities can drift. One checked witness/box retains one exact binding.

### Use weak ownership to avoid cycles

Rejected. A weak owner permits deallocation during an async read or lease. The
graph is made acyclic explicitly and remains strong in the forward direction.

### Treat `Span` as complete lifetime proof

Rejected. Nonescapability helps prevent returning the view but does not prove
provider/snapshot identity, mapping stability or backing retention. Both the
language borrow and strong owner are required.

### Custom-forward a bare span through the lease closure

Rejected. The supported compiler cannot express the required custom owner-
dependent forwarding without experimental lifetime annotations. The stable
shape lends the retained `Data` owner and derives `Data.span`/`Data.bytes` at
the use site.

### Enable experimental lifetime annotations

Rejected for this boundary. Supported-destination public API cannot depend on
an experimental compiler feature to make an otherwise invalid returned borrow
compile. The synchronous closure profile is sufficient evidence.

### Expose externally mutable mapped bytes directly

Rejected. A post-closure mutation check cannot undo effects produced from
bytes that changed during the scope. Direct mapped leases require immutable
snapshot semantics.

### Make wrapper `deinit` cancel reads asynchronously

Rejected. `deinit` is not a reliable async semantic boundary, and another task
or lease may validly retain the owner. Explicit cancellation and strong ARC
ownership govern separate concerns.

### Implement builders in the same increment

Rejected. Writable exclusivity/freeze has additional transaction semantics and
would obscure the minimum safe immutable read contract.

## Consequences

Positive consequences:

- Core/Storage ownership follows the live acyclic package graph;
- no public pointer or mutable destination survives suspension;
- complete read, cancellation, stale invalidation and commit have one oracle;
- checked erasure retains exact runtime type/binding safety;
- old immutable snapshot owners remain memory-safe without permitting stale
  relabelling;
- contiguous and mapped byte scopes are explicit and non-interchangeable; and
- source remains gated until real mapping/lifetime/platform evidence exists.

Costs and limitations:

- the first safe read profile materialises an owned result;
- synchronization and dynamic dispatch add bounded overhead;
- direct leases are synchronous and read-only;
- externally mutable mapped resources cannot use the initial direct lease;
- exact production limits/allocation recovery remain unproven; and
- this proposal does not complete `ImageData` or persistent identity.

## Affected modules

- `VoxeliaCore`: future backend-neutral binding, private bounded read-result
  target/coordinator, errors, optional lease witnesses and checked erasure.
- `VoxeliaStorage`: future contiguous/mapped owners, bounded-fill provider
  implementations, stable mapping and synchronous resource release.
- `VoxeliaExecution`: later coherent result/identity/provenance/cache
  publication and operation-wide generation/cancellation.
- `VoxeliaMetal`: later dynamic residency; never owns Core storage lifetime.
- `VoxeliaValidation`: focused lifetime, cancellation, race, malformed input,
  mapping and resource-release evidence.

The package graph does not change.

## Compatibility impact

No live public storage protocol or erased handle exists, so this proposal
changes no product ABI/API.

If accepted, controlled sketches and future source migrate as follows:

- backend-neutral protocol/erasure ownership is corrected from CDMS Storage to
  Core while concrete resources remain Storage-owned;
- the async caller-writable pointer destination is replaced by a Core-private
  fixed-capacity checked fill target and committed owned result;
- `read(region:into:)` sketches are replaced by a complete owned-result read or
  a later safe destination adapter with identical transaction semantics;
- exact retained optional witnesses replace caller-supplied capability bits;
- direct/mapped access becomes a synchronous owner-retaining `Data` scope that
  derives `Data.span`/`Data.bytes` at the use site rather than forwarding or
  returning pointers/views;
- mapped change policy becomes explicit; and
- the M1 checklist is corrected to require acceptance/evidence before erasure
  or concrete providers.

Any later compatibility adapter allocates private staging and exposes output
only after successful adoption. It cannot emulate the unsafe lifetime shape.

## Security impact

The decision reduces use-after-free, out-of-bounds, integer-overflow, partial-
publication, replay, cross-provider substitution, stale-generation, TOCTOU,
unbounded-work and diagnostic-leakage risk.

It does not establish provider authenticity, operating-system mapping safety,
file authorisation, cryptographic integrity, secure deletion or denial-of-
service freedom. Opaque in-process identity prevents detectable substitution;
it is not a signature or trust credential.

Actual unsafe/no-copy/mapping code remains blocked and requires minimal scope,
fuzz/fault/memory-pressure testing, sanitiser/race evidence where available and
independent security/lifetime review.

## Performance and memory impact

Read validation is O(rank). Candidate production is O(requested logical byte
count). Transaction admission/finalisation is bounded synchronization work.
Checked erasure adds one bounded dynamic dispatch. Direct lease access is O(1)
after admission and avoids a copy for stable compatible representations.

The initial owned-result profile allocates one exact-capacity private target and
fills it in place, so commit needs no second backing allocation. The request-
count budget bounds active transactions; the byte reservation is co-located
with that target/backing and follows it until the last qualifying result alias
is released, bounding aggregate active and caller-retained read results. Any
proved independent deep copy returned to a caller is caller-owned memory, not
an uncharged alias of the target.

No optimization may expose partial bytes, move validation after access, weaken
owner retention, split the commit gate or convert a mapped representation into
logical samples implicitly.

## Validation impact

Acceptance requires focused evidence for:

- checked platform/host counts, region bounds, byte arithmetic and budgets;
- re-erasing/copying a handle preserves one authority identity and cannot fork
  current state or multiply its per-lineage budget;
- exact provider-instance/descriptor/owner/snapshot/generation binding;
- provider outcomes cannot echo/mint authority; only the Core coordinator
  stamps a private record from the exact retained witness;
- bound-snapshot historical reads remain exact while current-permit reads stale
  atomically on generation displacement;
- checked-`Sendable` single-witness erasure and typed operation availability;
- complete owned read success with no earlier observable candidate;
- private prepared-versus-committed state and cancellation/invalidation in that
  window;
- short, overrun, recoverable-allocation-failure, provider-failure and
  unsupported-operation rejection;
- cancellation while suspended, late completion and zero publication;
- stale invalidation while suspended and no stale-current publication;
- cancelled/stale uncooperative work stays charged until provider drain, so
  cancellation/generation storms cannot reuse occupied capacity;
- explicit commit-wins-versus-cancel/invalidate first-terminal behavior;
- foreign seal/binding denial, replay/duplicate denial and budget release;
- more sequential reads than the tombstone capacity, safe retired-entry
  eviction and non-consuming rejection of an evicted seal replay;
- committed-result budget transfer, retained-result limit rejection and
  exactly-once release after the last result copy;
- shared-backing aliases co-retain the same result/mapping budget token, or a
  returned byte container is proved to be an independent deep copy;
- retained result release remains exact after its terminal tombstone is evicted
  and transaction slot reused;
- monotonic fill rejects duplicate, overlap, gap/out-of-order, concurrent-
  out-of-order, after-close and overrun writes without publication;
- simultaneous same-region and different-region reads within limits;
- limit rejection without provider invocation or allocation;
- source owner retention after caller references are released during a read;
- owned `Data` scope retention and exact `Data.span`/`Data.bytes` read-only
  views;
- direct mapped denial for an externally mutable change policy;
- exactly-once owner/resource deinitialisation after the last read/lease/handle;
- no retain cycle after cancellation/failure/contract violation;
- no provider/user/allocator/destructor work while the Core gate is held and no
  nested provider/Core gate order;
- strict Swift concurrency with no unsafe pointer, detached work, global
  mutable state or Voxelia-authored `@unchecked Sendable`;
- full-compile-negative custom returned `Span`/`RawSpan` configurations; and
- payload/path/identity/seal/digest/address-redacted errors and reflection.

The isolated evidence uses toy owners, Foundation `Data`,
`Synchronization.Mutex` and a deterministic suspension gate. It is not product
API, an actual VM/file mapping, no-copy/unsafe proof, production cancellation
cadence, arbitrary-provider allocation enforcement, allocation-failure
recovery, the production nonforkable provider-admission factory, persistent
identity, authenticity or diagnostic validation.

No complete package suite is required because this increment changes only
documentation and isolated evidence. The focused positive/compile-negative
probe plus documentation, package-graph/import, manifest and release-integrity
checks cover the affected surface.

## Migration

If accepted:

1. publish and accept the storage/data-model RFC;
2. approve and make effective the controlled Foundation/MTA/CDMS/RPSS/
   Requirements/module-overview ownership, destination, capability, milestone
   and publication corrections, including the Foundation-versus-Requirements
   mapped-storage resolution;
3. accept `ADR-0039`, `ADR-0040` and this decision in dependency order only
   with that correction package effective;
4. freeze final Core binding/error/read-result/lease/erasure API names;
5. establish production limits and supported-destination `Data.span`/
   `Data.bytes` builds with strict memory-safety checking;
6. implement checked Core values, transaction gate and type erasure with
   focused Core tests;
7. implement owned contiguous reads with Storage lifetime/cancellation/fault
   tests;
8. implement immutable mapped snapshots and scoped `Data.bytes` access only
   after actual mapping/lifetime review;
9. implement builders/writable storage under a separate accepted contract;
10. integrate identity/provenance/cache publication only through Execution's
    later atomic bundle boundary; and
11. run milestone-wide gates only at the applicable M1 acceptance boundary.

Until then, live storage leaves remain declaration vocabulary and no aggregate,
protocol, lease, erasure or concrete provider source is authorised.

## Supersession

This proposal refines the safe destination/lease/erasure source gate in
proposed `ADR-0039` and composes with proposed `ADR-0040`'s logical/
representation separation. It supersedes neither proposal or the live
controlled baseline while Proposed.

It does not define builders, canonical `ImageData`, persistent identity,
metadata/provenance, cache publication, integrity/digest, tiling/bricking,
compression, remote/sequential transport or Metal residency.

## References

- [Voxelia Project Foundation v0.1.1](../../project/Voxelia_Project_Foundation_v0.1.1.md)
- [Voxelia Master Technical Architecture v0.1.1](../../project/Voxelia_Master_Technical_Architecture_v0.1.1.md)
- [Voxelia Core Data Model Specification v0.1.1](../../project/Voxelia_Core_Data_Model_Specification_v0.1.1.md)
- [Voxelia Repository and Package Scaffold Specification v0.1.1](../../project/Voxelia_Repository_and_Package_Scaffold_Specification_v0.1.1.md)
- [Voxelia Requirements Baseline v0.1.1](../../project/Voxelia_Requirements_Baseline_v0.1.1.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)
- [Voxelia Validation and Benchmark Strategy v0.1.1](../../project/Voxelia_Validation_and_Benchmark_Strategy_v0.1.1.md)
- [ADR-0039 - Closed storage capability and descriptor admission boundary](ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md)
- [ADR-0040 - Normalized logical sample and representation projection boundary](ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md)
- [ADR-0041 storage read/lifetime probe](../../progress/evidence/ADR-0041-storage-read-lifetime-probe.swift)

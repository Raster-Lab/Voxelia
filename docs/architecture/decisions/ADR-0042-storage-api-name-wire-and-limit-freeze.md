---
document_id: "ADR-0042"
title: "Storage API name, wire and limit freeze"
status: "Accepted"
date: "2026-08-04"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-GOV-006"
  - "VOX-API-001"
  - "VOX-API-003"
  - "VOX-API-004"
  - "VOX-STO-001"
  - "VOX-STO-002"
  - "VOX-STO-003"
  - "VOX-STO-004"
  - "VOX-ERR-001"
  - "VOX-ERR-007"
  - "VOX-SEC-006"
  - "VOX-VAL-007"
---

# ADR-0042 - Storage API name, wire and limit freeze

## Context

Accepted `ADR-0039` through `ADR-0041`, composed by the `RFC-0001`
directional review and made effective through `CCR-0016`, fixed the storage
contract's semantics but deliberately deferred final public Swift names,
any operational wire and production resource ceilings to a focused
review/decision artefact (`RFC-0001` approval-order step 4, unresolved
questions 2, 3, 5 and 7). This record is that artefact. It was reviewed
and accepted by the project owner on 2026-08-04 through interactive
decision review. It freezes vocabulary and policy only; it does not add
source, and steps 5 through 11 of the `RFC-0001` approval order remain
their own gates.

## Decision

### Public naming profile

The reviewed conceptual categories become the public Swift vocabulary,
one name per semantic role, owned by `VoxeliaCore`:

| Category | Frozen public name |
|---|---|
| Logical sample binding | `LogicalSampleBinding` |
| Representation descriptor (tagged) | `StorageRepresentationDescriptor` |
| Immutable snapshot handle | `StorageSnapshotHandle` |
| Closed optional operation set | `StorageOperation` plus per-operation retained witnesses |
| Owned complete read result | `RegionReadResult` |
| Owner-retaining byte lease scope | `StorageByteLease` |
| Checked erased handle | `AnyImageStorage` (controlled name retained) |
| Typed failure family | `StorageContractError` |

Documentation, tests and controlled corrections use exactly these names.
Renaming any of them after implementation is a reviewed pre-1.0
compatibility decision, not a refactor.

### Error surface

`StorageContractError` is one closed, payload-free, value-redacted enum in
the established house style:

```swift
public enum StorageContractError: Error, Sendable, Equatable {
    case invalidRegion
    case incompatibleBinding
    case unsupportedOperation
    case resourceLimitExceeded
    case allocationFailed
    case cancelled
    case staleSnapshot
    case providerFailure
    case contractViolation
}
```

Cases carry no region, count, offset, path, provider message or underlying
error. Provider-originated failures map to `providerFailure` without
retaining the provider's error; privileged operational detail belongs to
host-governed channels. Error precedence follows the `ADR-0041` state
machine: pre-admission rejections (`invalidRegion`,
`incompatibleBinding`, `unsupportedOperation`, `resourceLimitExceeded`)
occur while unstarted and invoke no provider; the first terminal event
after admission wins.

### Wire policy

No persistent operational wire exists at M1. Characteristics, operation
sets, witnesses, snapshot handles, results and leases are in-process
values with no `Codable` conformance. A future persistent or distributed
capability/operational wire requires its own versioned decision with an
explicit schema, unknown-field policy and milestone owner; nothing in
this freeze may be serialised by convenience.

### Limit policy

Every ceiling is an explicit caller-supplied limits value with no
permissive defaults, following the accepted `VCMJ-1` pattern: request
counts, expected byte counts, active-plus-retained result byte budgets
and per-authority-domain budgets are all inclusive checked `UInt64`
ceilings the caller must select. Hard implementation maxima that cap
caller selections are deferred to the recorded lowest-resource
supported-device evidence campaign already tracked in the progress
ledger; probe values are not production defaults. Checked arithmetic
precedes every allocation, and a failed charge does not mutate
transaction state.

## Alternatives considered

Short pragmatic names were rejected because they diverge from the
reviewed RFC vocabulary and the controlled `ImageData` sketch. Contextual
rich errors were rejected because associated payloads leak paths, sizes
and provider text past the redaction discipline every accepted boundary
uses. Freezing numeric production ceilings now was rejected because the
composed ADRs require device evidence first. An M1 capability wire was
rejected because it would freeze an M9-relevant schema through an M1
guess. Deferring naming again was rejected because the RFC forbids
resolving names implicitly through the first implementation.

## Consequences

- `RFC-0001` unresolved questions 2, 3, 5 and 7 are closed; questions 1
  (already selected in `CCR-0016`) and 4, 6, 8 through 14 remain open.
- Steps 5 through 7 of the approval order (compatibility projections,
  Core contracts, one owned contiguous provider) are unblocked as their
  own increments; steps 8 through 11 remain gated.
- The frozen names become pre-1.0 compatibility surface on first
  implementation.

## Affected modules

`VoxeliaCore` owns every frozen name and the error family. `VoxeliaStorage`
implements providers behind them. No dependency edge changes.

## Compatibility impact

No storage source exists, so the freeze moves no compiled symbol. The
retained `AnyImageStorage` name keeps the controlled `ImageData` sketch
readable without a `Core -> Storage` edge, per `CCR-0016-A`.

## Security impact

Payload-free errors and the no-wire policy prevent path, size, provider
and capability disclosure through diagnostics or serialisation. Caller
limits keep hostile-input budgeting explicit; deferred hard maxima are a
recorded gap, not an unbounded surface, because every operation still
requires explicit caller ceilings.

## Performance and memory impact

None in this increment. The limits policy defers production ceiling
selection to measured device evidence rather than guessing.

## Validation impact

This freeze is documentation-only: the documentation gate, ADR register,
requirement-index and release-integrity checks cover the changed surface.
Implementation increments must add the focused evidence lists from
`ADR-0039` through `ADR-0041` under these frozen names.

## Migration

1. This record closes `RFC-0001` step 4 for the frozen items.
2. Step 5 (lossless logical/representation compatibility projections) and
   step 6 (checked Core descriptors, admission, transaction, result and
   erasure) proceed as separate user-requested increments under the
   accepted source-gate evidence obligations.
3. Step 7 implements one owned contiguous `VoxeliaStorage` provider with
   bounds, cancellation, allocation-failure, race, lifetime and release
   tests.
4. Hard implementation maxima are selected when the device-evidence
   campaign closes; until then caller limits govern.

## Supersession

This ADR supersedes no accepted decision. It completes the naming, wire
and limit items deferred by `ADR-0039` through `ADR-0041` and `RFC-0001`
and does not reopen their semantics.

## References

- [RFC-0001 - Storage contract and logical data-model composition](../../rfcs/RFC-0001-storage-contract-and-logical-data-model-composition.md)
- [ADR-0039 - Closed storage capability and descriptor admission boundary](ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md)
- [ADR-0040 - Normalized logical sample and representation projection boundary](ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md)
- [ADR-0041 - Safe storage read transaction and type-erasure lifetime boundary](ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md)
- [CCR-0016 - RFC-0001 storage composition corrections](../corrections/CCR-0016-rfc-0001-storage-composition-corrections.md)

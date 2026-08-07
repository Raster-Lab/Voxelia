---
document_id: "ADR-0306"
title: "Residency duplication analysis"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-GOV-005"
  - "VOX-MTL-009"
---

# ADR-0306 - Residency duplication analysis

## Context

`ADR-0305` opened `VOX-MTL-009` — "the backend shall minimise full-volume CPU-to-GPU
duplication" — and fixed what each of its three verification methods requires. This supplies
the **`A`** and the **`T`**. The **`D`** remains with the owner.

## The analysis

The claim to establish is that a caller asking for a volume on the GPU does not thereby cause
a second full-volume copy to exist.

**On this hardware it does not, and the reason is structural rather than incidental.**
`MetalResidencyManager.makeBuffer` reaches exactly one allocation, and the storage mode it
passes is decided by `selection(for:)`:

```text
.automatic / .shared   -> .shared        -> MTLResourceOptions.storageModeShared
.gpuOptimised          -> .privateDevice -> MTLResourceOptions.storageModePrivate
```

A `storageModeShared` buffer is **one range of memory that the CPU and the GPU both address**.
There is no host copy and no device copy; there is the buffer. So under `.automatic` — the
default — a full-volume duplicate does not exist at any point.

`storageModePrivate` **is** a duplicate, and it is the correct answer to `.gpuOptimised`: a
caller declaring repeated GPU access is asking to trade the copy for access speed. The
requirement says *minimise*, not *forbid*, and the distinction is the caller's to make.

The analysis has a **second branch, and it is not exercised on this host.** `.automatic` and
`.shared` both require `context.supportsUnifiedMemory`; where that is false they throw
`sharedStorageUnavailable`. So on a device without unified memory the guarantee is not
"shared storage" but "a typed refusal rather than a silent copy" — the caller learns that its
declared policy cannot be met instead of receiving a duplicate it did not ask for. This
follows from `ADR-0081`'s rule that the manager "never mutates a declared policy".

Three policies allocate nothing at all. `.cpuOnly` throws `policyRequiresNoDeviceResidency`,
and `.streamed` and `.sparse` throw `unsupportedResidencyPolicy`. The two cases are kept
distinct because collapsing them would lose the difference between *this policy means no GPU
copy* and *this policy is not implemented yet*.

## Decision

1. **`VOX-MTL-009`'s `A` is discharged** by the argument above.
2. **Its `T` is discharged** by six tests, tagged to the requirement.
3. **The evidence is the allocated buffer's storage mode, not the selection enum.** Asserting
   the selection alone proves what the manager *intends*; asserting `MTLBuffer.storageMode`
   proves what it *allocates*, and only the second is about duplication.
4. **Nothing is borrowed from `ResidencyPolicyTests`**, per `ADR-0305`. Those tests assert a
   vocabulary exists and is `Sendable`, and relabelling them would have put this requirement's
   name on evidence that does not address it.
5. **Its `D` is not claimed**, and remains an owner item.

## The tests, and what each would catch

- **Shared allocates one buffer both processors address** — `.automatic` and `.shared` both
  yield `storageMode == .shared` at 4,096 bytes. This is the row's subject.
- **The GPU-optimised policy is the one that does duplicate** — `.gpuOptimised` yields
  `.private`. Without this contrast the first test would pass for a manager that ignored its
  input and returned shared storage unconditionally.
- **An unfulfillable policy refuses by its own distinct case** — `.cpuOnly` separately from
  `.streamed` and `.sparse`.
- **A refused policy allocates nothing.** A manager that refused the *selection* and then
  allocated anyway would satisfy the previous test and still duplicate the volume, so the
  refusal is checked on the allocation path too.
- **An empty allocation is refused before any policy is consulted** — `invalidByteCount` for a
  policy that would otherwise succeed, so a zero-length request cannot yield a zero-length
  device buffer that a later read treats as a volume.
- **This host is the unified-memory branch** — recorded explicitly, because only one of the
  analysis's two branches is exercised here and the evidence should say which.

## Alternatives considered

### Measure peak working set instead

Rejected, and `ADR-0305` decision 3 had already ruled it out. `ADR-0271` established that a
combined benchmark run retains several intermediates and its peak is a harness artefact; a
duplication claim measured that way measures the harness.

### Assert `contents()` is non-nil for shared and nil for private

Rejected. It is the more direct statement of "the CPU can address this", but Metal's Swift
signature returns a non-optional pointer, so the assertion would depend on runtime behaviour
the type system does not express. `storageMode` states the same fact declaratively.

### Exercise the non-unified-memory branch with a stub context

Rejected as fabrication. A stub would assert that a hand-written double throws, which is a
fact about the double. The branch is named in the analysis and left unexercised, which is the
honest record of what this host can show.

### Claim the `D` from these tests

Refused, consistently with `ADR-0300`, `ADR-0303` and `ADR-0304`.

## Consequences

`VOX-MTL-009` has its analysis and its tests. It stays open on its Demonstration alone.

**11 entered-milestone rows remain** from `ADR-0290`'s sweep — the row is not fully discharged,
so the count is unchanged.

## Affected modules

None. Six tests in `VoxeliaMetalTests`; no source file changed.

## Compatibility impact

None.

## Security impact

None.

## Performance and memory impact

None to the product. The suite allocates a handful of 4,096-byte buffers.

## Validation impact

```text
swift build && swift test
swift test --filter "ResidencyDuplicationTests"
swift format lint --strict Tests/VoxeliaMetalTests/ResidencyDuplicationTests.swift
python3 Tools/Scripts/check_swift_safety.py
Tools/Scripts/validate-docs.sh
python3 Tools/Scripts/check_release_integrity.py --write
```

1235 tests in 218 suites pass, up from 1229 in 217.

## Migration

1. This record and six tests. No source changed.
2. **Next**: the derived queue's remaining rows.
3. **Owner**: unchanged — `VOX-MTL-009`'s Demonstration was already listed by `ADR-0305`.

## Supersession

This record supersedes nothing. It **supplies** two of the three methods `ADR-0305` scoped.

## References

- [ADR-0081 - Metal residency strategy](ADR-0081-metal-residency-strategy.md)
- [ADR-0271 - Compression benchmark and random access](ADR-0271-compression-benchmark-and-random-access.md)
- [ADR-0300 - CPU Metal differential references](ADR-0300-cpu-metal-differential-references.md)
- [ADR-0305 - Open the residency duplication row](ADR-0305-open-the-residency-duplication-row.md)
- [Voxelia First Vertical Slice Plan v0.1.1](../../project/Voxelia_First_Vertical_Slice_Plan_v0.1.1.md)

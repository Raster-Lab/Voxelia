---
document_id: "ADR-0186"
title: "Governed Metal shared-buffer transfer boundary"
status: "Accepted"
date: "2026-08-05"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-PLT-009"
  - "VOX-CON-004"
  - "VOX-MTL-001"
  - "VOX-MTL-004"
  - "VOX-MTL-007"
  - "VOX-MTL-014"
  - "VOX-VAL-007"
  - "VOX-ERR-001"
  - "VOX-SEC-001"
  - "VOX-SEC-002"
---

# ADR-0186 - Governed Metal shared-buffer transfer boundary

## Context

The fail-closed Swift strict-memory-safety gate now reaches `VoxeliaMetal` and
stops on thirteen diagnostics in the three accepted compute-kernel wrappers.
Those diagnostics are the host upload, inline parameter binding and completed
shared-buffer readback operations required by `ADR-0080`, `ADR-0096` and
`ADR-0132`. The accepted Metal residency strategy also requires real shared-
buffer transfer evidence.

The installed Xcode 26.6 / macOS 26.5 SDK audit found no checked API pair for
arbitrary in-memory upload and exact raw readback at Voxelia's deployment
floors. MetalKit supplies a checked `Data` upload through Model I/O mesh-buffer
semantics, but no checked inverse; it would cross the existing module boundary
without closing the gate. Blit commands move resources but cannot originate or
return arbitrary host bytes. Operational Metal therefore needs one explicit
reviewed memory boundary or must be deferred/redesigned.

On 2026-08-05 the project owner explicitly approved Option A from the recorded
audit and authorised an independent subagent review. The independent reviewer
approved this design with the conditions captured in the companion evidence.

## Decision

1. **One internal file owns every marked operation.**
   `Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift` will contain one
   stateless, non-public `MetalBufferTransfer` namespace and one internal,
   payload-free `MetalBufferTransferError`. No raw pointer, borrowed buffer,
   no-copy storage, generic value transfer or marked declaration may appear in
   any signature. No package target or framework import is added, and the
   transfer boundary itself adds no public API.
2. **The boundary has exactly three marked byte-owned operations.** It may
   synchronously write a nonempty owned `[UInt8]` into one validated existing
   `.storageModeShared` buffer range; bind a nonempty, locally bounded
   `[UInt8]` inline to a live `MTLComputeCommandEncoder`; and return a fresh
   owning `[UInt8]` copied from one validated shared-buffer range after the same
   writer command buffer has completed. A checked allocate-and-delegate
   convenience may create a new shared buffer and call the same write operation
   without adding a marked expression. The owned write completes before return,
   and the SDK documents inline binding as a synchronous copy; source storage is
   retained through each call.
3. **Every range and allocation is checked before access.** Allocation and
   write counts must be positive and no greater than `device.maxBufferLength`;
   allocation failure is typed; the returned buffer must cover the requested
   length and report shared storage. Write/read offset and count must be
   nonnegative/positive, their sum must not overflow, and the end must not
   exceed `MTLBuffer.length`. Private, managed and memoryless resources reject
   before content access. Inline binding requires a nonnegative index and uses
   a Voxelia-local 256-byte ceiling, comfortably above the largest accepted
   28-byte parameter block and intentionally below general payload-transfer
   scope.
4. **Completion and ownership are structural invariants.** A GPU result may be
   read only when the same writer command buffer reports `.completed`; `.error`
   maps distinctly from every not-yet-completed state. The boundary never waits
   on an uncommitted command. Callers retain per-invocation input, output and
   parameter values until their synchronous command wait finishes, and no
   concurrent CPU writer or other GPU command may touch the accessed range.
   The three kernels already satisfy this by using invocation-local resources.
5. **Scalar layout is explicit rather than borrowed.** A separate checked
   internal serializer converts `UInt32` words into exact little-endian bytes
   with overflow-preflighted output capacity. `Float` uses its exact
   `bitPattern`, and `Int32` uses `UInt32(bitPattern:)`. The window parameter
   block is exactly 28 bytes in MSL field order, composite is exactly 8 and
   invert exactly 4; composite opacity values are serialized word by word. No
   Swift struct or `[Float]` storage layout is transferred.
6. **Counts narrow exactly.** Sample, element and layer counts use
   `UInt32(exactly:)`; representability failure maps to the owning kernel's
   existing typed malformed-input category, or a new payload-free category
   where none exists. Packed products and serializer capacities use reporting-
   overflow arithmetic.
7. **The scanner exception is operation-exact and fail closed.** The safety
   scanner continues to inspect the complete file and all other repository
   sources. It may suppress only the three expected reserved expression
   markers in this exact path when the full file SHA-256 and expected finding
   multiset match the independently reviewed implementation. Any byte change,
   extra or different prohibited category, moved file or marker elsewhere
   fails. The exception grants no concurrency annotation, compiler flag or
   declaration-level escape.
8. **Failures remain private and payload-free.** Internal cases distinguish
   invalid byte count/range, unsupported storage, allocation failure, invalid
   inline binding, incomplete command and failed command. Kernel allocation
   faults map to existing public allocation failures; binding, completion,
   coherency and read faults map to existing execution failures. No bytes,
   counts, offsets, device strings or source values enter diagnostics.

## Alternatives considered

Preserving the zero-exception policy was rejected by the owner because it
requires operational Metal deferral or a larger GPU-resident public-contract
redesign that conflicts with the accepted M3/M4 path. A C or Objective-C shim
was rejected because it hides the same proof outside the semantic Swift gate
and adds a target and foreign-code review surface. A MetalKit mesh allocator was
rejected because it introduces Model I/O semantics and still cannot read back.
Allocating a separate parameter buffer was rejected because Metal's inline
binding already copies synchronously; wrapping it in the same boundary keeps
the existing lifetime and allocation behaviour with no additional marked
surface.

## Consequences

The unavoidable Metal host-memory bridge becomes one visible, fingerprinted
and independently reviewed internal boundary. Checked callers cannot obtain or
retain a pointer, and all public scientific APIs remain Metal-independent. Any
future boundary change requires a new fingerprint, independent review evidence
and policy update.

## Affected modules

`VoxeliaMetal` product and test targets, plus the repository Swift-safety
checker. No package dependency changes.

## Compatibility impact

No wire change. The pre-1.0 public `MetalInvertKernelError` vocabulary gains the
additive payload-free `invalidSampleByteCount` case because no existing case
correctly classifies exact count-representability failure; exhaustive source
switches must adopt that case.

## Security impact

The boundary rejects invalid ranges, unsupported storage and incomplete work
before access; returns owned copies; discloses no payload; and exposes no raw or
borrowed memory. Its exact file content and three markers are scanner-pinned.

## Performance and memory impact

Upload and readback each make the same one required copy as the existing
kernel path. Inline binding preserves Metal's existing synchronous-copy
behaviour and adds no parameter-buffer allocation. Manual scalar serialization
allocates small bounded byte arrays; composite opacity serialization replaces
the former implicit raw-array bridge with an equal-size explicit copy.

## Validation impact

Focused evidence must cover exact one-byte, non-power-of-two and parameter-size
write/readback; lower/upper write and read range boundaries plus zero, negative,
overflow and out-of-bounds rejection; private-storage rejection before access; incomplete
versus failed/completed command classification where deterministically
available; returned-copy lifetime; concurrent independent transfers; exact
28/8/4-byte parameter and float-opacity goldens; and the residency round trip.
All three kernel digest, differential, exactness, padding and concurrency suites
must remain green. Scanner regression tests must prove the exact fingerprint is
accepted while a byte mutation, extra/different marker, wrong path and marker
elsewhere fail. The complete semantic `--compile` gate must then pass beyond
the former Metal diagnostics.

## Migration

Replace the three kernels' implicit array/struct bridges and direct readback
with the boundary, and replace the residency test's direct buffer access. No
transfer-API migration exists; exhaustive switches over
`MetalInvertKernelError` must adopt the additive error case.

## Supersession

This record narrows the host-transfer implementation of accepted `ADR-0080`,
`ADR-0081`, `ADR-0096` and `ADR-0132`; it supersedes none of their numerical or
residency semantics. The earlier prospective `ADR-0186` label for the geometry
dependency decision was not an accepted record; that future decision moves to
`ADR-0187`.

## References

- [Strict-memory Metal transfer audit](../../progress/evidence/SWIFT_STRICT_MEMORY_METAL_TRANSFER_AUDIT_2026-08-05.md)
- [Independent review evidence](../../progress/evidence/ADR-0186-metal-buffer-transfer-independent-review.md)
- [Swift safety policy](../../security/SWIFT_SAFETY_POLICY.md)
- [ADR-0080 - Window-level Metal kernel](ADR-0080-window-level-metal-kernel.md)
- [ADR-0081 - Metal residency strategy](ADR-0081-metal-residency-strategy.md)
- [ADR-0096 - Layer compositing Metal kernel](ADR-0096-composite-metal-kernel.md)
- [ADR-0132 - Device invert kernel](ADR-0132-device-invert-kernel.md)

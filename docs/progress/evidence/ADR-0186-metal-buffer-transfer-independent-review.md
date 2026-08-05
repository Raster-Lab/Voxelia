# ADR-0186 independent Metal transfer review

## Review identity and independence

- Review date: 2026-08-05.
- Reviewer: Codex independent subagent `/root/metal_boundary_reviewer`,
  explicitly authorised by the project owner.
- Role: read-only safety reviewer; the reviewer authored no repository change
  and made no commit.
- Scope: the installed-SDK audit, governing v0.1.1 memory/Metal requirements,
  accepted Metal ADRs, Swift safety policy, three compute wrappers and the
  residency tests.

## Design disposition

**Approved with conditions; no blocking objection.** The audit proves that the
supported SDK has no checked arbitrary upload/readback pair. One internal,
byte-only Swift boundary in `VoxeliaMetal` is therefore justified and is safer
than a foreign shim or a Model I/O-backed partial route.

The reviewer requires:

1. exactly one internal `MetalBufferTransfer.swift` file, one stateless
   namespace and one payload-free internal error;
2. only owned-byte write into a validated existing shared buffer,
   synchronously copied inline binding and exact owned readback APIs, with a
   safe allocate-and-delegate convenience but no generic values, raw-pointer
   signatures, no-copy storage, stored encoder/buffer state or public surface;
3. positive bounded allocation/binding sizes, checked offset-plus-count
   arithmetic, exact buffer-length coverage and `.shared` storage validation;
4. readback only after the same writer command reports `.completed`, with
   `.error` distinct from not-yet-completed states and no wait on uncommitted
   work;
5. invocation-local logical ownership with no concurrent CPU or unrelated GPU
   access to the range;
6. manual exact little-endian serialization of `Float`, `UInt32` and `Int32`
   values, exact 28/8/4-byte parameter blocks and no raw Swift struct or
   `[Float]` layout transfer;
7. `UInt32(exactly:)` narrowing and reporting-overflow preflight for products
   and serializer capacity;
8. one exact-path scanner exception conditioned on a full-file SHA-256 and
   expected marker multiset, while every other category and source remains
   fail closed; and
9. focused range/storage/completion/lifetime/concurrency/serialization tests,
   all affected kernel and residency evidence, scanner mutation tests and the
   complete semantic gate.

The reviewer recommends keeping Metal's synchronous-copy `setBytes` operation
inside the same boundary rather than allocating a parameter buffer per
dispatch. This preserves the accepted performance/lifetime behaviour without
expanding the marked surface.

The initial draft's create-only upload operation could not preserve the
accepted residency test's manager-buffer CPU-write subject. Review corrected
the first marked operation to a bounded write into an existing shared buffer;
the creation convenience delegates to it without another marker.

## Blocking conditions

The reviewer would reject a generic raw-memory helper, readback without same-
command completion evidence, private/managed content access, implicit Swift
struct or float-array layout transfer, a whole-file scanner exclusion, a
foreign shim, or expansion into public scientific, residency or scheduling
APIs.

## Final implementation review

The independent reviewer inspected the complete boundary/scanner implementation
after two corrective passes and issued final approval for enabling
`SWIFT-MEM-001` at the exact fingerprint
`161b5298d68bfc1e6e312f650458db3e41e6b9ca418f6a49c486ff86e53c7aa9`.
The first pass rejected tests that paired readback with an unrelated completed
command, permitted the scanner exception without its policy and referenced
macOS-only managed storage on every platform. The corrected tests use a real
upload-to-readback blit and pass its exact writer, the scanner requires both
governance artifacts, and managed-storage evidence is macOS-conditional while
private-storage rejection remains cross-platform. Negative allocation and
transfer counts were added.

The second pass found that two blit tests relied on Metal's retained-reference
default instead of satisfying the stricter documented caller-lifetime rule.
Both now retain their upload buffer explicitly through exact command
completion, including the concurrent asynchronous path. After that correction,
the reviewer independently rechecked the exact three markers and file hash,
owned-byte signatures, overflow and storage validation, same-writer status
split, owned readback, scalar serialization and fail-closed scanner rules. The
reviewer's reruns passed all eight boundary tests, all fifty-two scanner unit
tests, the raw inventory scan and diff validation, with no remaining boundary
blocker.

This approval completed the boundary/scanner stage only. The same reviewer's
later three-kernel and residency migration inspection is recorded below. The
complete semantic gate still must pass before `ADR-0186` is declared fully
implemented.

## Migration implementation review

The same independent reviewer inspected the three-kernel and residency
migration. The first pass rejected one error-mapping collapse: each kernel
mapped every upload-preparation failure to public `bufferAllocationFailed`,
although `ADR-0186` requires an unexpected storage/coherency fault to map to
`executionFailed`. The review also required a direct unrepresentable
`layerCount` assertion alongside the existing element-count and packed-product
checks.

The corrected implementation shares one internal payload-free classifier.
Only invalid/capacity byte count and allocation failure classify as allocation;
range, unsupported storage, inline binding, incomplete/failed command and
unknown errors classify as execution. Regression evidence covers every class,
and direct element- and layer-count narrowing plus packed-product overflow are
all exercised. The reviewer then independently rechecked the exact 28/8/4-byte
MSL layouts, `Float` and `Int32` bit serialization, same-writer completed
readback, per-dispatch resource lifetimes, residency blit lifetime, unchanged
concurrency isolation, additive payload-free invert error and scanner
containment.

Final migration approval was issued with no remaining blocker. The reviewer's
expanded filter passed all twenty-five tests across the boundary, window,
composite, invert and residency suites with unchanged differential evidence;
the raw safety inventory, exact three-marker count, unchanged boundary SHA-256
and diff validation passed. The six unrelated test-only C-format initializers
were subsequently replaced with bounded Swift encoders and their focused suites
passed. The complete semantic gate progressed beyond them but remains red on
the unrelated `MetadataBinaryTests` pointer-backed no-copy ownership fixture,
so `ADR-0186` is still not declared fully implemented.

## Governance-draft review

The reviewer inspected the complete ADR, policy, register, ledger and evidence
diff after the create-only correction, exact public-error compatibility wording,
historical policy clarification and prospective geometry renumbering. The
governance design is accepted with no remaining objection. The later boundary/
scanner and migration implementation reviews are recorded above.

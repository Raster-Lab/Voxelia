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

Pending. The same independent reviewer will inspect the complete implementation
and verification diff before the exception fingerprint is accepted for push.

## Governance-draft review

The reviewer inspected the complete ADR, policy, register, ledger and evidence
diff after the create-only correction, exact public-error compatibility wording,
historical policy clarification and prospective geometry renumbering. The
governance design is accepted with no remaining objection. This acceptance does
not substitute for the pending implementation-diff review.

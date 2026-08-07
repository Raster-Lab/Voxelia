---
document_id: "ADR-0403"
title: "Runtime plug-ins not introduced"
status: "Accepted"
date: "2026-08-07"
owners:
  - "Voxelia Project"
affected_requirements:
  - "VOX-EXT-007"
  - "VOX-EXT-008"
  - "VOX-EXT-009"
---

# ADR-0403 - Runtime plug-ins not introduced

## Context

The `ADR-0397` plug-in arc. The three rows are conditional or
negotiation rows: a versioned stable boundary **if** runtime binary
plug-ins are introduced; explicit capability negotiation; out-of-
process execution for untrusted plug-ins **where the platform permits
it**. `ADR-0379` made source-level packages the primary extension
mechanism; the question this arc answers is what happens to the
runtime rows when their condition is unmet.

## Decision

1. **Runtime binary plug-ins are not introduced at M9**
   (`VOX-EXT-007`). The row's condition is unmet, and the record binds
   the future: if they are ever introduced, the boundary is a
   **versioned stable interface** — a C-compatible or serialised-IPC
   surface with its own semantic version — never an assumption of
   Swift compiler ABI compatibility across toolchains. Whether to
   introduce them at all is the `R` half, and it joins the owner batch
   rather than being decided here by omission.

2. **Capability negotiation is explicit and already has one seam**
   (`VOX-EXT-008`): `CapabilityNegotiation.negotiate` intersects a
   requirer's declared capability tokens against an offerer's and
   refuses typed on any missing token — the same vocabulary the
   `ADR-0380` contract and the `ADR-0402` worker admission already
   speak. The seam serves source-package extensions today and is the
   negotiation any future runtime boundary must route through; nothing
   negotiates implicitly.

3. **The out-of-process question is documented, not presumed**
   (`VOX-EXT-009`): with no runtime plug-ins there is nothing to
   isolate, and the extension-mechanism document records the
   direction — untrusted runtime plug-ins, if introduced, execute out
   of process where the host platform permits (XPC on Apple
   platforms), with the in-process option reserved for
   distribution-trusted code. The `D` half is that document plus this
   record.

## Alternatives considered

### Building the versioned boundary now, unused

Rejected. An unexercised ABI boundary is untested surface area
pretending to be safety; the rows gate a future introduction, and the
gate is this record.

## Consequences

M9 arc 5 closes as records plus one small seam; the Apple adapter and
energy arc remains.

## Affected modules

`VoxeliaExecution` gains `CapabilityNegotiation`; the extension
document gains the runtime section's resolution.

## Compatibility impact

Additive only.

## Security impact

Recorded direction: untrusted runtime code out of process, if ever
introduced.

## Performance and memory impact

None.

## Validation impact

```text
swift test --filter CapabilityNegotiationTests
swift test
```

The full suite must show the literal pass line before push.

## Migration

1. This record, the seam, the document update, the witness and the
   register updates, in the same increment.
2. **Next**: the Apple adapter and energy arc ends M9's queue.
3. **Owner**: whether runtime binary plug-ins are ever introduced,
   batched.

## Supersession

This record supersedes nothing; `ADR-0379` stands.

## References

- [ADR-0379 - The source-package extension mechanism](ADR-0379-the-source-package-extension-mechanism.md)
- [ADR-0380 - The registration declaration contract](ADR-0380-the-registration-declaration-contract.md)
- [ADR-0402 - Distributed integrity](ADR-0402-distributed-integrity.md)
- [The extension mechanism](../extension-mechanism.md)

# Strict-memory Metal transfer audit — 2026-08-05

## Scope and result

This read-only audit covers the thirteen product diagnostics left by
`python3 Tools/Scripts/check_swift_safety.py --compile` after the checked
shader-digest recovery. They are confined to the window-level, composite and
invert kernel wrappers: four host-to-buffer uploads, three parameter-byte
bindings and three shared-buffer readbacks reported as six compiler
expressions.

The installed supported-development toolchain provides no checked in-memory
Metal API that completes both arbitrary raw upload and exact raw readback.
MetalKit offers a checked `Data`-to-`MTLBuffer` upload route through its mesh
allocator, but it has no checked buffer-to-`Data` inverse and its Model I/O
semantics cross the current `VoxeliaMetal` architecture boundary. Operational
Metal cannot pass the zero-exception policy without a governed decision.

## Audited environment

- Xcode 26.6, build 17F113.
- Apple Swift 6.3.3, target `arm64-apple-macosx26.0`.
- macOS 26.5 SDK at the active Xcode SDK path.
- Repository deployment floors remain macOS 15, iOS 18, tvOS 18 and visionOS
  2; an API available only in the 26 generation is therefore not a solution.

## Installed SDK findings

| API family | Host upload | Exact host readback | Result |
|---|---|---|---|
| `MTLDevice` / `MTLBuffer` | Length-only allocation is checked; initial bytes use `const void *` | `contents` returns `void *` | Does not provide a checked transfer pair |
| `MTLComputeCommandEncoder` | Existing `MTLBuffer` binding is checked; inline bytes use `const void *` | Not applicable | Parameter bytes require a buffer or reviewed memory boundary |
| `MTLBlitCommandEncoder` | Resource-to-resource copy and constant-byte fill are checked | Resource-to-resource copy only | Cannot originate arbitrary host bytes or return bytes to a collection |
| `MTLIOCommandBuffer` | Can load a file handle into an `MTLBuffer` | No corresponding buffer-to-file/collection store | Adds disallowed spool/storage semantics and still lacks readback |
| `MTKMeshBufferAllocator` | `newBuffer(with: Data, type:)` type-checks under the strict oracle and exposes the backing buffer plus offset | Mapping returns a pointer; no `Data` property exists | Partial upload only; explicitly built on Model I/O mesh-buffer semantics |
| `MTKTextureLoader` | Accepts encoded image `Data` | No raw buffer readback | Changes representation, colour and kernel contracts |
| Metal tensors | Replace/get slice methods take pointers and require the 26-generation API | Pointer-based | Fails both strict-memory and deployment-floor requirements |

The SDK headers also state that CPU/GPU buffer access is not automatically
synchronised and that the caller owns coherency. Any accepted boundary must
therefore bind storage mode, byte range, command completion and object lifetime
as well as pointer validity.

## Compiler probes

The controlled upload probe imported Foundation, Metal and MetalKit and called
`MTKMeshBufferAllocator.newBuffer(with: Data(bytes), type: .custom)`. It passed:

```text
xcrun swiftc -typecheck -strict-memory-safety -warnings-as-errors ...
exit 0
```

The paired direct readback probe attempted to copy
`buffer.contents()` into `Data`. The compiler rejected the expression:

```text
error: expression uses unsafe constructs but is not marked with 'unsafe'
note: reference to instance method 'contents()' involves unsafe type
      'UnsafeMutableRawPointer'
exit 1
```

These probes establish compiler classification only. They are not lifetime,
coherency, performance or multi-destination evidence.

## Architecture and downstream inventory

The approved vertical slice assigns the shared-buffer bridge to
`VoxeliaMetal`, but the scaffold prohibits direct Model I/O imports there.
Using `MTKMeshBufferAllocator` for arbitrary compute payloads would introduce
Model I/O mesh allocation semantics indirectly, still leave readback blocked
and require architecture confirmation plus new allocation/performance evidence.

Once product compilation advances, static audit also predicts related test
recoveries: four pointer-backed integer-byte serialisations in Metal tests and
one direct shared-buffer round-trip in `MetalResidencyManagerTests`. Those can
use checked integer serialisation and any eventually accepted transfer helper.
The separate no-copy backing test in `MetadataBinaryTests` is not part of the
Metal decision and must be recovered independently when reached by the
compiler.

## Decision options

### A. Narrow explicit Swift boundary — recommended

Approve one internal `MetalBufferTransfer` implementation that exposes only
checked owned-byte upload/readback signatures. Confine compiler-marked memory
operations to that file, validate allocation length, storage mode and requested
range, retain the buffer through the immediate copy, require completed command
buffers before readback, and manually serialise parameter/scalar bytes with
checked arithmetic. The three kernels and tests call only the checked wrapper.

This option keeps the boundary visible to Swift's compiler and reviewers and
avoids a framework/package dependency. It requires a dedicated policy/ADR
change because the current exception inventory is empty. The policy requires
an exact owner and invariant, focused bounds/lifetime/coherency/failure tests,
an independent reviewer and a scanner exception narrowed to the exact
declaration or file.

### B. Objective-C or C shim — not recommended

An object-only shim could accept `NSData`, perform the pointer copies in foreign
code and return `NSData`/`MTLBuffer`, making Swift compilation appear checked.
This adds a target and dependency edge while moving the same memory proof
outside the semantic Swift gate. It would need its own foreign-code safety,
sanitizer and lifetime governance and is weaker than an explicit Swift
boundary.

### C. Preserve zero exceptions

Keeping the current zero-exception policy means the operational kernels cannot
retain their exact `[UInt8]` APIs on the installed supported SDK. The remaining
choices would be to withdraw/defer the Metal implementations or redesign their
public and numerical contracts around GPU-resident resources. Both conflict
with accepted Metal ADRs and require a larger architecture decision; neither is
an implementation cleanup.

## Required owner decision

Choose between the recommended narrow explicit Swift boundary and preserving
the zero-exception policy with operational Metal deferred/redesigned. No code
should change the scanner, package graph or kernel transfer path until that
choice and the required independent review mechanism are approved.

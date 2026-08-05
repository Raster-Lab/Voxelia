# Swift safety policy

Voxelia permits no concurrency-checking exception and only one explicitly
approved compiler-classified memory boundary in repository-owned executable
Swift. `ADR-0186` confines that boundary to three internal Metal byte-transfer
expressions; it grants no public API, pointer signature, no-copy storage,
compiler flag or concurrency annotation. Every other finding remains
prohibited.

`Tools/Scripts/check_swift_safety.py` inventories Swift package manifests,
product source, tests, validation tools, benchmarks, repository tools and
active shell, workflow and Xcode build configuration. `SWIFT-MEM-001` is
implemented and fingerprinted; the checker exempts only that exact reviewed
three-expression multiset when its governing policy is present and rejects:

- `@unchecked Sendable`, `@preconcurrency`, `nonisolated(unsafe)` and unsafe
  executor inheritance;
- every other Swift `unsafe` marker and every conditional that tests the
  strict-memory-safety compiler mode;
- SwiftPM unsafe flags, external compilation conditions, direct script/compiler
  execution and compiler escape channels;
- settings that suppress warnings or weaken memory safety, exclusivity, Swift
  6 or complete strict-concurrency enforcement; and
- unexpected manifests or Swift sources, non-`.swift` Swift scripts,
  non-regular source/configuration files and file or directory symlinks.

The escape-hatch spelling scan is intentionally raw and fail closed. Exact
spellings such as `@unchecked`, `@preconcurrency`, `StrictMemorySafety` and the
Swift word `unsafe` are reserved even in comments, strings and regex literals
inside executable Swift files. Ordinary checked vocabulary such as `free`,
`UnsafePointer` in explanatory text outside manifests or an identifier
containing `unsafe` is not reserved. Manifests have the stricter raw foreign-
symbol, pointer, lifetime and nondeterministic-input spelling rules because
SwiftPM executes them before target compilation. In addition, manifests are
lexed against an explicit deterministic declarative subset: one exact tools-
version header, one `PackageDescription` import and one literal `Package`
declaration composed only from the package APIs currently in use. Closures,
operators, interpolation, runtime clocks/tasks, computed settings and
unapproved package APIs fail closed. Configuration-only flag rules are not
applied to normal Swift expressions, so a value such as `-Double` is not
misclassified as an attached `-D` condition.

Individual source/configuration inputs are capped at 1 MiB, findings are
bounded per file and repository, and rendered diagnostic tokens are truncated.
An oversized, unreadable or non-UTF-8 input fails closed before lexical
allocation or diagnostic generation. Captured SwiftPM metadata output has a
combined 4 MiB stdout/stderr ceiling; the entire process group is killed on
that breach or on timeout, preventing a manifest from exhausting checker
memory by printing indefinitely.

The scaffold and security workflows invoke the checker with `--compile`. This
also verifies effective Swift 6 manifest settings, the exact governed local-
dependency set and bidirectional target-source coverage. It rejects every
resolved SwiftPM `unsafeFlags` setting and every target language-mode override,
foreign-memory execution and environment/random/process-dependent manifest
composition, then builds product and test targets in the root, validation,
benchmark and tool packages in both debug and release configurations. The
compiler's strict-memory-safety diagnostics are promoted to errors. SwiftPM
metadata is evaluated without mutable repository metadata, and package/build
commands have bounded process-group cleanup so a child process cannot hang the
self-hosted gate.

Generated build trees and the controlled non-product probes in
`docs/progress/evidence/` are excluded. Effective SwiftPM target descriptions
must prove both that every compiled source is inventoried and that every Swift
file in a governed package source/test tree is compiled by a target. This
prevents target exclusions, orphan files and custom target paths from escaping
the semantic compiler gate.

The host compiler gate is paired with `Tools/Scripts/test-platforms.sh`. The
platform workflow builds product and test targets for macOS, iOS device and
simulator, tvOS device and simulator, and visionOS device and simulator with
Xcode strict-memory-safety enabled and warnings treated as errors in Debug and
Release. Current local evidence passes both configurations for the first five
destinations. Xcode reports its visionOS 26.5 platform component as not
installed, so both visionOS destinations remain explicit open evidence; this
policy does not treat them as passing.

## Current inventory

The executable exception is enabled only for the raw-byte SHA-256
`161b5298d68bfc1e6e312f650458db3e41e6b9ca418f6a49c486ff86e53c7aa9`
of `Sources/VoxeliaMetal/Internal/MetalBufferTransfer.swift` and exactly its
three `unsafe` marker findings. A missing policy or source, a changed byte,
changed finding multiset, different prohibited category or marker at another
path fails closed. The raw escape-hatch scan passes with that one governed
exception and no unapproved finding. The 2026-08-05 recovery replaced three
test-only lock wrappers and the production pipeline cache with checked
`Synchronization.Mutex` state, isolated the execution context's device/queue
pair and all three kernel pipeline sets behind checked synchronous borrowing,
removed the immutable residency manager's obsolete exception and proved the
exact slice renderer is immutable checked composition.

The complete semantic gate is green. During recovery,
`check_swift_safety.py --compile` first compiled
`VoxeliaCore/ContentID.swift` cleanly after its incremental hashing
was moved to checked bounded `Data` inputs and direct verification to a
fixed-size Swift loop that accumulates all 32 byte differences without an early
exit. Registered goldens, chunk boundaries and first/middle/last mismatch
evidence remain green. The document store's pointer-shaped Foundation query was
also replaced by checked URL resource values with missing-path and regular-file
rejection evidence. The gate next compiled Core and Storage, then stopped in
the root debug build because warnings-as-errors promoted a redundant `await` in
`VoxeliaExecution/BrickRequestBroker.swift`. That same-actor call was corrected
and its five race/cancellation obligations pass. The gate proceeded through
Execution and stopped in Rendering because warnings-as-errors promoted the
extraneous duplicate `pixelY` parameter spelling in
`OrthographicRayGenerator.swift`. That public-selector-preserving cleanup and
its direct numerical dependants pass. The gate then exposed sixteen
strict-memory diagnostics across the three Metal kernels. The three C-format
digest conversions became one checked deterministic lowercase encoder, and the
remaining thirteen upload, parameter and readback calls now route through the
governed boundary with exact 28/8/4-byte parameter blocks. At that earlier
stage no finding was an accepted exception; the Metal transfer boundary first
required an installed-SDK and package-boundary audit.
That audit is now recorded: MetalKit can perform checked `Data` upload through
its Model I/O-backed mesh allocator, but the supported SDK has no checked exact
raw-buffer readback inverse. Blit and Metal I/O do not bridge arbitrary results
to owned collections, and tensor/texture readback remains pointer-shaped. The
then-current zero-exception policy therefore could not coexist with the
accepted operational kernel APIs without deferral/redesign. The selected
resolution is a single explicit internal Swift transfer boundary. The project
owner approved that option and an independent subagent review on 2026-08-05.
Accepted `ADR-0186` fixes the exact three-operation byte-only scope; the
boundary, checked word serializer, exact scanner fingerprint and focused range,
storage, completion, lifetime, concurrency, serialization and scanner-fault
evidence are implemented. All three kernels and the residency round trip are
migrated, and the independent reviewer approved both the boundary/scanner and
migration diffs. Its six test-only C-format initializers were then replaced
with bounded deterministic Swift encoders. The final pointer-backed
`MetadataBinaryTests` copy-ownership adversary now uses a checked caller-owned
reference collection while retaining its snapshot and hash-stability oracle.
The complete gate now builds every product and test target in the root,
Validation, Benchmarks and Tools packages under strict memory safety and
warnings-as-errors in both debug and release. It reports no unapproved finding
or configuration. This semantic compilation gate does not execute the complete
test suite or replace the separate Apple destination matrix.

| Exception ID | Declaration | Owner | Invariant | Review | Tests |
|---|---|---|---|---|---|
| `SWIFT-MEM-001` (enabled for exact fingerprint) | Three expression markers inside internal `MetalBufferTransfer`: bounded shared write, inline byte binding and completed shared readback | `VoxeliaMetal` maintainer | Owned nonempty bytes; checked size/range; shared storage only; same writer completed; fresh owned output; no concurrent range access | Owner approval plus independent design, boundary/scanner and migration-diff approvals recorded under `ADR-0186` | Boundary fingerprint, range, storage, completion, lifetime, concurrency, serialization, scanner mutation, three kernels and residency pass; complete semantic gate passes every repository package in debug and release |

## Introducing an exception

Do not suppress, rename or split a token to evade the gate. A necessary future
exception requires a dedicated policy change that:

1. identifies the exact declaration and owner;
2. documents its memory, lifetime and concurrency invariants;
3. explains why checked Swift cannot express the required behaviour;
4. adds focused stress, lifetime and failure tests;
5. records an independent reviewer and review evidence; and
6. narrows any scanner exception to the exact reviewed operation or
   declaration.

The exception may be enabled only after the governing public contract is
accepted. Proposed ADRs and RFCs are review material and grant no exception.

This policy provides implementation and review evidence for `VOX-CON-010` and
`VOX-SEC-002`. It supports, but does not by itself complete, `VOX-CON-003`,
`VOX-SEC-001` or the complete M1 acceptance checklist.

# Swift safety policy

Voxelia permits no concurrency-checking exception and only one explicitly
approved compiler-classified memory boundary in repository-owned executable
Swift. `ADR-0186` confines that boundary to three internal Metal byte-transfer
expressions; it grants no public API, pointer signature, no-copy storage,
compiler flag or concurrency annotation. Every other finding remains
prohibited.

`Tools/Scripts/check_swift_safety.py` inventories Swift package manifests,
product source, tests, validation tools, benchmarks, repository tools and
active shell, workflow and Xcode build configuration. Until `SWIFT-MEM-001` is
implemented and fingerprinted it rejects every marker; afterward it exempts
only that exact reviewed three-expression multiset and rejects:

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

The executable exception has not yet been enabled, so the raw escape-hatch scan
still passes with no findings. The 2026-08-05 recovery replaced three test-only
lock wrappers and the production pipeline cache with checked
`Synchronization.Mutex` state, isolated the execution context's device/queue
pair and all three kernel pipeline sets behind checked synchronous borrowing,
removed the immutable residency manager's obsolete exception and proved the
exact slice renderer is immutable checked composition.

The complete semantic gate is not green. `check_swift_safety.py --compile`
now compiles `VoxeliaCore/ContentID.swift` cleanly after its incremental hashing
was moved to checked bounded `Data` inputs and direct verification to a
fixed-size Swift loop that accumulates all 32 byte differences without an early
exit. Registered goldens, chunk boundaries and first/middle/last mismatch
evidence remain green. The document store's pointer-shaped Foundation query is
also replaced by checked URL resource values with missing-path and regular-file
rejection evidence. The gate now compiles Core and Storage, then stops in the
root debug build because warnings-as-errors promotes a redundant `await` in
`VoxeliaExecution/BrickRequestBroker.swift`. That same-actor call is now
corrected and its five race/cancellation obligations pass. The gate proceeds
through Execution and stops in Rendering because warnings-as-errors promotes
the extraneous duplicate `pixelY` parameter spelling in
`OrthographicRayGenerator.swift`. That public-selector-preserving cleanup and
its direct numerical dependants now pass. The gate proceeds through Rendering
and stops on sixteen strict-memory diagnostics across
`MetalInvertKernel.swift`, `MetalCompositeKernel.swift` and
`MetalWindowLevelKernel.swift`. The three C-format digest conversions are now
one checked deterministic lowercase encoder, with all registered digest pins
and kernel suites green. A filtered semantic rerun leaves exactly thirteen
pointer-shaped upload, parameter and readback calls. Later targets and
package/configuration phases remain unverified by that run. At that stage no
finding was an accepted exception; the Metal transfer boundary required an
installed-SDK and package-boundary audit before edits or governance decisions.
That audit is now recorded: MetalKit can perform checked `Data` upload through
its Model I/O-backed mesh allocator, but the supported SDK has no checked exact
raw-buffer readback inverse. Blit and Metal I/O do not bridge arbitrary results
to owned collections, and tensor/texture readback remains pointer-shaped. The
then-current zero-exception policy therefore could not coexist with the
accepted operational kernel APIs without deferral/redesign. The recommended resolution is a single
explicit internal Swift transfer boundary, but it requires owner approval and
the independent review/evidence process below before the exception inventory or
scanner changes. The project owner approved that recommended option and an
independent subagent review on 2026-08-05. Accepted `ADR-0186` now fixes the
exact three-operation byte-only scope; the independent design review approved
it with conditions, while implementation, focused evidence and final diff
review remain pending before the scanner fingerprint is enabled.

| Exception ID | Declaration | Owner | Invariant | Review | Tests |
|---|---|---|---|---|---|
| `SWIFT-MEM-001` (approved, not yet enabled) | Three expression markers inside internal `MetalBufferTransfer`: bounded shared write, inline byte binding and completed shared readback | `VoxeliaMetal` maintainer | Owned nonempty bytes; checked size/range; shared storage only; same writer completed; fresh owned output; no concurrent range access | Owner approval and independent design review recorded under `ADR-0186`; final implementation review pending | Fingerprint, range, storage, completion, lifetime, concurrency, serialization, kernel and semantic-gate evidence pending |

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

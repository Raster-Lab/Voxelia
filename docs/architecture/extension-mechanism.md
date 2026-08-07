# The extension mechanism

**The primary extension mechanism is source-level Swift packages
depending on public Voxelia modules** (`VOX-EXT-001`, `ADR-0379`).
There is no plug-in loader, no dynamic discovery and no binary
boundary in the M7 mechanism: an extension is an ordinary package that
declares a dependency on the public libraries (`VoxeliaCore`,
`VoxeliaSpatial`, `VoxeliaStorage`, `VoxeliaExecution`, and the other
published products), defines its own types against their public
vocabulary, and is compiled into the host application by the host's own
build.

## What an extension can do

- **Define operations**: an operation is a type conforming to the
  public execution contracts — the registered-operation pattern of
  `ADR-0134` — with its own operation and implementation token
  spellings under the extension's reverse-DNS namespace, never under
  `org.voxelia.*`.
- **Register implementations**: the host composes one
  `ImplementationRegistry` from the built-in backend registrations plus
  any extension entries. Registration is data — no core module is
  modified, recompiled or patched to admit a third-party entry
  (`VOX-EXT-002`, witnessed in the validation suite).
- **Adapt formats**: the optional adapter capabilities (`ADR-0364`,
  `ADR-0378`) are protocols an extension package conforms to.

## What an extension cannot do

- Enter a **diagnostic** execution policy without explicit host or
  validated-distribution approval — third-party entries are
  non-diagnostic by default (`VOX-EXT-006`; enforcement is the
  selection policy's admission).
- Register a **duplicate** operation/implementation identity pair: the
  registry refuses it typed (`VOX-EXT-004`).
- Reach non-public API: the mechanism is the public surface, and the
  semantic-versioning contract of the release process is the
  compatibility promise extensions build on.

## Runtime binary plug-ins

Deliberately absent, and **resolved at M9 as not introduced**
(`ADR-0403`): whether runtime binary plug-ins ever exist is an owner
decision, and this document binds any future introduction to a
versioned stable boundary (a C-compatible or serialised-IPC surface
with its own semantic version, never assumed Swift compiler ABI
compatibility), to the explicit `CapabilityNegotiation` seam that
source-package extensions already route through, and to out-of-process
execution for untrusted plug-ins where the host platform permits it
(XPC on Apple platforms) — in-process loading stays reserved for
distribution-trusted code.

## References

- [ADR-0379 - The source-package extension mechanism](decisions/ADR-0379-the-source-package-extension-mechanism.md)
- [ADR-0134 - Implementation registration](decisions/ADR-0134-implementation-registration.md)

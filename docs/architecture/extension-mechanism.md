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

Deliberately absent from M7. If they are introduced (the baseline's M9
runtime plug-in rows), they require a versioned stable boundary
rather than assumed Swift ABI compatibility, explicit capability
negotiation, and out-of-process execution for untrusted plug-ins where
the platform permits. Nothing in the source-level mechanism presumes
that decision.

## References

- [ADR-0379 - The source-package extension mechanism](decisions/ADR-0379-the-source-package-extension-mechanism.md)
- [ADR-0134 - Implementation registration](decisions/ADR-0134-implementation-registration.md)

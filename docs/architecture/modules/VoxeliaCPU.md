# VoxeliaCPU

**Purpose:** Deterministic CPU reference and optimised implementations.

**Direct dependencies:** VoxeliaImaging, VoxeliaGeometry, VoxeliaExecution

**Current status:** Reviewed milestone specifications authorize deterministic
CPU operations and backend registrations. Accepted `ADR-0191` migration step
three provides the internal one-read scalar adapter and exact
`freudenthal-surface-extraction/binary64-v1` reference kernel. Step four adds
the public atomic mesh/identity/provenance return with fixed CPU execution
claims and registers that evidence-backed implementation without adding a mesh
content digest or diagnostic validation claim. Accepted `ADR-0192` migration
step two separately adds the internal exact-integer labelled adapter and
`freudenthal-label-set-surface/binary64-v1` categorical kernel with exhaustive
oracle evidence. Migration step three now exposes its stateless public atomic
operation, binds the exact integer-domain parameter digest and fixed CPU
identity/provenance/execution claims after final cancellation, and registers
the complete evidence-backed implementation without claiming diagnostic
validation or a mesh content digest.

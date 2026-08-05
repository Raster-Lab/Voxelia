# ``VoxeliaCPU``

Deterministic CPU reference and optimised implementations.

## Current status

Reviewed milestone specifications now authorize deterministic CPU operations
and backend registrations. The scalar-surface migration currently contains an
internal one-read source adapter, the exact binary64 Freudenthal reference
kernel and a public atomic result operation. The operation binds caller-owned
output authority to fixed CPU execution and transformed provenance claims; its
registered result carries no provisional mesh content digest or diagnostic
validation claim.

## Direct dependencies

`VoxeliaImaging`, `VoxeliaGeometry`, `VoxeliaExecution`

## Topics

### Backend registration

- ``CPUBackendRegistrations``

### Geometry extraction

- ``CPUScalarSurfaceExtractionOperation``

### Project documents

- <doc:Architecture>
- <doc:Requirements>

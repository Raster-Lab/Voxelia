# ``VoxeliaCPU``

Deterministic CPU reference and optimised implementations.

## Current status

Reviewed milestone specifications now authorize deterministic CPU operations
and backend registrations. The scalar-surface migration currently contains an
internal one-read source adapter and the exact binary64 Freudenthal reference
kernel. Its public execution/result assembly and registration remain withheld
until the next accepted migration stage passes its publication evidence.

## Direct dependencies

`VoxeliaImaging`, `VoxeliaGeometry`, `VoxeliaExecution`

## Topics

### Backend registration

- ``CPUBackendRegistrations``

### Project documents

- <doc:Architecture>
- <doc:Requirements>

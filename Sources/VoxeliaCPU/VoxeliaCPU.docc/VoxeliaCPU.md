# ``VoxeliaCPU``

Deterministic CPU reference and optimised implementations.

## Current status

Reviewed milestone specifications now authorize deterministic CPU operations
and backend registrations. The scalar- and labelled-surface migrations each
contain an internal one-read source adapter, an exact binary64 Freudenthal
reference kernel and a public atomic result operation. Each operation binds
caller-owned output authority to fixed CPU execution and transformed provenance
claims; the registered results carry no provisional mesh content digest or
diagnostic validation claim. The labelled operation preserves exact signed or
unsigned 64-bit label identity in its technical parameter digest without
attaching a misleading per-vertex or per-primitive label attribute.

## Direct dependencies

`VoxeliaImaging`, `VoxeliaGeometry`, `VoxeliaExecution`

## Topics

### Backend registration

- ``CPUBackendRegistrations``

### Geometry extraction

- ``CPUScalarSurfaceExtractionOperation``
- ``CPULabelledSurfaceExtractionOperation``

### Project documents

- <doc:Architecture>
- <doc:Requirements>

# ``VoxeliaMetal``

Metal compute, rendering, resource residency and telemetry.

## Status

This target is part of the repository and dependency scaffold. Reviewed
milestone specifications introduce its substantive public API incrementally.

## Direct dependencies

`VoxeliaExecution`, `VoxeliaRendering`

## Topics

### Residency policy

- ``ResidencyPolicy``

### Execution context

- ``MetalExecutionContext``
- ``MetalContextError``
- ``MetalDeviceCapabilities``
- ``MetalPipelineCache``
- ``MetalPipelineCacheError``
- ``MetalDispatchTelemetry``
- ``MetalFrameScheduler``
- ``MetalFrameToken``
- ``MetalFrameError``
- ``MetalWindowLevelKernel``
- ``MetalKernelError``
- ``MetalResidencyManager``
- ``MetalResidencySelection``
- ``MetalResidencyError``
- ``ExactSliceRenderer``
- ``SliceRendererError``
- ``RenderPublicationStage``
- ``MetalWindowLevelOperation``
- ``MetalSliceRenderer``
- ``MetalCompositeKernel``
- ``MetalCompositeKernelError``
- ``MetalCompositeLayersOperation``
- ``MetalRendererPlanner``
- ``BackendPolicy``
- ``RendererBackendSelection``
- ``RendererPlan``

### Project documents

- <doc:Architecture>
- <doc:Requirements>

# ``VoxeliaRendering``

Backend-neutral scenes, viewports and rendering requests.

## M0 status

This target is part of the repository and dependency scaffold. Its substantive
public API is introduced only by reviewed milestone specifications.

## Direct dependencies

`VoxeliaImaging`, `VoxeliaGeometry`

## Topics

### Rendering models

- ``ViewportSize``
- ``CameraProjection``
- ``RenderCamera``
- ``GreyscaleWindowFunction``
- ``TransferFunction``
- ``TransferFunction1D``
- ``TransferFunctionEntry``
- ``TransferFunctionError``
- ``VolumeRaySampler``
- ``VolumeRaySamplePlan``
- ``VolumeRaySamplingError``
- ``VolumeMaskSampler``
- ``VolumeRayCompositor``
- ``CompositedRay``
- ``OrthographicRayGenerator``
- ``RayGenerationError``
- ``VolumeRenderRequest``
- ``VolumeClipBounds``
- ``VolumeMaskSelection``
- ``VolumeLightingModel``
- ``RenderQuality``
- ``RenderLayer``
- ``SceneSnapshot``
- ``RenderRequest``
- ``PresentationProvenance``
- ``RenderResult``
- ``RenderMode``
- ``ColourOutputConfiguration``
- ``DisplayColourSpace``
- ``DisplayColourTransform``
- ``DisplayColourSpaceError``
- ``AccumulationState``
- ``DenoisingState``
- ``SliceRenderer``
- ``MultiplanarRenderCoordinator``
- ``InteractiveLevelRenderCoordinator``
- ``HeadlessOutputDescriptor``
- ``HeadlessOutputCapabilities``
- ``OutputDynamicRange``
- ``AuxiliaryOutput``
- ``MediaBufferAdapter``
- ``HeadlessOutputError``
- ``MultiDimensionalTransferFunction``
- ``MaterialConditionedTransfer``
- ``TransferTableEntry``
- ``MultiDimensionalTransferError``
- ``InteractiveSourceSelection``
- ``InteractiveLevelError``
- ``InteractionPhase``
- ``RefinementDecision``
- ``CameraRelativeFloatTransform``
- ``RenderModelError``

### Surface scene

- ``SurfaceLayer``
- ``SurfaceMaterialSelection``
- ``SurfaceSceneSnapshot``
- ``SurfaceRenderRequest``
- ``SurfaceSceneError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>

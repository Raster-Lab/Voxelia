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
- ``VolumeRayCompositor``
- ``CompositedRay``
- ``OrthographicRayGenerator``
- ``RayGenerationError``
- ``VolumeRenderRequest``
- ``VolumeClipBounds``
- ``VolumeLightingModel``
- ``RenderQuality``
- ``RenderLayer``
- ``SceneSnapshot``
- ``RenderRequest``
- ``PresentationProvenance``
- ``RenderResult``
- ``RenderMode``
- ``ColourOutputConfiguration``
- ``AccumulationState``
- ``DenoisingState``
- ``SliceRenderer``
- ``CameraRelativeFloatTransform``
- ``RenderModelError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>

# ``VoxeliaImaging``

Backend-neutral scientific image-processing semantics.

## M0 status

This target is part of the repository and dependency scaffold. Its substantive
public API is introduced only by reviewed milestone specifications.

## Direct dependencies

`VoxeliaExecution`

## Topics

### DICOM ingest

- ``CTFrameDescription``
- ``CTFrameDescriptionError``
- ``MonochromeInterpretation``
- ``PixelPaddingDescriptor``
- ``CTSeriesAssembler``
- ``CTSeries``
- ``CTSeriesKey``
- ``CTSeriesMember``
- ``CTSeriesObservation``
- ``CTReferenceNormal``
- ``CTGeometryValidator``
- ``CTGeometryAssessment``
- ``CTGeometryMeasurement``
- ``CTGeometryFinding``
- ``CTGeometryVerdict``
- ``CTGeometryTolerance``
- ``CTAffineVolumeBuilder``
- ``CTVolumeConstruction``
- ``CTVolumeConstructionError``
- ``CTVolumeLayout``
- ``CTVolumeLayoutError``
- ``CTFramePlacement``
- ``CTFramePlacementError``
- ``CTVolumeByteBuffer``
- ``CTVolumeByteBufferError``
- ``CTValueInterpreter``
- ``CTValueInterpretationError``
- ``CTValueInterpretationFinding``
- ``CTInterpretedValue``
- ``CTSampleNormalisation``
- ``CTVolumeDescriptorBuilder``
- ``CTVolumeDescriptorError``
- ``CTVolumeStorageBuilder``
- ``CTVolumeStorageError``
- ``CTVolumePublicationBuilder``
- ``CTVolumePublicationError``
- ``CTSampleInspector``
- ``CTSampleInspection``
- ``CTSampleInspectionError``
- ``CTImportSession``
- ``CTImportedVolume``
- ``CTImportCheckpoint``
- ``CTImportCancellationProbe``
- ``CTImportSessionError``

### Multiplanar reconstruction

- ``MPRSliceCoordinator``
- ``MPRPlane``
- ``MPRPublicationStage``
- ``MPRError``

### Project documents

- <doc:Architecture>
- <doc:Requirements>

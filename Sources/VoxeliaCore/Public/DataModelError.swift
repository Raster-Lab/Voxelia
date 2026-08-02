// SPDX-License-Identifier: MIT

/// A common error vocabulary for canonical Voxelia data-model operations.
public enum DataModelError: Error, Sendable, Equatable {
    case invalidIdentifier
    case invalidShape(ShapeError)
    case invalidRegion(RegionError)
    case axisCountMismatch
    case duplicateAxisIdentifier
    case invalidScalarFormat
    case invalidComponentDescriptor
    case semanticMismatch
    case invalidValueTransform
    case invalidCoordinateSpace
    case invalidGeometry
    case incompatibleGeometry
    case singularTransform
    case coordinateSpaceMismatch
    case storageDescriptorMismatch
    case unsupportedStorageCapability
    case invalidContentIdentity
    case duplicateMetadataKey
    case invalidProvenance
    case provenanceCycle
    case invalidGeometryAttribute
    case meshIndexOutOfBounds
    case invalidSegmentation
    case invalidRegistrationResult
    case arithmeticOverflow
    case cancelled
}

// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised while validating an image descriptor.
public enum ImageDescriptorError: Error, Sendable, Equatable {
    case axisCountMismatch
    case duplicateAxisIdentifier
    case semanticComponentMismatch
    case invalidGeometryAxisReference
    case nonSampleUnit
}

/// The canonical logical image descriptor (CDMS section 19) admitted
/// under the accepted `ADR-0043` boundary.
///
/// Construction validates the section 19.2 invariants with typed
/// payload-free errors and never accesses storage. The descriptor is
/// logical: physical representation, integrity and residency belong to
/// the storage contract layers.
public struct ImageDescriptor: Sendable, Hashable {
    public let shape: ImageShape
    public let scalarFormat: ScalarFormat
    public let components: ComponentDescriptor
    public let semantic: ImageSemantic
    public let axes: ContiguousArray<AxisDescriptor>
    public let spatialGeometry: SpatialGeometry?
    public let valueTransform: ValueTransform?
    public let units: MeasurementUnit?

    /// - Throws: ``ImageDescriptorError`` when an invariant fails:
    ///   axis count must equal shape rank; axis identifiers must be
    ///   unique; colour semantics require RGB/RGBA component
    ///   interpretations while non-colour semantics reject them; a
    ///   spatial geometry must reference only valid image axes; and a
    ///   present unit must describe authoritative sample values, never
    ///   spatial coordinates.
    public init(
        shape: ImageShape,
        scalarFormat: ScalarFormat,
        components: ComponentDescriptor,
        semantic: ImageSemantic,
        axes: ContiguousArray<AxisDescriptor>,
        spatialGeometry: SpatialGeometry?,
        valueTransform: ValueTransform?,
        units: MeasurementUnit?
    ) throws {
        guard axes.count == shape.rank else {
            throw ImageDescriptorError.axisCountMismatch
        }
        var seenAxisIDs = Set<AxisID>()
        for axis in axes {
            guard seenAxisIDs.insert(axis.id).inserted else {
                throw ImageDescriptorError.duplicateAxisIdentifier
            }
        }

        let colourInterpretation =
            components.interpretation == .rgb || components.interpretation == .rgba
        switch semantic {
        case .colour:
            guard colourInterpretation else {
                throw ImageDescriptorError.semanticComponentMismatch
            }
        default:
            guard !colourInterpretation else {
                throw ImageDescriptorError.semanticComponentMismatch
            }
        }

        if case .affine(let affine) = spatialGeometry {
            for imageAxis in affine.spatialAxes.imageAxes {
                guard imageAxis < shape.rank else {
                    throw ImageDescriptorError.invalidGeometryAxisReference
                }
            }
        }

        // A sample unit describes authoritative sample values; spatial
        // coordinate units live on axes and coordinate spaces.
        if let units, units.dimension == .length {
            throw ImageDescriptorError.nonSampleUnit
        }

        self.shape = shape
        self.scalarFormat = scalarFormat
        self.components = components
        self.semantic = semantic
        self.axes = axes
        self.spatialGeometry = spatialGeometry
        self.valueTransform = valueTransform
        self.units = units
    }
}

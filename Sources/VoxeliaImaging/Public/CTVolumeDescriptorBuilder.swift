// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// An error raised while building a CT volume's image descriptor.
///
/// Cases deliberately carry no payload, so a refusal never discloses extents or
/// geometry in a diagnostic.
public enum CTVolumeDescriptorError: Error, Sendable, Equatable {
    /// The frame's extents or scalar format disagree with the layout's.
    case frameLayoutMismatch
    /// The affine geometry does not map the three image axes in order.
    case unexpectedAxisMapping
    /// The supplied sample unit does not describe a dimensionless quantity.
    ///
    /// `ImageDescriptor` requires a present unit to describe authoritative sample
    /// values rather than spatial coordinates, so a length unit here would be a
    /// category error: it would claim the samples are millimetres.
    case unsupportedSampleUnit
}

/// Builds the `ImageDescriptor` for an ingested CT volume, per `ADR-0238`
/// increment (a).
///
/// The descriptor's slots were designed for exactly this and had never been
/// filled: `spatialGeometry` takes the affine `ADR-0230` builds, and
/// `valueTransform` takes the rescale as `ValueTransform.linear`, governed by
/// `VOXELIA-ALG-0003` per `ADR-0237`.
public enum CTVolumeDescriptorBuilder {
    /// The axis order this bridge publishes.
    ///
    /// Image axis 0 is the **column** index, 1 the **row** index and 2 the slice,
    /// matching `VOXELIA-ALG-0050`'s layout so that axis 0 is the contiguous one —
    /// which is what `ContiguousImageStorage` reads in runs.
    public static let axisNames = ["column", "row", "slice"]

    /// Builds a descriptor for a volume.
    ///
    /// - Parameters:
    ///   - frame: the series anchor, supplying the scalar format and rescale
    ///     terms. Its extents must match `layout`.
    ///   - layout: the volume's addressing contract.
    ///   - geometry: the affine built by `CTAffineVolumeBuilder`.
    ///   - sampleUnits: the unit of the *rescaled* sample values, when known.
    ///     Absent by default, because deriving it requires DICOM's Rescale Type
    ///     which the adapter does not read — see the note below.
    /// - Throws: ``CTVolumeDescriptorError``.
    public static func descriptor(
        frame: CTFrameDescription,
        layout: CTVolumeLayout,
        geometry: AffineGridGeometry,
        sampleUnits: MeasurementUnit? = nil
    ) throws -> ImageDescriptor {
        guard frame.rows == layout.rows, frame.columns == layout.columns,
            frame.scalarFormat == layout.scalarFormat
        else {
            throw CTVolumeDescriptorError.frameLayoutMismatch
        }
        guard geometry.spatialAxes.imageAxes.elementsEqual([0, 1, 2]) else {
            throw CTVolumeDescriptorError.unexpectedAxisMapping
        }
        if let sampleUnits, sampleUnits.dimension == .length {
            throw CTVolumeDescriptorError.unsupportedSampleUnit
        }

        // Axis 0 is the column index, so its extent is the column count.
        let shape = try ImageShape(extents: [
            layout.columns, layout.rows, layout.sliceCount,
        ])

        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        var axes = ContiguousArray<AxisDescriptor>()
        for (index, name) in axisNames.enumerated() {
            guard let id = AxisID(rawValue: name) else {
                throw CTVolumeDescriptorError.unexpectedAxisMapping
            }
            axes.append(
                try AxisDescriptor(
                    id: id,
                    name: name,
                    semantic: semantics[index],
                    unit: nil,
                    // Index-only, because the affine already carries the spacing.
                    // Declaring a regular sampling as well would state one fact
                    // twice and let the two drift.
                    sampling: .indexOnly
                )
            )
        }

        return try ImageDescriptor(
            shape: shape,
            // ADR-0239: the published format drops the meaningful-bit narrowing,
            // because normalisation makes full-width containers true.
            scalarFormat: try CTSampleNormalisation.normalisedFormat(
                from: frame.scalarFormat
            ),
            components: try ComponentDescriptor(
                count: 1,
                interpretation: .scalar,
                layout: .interleaved
            ),
            semantic: .intensity,
            axes: axes,
            spatialGeometry: .affine(geometry),
            valueTransform: try valueTransform(
                slope: frame.rescaleSlope,
                intercept: frame.rescaleIntercept
            ),
            units: sampleUnits
        )
    }

    /// The stored-to-real transform for a frame's rescale terms.
    ///
    /// A unit slope with a zero intercept is published as `.identity` rather than
    /// `.linear(1, 0)`. That is not a shortcut: `VOXELIA-ALG-0003` states a linear
    /// mapping with `scale = 1, offset = 0` is bit-identical to no mapping, so the
    /// two declarations are equivalent and the simpler one spares every consumer a
    /// multiplication that cannot change a value.
    public static func valueTransform(
        slope: Double,
        intercept: Double
    ) throws -> ValueTransform {
        if slope == 1, intercept == 0 {
            return .identity
        }
        return .linear(
            try LinearValueTransformDescriptor(scale: slope, offset: intercept)
        )
    }
}

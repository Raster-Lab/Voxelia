// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaSpatial

/// An error raised by multiplanar slice admission.
///
/// Cases deliberately carry no payload; execution and publication
/// failures surface as their own audited typed errors.
public enum MPRError: Error, Sendable, Equatable {
    case volumeNotPublished
    case unsupportedVolumeShape
    case invalidSliceIndex
    case unsupportedAxisSampling
    case crosshairOutsideVolume
    case volumeNotSpatiallyCalibrated
}

/// The closed multiplanar plane vocabulary per `ADR-0117`.
///
/// Each plane fixes one axis of a rank-three volume: `axial` fixes
/// axis two, `coronal` axis one and `sagittal` axis zero.
public enum MPRPlane: Sendable, Hashable {
    case axial
    case coronal
    case sagittal

    var fixedAxis: Int {
        switch self {
        case .axial: 2
        case .coronal: 1
        case .sagittal: 0
        }
    }
}

/// The published stages one slice extraction produces; the host names
/// each stage per `ADR-0117`.
public enum MPRPublicationStage: Sendable, Equatable {
    case extracted
    case squeezed
}

/// The host-supplied naming for one slice's published stages; the
/// coordinator mints no identifiers and acquires no clock.
public typealias MPRPublicationNaming =
    @Sendable (MPRPublicationStage) throws -> (
        outputObjectID: DataObjectID,
        provenanceID: ProvenanceID,
        createdAt: CanonicalInstant
    )

/// The multiplanar slice coordinator per `ADR-0117` — the first
/// substantive `VoxeliaImaging` API.
///
/// A slice composes from accepted operations: the one-thick slab
/// extracts under the registered region model and the fixed axis
/// squeezes under the registered singleton drop, with both stages
/// published so every slice carries a complete chain whose recipes
/// are its explicit reproducible geometry.
public enum MPRSliceCoordinator {
    /// Extracts and publishes one plane slice of a published
    /// rank-three volume.
    ///
    /// - Throws: ``MPRError``, or the audited typed errors of the
    ///   execution and publication contracts.
    public static func extractSlice(
        volumeID: DataObjectID,
        plane: MPRPlane,
        sliceIndex: Int,
        naming: @escaping MPRPublicationNaming,
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity
    ) async throws -> ImageData {
        guard let volume = await publisher.publishedImage(for: volumeID) else {
            throw MPRError.volumeNotPublished
        }
        let extents = volume.descriptor.shape.extents
        guard extents.count == 3 else {
            throw MPRError.unsupportedVolumeShape
        }
        let fixedAxis = plane.fixedAxis
        guard sliceIndex >= 0, sliceIndex < extents[fixedAxis] else {
            throw MPRError.invalidSliceIndex
        }

        // The one-thick slab under the registered region model, then
        // the singleton drop, each published.
        var lowerBounds = [0, 0, 0]
        var upperBounds = [extents[0], extents[1], extents[2]]
        lowerBounds[fixedAxis] = sliceIndex
        upperBounds[fixedAxis] = sliceIndex + 1
        let slabNames = try naming(.extracted)
        let slab = try await RegionExtractionOperation.execute(
            input: volume,
            region: try ImageRegion(
                lowerBounds: ContiguousArray(lowerBounds),
                upperBounds: ContiguousArray(upperBounds)
            ),
            outputObjectID: slabNames.outputObjectID,
            outputProvenanceID: slabNames.provenanceID,
            createdAt: slabNames.createdAt,
            software: software,
            coordinator: readCoordinator
        )
        _ = try await publisher.publish(slab, mode: .complete)

        let sliceNames = try naming(.squeezed)
        let slice = try await SqueezeAxesOperation.execute(
            input: slab,
            axes: [fixedAxis],
            outputObjectID: sliceNames.outputObjectID,
            outputProvenanceID: sliceNames.provenanceID,
            createdAt: sliceNames.createdAt,
            software: software,
            coordinator: readCoordinator
        )
        _ = try await publisher.publish(slice, mode: .complete)
        return slice
    }

    /// Maps one axis-domain crosshair component to the plane's slice
    /// index per `ADR-0130`.
    ///
    /// The frozen rule: `difference = value - origin`,
    /// `quotient = difference / spacing`, ties-to-even rounding — an
    /// out-of-volume component rejects typed, never clamps, because
    /// presenting a nearest slice for a crosshair that left the volume
    /// would misreport where the views point. World points on
    /// obliquely oriented volumes map through
    /// ``sliceIndex(forWorldPoint:plane:volumeID:publisher:)``.
    ///
    /// - Throws: ``MPRError``.
    public static func sliceIndex(
        forAxisValue value: Double,
        plane: MPRPlane,
        volumeID: DataObjectID,
        publisher: PublicationCoordinator
    ) async throws -> Int {
        guard let volume = await publisher.publishedImage(for: volumeID) else {
            throw MPRError.volumeNotPublished
        }
        let extents = volume.descriptor.shape.extents
        guard extents.count == 3 else {
            throw MPRError.unsupportedVolumeShape
        }
        let fixedAxis = plane.fixedAxis
        guard
            case .regular(let origin, let spacing) =
                volume.descriptor.axes[fixedAxis].sampling
        else {
            throw MPRError.unsupportedAxisSampling
        }
        let difference = value - origin
        let quotient = difference / spacing
        return try Self.admittedSliceIndex(
            rounding: quotient,
            extent: extents[fixedAxis]
        )
    }

    /// Maps one world crosshair point to the plane's slice index per
    /// `ADR-0138`.
    ///
    /// The published volume's claimed affine geometry supplies the
    /// frozen `ADR-0138` world-to-index composition; the plane's
    /// fixed-axis component rounds under the accepted `ADR-0130`
    /// ties-to-even rule. Only the fixed-axis component gates
    /// admission because the other components do not select the
    /// slice. An uncalibrated volume rejects typed — presenting a
    /// slice for a world point against a volume that claims no world
    /// mapping would fabricate a registration.
    ///
    /// - Throws: ``MPRError`` and the world-to-index map's typed
    ///   errors.
    public static func sliceIndex(
        forWorldPoint point: Point3D,
        plane: MPRPlane,
        volumeID: DataObjectID,
        publisher: PublicationCoordinator
    ) async throws -> Int {
        guard let volume = await publisher.publishedImage(for: volumeID) else {
            throw MPRError.volumeNotPublished
        }
        let extents = volume.descriptor.shape.extents
        guard extents.count == 3 else {
            throw MPRError.unsupportedVolumeShape
        }
        guard case .affine(let affine)? = volume.descriptor.spatialGeometry
        else {
            throw MPRError.volumeNotSpatiallyCalibrated
        }
        let fixedAxis = plane.fixedAxis
        let map = try AffineWorldToIndexMap(geometry: affine)
        let continuous = try map.continuousIndex(
            forImageAxis: fixedAxis,
            of: point
        )
        return try Self.admittedSliceIndex(
            rounding: continuous,
            extent: extents[fixedAxis]
        )
    }

    /// The shared `ADR-0130` rounding admission: ties-to-even, then a
    /// double-domain range check before integer conversion so absurd
    /// magnitudes reject typed instead of trapping.
    private static func admittedSliceIndex(
        rounding value: Double,
        extent: Int
    ) throws -> Int {
        let rounded = value.rounded(.toNearestOrEven)
        guard rounded >= 0, rounded < Double(extent) else {
            throw MPRError.crosshairOutsideVolume
        }
        return Int(rounded)
    }
}

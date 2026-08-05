// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution

/// An error raised by multiplanar slice admission.
///
/// Cases deliberately carry no payload; execution and publication
/// failures surface as their own audited typed errors.
public enum MPRError: Error, Sendable, Equatable {
    case volumeNotPublished
    case unsupportedVolumeShape
    case invalidSliceIndex
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
}

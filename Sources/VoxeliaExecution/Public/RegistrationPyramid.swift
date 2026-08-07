// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by pyramid admission, per `ADR-0371`.
public enum RegistrationPyramidError: Error, Sendable, Equatable {
    /// The level-identity count does not match the schedule.
    case identityCountMismatch
}

/// The caller-supplied identities for one pyramid level's derived
/// images. Identifiers for skipped passes stay unused — identity is
/// supplied, never fabricated.
public struct RegistrationPyramidLevelIdentity: Sendable {
    public let smoothedObjectID: DataObjectID
    public let smoothedProvenanceID: ProvenanceID
    public let downsampledObjectID: DataObjectID
    public let downsampledProvenanceID: ProvenanceID

    public init(
        smoothedObjectID: DataObjectID,
        smoothedProvenanceID: ProvenanceID,
        downsampledObjectID: DataObjectID,
        downsampledProvenanceID: ProvenanceID
    ) {
        self.smoothedObjectID = smoothedObjectID
        self.smoothedProvenanceID = smoothedProvenanceID
        self.downsampledObjectID = downsampledObjectID
        self.downsampledProvenanceID = downsampledProvenanceID
    }
}

/// The multi-resolution pyramid of `VOX-REG-006`, per `ADR-0371`: a
/// composition of the `ADR-0366` schedule vocabulary over the frozen
/// `VOXELIA-ALG-0060` Gaussian and `VOXELIA-ALG-0056` level selection.
///
/// The pyramid composes, it does not compute: every number it produces
/// is already specified by the two operations it drives. A zero sigma
/// skips smoothing (the Gaussian's own admission refuses it); a unit
/// shrink factor skips selection (an identity copy under a new object
/// identity would be fabricated derivation); a level skipping both
/// passes the input through unchanged. The boundary is `replicate`,
/// recorded once in `ADR-0371` — zero padding would darken every border
/// at every level.
public enum RegistrationPyramid {
    /// Builds one image per schedule level, in schedule order
    /// (coarsest first per `ADR-0366`).
    ///
    /// - Throws: ``RegistrationPyramidError``, or the composed
    ///   operations' own typed errors.
    public static func build(
        image: ImageData,
        schedule: ContiguousArray<RegistrationScheduleLevel>,
        identities: ContiguousArray<RegistrationPyramidLevelIdentity>,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ContiguousArray<ImageData> {
        guard identities.count == schedule.count else {
            throw RegistrationPyramidError.identityCountMismatch
        }
        var levels = ContiguousArray<ImageData>()
        levels.reserveCapacity(schedule.count)
        for index in schedule.indices {
            let level = schedule[index]
            let identity = identities[index]
            var current = image
            if level.smoothingSigma > 0 {
                let rank = current.descriptor.shape.extents.count
                current = try await GaussianFilterOperation.execute(
                    input: current,
                    sigmas: [Double](repeating: level.smoothingSigma, count: rank),
                    boundary: .replicate,
                    outputObjectID: identity.smoothedObjectID,
                    outputProvenanceID: identity.smoothedProvenanceID,
                    createdAt: createdAt,
                    software: software,
                    coordinator: coordinator
                )
            }
            if level.shrinkFactor > 1 {
                current = try await LevelSelectOperation.execute(
                    input: current,
                    level: try BrickResolutionLevel(
                        index: index + 1,
                        downsamplingFactors: [
                            level.shrinkFactor, level.shrinkFactor, level.shrinkFactor,
                        ]
                    ),
                    outputObjectID: identity.downsampledObjectID,
                    outputProvenanceID: identity.downsampledProvenanceID,
                    createdAt: createdAt,
                    software: software,
                    coordinator: coordinator
                )
            }
            levels.append(current)
        }
        return levels
    }
}

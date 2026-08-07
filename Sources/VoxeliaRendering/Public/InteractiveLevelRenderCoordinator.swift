// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaImaging
import VoxeliaStorage

/// An error raised by interactive-level admission.
public enum InteractiveLevelError: Error, Sendable, Equatable {
    /// The level does not carry exactly three downsampling factors.
    case invalidLevelRank
}

/// The source a request renders from, per `ADR-0344`'s frozen rule.
public enum InteractiveSourceSelection: Sendable, Hashable {
    case level
    case fullResolution
}

/// The degraded path's decision layer per `ADR-0344` (`VOX-BRK-009`).
///
/// The representation degrades; the execution never does. A `.full`
/// request renders the full-resolution volume always; an
/// `.interactive` request renders the lower-resolution level while
/// study-cache generation is incomplete, and the full volume once it
/// completes. The renderer runs its accepted full-precision math over
/// whichever volume is selected, so every stage claim stays what it
/// says, and the interactive fact is recorded structurally: the
/// published render's ancestry reaches the level volume, whose own
/// derivation names the level-select operation and its factors.
public enum InteractiveLevelRenderCoordinator {
    /// The frozen, total selection rule.
    public static func selectSource(
        quality: RenderQuality,
        studyCacheGenerationComplete: Bool
    ) -> InteractiveSourceSelection {
        switch quality {
        case .full:
            return .fullResolution
        case .interactive:
            return studyCacheGenerationComplete ? .fullResolution : .level
        }
    }

    /// The frozen slice-index mapping: floor division by the plane
    /// axis's factor selects the level slice containing the sample the
    /// level kept at or below the requested position. The factor is at
    /// least one by `BrickResolutionLevel`'s own admission.
    public static func levelSliceIndex(
        fullResolutionIndex: Int,
        factor: Int
    ) -> Int {
        fullResolutionIndex / factor
    }

    /// Renders one plane from the selected source, forwarding every
    /// presentation choice unchanged to the accepted multiplanar path.
    ///
    /// - Throws: ``InteractiveLevelError/invalidLevelRank``, or the
    ///   audited typed errors of the extraction, publication and
    ///   rendering contracts.
    public static func renderPlane(
        quality: RenderQuality,
        studyCacheGenerationComplete: Bool,
        fullVolumeID: DataObjectID,
        levelVolumeID: DataObjectID,
        level: BrickResolutionLevel,
        plane: MPRPlane,
        sliceIndex: Int,
        transferFunction: TransferFunction,
        viewport: ViewportSize,
        camera: RenderCamera,
        interpolation: InterpolationPolicy,
        colourOutput: ColourOutputConfiguration,
        colourTransform: DisplayColourTransform,
        outputColourSpace: DisplayColourSpace?,
        naming: @escaping MPRPublicationNaming,
        publisher: PublicationCoordinator,
        readCoordinator: StorageReadCoordinator,
        software: SoftwareIdentity,
        renderer: any SliceRenderer
    ) async throws -> RenderResult {
        guard level.downsamplingFactors.count == 3 else {
            throw InteractiveLevelError.invalidLevelRank
        }
        let selection = Self.selectSource(
            quality: quality,
            studyCacheGenerationComplete: studyCacheGenerationComplete
        )
        let volumeID: DataObjectID
        let selectedSliceIndex: Int
        switch selection {
        case .fullResolution:
            volumeID = fullVolumeID
            selectedSliceIndex = sliceIndex
        case .level:
            volumeID = levelVolumeID
            selectedSliceIndex = Self.levelSliceIndex(
                fullResolutionIndex: sliceIndex,
                factor: level.downsamplingFactors[plane.fixedAxis]
            )
        }
        return try await MultiplanarRenderCoordinator.renderPlane(
            volumeID: volumeID,
            plane: plane,
            sliceIndex: selectedSliceIndex,
            transferFunction: transferFunction,
            viewport: viewport,
            camera: camera,
            interpolation: interpolation,
            quality: quality,
            colourOutput: colourOutput,
            colourTransform: colourTransform,
            outputColourSpace: outputColourSpace,
            naming: naming,
            publisher: publisher,
            readCoordinator: readCoordinator,
            software: software,
            renderer: renderer
        )
    }
}

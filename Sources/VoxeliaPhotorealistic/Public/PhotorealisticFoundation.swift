// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by the photorealistic module's activation seam.
public enum PhotorealisticActivationError: Error, Sendable, Equatable {
    /// The host disabled the module; conventional diagnostic rendering
    /// is unaffected by construction.
    case disabledByHost
}

/// The host's activation decision for this module, per `ADR-0385`
/// (`VOX-PRR-002`): a closed two-case vocabulary. The structural layer
/// beneath it is the module boundary itself — a host that does not
/// link `VoxeliaPhotorealistic` has no photorealistic code at all, and
/// conventional rendering in `VoxeliaRendering` does not know this
/// module exists.
public enum PhotorealisticActivation: String, Sendable, Hashable, Codable {
    case enabled
    case disabledByHost
}

/// The `VOX-PRR-003` quality-mode triad, verbatim and defaultless:
/// hosts select a mode explicitly, and no `automatic` case exists —
/// a library guess about quality would be a hidden clinical decision.
///
/// Each mode's numeric behaviour (seeds, convergence, accumulation)
/// belongs to the `ADR-0384` arcs that build it; this vocabulary
/// deliberately carries no knobs.
public enum PhotorealisticQualityMode: String, Sendable, Hashable, Codable {
    case interactive
    case progressive
    case reference
}

/// The activation seam of `VOX-PRR-002`: the one place every
/// photorealistic entry point checks the host's decision.
public enum PhotorealisticGate {
    /// Requires the host's activation before any photorealistic work.
    ///
    /// - Throws: ``PhotorealisticActivationError/disabledByHost``.
    public static func requireEnabled(
        _ activation: PhotorealisticActivation
    ) throws {
        guard activation == .enabled else {
            throw PhotorealisticActivationError.disabledByHost
        }
    }
}

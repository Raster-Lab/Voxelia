// SPDX-License-Identifier: MIT

import VoxeliaCore

/// The two pane kinds a comparison binds.
public enum ComparisonPane: Sendable, Hashable {
    /// Conventional diagnostic rendering, served by `VoxeliaRendering`
    /// under its own contracts.
    case conventional
    /// Photorealistic rendering at one declared quality mode.
    case photorealistic(PhotorealisticQualityMode)
}

/// The `VOX-PRR-015` binding, per `ADR-0394`: both panes bound to ONE
/// authoritative scene state by construction — the initialiser takes
/// one fingerprint, and no API accepts two. Divergent side-by-side
/// state is unrepresentable, not audited.
///
/// Rendering is not performed here: each pane's renderer consumes the
/// identical fingerprint under its own contract. The seam is the row.
public struct SideBySideComparison: Sendable {
    /// The one authoritative scene state both panes render.
    public let sceneState: SceneStateFingerprint
    public let leftPane: ComparisonPane
    public let rightPane: ComparisonPane

    public init(
        sceneState: SceneStateFingerprint,
        leftPane: ComparisonPane,
        rightPane: ComparisonPane
    ) {
        self.sceneState = sceneState
        self.leftPane = leftPane
        self.rightPane = rightPane
    }
}

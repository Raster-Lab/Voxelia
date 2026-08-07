// SPDX-License-Identifier: MIT

/// The host-supplied interaction phase per `ADR-0345`.
///
/// The library never acquires a clock: debouncing "input stopped" into
/// ``idle`` is the host's act, and everything downstream of the phase
/// is the library's.
public enum InteractionPhase: Sendable, Hashable {
    /// Input is arriving; the view is being driven.
    case active
    /// Input has stopped; the view owes requested diagnostic quality.
    case idle
}

/// One refinement decision per `ADR-0345` (`VOX-DVR-013`).
public struct RefinementDecision: Sendable, Hashable {
    /// The source the view renders from now, per the accepted
    /// `ADR-0344` selection.
    public let source: InteractiveSourceSelection
    /// Whether a diagnostic pass is still owed: true exactly when
    /// interaction has stopped but generation is incomplete, so the
    /// host must re-render when loading completes.
    public let refinementDue: Bool

    public init(source: InteractiveSourceSelection, refinementDue: Bool) {
        self.source = source
        self.refinementDue = refinementDue
    }
}

extension InteractiveLevelRenderCoordinator {
    /// The frozen, total refinement rule: the `ADR-0344` interactive
    /// source unchanged, plus the obligation flag. An idle view over
    /// completed generation discharges the obligation by that render,
    /// which the selection rule makes full-resolution; the byte
    /// identity of that render with a direct full-quality render is
    /// the `ADR-0345` obligation the suite proves.
    public static func refinementDecision(
        phase: InteractionPhase,
        studyCacheGenerationComplete: Bool
    ) -> RefinementDecision {
        let source = Self.selectSource(
            quality: .interactive,
            studyCacheGenerationComplete: studyCacheGenerationComplete
        )
        switch phase {
        case .active:
            return RefinementDecision(source: source, refinementDue: false)
        case .idle:
            return RefinementDecision(
                source: source,
                refinementDue: !studyCacheGenerationComplete
            )
        }
    }
}

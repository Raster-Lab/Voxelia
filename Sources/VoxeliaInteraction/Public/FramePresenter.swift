// SPDX-License-Identifier: MIT

/// One frame's content together with the render generation it was requested at.
///
/// Generic over its content so this module never names a rendering payload type, which
/// keeps `VOX-INT-001`'s independence from host types intact: a host stamps whatever it
/// draws, and this module only ever compares generations.
public struct StampedFrame<Content: Sendable>: Sendable {
    /// The generation current when this frame's render was requested.
    public let generation: RenderGeneration

    /// The frame's content.
    public let content: Content

    /// Creates a stamped frame.
    public init(generation: RenderGeneration, content: Content) {
        self.generation = generation
        self.content = content
    }
}

/// What a presenter did with a stamped frame.
///
/// The content is carried **inside** the presented case rather than alongside the
/// verdict. That is the enforcement, following `ADR-0259`'s shape: a host cannot draw
/// what it never receives, so honouring a drop is structural rather than a rule the host
/// must remember.
public enum PresentationOutcome<Content: Sendable>: Sendable {
    /// The frame was current and its content is handed over.
    case presented(Content)
    /// The frame was stamped at an older generation and was dropped.
    case droppedStale
}

/// Presents frames stamped with the generation they were requested at, dropping stale
/// ones, per `ADR-0276` (`VOX-INT-007`).
///
/// ## What this ends
///
/// `ADR-0122` froze the render-generation vocabulary and deferred its use: "stamping
/// frames and dropping stale ones is the interactive draw loop's behaviour, which remains
/// gated on its own architecture". `ADR-0275` supplied that architecture and this type is
/// the vocabulary's first product caller.
///
/// ## The rule, consumed rather than redefined
///
/// Staleness is `RenderGeneration.isStale(comparedTo:)`, frozen by `ADR-0122`: a frame is
/// stale when its generation is **strictly less** than the current one, so equality is
/// freshness. This type adds no tolerance and no second comparison.
///
/// ## Why that means "present only the latest"
///
/// `RenderGeneration`'s initialiser is internal to this module, so the only way a host
/// obtains one is ``RenderGenerationCounter/advance()``. Every stamp therefore names a
/// generation that was minted in the past, which gives `stamp <= current` always — and so
/// `!isStale` holds **exactly when `stamp == current`**.
///
/// The presenter consequently admits only frames rendered for the newest scene. That is a
/// stronger statement than the requirement's wording suggests, it follows from the
/// vocabulary rather than from a choice made here, and it has a consequence worth stating
/// plainly: **if generations are minted faster than frames complete, nothing is ever
/// presented.** A test demonstrates that starvation directly rather than leaving a host
/// author to discover it.
///
/// ## Which is why minting is per committed scene change
///
/// `ADR-0276` freezes the granularity: a generation is minted per **committed scene
/// change**, never per input event. A drag produces a stream of events and must be
/// coalesced by its host into scene commits, at which rate a renderer can keep up. The
/// counter's job is to order scene versions, not to count gestures.
public actor FramePresenter<Content: Sendable> {
    private let counter: RenderGenerationCounter
    private var lastPresented: RenderGeneration?

    /// Creates a presenter reading generations from `counter`.
    ///
    /// The counter is held rather than passed per call, so a caller cannot present
    /// against a generation other than the live one.
    public init(counter: RenderGenerationCounter) {
        self.counter = counter
    }

    /// The generation of the most recently presented frame, or `nil` before the first.
    ///
    /// Exposed because plan §34 lists "current generation" among the reference
    /// application's displays, so a host needs to read it without tracking it itself.
    public var lastPresentedGeneration: RenderGeneration? {
        lastPresented
    }

    /// Presents `frame` if it is current, and drops it if it is stale.
    ///
    /// - Returns: ``PresentationOutcome/presented(_:)`` carrying the content, or
    ///   ``PresentationOutcome/droppedStale``.
    public func present(
        _ frame: StampedFrame<Content>
    ) async -> PresentationOutcome<Content> {
        let current = await counter.currentGeneration
        guard !frame.generation.isStale(comparedTo: current) else {
            return .droppedStale
        }
        lastPresented = frame.generation
        return .presented(frame.content)
    }
}

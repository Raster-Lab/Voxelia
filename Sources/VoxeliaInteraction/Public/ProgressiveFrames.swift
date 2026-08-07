// SPDX-License-Identifier: MIT

/// An error raised by progressive-frame metadata admission.
public enum ProgressiveFrameError: Error, Sendable, Equatable {
    /// The sample count was below one.
    case invalidSampleCount
    /// The variance was negative, NaN or infinite.
    case invalidVariance
}

/// One intermediate or final frame's metadata, per `ADR-0399`
/// (`VOX-HLS-008`): the `ADR-0122` generation plus the transportable
/// half of the `ADR-0391` convergence triple — sample count and
/// optional variance. The mean is the frame itself; a metadata copy of
/// it would invite divergence.
public struct ProgressiveFrameMetadata: Sendable, Hashable {
    public let generation: RenderGeneration
    public let sampleCount: Int
    /// The unbiased variance, absent below two samples.
    public let variance: Double?

    /// Creates validated metadata.
    ///
    /// - Throws: ``ProgressiveFrameError``.
    public init(
        generation: RenderGeneration,
        sampleCount: Int,
        variance: Double?
    ) throws {
        guard sampleCount >= 1 else {
            throw ProgressiveFrameError.invalidSampleCount
        }
        if let variance {
            guard variance.isFinite, variance >= 0 else {
                throw ProgressiveFrameError.invalidVariance
            }
        }
        self.generation = generation
        self.sampleCount = sampleCount
        self.variance = variance
    }
}

/// One published progressive frame: content plus its metadata.
public struct ProgressiveFrame<Content: Sendable>: Sendable {
    public let content: Content
    public let metadata: ProgressiveFrameMetadata

    public init(content: Content, metadata: ProgressiveFrameMetadata) {
        self.content = content
        self.metadata = metadata
    }
}

/// The `VOX-HLS-008`/`VOX-HLS-009` session, per `ADR-0399`: the
/// `ADR-0122` counter and presenter composed unchanged.
///
/// A final frame is not special — a stale final drops exactly like a
/// stale intermediate, which is the whole of "shall not publish stale
/// final output". Cancellation is a generation advance: it instantly
/// stales every in-flight frame of the cancelled request, with no flag
/// to poll and no race against a final publish, because staleness is
/// decided at the presentation seam by one comparison.
public actor ProgressiveRenderSession<Content: Sendable> {
    private let counter: RenderGenerationCounter
    private let presenter: FramePresenter<Content>

    public init() {
        let counter = RenderGenerationCounter()
        self.counter = counter
        self.presenter = FramePresenter(counter: counter)
    }

    /// Begins one request, minting its generation.
    public func begin() async -> RenderGeneration {
        await counter.advance()
    }

    /// Cancels the current request by minting the next generation:
    /// every frame stamped before it — intermediate or final — is now
    /// stale at the presentation seam.
    public func cancel() async {
        _ = await counter.advance()
    }

    /// Publishes one frame — intermediate or final, the seam does not
    /// distinguish — dropping it if its generation is stale.
    public func publish(
        _ frame: ProgressiveFrame<Content>
    ) async -> PresentationOutcome<Content> {
        await presenter.present(
            StampedFrame(
                generation: frame.metadata.generation,
                content: frame.content
            )
        )
    }
}

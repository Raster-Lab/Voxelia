// SPDX-License-Identifier: MIT

/// The result one inference adapter produces: descriptors and their
/// per-segment fields, ready for the host to assemble into a validated
/// ``Segmentation`` with the host's own provenance and identity.
public struct SegmentInferenceResult: Sendable {
    /// The produced segments' descriptors; each algorithm descriptor
    /// should carry ``SegmentAlgorithmType/automatic`` and the model
    /// identity that produced it.
    public let descriptors: ContiguousArray<SegmentDescriptor>
    /// One field per produced segment, overlap permitted.
    public let fields: ContiguousArray<SegmentField>

    public init(
        descriptors: ContiguousArray<SegmentDescriptor>,
        fields: ContiguousArray<SegmentField>
    ) {
        self.descriptors = descriptors
        self.fields = fields
    }
}

/// The one inference-facing surface of the segmentation model, per
/// `ADR-0364` (`VOX-SEG-010`).
///
/// AI inference integrates through conformances to this protocol in
/// **optional adapter packages** and is never embedded in the
/// foundational model: no Voxelia module imports an inference runtime
/// (`check_prohibited_imports.py` forbids `CoreML` and `CreateML` in
/// every module, negative-tested), and this protocol references only
/// accepted model vocabulary. An adapter receives authoritative image
/// data and returns descriptors and fields; the host assembles and
/// publishes the ``Segmentation``, so admission and provenance stay
/// with the accepted lifecycle rather than the adapter.
public protocol SegmentInferenceAdapter: Sendable {
    /// The adapter's stable identity, recorded by hosts beside the
    /// produced segments' algorithm descriptors.
    var adapterIdentity: String { get }

    /// Runs inference over one authoritative image.
    func infer(image: ImageData) async throws -> SegmentInferenceResult
}

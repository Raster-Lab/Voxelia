// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by post-process declaration admission.
public enum PostProcessDeclarationError: Error, Sendable, Equatable {
    /// The method identifier was empty or whitespace-only.
    case emptyMethodIdentifier
}

/// What kind of declared step touched an output, per `ADR-0393`: the
/// closed vocabulary of `VOX-PRR-013` and `VOX-PRR-014`.
public enum PostProcessKind: String, Sendable, Hashable, Codable {
    case denoising
    case generativeReconstruction
}

/// One declared post-processing step: kind, processor identity and
/// method. Anonymous or unversioned post-processing is
/// unrepresentable — the processor is a full ``SoftwareIdentity``,
/// the accepted provenance vocabulary.
public struct PostProcessDeclaration: Sendable {
    public let kind: PostProcessKind
    public let processor: SoftwareIdentity
    public let methodIdentifier: String

    /// Creates a validated declaration.
    ///
    /// - Throws: ``PostProcessDeclarationError``.
    public init(
        kind: PostProcessKind,
        processor: SoftwareIdentity,
        methodIdentifier: String
    ) throws {
        guard methodIdentifier.contains(where: { !$0.isWhitespace }) else {
            throw PostProcessDeclarationError.emptyMethodIdentifier
        }
        self.kind = kind
        self.processor = processor
        self.methodIdentifier = methodIdentifier
    }
}

/// One photorealistic output's claim of what touched it, per
/// `ADR-0393`: the ordered declaration list. Constructing this record
/// is the only way to claim an output, so "implicit generative
/// reconstruction" is a type error, not a policy violation — output
/// either declares its steps or the record lies at construction, and
/// nothing in this module constructs records on the caller's behalf.
public struct PhotorealisticOutputRecord: Sendable {
    /// The declared steps, in application order; empty means the
    /// integration output untouched.
    public let postProcessing: ContiguousArray<PostProcessDeclaration>

    public init(postProcessing: ContiguousArray<PostProcessDeclaration>) {
        self.postProcessing = postProcessing
    }

    /// Whether any declared step is generative reconstruction — the
    /// host's acceptance policy reads this, never infers it.
    public var declaresGenerativeReconstruction: Bool {
        postProcessing.contains { $0.kind == .generativeReconstruction }
    }
}

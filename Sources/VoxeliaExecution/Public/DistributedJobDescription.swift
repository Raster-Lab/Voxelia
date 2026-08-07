// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised by distributed-job admission.
public enum DistributedJobError: Error, Sendable, Equatable {
    /// The job identifier was empty or whitespace-only.
    case emptyJobIdentifier
    /// A tile origin was negative or an extent non-positive.
    case invalidTile
    /// The frame range started below zero.
    case invalidFrameRange
    /// The brick set was empty or contained an empty identifier.
    case invalidBrickSet
    /// The sample count was zero.
    case invalidSampleRange
    /// A required input's object identifier was empty.
    case invalidInputIdentity
    /// A sample-range partition was declared without a seed: sample
    /// ranges exist for stochastic accumulation, and stochastic work
    /// without a declared seed refuses.
    case missingSeed
}

/// One required input's transportable identity: the object identifier
/// spelling and the content digest — the pair `VOX-DST-002` names.
public struct JobInputIdentity: Sendable, Hashable, Codable {
    public let objectIdentifier: String
    public let contentID: ContentID

    /// Creates a validated input identity.
    ///
    /// - Throws: ``DistributedJobError/invalidInputIdentity``.
    public init(objectIdentifier: String, contentID: ContentID) throws {
        guard objectIdentifier.contains(where: { !$0.isWhitespace }) else {
            throw DistributedJobError.invalidInputIdentity
        }
        self.objectIdentifier = objectIdentifier
        self.contentID = contentID
    }

    private enum CodingKeys: String, CodingKey {
        case objectIdentifier
        case contentID
    }

    /// Decodes and revalidates.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            objectIdentifier: try container.decode(
                String.self,
                forKey: .objectIdentifier
            ),
            contentID: try container.decode(ContentID.self, forKey: .contentID)
        )
    }
}

/// The closed partition vocabulary of `VOX-DST-004`, verbatim: image
/// tile, frame range, brick set or sample range. The photorealistic
/// partitioning row is served by `imageTile` and `sampleRange`.
public enum WorkPartition: Sendable, Hashable, Codable {
    case imageTile(originX: Int, originY: Int, width: Int, height: Int)
    case frameRange(ClosedRange<Int>)
    case brickSet(ContiguousArray<String>)
    case sampleRange(firstSample: UInt64, count: UInt64)

    /// Validates the partition's own bounds.
    ///
    /// - Throws: ``DistributedJobError``.
    public func validate() throws {
        switch self {
        case .imageTile(let originX, let originY, let width, let height):
            guard originX >= 0, originY >= 0, width >= 1, height >= 1 else {
                throw DistributedJobError.invalidTile
            }
        case .frameRange(let range):
            guard range.lowerBound >= 0 else {
                throw DistributedJobError.invalidFrameRange
            }
        case .brickSet(let bricks):
            guard !bricks.isEmpty,
                bricks.allSatisfy({ $0.contains(where: { !$0.isWhitespace }) })
            else {
                throw DistributedJobError.invalidBrickSet
            }
        case .sampleRange(_, let count):
            guard count >= 1 else {
                throw DistributedJobError.invalidSampleRange
            }
        }
    }
}

/// One transport-neutral distributable job, per `ADR-0401`: identity,
/// versions, canonical parameters digest, required input identities,
/// the `ADR-0380` compatibility contract verbatim, a validated
/// partition and — when the partition is stochastic — a declared
/// `VOXELIA-ALG-0079` seed. `Codable` with revalidating decode:
/// transport-neutral means JSON through the ordinary coder, and every
/// decode passes the same throwing admission as construction.
public struct DistributedJobDescription: Sendable, Codable {
    public let jobIdentifier: String
    public let operation: DerivationOperationToken
    public let operationVersion: SemanticVersion
    /// The canonical operation-parameters digest (`ADR-0054`):
    /// parameters travel as their identity, not as re-encoded
    /// structures.
    public let parameters: ContentID
    public let requiredInputs: ContiguousArray<JobInputIdentity>
    /// The `ADR-0380` contract, embedded verbatim — scalar formats,
    /// geometry, quality and capability requirements in one spelling.
    public let compatibility: DeclaredImplementationContract
    public let partition: WorkPartition
    /// The deterministic seed; required for sample-range partitions.
    public let seed: UInt64?

    /// Creates a validated job description.
    ///
    /// - Throws: ``DistributedJobError``.
    public init(
        jobIdentifier: String,
        operation: DerivationOperationToken,
        operationVersion: SemanticVersion,
        parameters: ContentID,
        requiredInputs: ContiguousArray<JobInputIdentity>,
        compatibility: DeclaredImplementationContract,
        partition: WorkPartition,
        seed: UInt64?
    ) throws {
        guard jobIdentifier.contains(where: { !$0.isWhitespace }) else {
            throw DistributedJobError.emptyJobIdentifier
        }
        try partition.validate()
        if case .sampleRange = partition {
            guard seed != nil else {
                throw DistributedJobError.missingSeed
            }
        }
        self.jobIdentifier = jobIdentifier
        self.operation = operation
        self.operationVersion = operationVersion
        self.parameters = parameters
        self.requiredInputs = requiredInputs
        self.compatibility = compatibility
        self.partition = partition
        self.seed = seed
    }

    private enum CodingKeys: String, CodingKey {
        case jobIdentifier
        case operation
        case operationVersion
        case parameters
        case requiredInputs
        case compatibility
        case partition
        case seed
    }

    /// Decodes and revalidates through the throwing admission.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            jobIdentifier: try container.decode(String.self, forKey: .jobIdentifier),
            operation: try container.decode(
                DerivationOperationToken.self,
                forKey: .operation
            ),
            operationVersion: try container.decode(
                SemanticVersion.self,
                forKey: .operationVersion
            ),
            parameters: try container.decode(ContentID.self, forKey: .parameters),
            requiredInputs: try container.decode(
                ContiguousArray<JobInputIdentity>.self,
                forKey: .requiredInputs
            ),
            compatibility: try container.decode(
                DeclaredImplementationContract.self,
                forKey: .compatibility
            ),
            partition: try container.decode(WorkPartition.self, forKey: .partition),
            seed: try container.decodeIfPresent(UInt64.self, forKey: .seed)
        )
    }
}

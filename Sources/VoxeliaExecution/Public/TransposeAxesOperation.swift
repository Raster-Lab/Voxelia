// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by axis-transposition admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum TransposeError: Error, Sendable, Equatable {
    case invalidAxisOrder
    case unsupportedGeometry
    case rankLimitExceeded
}

/// The axis-transposition operation registered by `ADR-0115` under the
/// `axis-transposition/exact-v1` model of `VOXELIA-ALG-0012`.
///
/// Every output sample is the whole source sample at the permuted
/// index — exact integer arithmetic, no value read — and every
/// per-axis property travels with its axis. The operation mints no
/// identifiers and acquires no clock.
public enum TransposeAxesOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.transpose-axes"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.transpose-axes.cpu"

    /// The inclusive rank ceiling.
    public static let maximumRank = 8

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one transposition through the budgeted coordinated
    /// read boundary.
    ///
    /// - Throws: ``TransposeError``, or the audited typed errors of
    ///   the storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        axisOrder: [Int],
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0115.
        let inputExtents = input.descriptor.shape.extents
        let rank = inputExtents.count
        guard rank <= Self.maximumRank else {
            throw TransposeError.rankLimitExceeded
        }
        guard
            axisOrder.count == rank,
            Set(axisOrder) == Set(0..<rank)
        else {
            throw TransposeError.invalidAxisOrder
        }
        guard input.descriptor.spatialGeometry == nil else {
            throw TransposeError.unsupportedGeometry
        }

        // One budgeted coordinated full read; the retention is released
        // as soon as the owned bytes are staged.
        let fullRegion = try ImageRegion(
            lowerBounds: ContiguousArray(repeating: 0, count: rank),
            upperBounds: inputExtents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // The frozen VOXELIA-ALG-0012 exact remap over whole samples.
        let sampleByteCount =
            input.descriptor.scalarFormat.type.byteCount
            * input.descriptor.components.count
        var outputExtents = [Int]()
        outputExtents.reserveCapacity(rank)
        for axis in 0..<rank {
            outputExtents.append(inputExtents[axisOrder[axis]])
        }
        var inputStrides = [Int](repeating: 1, count: rank)
        for axis in 1..<max(rank, 1) {
            inputStrides[axis] = inputStrides[axis - 1] * inputExtents[axis - 1]
        }
        let elementCount = inputExtents.reduce(1, *)
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(elementCount * sampleByteCount)
        var outputIndex = [Int](repeating: 0, count: rank)
        for _ in 0..<elementCount {
            var sourceOffset = 0
            for axis in 0..<rank {
                sourceOffset += outputIndex[axis] * inputStrides[axisOrder[axis]]
            }
            let base = sourceOffset * sampleByteCount
            outputBytes.append(contentsOf: storedBytes[base..<(base + sampleByteCount)])
            // Odometer increment, axis zero fastest.
            var axis = 0
            while axis < rank {
                outputIndex[axis] += 1
                if outputIndex[axis] < outputExtents[axis] {
                    break
                }
                outputIndex[axis] = 0
                axis += 1
            }
        }

        // Every per-axis property travels with its axis.
        let outputShape = try ImageShape(extents: ContiguousArray(outputExtents))
        var outputAxes = ContiguousArray<AxisDescriptor>()
        outputAxes.reserveCapacity(rank)
        for axis in 0..<rank {
            outputAxes.append(input.descriptor.axes[axisOrder[axis]])
        }
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: input.descriptor.scalarFormat.type,
                    componentCount: input.descriptor.components.count
                ),
                bytes: outputBytes
            )
        )
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: input.descriptor.semantic,
            axes: outputAxes,
            spatialGeometry: nil,
            valueTransform: input.descriptor.valueTransform,
            units: input.descriptor.units
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(axisOrder: axisOrder),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // Registered tokens, derivation recipe, content identity and
        // the subject-bound record with its parent edge, per the
        // accepted operation pattern.
        let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
        let operationToken = try DerivationOperationToken(
            rawValue: Self.operationIdentifier
        )
        let implementationToken = try DerivationOperationToken(
            rawValue: Self.implementationIdentifier
        )
        let derivation = try DerivationIdentity(
            operationID: operationToken,
            operationVersion: version,
            implementation: DerivationImplementationReference(
                identifier: implementationToken,
                version: version
            ),
            inputs: [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "input"),
                    identity: .object(input.identity.objectID)
                )
            ],
            parameterDigest: parameterDigest,
            declaresZeroInputGenerator: false
        )
        let outputIdentity = try DataIdentity(
            objectID: outputObjectID,
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: outputBytes
            ),
            sourceIdentities: [],
            derivation: derivation
        )
        let provenance = try ProvenanceRecord(
            id: outputProvenanceID,
            kind: .transformed,
            createdAt: createdAt,
            subject: .object(outputObjectID),
            software: software,
            activity: .operation(
                try OperationProvenance(
                    operationID: operationToken,
                    operationVersion: version,
                    implementationID: implementationToken,
                    implementationVersion: version,
                    parameterDigest: parameterDigest
                ),
                try executionClaim(version: version)
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(input.identity.objectID),
                    parent: .graphNode(input.provenance.id)
                )
            ],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )

        return try ImageData(
            descriptor: outputDescriptor,
            storage: outputStorage,
            metadata: input.metadata,
            provenance: provenance,
            identity: outputIdentity
        )
    }

    /// Builds the frozen parameter collection for one axis order.
    static func parameterCollection(axisOrder: [Int]) throws -> MetadataCollection {
        try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "axis-order"
                ),
                value: .array(
                    try MetadataArray(
                        values: axisOrder.map { .signedInteger(Int64($0)) }
                    )
                ),
                privacyClass: .technical
            )
        ])
    }

    private static func executionClaim(
        version: SemanticVersion
    ) throws -> ExecutionProvenanceClaim {
        ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: version
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.backend.cpu"
                ),
                version: version
            ),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.exact"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .exact,
            capabilityClass: nil,
            kernel: nil
        )
    }
}

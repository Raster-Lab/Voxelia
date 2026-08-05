// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by singleton-axis-squeeze admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum SqueezeError: Error, Sendable, Equatable {
    case invalidAxisSelection
    case unsupportedGeometry
}

/// The singleton-axis-squeeze operation registered by `ADR-0116` under
/// the `singleton-axis-squeeze/exact-v1` model of `VOXELIA-ALG-0013`.
///
/// Declared extent-one axes drop from the descriptor while the sample
/// bytes stay identical in order — a descriptor-level rank change with
/// no arithmetic. The operation mints no identifiers and acquires no
/// clock.
public enum SqueezeAxesOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.squeeze-axes"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.squeeze-axes.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one squeeze through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``SqueezeError``, or the audited typed errors of the
    ///   storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        axes droppedAxes: [Int],
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0116: explicit, existing,
        // singleton, unique, non-empty and never total.
        let inputExtents = input.descriptor.shape.extents
        let rank = inputExtents.count
        let dropped = Set(droppedAxes)
        guard
            !droppedAxes.isEmpty,
            dropped.count == droppedAxes.count,
            dropped.count < rank,
            droppedAxes.allSatisfy({ $0 >= 0 && $0 < rank }),
            droppedAxes.allSatisfy({ inputExtents[$0] == 1 })
        else {
            throw SqueezeError.invalidAxisSelection
        }
        guard input.descriptor.spatialGeometry == nil else {
            throw SqueezeError.unsupportedGeometry
        }

        // One budgeted coordinated full read; the payload is
        // byte-identical per the registered model.
        let fullRegion = try ImageRegion(
            lowerBounds: ContiguousArray(repeating: 0, count: rank),
            upperBounds: inputExtents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let outputBytes = read.result.bytes
        try await coordinator.release(read.retention)

        var outputExtents = [Int]()
        var outputAxes = ContiguousArray<AxisDescriptor>()
        for axis in 0..<rank where !dropped.contains(axis) {
            outputExtents.append(inputExtents[axis])
            outputAxes.append(input.descriptor.axes[axis])
        }
        let outputShape = try ImageShape(extents: ContiguousArray(outputExtents))
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
                payload: try parameterCollection(axes: droppedAxes),
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

    /// Builds the frozen parameter collection for one axis selection.
    static func parameterCollection(axes: [Int]) throws -> MetadataCollection {
        try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "axes"
                ),
                value: .array(
                    try MetadataArray(values: axes.map { .signedInteger(Int64($0)) })
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

// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaStorage

/// An error raised by display-inversion admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum InvertDisplayError: Error, Sendable, Equatable {
    case unsupportedScalarType
    case unsupportedComponentLayout
    case unsupportedSemantic
    case unsupportedValueTransform
}

/// The display-inversion operation registered by `ADR-0112` under the
/// `display-inversion/exact-v1` model of `VOXELIA-ALG-0011`.
///
/// Every eight-bit display sample maps to `255 - x` exactly — an
/// involution with no floating-point step — for inverted presentation
/// polarity, the `MONOCHROME1` convention. The operation mints no
/// identifiers and acquires no clock.
public enum InvertDisplayOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.invert-display"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.invert-display.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one inversion through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``InvertDisplayError``, or the audited typed errors
    ///   of the storage, identity, provenance and aggregate contracts.
    public static func execute(
        input: ImageData,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0112: eight-bit
        // single-component intensity of any rank, no value transform.
        guard input.descriptor.scalarFormat.type == .uint8 else {
            throw InvertDisplayError.unsupportedScalarType
        }
        guard
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar
        else {
            throw InvertDisplayError.unsupportedComponentLayout
        }
        guard input.descriptor.semantic == .intensity else {
            throw InvertDisplayError.unsupportedSemantic
        }
        guard input.descriptor.valueTransform == nil else {
            throw InvertDisplayError.unsupportedValueTransform
        }

        // One budgeted coordinated full read; the retention is released
        // as soon as the owned bytes are staged.
        let extents = input.descriptor.shape.extents
        let fullRegion = try ImageRegion(
            lowerBounds: ContiguousArray(repeating: 0, count: extents.count),
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // The frozen VOXELIA-ALG-0011 exact involution.
        let outputBytes = storedBytes.map { 255 - $0 }

        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: input.descriptor.shape,
                    scalarType: .uint8,
                    componentCount: 1
                ),
                bytes: outputBytes
            )
        )

        // The frozen empty parameter schema digested under the
        // registered operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // Registered tokens, derivation recipe, content identity and
        // the subject-bound record, per the accepted operation pattern.
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
            descriptor: input.descriptor,
            storage: outputStorage,
            metadata: input.metadata,
            provenance: provenance,
            identity: outputIdentity
        )
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

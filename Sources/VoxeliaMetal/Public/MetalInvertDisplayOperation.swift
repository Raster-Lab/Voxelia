// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaStorage

/// The device implementation of the registered display-inversion
/// operation per `ADR-0133`.
///
/// The operation executes the accepted integer-exact `ADR-0132`
/// kernel and assembles the same output shape as the CPU
/// implementation — the whole descriptor passes through, calibration
/// included — with the exact device claim: the involution has no
/// floating-point step, so `exact` precision is the honest policy.
/// The operation mints no identifiers and acquires no clock.
public enum MetalInvertDisplayOperation {
    /// The registered device implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.invert-display.metal"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one inversion on the device through the budgeted
    /// coordinated read boundary.
    ///
    /// - Throws: `InvertDisplayError` for device
    ///   admission, ``MetalInvertKernelError``, or the audited typed
    ///   errors of the storage, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator,
        kernel: MetalInvertKernel
    ) async throws -> ImageData {
        // Device admission mirroring the registered operation.
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

        // One budgeted coordinated full read; the accepted kernel is
        // the entire device path, and it is exact.
        let extents = input.descriptor.shape.extents
        let fullRegion = try ImageRegion(
            lowerBounds: ContiguousArray(repeating: 0, count: extents.count),
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)
        let outputBytes = try kernel.invertSamples(storedBytes)

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

        // The registered operation with the device implementation
        // reference and the exact device claim.
        let version = try SemanticVersion(major: 1, minor: 0, patch: 0)
        let operationToken = try DerivationOperationToken(
            rawValue: InvertDisplayOperation.operationIdentifier
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
                try deviceClaim(version: version, kernel: kernel)
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

    private static func deviceClaim(
        version: SemanticVersion,
        kernel: MetalInvertKernel
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
                    rawValue: "org.voxelia.backend.metal"
                ),
                version: try SemanticVersion(major: 1, minor: 0, patch: 0)
            ),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.exact"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .exact,
            capabilityClass: kernel.context.capabilityClass,
            kernel: kernel.kernelReference
        )
    }
}

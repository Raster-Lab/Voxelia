// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaStorage

/// The device implementation of the registered window-level operation
/// per `ADR-0092`.
///
/// The operation executes the accepted `ADR-0080` kernel and assembles
/// the same output shape as the CPU implementation with the honest
/// device claim: `binary32-device` precision, `approximate` status,
/// the kernel component reference and the detected capability class —
/// `MSL` has no 64-bit floating type, so `binary64-strict` is
/// prohibited. Device admission — widened to the 16-bit scalar types
/// by `ADR-0093` — is `uint8`, `int16` or `uint16` samples with an
/// absent or identity value transform, because the kernel implements
/// the plain registered model. The operation mints no identifiers and
/// acquires no clock.
public enum MetalWindowLevelOperation {
    /// The registered device implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.window-level.metal"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one window-level mapping on the device through the
    /// budgeted coordinated read boundary.
    ///
    /// - Throws: ``VoxeliaExecution/WindowLevelError`` for device
    ///   admission, ``MetalKernelError``, or the audited typed errors
    ///   of the storage, identity, provenance and aggregate contracts.
    public static func execute(
        input: ImageData,
        center: MetadataFloatingPoint,
        width: MetadataFloatingPoint,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator,
        kernel: MetalWindowLevelKernel
    ) async throws -> ImageData {
        // Device admission per ADR-0092 widened by ADR-0093: the
        // kernel implements the plain registered model over uint8,
        // int16 and uint16 samples; 16-bit device reads are native
        // little-endian, so a non-native declared order is outside
        // the admitted scalar formats.
        let scalarType = input.descriptor.scalarFormat.type
        guard
            scalarType == .uint8 || scalarType == .int16
                || scalarType == .uint16
        else {
            throw WindowLevelError.unsupportedScalarType
        }
        guard
            scalarType == .uint8
                || input.descriptor.scalarFormat.byteOrder == .native
        else {
            throw WindowLevelError.unsupportedScalarType
        }
        guard
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar
        else {
            throw WindowLevelError.unsupportedComponentLayout
        }
        guard input.descriptor.semantic == .intensity else {
            throw WindowLevelError.unsupportedSemantic
        }
        switch input.descriptor.valueTransform {
        case nil, .identity:
            break
        default:
            throw WindowLevelError.unsupportedValueTransform
        }
        guard width.value >= 1.0 else {
            throw WindowLevelError.invalidWindowWidth
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

        // The accepted kernel is the entire device numeric path.
        let mappedBytes = try kernel.mapSamples(
            storedBytes: storedBytes,
            scalarType: scalarType,
            center: center.value,
            width: width.value
        )

        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: input.descriptor.shape,
                    scalarType: .uint8,
                    componentCount: 1
                ),
                bytes: mappedBytes
            )
        )
        let outputDescriptor = try ImageDescriptor(
            shape: input.descriptor.shape,
            scalarFormat: try ScalarFormat(
                type: .uint8,
                validBitCount: nil,
                byteOrder: .native
            ),
            components: try ComponentDescriptor(
                count: 1,
                interpretation: .scalar,
                layout: .interleaved,
                componentNames: nil
            ),
            semantic: .intensity,
            axes: input.descriptor.axes,
            spatialGeometry: input.descriptor.spatialGeometry,
            valueTransform: nil,
            units: nil
        )

        // The one frozen parameter authority per ADR-0092: both
        // implementations digest identical parameter documents.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try WindowLevelOperation.parameterCollection(
                    center: center,
                    width: width,
                    paddingValue: nil
                ),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // The registered operation at its current contract version
        // with the device implementation reference and honest claim.
        let operationVersion = try SemanticVersion(major: 1, minor: 4, patch: 0)
        let implementationVersion = try SemanticVersion(major: 1, minor: 1, patch: 0)
        let operationToken = try DerivationOperationToken(
            rawValue: WindowLevelOperation.operationIdentifier
        )
        let implementationToken = try DerivationOperationToken(
            rawValue: Self.implementationIdentifier
        )
        let derivation = try DerivationIdentity(
            operationID: operationToken,
            operationVersion: operationVersion,
            implementation: DerivationImplementationReference(
                identifier: implementationToken,
                version: implementationVersion
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
                overCanonicalPackedBytes: mappedBytes
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
                    operationVersion: operationVersion,
                    implementationID: implementationToken,
                    implementationVersion: implementationVersion,
                    parameterDigest: parameterDigest
                ),
                try deviceClaim(
                    operationVersion: operationVersion,
                    kernel: kernel
                )
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

    private static func deviceClaim(
        operationVersion: SemanticVersion,
        kernel: MetalWindowLevelKernel
    ) throws -> ExecutionProvenanceClaim {
        ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: operationVersion
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.backend.metal"
                ),
                version: try SemanticVersion(major: 1, minor: 0, patch: 0)
            ),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.binary32-device"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .approximate,
            capabilityClass: kernel.context.capabilityClass,
            kernel: kernel.kernelReference
        )
    }
}

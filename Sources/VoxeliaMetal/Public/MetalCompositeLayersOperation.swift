// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaExecution
import VoxeliaStorage

/// The device implementation of the registered layer compositing
/// operation per `ADR-0098`.
///
/// The operation executes the accepted `ADR-0096` kernel and assembles
/// the same output shape as the CPU implementation with the honest
/// device claim: `binary32-device` precision, `approximate` status,
/// the composite kernel component reference and the detected
/// capability class — `MSL` has no 64-bit floating type, so
/// `binary64-strict` is prohibited. Device admission mirrors the
/// registered operation. The operation mints no identifiers and
/// acquires no clock.
public enum MetalCompositeLayersOperation {
    /// The registered device implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.composite-layers.metal"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one composite on the device through the budgeted
    /// coordinated read boundary.
    ///
    /// - Throws: ``VoxeliaExecution/CompositeError`` for device
    ///   admission, ``MetalCompositeKernelError``, or the audited
    ///   typed errors of the storage, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        layers: [ImageData],
        opacities: [Double],
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator,
        kernel: MetalCompositeKernel
    ) async throws -> ImageData {
        // Device admission mirroring the registered operation per
        // ADR-0098.
        guard
            layers.count >= CompositeLayersOperation.minimumLayerCount,
            layers.count <= CompositeLayersOperation.maximumLayerCount
        else {
            throw CompositeError.invalidLayerCount
        }
        let extents = layers[0].descriptor.shape.extents
        for layer in layers {
            guard layer.descriptor.shape.extents == extents else {
                throw CompositeError.extentMismatch
            }
            guard
                extents.count == 2,
                layer.descriptor.scalarFormat.type == .uint8,
                layer.descriptor.components.count == 1,
                layer.descriptor.components.interpretation == .scalar,
                layer.descriptor.semantic == .intensity,
                layer.descriptor.valueTransform == nil
            else {
                throw CompositeError.unsupportedLayerFormat
            }
            // The device implementation claims contract 1.1.0 — the
            // geometry-free revision it implements — so calibrated
            // layers stay outside its admitted format.
            for axis in layer.descriptor.axes {
                guard case .indexOnly = axis.sampling else {
                    throw CompositeError.unsupportedLayerFormat
                }
            }
            guard layer.descriptor.spatialGeometry == nil else {
                throw CompositeError.unsupportedLayerFormat
            }
        }
        guard opacities.count == layers.count else {
            throw CompositeError.invalidOpacity
        }
        for opacity in opacities {
            guard opacity.isFinite, opacity >= 0, opacity <= 1 else {
                throw CompositeError.invalidOpacity
            }
        }

        // One budgeted coordinated full read per layer, in declared
        // order; the accepted kernel is the entire device numeric
        // path.
        let fullRegion = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: extents
        )
        var layerBytes = [[UInt8]]()
        layerBytes.reserveCapacity(layers.count)
        for layer in layers {
            let read = try await coordinator.read(
                from: layer.storage,
                region: fullRegion
            )
            layerBytes.append(read.result.bytes)
            try await coordinator.release(read.retention)
        }
        let outputBytes = try kernel.blendLayers(layerBytes, opacities: opacities)

        let outputShape = try ImageShape(extents: extents)
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: .uint8,
                    componentCount: 1
                ),
                bytes: outputBytes
            )
        )
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: try ScalarFormat(
                type: .uint8,
                validBitCount: nil,
                byteOrder: .native
            ),
            components: layers[0].descriptor.components,
            semantic: .intensity,
            axes: layers[0].descriptor.axes,
            spatialGeometry: nil,
            valueTransform: nil,
            units: nil
        )

        // The one frozen parameter authority per ADR-0098: both
        // implementations digest identical parameter documents.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try CompositeLayersOperation.parameterCollection(
                    opacities: opacities
                ),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // The registered operation at its current contract version
        // with the device implementation reference and honest claim.
        let operationVersion = try SemanticVersion(major: 1, minor: 1, patch: 0)
        let implementationVersion = try SemanticVersion(major: 1, minor: 0, patch: 0)
        let operationToken = try DerivationOperationToken(
            rawValue: CompositeLayersOperation.operationIdentifier
        )
        let implementationToken = try DerivationOperationToken(
            rawValue: Self.implementationIdentifier
        )
        let layerRole = try DerivationInputRole(rawValue: "layer")
        let derivation = try DerivationIdentity(
            operationID: operationToken,
            operationVersion: operationVersion,
            implementation: DerivationImplementationReference(
                identifier: implementationToken,
                version: implementationVersion
            ),
            inputs: ContiguousArray(
                layers.map { layer in
                    DerivationInput(
                        role: layerRole,
                        identity: .object(layer.identity.objectID)
                    )
                }
            ),
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
        let provenanceRole = try ProvenanceInputRole(rawValue: "layer")
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
            inputs: ContiguousArray(
                try layers.enumerated().map { position, layer in
                    try ProvenanceInput(
                        role: provenanceRole,
                        occurrence: UInt32(position + 1),
                        identity: .object(layer.identity.objectID),
                        parent: .graphNode(layer.provenance.id)
                    )
                }
            ),
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )

        return try ImageData(
            descriptor: outputDescriptor,
            storage: outputStorage,
            metadata: try MetadataCollection(entries: []),
            provenance: provenance,
            identity: outputIdentity
        )
    }

    private static func deviceClaim(
        operationVersion: SemanticVersion,
        kernel: MetalCompositeKernel
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

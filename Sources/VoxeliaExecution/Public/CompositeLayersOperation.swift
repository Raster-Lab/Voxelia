// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaStorage

/// An error raised by layer compositing admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum CompositeError: Error, Sendable, Equatable {
    case invalidLayerCount
    case extentMismatch
    case unsupportedLayerFormat
    case unsupportedAxisSampling
    case unsupportedGeometry
    case invalidOpacity
}

/// The layer compositing operation registered by `ADR-0090` under the
/// `layered-linear-blend/binary64-v1` model of `VOXELIA-ALG-0009`.
///
/// Every output element blends the declared layers over a black
/// background through the frozen binary64 composite-over sequence with
/// one opacity per layer; a first layer at opacity one reproduces its
/// values exactly. The operation mints no identifiers and acquires no
/// clock.
public enum CompositeLayersOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.composite-layers"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.composite-layers.cpu"

    /// The inclusive layer-count bounds, widened to a single layer by
    /// `ADR-0094`; the ceiling matches the scene ceiling.
    public static let minimumLayerCount = 1
    public static let maximumLayerCount = 64

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one composite through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``CompositeError``, or the audited typed errors of the
    ///   storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        layers: [ImageData],
        opacities: [Double],
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0090.
        guard
            layers.count >= Self.minimumLayerCount,
            layers.count <= Self.maximumLayerCount
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
            for axis in layer.descriptor.axes {
                guard case .indexOnly = axis.sampling else {
                    throw CompositeError.unsupportedAxisSampling
                }
            }
            guard layer.descriptor.spatialGeometry == nil else {
                throw CompositeError.unsupportedGeometry
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
        // order; each retention is released as soon as the owned bytes
        // are staged.
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

        // The frozen VOXELIA-ALG-0009 blend: acc starts at positive
        // zero and every layer composites over it, no fused
        // multiply-add.
        let elementCount = extents[0] * extents[1]
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(elementCount)
        for index in 0..<elementCount {
            var accumulator = 0.0
            for (bytes, opacity) in zip(layerBytes, opacities) {
                let transparency = 1.0 - opacity
                let retained = accumulator * transparency
                let contributed = Double(bytes[index]) * opacity
                accumulator = retained + contributed
            }
            let rounded = accumulator.rounded(.toNearestOrEven)
            outputBytes.append(UInt8(min(255.0, max(0.0, rounded))))
        }

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

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(opacities: opacities),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // Registered tokens, derivation recipe, content identity and
        // the subject-bound record with one parent edge per layer, per
        // the accepted operation pattern.
        let version = try SemanticVersion(major: 1, minor: 1, patch: 0)
        let operationToken = try DerivationOperationToken(
            rawValue: Self.operationIdentifier
        )
        let implementationToken = try DerivationOperationToken(
            rawValue: Self.implementationIdentifier
        )
        let layerRole = try DerivationInputRole(rawValue: "layer")
        let derivation = try DerivationIdentity(
            operationID: operationToken,
            operationVersion: version,
            implementation: DerivationImplementationReference(
                identifier: implementationToken,
                version: version
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
                    operationVersion: version,
                    implementationID: implementationToken,
                    implementationVersion: version,
                    parameterDigest: parameterDigest
                ),
                try executionClaim(version: version)
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

    /// Builds the frozen parameter collection for one opacity list.
    static func parameterCollection(
        opacities: [Double]
    ) throws -> MetadataCollection {
        try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "opacities"
                ),
                value: .array(
                    try MetadataArray(
                        values: try opacities.map {
                            .floatingPoint(try MetadataFloatingPoint(value: $0))
                        }
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
                rawValue: "org.voxelia.precision.binary64-strict"
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

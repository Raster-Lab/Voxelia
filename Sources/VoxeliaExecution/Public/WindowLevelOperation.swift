// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaStorage

/// An error raised by version-one window-level admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum WindowLevelError: Error, Sendable, Equatable {
    case unsupportedScalarType
    case unsupportedComponentLayout
    case unsupportedSemantic
    case unsupportedValueTransform
    case invalidWindowWidth
}

/// The window-level operation registered by `ADR-0065` under the
/// `window-level-linear/binary64-v1` model of `VOXELIA-ALG-0002`.
///
/// Stored intensity samples map through the DICOM-derived linear window
/// function to the eight-bit display range with frozen binary64
/// evaluation order and ties-to-even rounding; the degenerate
/// unit-width window is a pure threshold with no special case. No
/// sample moves, so geometry, axes, sampling and metadata pass through
/// unchanged; the output display range is dimensionless, so units and
/// value transform are absent. The operation mints no identifiers and
/// acquires no clock.
public enum WindowLevelOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.window-level"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.window-level.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one window-level mapping through the budgeted
    /// coordinated read boundary.
    ///
    /// - Throws: ``WindowLevelError`` for version-one admission, or
    ///   the audited typed errors of the storage, metadata, identity,
    ///   provenance and aggregate contracts.
    public static func execute(
        input: ImageData,
        center: MetadataFloatingPoint,
        width: MetadataFloatingPoint,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0065.
        let scalarType = input.descriptor.scalarFormat.type
        guard scalarType == .uint8 || scalarType == .int16 else {
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
        guard input.descriptor.valueTransform == nil else {
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

        // The frozen VOXELIA-ALG-0002 model over exactly-converted
        // binary64 sample values.
        let mappedBytes = mapSamples(
            storedBytes: storedBytes,
            scalarType: scalarType,
            byteOrder: input.descriptor.scalarFormat.byteOrder,
            center: center.value,
            width: width.value
        )
        let outputBinding = try LogicalSampleBinding(
            shape: input.descriptor.shape,
            scalarType: .uint8,
            componentCount: 1
        )
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: outputBinding,
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

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(center: center, width: width),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // Registered tokens, derivation recipe, content identity and
        // the subject-bound record with its parent edge.
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

    /// Builds the frozen parameter collection for one window.
    static func parameterCollection(
        center: MetadataFloatingPoint,
        width: MetadataFloatingPoint
    ) throws -> MetadataCollection {
        try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "center"
                ),
                value: .floatingPoint(center),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "width"
                ),
                value: .floatingPoint(width),
                privacyClass: .technical
            ),
        ])
    }

    /// The exact `VOXELIA-ALG-0002` mapping pass.
    private static func mapSamples(
        storedBytes: [UInt8],
        scalarType: ScalarType,
        byteOrder: ByteOrder,
        center: Double,
        width: Double
    ) -> [UInt8] {
        let halfSpan = (width - 1.0) / 2.0
        let threshold = center - 0.5
        let lowerEdge = threshold - halfSpan
        let upperEdge = threshold + halfSpan

        func window(_ sample: Double) -> UInt8 {
            if sample <= lowerEdge {
                return 0
            }
            if sample > upperEdge {
                return 255
            }
            let mapped =
                ((sample - threshold) / (width - 1.0) + 0.5) * 255.0
            let rounded = mapped.rounded(.toNearestOrEven)
            return UInt8(min(255.0, max(0.0, rounded)))
        }

        switch scalarType {
        case .int16:
            // Two bytes per sample under the declared byte order; the
            // native declaration resolves to little-endian on every
            // supported Apple-silicon platform per VOXELIA-ALG-0002.
            var output = [UInt8]()
            output.reserveCapacity(storedBytes.count / 2)
            var offset = 0
            while offset + 1 < storedBytes.count {
                let low: UInt8
                let high: UInt8
                if byteOrder == .bigEndian {
                    high = storedBytes[offset]
                    low = storedBytes[offset + 1]
                } else {
                    low = storedBytes[offset]
                    high = storedBytes[offset + 1]
                }
                let bits = UInt16(high) << 8 | UInt16(low)
                let sample = Int16(bitPattern: bits)
                output.append(window(Double(sample)))
                offset += 2
            }
            return output
        default:
            var output = [UInt8]()
            output.reserveCapacity(storedBytes.count)
            for byte in storedBytes {
                output.append(window(Double(byte)))
            }
            return output
        }
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

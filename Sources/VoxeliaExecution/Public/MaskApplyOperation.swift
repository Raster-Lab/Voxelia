// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by mask-application admission.
public enum MaskApplyError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case shapeMismatch
    case invalidMaskValue
    case fillValueNotRepresentable
    case invalidOutputAxis
}

/// The mask application operation registered by `ADR-0353` under the
/// `mask-apply/binary64-v1` model of `VOXELIA-ALG-0058`.
///
/// Masked-in samples are kept byte-verbatim; masked-out samples take
/// the exactly-representable fill; any mask byte other than zero or
/// one rejects fail-closed. The operation mints no identifiers and
/// acquires no clock.
public enum MaskApplyOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.mask-apply"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.mask-apply.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one mask application through the budgeted coordinated
    /// read boundary.
    ///
    /// - Throws: ``MaskApplyError``, or the audited typed errors of the
    ///   storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        mask: ImageData,
        fillValue: Double,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        let scalarType = input.descriptor.scalarFormat.type
        let extents = input.descriptor.shape.extents
        guard
            (2...3).contains(extents.count),
            scalarType == .uint8 || scalarType == .int16
                || scalarType == .uint16 || scalarType == .float32,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity
                || input.descriptor.semantic == .parametric,
            input.descriptor.valueTransform == nil,
            mask.descriptor.scalarFormat.type == .uint8,
            mask.descriptor.semantic == .mask,
            mask.descriptor.components.count == 1
        else {
            throw MaskApplyError.unsupportedLayerFormat
        }
        guard mask.descriptor.shape.extents == extents else {
            throw MaskApplyError.shapeMismatch
        }
        let sampleWidth: Int
        switch scalarType {
        case .uint8: sampleWidth = 1
        case .int16, .uint16: sampleWidth = 2
        default: sampleWidth = 4
        }
        // The fill must round-trip the stored type exactly: a written
        // value must be the declared one, never a silent rewrite.
        guard let fillBytes = Self.exactFillBytes(fillValue, scalarType: scalarType)
        else {
            throw MaskApplyError.fillValueNotRepresentable
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: extents
        )
        let imageRead = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = imageRead.result.bytes
        try await coordinator.release(imageRead.retention)
        let maskRead = try await coordinator.read(from: mask.storage, region: fullRegion)
        let maskStored = maskRead.result.bytes
        try await coordinator.release(maskRead.retention)

        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(storedBytes.count)
        for (sampleIndex, maskByte) in maskStored.enumerated() {
            guard maskByte == 0 || maskByte == 1 else {
                throw MaskApplyError.invalidMaskValue
            }
            let start = sampleIndex * sampleWidth
            if maskByte == 1 {
                outputBytes.append(contentsOf: storedBytes[start..<start + sampleWidth])
            } else {
                outputBytes.append(contentsOf: fillBytes)
            }
        }

        let outputShape = try ImageShape(extents: extents)
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: scalarType,
                    componentCount: 1
                ),
                bytes: outputBytes
            )
        )
        var outputAxes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for index in 0..<extents.count {
            outputAxes.append(
                try Self.outputAxis(["u", "v", "w"][index], semantic: semantics[index])
            )
        }
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: input.descriptor.semantic,
            axes: outputAxes,
            spatialGeometry: input.descriptor.spatialGeometry,
            valueTransform: nil,
            units: nil
        )

        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: [
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "fill-value"
                        ),
                        value: .floatingPoint(
                            try MetadataFloatingPoint(value: fillValue)
                        ),
                        privacyClass: .technical
                    )
                ]),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

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
                ),
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "mask"),
                    identity: .object(mask.identity.objectID)
                ),
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
                try Self.executionClaim(version: version)
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(input.identity.objectID),
                    parent: .graphNode(input.provenance.id)
                ),
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "mask"),
                    occurrence: 1,
                    identity: .object(mask.identity.objectID),
                    parent: .graphNode(mask.provenance.id)
                ),
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

    /// The fill's exact little-endian stored encoding, or nil when the
    /// value does not round-trip the stored type.
    static func exactFillBytes(_ fill: Double, scalarType: ScalarType) -> [UInt8]? {
        guard fill.isFinite else { return nil }
        switch scalarType {
        case .uint8:
            guard fill == fill.rounded(), fill >= 0, fill <= 255 else { return nil }
            return [UInt8(fill)]
        case .int16:
            guard fill == fill.rounded(), fill >= -32768, fill <= 32767 else {
                return nil
            }
            let bits = UInt16(bitPattern: Int16(fill))
            return [UInt8(bits & 0xFF), UInt8(bits >> 8)]
        case .uint16:
            guard fill == fill.rounded(), fill >= 0, fill <= 65535 else { return nil }
            let bits = UInt16(fill)
            return [UInt8(bits & 0xFF), UInt8(bits >> 8)]
        case .float32:
            let narrowed = Float32(fill)
            guard Double(narrowed) == fill else { return nil }
            let bits = narrowed.bitPattern
            return [
                UInt8(bits & 0xFF),
                UInt8((bits >> 8) & 0xFF),
                UInt8((bits >> 16) & 0xFF),
                UInt8(bits >> 24),
            ]
        default:
            return nil
        }
    }

    static func executionClaim(
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

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw MaskApplyError.invalidOutputAxis
        }
        return try AxisDescriptor(
            id: axisID,
            name: name,
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }
}

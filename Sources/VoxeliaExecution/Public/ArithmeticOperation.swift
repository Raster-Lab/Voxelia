// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by image-arithmetic admission.
public enum ArithmeticError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case shapeMismatch
    case operandTypeMismatch
    case invalidScalarOperand
    case invalidOutputAxis
}

/// The arithmetic operator vocabulary of `VOXELIA-ALG-0058`.
public enum ArithmeticOperator: String, Sendable, Hashable {
    case add
    case subtract
    case multiply
}

/// The right-hand operand: a second image or one finite scalar.
public enum ArithmeticOperand: Sendable {
    case image(ImageData)
    case scalar(Double)
}

/// The image arithmetic operation registered by `ADR-0353` under the
/// `image-arithmetic/binary64-v1` model of `VOXELIA-ALG-0058`.
///
/// Operands widen exactly to binary64; integer outputs round
/// ties-to-even then saturate with every saturation counted into an
/// aggregated warning; float32 outputs store non-finite results
/// verbatim, counted likewise. The operation mints no identifiers and
/// acquires no clock.
public enum ArithmeticOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.image-arithmetic"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.image-arithmetic.cpu"

    /// The aggregated warning code counting integer saturations.
    public static let saturationWarningCode = "org.voxelia.warn.arithmetic-saturated"
    /// The aggregated warning code counting float32 non-finite results.
    public static let nonFiniteWarningCode = "org.voxelia.warn.arithmetic-non-finite"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one arithmetic pass through the budgeted coordinated
    /// read boundary.
    ///
    /// - Throws: ``ArithmeticError``, or the audited typed errors of
    ///   the storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        operand: ArithmeticOperand,
        operator arithmeticOperator: ArithmeticOperator,
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
            input.descriptor.valueTransform == nil
        else {
            throw ArithmeticError.unsupportedLayerFormat
        }
        switch operand {
        case .image(let right):
            guard right.descriptor.scalarFormat.type == scalarType else {
                throw ArithmeticError.operandTypeMismatch
            }
            guard right.descriptor.shape.extents == extents else {
                throw ArithmeticError.shapeMismatch
            }
        case .scalar(let value):
            guard value.isFinite else {
                throw ArithmeticError.invalidScalarOperand
            }
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: extents
        )
        let leftRead = try await coordinator.read(from: input.storage, region: fullRegion)
        let leftBytes = leftRead.result.bytes
        try await coordinator.release(leftRead.retention)
        var rightBytes: [UInt8]? = nil
        var rightObject: ImageData? = nil
        if case .image(let right) = operand {
            let read = try await coordinator.read(from: right.storage, region: fullRegion)
            rightBytes = read.result.bytes
            try await coordinator.release(read.retention)
            rightObject = right
        }

        let byteOrder = input.descriptor.scalarFormat.byteOrder
        let left = Self.widen(leftBytes, scalarType: scalarType, byteOrder: byteOrder)
        let right: [Double]
        switch operand {
        case .image:
            right = Self.widen(
                rightBytes ?? [],
                scalarType: scalarType,
                byteOrder: byteOrder
            )
        case .scalar(let value):
            right = [Double](repeating: value, count: left.count)
        }

        var outputBytes = [UInt8]()
        var saturatedCount: UInt64 = 0
        var nonFiniteCount: UInt64 = 0
        for index in 0..<left.count {
            let result: Double
            switch arithmeticOperator {
            case .add: result = left[index] + right[index]
            case .subtract: result = left[index] - right[index]
            case .multiply: result = left[index] * right[index]
            }
            switch scalarType {
            case .uint8:
                let rounded = result.rounded(.toNearestOrEven)
                if rounded < 0 {
                    outputBytes.append(0)
                    saturatedCount += 1
                } else if rounded > 255 {
                    outputBytes.append(255)
                    saturatedCount += 1
                } else {
                    outputBytes.append(UInt8(rounded))
                }
            case .int16, .uint16:
                let rounded = result.rounded(.toNearestOrEven)
                let lower: Double = scalarType == .int16 ? -32768 : 0
                let upper: Double = scalarType == .int16 ? 32767 : 65535
                let stored: Int
                if rounded < lower {
                    stored = Int(lower)
                    saturatedCount += 1
                } else if rounded > upper {
                    stored = Int(upper)
                    saturatedCount += 1
                } else {
                    stored = Int(rounded)
                }
                let bits =
                    scalarType == .int16
                    ? UInt16(bitPattern: Int16(stored)) : UInt16(stored)
                outputBytes.append(UInt8(bits & 0xFF))
                outputBytes.append(UInt8(bits >> 8))
            default:
                let narrowed = Float32(result)
                if !narrowed.isFinite {
                    nonFiniteCount += 1
                }
                let bits = narrowed.bitPattern
                outputBytes.append(UInt8(bits & 0xFF))
                outputBytes.append(UInt8((bits >> 8) & 0xFF))
                outputBytes.append(UInt8((bits >> 16) & 0xFF))
                outputBytes.append(UInt8(bits >> 24))
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

        var parameterEntries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "operator"
                ),
                value: .string(arithmeticOperator.rawValue),
                privacyClass: .technical
            )
        ]
        if case .scalar(let value) = operand {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "scalar-operand"
                    ),
                    value: .floatingPoint(try MetadataFloatingPoint(value: value)),
                    privacyClass: .technical
                )
            )
        }
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: parameterEntries),
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
        var derivationInputs = ContiguousArray<DerivationInput>([
            DerivationInput(
                role: try DerivationInputRole(rawValue: "input"),
                identity: .object(input.identity.objectID)
            )
        ])
        var provenanceInputs = ContiguousArray<ProvenanceInput>([
            try ProvenanceInput(
                role: try ProvenanceInputRole(rawValue: "input"),
                occurrence: 1,
                identity: .object(input.identity.objectID),
                parent: .graphNode(input.provenance.id)
            )
        ])
        if let rightObject {
            derivationInputs.append(
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "operand"),
                    identity: .object(rightObject.identity.objectID)
                )
            )
            provenanceInputs.append(
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "operand"),
                    occurrence: 1,
                    identity: .object(rightObject.identity.objectID),
                    parent: .graphNode(rightObject.provenance.id)
                )
            )
        }
        let derivation = try DerivationIdentity(
            operationID: operationToken,
            operationVersion: version,
            implementation: DerivationImplementationReference(
                identifier: implementationToken,
                version: version
            ),
            inputs: derivationInputs,
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
        var warnings = ContiguousArray<ProvenanceWarning>()
        if saturatedCount >= 1 {
            warnings.append(
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(
                        rawValue: Self.saturationWarningCode
                    ),
                    schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                    severity: .qualityAffecting,
                    occurrenceCount: saturatedCount
                )
            )
        }
        if nonFiniteCount >= 1 {
            warnings.append(
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(
                        rawValue: Self.nonFiniteWarningCode
                    ),
                    schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                    severity: .qualityAffecting,
                    occurrenceCount: nonFiniteCount
                )
            )
        }
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
                try MaskApplyOperation.executionClaim(version: version)
            ),
            inputs: provenanceInputs,
            warnings: warnings,
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

    /// Exact binary64 widening in canonical order.
    static func widen(
        _ bytes: [UInt8],
        scalarType: ScalarType,
        byteOrder: ByteOrder
    ) -> [Double] {
        var out = [Double]()
        switch scalarType {
        case .uint8:
            out.reserveCapacity(bytes.count)
            for byte in bytes {
                out.append(Double(byte))
            }
        case .int16, .uint16:
            out.reserveCapacity(bytes.count / 2)
            var offset = 0
            while offset + 1 < bytes.count {
                let low: UInt8
                let high: UInt8
                if byteOrder == .bigEndian {
                    high = bytes[offset]
                    low = bytes[offset + 1]
                } else {
                    low = bytes[offset]
                    high = bytes[offset + 1]
                }
                let bits = UInt16(high) << 8 | UInt16(low)
                if scalarType == .int16 {
                    out.append(Double(Int16(bitPattern: bits)))
                } else {
                    out.append(Double(bits))
                }
                offset += 2
            }
        default:
            out.reserveCapacity(bytes.count / 4)
            var offset = 0
            while offset + 3 < bytes.count {
                var bits: UInt32 = 0
                if byteOrder == .bigEndian {
                    for index in 0...3 {
                        bits = bits << 8 | UInt32(bytes[offset + index])
                    }
                } else {
                    for index in stride(from: 3, through: 0, by: -1) {
                        bits = bits << 8 | UInt32(bytes[offset + index])
                    }
                }
                out.append(Double(Float32(bitPattern: bits)))
                offset += 4
            }
        }
        return out
    }

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw ArithmeticError.invalidOutputAxis
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

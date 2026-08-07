// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by range-threshold admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum ThresholdError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidThresholdRange
    case invalidPaddingValue
    case invalidOutputAxis
}

/// The range threshold operation registered by `ADR-0352` under the
/// `range-threshold/binary64-v1` model of `VOXELIA-ALG-0057` — the
/// first of the `VOX-IMG-010` processing foundations, and the record
/// of the arc's stored-value domain (`uint8`, `int16`, `uint16` and
/// `float32`, per `VOX-R2D-004`).
///
/// The frozen order per sample: the declared padding sentinel excludes
/// before any comparison, NaN is never included and always counted,
/// and the inclusive range compares exactly widened binary64 values.
/// The output is a `uint8` mask image of exact zeros and ones claiming
/// the input geometry verbatim. The operation mints no identifiers and
/// acquires no clock.
public enum ThresholdOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.threshold"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.threshold.cpu"

    /// The aggregated warning code recording non-finite input samples.
    public static let nonFiniteWarningCode = "org.voxelia.warn.threshold-non-finite"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one threshold through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``ThresholdError``, or the audited typed errors of the
    ///   storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        lowerBound: Double,
        upperBound: Double,
        paddingValue: Double?,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // The arc's stored-value domain per ADR-0352 decision 1.
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
            throw ThresholdError.unsupportedLayerFormat
        }
        guard
            lowerBound.isFinite, upperBound.isFinite, lowerBound <= upperBound
        else {
            throw ThresholdError.invalidThresholdRange
        }
        if let paddingValue, !paddingValue.isFinite {
            throw ThresholdError.invalidPaddingValue
        }

        // One budgeted coordinated full read; the retention is released
        // as soon as the owned bytes are staged.
        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // The frozen VOXELIA-ALG-0057 pass: exact widening, padding
        // first, NaN counted and excluded, inclusive range.
        let byteOrder = input.descriptor.scalarFormat.byteOrder
        var maskBytes = [UInt8]()
        var nonFiniteCount: UInt64 = 0
        func classify(_ sample: Double) {
            if let paddingValue, sample == paddingValue {
                maskBytes.append(0)
                return
            }
            if sample.isNaN {
                nonFiniteCount += 1
                maskBytes.append(0)
                return
            }
            maskBytes.append(lowerBound <= sample && sample <= upperBound ? 1 : 0)
        }
        switch scalarType {
        case .uint8:
            maskBytes.reserveCapacity(storedBytes.count)
            for byte in storedBytes {
                classify(Double(byte))
            }
        case .int16, .uint16:
            maskBytes.reserveCapacity(storedBytes.count / 2)
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
                if scalarType == .int16 {
                    classify(Double(Int16(bitPattern: bits)))
                } else {
                    classify(Double(bits))
                }
                offset += 2
            }
        case .float32:
            maskBytes.reserveCapacity(storedBytes.count / 4)
            var offset = 0
            while offset + 3 < storedBytes.count {
                var bits: UInt32 = 0
                if byteOrder == .bigEndian {
                    for index in 0...3 {
                        bits = bits << 8 | UInt32(storedBytes[offset + index])
                    }
                } else {
                    for index in stride(from: 3, through: 0, by: -1) {
                        bits = bits << 8 | UInt32(storedBytes[offset + index])
                    }
                }
                classify(Double(Float32(bitPattern: bits)))
                offset += 4
            }
        default:
            throw ThresholdError.unsupportedLayerFormat
        }

        let outputShape = try ImageShape(extents: extents)
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: .uint8,
                    componentCount: 1
                ),
                bytes: maskBytes
            )
        )
        var outputAxes = ContiguousArray<AxisDescriptor>()
        let semantics: [AxisSemantic] = [.spatialX, .spatialY, .spatialZ]
        for index in 0..<extents.count {
            outputAxes.append(
                try Self.outputAxis(
                    ["u", "v", "w"][index],
                    semantic: semantics[index]
                )
            )
        }
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: try ScalarFormat(
                type: .uint8,
                validBitCount: nil,
                byteOrder: .native
            ),
            components: input.descriptor.components,
            semantic: .mask,
            axes: outputAxes,
            spatialGeometry: input.descriptor.spatialGeometry,
            valueTransform: nil,
            units: nil
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection; the padding entry exists
        // only when the sentinel does.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(
                    lowerBound: lowerBound,
                    upperBound: upperBound,
                    paddingValue: paddingValue
                ),
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
                )
            ],
            parameterDigest: parameterDigest,
            declaresZeroInputGenerator: false
        )
        let outputIdentity = try DataIdentity(
            objectID: outputObjectID,
            contentID: try ContentID.sampleBytesIdentity(
                overCanonicalPackedBytes: maskBytes
            ),
            sourceIdentities: [],
            derivation: derivation
        )
        var warnings = ContiguousArray<ProvenanceWarning>()
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

    /// Builds the frozen parameter collection; the padding entry is
    /// present only when the sentinel is (the padding-entry precedent).
    static func parameterCollection(
        lowerBound: Double,
        upperBound: Double,
        paddingValue: Double?
    ) throws -> MetadataCollection {
        var entries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "lower-bound"
                ),
                value: .floatingPoint(try MetadataFloatingPoint(value: lowerBound)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "upper-bound"
                ),
                value: .floatingPoint(try MetadataFloatingPoint(value: upperBound)),
                privacyClass: .technical
            ),
        ]
        if let paddingValue {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "padding-value"
                    ),
                    value: .floatingPoint(try MetadataFloatingPoint(value: paddingValue)),
                    privacyClass: .technical
                )
            )
        }
        return try MetadataCollection(entries: entries)
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

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw ThresholdError.invalidOutputAxis
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

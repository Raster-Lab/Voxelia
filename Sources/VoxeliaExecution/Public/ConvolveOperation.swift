// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by convolution admission.
public enum ConvolveError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidKernel
    case invalidOutputAxis
}

/// The explicit boundary vocabulary of `VOXELIA-ALG-0059`: a closed,
/// defaultless choice, because a defaulted boundary is an implicit one
/// and `VOX-IMG-011` forbids exactly that.
public enum ConvolutionBoundary: String, Sendable, Hashable {
    /// An out-of-image tap reads the nearest edge sample per axis.
    case replicate
    /// An out-of-image tap contributes exactly zero.
    case zero
}

/// The convolution operation registered by `ADR-0354` under the
/// `convolution/binary64-v1` model of `VOXELIA-ALG-0059`.
///
/// The kernel applies in stated correlation orientation; offsets are
/// visited in ascending lexicographic order (axis zero fastest) with
/// left-associative binary64 accumulation from zero; the output
/// composes `VOXELIA-ALG-0058`'s result rule with this operation's own
/// warning codes. The operation mints no identifiers and acquires no
/// clock.
public enum ConvolveOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.convolve"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.convolve.cpu"

    /// The inclusive per-axis kernel extent ceiling.
    public static let maximumKernelExtent = 31

    /// The aggregated warning code counting integer saturations.
    public static let saturationWarningCode = "org.voxelia.warn.convolution-saturated"
    /// The aggregated warning code counting float32 non-finite results.
    public static let nonFiniteWarningCode = "org.voxelia.warn.convolution-non-finite"

    private static let parameterDocumentByteCeiling: UInt64 = 262_144

    /// Executes one convolution through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``ConvolveError``, or the audited typed errors of the
    ///   storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        kernel: [Double],
        kernelExtents: [Int],
        boundary: ConvolutionBoundary,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        let scalarType = input.descriptor.scalarFormat.type
        let extents = Array(input.descriptor.shape.extents)
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
            throw ConvolveError.unsupportedLayerFormat
        }
        guard
            kernelExtents.count == extents.count,
            kernelExtents.allSatisfy({
                $0 >= 1 && $0 <= Self.maximumKernelExtent && $0 % 2 == 1
            }),
            kernel.count == kernelExtents.reduce(1, *),
            kernel.allSatisfy(\.isFinite)
        else {
            throw ConvolveError.invalidKernel
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: ContiguousArray(extents)
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)
        let samples = ArithmeticOperation.widen(
            storedBytes,
            scalarType: scalarType,
            byteOrder: input.descriptor.scalarFormat.byteOrder
        )

        // Canonical strides for both the image and the kernel.
        let rank = extents.count
        var strides = [Int](repeating: 1, count: rank)
        for axis in 1..<rank {
            strides[axis] = strides[axis - 1] * extents[axis - 1]
        }
        let radii = kernelExtents.map { $0 / 2 }
        let sampleCount = extents.reduce(1, *)

        var outputBytes = [UInt8]()
        var saturatedCount: UInt64 = 0
        var nonFiniteCount: UInt64 = 0
        var index = [Int](repeating: 0, count: rank)
        var offset = [Int](repeating: 0, count: rank)
        for _ in 0..<sampleCount {
            // The frozen lexicographic kernel visit, axis zero fastest.
            var accumulator = 0.0
            for kernelIndex in 0..<kernel.count {
                var remainder = kernelIndex
                for axis in 0..<rank {
                    offset[axis] = remainder % kernelExtents[axis] - radii[axis]
                    remainder /= kernelExtents[axis]
                }
                var sourceLinear = 0
                var contributes = true
                for axis in 0..<rank {
                    var source = index[axis] + offset[axis]
                    if source < 0 || source >= extents[axis] {
                        switch boundary {
                        case .replicate:
                            source = min(max(source, 0), extents[axis] - 1)
                        case .zero:
                            contributes = false
                        }
                    }
                    sourceLinear += source * strides[axis]
                }
                if contributes {
                    accumulator = accumulator + kernel[kernelIndex] * samples[sourceLinear]
                }
            }
            Self.store(
                accumulator,
                scalarType: scalarType,
                into: &outputBytes,
                saturated: &saturatedCount,
                nonFinite: &nonFiniteCount
            )
            // Advance the canonical output index, axis zero fastest.
            var axis = 0
            while axis < rank {
                index[axis] += 1
                if index[axis] < extents[axis] {
                    break
                }
                index[axis] = 0
                axis += 1
            }
        }

        let outputShape = try ImageShape(extents: ContiguousArray(extents))
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
        for axis in 0..<rank {
            outputAxes.append(
                try Self.outputAxis(["u", "v", "w"][axis], semantic: semantics[axis])
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
                    name: "boundary"
                ),
                value: .string(boundary.rawValue),
                privacyClass: .technical
            )
        ]
        for (axis, extent) in kernelExtents.enumerated() {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "kernel-extent-\(axis)"
                    ),
                    value: .signedInteger(Int64(extent)),
                    privacyClass: .technical
                )
            )
        }
        for (position, weight) in kernel.enumerated() {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "kernel-\(position)"
                    ),
                    value: .floatingPoint(try MetadataFloatingPoint(value: weight)),
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
        var warnings = ContiguousArray<ProvenanceWarning>()
        if saturatedCount >= 1 {
            warnings.append(
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(rawValue: Self.saturationWarningCode),
                    schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                    severity: .qualityAffecting,
                    occurrenceCount: saturatedCount
                )
            )
        }
        if nonFiniteCount >= 1 {
            warnings.append(
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(rawValue: Self.nonFiniteWarningCode),
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

    /// Stores one binary64 result under the composed ALG-0058 rule.
    static func store(
        _ result: Double,
        scalarType: ScalarType,
        into bytes: inout [UInt8],
        saturated: inout UInt64,
        nonFinite: inout UInt64
    ) {
        switch scalarType {
        case .uint8:
            let rounded = result.rounded(.toNearestOrEven)
            if rounded < 0 {
                bytes.append(0)
                saturated += 1
            } else if rounded > 255 {
                bytes.append(255)
                saturated += 1
            } else {
                bytes.append(UInt8(rounded))
            }
        case .int16, .uint16:
            let rounded = result.rounded(.toNearestOrEven)
            let lower: Double = scalarType == .int16 ? -32768 : 0
            let upper: Double = scalarType == .int16 ? 32767 : 65535
            let stored: Int
            if rounded < lower {
                stored = Int(lower)
                saturated += 1
            } else if rounded > upper {
                stored = Int(upper)
                saturated += 1
            } else {
                stored = Int(rounded)
            }
            let bits =
                scalarType == .int16 ? UInt16(bitPattern: Int16(stored)) : UInt16(stored)
            bytes.append(UInt8(bits & 0xFF))
            bytes.append(UInt8(bits >> 8))
        default:
            let narrowed = Float32(result)
            if !narrowed.isFinite {
                nonFinite += 1
            }
            let bits = narrowed.bitPattern
            bytes.append(UInt8(bits & 0xFF))
            bytes.append(UInt8((bits >> 8) & 0xFF))
            bytes.append(UInt8((bits >> 16) & 0xFF))
            bytes.append(UInt8(bits >> 24))
        }
    }

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw ConvolveError.invalidOutputAxis
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

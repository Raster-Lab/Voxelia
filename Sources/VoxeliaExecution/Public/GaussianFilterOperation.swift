// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by Gaussian-filter admission.
public enum GaussianFilterError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidSigma
    case invalidOutputAxis
}

/// The separable Gaussian filter registered by `ADR-0355` under the
/// `gaussian/binary64-v1` model of `VOXELIA-ALG-0060`.
///
/// Sampled weights over the frozen `ceil(3 sigma)` radius, normalised
/// in left-to-right order, applied in axis-ascending separable passes
/// through the one `VOXELIA-ALG-0059` accumulation core — with the
/// intermediates carried in binary64 and the stored-type conversion
/// happening exactly once, after the final pass. The operation mints
/// no identifiers and acquires no clock.
public enum GaussianFilterOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.gaussian-filter"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.gaussian-filter.cpu"

    /// The aggregated warning code counting integer saturations —
    /// unreachable for finite inputs by the normalised kernel's
    /// convexity, kept because the shared store rule carries it.
    public static let saturationWarningCode = "org.voxelia.warn.gaussian-saturated"
    /// The aggregated warning code counting float32 non-finite results.
    public static let nonFiniteWarningCode = "org.voxelia.warn.gaussian-non-finite"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one separable Gaussian pass sequence through the
    /// budgeted coordinated read boundary.
    ///
    /// - Throws: ``GaussianFilterError``, or the audited typed errors
    ///   of the storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        sigmas: [Double],
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
            throw GaussianFilterError.unsupportedLayerFormat
        }
        guard
            sigmas.count == extents.count,
            sigmas.allSatisfy({ $0.isFinite && $0 > 0 })
        else {
            throw GaussianFilterError.invalidSigma
        }
        let radii = sigmas.map { Int((3.0 * $0).rounded(.up)) }
        guard
            radii.allSatisfy({ 2 * $0 + 1 <= ConvolveOperation.maximumKernelExtent })
        else {
            throw GaussianFilterError.invalidSigma
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: ContiguousArray(extents)
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // Axis-ascending separable passes, binary64 throughout; the
        // stored-type conversion happens exactly once at the end.
        var current = ArithmeticOperation.widen(
            storedBytes,
            scalarType: scalarType,
            byteOrder: input.descriptor.scalarFormat.byteOrder
        )
        let rank = extents.count
        for axis in 0..<rank {
            let weights = Self.normalisedWeights(sigma: sigmas[axis], radius: radii[axis])
            var kernelExtents = [Int](repeating: 1, count: rank)
            kernelExtents[axis] = weights.count
            current = ConvolveOperation.convolvedValues(
                samples: current,
                extents: extents,
                kernel: weights,
                kernelExtents: kernelExtents,
                boundary: boundary
            )
        }

        var outputBytes = [UInt8]()
        var saturatedCount: UInt64 = 0
        var nonFiniteCount: UInt64 = 0
        for value in current {
            ConvolveOperation.store(
                value,
                scalarType: scalarType,
                into: &outputBytes,
                saturated: &saturatedCount,
                nonFinite: &nonFiniteCount
            )
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
        for (axis, sigma) in sigmas.enumerated() {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "sigma-\(axis)"
                    ),
                    value: .floatingPoint(try MetadataFloatingPoint(value: sigma)),
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

    /// The frozen VOXELIA-ALG-0060 weights: sampled at integer offsets,
    /// summed left-to-right in ascending offset order, each divided by
    /// that binary64 sum.
    static func normalisedWeights(sigma: Double, radius: Int) -> [Double] {
        var raw = [Double]()
        raw.reserveCapacity(2 * radius + 1)
        for offset in -radius...radius {
            let x = Double(offset)
            raw.append(exp(-(x * x) / (2.0 * sigma * sigma)))
        }
        var total = 0.0
        for weight in raw {
            total = total + weight
        }
        return raw.map { $0 / total }
    }

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw GaussianFilterError.invalidOutputAxis
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

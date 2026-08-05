// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by bilinear-resampling admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum ResampleLinearError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case unsupportedAxisSampling
    case invalidOutputExtent
}

/// The bilinear resampling operation registered by `ADR-0123` under
/// the `bilinear-resampling/binary64-v1` model of `VOXELIA-ALG-0015`
/// — the linear interpolation display policy of `VOX-R2D-013`.
///
/// Source coordinates align pixel centres with edge replication
/// through clamped taps; the identity mapping at equal dimensions is
/// exact by construction. The operation mints no identifiers and
/// acquires no clock.
public enum ResampleLinearOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.resample-linear"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.resample-linear.cpu"

    /// The inclusive per-dimension output extent ceiling.
    public static let maximumOutputExtent = 16_384

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one resampling through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``ResampleLinearError``, or the audited typed errors
    ///   of the storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        outputWidth: Int,
        outputHeight: Int,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0123: the display-policy
        // value domain, mirroring the compositing admission.
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 2,
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity,
            input.descriptor.valueTransform == nil
        else {
            throw ResampleLinearError.unsupportedLayerFormat
        }
        // Widened by ADR-0127: regular sampling and affine geometry
        // rescale under the registered shared rules; irregular and
        // categorical payloads have no linear rescale.
        for axis in input.descriptor.axes {
            switch axis.sampling {
            case .indexOnly, .regular:
                continue
            default:
                throw ResampleLinearError.unsupportedAxisSampling
            }
        }
        guard
            outputWidth >= 1, outputWidth <= Self.maximumOutputExtent,
            outputHeight >= 1, outputHeight <= Self.maximumOutputExtent
        else {
            throw ResampleLinearError.invalidOutputExtent
        }

        // One budgeted coordinated full read; the retention is released
        // as soon as the owned bytes are staged.
        let fullRegion = try ImageRegion(
            lowerBounds: [0, 0],
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // The frozen VOXELIA-ALG-0015 interpolation.
        let inputWidth = extents[0]
        let inputHeight = extents[1]
        let columns = (0..<outputWidth).map { position in
            Self.axisTaps(position, inputCount: inputWidth, outputCount: outputWidth)
        }
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(outputWidth * outputHeight)
        for outputRow in 0..<outputHeight {
            let row = Self.axisTaps(
                outputRow,
                inputCount: inputHeight,
                outputCount: outputHeight
            )
            for column in columns {
                let v00 = Double(storedBytes[column.lower + row.lower * inputWidth])
                let v10 = Double(storedBytes[column.upper + row.lower * inputWidth])
                let v01 = Double(storedBytes[column.lower + row.upper * inputWidth])
                let v11 = Double(storedBytes[column.upper + row.upper * inputWidth])
                let vx0 = (v00 * (1.0 - column.weight)) + (v10 * column.weight)
                let vx1 = (v01 * (1.0 - column.weight)) + (v11 * column.weight)
                let value = (vx0 * (1.0 - row.weight)) + (vx1 * row.weight)
                let rounded = value.rounded(.toNearestOrEven)
                outputBytes.append(UInt8(min(255.0, max(0.0, rounded))))
            }
        }

        let outputShape = try ImageShape(extents: [outputWidth, outputHeight])
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
        // The ADR-0127 rescale through the one shared rule authority.
        let scales = [
            Double(inputWidth) / Double(outputWidth),
            Double(inputHeight) / Double(outputHeight),
        ]
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: input.descriptor.semantic,
            axes: try ResampleRescale.rescaledAxes(
                of: input.descriptor,
                scales: scales
            ),
            spatialGeometry: try ResampleRescale.rescaledGeometry(
                of: input.descriptor,
                scales: scales
            ),
            valueTransform: nil,
            units: nil
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(
                    outputWidth: outputWidth,
                    outputHeight: outputHeight
                ),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // Registered tokens, derivation recipe, content identity and
        // the subject-bound record with its parent edge, per the
        // accepted operation pattern.
        let version = try SemanticVersion(major: 1, minor: 1, patch: 0)
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

    /// The exact `VOXELIA-ALG-0015` per-axis tap computation: the
    /// weight comes from the unclamped floor so edge positions
    /// replicate the border sample.
    static func axisTaps(
        _ position: Int,
        inputCount: Int,
        outputCount: Int
    ) -> (lower: Int, upper: Int, weight: Double) {
        let scale = Double(inputCount) / Double(outputCount)
        let source = ((Double(position) + 0.5) * scale) - 0.5
        let flooredSource = floor(source)
        let weight = source - flooredSource
        let floored = Int(flooredSource)
        let lower = min(inputCount - 1, max(0, floored))
        let upper = min(inputCount - 1, max(0, floored + 1))
        return (lower, upper, weight)
    }

    /// Builds the frozen parameter collection for one output size.
    static func parameterCollection(
        outputWidth: Int,
        outputHeight: Int
    ) throws -> MetadataCollection {
        try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "output-width"
                ),
                value: .signedInteger(Int64(outputWidth)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "output-height"
                ),
                value: .signedInteger(Int64(outputHeight)),
                privacyClass: .technical
            ),
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

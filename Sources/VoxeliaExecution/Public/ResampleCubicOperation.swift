// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by cubic-resampling admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum ResampleCubicError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case unsupportedAxisSampling
    case invalidOutputExtent
}

/// The cubic resampling operation registered by `ADR-0164` under the
/// `cubic-resampling/binary64-v1` model of `VOXELIA-ALG-0021` — the
/// `VOX-IMG-005` cubic interpolation with its documented kernel and
/// boundary behaviour.
///
/// The Catmull-Rom kernel interpolates through the samples, so the
/// identity mapping at equal dimensions is exact by construction;
/// border coordinates replicate the border sample through the accepted
/// clamped-tap convention, and the output clamp is modelled because
/// the kernel's negative lobes overshoot the sample range. The
/// operation mints no identifiers and acquires no clock.
public enum ResampleCubicOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.resample-cubic"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.resample-cubic.cpu"

    /// The inclusive per-dimension output extent ceiling.
    public static let maximumOutputExtent = 16_384

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one resampling through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``ResampleCubicError``, or the audited typed errors
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
        // Version-one admission per ADR-0164: the display-policy
        // value domain, mirroring the linear operation.
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 2,
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity,
            input.descriptor.valueTransform == nil
        else {
            throw ResampleCubicError.unsupportedLayerFormat
        }
        for axis in input.descriptor.axes {
            switch axis.sampling {
            case .indexOnly, .regular:
                continue
            default:
                throw ResampleCubicError.unsupportedAxisSampling
            }
        }
        guard
            outputWidth >= 1, outputWidth <= Self.maximumOutputExtent,
            outputHeight >= 1, outputHeight <= Self.maximumOutputExtent
        else {
            throw ResampleCubicError.invalidOutputExtent
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

        // The frozen VOXELIA-ALG-0021 interpolation: separable
        // rows-inside-columns with ascending accumulation.
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
                var value = 0.0
                for vertical in 0..<4 {
                    var horizontal = 0.0
                    let rowBase = row.taps[vertical] * inputWidth
                    for tap in 0..<4 {
                        horizontal =
                            horizontal
                            + (column.weights[tap]
                                * Double(storedBytes[column.taps[tap] + rowBase]))
                    }
                    value = value + (row.weights[vertical] * horizontal)
                }
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
        // Geometry rescales through the one shared rule authority,
        // exactly as the linear operation adopted it.
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

    /// The exact `VOXELIA-ALG-0021` per-axis taps and frozen
    /// Catmull-Rom weights: four clamped taps around the accepted
    /// pixel-centre coordinate with the weight from the unclamped
    /// floor, so border coordinates replicate the border sample.
    static func axisTaps(
        _ position: Int,
        inputCount: Int,
        outputCount: Int
    ) -> (taps: [Int], weights: [Double]) {
        let scale = Double(inputCount) / Double(outputCount)
        let source = ((Double(position) + 0.5) * scale) - 0.5
        let flooredSource = floor(source)
        let t = source - flooredSource
        let floored = Int(flooredSource)
        var taps = [Int]()
        taps.reserveCapacity(4)
        for offset in -1...2 {
            taps.append(min(inputCount - 1, max(0, floored + offset)))
        }
        let t2 = t * t
        let t3 = t2 * t
        let weights = [
            ((-t3 + 2.0 * t2) - t) * 0.5,
            ((3.0 * t3 - 5.0 * t2) + 2.0) * 0.5,
            ((-3.0 * t3 + 4.0 * t2) + t) * 0.5,
            (t3 - t2) * 0.5,
        ]
        return (taps, weights)
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

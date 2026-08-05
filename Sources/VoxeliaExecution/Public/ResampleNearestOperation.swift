// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by nearest-neighbour resampling admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum ResampleError: Error, Sendable, Equatable {
    case unsupportedRank
    case unsupportedAxisSampling
    case invalidOutputExtent
}

/// The nearest-neighbour resampling operation registered by `ADR-0088`
/// under the `nearest-neighbour-resampling/binary64-v1` model of
/// `VOXELIA-ALG-0008`.
///
/// Every output pixel selects exactly one whole source sample through
/// the frozen binary64 index computation; no sample value is created,
/// altered or interpreted, so the model is value-neutral across scalar
/// formats and component counts. The operation mints no identifiers and
/// acquires no clock.
public enum ResampleNearestOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.resample-nearest"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.resample-nearest.cpu"

    /// The inclusive per-dimension output extent ceiling.
    public static let maximumOutputExtent = 16_384

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one resampling through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``ResampleError``, or the audited typed errors of the
    ///   storage, metadata, identity, provenance and aggregate
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
        // Admission per ADR-0088 widened by ADR-0126: regular
        // sampling and affine geometry rescale under the registered
        // rules; irregular and categorical payloads have no linear
        // rescale.
        let extents = input.descriptor.shape.extents
        guard extents.count == 2 else {
            throw ResampleError.unsupportedRank
        }
        for axis in input.descriptor.axes {
            switch axis.sampling {
            case .indexOnly, .regular:
                continue
            default:
                throw ResampleError.unsupportedAxisSampling
            }
        }
        guard
            outputWidth >= 1, outputWidth <= Self.maximumOutputExtent,
            outputHeight >= 1, outputHeight <= Self.maximumOutputExtent
        else {
            throw ResampleError.invalidOutputExtent
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

        // The frozen VOXELIA-ALG-0008 whole-sample selection.
        let inputWidth = extents[0]
        let inputHeight = extents[1]
        let sampleByteCount =
            input.descriptor.scalarFormat.type.byteCount
            * input.descriptor.components.count
        let columnIndices = (0..<outputWidth).map { position in
            Self.sourceIndex(position, inputCount: inputWidth, outputCount: outputWidth)
        }
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(outputWidth * outputHeight * sampleByteCount)
        for outputRow in 0..<outputHeight {
            let sourceRow = Self.sourceIndex(
                outputRow,
                inputCount: inputHeight,
                outputCount: outputHeight
            )
            let rowBase = sourceRow * inputWidth * sampleByteCount
            for sourceColumn in columnIndices {
                let base = rowBase + sourceColumn * sampleByteCount
                outputBytes.append(
                    contentsOf: storedBytes[base..<(base + sampleByteCount)]
                )
            }
        }

        let outputShape = try ImageShape(extents: [outputWidth, outputHeight])
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: input.descriptor.scalarFormat.type,
                    componentCount: input.descriptor.components.count
                ),
                bytes: outputBytes
            )
        )
        // The ADR-0126 rescale through the one shared rule authority.
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
            valueTransform: input.descriptor.valueTransform,
            units: input.descriptor.units
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

    /// The exact `VOXELIA-ALG-0008` index computation.
    static func sourceIndex(_ position: Int, inputCount: Int, outputCount: Int) -> Int {
        let scale = Double(inputCount) / Double(outputCount)
        let centre = (Double(position) + 0.5) * scale
        return min(inputCount - 1, max(0, Int(centre.rounded(.down))))
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

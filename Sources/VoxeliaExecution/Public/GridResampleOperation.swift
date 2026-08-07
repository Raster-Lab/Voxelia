// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by grid-resample admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum GridResampleError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case volumeNotSpatiallyCalibrated
    case unsupportedVolumeMapping
    case unsupportedRequestMapping
    case coordinateSpaceMismatch
    case invalidOutputExtent
    case outputBudgetExceeded
    case invalidOutputAxis
}

/// The grid resampling operation registered by `ADR-0340` under the
/// `grid-resample/binary64-v1` model of `VOXELIA-ALG-0055` — the
/// explicit source-to-target-grid resampling of `VOX-IMG-008`.
///
/// The request is the output's own rank-three affine geometry and the
/// output claims it verbatim; sampling composes only accepted
/// authorities — the frozen target forward evaluation, the `ADR-0138`
/// world-to-index composition and the `VOXELIA-ALG-0017` sampling
/// authority with its exact zero padding. Padded samples are counted
/// and recorded as an aggregated provenance warning per `ADR-0338`
/// decision 7. The operation mints no identifiers and acquires no
/// clock.
public enum GridResampleOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.grid-resample"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.grid-resample.cpu"

    /// The inclusive per-dimension output extent ceiling.
    public static let maximumOutputExtent = 16_384
    /// The inclusive total output sample ceiling, exactly `1024^3`.
    public static let maximumOutputSampleCount = 1_073_741_824

    /// The aggregated warning code recording padded samples.
    public static let paddingWarningCode = "org.voxelia.warn.grid-resample-padding"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one grid resampling through the budgeted coordinated
    /// read boundary.
    ///
    /// - Throws: ``GridResampleError``, or the audited typed errors of
    ///   the spatial, storage, metadata, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        input: ImageData,
        request: AffineGridGeometry,
        outputExtents: [Int],
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0340: the sampler's value
        // domain over a calibrated rank-three volume, mirrored from the
        // oblique admission it composes.
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 3,
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity,
            input.descriptor.valueTransform == nil
        else {
            throw GridResampleError.unsupportedLayerFormat
        }
        guard case .affine(let volumeGeometry)? = input.descriptor.spatialGeometry
        else {
            throw GridResampleError.volumeNotSpatiallyCalibrated
        }
        guard Set(volumeGeometry.spatialAxes.imageAxes) == Set([0, 1, 2]) else {
            throw GridResampleError.unsupportedVolumeMapping
        }
        guard request.spatialAxes.imageAxes == [0, 1, 2] else {
            throw GridResampleError.unsupportedRequestMapping
        }
        guard request.coordinateSpace.id == volumeGeometry.coordinateSpace.id
        else {
            throw GridResampleError.coordinateSpaceMismatch
        }
        guard outputExtents.count == 3 else {
            throw GridResampleError.invalidOutputExtent
        }
        for extent in outputExtents {
            guard extent >= 1, extent <= Self.maximumOutputExtent else {
                throw GridResampleError.invalidOutputExtent
            }
        }
        let sampleCount = outputExtents[0] * outputExtents[1] * outputExtents[2]
        guard sampleCount <= Self.maximumOutputSampleCount else {
            throw GridResampleError.outputBudgetExceeded
        }

        // One budgeted coordinated full read; the retention is released
        // as soon as the owned bytes are staged.
        let fullRegion = try ImageRegion(
            lowerBounds: [0, 0, 0],
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // The frozen VOXELIA-ALG-0055 chain: the target forward
        // evaluation in the sampler's request order extended by the
        // third slot term, the accepted inverse composition, then the
        // one sampling authority with its exact zero padding.
        let map = try AffineWorldToIndexMap(geometry: volumeGeometry)
        let requestElements = request.indexToWorld.elements
        let requestSpace = request.coordinateSpace.id
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(sampleCount)
        var paddedSampleCount: UInt64 = 0
        for outputPlane in 0..<outputExtents[2] {
            for outputRow in 0..<outputExtents[1] {
                for outputColumn in 0..<outputExtents[0] {
                    let j0 = Double(outputColumn)
                    let j1 = Double(outputRow)
                    let j2 = Double(outputPlane)
                    var world = [0.0, 0.0, 0.0]
                    for r in 0...2 {
                        world[r] =
                            ((requestElements[4 * r + 3]
                                + (requestElements[4 * r] * j0))
                                + (requestElements[4 * r + 1] * j1))
                            + (requestElements[4 * r + 2] * j2)
                    }
                    let slots = try map.continuousSlotIndices(
                        of: try Point3D(
                            x: world[0],
                            y: world[1],
                            z: world[2],
                            coordinateSpace: requestSpace
                        )
                    )
                    var continuous = [0.0, 0.0, 0.0]
                    for (slot, axis) in map.spatialAxes.imageAxes.enumerated() {
                        continuous[axis] = slots[slot]
                    }
                    if !ObliqueSliceOperation.supports(continuous, extents: extents) {
                        paddedSampleCount += 1
                    }
                    outputBytes.append(
                        ObliqueSliceOperation.sample(
                            continuous,
                            extents: extents,
                            bytes: storedBytes
                        )
                    )
                }
            }
        }

        let outputShape = try ImageShape(extents: ContiguousArray(outputExtents))
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
        // Fresh index-only axes: the verbatim request claim is the one
        // calibration authority for the resampled grid.
        let outputDescriptor = try ImageDescriptor(
            shape: outputShape,
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: input.descriptor.semantic,
            axes: [
                try Self.outputAxis("u", semantic: .spatialX),
                try Self.outputAxis("v", semantic: .spatialY),
                try Self.outputAxis("w", semantic: .spatialZ),
            ],
            spatialGeometry: .affine(request),
            valueTransform: nil,
            units: nil
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(
                    request: request,
                    outputExtents: outputExtents
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
        // The ADR-0338 d7 padding record: an aggregated warning claim,
        // present exactly when padding occurred.
        var warnings = ContiguousArray<ProvenanceWarning>()
        if paddedSampleCount >= 1 {
            warnings.append(
                try ProvenanceWarning(
                    code: try ProvenanceWarningCode(
                        rawValue: Self.paddingWarningCode
                    ),
                    schemaVersion: ProvenanceWarningSchemaVersion(major: 1, minor: 0),
                    severity: .qualityAffecting,
                    occurrenceCount: paddedSampleCount
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

    /// Builds the frozen parameter collection: the full request matrix,
    /// its coordinate space and the three output extents — the complete
    /// reproduction recipe.
    static func parameterCollection(
        request: AffineGridGeometry,
        outputExtents: [Int]
    ) throws -> MetadataCollection {
        var entries = [MetadataEntry]()
        for (index, element) in request.indexToWorld.elements.enumerated() {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "matrix-\(index)"
                    ),
                    value: .floatingPoint(try MetadataFloatingPoint(value: element)),
                    privacyClass: .technical
                )
            )
        }
        entries.append(
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "coordinate-space"
                ),
                value: .string(request.coordinateSpace.id.rawValue),
                privacyClass: .technical
            )
        )
        for (index, extent) in outputExtents.enumerated() {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "output-extent-\(index)"
                    ),
                    value: .signedInteger(Int64(extent)),
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
            throw GridResampleError.invalidOutputAxis
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

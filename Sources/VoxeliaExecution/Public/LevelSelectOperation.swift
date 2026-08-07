// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by level-select admission.
///
/// Cases deliberately carry no payload; every other failure surfaces as
/// the audited typed error of the underlying accepted contract.
public enum LevelSelectError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case volumeNotSpatiallyCalibrated
    case unsupportedVolumeMapping
    case invalidDownsamplingLevel
    case invalidOutputAxis
}

/// The level selection downsampling operation registered by `ADR-0343`
/// under the `level-select/binary64-v1` model of `VOXELIA-ALG-0056` —
/// the lower-resolution level generator the progressive-refinement arc
/// builds on.
///
/// Level sample `(j0, j1, j2)` selects the level-zero stored value at
/// `(j0*f0, j1*f1, j2*f2)` — every level sample is a verbatim acquired
/// sample, never an average — and the output claims the geometry with
/// its index-step columns scaled by the factors, so a level sample's
/// centre is its selected sample's centre. The operation mints no
/// identifiers and acquires no clock.
public enum LevelSelectOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.level-select"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.level-select.cpu"

    /// The inclusive per-axis downsampling factor ceiling.
    public static let maximumDownsamplingFactor = 16_384

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one level selection through the budgeted coordinated
    /// read boundary.
    ///
    /// - Throws: ``LevelSelectError``, or the audited typed errors of
    ///   the spatial, storage, metadata, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        input: ImageData,
        level: BrickResolutionLevel,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Version-one admission per ADR-0343: the sampler's value
        // domain over a calibrated rank-three volume, and a level that
        // is genuinely below full resolution.
        let extents = input.descriptor.shape.extents
        guard
            extents.count == 3,
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity,
            input.descriptor.valueTransform == nil
        else {
            throw LevelSelectError.unsupportedLayerFormat
        }
        guard case .affine(let volumeGeometry)? = input.descriptor.spatialGeometry
        else {
            throw LevelSelectError.volumeNotSpatiallyCalibrated
        }
        guard Set(volumeGeometry.spatialAxes.imageAxes) == Set([0, 1, 2]) else {
            throw LevelSelectError.unsupportedVolumeMapping
        }
        guard
            level.index >= 1,
            level.downsamplingFactors.count == 3,
            level.downsamplingFactors.allSatisfy({
                $0 >= 1 && $0 <= Self.maximumDownsamplingFactor
            })
        else {
            throw LevelSelectError.invalidDownsamplingLevel
        }
        let factors = Array(level.downsamplingFactors)

        // One budgeted coordinated full read; the retention is released
        // as soon as the owned bytes are staged.
        let fullRegion = try ImageRegion(
            lowerBounds: [0, 0, 0],
            upperBounds: extents
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)

        // The frozen VOXELIA-ALG-0056 selection: ceil(e/f) extents and
        // the verbatim sample at (j0*f0, j1*f1, j2*f2), canonical
        // lower-axis-fastest order.
        let levelExtents = (0...2).map { axis in
            (extents[axis] + factors[axis] - 1) / factors[axis]
        }
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(levelExtents[0] * levelExtents[1] * levelExtents[2])
        for j2 in 0..<levelExtents[2] {
            let i2 = j2 * factors[2]
            for j1 in 0..<levelExtents[1] {
                let i1 = j1 * factors[1]
                let rowBase = extents[0] * (i1 + extents[1] * i2)
                for j0 in 0..<levelExtents[0] {
                    outputBytes.append(storedBytes[j0 * factors[0] + rowBase])
                }
            }
        }

        // The frozen VOXELIA-ALG-0056 geometry scaling: index-step
        // columns times the factors, translation and bottom row
        // verbatim, revalidated by the geometry admission.
        var scaledElements = Array(volumeGeometry.indexToWorld.elements)
        for r in 0...2 {
            for c in 0...2 {
                scaledElements[4 * r + c] =
                    volumeGeometry.indexToWorld.elements[4 * r + c] * Double(factors[c])
            }
        }
        let levelGeometry = try AffineGridGeometry(
            spatialAxes: volumeGeometry.spatialAxes,
            indexToWorld: try Matrix4x4Double(elements: scaledElements),
            coordinateSpace: volumeGeometry.coordinateSpace
        )

        let outputShape = try ImageShape(extents: ContiguousArray(levelExtents))
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
            spatialGeometry: .affine(levelGeometry),
            valueTransform: nil,
            units: nil
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(level: level),
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

    /// Builds the frozen parameter collection: the level index and the
    /// three factors — the complete reproduction recipe.
    static func parameterCollection(
        level: BrickResolutionLevel
    ) throws -> MetadataCollection {
        var entries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "level-index"
                ),
                value: .signedInteger(Int64(level.index)),
                privacyClass: .technical
            )
        ]
        for (axis, factor) in level.downsamplingFactors.enumerated() {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "factor-\(axis)"
                    ),
                    value: .signedInteger(Int64(factor)),
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
            throw LevelSelectError.invalidOutputAxis
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

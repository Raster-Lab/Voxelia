// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by region-extraction admission.
///
/// The single case deliberately carries no payload; every other failure
/// surfaces as the audited typed error of the underlying accepted
/// contract.
public enum RegionExtractionError: Error, Sendable, Equatable {
    case unsupportedAxisSampling
}

/// The exact region extraction operation registered by `ADR-0064` —
/// the first executable operation.
///
/// The semantic is a byte-exact copy of one full-rank half-open region
/// of the input's canonical packed decoded bytes: no sample value is
/// created, altered, rounded or interpreted. Version one admits only
/// geometry-free descriptors with index-only axis sampling, because
/// cropping under affine geometry or regular sampling shifts origins,
/// which is arithmetic deferred to its own decision. The operation
/// mints no identifiers and acquires no clock: the caller supplies the
/// output object identifier, provenance identifier, instant and
/// software identity, and receives a fully validated `ImageData` whose
/// provenance carries a graph-node parent edge to the input's own
/// record.
public enum RegionExtractionOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.extract-region"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.extract-region.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one byte-exact region extraction through the budgeted
    /// coordinated read boundary.
    ///
    /// - Throws: ``RegionExtractionError`` for version-one admission,
    ///   or the audited typed errors of the storage, metadata,
    ///   identity, provenance and aggregate contracts.
    public static func execute(
        input: ImageData,
        region: ImageRegion,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        // Admission per ADR-0064 lifted by ADR-0071: index-only and
        // regular sampling; slicing other sampling payloads is a
        // different model.
        for axis in input.descriptor.axes {
            switch axis.sampling {
            case .indexOnly, .regular:
                continue
            case .irregular, .categorical, .externallyDefined:
                throw RegionExtractionError.unsupportedAxisSampling
            }
        }

        // One budgeted, coalescing coordinated read; the retention is
        // released as soon as the owned bytes are staged.
        let read = try await coordinator.read(from: input.storage, region: region)
        let bytes = read.result.bytes
        let outputBinding = read.result.binding
        try await coordinator.release(read.retention)
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(binding: outputBinding, bytes: bytes)
        )

        // The output descriptor keeps every per-sample property with
        // the region's shape; regular origins and the affine
        // translation shift per the registered VOXELIA-ALG-0006 model
        // so every extracted sample keeps its source position.
        var extents = [Int]()
        extents.reserveCapacity(region.rank)
        for axis in 0..<region.rank {
            extents.append(region.upperBounds[axis] - region.lowerBounds[axis])
        }
        var outputAxes = ContiguousArray<AxisDescriptor>()
        outputAxes.reserveCapacity(input.descriptor.axes.count)
        for (axisIndex, axis) in input.descriptor.axes.enumerated() {
            if case .regular(let origin, let spacing) = axis.sampling {
                let shiftedOrigin =
                    origin + (Double(region.lowerBounds[axisIndex]) * spacing)
                outputAxes.append(
                    try AxisDescriptor(
                        id: axis.id,
                        name: axis.name,
                        semantic: axis.semantic,
                        unit: axis.unit,
                        sampling: .regular(origin: shiftedOrigin, spacing: spacing)
                    )
                )
            } else {
                outputAxes.append(axis)
            }
        }
        var outputGeometry: SpatialGeometry?
        if case .affine(let affine) = input.descriptor.spatialGeometry {
            var elements = Array(affine.indexToWorld.elements)
            for row in 0...2 {
                var translation = elements[4 * row + 3]
                for (slot, imageAxis) in affine.spatialAxes.imageAxes.enumerated() {
                    translation =
                        translation
                        + (elements[4 * row + slot]
                            * Double(region.lowerBounds[imageAxis]))
                }
                elements[4 * row + 3] = translation
            }
            outputGeometry = .affine(
                try AffineGridGeometry(
                    spatialAxes: affine.spatialAxes,
                    indexToWorld: try Matrix4x4Double(elements: elements),
                    coordinateSpace: affine.coordinateSpace
                )
            )
        }
        let outputDescriptor = try ImageDescriptor(
            shape: try ImageShape(extents: extents),
            scalarFormat: input.descriptor.scalarFormat,
            components: input.descriptor.components,
            semantic: input.descriptor.semantic,
            axes: outputAxes,
            spatialGeometry: outputGeometry,
            valueTransform: input.descriptor.valueTransform,
            units: input.descriptor.units
        )

        // The frozen parameter schema digested under the registered
        // operation-parameters projection.
        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try parameterCollection(for: region),
                maximumOutputByteCount: Self.parameterDocumentByteCeiling
            )
        )

        // Registered tokens (advanced to 1.1.0 by ADR-0071), derivation
        // recipe and content identity.
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
                overCanonicalPackedBytes: bytes
            ),
            sourceIdentities: [],
            derivation: derivation
        )

        // The transformed-kind record binds the output subject, the
        // input edge and the parent edge to the input's own record.
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

    /// Builds the frozen parameter collection for one region.
    static func parameterCollection(
        for region: ImageRegion
    ) throws -> MetadataCollection {
        func bounds(_ values: ContiguousArray<Int>) throws -> MetadataValue {
            .array(
                try MetadataArray(
                    values: values.map { .signedInteger(Int64($0)) }
                )
            )
        }
        return try MetadataCollection(entries: [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "lower-bounds"
                ),
                value: try bounds(region.lowerBounds),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "upper-bounds"
                ),
                value: try bounds(region.upperBounds),
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
                rawValue: "org.voxelia.precision.exact"
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

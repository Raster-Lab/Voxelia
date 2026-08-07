// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by binary-morphology admission.
public enum MorphologyError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidMaskValue
    case invalidStructuringElement
    case invalidOutputAxis
}

/// The morphology operator vocabulary of `VOXELIA-ALG-0061`.
public enum MorphologyOperator: String, Sendable, Hashable {
    case erode
    case dilate
}

/// The binary morphology operation registered by `ADR-0356` under the
/// `binary-morphology/exact-v1` model of `VOXELIA-ALG-0061`.
///
/// Dilation is ANY and erosion is ALL over the structuring element's
/// covered taps, with the explicit defaultless boundary deciding what
/// an out-of-image tap contributes: under `zero`, border-touching
/// foreground erodes; under `replicate`, the border extends. The
/// operation mints no identifiers and acquires no clock.
public enum MorphologyOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.morphology"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.morphology.cpu"

    /// The inclusive per-axis structuring-element extent ceiling.
    public static let maximumElementExtent = 31

    private static let parameterDocumentByteCeiling: UInt64 = 262_144

    /// Executes one morphology pass through the budgeted coordinated
    /// read boundary.
    ///
    /// - Throws: ``MorphologyError``, or the audited typed errors of
    ///   the storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        element: [UInt8],
        elementExtents: [Int],
        operator morphologyOperator: MorphologyOperator,
        boundary: ConvolutionBoundary,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        let extents = Array(input.descriptor.shape.extents)
        guard
            (2...3).contains(extents.count),
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.semantic == .mask,
            input.descriptor.valueTransform == nil
        else {
            throw MorphologyError.unsupportedLayerFormat
        }
        guard
            elementExtents.count == extents.count,
            elementExtents.allSatisfy({
                $0 >= 1 && $0 <= Self.maximumElementExtent && $0 % 2 == 1
            }),
            element.count == elementExtents.reduce(1, *),
            element.allSatisfy({ $0 == 0 || $0 == 1 }),
            element.contains(1)
        else {
            throw MorphologyError.invalidStructuringElement
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: extents.count),
            upperBounds: ContiguousArray(extents)
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let maskBytes = read.result.bytes
        try await coordinator.release(read.retention)
        guard maskBytes.allSatisfy({ $0 == 0 || $0 == 1 }) else {
            throw MorphologyError.invalidMaskValue
        }

        // The frozen ALG-0061 pass: lexicographic element visits, axis
        // zero fastest; ANY for dilation, ALL for erosion.
        let rank = extents.count
        var strides = [Int](repeating: 1, count: rank)
        for axis in 1..<rank {
            strides[axis] = strides[axis - 1] * extents[axis - 1]
        }
        let radii = elementExtents.map { $0 / 2 }
        let sampleCount = extents.reduce(1, *)
        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(sampleCount)
        var index = [Int](repeating: 0, count: rank)
        var offset = [Int](repeating: 0, count: rank)
        for _ in 0..<sampleCount {
            var anyHit = false
            var allHit = true
            for elementIndex in 0..<element.count where element[elementIndex] == 1 {
                var remainder = elementIndex
                for axis in 0..<rank {
                    offset[axis] = remainder % elementExtents[axis] - radii[axis]
                    remainder /= elementExtents[axis]
                }
                var sample: UInt8? = nil
                var linear = 0
                for axis in 0..<rank {
                    var source = index[axis] + offset[axis]
                    if source < 0 || source >= extents[axis] {
                        switch boundary {
                        case .replicate:
                            source = min(max(source, 0), extents[axis] - 1)
                        case .zero:
                            sample = 0
                            source = min(max(source, 0), extents[axis] - 1)
                        }
                    }
                    linear += source * strides[axis]
                }
                let value = sample ?? maskBytes[linear]
                if value == 1 {
                    anyHit = true
                } else {
                    allHit = false
                }
            }
            outputBytes.append(
                morphologyOperator == .dilate ? (anyHit ? 1 : 0) : (allHit ? 1 : 0)
            )
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
                    scalarType: .uint8,
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
            semantic: .mask,
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
                value: .string(morphologyOperator.rawValue),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "boundary"
                ),
                value: .string(boundary.rawValue),
                privacyClass: .technical
            ),
        ]
        for (axis, extent) in elementExtents.enumerated() {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "element-extent-\(axis)"
                    ),
                    value: .signedInteger(Int64(extent)),
                    privacyClass: .technical
                )
            )
        }
        for (position, bit) in element.enumerated() {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "element-\(position)"
                    ),
                    value: .signedInteger(Int64(bit)),
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

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw MorphologyError.invalidOutputAxis
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

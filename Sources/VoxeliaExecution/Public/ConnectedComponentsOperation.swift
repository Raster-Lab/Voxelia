// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by connected-component admission or the label
/// ceiling.
public enum ConnectedComponentsError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidMaskValue
    case invalidConnectivity
    case componentCountExceeded
    case invalidOutputAxis
}

/// The closed connectivity vocabulary of `VOXELIA-ALG-0062`, named by
/// the shared adjacency dimension.
public enum ComponentConnectivity: String, Sendable, Hashable {
    /// Manhattan distance one: four neighbours in two dimensions, six
    /// in three.
    case faces
    /// Manhattan distance up to two: eighteen in three dimensions;
    /// rejected in two, where no edge adjacency distinct from vertices
    /// exists.
    case facesAndEdges
    /// Every non-zero offset: eight in two dimensions, twenty-six in
    /// three.
    case facesEdgesAndVertices
}

/// The connected-components operation registered by `ADR-0357` under
/// the `connected-components/exact-v1` model of `VOXELIA-ALG-0062`.
///
/// The canonical scan founds components in first-encounter order with
/// labels from one; background stays exactly zero; the label space is
/// sixteen bits with a typed ceiling. The operation mints no
/// identifiers and acquires no clock.
public enum ConnectedComponentsOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.connected-components"
    /// The registered implementation token spelling.
    public static let implementationIdentifier =
        "org.voxelia.impl.connected-components.cpu"

    /// The inclusive component-count ceiling: the sixteen-bit label
    /// space less the zero background.
    public static let maximumComponentCount = 65_535

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one labelling through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``ConnectedComponentsError``, or the audited typed
    ///   errors of the storage, metadata, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        input: ImageData,
        connectivity: ComponentConnectivity,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        let extents = Array(input.descriptor.shape.extents)
        let rank = extents.count
        guard
            (2...3).contains(rank),
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.semantic == .mask,
            input.descriptor.valueTransform == nil
        else {
            throw ConnectedComponentsError.unsupportedLayerFormat
        }
        guard !(rank == 2 && connectivity == .facesAndEdges) else {
            throw ConnectedComponentsError.invalidConnectivity
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: rank),
            upperBounds: ContiguousArray(extents)
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let maskBytes = read.result.bytes
        try await coordinator.release(read.retention)
        guard maskBytes.allSatisfy({ $0 == 0 || $0 == 1 }) else {
            throw ConnectedComponentsError.invalidMaskValue
        }

        // The neighbourhood offsets for the chosen connectivity, in a
        // fixed enumeration order (not output-observable: only the
        // scan's first-encounter order names labels).
        var offsets = [[Int]]()
        func buildOffsets(_ prefix: [Int]) {
            if prefix.count == rank {
                let manhattan = prefix.reduce(0) { $0 + abs($1) }
                guard manhattan > 0 else { return }
                switch connectivity {
                case .faces:
                    if manhattan == 1 { offsets.append(prefix) }
                case .facesAndEdges:
                    if manhattan <= 2 { offsets.append(prefix) }
                case .facesEdgesAndVertices:
                    offsets.append(prefix)
                }
                return
            }
            for delta in [-1, 0, 1] {
                buildOffsets(prefix + [delta])
            }
        }
        buildOffsets([])

        var strides = [Int](repeating: 1, count: rank)
        for axis in 1..<rank {
            strides[axis] = strides[axis - 1] * extents[axis - 1]
        }
        let sampleCount = extents.reduce(1, *)
        var labels = [UInt16](repeating: 0, count: sampleCount)
        var nextLabel = 1
        var queue = [Int]()
        for start in 0..<sampleCount where maskBytes[start] == 1 && labels[start] == 0 {
            guard nextLabel <= Self.maximumComponentCount else {
                throw ConnectedComponentsError.componentCountExceeded
            }
            let label = UInt16(nextLabel)
            labels[start] = label
            queue.removeAll(keepingCapacity: true)
            queue.append(start)
            var head = 0
            while head < queue.count {
                let current = queue[head]
                head += 1
                var coordinates = [Int](repeating: 0, count: rank)
                var remainder = current
                for axis in 0..<rank {
                    coordinates[axis] = remainder % extents[axis]
                    remainder /= extents[axis]
                }
                for offset in offsets {
                    var linear = 0
                    var inside = true
                    for axis in 0..<rank {
                        let c = coordinates[axis] + offset[axis]
                        if c < 0 || c >= extents[axis] {
                            inside = false
                            break
                        }
                        linear += c * strides[axis]
                    }
                    if inside, maskBytes[linear] == 1, labels[linear] == 0 {
                        labels[linear] = label
                        queue.append(linear)
                    }
                }
            }
            nextLabel += 1
        }

        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(sampleCount * 2)
        for label in labels {
            outputBytes.append(UInt8(label & 0xFF))
            outputBytes.append(UInt8(label >> 8))
        }

        let outputShape = try ImageShape(extents: ContiguousArray(extents))
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: .uint16,
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
            scalarFormat: try ScalarFormat(
                type: .uint16,
                validBitCount: nil,
                byteOrder: .native
            ),
            components: input.descriptor.components,
            semantic: .label,
            axes: outputAxes,
            spatialGeometry: input.descriptor.spatialGeometry,
            valueTransform: nil,
            units: nil
        )

        let parameterDigest = try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: [
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "connectivity"
                        ),
                        value: .string(connectivity.rawValue),
                        privacyClass: .technical
                    )
                ]),
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
            throw ConnectedComponentsError.invalidOutputAxis
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

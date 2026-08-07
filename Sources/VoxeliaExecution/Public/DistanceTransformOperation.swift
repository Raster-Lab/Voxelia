// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by distance-transform admission.
public enum DistanceTransformError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidMaskValue
    case noBackground
    case invalidOutputAxis
}

/// The squared Euclidean distance transform registered by `ADR-0358`
/// under the `squared-euclidean-distance/exact-v1` model of
/// `VOXELIA-ALG-0063`.
///
/// Background publishes exactly zero; every foreground sample publishes
/// its exact integer squared distance to the nearest background sample,
/// via the separable lower-envelope method with the frozen far-parabola
/// sentinel. The square root is the consumer's presentation step. The
/// operation mints no identifiers and acquires no clock.
public enum DistanceTransformOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.distance-transform"
    /// The registered implementation token spelling.
    public static let implementationIdentifier =
        "org.voxelia.impl.distance-transform.cpu"

    /// The inclusive per-axis extent ceiling, keeping every squared
    /// distance far inside `uint32`.
    public static let maximumExtent = 16_384

    /// The frozen far-parabola sentinel: above any admissible squared
    /// distance, far below `2^53`.
    static let farParabola = 1e15

    private static let parameterDocumentByteCeiling: UInt64 = 65_536

    /// Executes one transform through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``DistanceTransformError``, or the audited typed
    ///   errors of the storage, metadata, identity, provenance and
    ///   aggregate contracts.
    public static func execute(
        input: ImageData,
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
            extents.allSatisfy({ $0 <= Self.maximumExtent }),
            input.descriptor.scalarFormat.type == .uint8,
            input.descriptor.components.count == 1,
            input.descriptor.semantic == .mask,
            input.descriptor.valueTransform == nil
        else {
            throw DistanceTransformError.unsupportedLayerFormat
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: rank),
            upperBounds: ContiguousArray(extents)
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let maskBytes = read.result.bytes
        try await coordinator.release(read.retention)
        guard maskBytes.allSatisfy({ $0 == 0 || $0 == 1 }) else {
            throw DistanceTransformError.invalidMaskValue
        }
        guard maskBytes.contains(0) else {
            throw DistanceTransformError.noBackground
        }

        // Initialise: zero at background, the far parabola at
        // foreground; then the frozen axis-ascending separable passes.
        var field = maskBytes.map { $0 == 0 ? 0.0 : Self.farParabola }
        var strides = [Int](repeating: 1, count: rank)
        for axis in 1..<rank {
            strides[axis] = strides[axis - 1] * extents[axis - 1]
        }
        let sampleCount = extents.reduce(1, *)
        for axis in 0..<rank {
            let length = extents[axis]
            guard length > 1 else { continue }
            let stride = strides[axis]
            var line = [Double](repeating: 0, count: length)
            var transformed = [Double](repeating: 0, count: length)
            // Enumerate every line along this axis: iterate all samples
            // whose coordinate on `axis` is zero.
            var index = [Int](repeating: 0, count: rank)
            for linear in 0..<sampleCount {
                var remainder = linear
                for a in 0..<rank {
                    index[a] = remainder % extents[a]
                    remainder /= extents[a]
                }
                guard index[axis] == 0 else { continue }
                for position in 0..<length {
                    line[position] = field[linear + position * stride]
                }
                Self.lowerEnvelope(line, into: &transformed)
                for position in 0..<length {
                    field[linear + position * stride] = transformed[position]
                }
            }
        }

        var outputBytes = [UInt8]()
        outputBytes.reserveCapacity(sampleCount * 4)
        for value in field {
            let squared = UInt32(value)
            outputBytes.append(UInt8(squared & 0xFF))
            outputBytes.append(UInt8((squared >> 8) & 0xFF))
            outputBytes.append(UInt8((squared >> 16) & 0xFF))
            outputBytes.append(UInt8(squared >> 24))
        }

        let outputShape = try ImageShape(extents: ContiguousArray(extents))
        let outputStorage = AnyImageStorage(
            erasing: try ContiguousImageStorage(
                binding: try LogicalSampleBinding(
                    shape: outputShape,
                    scalarType: .uint32,
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
                type: .uint32,
                validBitCount: nil,
                byteOrder: .native
            ),
            components: input.descriptor.components,
            semantic: .parametric,
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
                            name: "metric"
                        ),
                        value: .string("squared-euclidean-sample-units"),
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

    /// The one-dimensional lower envelope of parabolas — the
    /// Felzenszwalb-Huttenlocher pass over one line.
    static func lowerEnvelope(_ f: [Double], into output: inout [Double]) {
        let n = f.count
        var v = [Int](repeating: 0, count: n)
        var z = [Double](repeating: 0, count: n + 1)
        var k = 0
        v[0] = 0
        z[0] = -Double.infinity
        z[1] = Double.infinity
        for q in 1..<n {
            let fq = f[q] + Double(q * q)
            var s = (fq - (f[v[k]] + Double(v[k] * v[k]))) / Double(2 * q - 2 * v[k])
            while s <= z[k] {
                k -= 1
                s = (fq - (f[v[k]] + Double(v[k] * v[k]))) / Double(2 * q - 2 * v[k])
            }
            k += 1
            v[k] = q
            z[k] = s
            z[k + 1] = Double.infinity
        }
        k = 0
        for q in 0..<n {
            while z[k + 1] < Double(q) {
                k += 1
            }
            let d = Double(q - v[k])
            output[q] = d * d + f[v[k]]
        }
    }

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw DistanceTransformError.invalidOutputAxis
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

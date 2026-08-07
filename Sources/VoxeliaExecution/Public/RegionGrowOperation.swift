// SPDX-License-Identifier: MIT

import Foundation
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

/// An error raised by region-grow admission.
public enum RegionGrowError: Error, Sendable, Equatable {
    case unsupportedLayerFormat
    case invalidThresholdRange
    case invalidPaddingValue
    case invalidSeed
    case invalidConnectivity
    case invalidOutputAxis
}

/// The region growing operation registered by `ADR-0361` under the
/// `region-grow/exact-v1` model of `VOXELIA-ALG-0065`.
///
/// A sample is included exactly when it is in the inclusive threshold
/// range — padding excluded first, NaN never in range — and connected
/// to an in-range seed through in-range samples under the chosen
/// connectivity. An out-of-range seed founds nothing, deliberately not
/// an error. The parameter document records every seed, both bounds,
/// the sentinel when declared and the connectivity — the recording the
/// row demands. The operation mints no identifiers and acquires no
/// clock.
public enum RegionGrowOperation {
    /// The registered operation token spelling.
    public static let operationIdentifier = "org.voxelia.op.region-grow"
    /// The registered implementation token spelling.
    public static let implementationIdentifier = "org.voxelia.impl.region-grow.cpu"

    private static let parameterDocumentByteCeiling: UInt64 = 262_144

    /// Executes one growth through the budgeted coordinated read
    /// boundary.
    ///
    /// - Throws: ``RegionGrowError``, or the audited typed errors of
    ///   the storage, metadata, identity, provenance and aggregate
    ///   contracts.
    public static func execute(
        input: ImageData,
        seeds: [[Int]],
        lowerBound: Double,
        upperBound: Double,
        paddingValue: Double?,
        connectivity: ComponentConnectivity,
        outputObjectID: DataObjectID,
        outputProvenanceID: ProvenanceID,
        createdAt: CanonicalInstant,
        software: SoftwareIdentity,
        coordinator: StorageReadCoordinator
    ) async throws -> ImageData {
        let scalarType = input.descriptor.scalarFormat.type
        let extents = Array(input.descriptor.shape.extents)
        let rank = extents.count
        guard
            (2...3).contains(rank),
            scalarType == .uint8 || scalarType == .int16
                || scalarType == .uint16 || scalarType == .float32,
            input.descriptor.components.count == 1,
            input.descriptor.components.interpretation == .scalar,
            input.descriptor.semantic == .intensity
                || input.descriptor.semantic == .parametric,
            input.descriptor.valueTransform == nil
        else {
            throw RegionGrowError.unsupportedLayerFormat
        }
        guard
            lowerBound.isFinite, upperBound.isFinite, lowerBound <= upperBound
        else {
            throw RegionGrowError.invalidThresholdRange
        }
        if let paddingValue, !paddingValue.isFinite {
            throw RegionGrowError.invalidPaddingValue
        }
        guard !seeds.isEmpty else {
            throw RegionGrowError.invalidSeed
        }
        for seed in seeds {
            guard seed.count == rank else {
                throw RegionGrowError.invalidSeed
            }
            for axis in 0..<rank {
                guard seed[axis] >= 0, seed[axis] < extents[axis] else {
                    throw RegionGrowError.invalidSeed
                }
            }
        }
        guard !(rank == 2 && connectivity == .facesAndEdges) else {
            throw RegionGrowError.invalidConnectivity
        }

        let fullRegion = try ImageRegion(
            lowerBounds: [Int](repeating: 0, count: rank),
            upperBounds: ContiguousArray(extents)
        )
        let read = try await coordinator.read(from: input.storage, region: fullRegion)
        let storedBytes = read.result.bytes
        try await coordinator.release(read.retention)
        let samples = ArithmeticOperation.widen(
            storedBytes,
            scalarType: scalarType,
            byteOrder: input.descriptor.scalarFormat.byteOrder
        )

        func inRange(_ linear: Int) -> Bool {
            let value = samples[linear]
            if let paddingValue, value == paddingValue {
                return false
            }
            if value.isNaN {
                return false
            }
            return lowerBound <= value && value <= upperBound
        }

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
        var maskBytes = [UInt8](repeating: 0, count: sampleCount)
        var queue = [Int]()
        for seed in seeds {
            var linear = 0
            for axis in 0..<rank {
                linear += seed[axis] * strides[axis]
            }
            if inRange(linear), maskBytes[linear] == 0 {
                maskBytes[linear] = 1
                queue.append(linear)
            }
        }
        var head = 0
        var coordinates = [Int](repeating: 0, count: rank)
        while head < queue.count {
            let current = queue[head]
            head += 1
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
                if inside, maskBytes[linear] == 0, inRange(linear) {
                    maskBytes[linear] = 1
                    queue.append(linear)
                }
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
                bytes: maskBytes
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
                type: .uint8,
                validBitCount: nil,
                byteOrder: .native
            ),
            components: input.descriptor.components,
            semantic: .mask,
            axes: outputAxes,
            spatialGeometry: input.descriptor.spatialGeometry,
            valueTransform: nil,
            units: nil
        )

        // The recording the row demands: every seed in order, both
        // bounds, the sentinel only when declared, the connectivity.
        var parameterEntries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "lower-bound"
                ),
                value: .floatingPoint(try MetadataFloatingPoint(value: lowerBound)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "upper-bound"
                ),
                value: .floatingPoint(try MetadataFloatingPoint(value: upperBound)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "connectivity"
                ),
                value: .string(connectivity.rawValue),
                privacyClass: .technical
            ),
        ]
        if let paddingValue {
            parameterEntries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "padding-value"
                    ),
                    value: .floatingPoint(
                        try MetadataFloatingPoint(value: paddingValue)
                    ),
                    privacyClass: .technical
                )
            )
        }
        for (seedIndex, seed) in seeds.enumerated() {
            for (axis, coordinate) in seed.enumerated() {
                parameterEntries.append(
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "seed-\(seedIndex)-axis-\(axis)"
                        ),
                        value: .signedInteger(Int64(coordinate)),
                        privacyClass: .technical
                    )
                )
            }
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
                overCanonicalPackedBytes: maskBytes
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

    /// Builds the frozen parameter collection for digest comparison in
    /// the suite.
    static func parameterCollection(
        seeds: [[Int]],
        lowerBound: Double,
        upperBound: Double,
        paddingValue: Double?,
        connectivity: ComponentConnectivity
    ) throws -> MetadataCollection {
        var entries = [
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "lower-bound"
                ),
                value: .floatingPoint(try MetadataFloatingPoint(value: lowerBound)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "upper-bound"
                ),
                value: .floatingPoint(try MetadataFloatingPoint(value: upperBound)),
                privacyClass: .technical
            ),
            MetadataEntry(
                key: try AnyMetadataKey(
                    namespace: Self.operationIdentifier,
                    name: "connectivity"
                ),
                value: .string(connectivity.rawValue),
                privacyClass: .technical
            ),
        ]
        if let paddingValue {
            entries.append(
                MetadataEntry(
                    key: try AnyMetadataKey(
                        namespace: Self.operationIdentifier,
                        name: "padding-value"
                    ),
                    value: .floatingPoint(
                        try MetadataFloatingPoint(value: paddingValue)
                    ),
                    privacyClass: .technical
                )
            )
        }
        for (seedIndex, seed) in seeds.enumerated() {
            for (axis, coordinate) in seed.enumerated() {
                entries.append(
                    MetadataEntry(
                        key: try AnyMetadataKey(
                            namespace: Self.operationIdentifier,
                            name: "seed-\(seedIndex)-axis-\(axis)"
                        ),
                        value: .signedInteger(Int64(coordinate)),
                        privacyClass: .technical
                    )
                )
            }
        }
        return try MetadataCollection(entries: entries)
    }

    private static func outputAxis(
        _ name: String,
        semantic: AxisSemantic
    ) throws -> AxisDescriptor {
        guard let axisID = AxisID(rawValue: name) else {
            throw RegionGrowError.invalidOutputAxis
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

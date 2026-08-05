// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

final class ScalarSurfaceFixtureOwner: Sendable {
    let bytes: [UInt8]
    let failure: StorageContractError?
    private let readCounter = Mutex(0)

    init(bytes: [UInt8], failure: StorageContractError?) {
        self.bytes = bytes
        self.failure = failure
    }

    var readCount: Int {
        readCounter.withLock { $0 }
    }

    func recordRead() {
        readCounter.withLock { $0 += 1 }
    }
}

struct ScalarSurfaceFixtureStorage: ImageStorageContract {
    let snapshot: StorageSnapshotHandle
    let owner: ScalarSurfaceFixtureOwner

    func read(region: ImageRegion) throws -> RegionReadResult {
        owner.recordRead()
        if let failure = owner.failure {
            throw failure
        }
        let transaction = try RegionReadTransaction(
            handle: snapshot,
            region: region
        )
        try transaction.fill { fill in
            try fill.write(owner.bytes)
        }
        return try transaction.commit()
    }
}

struct ScalarSurfaceFixture: Sendable {
    let image: ImageData
    let owner: ScalarSurfaceFixtureOwner
}

enum ScalarSurfaceTestSupport {
    static let identityMatrix: ContiguousArray<Double> = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ]

    static let singleCornerPositions: ContiguousArray<Double> = [
        0.5, 0, 0,
        0.5, 0.5, 0,
        0.5, 0.5, 0.5,
        0.5, 0, 0.5,
        0, 0.5, 0,
        0, 0.5, 0.5,
        0, 0, 0.5,
    ]

    static let singleCornerIndices: ContiguousArray<UInt64> = [
        0, 1, 2,
        3, 0, 2,
        1, 4, 2,
        4, 5, 2,
        6, 3, 2,
        5, 6, 2,
    ]

    static func fixture(
        extents: ContiguousArray<Int> = [2, 2, 2],
        scalarType: ScalarType = .uint8,
        byteOrder: ByteOrder = .native,
        values: [Double] = [1, 0, 0, 0, 0, 0, 0, 0],
        componentCount: Int = 1,
        interpretation: ComponentInterpretation = .scalar,
        semantic: ImageSemantic = .intensity,
        spatialAxes: ContiguousArray<Int> = [0, 1, 2],
        matrixElements: ContiguousArray<Double> = identityMatrix,
        includesGeometry: Bool = true,
        valueTransform: ValueTransform? = nil,
        validBitCount: Int? = nil,
        readFailure: StorageContractError? = nil,
        allocateBytes: Bool = true
    ) throws -> ScalarSurfaceFixture {
        let shape = try ImageShape(extents: extents)
        let binding = try LogicalSampleBinding(
            shape: shape,
            scalarType: scalarType,
            componentCount: componentCount
        )
        let bytes =
            allocateBytes
            ? encode(
                values: values,
                scalarType: scalarType,
                byteOrder: byteOrder,
                componentCount: componentCount,
                sampleCount: try shape.elementCount()
            ) : []
        let owner = ScalarSurfaceFixtureOwner(
            bytes: bytes,
            failure: readFailure
        )
        let representation = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: byteOrder,
            locality: .processLocalOwned
        )
        let storage = ScalarSurfaceFixtureStorage(
            snapshot: try StorageSnapshotHandle.admit(
                binding: binding,
                representation: .decodedStrided(representation),
                owner: owner,
                generation: 1
            ),
            owner: owner
        )
        let objectID = try #require(
            DataObjectID(rawValue: "scalar-surface-source")
        )
        let provenanceID = try #require(
            ProvenanceID(rawValue: "scalar-surface-source-record")
        )
        let software = try SoftwareIdentity(
            name: "Scalar Surface Test Source",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
        let geometry: SpatialGeometry?
        if includesGeometry {
            geometry = .affine(
                try AffineGridGeometry(
                    spatialAxes: try SpatialAxisMapping(
                        imageAxes: spatialAxes
                    ),
                    indexToWorld: try Matrix4x4Double(
                        elements: matrixElements
                    ),
                    coordinateSpace: try coordinateSpace()
                )
            )
        } else {
            geometry = nil
        }
        let image = try ImageData(
            descriptor: try ImageDescriptor(
                shape: shape,
                scalarFormat: try ScalarFormat(
                    type: scalarType,
                    validBitCount: validBitCount,
                    byteOrder: byteOrder
                ),
                components: try ComponentDescriptor(
                    count: componentCount,
                    interpretation: interpretation,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: semantic,
                axes: ContiguousArray(
                    try (0..<extents.count).map { try axis($0) }
                ),
                spatialGeometry: geometry,
                valueTransform: valueTransform,
                units: nil
            ),
            storage: AnyImageStorage(erasing: storage),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: provenanceID,
                kind: .source,
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-05T15:20:00Z"
                ),
                subject: .object(objectID),
                software: software,
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: objectID,
                contentID: try ContentID.sampleBytesIdentity(
                    overCanonicalPackedBytes: [0]
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "test.scalar-surface",
                        identifier: "source",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
        return ScalarSurfaceFixture(image: image, owner: owner)
    }

    static func request(
        fixture: ScalarSurfaceFixture,
        isovalue: Double = 0.5,
        maximumVertexCount: UInt64 = 1_000_000,
        maximumTriangleCount: UInt64 = 1_000_000
    ) -> ScalarSurfaceExtractionRequest {
        ScalarSurfaceExtractionRequest(
            source: fixture.image,
            isovalue: isovalue,
            limits: ScalarSurfaceExtractionLimits(
                maximumVertexCount: maximumVertexCount,
                maximumTriangleCount: maximumTriangleCount
            )
        )
    }

    static func encode(
        values: [Double],
        scalarType: ScalarType,
        byteOrder: ByteOrder,
        componentCount: Int = 1,
        sampleCount: Int? = nil
    ) -> [UInt8] {
        let requiredValueCount = (sampleCount ?? values.count) * componentCount
        var expanded = [Double]()
        expanded.reserveCapacity(requiredValueCount)
        for index in 0..<requiredValueCount {
            expanded.append(values[index % values.count])
        }

        var bytes = [UInt8]()
        bytes.reserveCapacity(requiredValueCount * scalarType.byteCount)
        for value in expanded {
            let bits: UInt64
            switch scalarType {
            case .int8:
                bits = UInt64(UInt8(bitPattern: Int8(value)))
            case .uint8:
                bits = UInt64(UInt8(value))
            case .int16:
                bits = UInt64(UInt16(bitPattern: Int16(value)))
            case .uint16:
                bits = UInt64(UInt16(value))
            case .int32:
                bits = UInt64(UInt32(bitPattern: Int32(value)))
            case .uint32:
                bits = UInt64(UInt32(value))
            case .int64:
                bits = UInt64(bitPattern: Int64(value))
            case .uint64:
                bits = UInt64(value)
            case .float16:
                bits = UInt64(Float16(value).bitPattern)
            case .float32:
                bits = UInt64(Float(value).bitPattern)
            case .float64:
                bits = value.bitPattern
            }
            append(
                bits: bits,
                byteCount: scalarType.byteCount,
                byteOrder: byteOrder,
                to: &bytes
            )
        }
        return bytes
    }

    private static func append(
        bits: UInt64,
        byteCount: Int,
        byteOrder: ByteOrder,
        to bytes: inout [UInt8]
    ) {
        if byteOrder == .bigEndian {
            for index in (0..<byteCount).reversed() {
                bytes.append(UInt8(truncatingIfNeeded: bits >> UInt64(index * 8)))
            }
        } else {
            for index in 0..<byteCount {
                bytes.append(UInt8(truncatingIfNeeded: bits >> UInt64(index * 8)))
            }
        }
    }

    private static func coordinateSpace() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(
                namespace: "UCUM",
                code: "mm",
                dimension: .length
            ),
            externalReferences: []
        )
    }

    private static func axis(_ index: Int) throws -> AxisDescriptor {
        let semantic: AxisSemantic =
            switch index {
            case 0: .spatialX
            case 1: .spatialY
            case 2: .spatialZ
            default: .generic(namespace: "test", name: "axis")
            }
        return try AxisDescriptor(
            id: try #require(AxisID(rawValue: "axis-\(index)")),
            name: "axis-\(index)",
            semantic: semantic,
            unit: nil,
            sampling: .indexOnly
        )
    }
}

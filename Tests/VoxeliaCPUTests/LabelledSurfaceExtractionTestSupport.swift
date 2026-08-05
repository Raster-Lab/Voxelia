// SPDX-License-Identifier: MIT

import Synchronization
import Testing
import VoxeliaCore
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaCPU

enum LabelledSurfaceFixtureValues: Sendable {
    case signed(ContiguousArray<Int64>)
    case unsigned(ContiguousArray<UInt64>)
}

final class LabelledSurfaceFixtureOwner: Sendable {
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

struct LabelledSurfaceFixtureStorage: ImageStorageContract {
    let snapshot: StorageSnapshotHandle
    let owner: LabelledSurfaceFixtureOwner

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

struct LabelledSurfaceFixture: Sendable {
    let image: ImageData
    let owner: LabelledSurfaceFixtureOwner
}

enum LabelledSurfaceTestSupport {
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
        values: LabelledSurfaceFixtureValues = .unsigned([7, 0, 0, 0, 0, 0, 0, 0]),
        componentCount: Int = 1,
        interpretation: ComponentInterpretation = .scalar,
        semantic: ImageSemantic = .label,
        spatialAxes: ContiguousArray<Int> = [0, 1, 2],
        matrixElements: ContiguousArray<Double> = identityMatrix,
        includesGeometry: Bool = true,
        valueTransform: ValueTransform? = nil,
        validBitCount: Int? = nil,
        units: MeasurementUnit? = nil,
        readFailure: StorageContractError? = nil,
        allocateBytes: Bool = true
    ) throws -> LabelledSurfaceFixture {
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
        let owner = LabelledSurfaceFixtureOwner(
            bytes: bytes,
            failure: readFailure
        )
        let representation = try DecodedStridedRepresentation.canonicalPacked(
            binding: binding,
            byteOrder: byteOrder,
            locality: .processLocalOwned
        )
        let storage = LabelledSurfaceFixtureStorage(
            snapshot: try StorageSnapshotHandle.admit(
                binding: binding,
                representation: .decodedStrided(representation),
                owner: owner,
                generation: 1
            ),
            owner: owner
        )
        let objectID = try #require(
            DataObjectID(rawValue: "labelled-surface-source")
        )
        let provenanceID = try #require(
            ProvenanceID(rawValue: "labelled-surface-source-record")
        )
        let software = try SoftwareIdentity(
            name: "Labelled Surface Test Source",
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
                units: units
            ),
            storage: AnyImageStorage(erasing: storage),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: provenanceID,
                kind: .source,
                createdAt: try CanonicalInstant(
                    utcString: "2026-08-05T16:30:00Z"
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
                    overCanonicalPackedBytes: bytes
                ),
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "test.labelled-surface",
                        identifier: "source",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
        return LabelledSurfaceFixture(image: image, owner: owner)
    }

    static func request(
        fixture: LabelledSurfaceFixture,
        selectedLabels: LabelledSurfaceLabelSet = .unsigned([7]),
        maximumSelectedLabelCount: UInt64 = 65_536,
        maximumVertexCount: UInt64 = 1_000_000,
        maximumTriangleCount: UInt64 = 1_000_000
    ) -> LabelledSurfaceExtractionRequest {
        LabelledSurfaceExtractionRequest(
            source: fixture.image,
            selectedLabels: selectedLabels,
            limits: LabelledSurfaceExtractionLimits(
                maximumSelectedLabelCount: maximumSelectedLabelCount,
                maximumVertexCount: maximumVertexCount,
                maximumTriangleCount: maximumTriangleCount
            )
        )
    }

    static func encode(
        values: LabelledSurfaceFixtureValues,
        scalarType: ScalarType,
        byteOrder: ByteOrder,
        componentCount: Int = 1,
        sampleCount: Int? = nil
    ) -> [UInt8] {
        let valueCount: Int
        switch values {
        case .signed(let signed): valueCount = signed.count
        case .unsigned(let unsigned): valueCount = unsigned.count
        }
        let requiredValueCount = (sampleCount ?? valueCount) * componentCount
        var bytes = [UInt8]()
        bytes.reserveCapacity(requiredValueCount * scalarType.byteCount)
        for index in 0..<requiredValueCount {
            let bits: UInt64
            switch values {
            case .signed(let signed):
                bits = UInt64(bitPattern: signed[index % signed.count])
            case .unsigned(let unsigned):
                bits = unsigned[index % unsigned.count]
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

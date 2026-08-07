// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaCore
import VoxeliaExecution
import VoxeliaGeometry

@testable import VoxeliaCPU

@Suite("CPU labelled-surface reference kernel")
struct LabelledSurfaceReferenceKernelTests {
    private struct PointKey: Hashable, Comparable {
        let x: Double
        let y: Double
        let z: Double

        static func < (lhs: Self, rhs: Self) -> Bool {
            if lhs.x != rhs.x { return lhs.x < rhs.x }
            if lhs.y != rhs.y { return lhs.y < rhs.y }
            return lhs.z < rhs.z
        }
    }

    private struct SegmentKey: Hashable, Comparable {
        let first: PointKey
        let second: PointKey

        static func < (lhs: Self, rhs: Self) -> Bool {
            if lhs.first != rhs.first { return lhs.first < rhs.first }
            return lhs.second < rhs.second
        }
    }

    @Test(
        "[Kernel][VOX-GEO-007] every integer container and byte order matches the golden",
        arguments: [
            ScalarType.int8, .uint8, .int16, .uint16,
            .int32, .uint32, .int64, .uint64,
        ],
        [ByteOrder.native, .littleEndian, .bigEndian]
    )
    func admittedContainerAndByteOrder(
        scalarType: ScalarType,
        byteOrder: ByteOrder
    ) async throws {
        let signed = scalarType.isSignedInteger
        let fixture = try LabelledSurfaceTestSupport.fixture(
            scalarType: scalarType,
            byteOrder: byteOrder,
            values: signed
                ? .signed([7, -4, -4, -4, -4, -4, -4, -4])
                : .unsigned([7, 0, 0, 0, 0, 0, 0, 0])
        )
        let selected: LabelledSurfaceLabelSet =
            signed ? .signed([7]) : .unsigned([7])
        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        let mesh = try await CPULabelledSurfaceExtractionOperation.extractMesh(
            request: LabelledSurfaceTestSupport.request(
                fixture: fixture,
                selectedLabels: selected
            ),
            coordinator: coordinator
        )
        #expect(
            mesh.positions.components
                == LabelledSurfaceTestSupport.singleCornerPositions
        )
        #expect(
            mesh.topology.indices
                == LabelledSurfaceTestSupport.singleCornerIndices
        )
        #expect(fixture.owner.readCount == 1)
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    @Test("[Oracle][VOX-GEO-008] all 256 memberships match both registered digests")
    func everyCubeMembershipMatchesIndependentOracle() throws {
        let fixture = try LabelledSurfaceTestSupport.fixture()
        var rationalRecords = [String]()
        var binary64Records = [String]()
        var maximumVertexCount = 0
        var maximumTriangleCount = 0
        for mask in 0..<256 {
            let labels = (0..<8).map {
                mask & (1 << $0) == 0 ? UInt64(23) : UInt64(11)
            }
            let mesh = try extract(
                fixture: fixture,
                values: .unsigned(ContiguousArray(labels)),
                selectedLabels: .unsigned([11])
            )
            maximumVertexCount = max(
                maximumVertexCount,
                mesh.positions.vertexCount
            )
            maximumTriangleCount = max(
                maximumTriangleCount,
                mesh.topology.triangleCount
            )
            for offset in stride(
                from: 0,
                to: mesh.topology.indices.count,
                by: 3
            ) {
                #expect(
                    Set(mesh.topology.indices[offset..<(offset + 3)]).count
                        == 3
                )
            }
            rationalRecords.append(
                try rationalRecord(mesh: mesh, prefix: "\"mask\":\(mask),")
            )
            binary64Records.append(
                binary64Record(mesh: mesh, prefix: "\"mask\":\(mask),")
            )
        }
        #expect(
            sha256("[" + rationalRecords.joined(separator: ",") + "]")
                == "4bed958ac7d25a4539de8a0cea28524271a89303c3e9e3fb0de0d311e5c6931d"
        )
        #expect(
            sha256("[" + binary64Records.joined(separator: ",") + "]")
                == "154f1d57f1fe6491f9fe6267109fa46074ffba860d16f7284736388a434536aa"
        )
        #expect(maximumVertexCount == 13)
        #expect(maximumTriangleCount == 12)
    }

    @Test("[Oracle][VOX-GEO-007] all 45,927 ternary unions match categorical oracle")
    func everyTernaryUnionMatchesIndependentOracle() throws {
        let fixture = try LabelledSurfaceTestSupport.fixture(
            scalarType: .int8,
            values: .signed([0])
        )
        let rawValues: ContiguousArray<Int64> = [-9, 4, 71]
        let selections: [ContiguousArray<Int64>] = [
            [-9], [4], [71], [-9, 4], [-9, 71], [4, 71], [-9, 4, 71],
        ]
        var hasher = SHA256()
        var caseCount = 0
        for encoded in 0..<6_561 {
            var labels = ContiguousArray<Int64>()
            var divisor = 2_187
            for _ in 0..<8 {
                labels.append(rawValues[(encoded / divisor) % 3])
                divisor /= 3
            }
            for selected in selections {
                let mesh = try extract(
                    fixture: fixture,
                    values: .signed(labels),
                    selectedLabels: .signed(selected)
                )
                let labelsText = labels.map(String.init).joined(separator: ",")
                let selectedText = selected.map(String.init).joined(separator: ",")
                let prefix =
                    "\"labels\":[\(labelsText)],\"selected\":[\(selectedText)],"
                let record = try rationalRecord(mesh: mesh, prefix: prefix)
                hasher.update(data: Array(record.utf8))
                hasher.update(data: [UInt8(0x0A)])
                caseCount += 1
            }
        }
        #expect(caseCount == 45_927)
        #expect(
            hexadecimal(hasher.finalize())
                == "b4bfe7adc07d80b0231bff3be93e82adb42a3c7c8d0d72684899d7aa7ac6ef95"
        )
    }

    @Test("[Oracle][VOX-GEO-008] all 4,096 shared faces are conforming")
    func everySharedFaceMatchesIndependentOracle() throws {
        let fixture = try LabelledSurfaceTestSupport.fixture()
        var records = [String]()
        for mask in 0..<(1 << 12) {
            let labels = (0..<12).map {
                mask & (1 << $0) == 0 ? UInt64(0) : UInt64(1)
            }
            var left = ContiguousArray<UInt64>()
            var right = ContiguousArray<UInt64>()
            for z in 0..<2 {
                for y in 0..<2 {
                    for x in 0..<2 {
                        left.append(labels[x + 3 * y + 6 * z])
                        right.append(labels[(x + 1) + 3 * y + 6 * z])
                    }
                }
            }
            let leftMesh = try extract(
                fixture: fixture,
                values: .unsigned(left),
                selectedLabels: .unsigned([1])
            )
            let rightMesh = try extract(
                fixture: fixture,
                values: .unsigned(right),
                selectedLabels: .unsigned([1])
            )
            let leftSegments = seamSegments(
                mesh: leftMesh,
                xOffset: 0,
                planeX: 1
            )
            let rightSegments = seamSegments(
                mesh: rightMesh,
                xOffset: 1,
                planeX: 1
            )
            #expect(leftSegments == rightSegments)
            let segmentText = try leftSegments.map { segment in
                "[\(try pointRecord(segment.first)),\(try pointRecord(segment.second))]"
            }.joined(separator: ",")
            records.append(
                "{\"mask\":\(mask),\"segments\":[\(segmentText)]}"
            )
        }
        #expect(
            sha256("[" + records.joined(separator: ",") + "]")
                == "d656b3f812750fd97813431fb9168d26e8f87ea1148f326cf6e2a83ef0a831e9"
        )
    }

    @Test("[Oracle][VOX-GEO-007] integer extrema and explicit byte orders are exact")
    func integerContainerExtremaMatchIndependentOracle() throws {
        let scalarTypes: [ScalarType] = [
            .int8, .uint8, .int16, .uint16,
            .int32, .uint32, .int64, .uint64,
        ]
        var records = [String]()
        for scalarType in scalarTypes {
            for (byteOrder, orderText) in [
                (ByteOrder.littleEndian, "little"),
                (.bigEndian, "big"),
            ] {
                let fixture = try LabelledSurfaceTestSupport.fixture(
                    extents: [1, 1, 1],
                    scalarType: scalarType,
                    byteOrder: byteOrder,
                    values: scalarType.isSignedInteger
                        ? .signed([0]) : .unsigned([0])
                )
                if scalarType.isSignedInteger {
                    for value in signedExtrema(scalarType) {
                        let values = LabelledSurfaceFixtureValues.signed([value])
                        let selected = LabelledSurfaceLabelSet.signed([value])
                        try expectSelected(
                            fixture: fixture,
                            scalarType: scalarType,
                            byteOrder: byteOrder,
                            values: values,
                            selectedLabels: selected
                        )
                        let bytes = LabelledSurfaceTestSupport.encode(
                            values: values,
                            scalarType: scalarType,
                            byteOrder: byteOrder
                        )
                        records.append(
                            containerRecord(
                                scalarType: scalarType,
                                bytes: bytes,
                                domain: "signed",
                                order: orderText,
                                value: String(value)
                            )
                        )
                    }
                } else {
                    for value in unsignedExtrema(scalarType) {
                        let values = LabelledSurfaceFixtureValues.unsigned([value])
                        let selected = LabelledSurfaceLabelSet.unsigned([value])
                        try expectSelected(
                            fixture: fixture,
                            scalarType: scalarType,
                            byteOrder: byteOrder,
                            values: values,
                            selectedLabels: selected
                        )
                        let bytes = LabelledSurfaceTestSupport.encode(
                            values: values,
                            scalarType: scalarType,
                            byteOrder: byteOrder
                        )
                        records.append(
                            containerRecord(
                                scalarType: scalarType,
                                bytes: bytes,
                                domain: "unsigned",
                                order: orderText,
                                value: String(value)
                            )
                        )
                    }
                }
            }
        }
        #expect(records.count == 48)
        #expect(
            sha256("[" + records.joined(separator: ",") + "]")
                == "3bf3a336dfd94d366f4981ce0431e2ea42f126f48647e0ab39d3b6c3e6f54253"
        )
    }

    @Test("[Kernel][VOX-GEO-007] unions suppress selected interfaces and preserve open bounds")
    func unionAndEmptyBoundarySemantics() throws {
        let fixture = try LabelledSurfaceTestSupport.fixture(
            extents: [3, 2, 2],
            values: .unsigned([0])
        )
        let labels: ContiguousArray<UInt64> = [
            1, 2, 0,
            1, 2, 0,
            1, 2, 0,
            1, 2, 0,
        ]
        let union = try extract(
            fixture: fixture,
            values: .unsigned(labels),
            selectedLabels: .unsigned([1, 2])
        )
        #expect(union.positions.vertexCount == 9)
        #expect(union.topology.triangleCount == 8)
        #expect(positionTriples(union).allSatisfy { $0.x == 1.5 })

        for selected in [
            LabelledSurfaceLabelSet.unsigned([0, 1, 2]),
            .unsigned([99]),
            .unsigned([UInt64.max]),
        ] {
            let empty = try extract(
                fixture: fixture,
                values: .unsigned(labels),
                selectedLabels: selected
            )
            #expect(empty.positions.components.isEmpty)
            #expect(empty.topology.indices.isEmpty)
        }

        let noCellFixture = try LabelledSurfaceTestSupport.fixture(
            extents: [1, 2, 2],
            values: .unsigned([1, 0, 0, 0])
        )
        let noCell = try extract(
            fixture: noCellFixture,
            values: .unsigned([1, 0, 0, 0]),
            selectedLabels: .unsigned([1])
        )
        #expect(noCell.topology.indices.isEmpty)
    }

    @Test("[Kernel][VOX-GEO-006][VOX-ERR-001] mapping winding midpoints and limits fail closed")
    func mappingMidpointAndLimits() async throws {
        #expect(try LabelledSurfaceReferenceKernel.midpoint(0, 1) == 0.5)
        #expect(throws: LabelledSurfaceExtractionError.positionNotRepresentable) {
            try LabelledSurfaceReferenceKernel.midpoint(
                9_007_199_254_740_991,
                9_007_199_254_740_992
            )
        }
        #expect(throws: LabelledSurfaceExtractionError.positionNotRepresentable) {
            try LabelledSurfaceReferenceKernel.midpoint(Int.min, Int.max)
        }

        let reflected = try LabelledSurfaceTestSupport.fixture(
            matrixElements: [
                -1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]
        )
        let reflectedMesh = try extract(
            fixture: reflected,
            values: .unsigned([7, 0, 0, 0, 0, 0, 0, 0]),
            selectedLabels: .unsigned([7])
        )
        var expectedReflected = ContiguousArray<Double>()
        for offset in stride(
            from: 0,
            to: LabelledSurfaceTestSupport.singleCornerPositions.count,
            by: 3
        ) {
            expectedReflected.append(
                -LabelledSurfaceTestSupport.singleCornerPositions[offset]
            )
            expectedReflected.append(
                LabelledSurfaceTestSupport.singleCornerPositions[offset + 1]
            )
            expectedReflected.append(
                LabelledSurfaceTestSupport.singleCornerPositions[offset + 2]
            )
        }
        #expect(reflectedMesh.positions.components == expectedReflected)
        #expect(
            reflectedMesh.topology.indices
                == reversedWinding(LabelledSurfaceTestSupport.singleCornerIndices)
        )

        let permuted = try LabelledSurfaceTestSupport.fixture(
            spatialAxes: [1, 0, 2]
        )
        let permutedMesh = try extract(
            fixture: permuted,
            values: .unsigned([7, 0, 0, 0, 0, 0, 0, 0]),
            selectedLabels: .unsigned([7])
        )
        var expectedPermuted = ContiguousArray<Double>()
        for offset in stride(
            from: 0,
            to: LabelledSurfaceTestSupport.singleCornerPositions.count,
            by: 3
        ) {
            expectedPermuted.append(
                LabelledSurfaceTestSupport.singleCornerPositions[offset + 1]
            )
            expectedPermuted.append(
                LabelledSurfaceTestSupport.singleCornerPositions[offset]
            )
            expectedPermuted.append(
                LabelledSurfaceTestSupport.singleCornerPositions[offset + 2]
            )
        }
        #expect(permutedMesh.positions.components == expectedPermuted)
        #expect(
            permutedMesh.topology.indices
                == reversedWinding(LabelledSurfaceTestSupport.singleCornerIndices)
        )

        let orderedAffine = try LabelledSurfaceTestSupport.fixture(
            matrixElements: [
                2, 4, 8, 16,
                1, 3, 9, 27,
                5, 7, 11, 13,
                0, 0, 0, 1,
            ]
        )
        let orderedAffineMesh = try extract(
            fixture: orderedAffine,
            values: .unsigned([7, 0, 0, 0, 0, 0, 0, 0]),
            selectedLabels: .unsigned([7])
        )
        #expect(
            orderedAffineMesh.positions.components
                == [
                    17, 27.5, 15.5,
                    19, 29, 19,
                    23, 33.5, 24.5,
                    21, 32, 21,
                    18, 28.5, 16.5,
                    22, 33, 22,
                    20, 31.5, 18.5,
                ]
        )
        #expect(
            orderedAffineMesh.topology.indices
                == LabelledSurfaceTestSupport.singleCornerIndices
        )

        let maximum = Double.greatestFiniteMagnitude
        let overflowing = try LabelledSurfaceTestSupport.fixture(
            matrixElements: [
                maximum, 0, 0, maximum,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ]
        )
        #expect(throws: LabelledSurfaceExtractionError.positionNotRepresentable) {
            try extract(
                fixture: overflowing,
                values: .unsigned([7, 0, 0, 0, 0, 0, 0, 0]),
                selectedLabels: .unsigned([7])
            )
        }

        let coordinator = StorageReadCoordinator(
            maximumRetainedResultByteCount: 1_024
        )
        for request in [
            LabelledSurfaceTestSupport.request(
                fixture: reflected,
                maximumVertexCount: 6
            ),
            LabelledSurfaceTestSupport.request(
                fixture: reflected,
                maximumTriangleCount: 5
            ),
        ] {
            await #expect(
                throws: LabelledSurfaceExtractionError.resourceLimitExceeded
            ) {
                try await CPULabelledSurfaceExtractionOperation.extractMesh(
                    request: request,
                    coordinator: coordinator
                )
            }
        }
        #expect(await coordinator.currentChargedByteCount == 0)
    }

    private func extract(
        fixture: LabelledSurfaceFixture,
        values: LabelledSurfaceFixtureValues,
        selectedLabels: LabelledSurfaceLabelSet
    ) throws -> TriangleMesh {
        let request = LabelledSurfaceTestSupport.request(
            fixture: fixture,
            selectedLabels: selectedLabels
        )
        let admission = try LabelledSurfaceSourceAdmission(request: request)
        let bytes = LabelledSurfaceTestSupport.encode(
            values: values,
            scalarType: admission.scalarType,
            byteOrder: admission.byteOrder,
            sampleCount: admission.sampleCount
        )
        let source = try LabelledSurfaceSourceAdapter(
            request: request,
            admission: admission,
            bytes: bytes
        )
        return try LabelledSurfaceReferenceKernel.extract(
            request: request,
            source: source,
            cancellation: { _ in false }
        )
    }

    private func expectSelected(
        fixture: LabelledSurfaceFixture,
        scalarType: ScalarType,
        byteOrder: ByteOrder,
        values: LabelledSurfaceFixtureValues,
        selectedLabels: LabelledSurfaceLabelSet
    ) throws {
        let request = LabelledSurfaceTestSupport.request(
            fixture: fixture,
            selectedLabels: selectedLabels
        )
        let source = try LabelledSurfaceSourceAdapter(
            request: request,
            admission: LabelledSurfaceSourceAdmission(request: request),
            bytes: LabelledSurfaceTestSupport.encode(
                values: values,
                scalarType: scalarType,
                byteOrder: byteOrder
            )
        )
        #expect(try source.isSelected(at: 0))
    }

    private func rationalRecord(
        mesh: TriangleMesh,
        prefix: String
    ) throws -> String {
        let triangles = triangleRecords(mesh).joined(separator: ",")
        let vertices = try positionTriples(mesh).map(pointRecord).joined(
            separator: ","
        )
        return
            "{\(prefix)\"triangles\":[\(triangles)],\"vertices\":[\(vertices)]}"
    }

    private func binary64Record(
        mesh: TriangleMesh,
        prefix: String
    ) -> String {
        let triangles = triangleRecords(mesh).joined(separator: ",")
        let vertices = positionTriples(mesh).map { point in
            "[\"\(hexadecimal(point.x.bitPattern, width: 16))\",\"\(hexadecimal(point.y.bitPattern, width: 16))\",\"\(hexadecimal(point.z.bitPattern, width: 16))\"]"
        }.joined(separator: ",")
        return
            "{\(prefix)\"triangles\":[\(triangles)],\"vertexBits\":[\(vertices)]}"
    }

    private func triangleRecords(_ mesh: TriangleMesh) -> [String] {
        stride(from: 0, to: mesh.topology.indices.count, by: 3).map {
            "[\(mesh.topology.indices[$0]),\(mesh.topology.indices[$0 + 1]),\(mesh.topology.indices[$0 + 2])]"
        }
    }

    private func positionTriples(_ mesh: TriangleMesh) -> [PointKey] {
        stride(from: 0, to: mesh.positions.components.count, by: 3).map {
            PointKey(
                x: mesh.positions.components[$0],
                y: mesh.positions.components[$0 + 1],
                z: mesh.positions.components[$0 + 2]
            )
        }
    }

    private func pointRecord(_ point: PointKey) throws -> String {
        "[\"\(try fractionText(point.x))\",\"\(try fractionText(point.y))\",\"\(try fractionText(point.z))\"]"
    }

    private func fractionText(_ value: Double) throws -> String {
        guard
            let doubled = Int(exactly: value * 2),
            Double(doubled) / 2 == value
        else {
            throw FixtureError.nonDyadicHalfCoordinate
        }
        if doubled.isMultiple(of: 2) {
            return "\(doubled / 2)/1"
        }
        return "\(doubled)/2"
    }

    private func seamSegments(
        mesh: TriangleMesh,
        xOffset: Double,
        planeX: Double
    ) -> [SegmentKey] {
        let positions = positionTriples(mesh).map {
            PointKey(x: $0.x + xOffset, y: $0.y, z: $0.z)
        }
        var segments = [SegmentKey]()
        for offset in stride(from: 0, to: mesh.topology.indices.count, by: 3) {
            let triangle = [
                positions[Int(mesh.topology.indices[offset])],
                positions[Int(mesh.topology.indices[offset + 1])],
                positions[Int(mesh.topology.indices[offset + 2])],
            ]
            for (firstIndex, secondIndex) in [(0, 1), (1, 2), (2, 0)] {
                let first = triangle[firstIndex]
                let second = triangle[secondIndex]
                if first.x == planeX, second.x == planeX {
                    segments.append(
                        first < second
                            ? SegmentKey(first: first, second: second)
                            : SegmentKey(first: second, second: first)
                    )
                }
            }
        }
        return segments.sorted()
    }

    private func signedExtrema(_ scalarType: ScalarType) -> [Int64] {
        switch scalarType {
        case .int8: [Int64(Int8.min), 0, Int64(Int8.max)]
        case .int16: [Int64(Int16.min), 0, Int64(Int16.max)]
        case .int32: [Int64(Int32.min), 0, Int64(Int32.max)]
        case .int64: [Int64.min, 0, Int64.max]
        default: []
        }
    }

    private func unsignedExtrema(_ scalarType: ScalarType) -> [UInt64] {
        switch scalarType {
        case .uint8: [UInt64(UInt8.min), 0, UInt64(UInt8.max)]
        case .uint16: [UInt64(UInt16.min), 0, UInt64(UInt16.max)]
        case .uint32: [UInt64(UInt32.min), 0, UInt64(UInt32.max)]
        case .uint64: [UInt64.min, 0, UInt64.max]
        default: []
        }
    }

    private func containerRecord(
        scalarType: ScalarType,
        bytes: [UInt8],
        domain: String,
        order: String,
        value: String
    ) -> String {
        let byteText = bytes.map {
            hexadecimal(UInt64($0), width: 2)
        }.joined()
        return
            "{\"bits\":\(scalarType.bitCount),\"bytes\":\"\(byteText)\",\"domain\":\"\(domain)\",\"order\":\"\(order)\",\"value\":\"\(value)\"}"
    }

    private func sha256(_ text: String) -> String {
        hexadecimal(SHA256.hash(data: Array(text.utf8)))
    }

    private func hexadecimal<Digest: Sequence>(_ digest: Digest) -> String
    where Digest.Element == UInt8 {
        digest.map { hexadecimal(UInt64($0), width: 2) }.joined()
    }

    private func hexadecimal(_ value: UInt64, width: Int) -> String {
        let text = String(value, radix: 16)
        return String(repeating: "0", count: width - text.count) + text
    }

    private func reversedWinding(
        _ indices: ContiguousArray<UInt64>
    ) -> ContiguousArray<UInt64> {
        var reversed = ContiguousArray<UInt64>()
        for offset in stride(from: 0, to: indices.count, by: 3) {
            reversed.append(indices[offset])
            reversed.append(indices[offset + 2])
            reversed.append(indices[offset + 1])
        }
        return reversed
    }

    private enum FixtureError: Error {
        case nonDyadicHalfCoordinate
    }
}

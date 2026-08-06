// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaSpatial

@testable import VoxeliaGeometry

@Suite("Triangle mesh byte decoder")
struct TriangleMeshByteDecoderTests {
    private struct Fixture: Sendable {
        let name: String
        let vertexCount: Int
        let triangleCount: Int
        let positionBytes: [UInt8]
        let indexBytes: [UInt8]
    }

    @Test(
        "[Oracle][VOX-SUR-009][VOX-NUM-001] all ALG-0041 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            let mesh: TriangleMesh
            do {
                mesh = try decode(fixture)
            } catch {
                records.append("\(fixture.name)|error=\(errorName(error))")
                continue
            }
            let components = Array(mesh.positions.components)
            let indices = Array(mesh.topology.indices)
            records.append(
                "\(fixture.name)|components="
                    + components.map {
                        hexadecimal($0.bitPattern, width: 16)
                    }.joined(separator: ",")
                    + "|indices="
                    + indices.map(String.init).joined(separator: ",")
            )
            for component in components {
                payload.append(
                    contentsOf: littleEndianBytes(component.bitPattern)
                )
            }
            for index in indices {
                payload.append(contentsOf: littleEndianBytes(index))
            }
        }

        #expect(records.count == 18)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "055eddda7b501f397741194f7ca2dbc038e0191c87c9e8634f298561d4ae079c"
        )
        #expect(
            sha256(payload)
                == "fc52599c92900bc37cbea6dc206f481a4ee419347628634a67cf5da476ab04c4"
        )
    }

    @Test(
        "[Unit][VOX-SUR-009][VOX-GEO-002] the decoded mesh survives its source bytes"
    )
    func decodedMeshSurvivesItsSourceBytes() throws {
        // This is the operational meaning of "the buffer is not canonical":
        // once decoded, the payload can be mutated or discarded and the mesh is
        // unchanged, because the canonical value holds no reference to it.
        var positionBytes = Self.unitPositions
        let indexBytes = Self.indices(0, 1, 2)
        let mesh = try TriangleMeshByteDecoder.decode(
            vertexCount: 3,
            triangleCount: 1,
            positionBytes: positionBytes,
            indexBytes: indexBytes,
            coordinateSpace: try coordinateSpace()
        )
        let before = Array(mesh.positions.components)

        for index in positionBytes.indices {
            positionBytes[index] = 0xFF
        }
        positionBytes = []

        #expect(Array(mesh.positions.components) == before)
        #expect(before == [1, 0, 0, 0, 1, 0, 0, 0, 1])
    }

    @Test(
        "[Unit][VOX-SUR-009][VOX-NUM-001] the byte order is little-endian and the widening is exact"
    )
    func byteOrderIsLittleEndianAndWideningIsExact() throws {
        // 00 00 80 3F is exactly 1.0. Read the other way it would be
        // 4.6006e-41, so this single assertion pins the byte order.
        #expect(try component(of: [0x00, 0x00, 0x80, 0x3F]) == 1.0)

        // Widening binary32 to binary64 is exact, so no precision is invented:
        // decimal 0.1 written as a binary32 publishes as its own value, not as
        // 0.1.
        #expect(
            try component(of: [0xCD, 0xCC, 0xCC, 0x3D])
                == 0.100_000_001_490_116_12
        )

        // The binary32 extremes widen exactly too.
        #expect(
            try component(of: [0x01, 0x00, 0x00, 0x00])
                == Double(Float.leastNonzeroMagnitude)
        )
        #expect(
            try component(of: [0x00, 0x00, 0x80, 0x00])
                == Double(Float.leastNormalMagnitude)
        )
        #expect(
            try component(of: [0xFF, 0xFF, 0x7F, 0x7F])
                == Double(Float.greatestFiniteMagnitude)
        )

        // Negative zero survives as negative zero, distinguishable only by its
        // bit pattern.
        let signedZero = try component(of: [0x00, 0x00, 0x00, 0x80])
        #expect(signedZero == 0.0)
        #expect(signedZero.bitPattern == 0x8000_0000_0000_0000)
    }

    @Test(
        "[Unit][VOX-SUR-009][VOX-ERR-001] geometric rejections come from the canonical admission"
    )
    func geometricRejectionsComeFromTheCanonicalAdmission() throws {
        // The decoder restates no geometric rule, and the thrown error type is
        // the proof: a non-finite position and an out-of-range index are the
        // canonical value's own failures, not the decoder's.
        #expect(throws: TriangleMeshPositionDomainError.nonFinitePosition) {
            try TriangleMeshByteDecoder.decode(
                vertexCount: 1,
                triangleCount: 0,
                positionBytes: [0x00, 0x00, 0x80, 0x7F] + [UInt8](repeating: 0, count: 8),
                indexBytes: [],
                coordinateSpace: try coordinateSpace()
            )
        }
        #expect(throws: TriangleMeshTopologyError.indexOutOfBounds) {
            try TriangleMeshByteDecoder.decode(
                vertexCount: 3,
                triangleCount: 1,
                positionBytes: Self.unitPositions,
                indexBytes: Self.indices(0, 1, 3),
                coordinateSpace: try coordinateSpace()
            )
        }

        // The decoder's own family is exactly four byte-level cases.
        let errors: [TriangleMeshByteDecodingError] = [
            .negativeCount, .countNotRepresentable,
            .positionByteCountMismatch, .indexByteCountMismatch,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "negativeCount", "countNotRepresentable",
                "positionByteCountMismatch", "indexByteCountMismatch",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })

        // A count too large to address its own payload is rejected before a
        // single byte is read.
        #expect(throws: TriangleMeshByteDecodingError.countNotRepresentable) {
            try TriangleMeshByteDecoder.decode(
                vertexCount: Int.max / 4,
                triangleCount: 0,
                positionBytes: [],
                indexBytes: [],
                coordinateSpace: try coordinateSpace()
            )
        }
    }

    // MARK: - Fixtures

    private static let unitPositions = floats(
        0x3F80_0000, 0, 0, 0, 0x3F80_0000, 0, 0, 0, 0x3F80_0000
    )

    private func analyticalFixtures() -> [Fixture] {
        func fixture(
            _ name: String,
            _ vertexCount: Int,
            _ triangleCount: Int,
            _ positionBytes: [UInt8],
            _ indexBytes: [UInt8] = []
        ) -> Fixture {
            Fixture(
                name: name,
                vertexCount: vertexCount,
                triangleCount: triangleCount,
                positionBytes: positionBytes,
                indexBytes: indexBytes
            )
        }
        let unit = Self.unitPositions
        return [
            fixture("single-triangle", 3, 1, unit, Self.indices(0, 1, 2)),
            fixture("byte-order", 1, 0, Self.floats(0x3F80_0000, 0, 0)),
            fixture("exact-widening", 1, 0, Self.floats(0x3DCC_CCCD, 0, 0)),
            fixture(
                "binary32-extremes",
                1,
                0,
                Self.floats(0x0000_0001, 0x0080_0000, 0x7F7F_FFFF)
            ),
            fixture("negative-zero", 1, 0, Self.floats(0x8000_0000, 0, 0)),
            fixture("empty", 0, 0, []),
            fixture("vertices-without-triangles", 1, 0, Self.floats(1, 2, 3)),
            fixture(
                "two-triangles",
                4,
                2,
                unit + Self.floats(0xBF80_0000, 0, 0),
                Self.indices(0, 1, 2, 2, 1, 3)
            ),
            fixture("infinite-position", 1, 0, Self.floats(0x7F80_0000, 0, 0)),
            fixture("nan-position", 1, 0, Self.floats(0x7FC0_0000, 0, 0)),
            fixture(
                "index-out-of-bounds",
                3,
                1,
                unit,
                Self.indices(0, 1, 3)
            ),
            fixture(
                "position-bytes-short",
                3,
                1,
                Array(unit.dropLast()),
                Self.indices(0, 1, 2)
            ),
            fixture(
                "position-bytes-long",
                3,
                1,
                unit + [0],
                Self.indices(0, 1, 2)
            ),
            fixture("index-bytes-short", 3, 1, unit, Self.indices(0, 1)),
            fixture(
                "index-bytes-long",
                3,
                1,
                unit,
                Self.indices(0, 1, 2, 0)
            ),
            fixture("negative-vertex-count", -1, 0, []),
            fixture("negative-triangle-count", 0, -1, []),
            fixture("count-not-representable", 1 << 62, 0, []),
        ]
    }

    // MARK: - Helpers

    private static func floats(_ words: UInt32...) -> [UInt8] {
        words.flatMap { word in
            (0..<4).map { UInt8(truncatingIfNeeded: word >> UInt32($0 * 8)) }
        }
    }

    private static func indices(_ values: UInt32...) -> [UInt8] {
        values.flatMap { value in
            (0..<4).map { UInt8(truncatingIfNeeded: value >> UInt32($0 * 8)) }
        }
    }

    private func decode(_ fixture: Fixture) throws -> TriangleMesh {
        try TriangleMeshByteDecoder.decode(
            vertexCount: fixture.vertexCount,
            triangleCount: fixture.triangleCount,
            positionBytes: fixture.positionBytes,
            indexBytes: fixture.indexBytes,
            coordinateSpace: try coordinateSpace()
        )
    }

    private func component(of bytes: [UInt8]) throws -> Double {
        let mesh = try TriangleMeshByteDecoder.decode(
            vertexCount: 1,
            triangleCount: 0,
            positionBytes: bytes + [UInt8](repeating: 0, count: 8),
            indexBytes: [],
            coordinateSpace: try coordinateSpace()
        )
        return mesh.positions.components[0]
    }

    private func errorName(_ error: any Error) -> String {
        String(describing: error)
    }

    private func coordinateSpace() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "decoder-world")),
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

    private func littleEndianBytes(_ bitPattern: UInt64) -> [UInt8] {
        (0..<8).map { byteIndex in
            UInt8(truncatingIfNeeded: bitPattern >> UInt64(byteIndex * 8))
        }
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: bytes).map {
            hexadecimal(UInt64($0), width: 2)
        }.joined()
    }

    private func hexadecimal(_ value: UInt64, width: Int) -> String {
        let text = String(value, radix: 16)
        return String(repeating: "0", count: width - text.count) + text
    }
}

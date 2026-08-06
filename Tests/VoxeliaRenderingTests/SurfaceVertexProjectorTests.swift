// SPDX-License-Identifier: MIT

import CryptoKit
import Synchronization
import Testing
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("Surface vertex projector")
struct SurfaceVertexProjectorTests {
    private struct Fixture: Sendable {
        let name: String
        let positions: ContiguousArray<Double>
        let matrix: [Double]
        let position: (Double, Double, Double)
        let target: (Double, Double, Double)
        let up: (Double, Double, Double)
        let planeHeight: Double
        let width: Int
        let height: Int
        let perspective: Bool
    }

    private final class CheckpointLog: Sendable {
        private let recorded = Mutex([SurfaceVertexProjectionCheckpoint]())

        func record(_ checkpoint: SurfaceVertexProjectionCheckpoint) {
            recorded.withLock { $0.append(checkpoint) }
        }

        var checkpoints: [SurfaceVertexProjectionCheckpoint] {
            recorded.withLock { $0 }
        }
    }

    @Test(
        "[Oracle][VOX-SUR-001][VOX-NUM-001] all ALG-0033 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let projected = try project(fixture)
                var tokens = [String]()
                for vertex in projected {
                    for component in [vertex.column, vertex.row, vertex.depth] {
                        tokens.append(
                            hexadecimal(component.bitPattern, width: 16)
                        )
                        payload.append(
                            contentsOf: littleEndianBytes(component.bitPattern)
                        )
                    }
                }
                records.append(
                    "\(fixture.name)|vertices=\(projected.count)"
                        + "|bits=\(tokens.joined(separator: ","))"
                )
            } catch let error as SurfaceProjectionError {
                records.append("\(fixture.name)|error=\(errorName(error))")
            }
        }

        #expect(records.count == 12)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "cbb73b21b0a3789aa46c08f3195893e7329b376b0c9639fa06ec60459cb39a38"
        )
        #expect(
            sha256(payload)
                == "6171752e014b1a05774b15739faf44e5222764f18ebda7f4de6749674127e017"
        )
    }

    @Test(
        "[Unit][VOX-SUR-001][VOX-NUM-001] the frozen conventions hold exactly"
    )
    func frozenConventionsHoldExactly() throws {
        let identity = try project(baseFixture())
        // The origin lands at the exact viewport centre of a 4x3 viewport.
        #expect(identity[0].column == 2)
        #expect(identity[0].row == 1.5)
        // Depth is measured along forward, positive in front of the camera.
        #expect(identity[0].depth == 10)

        // Repeated execution is bit-identical.
        let repeated = try project(baseFixture())
        #expect(
            repeated.map(\.column.bitPattern)
                == identity.map(\.column.bitPattern)
        )

        // Square pixels are height-derived: an 8x2 viewport does not stretch.
        let wide = try project(
            baseFixture(planeHeight: 2, width: 8, height: 2)
        )
        #expect(wide[0].column == 4)
        #expect(wide[0].row == 1)

        // A vertex behind the camera is admitted with negative depth.
        let behind = try project(
            baseFixture(matrix: translation(x: 0, y: 0, z: 20))
        )
        #expect(behind[0].depth == -10)

        // A singular placement collapses every vertex onto one point.
        var collapsedMatrix = identityElements
        collapsedMatrix[0] = 0
        collapsedMatrix[5] = 0
        collapsedMatrix[10] = 0
        let collapsed = try project(baseFixture(matrix: collapsedMatrix))
        #expect(collapsed[0] == collapsed[1])
        #expect(collapsed[1] == collapsed[2])

        // An empty mesh projects to no vertices and is not a failure.
        #expect(try project(baseFixture(positions: [])).isEmpty)
    }

    @Test(
        "[Unit][VOX-SUR-001][VOX-ERR-001] failure precedence and cancellation are exact"
    )
    func failurePrecedenceAndCancellationAreExact() throws {
        // Perspective is rejected before any arithmetic runs.
        #expect(throws: SurfaceProjectionError.unsupportedProjection) {
            try self.project(self.baseFixture(perspective: true))
        }

        // An overflowing placement fails representably.
        var overflowMatrix = identityElements
        overflowMatrix[0] = .greatestFiniteMagnitude
        overflowMatrix[3] = .greatestFiniteMagnitude
        #expect(throws: SurfaceProjectionError.positionNotRepresentable) {
            try self.project(self.baseFixture(matrix: overflowMatrix))
        }

        // Cancellation at admission precedes the projection check, so a
        // cancelled perspective request reports cancellation.
        #expect(throws: SurfaceProjectionError.cancelled) {
            try self.project(
                self.baseFixture(perspective: true),
                cancellation: { $0 == .admission }
            )
        }

        // The poll set is admission plus vertex ordinals divisible by 4,096.
        var positions = ContiguousArray<Double>()
        positions.reserveCapacity(8_193 * 3)
        for index in 0..<8_193 {
            positions.append(contentsOf: [Double(index % 7), 0, 0])
        }
        let log = CheckpointLog()
        let projected = try project(
            baseFixture(positions: positions),
            cancellation: { checkpoint in
                log.record(checkpoint)
                return false
            }
        )
        #expect(projected.count == 8_193)
        #expect(
            log.checkpoints == [
                .admission, .vertex(0), .vertex(4_096), .vertex(8_192),
            ]
        )
        for ordinal in [UInt64(0), 4_096, 8_192] {
            #expect(throws: SurfaceProjectionError.cancelled) {
                try self.project(
                    self.baseFixture(positions: positions),
                    cancellation: { $0 == .vertex(ordinal) }
                )
            }
        }
        // A non-poll ordinal is never observed, so it cannot cancel.
        #expect(
            try project(
                baseFixture(positions: positions),
                cancellation: { $0 == .vertex(1) }
            ).count == 8_193
        )

        let errors: [SurfaceProjectionError] = [
            .unsupportedProjection,
            .positionNotRepresentable,
            .cancelled,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "unsupportedProjection",
                "positionNotRepresentable",
                "cancelled",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private let identityElements: [Double] = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ]

    private let unitTriangle: ContiguousArray<Double> = [
        0, 0, 0,
        1, 0, 0,
        0, 1, 0,
    ]

    private func baseFixture(
        name: String = "identity-front",
        positions: ContiguousArray<Double>? = nil,
        matrix: [Double]? = nil,
        position: (Double, Double, Double) = (0, 0, 10),
        target: (Double, Double, Double) = (0, 0, 0),
        up: (Double, Double, Double) = (0, 1, 0),
        planeHeight: Double = 4,
        width: Int = 4,
        height: Int = 3,
        perspective: Bool = false
    ) -> Fixture {
        Fixture(
            name: name,
            positions: positions ?? unitTriangle,
            matrix: matrix ?? identityElements,
            position: position,
            target: target,
            up: up,
            planeHeight: planeHeight,
            width: width,
            height: height,
            perspective: perspective
        )
    }

    private func translation(
        x: Double,
        y: Double,
        z: Double
    ) -> [Double] {
        var elements = identityElements
        elements[3] = x
        elements[7] = y
        elements[11] = z
        return elements
    }

    private func analyticalFixtures() -> [Fixture] {
        var collapsedMatrix = identityElements
        collapsedMatrix[0] = 0
        collapsedMatrix[5] = 0
        collapsedMatrix[10] = 0
        var scaledMatrix = identityElements
        scaledMatrix[0] = 2
        scaledMatrix[5] = 2
        scaledMatrix[10] = 2
        var orderMatrix = identityElements
        orderMatrix[0] = 1e16
        orderMatrix[1] = -1e16
        orderMatrix[2] = 1
        var overflowMatrix = identityElements
        overflowMatrix[0] = .greatestFiniteMagnitude
        overflowMatrix[3] = .greatestFiniteMagnitude
        let contractionValue = 0x1.0000002p0
        return [
            baseFixture(),
            baseFixture(
                name: "translated",
                matrix: translation(x: 1, y: 2, z: 3)
            ),
            baseFixture(
                name: "wide-viewport",
                planeHeight: 2,
                width: 8,
                height: 2
            ),
            baseFixture(
                name: "behind-camera",
                matrix: translation(x: 0, y: 0, z: 20)
            ),
            baseFixture(name: "collapsed-placement", matrix: collapsedMatrix),
            baseFixture(name: "scaled-placement", matrix: scaledMatrix),
            baseFixture(
                name: "oblique-camera",
                position: (3, 4, 5),
                up: (0, 0, 1)
            ),
            baseFixture(
                name: "grouping-sensitive",
                positions: [1, 1, 1],
                matrix: orderMatrix
            ),
            baseFixture(
                name: "contraction-sensitive",
                up: (contractionValue, 1, 0)
            ),
            baseFixture(name: "empty", positions: []),
            baseFixture(name: "placement-overflow", matrix: overflowMatrix),
            baseFixture(name: "perspective", perspective: true),
        ]
    }

    // MARK: - Helpers

    private func project(
        _ fixture: Fixture,
        cancellation: SurfaceVertexProjectionProbe = { _ in false }
    ) throws -> ContiguousArray<ProjectedVertex> {
        let space = try coordinateSpace()
        let vertexCount = fixture.positions.count / 3
        let domain = try TriangleMeshPositionDomain(
            coordinateSpace: space,
            components: fixture.positions
        )
        let mesh = try TriangleMesh(
            positions: domain,
            topology: try TriangleMeshTopology(
                vertexCount: vertexCount,
                indices: vertexCount >= 3 ? [0, 1, 2] : []
            ),
            vertexAttributes: []
        )
        let layer = try SurfaceLayer(
            mesh: mesh,
            objectToWorld: try Matrix4x4Double(elements: fixture.matrix),
            worldSpace: space,
            opacity: 1,
            material: .diagnostic
        )
        let camera = try RenderCamera(
            position: try Point3D(
                x: fixture.position.0,
                y: fixture.position.1,
                z: fixture.position.2,
                coordinateSpace: space.id
            ),
            target: try Point3D(
                x: fixture.target.0,
                y: fixture.target.1,
                z: fixture.target.2,
                coordinateSpace: space.id
            ),
            up: try Vector3D(
                x: fixture.up.0,
                y: fixture.up.1,
                z: fixture.up.2,
                coordinateSpace: space.id
            ),
            projection: fixture.perspective
                ? .perspective(verticalFieldOfViewRadians: 1)
                : .orthographic(planeHeight: fixture.planeHeight)
        )
        return try SurfaceVertexProjector.project(
            layer: layer,
            camera: camera,
            viewport: try ViewportSize(
                width: fixture.width,
                height: fixture.height
            ),
            cancellation: cancellation
        )
    }

    private func coordinateSpace() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "projector-world")),
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

    private func errorName(_ error: SurfaceProjectionError) -> String {
        switch error {
        case .unsupportedProjection: "unsupportedProjection"
        case .positionNotRepresentable: "positionNotRepresentable"
        case .cancelled: "cancelled"
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

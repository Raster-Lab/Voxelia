// SPDX-License-Identifier: MIT

import Testing
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("AppleAdapterSeam")
struct AppleAdapterSeamTests {
    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    @Test("[Unit][VOX-ADP-001][VOX-ADP-002] the spatial seam is implementable and declared")
    func theSpatialSeamIsImplementableAndDeclared() throws {
        struct StubEntity: Equatable {
            let kind: String
        }
        struct StubAdapter: SpatialPresentationAdapter {
            let adapterIdentity = "org.voxelia.test.spatial-adapter/1.0.0"
            let isAvailable = true

            func spatialEntity(for mesh: TriangleMesh) throws -> StubEntity {
                StubEntity(kind: "mesh-\(mesh.topology.triangleCount)")
            }
            func spatialEntity(
                for annotation: SpatialAnnotation
            ) throws -> StubEntity {
                StubEntity(kind: "annotation-\(annotation.label)")
            }
        }
        let mesh = try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: try space(),
                components: [0, 0, 0, 1, 0, 0, 0, 1, 0]
            ),
            topology: try TriangleMeshTopology(vertexCount: 3, indices: [0, 1, 2]),
            vertexAttributes: []
        )
        let adapter = StubAdapter()
        // Availability is the adapter's own declared report.
        #expect(adapter.isAvailable)
        #expect(try adapter.spatialEntity(for: mesh) == StubEntity(kind: "mesh-1"))
        let annotation = try SpatialAnnotation(
            anchor: try Point3D(
                x: 1,
                y: 2,
                z: 3,
                coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
            ),
            label: "lesion-1"
        )
        #expect(
            try adapter.spatialEntity(for: annotation)
                == StubEntity(kind: "annotation-lesion-1")
        )
        #expect(throws: AppleAdapterError.emptyAnnotationLabel) {
            _ = try SpatialAnnotation(
                anchor: annotation.anchor,
                label: "  "
            )
        }
    }

    @Test("[Unit][VOX-ADP-004] the media seam is two-dimensional by type")
    func theMediaSeamIsTwoDimensionalByType() throws {
        struct StubImage: Equatable {
            let width: Int
            let height: Int
            let byteCount: Int
        }
        struct StubAdapter: TwoDimensionalMediaAdapter {
            let adapterIdentity = "org.voxelia.test.media-adapter/1.0.0"

            func image(
                rawPixels: ContiguousArray<UInt8>,
                width: Int,
                height: Int
            ) throws -> StubImage {
                StubImage(width: width, height: height, byteCount: rawPixels.count)
            }
        }
        // No volume, scene or camera exists in the signature: the
        // two-dimensional limitation is the only thing expressible.
        let image = try StubAdapter().image(
            rawPixels: [0, 1, 2, 3],
            width: 2,
            height: 2
        )
        #expect(image == StubImage(width: 2, height: 2, byteCount: 4))
    }
}

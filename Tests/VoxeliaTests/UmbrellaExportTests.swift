// SPDX-License-Identifier: MIT

import Testing
import Voxelia

/// The `ADR-0406` witness: importing only `Voxelia` grants the eight
/// stable modules' vocabulary — the umbrella genuinely re-exports.
/// The optional integrations are not dependencies of the umbrella
/// target, so their non-re-export is structural.
@Suite("UmbrellaExport")
struct UmbrellaExportTests {
    @Test("[Unit][VOX-REP-007] one import grants every stable module's vocabulary")
    func oneImportGrantsEveryStableModulesVocabulary() throws {
        // VoxeliaSpatial.
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let point = try Point3D(x: 1, y: 2, z: 3, coordinateSpace: space)
        #expect(point.x == 1)
        // VoxeliaCore.
        let shape = try ImageShape(extents: [2, 2])
        #expect(shape.rank == 2)
        // VoxeliaStorage.
        let binding = try LogicalSampleBinding(
            shape: shape,
            scalarType: .uint8,
            componentCount: 1
        )
        _ = binding
        // VoxeliaExecution.
        _ = WorkPartition.frameRange(0...1)
        // VoxeliaImaging.
        _ = MPRPlane.self
        // VoxeliaGeometry.
        let topology = try TriangleMeshTopology(vertexCount: 0, indices: [])
        #expect(topology.triangleCount == 0)
        // VoxeliaRendering.
        _ = OutputDynamicRange.sdr
        // VoxeliaInteraction.
        let counter = RenderGenerationCounter()
        _ = counter
    }
}

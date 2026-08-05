// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("VolumeRenderRequest")
struct VolumeRenderRequestTests {
    @Test("[Unit][VOX-DVR-001] the request and widened claims carry exact identity")
    func requestAndWidenedClaimsCarryExactIdentity() throws {
        // The ADR-0174 vocabulary: the closed request value and the
        // additive render-mode and colour-output cases.
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        var entries = ContiguousArray<TransferFunctionEntry>()
        for index in 0..<256 {
            let level = UInt8(index)
            entries.append(
                TransferFunctionEntry(
                    red: level,
                    green: level,
                    blue: level,
                    opacity: level
                )
            )
        }
        let request = VolumeRenderRequest(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
            table: try TransferFunction1D(entries: entries),
            camera: try RenderCamera(
                position: try Point3D(x: 1, y: 1, z: -5, coordinateSpace: space),
                target: try Point3D(x: 1, y: 1, z: 1, coordinateSpace: space),
                up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
                projection: .orthographic(planeHeight: 4)
            ),
            viewport: try ViewportSize(width: 2, height: 2),
            quality: "org.voxelia.quality.full",
            lighting: .none,
            clip: nil,
            crop: nil
        )
        #expect(request.volumeObjectID.rawValue == "volume-7")
        #expect(request.quality == "org.voxelia.quality.full")
        #expect(request == request)

        #expect(VolumeLightingModel.headlight != VolumeLightingModel.none)
        #expect(RenderMode.volumeDirect != RenderMode.slice)
        #expect(
            ColourOutputConfiguration.rgba8
                != ColourOutputConfiguration.greyscale8
        )
        requireSendable(VolumeRenderRequest.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}

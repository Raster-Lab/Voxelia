// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("CameraSerialisation")
struct CameraSerialisationTests {
    @Test("[Unit][VOX-INT-003] the camera round-trips through its own admission")
    func theCameraRoundTripsThroughItsOwnAdmission() throws {
        let space = try #require(CoordinateSpaceID(rawValue: "patient"))
        let camera = try RenderCamera(
            position: try Point3D(x: 10, y: -20, z: 300, coordinateSpace: space),
            target: try Point3D(x: 0, y: 0, z: 0, coordinateSpace: space),
            up: try Vector3D(x: 0, y: 1, z: 0, coordinateSpace: space),
            projection: .perspective(verticalFieldOfViewRadians: 0.75)
        )
        let encoded = try JSONEncoder().encode(camera)
        let decoded = try JSONDecoder().decode(RenderCamera.self, from: encoded)
        #expect(decoded == camera)

        // Decode revalidates: a tampered wire form with a degenerate
        // view direction refuses with the camera's own typed error.
        var json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        json["target"] = json["position"]
        let tampered = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: RenderModelError.degenerateViewDirection) {
            _ = try JSONDecoder().decode(RenderCamera.self, from: tampered)
        }
    }
}

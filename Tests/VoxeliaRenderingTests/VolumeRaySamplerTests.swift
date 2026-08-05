// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("VolumeRaySampler")
struct VolumeRaySamplerTests {
    private func space(id: String = "patient") throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: id)),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func geometry(
        diagonal: Double,
        imageAxes: [Int] = [0, 1, 2]
    ) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: imageAxes),
            indexToWorld: try Matrix4x4Double(elements: [
                diagonal, 0, 0, 0,
                0, diagonal, 0, 0,
                0, 0, diagonal, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: try space()
        )
    }

    private func ray(
        _ x: Double, _ y: Double, _ z: Double,
        spaceID: String = "patient"
    ) throws -> Ray3D {
        let id = try #require(CoordinateSpaceID(rawValue: spaceID))
        return try Ray3D(
            origin: try Point3D(x: x, y: y, z: z, coordinateSpace: id),
            direction: try Vector3D(x: 1, y: 0, z: 0, coordinateSpace: id)
        )
    }

    @Test("[Unit][VOX-DVR-002][VOX-DVR-003] the frozen plans reproduce the fixtures")
    func frozenPlansReproduceTheFixtures() throws {
        // The ALG-0022 fixtures: the axis ray, the miss, the
        // scaled-spacing ray and the inside camera — every value an
        // exact dyadic, repetition bit-identical.
        let identity = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: nil,
            crop: nil
        )
        let axis = try identity.plan(for: try ray(-2, 1, 1))
        #expect(axis.entryDistance == 1.5)
        #expect(axis.exitDistance == 4.5)
        #expect(axis.interval == 0.5)
        #expect(axis.sampleCount == 6)
        #expect(axis.sampleDistance(at: 0) == 1.75)
        #expect(axis.sampleDistance(at: 5) == 4.25)
        #expect(axis.indexPosition(at: 0) == [-0.25, 1, 1])

        let miss = try identity.plan(for: try ray(-2, 5, 1))
        #expect(miss.sampleCount == 0)

        let scaled = try VolumeRaySampler(
            geometry: try geometry(diagonal: 2),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: nil,
            crop: nil
        )
        let widened = try scaled.plan(for: try ray(-3, 1, 1))
        #expect(widened.entryDistance == 2)
        #expect(widened.exitDistance == 8)
        #expect(widened.interval == 1)
        #expect(widened.sampleCount == 6)
        #expect(widened.sampleDistance(at: 0) == 2.5)
        #expect(widened.sampleDistance(at: 5) == 7.5)

        let inside = try identity.plan(for: try ray(1, 1, 1))
        #expect(inside.entryDistance == 0)
        #expect(inside.exitDistance == 1.5)
        #expect(inside.sampleCount == 3)
        #expect(inside.sampleDistance(at: 1) == 0.75)

        #expect(try identity.plan(for: try ray(-2, 1, 1)) == axis)
    }

    private func clip(
        _ minimum: (Double, Double, Double),
        _ maximum: (Double, Double, Double),
        spaceID: String = "patient"
    ) throws -> VolumeClipBounds {
        let id = try #require(CoordinateSpaceID(rawValue: spaceID))
        return try VolumeClipBounds(
            minimum: try Point3D(
                x: minimum.0,
                y: minimum.1,
                z: minimum.2,
                coordinateSpace: id
            ),
            maximum: try Point3D(
                x: maximum.0,
                y: maximum.1,
                z: maximum.2,
                coordinateSpace: id
            )
        )
    }

    @Test("[Unit][VOX-DVR-009] clip and crop restrict the interval per the fixtures")
    func clipAndCropRestrictTheIntervalPerTheFixtures() throws {
        // The ADR-0178 fixtures: the clipped interval, the behind and
        // parallel-outside empties, the tightened crop, and the
        // all-containing identity against the unclipped plan.
        let unclipped = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: nil,
            crop: nil
        )
        let baseline = try unclipped.plan(for: try ray(-2, 1, 1))

        let clipped = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: try clip((0.5, -10, -10), (1.5, 10, 10)),
            crop: nil
        )
        let restricted = try clipped.plan(for: try ray(-2, 1, 1))
        #expect(restricted.entryDistance == 2.5)
        #expect(restricted.exitDistance == 3.5)
        #expect(restricted.sampleCount == 2)
        #expect(restricted.sampleDistance(at: 0) == 2.75)
        #expect(restricted.sampleDistance(at: 1) == 3.25)

        let behind = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: try clip((-4, -10, -10), (-3, 10, 10)),
            crop: nil
        )
        #expect(try behind.plan(for: try ray(-2, 1, 1)).sampleCount == 0)

        let outside = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: try clip((-10, 5, -10), (10, 6, 10)),
            crop: nil
        )
        #expect(try outside.plan(for: try ray(-2, 1, 1)).sampleCount == 0)

        let cropped = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: nil,
            crop: try ImageRegion(lowerBounds: [1, 0, 0], upperBounds: [3, 3, 3])
        )
        let tightened = try cropped.plan(for: try ray(-2, 1, 1))
        #expect(tightened.entryDistance == 2.5)
        #expect(tightened.exitDistance == 4.5)
        #expect(tightened.sampleCount == 4)
        #expect(tightened.sampleDistance(at: 0) == 2.75)
        #expect(tightened.sampleDistance(at: 3) == 4.25)

        let containing = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: try clip((-100, -100, -100), (100, 100, 100)),
            crop: nil
        )
        #expect(try containing.plan(for: try ray(-2, 1, 1)) == baseline)
    }

    @Test("[Unit][VOX-DVR-009][VOX-ERR-001] clip and crop admissions reject typed")
    func clipAndCropAdmissionsRejectTyped() throws {
        #expect(throws: VolumeRaySamplingError.clipCoordinateSpaceMismatch) {
            try VolumeRaySampler(
                geometry: try self.geometry(diagonal: 1),
                extents: [3, 3, 3],
                quality: VolumeRaySampler.fullQualityToken,
                clip: try self.clip((0, 0, 0), (1, 1, 1), spaceID: "device"),
                crop: nil
            )
        }
        #expect(throws: VolumeRaySamplingError.invalidCropRegion) {
            try VolumeRaySampler(
                geometry: try self.geometry(diagonal: 1),
                extents: [3, 3, 3],
                quality: VolumeRaySampler.fullQualityToken,
                clip: nil,
                crop: try ImageRegion(
                    lowerBounds: [0, 0, 0],
                    upperBounds: [4, 3, 3]
                )
            )
        }
        #expect(throws: RenderModelError.invalidClipBounds) {
            try self.clip((1, 0, 0), (1, 1, 1))
        }
    }

    @Test("[Unit][VOX-ERR-001] sampler admissions reject typed")
    func samplerAdmissionsRejectTyped() throws {
        #expect(throws: VolumeRaySamplingError.invalidVolumeExtents) {
            try VolumeRaySampler(
                geometry: try self.geometry(diagonal: 1),
                extents: [3, 3],
                quality: VolumeRaySampler.fullQualityToken,
                clip: nil,
                crop: nil
            )
        }
        #expect(throws: VolumeRaySamplingError.unsupportedVolumeMapping) {
            try VolumeRaySampler(
                geometry: try self.geometry(diagonal: 1, imageAxes: [0, 1]),
                extents: [3, 3, 3],
                quality: VolumeRaySampler.fullQualityToken,
                clip: nil,
                crop: nil
            )
        }
        #expect(throws: VolumeRaySamplingError.unsupportedQualityPolicy) {
            try VolumeRaySampler(
                geometry: try self.geometry(diagonal: 1),
                extents: [3, 3, 3],
                quality: "org.voxelia.quality.interactive",
                clip: nil,
                crop: nil
            )
        }
        let sampler = try VolumeRaySampler(
            geometry: try geometry(diagonal: 1),
            extents: [3, 3, 3],
            quality: VolumeRaySampler.fullQualityToken,
            clip: nil,
            crop: nil
        )
        #expect(throws: AffineWorldToIndexError.coordinateSpaceMismatch) {
            try sampler.plan(for: try self.ray(-2, 1, 1, spaceID: "device"))
        }
    }
}

// SPDX-License-Identifier: MIT

import Testing
import VoxeliaSpatial

@testable import VoxeliaRendering

@Suite("CameraRelativeFloatTransform")
struct CameraRelativeFloatTransformTests {
    private struct DeterministicGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }

        mutating func unit() -> Double {
            Double(next() >> 11) * 0x1p-53
        }
    }

    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    /// A strictly diagonally dominant rotation-scale block, so the
    /// determinant admission holds for every generated sample.
    private func geometry(
        translationScale: Double,
        using generator: inout DeterministicGenerator
    ) throws -> AffineGridGeometry {
        var elements = [Double](repeating: 0, count: 16)
        for row in 0...2 {
            for column in 0...2 {
                elements[4 * row + column] =
                    row == column
                    ? 0.5 + 2.0 * generator.unit()
                    : -0.2 + 0.4 * generator.unit()
            }
            elements[4 * row + 3] =
                (generator.unit() - 0.5) * 2.0 * translationScale
        }
        elements[15] = 1
        return try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: elements),
            coordinateSpace: try space()
        )
    }

    @Test("[Unit][VOX-SPA-004][VOX-ARC-008] the verified bound holds across regimes")
    func verifiedBoundHoldsAcrossRegimes() throws {
        // Thousands of deterministic samples across small- and
        // large-coordinate regimes: every row of every sample must
        // satisfy the specification's γ5 bound against the binary64
        // reference; the maximum observed ratio is reported evidence.
        var generator = DeterministicGenerator(state: 0xF10A_75)
        var checkedRows = 0
        var maximumRatio = 0.0
        for regimeScale in [100.0, 1_000_000.0] {
            for _ in 0..<100 {
                let geometry = try geometry(
                    translationScale: regimeScale,
                    using: &generator
                )
                let camera = try Point3D(
                    x: (generator.unit() - 0.5) * 2.0 * regimeScale,
                    y: (generator.unit() - 0.5) * 2.0 * regimeScale,
                    z: (generator.unit() - 0.5) * 2.0 * regimeScale,
                    coordinateSpace: try #require(
                        CoordinateSpaceID(rawValue: "patient")
                    )
                )
                let transform = try CameraRelativeFloatTransform(
                    geometry: geometry,
                    cameraPosition: camera
                )
                let repeated = try CameraRelativeFloatTransform(
                    geometry: geometry,
                    cameraPosition: camera
                )
                #expect(transform.elements == repeated.elements)

                for _ in 0..<25 {
                    let i0 = Double(generator.next() % 512)
                    let i1 = Double(generator.next() % 512)
                    let i2 = Double(generator.next() % 512)
                    let produced = transform.apply(
                        Float(i0), Float(i1), Float(i2)
                    )
                    let reference = transform.reference(i0, i1, i2)
                    let bounds = transform.errorBound(i0, i1, i2)
                    let differences = [
                        abs(Double(produced.0) - reference.0),
                        abs(Double(produced.1) - reference.1),
                        abs(Double(produced.2) - reference.2),
                    ]
                    for row in 0...2 {
                        #expect(differences[row] <= bounds[row])
                        if bounds[row] > 0 {
                            maximumRatio = max(
                                maximumRatio,
                                differences[row] / bounds[row]
                            )
                        }
                        checkedRows += 1
                    }
                }
            }
        }
        #expect(checkedRows == 2 * 100 * 25 * 3)
        print(
            "ADR-0087 bound evidence: \(checkedRows) rows, max ratio \(maximumRatio)"
        )
        #expect(maximumRatio <= 1)

        requireSendable(CameraRelativeFloatTransform.self)
    }

    @Test("[Unit][VOX-SPA-004][VOX-ERR-001] the camera-relative order defeats cancellation")
    func cameraRelativeOrderDefeatsCancellation() throws {
        // In the large-coordinate regime the naive order — demoting the
        // world translation before the camera subtraction — violates
        // the bound the registered derivation satisfies, which is
        // exactly why the derivation order is frozen.
        var generator = DeterministicGenerator(state: 0xCA11CE)
        let geometry = try geometry(
            translationScale: 1_000_000,
            using: &generator
        )
        // The realistic case: the camera sits near the world content,
        // so the camera-relative translation is small and the bound is
        // tight — exactly where naive world-space demotion loses the
        // large-coordinate cancellation.
        let worldTranslation = geometry.indexToWorld.elements
        let camera = try Point3D(
            x: worldTranslation[3] + 137.5,
            y: worldTranslation[7] - 89.25,
            z: worldTranslation[11] + 211.75,
            coordinateSpace: try #require(CoordinateSpaceID(rawValue: "patient"))
        )
        let transform = try CameraRelativeFloatTransform(
            geometry: geometry,
            cameraPosition: camera
        )
        let cameraComponents = [camera.x, camera.y, camera.z]
        var naiveViolations = 0
        for _ in 0..<50 {
            let i0 = Double(generator.next() % 512)
            let i1 = Double(generator.next() % 512)
            let i2 = Double(generator.next() % 512)
            let referenceTuple = transform.reference(i0, i1, i2)
            let reference = [referenceTuple.0, referenceTuple.1, referenceTuple.2]
            let bounds = transform.errorBound(i0, i1, i2)
            let registered = transform.apply(Float(i0), Float(i1), Float(i2))
            let registeredDifferences = [
                abs(Double(registered.0) - reference[0]),
                abs(Double(registered.1) - reference[1]),
                abs(Double(registered.2) - reference[2]),
            ]
            for row in 0...2 {
                #expect(registeredDifferences[row] <= bounds[row])
            }

            // The naive order: world-space demotion, camera subtracted
            // last in binary32.
            let m = geometry.indexToWorld.elements
            let index = [Float(i0), Float(i1), Float(i2)]
            for row in 0...2 {
                var naive = Float(m[4 * row + 3])
                for column in 0...2 {
                    naive =
                        naive + Float(m[4 * row + column]) * index[column]
                }
                naive = naive - Float(cameraComponents[row])
                let difference = abs(Double(naive) - reference[row])
                if difference > bounds[row] {
                    naiveViolations += 1
                }
            }
        }
        #expect(naiveViolations > 0)

        // A mismatched camera space rejects typed.
        do {
            _ = try CameraRelativeFloatTransform(
                geometry: geometry,
                cameraPosition: try Point3D(
                    x: 0,
                    y: 0,
                    z: 0,
                    coordinateSpace: try #require(
                        CoordinateSpaceID(rawValue: "detector")
                    )
                )
            )
            #expect(Bool(false), "Expected a space mismatch to be rejected.")
        } catch RenderModelError.coordinateSpaceMismatch {}
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}

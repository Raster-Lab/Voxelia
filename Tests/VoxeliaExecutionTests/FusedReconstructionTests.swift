// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaExecution

@Suite("Fused reconstruction")
struct FusedReconstructionTests {
    @Test(
        "[Unit][VOX-MPR-011][VOX-ERR-001] registration is admitted by exact equality, never a tolerance"
    )
    func registrationIsAdmittedByExactEqualityNeverATolerance() throws {
        let grid = try geometry()

        // Two reconstructions on the same grid in the same space are
        // registered by construction: every output sample of both is the same
        // physical position.
        try FusedReconstruction.admit(
            base: grid,
            overlay: grid,
            baseSampleCount: 4,
            overlaySampleCount: 4
        )

        // A different coordinate space is a different problem from a different
        // grid, so the two are distinct cases.
        #expect(throws: FusedReconstructionError.coordinateSpaceMismatch) {
            try FusedReconstruction.admit(
                base: grid,
                overlay: try geometry(space: "table-world"),
                baseSampleCount: 4,
                overlaySampleCount: 4
            )
        }

        // Exact equality, not a tolerance: one unit in the last place of the
        // translation is a different plane. Deciding how much difference is
        // acceptable is a clinical judgement no accepted record supplies.
        #expect(throws: FusedReconstructionError.gridMismatch) {
            try FusedReconstruction.admit(
                base: grid,
                overlay: try geometry(translationX: 1.0.nextUp),
                baseSampleCount: 4,
                overlaySampleCount: 4
            )
        }
        #expect(throws: FusedReconstructionError.extentMismatch) {
            try FusedReconstruction.admit(
                base: grid,
                overlay: grid,
                baseSampleCount: 4,
                overlaySampleCount: 5
            )
        }

        let errors: [FusedReconstructionError] = [
            .coordinateSpaceMismatch, .gridMismatch, .extentMismatch,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "coordinateSpaceMismatch", "gridMismatch", "extentMismatch",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    @Test(
        "[Unit][VOX-MPR-011][VOX-API-003] fusion composes the accepted overlay model"
    )
    func fusionComposesTheAcceptedOverlayModel() throws {
        let grid = try geometry()
        let baseSamples: [UInt8] = [0, 100, 200, 255]
        let overlaySamples: [UInt8] = [0, 1, 0, 1]
        // A two-entry palette: entry zero black, entry one pure red.
        let red = try table([0, 255])
        let green = try table([0, 0])
        let blue = try table([0, 0])

        // At zero opacity the fused image is the base exactly, so fusion can
        // never alter the anatomy it is drawn over.
        let transparent = try FusedReconstruction.fuse(
            baseSamples: baseSamples,
            overlaySamples: overlaySamples,
            baseGrid: grid,
            overlayGrid: grid,
            red: red,
            green: green,
            blue: blue,
            opacity: 0
        )
        #expect(
            transparent.map(\.red) == baseSamples
        )
        #expect(transparent.allSatisfy { $0.red == $0.green })
        #expect(transparent.allSatisfy { $0.alpha == 255 })

        // At full opacity it is the overlay's palette colour exactly.
        let opaque = try FusedReconstruction.fuse(
            baseSamples: baseSamples,
            overlaySamples: overlaySamples,
            baseGrid: grid,
            overlayGrid: grid,
            red: red,
            green: green,
            blue: blue,
            opacity: 1
        )
        #expect(opaque.map(\.red) == [0, 255, 0, 255])
        #expect(opaque.map(\.green) == [0, 0, 0, 0])

        // A partial opacity agrees with the accepted overlay model directly,
        // rather than with a second arithmetic written here.
        let half = try FusedReconstruction.fuse(
            baseSamples: baseSamples,
            overlaySamples: overlaySamples,
            baseGrid: grid,
            overlayGrid: grid,
            red: red,
            green: green,
            blue: blue,
            opacity: 0.5
        )
        for index in baseSamples.indices {
            let grey = baseSamples[index]
            let expected = try OverlayCompositing.composite(
                base: DisplayPixelRGBA8(
                    red: grey,
                    green: grey,
                    blue: grey,
                    alpha: 255
                ),
                overlays: [
                    Overlay(
                        source: .image(
                            OverlayEntry(
                                red: overlaySamples[index] == 1 ? 255 : 0,
                                green: 0,
                                blue: 0,
                                alpha: 255
                            )
                        ),
                        opacity: 0.5
                    )
                ]
            )
            #expect(half[index] == expected)
        }

        // The admission runs before any fusion, so a mismatched pair never
        // produces a partial image.
        #expect(throws: FusedReconstructionError.coordinateSpaceMismatch) {
            try FusedReconstruction.fuse(
                baseSamples: baseSamples,
                overlaySamples: overlaySamples,
                baseGrid: grid,
                overlayGrid: try geometry(space: "table-world"),
                red: red,
                green: green,
                blue: blue,
                opacity: 1
            )
        }
    }

    // MARK: - Helpers

    private func table(_ values: [Double]) throws -> LookupTableDescriptor {
        try LookupTableDescriptor(
            firstMappedValue: 0,
            values: values,
            outputUnit: nil
        )
    }

    private func geometry(
        space: String = "patient-world",
        translationX: Double = 1.0
    ) throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(
                elements: [
                    1, 0, 0, translationX,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                ]
            ),
            coordinateSpace: try CoordinateSpaceDescriptor(
                id: try #require(CoordinateSpaceID(rawValue: space)),
                convention: .dicomPatientLPS,
                handedness: .unspecified,
                unit: try MeasurementUnit(
                    namespace: "UCUM",
                    code: "mm",
                    dimension: .length
                ),
                externalReferences: []
            )
        )
    }
}

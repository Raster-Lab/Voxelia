// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaGeometry
import VoxeliaSpatial

@testable import VoxeliaRendering

/// `ADR-0285` (`VOX-SUR-004`): the shading normal-space correction.
///
/// `ADR-0280` found that `VOXELIA-ALG-0033` transforms vertex positions into world space
/// while `VOXELIA-ALG-0036` reads object-space normals and dots them against a world-space
/// forward, and quantified the error at `1.000000` where `0.000000` is correct.
///
/// Neither specification was wrong: `ALG-0036` names its inputs without naming a space, and
/// its arithmetic is right for same-space inputs. Both are unedited.
@Suite("SurfaceNormalTransform")
struct SurfaceNormalTransformTests {
    // MARK: - Fixtures

    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "world")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    /// Little-endian binary64, three components per vertex, matching the serialisation
    /// `ADR-0193` froze for the normal attribute.
    private func normalAttribute(
        _ normals: [(Double, Double, Double)]
    ) throws -> TriangleMeshVertexAttribute {
        // Explicit shifts rather than a pointer API: the safety policy forbids those, and
        // the encoding is stated here rather than delegated to memory layout.
        var bytes = ContiguousArray<UInt8>()
        for normal in normals {
            for component in [normal.0, normal.1, normal.2] {
                let pattern = component.bitPattern
                for byte in 0..<8 {
                    bytes.append(UInt8(truncatingIfNeeded: pattern >> (8 * byte)))
                }
            }
        }
        return try TriangleMeshVertexAttribute(
            descriptor: try GeometryAttributeDescriptor(
                semantic: .normal,
                scalarFormat: try ScalarFormat(
                    type: .float64,
                    validBitCount: nil,
                    byteOrder: .littleEndian
                ),
                components: try ComponentDescriptor(
                    count: 3,
                    interpretation: .vector,
                    layout: .interleaved
                ),
                elementCount: normals.count
            ),
            bytes: bytes
        )
    }

    private func mesh(
        normals: [(Double, Double, Double)]
    ) throws -> TriangleMesh {
        try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: try space(),
                components: [0, 0, 0, 1, 0, 0, 0, 1, 0]
            ),
            topology: try TriangleMeshTopology(vertexCount: 3, indices: [0, 1, 2]),
            vertexAttributes: [try normalAttribute(normals)]
        )
    }

    private func affine(_ block: [Double]) throws -> Matrix4x4Double {
        try Matrix4x4Double(elements: [
            block[0], block[1], block[2], 0,
            block[3], block[4], block[5], 0,
            block[6], block[7], block[8], 0,
            0, 0, 0, 1,
        ])
    }

    private func unit(_ x: Double, _ y: Double, _ z: Double) -> (Double, Double, Double) {
        let length = ((x * x + y * y) + z * z).squareRoot()
        return (x / length, y / length, z / length)
    }

    // MARK: - ADR-0280's finding, as a test

    @Test("[Unit][VOX-SUR-004] an object-space normal shades wrongly under rotation")
    func objectSpaceNormalShadesWronglyUnderRotation() throws {
        // `ADR-0280`'s measurement, reproduced: a facet whose normal faces the camera in
        // object space is rotated ninety degrees away in world space. Shading the untransformed
        // normal reports fully lit; shading the transformed one reports fully unlit, which
        // is correct. The maximum possible error for a value bounded in zero to one.
        let normals = [(0.0, 0.0, 1.0), (0.0, 0.0, 1.0), (0.0, 0.0, 1.0)]
        let source = try mesh(normals: normals)
        let rotation = try affine([1, 0, 0, 0, 0, -1, 0, 1, 0])
        let forward = ShadingDirection(x: 0, y: 0, z: 1)

        let object = try SurfaceShader.normals(of: source, facetOrdinal: 0)
        let world = try SurfaceNormalTransform.worldNormals(
            of: source, facetOrdinal: 0, objectToWorld: rotation)

        let uncorrected = SurfaceShader.intensity(
            first: object.0, second: object.1, third: object.2,
            weightA: 1, weightB: 0, weightC: 0, swapped: false, forward: forward)
        let corrected = SurfaceShader.intensity(
            first: world.0, second: world.1, third: world.2,
            weightA: 1, weightB: 0, weightC: 0, swapped: false, forward: forward)

        #expect(uncorrected == 1.0)
        #expect(corrected == 0.0)
        #expect(abs(uncorrected - corrected) == 1.0)
    }

    // MARK: - The normalisation-order decision, evidenced

    @Test("[Unit][VOX-SUR-004] normalising before interpolation is not the same as after")
    func normalisingBeforeInterpolationIsNotTheSameAsAfter() throws {
        // `ADR-0285` measured the two orderings 22.37 degrees apart, with intensities
        // differing by 0.29873328108119157. The decision to normalise each transformed
        // normal first is evidenced here rather than asserted, so a later "simplification"
        // to the cheaper ordering fails a test that says why.
        let normals = [unit(0, 1, 1), unit(1, 0, 1), (0.0, 0.0, 1.0)]
        let source = try mesh(normals: normals)
        let anisotropic = try affine([1, 0, 0, 0, 1, 0, 0, 0, 5])
        let forward = ShadingDirection(x: 0, y: 0, z: 1)
        let (weightA, weightB, weightC) = (0.25, 0.35, 0.40)

        // The specified ordering: each transformed normal normalised, then interpolated.
        let world = try SurfaceNormalTransform.worldNormals(
            of: source, facetOrdinal: 0, objectToWorld: anisotropic)
        let specified = SurfaceShader.intensity(
            first: world.0, second: world.1, third: world.2,
            weightA: weightA, weightB: weightB, weightC: weightC,
            swapped: false, forward: forward)

        // The rejected ordering: raw transformed normals, left for the shader to
        // renormalise after interpolating.
        let inverse = try AffineSpatialInverse(spatialPartOf: anisotropic)
        func raw(_ n: (Double, Double, Double)) -> ShadingDirection {
            let t = AffineTransformAlgebra.transformNormal(
                usingInverseOf: inverse, x: n.0, y: n.1, z: n.2)
            return ShadingDirection(x: t[0], y: t[1], z: t[2])
        }
        let rejected = SurfaceShader.intensity(
            first: raw(normals[0]), second: raw(normals[1]), third: raw(normals[2]),
            weightA: weightA, weightB: weightB, weightC: weightC,
            swapped: false, forward: forward)

        #expect(specified != rejected)
        // Registered in `ADR-0285`: nearly thirty per cent of the full range.
        #expect(abs(specified - rejected) > 0.29)
    }

    // MARK: - Nothing that exists today changes

    @Test("[Unit][VOX-SUR-004] the identity transform leaves shading bit-identical")
    func identityTransformLeavesShadingBitIdentical() throws {
        // What makes "nothing existing changes" checkable rather than claimed: under the
        // identity, world-space normals must equal the object-space ones exactly.
        let normals = [unit(0, 1, 1), unit(1, 0, 1), unit(2, 3, 6)]
        let source = try mesh(normals: normals)
        let identity = try affine([1, 0, 0, 0, 1, 0, 0, 0, 1])

        let object = try SurfaceShader.normals(of: source, facetOrdinal: 0)
        let world = try SurfaceNormalTransform.worldNormals(
            of: source, facetOrdinal: 0, objectToWorld: identity)

        #expect(world.0 == object.0)
        #expect(world.1 == object.1)
        #expect(world.2 == object.2)
    }

    @Test("[Unit][VOX-SUR-004] the transformed normal is renormalised")
    func transformedNormalIsRenormalised() throws {
        // `ALG-0036` states its inputs are unit by construction and does not re-admit them,
        // so restoring that is the whole reason normalisation happens here.
        //
        // The case is chosen to be exactly representable rather than asserted with a
        // tolerance: an axis-aligned normal under a diagonal transform scales to
        // `(0, 0, 0.2)`, whose scaled normalisation is exactly `(0, 0, 1)`. Asserting the
        // exact value also distinguishes "normalised" from "returned raw", which a
        // unit-length tolerance would not.
        let source = try mesh(normals: [(0, 0, 1), (0, 0, 1), (0, 0, 1)])
        let anisotropic = try affine([1, 0, 0, 0, 1, 0, 0, 0, 5])
        let world = try SurfaceNormalTransform.worldNormals(
            of: source, facetOrdinal: 0, objectToWorld: anisotropic)

        #expect(world.0 == ShadingDirection(x: 0, y: 0, z: 1))

        // The raw transformed value, shown to differ, so the assertion above is evidence
        // that the normalisation ran rather than that nothing happened.
        let inverse = try AffineSpatialInverse(spatialPartOf: anisotropic)
        let raw = AffineTransformAlgebra.transformNormal(
            usingInverseOf: inverse, x: 0, y: 0, z: 1)
        #expect(Array(raw) == [0, 0, 0.2])
    }

    // MARK: - Failures, all inherited

    @Test("[Unit][VOX-SUR-004] a mesh without normals is refused as before")
    func meshWithoutNormalsIsRefusedAsBefore() throws {
        let bare = try TriangleMesh(
            positions: try TriangleMeshPositionDomain(
                coordinateSpace: try space(),
                components: [0, 0, 0, 1, 0, 0, 0, 1, 0]
            ),
            topology: try TriangleMeshTopology(vertexCount: 3, indices: [0, 1, 2]),
            vertexAttributes: []
        )
        #expect(throws: SurfaceShadingError.normalsMissing) {
            _ = try SurfaceNormalTransform.worldNormals(
                of: bare, facetOrdinal: 0, objectToWorld: try affine([1, 0, 0, 0, 1, 0, 0, 0, 1]))
        }
    }

    @Test("[Unit][VOX-SUR-004] a singular transform surfaces the accepted inverse's error")
    func singularTransformSurfacesTheAcceptedInverseError() throws {
        let source = try mesh(normals: [(0, 0, 1), (0, 0, 1), (0, 0, 1)])
        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            _ = try SurfaceNormalTransform.worldNormals(
                of: source,
                facetOrdinal: 0,
                objectToWorld: try affine([0, 0, 0, 0, 1, 0, 0, 0, 1])
            )
        }
    }

    @Test("[Unit][VOX-SUR-004] a non-affine transform is refused")
    func nonAffineTransformIsRefused() throws {
        let source = try mesh(normals: [(0, 0, 1), (0, 0, 1), (0, 0, 1)])
        let projective = try Matrix4x4Double(elements: [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 1, 1,
        ])
        #expect(throws: AffineTransformError.nonAffineOperand) {
            _ = try SurfaceNormalTransform.worldNormals(
                of: source, facetOrdinal: 0, objectToWorld: projective)
        }
    }
}

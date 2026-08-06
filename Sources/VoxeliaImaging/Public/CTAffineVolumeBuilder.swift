// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// An error raised while constructing a CT affine volume geometry.
///
/// Cases deliberately carry no payload, so a refused construction never
/// discloses source geometry in a diagnostic. Construction throws rather than
/// returning a verdict: assessment is a judgement with degrees, which
/// `CTGeometryValidator` reports, while construction either produces a value or
/// does not.
public enum CTVolumeConstructionError: Error, Sendable, Equatable {
    /// The series was rejected by `CTGeometryValidator`.
    case seriesRejected
    /// The series has fewer than two members, so no slice step can be derived.
    ///
    /// A single-member series is a *warning* in `ADR-0229` because it is a valid
    /// series, and it is still not constructible: there is no second position to
    /// subtract. `ADR-0230` decision 6 records that (c) judges regularity while
    /// (d) judges constructibility, so a series can pass one and fail the other.
    /// No slice thickness is invented to rescue it.
    case sliceStepUndefined
    /// The supplied descriptor names a different coordinate space than the
    /// series, compared on exact UTF-8 bytes.
    case coordinateSpaceMismatch
    /// The series carries a frame-of-reference the descriptor does not list.
    ///
    /// This is how `VOX-DCM-007`'s frame-of-reference preservation reaches the
    /// volume rather than stopping at the series.
    case frameOfReferenceNotPreserved
    /// A computed matrix element overflowed to a non-finite value.
    case nonFiniteTransform
    /// The upper-left determinant magnitude is below
    /// `Double.leastNormalMagnitude`.
    ///
    /// Reachable from a series `CTGeometryValidator` fully approved: in-plane
    /// spacings near `Double.leastNonzeroMagnitude` are admitted by `ADR-0227`
    /// and make the determinant **underflow**. The rejection comes from
    /// `AffineGridGeometry`'s accepted `ADR-0043` admission, which this type
    /// forwards rather than pre-empts.
    case singularTransform
}

/// A constructed CT affine volume geometry and the evidence for its fidelity.
public struct CTVolumeConstruction: Sendable, Hashable {
    /// The accepted spatial geometry, admitted under `ADR-0043`.
    public let geometry: AffineGridGeometry
    /// The largest absolute difference between the position the affine computes
    /// for a slice index and the position the source stated.
    ///
    /// **Not always zero, even for a series the exact tolerance admits.** A
    /// position list built by repeated addition has uniform differences without
    /// lying on a uniform lattice, so a uniform affine can misplace a slice by a
    /// few units in the last place. Fixture D5 of `VOXELIA-ALG-0049` is such a
    /// series. The residual is reported and **not judged**: judging it would need
    /// a threshold, which is the owner gate `ADR-0229` decision 3 named.
    public let fidelityResidual: Double
    /// The warnings carried forward from the geometry assessment.
    ///
    /// Non-empty only for `representableWithWarnings`. The construction proceeds
    /// because both warnings are non-geometric, and the caller still needs to
    /// know about them.
    public let carriedWarnings: Set<CTGeometryFinding>
}

/// The deterministic construction of an affine volume geometry in patient space,
/// implementing `ct-affine-volume/binary64-v1` (`VOXELIA-ALG-0049`) for
/// `VOX-VS1-004` and `VOX-DCM-007`.
///
/// The construction never normalises a direction and never divides. The
/// displacement per slice index is a **vector difference of two stated
/// positions**, so the unit normal — and therefore a square root — is never
/// needed, and no nominal slice spacing has to be chosen.
public enum CTAffineVolumeBuilder {
    /// Builds the index-to-world geometry for `series`.
    ///
    /// - Parameters:
    ///   - series: an assembled series, ordered by projection.
    ///   - assessment: the verdict `CTGeometryValidator` returned for `series`.
    ///   - coordinateSpace: the patient-space descriptor. Required, because
    ///     convention, handedness and unit are not facts a CT frame states.
    /// - Throws: ``CTVolumeConstructionError``.
    public static func build(
        series: CTSeries,
        assessment: CTGeometryAssessment,
        coordinateSpace: CoordinateSpaceDescriptor
    ) throws -> CTVolumeConstruction {
        guard assessment.verdict != .rejected else {
            throw CTVolumeConstructionError.seriesRejected
        }
        guard series.members.count >= 2, let anchor = series.anchor else {
            throw CTVolumeConstructionError.sliceStepUndefined
        }
        guard
            coordinateSpace.id.rawValue.utf8.elementsEqual(
                series.key.coordinateSpace.rawValue.utf8
            )
        else {
            throw CTVolumeConstructionError.coordinateSpaceMismatch
        }
        if let reference = series.key.frameOfReference,
            !coordinateSpace.externalReferences.contains(reference)
        {
            throw CTVolumeConstructionError.frameOfReferenceNotPreserved
        }

        // The column index advances along rowDirection by columnSpacing, and the
        // row index along columnDirection by rowSpacing. The crossing is the
        // ADR-0227 axis convention; reading it backwards transposes the volume
        // silently, which is why the frozen fixtures use distinct spacings.
        let iStep = scaled(anchor.columnSpacingMillimetres, anchor.rowDirection)
        let jStep = scaled(anchor.rowSpacingMillimetres, anchor.columnDirection)

        let first = series.members[0].frame.imagePosition
        let second = series.members[1].frame.imagePosition
        let kStep = (
            x: second.x - first.x,
            y: second.y - first.y,
            z: second.z - first.z
        )

        let elements: [Double] = [
            iStep.x, jStep.x, kStep.x, first.x,
            iStep.y, jStep.y, kStep.y, first.y,
            iStep.z, jStep.z, kStep.z, first.z,
            0, 0, 0, 1,
        ]

        let matrix: Matrix4x4Double
        do {
            matrix = try Matrix4x4Double(elements: elements)
        } catch {
            // The only reachable case is a non-finite element: the count is a
            // literal sixteen.
            throw CTVolumeConstructionError.nonFiniteTransform
        }

        let geometry: AffineGridGeometry
        do {
            geometry = try AffineGridGeometry(
                spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
                indexToWorld: matrix,
                coordinateSpace: coordinateSpace
            )
        } catch SpatialGeometryError.singularTransform {
            throw CTVolumeConstructionError.singularTransform
        }
        // `SpatialGeometryError.nonAffineBottomRow` is unreachable: the bottom
        // row above is the literal `0, 0, 0, 1` the admission requires. The
        // axis mapping is the literal `[0, 1, 2]`, so its validation cannot
        // fail either. Both are discharged rather than mapped to a case this
        // type would never throw.

        return CTVolumeConstruction(
            geometry: geometry,
            fidelityResidual: fidelityResidual(
                series: series,
                origin: (first.x, first.y, first.z),
                kStep: (kStep.x, kStep.y, kStep.z)
            ),
            carriedWarnings: assessment.findings.filter { !$0.rejects }
        )
    }

    /// Componentwise scaling in the frozen expression order.
    private static func scaled(
        _ scalar: Double,
        _ vector: Vector3D
    ) -> (x: Double, y: Double, z: Double) {
        (x: scalar * vector.x, y: scalar * vector.y, z: scalar * vector.z)
    }

    /// The largest absolute difference between the affine's computed slice
    /// position and the position the source stated, in the frozen expression
    /// order.
    private static func fidelityResidual(
        series: CTSeries,
        origin: (Double, Double, Double),
        kStep: (Double, Double, Double)
    ) -> Double {
        var worst = 0.0
        for (index, member) in series.members.enumerated() {
            let k = Double(index)
            let position = member.frame.imagePosition
            for (originAxis, stepAxis, stated) in [
                (origin.0, kStep.0, position.x),
                (origin.1, kStep.1, position.y),
                (origin.2, kStep.2, position.z),
            ] {
                let computed = originAxis + (k * stepAxis)
                worst = Swift.max(worst, abs(computed - stated))
            }
        }
        return worst
    }
}

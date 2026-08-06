// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// The thresholds a series is judged by, per `ADR-0229`.
///
/// A tolerance is a **clinical safety parameter**, not a library constant, so it
/// is supplied rather than assumed and it appears nowhere in the measurement
/// arithmetic of `VOXELIA-ALG-0048`.
///
/// Only ``exact`` is defined. `ADR-0229` decisions 2 and 3 record why: no
/// permissive threshold this project could set today would be evidence-based,
/// because the one principled source — the source's own stated decimal
/// precision — was discarded when `ADR-0227` chose `Double` values over the
/// original strings. A permissive tolerance requires phantom studies or a
/// characterised scanner corpus, and owner acceptance.
public struct CTGeometryTolerance: Sendable, Hashable {
    /// The largest admissible absolute difference between any direction
    /// component and the anchor's.
    public let orientationComponent: Double
    /// The largest admissible absolute difference in either in-plane spacing.
    public let inPlaneSpacingMillimetres: Double
    /// The largest admissible spread between the smallest and largest slice
    /// spacing.
    public let sliceSpacingMillimetres: Double
    /// The largest admissible absolute orthonormality residual.
    public let orthonormalityResidual: Double

    /// Creates a tolerance from four explicit thresholds.
    public init(
        orientationComponent: Double,
        inPlaneSpacingMillimetres: Double,
        sliceSpacingMillimetres: Double,
        orthonormalityResidual: Double
    ) {
        self.orientationComponent = orientationComponent
        self.inPlaneSpacingMillimetres = inPlaneSpacingMillimetres
        self.sliceSpacingMillimetres = sliceSpacingMillimetres
        self.orthonormalityResidual = orthonormalityResidual
    }

    /// Every threshold zero: only exactly regular geometry is admitted.
    ///
    /// This is less brittle than it sounds. Two different decimal spellings that
    /// round to the same binary64 value differ by *exactly* zero and are
    /// admitted; exact tolerance forgives re-spelling and refuses only values
    /// that land on genuinely different doubles.
    ///
    /// It will nevertheless reject real scanner series whose spacing varies by
    /// physically negligible amounts, which `ADR-0229` decision 5 records as the
    /// intended conservative posture rather than an oversight.
    public static let exact = CTGeometryTolerance(
        orientationComponent: 0,
        inPlaneSpacingMillimetres: 0,
        sliceSpacingMillimetres: 0,
        orthonormalityResidual: 0
    )
}

/// The exact measurements `VOXELIA-ALG-0048` defines for one series.
///
/// Every value is a subtraction, a product-sum or a comparison against zero. No
/// threshold takes part in producing any of them, so the numbers a series is
/// judged by are reproducible independently of the judgement applied to them.
public struct CTGeometryMeasurement: Sendable, Hashable {
    /// The number of members measured.
    public let memberCount: Int
    /// The smallest consecutive projection difference.
    ///
    /// Absent for fewer than two members, and absent when the series is not
    /// ordered by projection — differences over an identity-order fallback
    /// measure nothing, and reporting them as spacings would manufacture a
    /// number.
    public let minimumSliceSpacing: Double?
    /// The largest consecutive projection difference, absent as above.
    public let maximumSliceSpacing: Double?
    /// The largest slice spacing minus the smallest, absent as above.
    ///
    /// This is the irregularity measure, deliberately not a deviation from a
    /// nominal spacing: a nominal value would need an arbitrary anchor, or a
    /// mean's division and summation order, or a median's sort and even-count
    /// tie rule.
    public let sliceSpacingSpread: Double?
    /// The largest absolute componentwise difference from the anchor's
    /// directions, taken componentwise rather than as a norm.
    public let maximumOrientationDeviation: Double
    /// The largest absolute difference from the anchor's in-plane spacings.
    public let maximumInPlaneSpacingDeviation: Double
    /// The anchor's row-column dot product; zero when the directions are
    /// orthogonal.
    public let rowColumnDotProduct: Double
    /// The anchor's row squared magnitude minus one; zero when it is a unit
    /// vector.
    public let rowMagnitudeResidual: Double
    /// The anchor's column squared magnitude minus one.
    public let columnMagnitudeResidual: Double
    /// Whether any adjacent pair of members shares a projection exactly.
    public let hasDuplicateProjections: Bool
    /// Whether every member shares the anchor's extents and scalar format.
    public let hasUniformGrid: Bool
}

/// One condition observed about a series' geometry.
///
/// The three assembly observations are **inherited** from `VOXELIA-ALG-0047`
/// rather than recomputed, so that one place establishes each fact.
public enum CTGeometryFinding: Sendable, Hashable, CaseIterable {
    /// The members do not share one sampling grid, so they cannot be one array.
    case nonUniformGrid
    /// Two members occupy the same position along the ordering axis.
    case duplicateProjections
    /// The series holds no members at all.
    ///
    /// `VOXELIA-ALG-0048`'s fixtures do not cover this case, because
    /// ``CTSeriesAssembler`` never produces an empty series — but ``CTSeries``
    /// has a public initialiser, so the case is reachable and is given a
    /// deterministic rejecting result rather than being left to fall through as
    /// representable.
    case emptySeries
    /// The series holds exactly one member, so it has no slice spacing.
    case singleMemberSeries
    /// A member's directions differ from the anchor's beyond tolerance.
    case orientationDisagreement
    /// A member's in-plane spacing differs from the anchor's beyond tolerance.
    case inPlaneSpacingDisagreement
    /// The slice spacings vary beyond tolerance.
    case sliceSpacingIrregular
    /// The anchor's directions are not orthogonal within tolerance.
    case nonOrthogonalDirections
    /// An anchor direction is not unit length within tolerance.
    case nonUnitDirections
    /// Rescale or photometric terms differ across members.
    ///
    /// Not a geometry fact: contradictory rescale terms make a volume's values
    /// incomparable, which `ADR-0229` decision 10 assigns to the
    /// value-transformation stage `VOX-DCM-006` requires. Reported here so the
    /// condition is visible rather than unowned.
    case presentationDisagreement
    /// Inherited: the reference normal is exactly zero.
    case degenerateReferenceNormal
    /// Inherited: a reference-normal component is not finite.
    case nonFiniteReferenceNormal
    /// Inherited: a member's projection is not finite.
    case nonFiniteProjection

    /// Whether this finding rejects a series rather than warning about it.
    public var rejects: Bool {
        switch self {
        case .singleMemberSeries, .presentationDisagreement:
            false
        case .nonUniformGrid, .duplicateProjections, .emptySeries,
            .orientationDisagreement, .inPlaneSpacingDisagreement,
            .sliceSpacingIrregular, .nonOrthogonalDirections, .nonUnitDirections,
            .degenerateReferenceNormal, .nonFiniteReferenceNormal,
            .nonFiniteProjection:
            true
        }
    }
}

/// Whether a series may be built into a volume.
public enum CTGeometryVerdict: Sendable, Hashable {
    /// No findings at all.
    case representable
    /// Only warning findings.
    case representableWithWarnings
    /// At least one rejecting finding.
    case rejected
}

/// The complete assessment of one series' geometry.
public struct CTGeometryAssessment: Sendable, Hashable {
    /// The exact measurements, reported whether or not they triggered a finding
    /// so that a caller holding its own evidence can apply its own thresholds.
    public let measurement: CTGeometryMeasurement
    /// Every condition observed, warnings and rejections alike.
    public let findings: Set<CTGeometryFinding>
    /// The classification of ``findings``.
    public let verdict: CTGeometryVerdict
}

/// The deterministic geometry assessment of an assembled CT series,
/// implementing `series-geometry-validation/binary64-v1`
/// (`VOXELIA-ALG-0048`) for `VOX-VS1-003` and `VOX-DCM-009`.
///
/// Assessment cannot fail: an unusable series produces a `rejected` verdict with
/// the findings that justify it, never a thrown error, because the caller needs
/// the evidence in order to report which frames were at fault.
public enum CTGeometryValidator {
    /// Measures `series` exactly, then judges it against `tolerance`.
    ///
    /// `tolerance` has no default. `ADR-0229` makes it an explicit input
    /// precisely so that the threshold a series was judged by is visible at
    /// every call site rather than inherited silently.
    public static func assess(
        _ series: CTSeries,
        tolerance: CTGeometryTolerance
    ) -> CTGeometryAssessment {
        let measurement = measure(series)
        var findings: Set<CTGeometryFinding> = []

        // Inherited from assembly, never recomputed.
        for observation in series.observations {
            switch observation {
            case .degenerateReferenceNormal:
                findings.insert(.degenerateReferenceNormal)
            case .nonFiniteReferenceNormal:
                findings.insert(.nonFiniteReferenceNormal)
            case .nonFiniteProjection:
                findings.insert(.nonFiniteProjection)
            }
        }

        if measurement.memberCount == 0 {
            findings.insert(.emptySeries)
        }
        if measurement.memberCount == 1 {
            findings.insert(.singleMemberSeries)
        }
        if !measurement.hasUniformGrid {
            findings.insert(.nonUniformGrid)
        }
        if measurement.hasDuplicateProjections {
            findings.insert(.duplicateProjections)
        }
        if measurement.maximumOrientationDeviation > tolerance.orientationComponent {
            findings.insert(.orientationDisagreement)
        }
        if measurement.maximumInPlaneSpacingDeviation
            > tolerance.inPlaneSpacingMillimetres
        {
            findings.insert(.inPlaneSpacingDisagreement)
        }
        if let spread = measurement.sliceSpacingSpread,
            spread > tolerance.sliceSpacingMillimetres
        {
            findings.insert(.sliceSpacingIrregular)
        }
        if abs(measurement.rowColumnDotProduct) > tolerance.orthonormalityResidual {
            findings.insert(.nonOrthogonalDirections)
        }
        if abs(measurement.rowMagnitudeResidual) > tolerance.orthonormalityResidual
            || abs(measurement.columnMagnitudeResidual)
                > tolerance.orthonormalityResidual
        {
            findings.insert(.nonUnitDirections)
        }
        if !presentationAgrees(series) {
            findings.insert(.presentationDisagreement)
        }

        let verdict: CTGeometryVerdict =
            if findings.contains(where: \.rejects) {
                .rejected
            } else if findings.isEmpty {
                .representable
            } else {
                .representableWithWarnings
            }

        return CTGeometryAssessment(
            measurement: measurement,
            findings: findings,
            verdict: verdict
        )
    }

    // MARK: - Measurement

    private static func measure(_ series: CTSeries) -> CTGeometryMeasurement {
        let members = series.members
        guard let anchor = series.anchor else {
            return CTGeometryMeasurement(
                memberCount: 0,
                minimumSliceSpacing: nil,
                maximumSliceSpacing: nil,
                sliceSpacingSpread: nil,
                maximumOrientationDeviation: 0,
                maximumInPlaneSpacingDeviation: 0,
                rowColumnDotProduct: 0,
                rowMagnitudeResidual: 0,
                columnMagnitudeResidual: 0,
                hasDuplicateProjections: false,
                hasUniformGrid: true
            )
        }

        var minimumSpacing: Double?
        var maximumSpacing: Double?
        var duplicate = false
        if series.isOrderedByProjection, members.count >= 2 {
            for index in 0..<(members.count - 1) {
                let spacing =
                    members[index + 1].projection - members[index].projection
                minimumSpacing = minimumSpacing.map { Swift.min($0, spacing) } ?? spacing
                maximumSpacing = maximumSpacing.map { Swift.max($0, spacing) } ?? spacing
                if members[index].projection == members[index + 1].projection {
                    duplicate = true
                }
            }
        }

        var orientationDeviation = 0.0
        var inPlaneDeviation = 0.0
        var uniformGrid = true
        for member in members {
            let frame = member.frame
            for (component, anchorComponent) in [
                (frame.rowDirection.x, anchor.rowDirection.x),
                (frame.rowDirection.y, anchor.rowDirection.y),
                (frame.rowDirection.z, anchor.rowDirection.z),
                (frame.columnDirection.x, anchor.columnDirection.x),
                (frame.columnDirection.y, anchor.columnDirection.y),
                (frame.columnDirection.z, anchor.columnDirection.z),
            ] {
                orientationDeviation = Swift.max(
                    orientationDeviation,
                    abs(component - anchorComponent)
                )
            }
            inPlaneDeviation = Swift.max(
                inPlaneDeviation,
                abs(frame.rowSpacingMillimetres - anchor.rowSpacingMillimetres)
            )
            inPlaneDeviation = Swift.max(
                inPlaneDeviation,
                abs(frame.columnSpacingMillimetres - anchor.columnSpacingMillimetres)
            )
            if frame.rows != anchor.rows || frame.columns != anchor.columns
                || frame.scalarFormat != anchor.scalarFormat
            {
                uniformGrid = false
            }
        }

        let spread: Double? =
            if let maximumSpacing, let minimumSpacing {
                maximumSpacing - minimumSpacing
            } else {
                nil
            }

        return CTGeometryMeasurement(
            memberCount: members.count,
            minimumSliceSpacing: minimumSpacing,
            maximumSliceSpacing: maximumSpacing,
            sliceSpacingSpread: spread,
            maximumOrientationDeviation: orientationDeviation,
            maximumInPlaneSpacingDeviation: inPlaneDeviation,
            rowColumnDotProduct: dot(anchor.rowDirection, anchor.columnDirection),
            rowMagnitudeResidual: magnitudeResidual(anchor.rowDirection),
            columnMagnitudeResidual: magnitudeResidual(anchor.columnDirection),
            hasDuplicateProjections: duplicate,
            hasUniformGrid: uniformGrid
        )
    }

    /// The dot product in the frozen expression order, with no fused
    /// multiply-add.
    private static func dot(_ lhs: Vector3D, _ rhs: Vector3D) -> Double {
        ((lhs.x * rhs.x) + (lhs.y * rhs.y)) + (lhs.z * rhs.z)
    }

    /// `(v . v) - 1` in the frozen expression order. No square root, so no
    /// second numeric boundary and no overflow path beyond the products.
    private static func magnitudeResidual(_ vector: Vector3D) -> Double {
        (((vector.x * vector.x) + (vector.y * vector.y)) + (vector.z * vector.z))
            - 1.0
    }

    private static func presentationAgrees(_ series: CTSeries) -> Bool {
        guard let anchor = series.anchor else { return true }
        return series.members.allSatisfy { member in
            member.frame.rescaleSlope == anchor.rescaleSlope
                && member.frame.rescaleIntercept == anchor.rescaleIntercept
                && member.frame.photometricInterpretation
                    == anchor.photometricInterpretation
        }
    }
}

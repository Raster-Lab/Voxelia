// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("RayAxisAlignedBoundsIntersection3D")
struct RayAxisAlignedBoundsIntersection3DTests {
    private let world = CoordinateSpaceID(rawValue: "org.voxelia.coordinate.world")!
    private let patient = CoordinateSpaceID(rawValue: "org.voxelia.coordinate.patient")!

    private func bounds(
        _ minimum: (Double, Double, Double),
        _ maximum: (Double, Double, Double)
    ) throws -> AxisAlignedBounds3D {
        try AxisAlignedBounds3D(
            minimum: Point3D(
                x: minimum.0,
                y: minimum.1,
                z: minimum.2,
                coordinateSpace: world
            ),
            maximum: Point3D(
                x: maximum.0,
                y: maximum.1,
                z: maximum.2,
                coordinateSpace: world
            )
        )
    }

    private func ray(
        _ origin: (Double, Double, Double),
        _ direction: (Double, Double, Double)
    ) throws -> Ray3D {
        try Ray3D(
            origin: Point3D(
                x: origin.0,
                y: origin.1,
                z: origin.2,
                coordinateSpace: world
            ),
            direction: Vector3D(
                x: direction.0,
                y: direction.1,
                z: direction.2,
                coordinateSpace: world
            )
        )
    }

    @Test("[Unit][VOX-SPA-011][VOX-VAL-002] axis hits produce analytic parameters")
    func axisHitsProduceAnalyticParameters() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        let positive = try #require(
            try box.intersection(with: ray((-2, 1, 1), (2, 0, 0)))
        )
        #expect(positive.entryParameter == 1)
        #expect(positive.exitParameter == 3)

        let negative = try #require(
            try box.intersection(with: ray((6, 1, 1), (-2, 0, 0)))
        )
        #expect(negative.entryParameter == 1)
        #expect(negative.exitParameter == 3)
    }

    @Test("[Unit][VOX-SPA-011] positive rescaling scales parameters inversely")
    func rescalingScalesParametersInversely() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        let base = try #require(
            try box.intersection(with: ray((-2, 1, 1), (2, 0, 0)))
        )
        let doubled = try #require(
            try box.intersection(with: ray((-2, 1, 1), (4, 0, 0)))
        )
        #expect(doubled.entryParameter == base.entryParameter / 2)
        #expect(doubled.exitParameter == base.exitParameter / 2)

        // The dyadic fixtures reach identical geometric points.
        #expect(-2 + base.entryParameter * 2 == -2 + doubled.entryParameter * 4)
        #expect(-2 + base.exitParameter * 2 == -2 + doubled.exitParameter * 4)
    }

    @Test("[Unit][VOX-SPA-011] behind-origin and separated-axis rays miss")
    func behindOriginAndSeparatedAxisMiss() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        #expect(try box.intersection(with: ray((6, 1, 1), (1, 0, 0))) == nil)
        #expect(try box.intersection(with: ray((-2, 10, 1), (1, 0, 0))) == nil)
        #expect(try box.intersection(with: ray((1, 1, -9), (0, 1, 0))) == nil)
    }

    @Test("[Unit][VOX-SPA-011] inside, face and corner origins use entry zero")
    func insideAndBoundaryOriginsUseEntryZero() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        let inside = try #require(
            try box.intersection(with: ray((2, 2, 2), (1, 0, 0)))
        )
        #expect(inside.entryParameter == 0)
        #expect(inside.exitParameter == 2)

        let outwardFace = try #require(
            try box.intersection(with: ray((4, 2, 2), (1, 0, 0)))
        )
        #expect(outwardFace.entryParameter == 0)
        #expect(outwardFace.exitParameter == 0)
        #expect(outwardFace.entryParameter.sign == .plus)
        #expect(outwardFace.exitParameter.sign == .plus)

        let inwardFace = try #require(
            try box.intersection(with: ray((0, 2, 2), (1, 0, 0)))
        )
        #expect(inwardFace.entryParameter == 0)
        #expect(inwardFace.exitParameter == 4)

        let outwardCorner = try #require(
            try box.intersection(with: ray((4, 4, 4), (1, 1, 1)))
        )
        #expect(outwardCorner.entryParameter == 0)
        #expect(outwardCorner.exitParameter == 0)

        let inwardCorner = try #require(
            try box.intersection(with: ray((0, 0, 0), (1, 1, 1)))
        )
        #expect(inwardCorner.entryParameter == 0)
        #expect(inwardCorner.exitParameter == 4)
    }

    @Test("[Unit][VOX-SPA-011] corner tangency is a singleton interval")
    func cornerTangencyIsSingleton() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        let tangent = try #require(
            try box.intersection(with: ray((3, 5, 2), (1, -1, 0)))
        )
        #expect(tangent.entryParameter == 1)
        #expect(tangent.exitParameter == 1)
    }

    @Test("[Unit][VOX-SPA-011] degenerate bounds use the same closed rule")
    func degenerateBoundsUseClosedRule() throws {
        let point = try bounds((2, 2, 2), (2, 2, 2))
        let pointHit = try #require(
            try point.intersection(with: ray((0, 2, 2), (1, 0, 0)))
        )
        #expect(pointHit.entryParameter == 2)
        #expect(pointHit.exitParameter == 2)

        let line = try bounds((0, 2, 2), (4, 2, 2))
        let coincident = try #require(
            try line.intersection(with: ray((-2, 2, 2), (1, 0, 0)))
        )
        #expect(coincident.entryParameter == 2)
        #expect(coincident.exitParameter == 6)

        let plane = try bounds((0, 0, 2), (4, 4, 2))
        #expect(try plane.intersection(with: ray((2, 2, 3), (1, 0, 0))) == nil)
        let planeHit = try #require(
            try plane.intersection(with: ray((2, 2, 0), (0, 0, 2)))
        )
        #expect(planeHit.entryParameter == 1)
        #expect(planeHit.exitParameter == 1)
    }

    @Test("[Unit][VOX-SPA-011] exact-zero components are parallel per axis")
    func exactZeroComponentsAreParallel() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        for axis in 0..<3 {
            var insideOrigin = [2.0, 2, 2]
            var direction = [0.0, 0, 0]
            direction[(axis + 1) % 3] = 1

            insideOrigin[axis] = 2
            #expect(
                try box.intersection(
                    with: ray(
                        (insideOrigin[0], insideOrigin[1], insideOrigin[2]),
                        (direction[0], direction[1], direction[2])
                    )
                ) != nil
            )

            var onOrigin = [2.0, 2, 2]
            onOrigin[axis] = 4
            #expect(
                try box.intersection(
                    with: ray(
                        (onOrigin[0], onOrigin[1], onOrigin[2]),
                        (direction[0], direction[1], direction[2])
                    )
                ) != nil
            )

            var outsideOrigin = [2.0, 2, 2]
            outsideOrigin[axis] = 5
            #expect(
                try box.intersection(
                    with: ray(
                        (outsideOrigin[0], outsideOrigin[1], outsideOrigin[2]),
                        (direction[0], direction[1], direction[2])
                    )
                ) == nil
            )
        }
    }

    @Test("[Unit][VOX-SPA-011] signed zero is parallel and subnormal is not")
    func signedZeroParallelAndSubnormalNot() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        let negativeZero = try #require(
            try box.intersection(with: ray((-2, 2, 2), (1, -0.0, 0)))
        )
        #expect(negativeZero.entryParameter == 2)
        #expect(negativeZero.exitParameter == 6)

        // A subnormal component is not parallel: its selected far quotient
        // overflows instead of being ignored.
        do {
            _ = try box.intersection(
                with: ray((2, 2, 2), (Double.leastNonzeroMagnitude, 0, 0))
            )
            #expect(Bool(false), "Expected a selected exit overflow.")
        } catch SpatialBoundsError.rayIntersectionExitParameterNotRepresentable(
            let axis,
            let reason
        ) {
            #expect(axis == 0)
            #expect(reason == .overflow)
        }
    }

    @Test("[Unit][VOX-ERR-001] coordinate-space mismatch throws before arithmetic")
    func coordinateSpaceMismatchThrows() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))
        let foreignRay = try Ray3D(
            origin: Point3D(x: 2, y: 2, z: 2, coordinateSpace: patient),
            direction: Vector3D(x: 1, y: 0, z: 0, coordinateSpace: patient)
        )

        #expect(
            throws: SpatialBoundsError.coordinateSpaceMismatch(
                expected: world,
                actual: patient
            )
        ) {
            try box.intersection(with: foreignRay)
        }
    }

    @Test("[Unit][VOX-VAL-007] overflowing subtraction uses the scaled fallback")
    func overflowingSubtractionUsesScaledFallback() throws {
        let extreme = Double.greatestFiniteMagnitude
        let box = try bounds((-extreme, -extreme, -extreme), (extreme, extreme, extreme))

        let hit = try #require(
            try box.intersection(with: ray((-extreme, 0, 0), (4, 0, 0)))
        )
        #expect(hit.entryParameter == 0)
        #expect(hit.exitParameter == extreme / 2)
    }

    @Test("[Unit][VOX-ERR-001] selected overflow throws entry before exit")
    func selectedOverflowThrowsEntryBeforeExit() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        do {
            _ = try box.intersection(
                with: ray((-Double.greatestFiniteMagnitude, 2, 2), (1e-300, 0, 0))
            )
            #expect(Bool(false), "Expected a selected entry overflow.")
        } catch SpatialBoundsError.rayIntersectionEntryParameterNotRepresentable(
            let axis,
            let reason
        ) {
            #expect(axis == 0)
            #expect(reason == .overflow)
        }
    }

    @Test("[Unit][VOX-ERR-001] selected exit underflow is a typed failure")
    func selectedExitUnderflowIsTypedFailure() throws {
        let tiny = Double.leastNonzeroMagnitude
        let huge = Double.greatestFiniteMagnitude
        let box = try bounds((0, 0, 0), (tiny, 4, 4))

        do {
            _ = try box.intersection(with: ray((0, 2, 2), (huge, 0, 0)))
            #expect(Bool(false), "Expected a selected exit underflow.")
        } catch SpatialBoundsError.rayIntersectionExitParameterNotRepresentable(
            let axis,
            let reason
        ) {
            #expect(axis == 0)
            #expect(reason == .underflow)
        }
    }

    @Test("[Unit][VOX-SPA-011] unselected non-representable quotients are harmless")
    func unselectedNonRepresentableQuotientsAreHarmless() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        let hit = try #require(
            try box.intersection(
                with: ray((2, 2, 2), (Double.leastNonzeroMagnitude, 1, 0))
            )
        )
        #expect(hit.entryParameter == 0)
        #expect(hit.exitParameter == 2)
    }

    @Test("[Unit][VOX-SPA-011] parallel-outside miss precedes unrelated overflow")
    func parallelOutsideMissPrecedesOverflow() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))

        #expect(
            try box.intersection(
                with: ray((-Double.greatestFiniteMagnitude, 10, 2), (1e-300, 0, 0))
            ) == nil
        )
    }

    @Test("[Unit][VOX-SPA-011] empty token intervals precede representability failures")
    func emptyTokenIntervalsPrecedeFailures() throws {
        let tiny = Double.leastNonzeroMagnitude
        let huge = Double.greatestFiniteMagnitude

        // Positive-underflow entry versus zero exit is a nil miss.
        let entryBox = try bounds((0, 0, 0), (4, 4, 4))
        #expect(
            try entryBox.intersection(with: ray((-tiny, 4, 2), (huge, 1, 0))) == nil
        )

        // Negative-underflow exit versus zero entry is a nil miss.
        let exitBox = try bounds((-4, 0, 0), (0, 4, 4))
        #expect(
            try exitBox.intersection(with: ray((tiny, 2, 2), (huge, 0, 0))) == nil
        )
    }

    @Test("[Unit][VOX-ERR-001] equal tokens keep the earliest axis provenance")
    func equalTokensKeepEarliestAxis() throws {
        let box = try bounds((0, 0, 0), (4, 4, 4))
        let extreme = Double.greatestFiniteMagnitude

        do {
            _ = try box.intersection(
                with: ray((-extreme, -extreme, 2), (1e-300, 1e-300, 0))
            )
            #expect(Bool(false), "Expected a selected entry overflow.")
        } catch SpatialBoundsError.rayIntersectionEntryParameterNotRepresentable(
            let axis,
            let reason
        ) {
            #expect(axis == 0)
            #expect(reason == .overflow)
        }
    }

    @Test("[Unit][VOX-VAL-002] results match an independent binary64-v1 evaluator")
    func matchesIndependentEvaluator() throws {
        let tiny = Double.leastNonzeroMagnitude
        let huge = Double.greatestFiniteMagnitude
        let boxes: [((Double, Double, Double), (Double, Double, Double))] = [
            ((0, 0, 0), (4, 4, 4)),
            ((2, 2, 2), (2, 2, 2)),
            ((0, 2, 2), (4, 2, 2)),
            ((0, 0, 0), (tiny, 4, 4)),
            ((-huge, -huge, -huge), (huge, huge, huge)),
        ]
        let rays: [((Double, Double, Double), (Double, Double, Double))] = [
            ((-2, 1, 1), (2, 0, 0)),
            ((6, 1, 1), (-2, 0, 0)),
            ((2, 2, 2), (1, 1, 1)),
            ((4, 2, 2), (1, 0, 0)),
            ((3, 5, 2), (1, -1, 0)),
            ((-2, 2, 2), (1, -0.0, 0)),
            ((2, 2, 2), (tiny, 1, 0)),
            ((0, 2, 2), (huge, 0, 0)),
            ((-huge, 2, 2), (1e-300, 0, 0)),
            ((-tiny, 4, 2), (huge, 1, 0)),
            ((-huge, 0, 0), (4, 0, 0)),
        ]

        for boxFixture in boxes {
            for rayFixture in rays {
                let box = try bounds(boxFixture.0, boxFixture.1)
                let query = try ray(rayFixture.0, rayFixture.1)
                let expected = independentOutcome(
                    minimum: [boxFixture.0.0, boxFixture.0.1, boxFixture.0.2],
                    maximum: [boxFixture.1.0, boxFixture.1.1, boxFixture.1.2],
                    origin: [rayFixture.0.0, rayFixture.0.1, rayFixture.0.2],
                    direction: [rayFixture.1.0, rayFixture.1.1, rayFixture.1.2]
                )
                let actual = queryOutcome(box: box, ray: query)
                #expect(
                    actual == expected,
                    "box \(boxFixture) ray \(rayFixture): \(actual) != \(expected)"
                )
            }
        }
    }

    // MARK: - Independent binary64-v1 evaluator

    private enum Outcome: Equatable, CustomStringConvertible {
        case miss
        case hit(UInt64, UInt64)
        case entryFailure(Int, RayIntersectionParameterFailureReason)
        case exitFailure(Int, RayIntersectionParameterFailureReason)

        var description: String {
            switch self {
            case .miss: "miss"
            case .hit(let entry, let exit):
                "hit(\(Double(bitPattern: entry)), \(Double(bitPattern: exit)))"
            case .entryFailure(let axis, let reason): "entry(\(axis), \(reason))"
            case .exitFailure(let axis, let reason): "exit(\(axis), \(reason))"
            }
        }
    }

    private func queryOutcome(box: AxisAlignedBounds3D, ray: Ray3D) -> Outcome {
        do {
            guard let result = try box.intersection(with: ray) else {
                return .miss
            }
            return .hit(
                result.entryParameter.bitPattern,
                result.exitParameter.bitPattern
            )
        } catch SpatialBoundsError.rayIntersectionEntryParameterNotRepresentable(
            let axis,
            let reason
        ) {
            return .entryFailure(axis, reason)
        } catch SpatialBoundsError.rayIntersectionExitParameterNotRepresentable(
            let axis,
            let reason
        ) {
            return .exitFailure(axis, reason)
        } catch {
            Issue.record("Unexpected error: \(error)")
            return .miss
        }
    }

    /// A deliberately differently structured evaluator: it materializes every
    /// axis token first, then folds with explicit rank comparison.
    private func independentOutcome(
        minimum: [Double],
        maximum: [Double],
        origin: [Double],
        direction: [Double]
    ) -> Outcome {
        for axis in 0..<3 where direction[axis] == 0 {
            if origin[axis] < minimum[axis] || origin[axis] > maximum[axis] {
                return .miss
            }
        }

        // rank 0/2/4/6/7 as in the normative order; finite uses 1, 3 or 5.
        func token(_ boundary: Double, _ axis: Int) -> (rank: Int, value: Double, axis: Int) {
            var numerator = boundary - origin[axis]
            var divisor = direction[axis]
            if numerator.isInfinite {
                numerator = boundary * 0.5 - origin[axis] * 0.5
                divisor = direction[axis] * 0.5
                if divisor == 0 {
                    let positive = (numerator > 0) == (direction[axis] > 0)
                    return (positive ? 6 : 0, 0, axis)
                }
            }
            let quotient = numerator / divisor
            if quotient.isInfinite {
                return (quotient > 0 ? 6 : 0, 0, axis)
            }
            if quotient == 0, boundary != origin[axis] {
                let positive = (boundary > origin[axis]) == (direction[axis] > 0)
                return (positive ? 4 : 2, 0, axis)
            }
            let canonical = quotient == 0 ? 0 : quotient
            return (canonical < 0 ? 1 : (canonical == 0 ? 3 : 5), canonical, axis)
        }

        func isAfter(
            _ lhs: (rank: Int, value: Double, axis: Int),
            _ rhs: (rank: Int, value: Double, axis: Int)
        ) -> Bool {
            if lhs.rank != rhs.rank { return lhs.rank > rhs.rank }
            if [1, 3, 5].contains(lhs.rank) { return lhs.value > rhs.value }
            return false
        }

        var entry = (rank: 3, value: 0.0, axis: -1)
        var exit = (rank: 7, value: Double.infinity, axis: -1)
        for axis in 0..<3 where direction[axis] != 0 {
            let lower = token(minimum[axis], axis)
            let upper = token(maximum[axis], axis)
            let near = direction[axis] > 0 ? lower : upper
            let far = direction[axis] > 0 ? upper : lower
            if isAfter(near, entry) { entry = near }
            if isAfter(exit, far) { exit = far }
        }

        if isAfter(entry, exit) { return .miss }
        if entry.rank == 0 || entry.rank == 6 {
            return .entryFailure(entry.axis, .overflow)
        }
        if entry.rank == 2 || entry.rank == 4 {
            return .entryFailure(entry.axis, .underflow)
        }
        if exit.rank == 0 || exit.rank == 6 {
            return .exitFailure(exit.axis, .overflow)
        }
        if exit.rank == 2 || exit.rank == 4 {
            return .exitFailure(exit.axis, .underflow)
        }
        return .hit(entry.value.bitPattern, exit.value.bitPattern)
    }
}

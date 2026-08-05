// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("AffineSpatialInverse")
struct AffineSpatialInverseTests {
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

    private func matrix(spatial: [Double]) throws -> Matrix4x4Double {
        var elements = [Double](repeating: 0, count: 16)
        for row in 0...2 {
            for column in 0...2 {
                elements[4 * row + column] = spatial[3 * row + column]
            }
        }
        elements[15] = 1
        return try Matrix4x4Double(elements: elements)
    }

    @Test("[Unit][VOX-SPA-004] the rotation-scale fixture inverts exactly")
    func rotationScaleFixtureInvertsExactly() throws {
        let inverse = try AffineSpatialInverse(
            spatialPartOf: try matrix(spatial: [0, -2, 0, 2, 0, 0, 0, 0, 1])
        )
        #expect(inverse.determinant == 4)
        #expect(inverse.elements == [0, 0.5, 0, -0.5, 0, 0, 0, 0, 1])
    }

    @Test("[Unit][VOX-SPA-004] the diagonal fixture inverts exactly")
    func diagonalFixtureInvertsExactly() throws {
        let inverse = try AffineSpatialInverse(
            spatialPartOf: try matrix(spatial: [2, 0, 0, 0, 4, 0, 0, 0, 5])
        )
        #expect(inverse.determinant == 40)
        #expect(inverse.elements == [0.5, 0, 0, 0, 0.25, 0, 0, 0, 0.2])
    }

    @Test("[Unit][VOX-SPA-004] the symmetric fixture matches the frozen row")
    func symmetricFixtureMatchesTheFrozenRow() throws {
        // The exact rational inverse row zero is 13/49, -3/49, 1/49;
        // the frozen binary64 spellings are the specification's.
        let inverse = try AffineSpatialInverse(
            spatialPartOf: try matrix(spatial: [4, 1, 0, 1, 5, 2, 0, 2, 6])
        )
        #expect(inverse.determinant == 98)
        #expect(inverse.elements[0] == 0.2653061224489796)
        #expect(inverse.elements[1] == -0.061224489795918366)
        #expect(inverse.elements[2] == 0.02040816326530612)
    }

    @Test("[Unit][VOX-SPA-004] repeated evaluation is bit-identical")
    func repeatedEvaluationIsBitIdentical() throws {
        let source = try matrix(spatial: [4, 1, 0, 1, 5, 2, 0, 2, 6])
        let first = try AffineSpatialInverse(spatialPartOf: source)
        let second = try AffineSpatialInverse(spatialPartOf: source)
        #expect(first == second)
        #expect(
            first.elements.map(\.bitPattern) == second.elements.map(\.bitPattern)
        )
    }

    @Test("[Unit][VOX-SPA-004][VOX-ERR-001] sub-threshold determinants reject typed")
    func subThresholdDeterminantsRejectTyped() throws {
        // An exactly rank-deficient block and a subnormal determinant
        // both fall under the no-epsilon admission rule.
        let rankDeficient = try matrix(spatial: [1, 2, 3, 2, 4, 6, 0, 0, 1])
        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            try AffineSpatialInverse(spatialPartOf: rankDeficient)
        }
        let subnormal = try matrix(
            spatial: [1e-155, 0, 0, 0, 1e-155, 0, 0, 0, 1e-3]
        )
        #expect(throws: AffineSpatialInverseError.singularMatrix) {
            try AffineSpatialInverse(spatialPartOf: subnormal)
        }
    }

    @Test("[Unit][VOX-SPA-004][VOX-VAL-007] the measured bound holds against the rational oracle")
    func measuredBoundHoldsAgainstTheRationalOracle() throws {
        // Ten thousand seeded strictly diagonally dominant matrices
        // across four magnitude regimes; the host python3 interpreter
        // inverts each exactly over rationals and asserts the
        // specification's elementwise bound, reporting the maximum
        // observed ratio as evidence.
        var generator = DeterministicGenerator(state: 0xA16_0016)
        var lines = [String]()
        for regimeScale in [1e-3, 1.0, 1e3, 1e6] {
            for _ in 0..<2_500 {
                var spatial = [Double](repeating: 0, count: 9)
                for row in 0...2 {
                    var offDiagonalSum = 0.0
                    for column in 0...2 where column != row {
                        let value = (generator.unit() - 0.5) * 2.0 * regimeScale
                        spatial[3 * row + column] = value
                        offDiagonalSum += value.magnitude
                    }
                    let sign: Double = generator.next() % 2 == 0 ? 1 : -1
                    spatial[3 * row + row] =
                        sign * (offDiagonalSum + (0.5 + generator.unit()) * regimeScale)
                }
                let inverse = try AffineSpatialInverse(
                    spatialPartOf: try matrix(spatial: spatial)
                )
                let words =
                    spatial.map(\.bitPattern)
                    + inverse.elements.map(\.bitPattern)
                    + inverse.elementwiseErrorBounds.map(\.bitPattern)
                lines.append(
                    words.map { String(format: "%016llx", $0) }
                        .joined(separator: " ")
                )
            }
        }

        let script = """
            import struct, sys
            from fractions import Fraction

            def bits(word):
                return struct.unpack(">d", bytes.fromhex(word))[0]

            matrices = 0
            entries = 0
            max_ratio = 0.0
            for line in sys.stdin.read().splitlines():
                words = line.split(" ")
                assert len(words) == 27, line
                values = [bits(word) for word in words]
                m = [Fraction(value) for value in values[0:9]]
                computed = values[9:18]
                bounds = values[18:27]
                det = (
                    m[0] * (m[4] * m[8] - m[5] * m[7])
                    - m[1] * (m[3] * m[8] - m[5] * m[6])
                    + m[2] * (m[3] * m[7] - m[4] * m[6])
                )
                assert det != 0, line
                exact = [
                    (m[4] * m[8] - m[5] * m[7]) / det,
                    -(m[1] * m[8] - m[2] * m[7]) / det,
                    (m[1] * m[5] - m[2] * m[4]) / det,
                    -(m[3] * m[8] - m[5] * m[6]) / det,
                    (m[0] * m[8] - m[2] * m[6]) / det,
                    -(m[0] * m[5] - m[2] * m[3]) / det,
                    (m[3] * m[7] - m[4] * m[6]) / det,
                    -(m[0] * m[7] - m[1] * m[6]) / det,
                    (m[0] * m[4] - m[1] * m[3]) / det,
                ]
                for k in range(9):
                    difference = abs(Fraction(computed[k]) - exact[k])
                    bound = Fraction(bounds[k])
                    assert difference <= bound, line
                    if bound:
                        max_ratio = max(max_ratio, float(difference / bound))
                    entries += 1
                matrices += 1
            print("OK", matrices, entries, repr(max_ratio))
            """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", "-c", script]
        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        try process.run()
        input.fileHandleForWriting.write(
            Data((lines.joined(separator: "\n") + "\n").utf8)
        )
        input.fileHandleForWriting.closeFile()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        let result = String(
            decoding: output.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let fields = result.split(separator: " ").map(String.init)
        #expect(fields.count == 4)
        #expect(fields.first == "OK")
        #expect(fields.dropFirst().first == "10000")
        #expect(fields.dropFirst(2).first == "90000")
        let ratioField = try #require(fields.last)
        let maximumRatio = try #require(Double(ratioField))
        #expect(maximumRatio < 1)
        print(
            "ALG-0016 bound evidence: 10000 matrices, 90000 entries, "
                + "max ratio \(maximumRatio), headroom \(1 / maximumRatio)"
        )
    }
}

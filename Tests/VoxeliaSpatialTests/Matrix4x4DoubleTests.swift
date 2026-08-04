// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("Matrix4x4Double")
struct Matrix4x4DoubleTests {
    @Test("[Unit][VOX-SPA-003] preserves sixteen row-major Double values")
    func preservesRowMajorValues() throws {
        let values = ContiguousArray((0..<16).map(Double.init))
        let matrix = try Matrix4x4Double(elements: values)

        #expect(matrix.elements == values)
        #expect(matrix.elements[3] == 3)
        #expect(matrix.elements[7] == 7)
        #expect(matrix.elements[11] == 11)

        let padded = [-1.0] + Array(values) + [-1.0]
        #expect(try Matrix4x4Double(elements: padded[1...16]) == matrix)

        var changedValues = values
        changedValues[15] = values[15].nextUp
        let changed = try Matrix4x4Double(elements: changedValues)
        #expect(changed != matrix)
        #expect(Set([matrix, changed]).count == 2)
    }

    @Test("[Unit] exposes the canonical identity matrix")
    func exposesIdentity() {
        let expected: ContiguousArray<Double> = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ]

        #expect(Matrix4x4Double.identity.elements == expected)
    }

    @Test("[Unit][VOX-ERR-001] rejects every invalid element count")
    func rejectsInvalidElementCounts() {
        for count in [0, 1, 15, 17, 64] {
            #expect(throws: Matrix4x4DoubleError.invalidElementCount(actual: count)) {
                try Matrix4x4Double(elements: Array(repeating: 0.0, count: count))
            }
        }
    }

    @Test("[Unit][VOX-ERR-001] rejects non-finite elements with their index")
    func rejectsNonFiniteElements() {
        let cases = [
            (0, Double.nan),
            (7, Double.infinity),
            (15, -Double.infinity),
        ]

        for (index, value) in cases {
            var elements = Array(repeating: 0.0, count: 16)
            elements[index] = value
            #expect(throws: Matrix4x4DoubleError.nonFiniteElement(index: index)) {
                try Matrix4x4Double(elements: elements)
            }
        }
    }

    @Test("[Unit][VOX-API-004] normalizes only negative zero for stable identity")
    func normalizesNegativeZero() throws {
        var elements = Array(repeating: 0.0, count: 16)
        elements[5] = -0.0
        elements[10] = Double.leastNonzeroMagnitude
        let matrix = try Matrix4x4Double(elements: elements)

        #expect(matrix.elements[5].bitPattern == Double(0).bitPattern)
        #expect(matrix.elements[10].bitPattern == Double.leastNonzeroMagnitude.bitPattern)
        #expect(!String(decoding: try JSONEncoder().encode(matrix), as: UTF8.self).contains("-0"))
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] Codable preserves structure and revalidates input")
    func codableRoundTripAndValidation() throws {
        let matrix = try Matrix4x4Double(
            elements: ContiguousArray((0..<16).map(Double.init))
        )
        let encoded = try JSONEncoder().encode(matrix)
        #expect(try JSONDecoder().decode(Matrix4x4Double.self, from: encoded) == matrix)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        #expect(Set(object.keys) == ["elements"])
        #expect(try #require(object["elements"] as? [Double]) == Array(matrix.elements))

        do {
            _ = try JSONDecoder().decode(
                Matrix4x4Double.self,
                from: Data(#"{"elements":[0,1,2]}"#.utf8)
            )
            #expect(Bool(false), "Expected a three-element matrix to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["elements"])
            #expect(
                context.underlyingError as? Matrix4x4DoubleError
                    == .invalidElementCount(actual: 3)
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(
                Matrix4x4Double.self,
                from: Data(
                    #"{"elements":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],"extra":true}"#
                        .utf8
                )
            )
            #expect(Bool(false), "Expected an extra-key matrix to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }

        do {
            _ = try JSONDecoder().decode(
                Matrix4x4Double.self,
                from: Data(#"[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]"#.utf8)
            )
            #expect(Bool(false), "Expected an array-shaped matrix to fail decoding.")
        } catch DecodingError.typeMismatch {
            // The keyed-container request rejects the non-object shape.
        } catch {
            #expect(Bool(false), "Expected typeMismatch, received \(error).")
        }

        let nonFinite = Data(
            #"{"elements":["NaN",1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}"#.utf8
        )
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
        do {
            _ = try decoder.decode(Matrix4x4Double.self, from: nonFinite)
            #expect(Bool(false), "Expected a non-finite element to fail decoding.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["elements"])
            #expect(
                context.underlyingError as? Matrix4x4DoubleError
                    == .nonFiniteElement(index: 0)
            )
        } catch {
            #expect(Bool(false), "Expected dataCorrupted, received \(error).")
        }
    }
}

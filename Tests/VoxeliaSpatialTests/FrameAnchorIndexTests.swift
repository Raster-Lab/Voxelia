// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaSpatial

@Suite("FrameAnchorIndex")
struct FrameAnchorIndexTests {
    @Test("[Unit][CDMS-26.2][VOX-SPA-012] accepts possible full-rank anchors")
    func acceptsPossibleAnchors() throws {
        let rankOne = try FrameAnchorIndex(components: [0])
        #expect(rankOne.rank == 1)
        #expect(Array(rankOne.components) == [0])

        let allZero = try FrameAnchorIndex(components: [0, 0, 0, 0])
        #expect(allZero.rank == 4)

        let multiRank = try FrameAnchorIndex(components: [0, 0, 7, 2])
        #expect(Array(multiRank.components) == [0, 0, 7, 2])

        let highRank = try FrameAnchorIndex(
            components: Array(repeating: 3, count: 1_024)
        )
        #expect(highRank.rank == 1_024)

        let extreme = try FrameAnchorIndex(components: [Int.max - 1])
        #expect(extreme.components[0] == Int.max - 1)
    }

    @Test("[Unit][VOX-ERR-001] rejects impossible components in axis order")
    func rejectsImpossibleComponents() {
        #expect(throws: FrameAnchorIndexError.emptyRank) {
            try FrameAnchorIndex(components: [Int]())
        }

        let invalidFixtures: [(components: [Int], axis: Int, value: Int)] = [
            ([-1, 0, 0], 0, -1),
            ([0, Int.max, 0], 1, Int.max),
            ([0, 0, -7], 2, -7),
            ([Int.min, 0], 0, Int.min),
            ([0, -1, Int.max], 1, -1),
        ]
        for invalidFixture in invalidFixtures {
            #expect(
                throws: FrameAnchorIndexError.componentOutsidePossibleImageRange(
                    axis: invalidFixture.axis,
                    value: invalidFixture.value
                )
            ) {
                try FrameAnchorIndex(components: invalidFixture.components)
            }
        }
    }

    @Test("[Unit][VOX-API-003] materialises generic collections with exact order")
    func materialisesGenericCollections() throws {
        let slice = try FrameAnchorIndex(components: [9, 1, 2, 3, 9][1...3])
        #expect(Array(slice.components) == [1, 2, 3])

        let repeated = try FrameAnchorIndex(components: repeatElement(4, count: 2))
        #expect(Array(repeated.components) == [4, 4])

        let ordered = try FrameAnchorIndex(components: [1, 2])
        let reversed = try FrameAnchorIndex(components: [2, 1])
        #expect(ordered != reversed)
        #expect(Set([ordered, reversed, ordered]).count == 2)

        requireSendable(FrameAnchorIndex.self)
        requireSendable(FrameAnchorIndexError.self)
    }

    @Test("[Unit][VOX-API-004] Codable uses the exact one-key wire without rank")
    func codableUsesDocumentedWire() throws {
        let anchor = try FrameAnchorIndex(components: [0, 0, 7, 2])
        let data = try JSONEncoder().encode(anchor)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: [Int]]
        )
        #expect(object == ["components": [0, 0, 7, 2]])
        #expect(try JSONDecoder().decode(FrameAnchorIndex.self, from: data) == anchor)
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects wrong-keyed shapes")
    func decodingRejectsWrongKeyedShapes() {
        let rootCorruptedValues = [
            #"{}"#,
            #"{"values":[0]}"#,
            #"{"components":[0],"rank":1}"#,
            #"{"components":[0],"extra":true,"other":1}"#,
        ]
        for rootCorruptedValue in rootCorruptedValues {
            do {
                _ = try JSONDecoder().decode(
                    FrameAnchorIndex.self,
                    from: Data(rootCorruptedValue.utf8)
                )
                #expect(Bool(false), "Expected a wrong-keyed anchor to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(
                FrameAnchorIndex.self,
                from: Data(#"{"components":null}"#.utf8)
            )
            #expect(Bool(false), "Expected a null components field to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null is rejected for the non-optional components array.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in [#"[0,1]"#, #""anchor""#, "3"] {
            do {
                _ = try JSONDecoder().decode(
                    FrameAnchorIndex.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped anchor to fail decoding.")
            } catch DecodingError.typeMismatch {
                // The keyed-container request rejects non-object shapes.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects invalid array elements")
    func decodingRejectsInvalidElements() {
        for typeMismatchJSON in [
            #"{"components":["0"]}"#,
            #"{"components":[true]}"#,
        ] {
            do {
                _ = try JSONDecoder().decode(
                    FrameAnchorIndex.self,
                    from: Data(typeMismatchJSON.utf8)
                )
                #expect(Bool(false), "Expected a non-integer element to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-numeric elements are rejected by the array decoder.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }

        do {
            _ = try JSONDecoder().decode(
                FrameAnchorIndex.self,
                from: Data(#"{"components":[0,null]}"#.utf8)
            )
            #expect(Bool(false), "Expected a null element to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null elements are rejected by the array decoder.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for corruptedJSON in [
            #"{"components":[1.5]}"#,
            #"{"components":[1e300]}"#,
        ] {
            do {
                _ = try JSONDecoder().decode(
                    FrameAnchorIndex.self,
                    from: Data(corruptedJSON.utf8)
                )
                #expect(Bool(false), "Expected a non-Int number to fail decoding.")
            } catch DecodingError.dataCorrupted {
                // Fractional and out-of-Int numbers cannot become Int.
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding revalidates anchor invariants")
    func decodingRevalidatesInvariants() {
        let invalidPayloads: [(json: String, expectedError: FrameAnchorIndexError)] = [
            (#"{"components":[]}"#, .emptyRank),
            (
                #"{"components":[0,-1]}"#,
                .componentOutsidePossibleImageRange(axis: 1, value: -1)
            ),
            (
                #"{"components":[9223372036854775807]}"#,
                .componentOutsidePossibleImageRange(axis: 0, value: Int.max)
            ),
        ]
        for invalidPayload in invalidPayloads {
            do {
                _ = try JSONDecoder().decode(
                    FrameAnchorIndex.self,
                    from: Data(invalidPayload.json.utf8)
                )
                #expect(Bool(false), "Expected an impossible anchor to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.map(\.stringValue) == ["components"])
                #expect(
                    context.underlyingError as? FrameAnchorIndexError
                        == invalidPayload.expectedError
                )
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}

// SPDX-License-Identifier: MIT

import CryptoKit
import Testing
import VoxeliaCore

@testable import VoxeliaExecution

@Suite("RGB source presentation")
struct RGBSourcePresentationTests {
    private struct Fixture: Sendable {
        let name: String
        let interpretation: ComponentInterpretation
        let sampleType: ScalarType
        let channels: [UInt8]
    }

    @Test(
        "[Oracle][VOX-R2D-010][VOX-NUM-001] all ALG-0044 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let pixel = try RGBSourcePresentation.present(
                    interpretation: fixture.interpretation,
                    sampleType: fixture.sampleType,
                    channels: fixture.channels
                )
                records.append(
                    "\(fixture.name)|rgba=\(pixel.red),\(pixel.green),"
                        + "\(pixel.blue),\(pixel.alpha)"
                )
                payload.append(
                    contentsOf: [
                        pixel.red, pixel.green, pixel.blue, pixel.alpha,
                    ]
                )
            } catch let error as RGBSourceError {
                records.append("\(fixture.name)|error=\(error)")
            }
        }

        #expect(records.count == 12)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "6115cfd287cc8bd9c7cbebb79d697d198bb8d64306b1375ccbfdca003e9cb0f2"
        )
        #expect(
            sha256(payload)
                == "9a039575cea559af60aba8c8cdc87891205e6d04b50ab0a17df371594b9d46a4"
        )
    }

    @Test(
        "[Unit][VOX-R2D-010][VOX-API-003] channels pass through in order and alpha follows the source"
    )
    func channelsPassThroughInOrderAndAlphaFollowsTheSource() throws {
        // A swap of any two channels would change this.
        #expect(
            try present(.rgb, [1, 2, 3])
                == DisplayPixelRGBA8(red: 1, green: 2, blue: 3, alpha: 255)
        )

        // A source with no alpha is opaque; a source with one keeps it
        // unchanged, including a fully transparent alpha. That is the one
        // place this model differs from the palette rule, and it differs
        // because a palette has no alpha to carry while an RGBA source does.
        #expect(try present(.rgba, [10, 20, 30, 40]).alpha == 40)
        #expect(try present(.rgba, [10, 20, 30, 0]).alpha == 0)
        #expect(try present(.rgb, [10, 20, 30]).alpha == 255)

        // No arithmetic occurs, so the extremes survive exactly.
        #expect(
            try present(.rgb, [0, 255, 0])
                == DisplayPixelRGBA8(red: 0, green: 255, blue: 0, alpha: 255)
        )
    }

    @Test(
        "[Unit][VOX-R2D-010][VOX-ERR-001] the admission is exactly three payload-free cases"
    )
    func admissionIsExactlyThreePayloadFreeCases() throws {
        // A non-colour interpretation is rejected rather than reinterpreted.
        for interpretation: ComponentInterpretation in [
            .scalar, .vector, .labelProbability,
        ] {
            #expect(throws: RGBSourceError.unsupportedInterpretation) {
                try present(interpretation, [1, 2, 3])
            }
        }

        // A wider channel is rejected rather than silently reduced.
        #expect(throws: RGBSourceError.unsupportedSampleType) {
            try RGBSourcePresentation.present(
                interpretation: .rgb,
                sampleType: .uint16,
                channels: [1, 2, 3]
            )
        }

        // The channel count must match the interpretation exactly, both ways.
        #expect(throws: RGBSourceError.channelCountMismatch) {
            try present(.rgb, [1, 2])
        }
        #expect(throws: RGBSourceError.channelCountMismatch) {
            try present(.rgb, [1, 2, 3, 4])
        }
        #expect(throws: RGBSourceError.channelCountMismatch) {
            try present(.rgba, [1, 2, 3])
        }

        let errors: [RGBSourceError] = [
            .unsupportedInterpretation, .unsupportedSampleType,
            .channelCountMismatch,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "unsupportedInterpretation", "unsupportedSampleType",
                "channelCountMismatch",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private func analyticalFixtures() -> [Fixture] {
        func fixture(
            _ name: String,
            _ interpretation: ComponentInterpretation,
            _ channels: [UInt8],
            _ sampleType: ScalarType = .uint8
        ) -> Fixture {
            Fixture(
                name: name,
                interpretation: interpretation,
                sampleType: sampleType,
                channels: channels
            )
        }
        return [
            fixture("rgb-passthrough", .rgb, [10, 20, 30]),
            fixture("rgba-passthrough", .rgba, [10, 20, 30, 40]),
            fixture("rgba-transparent", .rgba, [10, 20, 30, 0]),
            fixture("channel-order", .rgb, [1, 2, 3]),
            fixture("rgb-extremes", .rgb, [0, 255, 0]),
            fixture("rgba-opaque-maximum", .rgba, [255, 255, 255, 255]),
            fixture("scalar-source", .scalar, [1, 2, 3]),
            fixture("vector-source", .vector, [1, 2, 3]),
            fixture("wide-sample-type", .rgb, [1, 2, 3], .uint16),
            fixture("rgb-too-few-channels", .rgb, [1, 2]),
            fixture("rgb-too-many-channels", .rgb, [1, 2, 3, 4]),
            fixture("rgba-too-few-channels", .rgba, [1, 2, 3]),
        ]
    }

    // MARK: - Helpers

    private func present(
        _ interpretation: ComponentInterpretation,
        _ channels: [UInt8]
    ) throws -> DisplayPixelRGBA8 {
        try RGBSourcePresentation.present(
            interpretation: interpretation,
            sampleType: .uint8,
            channels: channels
        )
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: bytes).map {
            hexadecimal(UInt64($0), width: 2)
        }.joined()
    }

    private func hexadecimal(_ value: UInt64, width: Int) -> String {
        let text = String(value, radix: 16)
        return String(repeating: "0", count: width - text.count) + text
    }
}

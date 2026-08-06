// SPDX-License-Identifier: MIT

import CryptoKit
import Testing

@testable import VoxeliaExecution

@Suite("Overlay compositing")
struct OverlayCompositingTests {
    private struct Fixture: Sendable {
        let name: String
        let base: DisplayPixelRGBA8
        let overlays: [Overlay]
    }

    @Test(
        "[Oracle][VOX-R2D-011][VOX-NUM-001] all ALG-0045 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in analyticalFixtures() {
            do {
                let pixel = try OverlayCompositing.composite(
                    base: fixture.base,
                    overlays: fixture.overlays
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
            } catch let error as OverlayCompositingError {
                records.append("\(fixture.name)|error=\(error)")
            }
        }

        #expect(records.count == 18)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "f91aaecff517a77019e9ec4201555cbdd16784b30f68c447f9d8087d919d3a0b"
        )
        #expect(
            sha256(payload)
                == "36c48cd8d48defdc25039dffea2936cdcad64a6963de89319aecdabd9e964171"
        )
    }

    @Test(
        "[Unit][VOX-R2D-011][VOX-NUM-001] the accumulator is rounded exactly once"
    )
    func accumulatorIsRoundedExactlyOnce() throws {
        // THE implementation trap. Quantising each overlay before the next
        // composites is the obvious shortcut and it visibly changes the
        // result: two overlays at opacity 0.3 over a base of 10 give 58
        // rounded once and 59 rounded in between.
        let composited = try OverlayCompositing.composite(
            base: Self.base,
            overlays: [
                Overlay(source: .image(Self.red), opacity: 0.3),
                Overlay(source: .image(Self.green), opacity: 0.3),
            ]
        )
        #expect(composited.red == 58)

        // A fully opaque overlay replaces the base exactly, because
        // `acc * 0 + x * 1` is exact in binary64, and a fully transparent one
        // leaves it exactly.
        #expect(
            try OverlayCompositing.composite(
                base: Self.base,
                overlays: [Overlay(source: .image(Self.red), opacity: 1)]
            ) == entryPixel(255, 0, 0)
        )
        #expect(
            try OverlayCompositing.composite(
                base: Self.base,
                overlays: [Overlay(source: .image(Self.red), opacity: 0)]
            ) == entryPixel(10, 20, 30)
        )

        // Order matters.
        let redThenGreen = try OverlayCompositing.composite(
            base: Self.base,
            overlays: [
                Overlay(source: .image(Self.red), opacity: 0.5),
                Overlay(source: .image(Self.green), opacity: 0.5),
            ]
        )
        let greenThenRed = try OverlayCompositing.composite(
            base: Self.base,
            overlays: [
                Overlay(source: .image(Self.green), opacity: 0.5),
                Overlay(source: .image(Self.red), opacity: 0.5),
            ]
        )
        #expect(redThenGreen != greenThenRed)
    }

    @Test(
        "[Unit][VOX-R2D-011][VOX-API-003] a mask is a two-label segmentation"
    )
    func maskIsATwoLabelSegmentation() throws {
        // There is no separate mask model: a two-entry table whose first entry
        // has zero alpha is exactly a mask, and a background label is simply an
        // entry that contributes nothing.
        let mask = [
            OverlayEntry(red: 0, green: 0, blue: 0, alpha: 0),
            OverlayEntry(red: 0, green: 255, blue: 0, alpha: 255),
        ]
        #expect(
            try composite(.labelled(label: 0, table: mask))
                == entryPixel(10, 20, 30)
        )
        #expect(
            try composite(.labelled(label: 1, table: mask))
                == entryPixel(0, 255, 0)
        )

        // A segmentation selects its own label's colour.
        #expect(
            try composite(.labelled(label: 2, table: Self.segmentation))
                == entryPixel(0, 0, 255)
        )

        // An image overlay's per-pixel alpha multiplies the layer opacity, so
        // a half-transparent entry at half opacity is a quarter contribution.
        let translucent = OverlayEntry(
            red: 0,
            green: 0,
            blue: 255,
            alpha: 128
        )
        let quarter = try OverlayCompositing.composite(
            base: Self.base,
            overlays: [Overlay(source: .image(translucent), opacity: 0.5)]
        )
        let half = try OverlayCompositing.composite(
            base: Self.base,
            overlays: [Overlay(source: .image(translucent), opacity: 1)]
        )
        #expect(quarter.blue < half.blue)
    }

    @Test(
        "[Unit][VOX-R2D-011][VOX-ERR-001] an unmapped label and an invalid opacity are rejected"
    )
    func unmappedLabelAndInvalidOpacityAreRejected() throws {
        // Rejected, NOT clamped: clamping would paint a label nobody assigned
        // a colour to with the last colour in the table.
        #expect(throws: OverlayCompositingError.unmappedLabel) {
            try composite(.labelled(label: 3, table: Self.segmentation))
        }
        #expect(throws: OverlayCompositingError.unmappedLabel) {
            try composite(.labelled(label: -1, table: Self.segmentation))
        }

        for bad in [-0.000_000_1, 1.000_000_1, Double.nan, Double.infinity] {
            #expect(throws: OverlayCompositingError.invalidOpacity) {
                try OverlayCompositing.composite(
                    base: Self.base,
                    overlays: [
                        Overlay(source: .image(Self.red), opacity: bad)
                    ]
                )
            }
        }

        let errors: [OverlayCompositingError] = [
            .invalidOpacity, .unmappedLabel,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "invalidOpacity", "unmappedLabel",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private static let base = DisplayPixelRGBA8(
        red: 10,
        green: 20,
        blue: 30,
        alpha: 255
    )
    private static let red = OverlayEntry(
        red: 255,
        green: 0,
        blue: 0,
        alpha: 255
    )
    private static let green = OverlayEntry(
        red: 0,
        green: 255,
        blue: 0,
        alpha: 255
    )
    private static let translucent = OverlayEntry(
        red: 0,
        green: 0,
        blue: 255,
        alpha: 128
    )
    private static let mask = [
        OverlayEntry(red: 0, green: 0, blue: 0, alpha: 0),
        OverlayEntry(red: 0, green: 255, blue: 0, alpha: 255),
    ]
    private static let segmentation = [
        OverlayEntry(red: 0, green: 0, blue: 0, alpha: 0),
        OverlayEntry(red: 255, green: 0, blue: 0, alpha: 255),
        OverlayEntry(red: 0, green: 0, blue: 255, alpha: 255),
    ]

    private func analyticalFixtures() -> [Fixture] {
        func fixture(
            _ name: String,
            _ overlays: [Overlay],
            base: DisplayPixelRGBA8 = OverlayCompositingTests.base
        ) -> Fixture {
            Fixture(name: name, base: base, overlays: overlays)
        }
        func image(_ entry: OverlayEntry, _ opacity: Double) -> Overlay {
            Overlay(source: .image(entry), opacity: opacity)
        }
        func label(
            _ value: Int,
            _ table: [OverlayEntry],
            _ opacity: Double = 1
        ) -> Overlay {
            Overlay(
                source: .labelled(label: value, table: table),
                opacity: opacity
            )
        }
        let opaque = OverlayEntry(
            red: 255,
            green: 255,
            blue: 255,
            alpha: 255
        )
        let black = OverlayEntry(red: 0, green: 0, blue: 0, alpha: 255)
        return [
            fixture("opaque-overlay", [image(Self.red, 1)]),
            fixture("transparent-overlay", [image(Self.red, 0)]),
            fixture("half-alpha", [image(Self.red, 0.5)]),
            fixture(
                "order-red-then-green",
                [image(Self.red, 0.5), image(Self.green, 0.5)]
            ),
            fixture(
                "order-green-then-red",
                [image(Self.green, 0.5), image(Self.red, 0.5)]
            ),
            fixture(
                "single-rounding",
                [image(Self.red, 0.3), image(Self.green, 0.3)]
            ),
            fixture("mask-absent", [label(0, Self.mask)]),
            fixture("mask-present", [label(1, Self.mask)]),
            fixture(
                "segmentation-second-label",
                [label(2, Self.segmentation)]
            ),
            fixture("segmentation-background", [label(0, Self.segmentation)]),
            fixture(
                "image-overlay-translucent",
                [image(Self.translucent, 0.5)]
            ),
            fixture("image-overlay-full", [image(Self.translucent, 1)]),
            fixture(
                "clamp-at-white",
                [image(opaque, 1)],
                base: DisplayPixelRGBA8(
                    red: 255,
                    green: 255,
                    blue: 255,
                    alpha: 255
                )
            ),
            fixture(
                "clamp-at-black",
                [image(black, 1)],
                base: DisplayPixelRGBA8(
                    red: 0,
                    green: 0,
                    blue: 0,
                    alpha: 255
                )
            ),
            fixture("unmapped-label", [label(3, Self.segmentation)]),
            fixture("negative-label", [label(-1, Self.segmentation)]),
            fixture("opacity-above-one", [image(Self.red, 1.000_000_1)]),
            fixture("opacity-not-a-number", [image(Self.red, .nan)]),
        ]
    }

    // MARK: - Helpers

    private func composite(
        _ source: OverlaySource
    ) throws -> DisplayPixelRGBA8 {
        try OverlayCompositing.composite(
            base: Self.base,
            overlays: [Overlay(source: source, opacity: 1)]
        )
    }

    private func entryPixel(
        _ red: UInt8,
        _ green: UInt8,
        _ blue: UInt8
    ) -> DisplayPixelRGBA8 {
        DisplayPixelRGBA8(red: red, green: green, blue: blue, alpha: 255)
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

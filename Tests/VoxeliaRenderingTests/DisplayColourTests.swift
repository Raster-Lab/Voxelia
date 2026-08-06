// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaRendering

@Suite("Display colour vocabulary")
struct DisplayColourTests {
    @Test(
        "[Unit][VOX-R2D-015][VOX-ERR-001] the admission is exactly two blank-field cases"
    )
    func admissionIsExactlyTwoBlankFieldCases() throws {
        _ = try DisplayColourSpace(
            namespace: "IEC",
            code: "61966-2-1",
            displayName: nil
        )

        for blank in ["", " ", "\t", "\u{00A0}", "\u{3000}"] {
            #expect(throws: DisplayColourSpaceError.emptyNamespace) {
                try DisplayColourSpace(
                    namespace: blank,
                    code: "61966-2-1",
                    displayName: nil
                )
            }
            #expect(throws: DisplayColourSpaceError.emptyCode) {
                try DisplayColourSpace(
                    namespace: "IEC",
                    code: blank,
                    displayName: nil
                )
            }
        }

        // There is no invalid-code case: the project holds no registry of
        // colour-space codes, so an unrecognised code is admitted rather than
        // judged against a list this project cannot attest.
        let unknown = try DisplayColourSpace(
            namespace: "vendor.example",
            code: "not-a-real-space",
            displayName: nil
        )
        #expect(unknown.code == "not-a-real-space")

        let errors: [DisplayColourSpaceError] = [.emptyNamespace, .emptyCode]
        #expect(
            errors.map { String(describing: $0) } == [
                "emptyNamespace", "emptyCode",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    @Test(
        "[Unit][VOX-R2D-015][VOX-API-003] equality is exact, case-sensitive and name-blind"
    )
    func equalityIsExactCaseSensitiveAndNameBlind() throws {
        let sRGB = try space(namespace: "IEC", code: "sRGB")

        // The display name is human-readable text with no semantic weight, so
        // it is excluded from equality and from hashing.
        let named = try DisplayColourSpace(
            namespace: "IEC",
            code: "sRGB",
            displayName: "Standard RGB"
        )
        #expect(sRGB == named)
        #expect(sRGB.hashValue == named.hashValue)

        // Comparison is byte-for-byte: no case folding and no Unicode
        // normalisation. A code is an identifier from an external namespace,
        // and folding case would silently merge two distinct registry entries.
        #expect(try sRGB != space(namespace: "IEC", code: "SRGB"))
        #expect(try sRGB != space(namespace: "iec", code: "sRGB"))
        #expect(try sRGB != space(namespace: "ICC", code: "sRGB"))

        // A declaration carries no gamma, primaries, white point or transfer
        // characteristic — those are the inputs to a conversion this
        // vocabulary deliberately does not authorise.
        let mirror = Mirror(reflecting: sRGB)
        #expect(
            mirror.children.compactMap(\.label) == [
                "namespace", "code", "displayName",
            ]
        )
    }

    @Test(
        "[Unit][VOX-R2D-015][VOX-API-003] the transform set names what the pipeline does today"
    )
    func transformSetNamesWhatThePipelineDoesToday() {
        // Both cases describe work that exists now: the slice path presents
        // values as produced, and the volume compositor maps them through an
        // accepted one-dimensional transfer function. A single-case set would
        // make provenance claim no colour transform ran where one demonstrably
        // does.
        let transforms: [DisplayColourTransform] = [.none, .transferFunction]
        #expect(
            transforms.map { String(describing: $0) } == [
                "none", "transferFunction",
            ]
        )
        #expect(
            transforms.allSatisfy { Mirror(reflecting: $0).children.isEmpty }
        )
        #expect(Set(transforms).count == 2)
    }

    // MARK: - Helpers

    private func space(
        namespace: String,
        code: String
    ) throws -> DisplayColourSpace {
        try DisplayColourSpace(
            namespace: namespace,
            code: code,
            displayName: nil
        )
    }
}

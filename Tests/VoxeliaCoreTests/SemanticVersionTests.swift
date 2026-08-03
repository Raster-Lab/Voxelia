// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("SemanticVersion")
struct SemanticVersionTests {
    @Test("[Unit][VOX-API-004] accepts core-value boundaries")
    func acceptsCoreBoundaries() throws {
        let zero = try SemanticVersion(major: 0, minor: 0, patch: 0)
        let maximum = try SemanticVersion(
            major: Int.max,
            minor: Int.max,
            patch: Int.max
        )

        #expect((zero.major, zero.minor, zero.patch) == (0, 0, 0))
        #expect((maximum.major, maximum.minor, maximum.patch) == (Int.max, Int.max, Int.max))
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] rejects negative core values with typed errors")
    func rejectsNegativeCoreValues() {
        #expect(throws: SemanticVersionError.negativeMajor(Int.min)) {
            try SemanticVersion(major: Int.min, minor: 0, patch: 0)
        }
        #expect(throws: SemanticVersionError.negativeMinor(-1)) {
            try SemanticVersion(major: 0, minor: -1, patch: 0)
        }
        #expect(throws: SemanticVersionError.negativePatch(-1)) {
            try SemanticVersion(major: 0, minor: 0, patch: -1)
        }
    }

    @Test("[Unit][VOX-API-004] preserves valid prerelease and build identifiers")
    func acceptsValidIdentifiers() throws {
        let version = try SemanticVersion(
            major: 1,
            minor: 2,
            patch: 3,
            prerelease: "alpha.1.x-y-z.--",
            buildMetadata: "001.exp.sha-5114f85"
        )

        #expect(version.prerelease == "alpha.1.x-y-z.--")
        #expect(version.buildMetadata == "001.exp.sha-5114f85")
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] rejects malformed prerelease identifiers")
    func rejectsInvalidPrerelease() {
        let invalidValues = [
            "", ".alpha", "alpha.", "alpha..1", "01", "alpha_1", "alpha+1",
            "é",
        ]

        for value in invalidValues {
            #expect(throws: SemanticVersionError.invalidPrerelease(value)) {
                try SemanticVersion(
                    major: 1,
                    minor: 0,
                    patch: 0,
                    prerelease: value
                )
            }
        }
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] rejects malformed build identifiers")
    func rejectsInvalidBuildMetadata() {
        let invalidValues = [
            "", ".build", "build.", "build..1", "build_1", "build+1", "é",
        ]

        for value in invalidValues {
            #expect(throws: SemanticVersionError.invalidBuildMetadata(value)) {
                try SemanticVersion(
                    major: 1,
                    minor: 0,
                    patch: 0,
                    buildMetadata: value
                )
            }
        }
    }

    @Test("[Unit][VOX-API-004] follows canonical SemVer precedence")
    func followsCanonicalPrecedence() throws {
        let prereleases = [
            "alpha", "alpha.1", "alpha.beta", "beta", "beta.2", "beta.11",
            "rc.1",
        ]
        let ordered =
            try prereleases.map {
                try SemanticVersion(major: 1, minor: 0, patch: 0, prerelease: $0)
            } + [SemanticVersion(major: 1, minor: 0, patch: 0)]

        for pair in zip(ordered, ordered.dropFirst()) {
            #expect(pair.0 < pair.1)
        }
        #expect(
            try SemanticVersion(major: 1, minor: 9, patch: 9)
                < SemanticVersion(major: 2, minor: 0, patch: 0))
        #expect(
            try SemanticVersion(major: 1, minor: 1, patch: 9)
                < SemanticVersion(major: 1, minor: 2, patch: 0))
        #expect(
            try SemanticVersion(major: 1, minor: 1, patch: 1)
                < SemanticVersion(major: 1, minor: 1, patch: 2))
    }

    @Test("[Unit][VOX-API-004] compares prerelease identifiers without overflow")
    func comparesLargePrereleaseIdentifiers() throws {
        let shorter = String(repeating: "9", count: 100)
        let longer = "1" + String(repeating: "0", count: 100)
        let numeric = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            prerelease: shorter
        )
        let largerNumeric = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            prerelease: longer
        )
        let alpha = try SemanticVersion(
            major: 1,
            minor: 0,
            patch: 0,
            prerelease: "alpha"
        )

        #expect(numeric < largerNumeric)
        #expect(largerNumeric < alpha)
        #expect(
            try SemanticVersion(major: 1, minor: 0, patch: 0, prerelease: "alpha")
                < SemanticVersion(major: 1, minor: 0, patch: 0, prerelease: "alpha.1"))
    }

    @Test("[Unit][VOX-API-004] build metadata does not affect identity or precedence")
    func ignoresBuildMetadataForComparableIdentity() throws {
        let first = try SemanticVersion(
            major: 1,
            minor: 2,
            patch: 3,
            buildMetadata: "build.1"
        )
        let second = try SemanticVersion(
            major: 1,
            minor: 2,
            patch: 3,
            buildMetadata: "build.2"
        )

        #expect(first == second)
        #expect(!(first < second))
        #expect(!(second < first))
        #expect(Set([first, second]).count == 1)
        #expect(first.buildMetadata == "build.1")
        #expect(second.buildMetadata == "build.2")
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] Codable preserves fields and revalidates input")
    func codableRoundTripAndValidation() throws {
        let version = try SemanticVersion(
            major: 1,
            minor: 2,
            patch: 3,
            prerelease: "rc.1",
            buildMetadata: "001"
        )
        let encoded = try JSONEncoder().encode(version)
        let decoded = try JSONDecoder().decode(SemanticVersion.self, from: encoded)

        #expect(decoded.major == version.major)
        #expect(decoded.minor == version.minor)
        #expect(decoded.patch == version.patch)
        #expect(decoded.prerelease == version.prerelease)
        #expect(decoded.buildMetadata == version.buildMetadata)

        let invalidValues: [(json: String, expectedError: SemanticVersionError)] = [
            (
                #"{"major":-1,"minor":0,"patch":0,"prerelease":null,"buildMetadata":null}"#,
                .negativeMajor(-1)
            ),
            (
                #"{"major":1,"minor":0,"patch":0,"prerelease":"01","buildMetadata":null}"#,
                .invalidPrerelease("01")
            ),
            (
                #"{"major":1,"minor":0,"patch":0,"prerelease":null,"buildMetadata":"bad_value"}"#,
                .invalidBuildMetadata("bad_value")
            ),
        ]
        for invalidValue in invalidValues {
            do {
                _ = try JSONDecoder().decode(
                    SemanticVersion.self,
                    from: Data(invalidValue.json.utf8)
                )
                #expect(Bool(false), "Expected invalid semantic version to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
                #expect(
                    context.underlyingError as? SemanticVersionError
                        == invalidValue.expectedError
                )
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }
}

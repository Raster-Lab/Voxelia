// SPDX-License-Identifier: MIT

import Foundation
import Testing

@testable import VoxeliaCore

@Suite("CanonicalInstant")
struct CanonicalInstantTests {
    @Test("[Unit][CDMS-7.7][VOX-META-003] accepts the canonical profile exactly")
    func acceptsCanonicalProfile() throws {
        let validValues = [
            "0001-01-01T00:00:00Z",
            "9999-12-31T23:59:59.999999999Z",
            "2026-08-02T12:34:56Z",
            "2026-08-02T12:34:56.1Z",
            "2026-08-02T12:34:56.12Z",
            "2026-08-02T12:34:56.123Z",
            "2026-08-02T12:34:56.1234Z",
            "2026-08-02T12:34:56.12345Z",
            "2026-08-02T12:34:56.123456Z",
            "2026-08-02T12:34:56.1234567Z",
            "2026-08-02T12:34:56.12345678Z",
            "2026-08-02T12:34:56.123456789Z",
            "2026-08-02T12:34:56.000001Z",
            "2024-02-29T00:00:00Z",
            "2000-02-29T23:59:59Z",
        ]
        for validValue in validValues {
            let instant = try CanonicalInstant(utcString: validValue)
            #expect(instant.utcString == validValue)
            #expect(validValue.utf8.count <= CanonicalInstant.maximumUTF8ByteCount)
        }

        #expect(
            try CanonicalInstant(utcString: "2026-08-02T12:34:56Z")
                == CanonicalInstant(utcString: "2026-08-02T12:34:56Z")
        )
        #expect(
            Set([
                try CanonicalInstant(utcString: "2026-08-02T12:34:56Z"),
                try CanonicalInstant(utcString: "2026-08-02T12:34:56.1Z"),
                try CanonicalInstant(utcString: "2026-08-02T12:34:56Z"),
            ]).count == 2
        )
        requireSendable(CanonicalInstant.self)
        requireSendable(CanonicalInstantError.self)
    }

    @Test("[Unit][CDMS-7.7][VOX-VAL-007] matches a 400-year Gregorian cycle oracle")
    func matchesGregorianCycleOracle() throws {
        for year in 2001...2400 {
            let isLeap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
            for month in 1...12 {
                let expectedDays =
                    switch month {
                    case 1, 3, 5, 7, 8, 10, 12: 31
                    case 4, 6, 9, 11: 30
                    default: isLeap ? 29 : 28
                    }
                let yearField = String(format: "%04d", year)
                let monthField = String(format: "%02d", month)
                let lastDay = String(format: "%02d", expectedDays)

                _ = try CanonicalInstant(
                    utcString: "\(yearField)-\(monthField)-\(lastDay)T00:00:00Z"
                )
                if expectedDays < 31 {
                    let overflowDay = String(format: "%02d", expectedDays + 1)
                    #expect(throws: CanonicalInstantError.dayOutOfRange) {
                        try CanonicalInstant(
                            utcString:
                                "\(yearField)-\(monthField)-\(overflowDay)T00:00:00Z"
                        )
                    }
                }
            }
        }

        for centuryFixture in [(1900, false), (2000, true), (2100, false)] {
            let spelling = "\(centuryFixture.0)-02-29T00:00:00Z"
            if centuryFixture.1 {
                _ = try CanonicalInstant(utcString: spelling)
            } else {
                #expect(throws: CanonicalInstantError.dayOutOfRange) {
                    try CanonicalInstant(utcString: spelling)
                }
            }
        }
    }

    @Test("[Unit][VOX-ERR-001] rejects out-of-range components with exact errors")
    func rejectsOutOfRangeComponents() {
        let rangeFixtures: [(value: String, expectedError: CanonicalInstantError)] = [
            ("0000-01-01T00:00:00Z", .yearOutOfRange),
            ("2026-00-02T12:34:56Z", .monthOutOfRange),
            ("2026-13-02T12:34:56Z", .monthOutOfRange),
            ("2026-08-00T12:34:56Z", .dayOutOfRange),
            ("2026-08-32T12:34:56Z", .dayOutOfRange),
            ("2026-02-30T12:34:56Z", .dayOutOfRange),
            ("2026-04-31T12:34:56Z", .dayOutOfRange),
            ("2023-02-29T12:34:56Z", .dayOutOfRange),
            ("2026-08-02T24:00:00Z", .hourOutOfRange),
            ("2026-08-02T12:60:56Z", .minuteOutOfRange),
            ("2026-08-02T12:34:60Z", .unsupportedLeapSecond),
            ("2026-08-02T12:34:61Z", .secondOutOfRange),
            ("2026-08-02T12:34:99Z", .secondOutOfRange),
        ]
        for rangeFixture in rangeFixtures {
            #expect(throws: rangeFixture.expectedError) {
                try CanonicalInstant(utcString: rangeFixture.value)
            }
        }
    }

    @Test("[Unit][VOX-ERR-001] rejects noncanonical spellings with exact errors")
    func rejectsNoncanonicalSpellings() {
        let lengthFixtures = [
            "",
            "2026-08-02T12:34Z",
            "2026-08-02T12:34:56",
            "2026-08-02T12:34:56.Z",
            "2026-08-02T12:34:56.1234567891Z",
            "2026-08-02T12:34:56.123456789123456789Z",
            String(repeating: "1", count: 64),
        ]
        for lengthFixture in lengthFixtures {
            #expect(throws: CanonicalInstantError.invalidLength) {
                try CanonicalInstant(utcString: lengthFixture)
            }
        }

        let syntaxFixtures = [
            "2026-08-02t12:34:56Z",
            "2026-08-02T12:34:56z",
            "2026-08-02 12:34:56Z",
            "2026/08/02T12:34:56Z",
            "2026-W31-6T12:34:56Z",
            "2026-08-02T12:34:56+00:00",
            "2026-08-02T12:34:56-00:00",
            "2026-08-02T12:34:56Z[UTC]",
            "2026-08-02T12:34:56.\u{0666}Z",
            "2026-08-02T12:34:5AZ",
        ]
        for syntaxFixture in syntaxFixtures {
            #expect(throws: CanonicalInstantError.invalidSyntax) {
                try CanonicalInstant(utcString: syntaxFixture)
            }
        }

        let fractionFixtures = [
            "2026-08-02T12:34:56.0Z",
            "2026-08-02T12:34:56.100Z",
            "2026-08-02T12:34:56.120Z",
            "2026-08-02T12:34:56.000000000Z",
        ]
        for fractionFixture in fractionFixtures {
            #expect(throws: CanonicalInstantError.nonCanonicalFraction) {
                try CanonicalInstant(utcString: fractionFixture)
            }
        }
    }

    @Test("[Unit][VOX-ERR-001] applies deterministic error precedence")
    func appliesErrorPrecedence() {
        let precedenceFixtures: [(value: String, expectedError: CanonicalInstantError)] = [
            ("0000-13-32T24:60:61.0Z", .yearOutOfRange),
            ("2026-13-32T24:60:61.0Z", .monthOutOfRange),
            ("2026-08-32T24:60:61.0Z", .dayOutOfRange),
            ("2026-08-02T24:60:61.0Z", .hourOutOfRange),
            ("2026-08-02T12:60:61.0Z", .minuteOutOfRange),
            ("2026-08-02T12:34:60.0Z", .unsupportedLeapSecond),
            ("2026-08-02T12:34:61.0Z", .secondOutOfRange),
            ("2026-08-02T12:34:56.0Z", .nonCanonicalFraction),
            ("202X-13-32T24:60:61.0Z", .invalidSyntax),
            ("0000-13-32T24:60:61.1234567890Z", .invalidLength),
        ]
        for precedenceFixture in precedenceFixtures {
            #expect(throws: precedenceFixture.expectedError) {
                try CanonicalInstant(utcString: precedenceFixture.value)
            }
        }
    }

    @Test("[Unit][VOX-SEC-003] deterministic pseudo-fuzzing never crashes or leaks text")
    func pseudoFuzzingIsTotal() {
        var state: UInt64 = 0x5DEECE66D
        func nextByte() -> UInt8 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return UInt8((state >> 33) % 96) + 32
        }

        for length in 0...40 {
            for _ in 0..<64 {
                let candidate = String(
                    decoding: (0..<length).map { _ in nextByte() },
                    as: UTF8.self
                )
                do {
                    let instant = try CanonicalInstant(utcString: candidate)
                    #expect(instant.utcString == candidate)
                } catch let error as CanonicalInstantError {
                    // Payload-free cases cannot echo meaningful source text.
                    if candidate.count >= 4 {
                        #expect(!String(describing: error).contains(candidate))
                    }
                } catch {
                    #expect(Bool(false), "Unexpected error type: \(error)")
                }
            }
        }
    }

    @Test("[Unit][VOX-API-004] Codable uses one exact JSON string")
    func codableUsesExactString() throws {
        let instant = try CanonicalInstant(utcString: "2026-08-02T12:34:56.000001Z")
        let data = try JSONEncoder().encode([instant])
        #expect(
            String(decoding: data, as: UTF8.self)
                == #"["2026-08-02T12:34:56.000001Z"]"#
        )
        #expect(
            try JSONDecoder().decode([CanonicalInstant].self, from: data) == [instant]
        )
    }

    @Test("[Unit][VOX-API-004][VOX-ERR-001] decoding rejects wrong shapes and revalidates")
    func decodingRejectsAndRevalidates() {
        do {
            _ = try JSONDecoder().decode(CanonicalInstant.self, from: Data("null".utf8))
            #expect(Bool(false), "Expected null to fail decoding.")
        } catch DecodingError.valueNotFound {
            // Null is rejected for the non-optional string.
        } catch {
            #expect(Bool(false), "Expected valueNotFound, received \(error).")
        }

        for wrongShape in ["1", "true", "[]", "{}"] {
            do {
                _ = try JSONDecoder().decode(
                    CanonicalInstant.self,
                    from: Data(wrongShape.utf8)
                )
                #expect(Bool(false), "Expected a wrong-shaped instant to fail decoding.")
            } catch DecodingError.typeMismatch {
                // Non-string shapes are rejected before validation.
            } catch {
                #expect(Bool(false), "Expected typeMismatch, received \(error).")
            }
        }

        let revalidationFixtures: [(json: String, expectedError: CanonicalInstantError)] = [
            (#""2026-08-02T12:34:56.0Z""#, .nonCanonicalFraction),
            (#""2026-08-02T12:34:56+00:00""#, .invalidSyntax),
            (#""2026-02-30T12:34:56Z""#, .dayOutOfRange),
        ]
        for revalidationFixture in revalidationFixtures {
            do {
                _ = try JSONDecoder().decode(
                    CanonicalInstant.self,
                    from: Data(revalidationFixture.json.utf8)
                )
                #expect(Bool(false), "Expected an invalid instant to fail decoding.")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(context.codingPath.isEmpty)
                #expect(
                    context.underlyingError as? CanonicalInstantError
                        == revalidationFixture.expectedError
                )
                #expect(!context.debugDescription.contains("2026"))
            } catch {
                #expect(Bool(false), "Expected dataCorrupted, received \(error).")
            }
        }
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}

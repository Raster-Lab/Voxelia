// SPDX-License-Identifier: MIT

import CryptoKit
import Testing

@testable import VoxeliaExecution

@Suite("Progress observation")
struct ProgressObservationTests {
    @Test(
        "[Oracle][VOX-EXE-008][VOX-NUM-001] all ALG-0046 analytical fixtures match registered digests"
    )
    func allAnalyticalFixturesMatchRegisteredDigests() throws {
        var records = [String]()
        var payload = [UInt8]()

        for fixture in Self.fixtures {
            do {
                let sequence = try ProgressSequence.observations(
                    total: fixture.total,
                    cadence: fixture.cadence
                )
                try verify(sequence, total: fixture.total)
                records.append(
                    "\(fixture.name)|count=\(sequence.count)|sequence="
                        + sequence.map { "\($0.completed)/\($0.total)" }
                        .joined(separator: ";")
                )
                for observation in sequence {
                    payload.append(
                        contentsOf: littleEndianBytes(observation.completed)
                    )
                    payload.append(
                        contentsOf: littleEndianBytes(observation.total)
                    )
                }
            } catch let error as ProgressReportingError {
                records.append("\(fixture.name)|error=\(error)")
            }
        }

        #expect(records.count == 13)
        #expect(
            sha256(Array(records.joined(separator: "\n").utf8))
                == "cbe6f376b55cdb20b2b9791d8dcfbd638096d034a3fd1d20c4094359a1c27e39"
        )
        #expect(
            sha256(payload)
                == "521642346b28883ab7813dbb316ac845fc488ad7ef166c9dc71c776c846850db"
        )
    }

    @Test(
        "[Unit][VOX-EXE-008][VOX-NUM-001] the four guarantees hold and the final observation is always emitted"
    )
    func fourGuaranteesHoldAndFinalObservationIsAlwaysEmitted() throws {
        for total in [0, 1, 63, 64, 65, 4_096, 4_097] {
            let cadences = [
                1,
                ProgressSequence.facetCadence,
                ProgressSequence.vertexCadence,
            ]
            for cadence in cadences {
                let sequence = try ProgressSequence.observations(
                    total: total,
                    cadence: cadence
                )
                try verify(sequence, total: total)
            }
        }

        // Zero work reports exactly ONE observation, so no consumer needs a
        // "nothing happened" special case and a progress display terminates.
        #expect(
            try ProgressSequence.observations(total: 0, cadence: 64)
                == [ProgressObservation(completed: 0, total: 0)]
        )

        // An exact multiple of the cadence does NOT duplicate the final count.
        // Emitting the boundary and then the total is the obvious off-by-one.
        #expect(
            try ProgressSequence.observations(total: 128, cadence: 64).count
                == 3
        )
        #expect(
            try ProgressSequence.observations(total: 130, cadence: 64).count
                == 4
        )

        // A partial last step is reported at its true count, not rounded up.
        let partial = try ProgressSequence.observations(
            total: 130,
            cadence: 64
        )
        #expect(partial.last == ProgressObservation(completed: 130, total: 130))
    }

    @Test(
        "[Unit][VOX-EXE-008][VOX-ERR-001] the admission is exactly two payload-free cases"
    )
    func admissionIsExactlyTwoPayloadFreeCases() throws {
        #expect(throws: ProgressReportingError.negativeTotal) {
            try ProgressSequence.observations(total: -1, cadence: 64)
        }
        #expect(throws: ProgressReportingError.invalidCadence) {
            try ProgressSequence.observations(total: 10, cadence: 0)
        }
        #expect(throws: ProgressReportingError.invalidCadence) {
            try ProgressSequence.observations(total: 10, cadence: -1)
        }

        let errors: [ProgressReportingError] = [
            .negativeTotal, .invalidCadence,
        ]
        #expect(
            errors.map { String(describing: $0) } == [
                "negativeTotal", "invalidCadence",
            ]
        )
        #expect(errors.allSatisfy { Mirror(reflecting: $0).children.isEmpty })
    }

    // MARK: - Fixtures

    private struct Fixture: Sendable {
        let name: String
        let total: Int
        let cadence: Int
    }

    private static let fixtures: [Fixture] = [
        Fixture(name: "zero-work", total: 0, cadence: 64),
        Fixture(name: "below-one-step", total: 10, cadence: 64),
        Fixture(name: "exact-multiple", total: 128, cadence: 64),
        Fixture(name: "partial-last-step", total: 130, cadence: 64),
        Fixture(name: "single-unit", total: 1, cadence: 64),
        Fixture(name: "cadence-boundary-minus-one", total: 63, cadence: 64),
        Fixture(name: "cadence-boundary", total: 64, cadence: 64),
        Fixture(name: "cadence-boundary-plus-one", total: 65, cadence: 64),
        Fixture(name: "dense-cadence", total: 3, cadence: 1),
        Fixture(name: "vertex-cadence", total: 4_097, cadence: 4_096),
        Fixture(name: "negative-total", total: -1, cadence: 64),
        Fixture(name: "zero-cadence", total: 10, cadence: 0),
        Fixture(name: "negative-cadence", total: 10, cadence: -1),
    ]

    // MARK: - Helpers

    /// The four guarantees a consumer may rely on.
    private func verify(
        _ sequence: [ProgressObservation],
        total: Int
    ) throws {
        var previous = -1
        for observation in sequence {
            #expect(observation.total == total)
            #expect(observation.completed >= previous)
            #expect(observation.completed <= observation.total)
            previous = observation.completed
        }
        #expect(
            sequence.last == ProgressObservation(completed: total, total: total)
        )
    }

    private func littleEndianBytes(_ value: Int) -> [UInt8] {
        let pattern = UInt64(bitPattern: Int64(value))
        return (0..<8).map { byteIndex in
            UInt8(truncatingIfNeeded: pattern >> UInt64(byteIndex * 8))
        }
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: bytes).map {
            let text = String($0, radix: 16)
            return text.count == 1 ? "0" + text : text
        }.joined()
    }
}

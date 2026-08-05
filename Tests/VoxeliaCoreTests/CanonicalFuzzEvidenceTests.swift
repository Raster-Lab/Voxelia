// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaTestSupport

@testable import VoxeliaCore

@Suite("CanonicalFuzzEvidence")
struct CanonicalFuzzEvidenceTests {
    /// A deterministic linear congruential generator so every campaign
    /// run is identical.
    private struct DeterministicGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private func mutate(
        _ bytes: [UInt8],
        using generator: inout DeterministicGenerator
    ) -> [UInt8] {
        var mutant = bytes
        let operation = generator.next() % 3
        let position = Int(generator.next() % UInt64(max(1, mutant.count)))
        switch operation {
        case 0:
            mutant[position] ^= UInt8(1 << (generator.next() % 8))
        case 1:
            mutant.insert(UInt8(truncatingIfNeeded: generator.next()), at: position)
        default:
            mutant.remove(at: position)
        }
        return mutant
    }

    private func generousLimits() -> CanonicalMetadataIngressLimits {
        CanonicalMetadataIngressLimits(
            maximumRawDocumentByteCount: 65_536,
            maximumRawTokenByteCount: 8_192,
            maximumDecodedStringByteCount: 8_192,
            maximumEncodedBinaryByteCount: 8_192,
            maximumDecodedBinaryByteCount: 8_192,
            maximumDirectMemberCount: 4_096,
            maximumRawNestingDepth: 64
        )
    }

    @Test("[Unit][VOX-SEC-001][VOX-ERR-001] mutation campaigns never accept noncanonical bytes")
    func mutationCampaignsNeverAcceptNoncanonicalBytes() throws {
        // The ADR-0076 invariant over every registered golden corpus
        // document: each deterministic mutant is either rejected by
        // throwing or accepted as a record whose canonical re-emission
        // equals the mutant byte for byte.
        let provenanceCorpus = [
            try CanonicalProvenanceJSON.encodeRecordDocument(
                record: try FuzzFixtures.originRecord(),
                maximumOutputByteCount: 16_384
            ),
            try CanonicalProvenanceJSON.encodeRecordDocument(
                record: try FuzzFixtures.operationRecord(),
                maximumOutputByteCount: 16_384
            ),
        ]
        let derivationCorpus = [
            try CanonicalDerivationJSON.encodeRecordDocument(
                record: try FuzzFixtures.fullDerivation(),
                maximumOutputByteCount: 16_384
            ),
            try CanonicalDerivationJSON.encodeRecordDocument(
                record: try FuzzFixtures.generatorDerivation(),
                maximumOutputByteCount: 16_384
            ),
        ]
        let metadataCorpus = [
            try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        ]

        var generator = DeterministicGenerator(state: 0x5EED_0001)
        var provenanceAccepted = 0
        for document in provenanceCorpus {
            for _ in 0..<400 {
                let mutant = mutate(document, using: &generator)
                do {
                    let record = try CanonicalProvenanceJSON.decodeRecordDocument(
                        from: mutant,
                        maximumInputByteCount: 65_536
                    )
                    provenanceAccepted += 1
                    #expect(
                        try CanonicalProvenanceJSON.encodeRecordDocument(
                            record: record,
                            maximumOutputByteCount: 65_536
                        ) == mutant
                    )
                } catch {}
            }
        }
        var derivationAccepted = 0
        for document in derivationCorpus {
            for _ in 0..<400 {
                let mutant = mutate(document, using: &generator)
                do {
                    let record = try CanonicalDerivationJSON.decodeRecordDocument(
                        from: mutant,
                        maximumInputByteCount: 65_536
                    )
                    derivationAccepted += 1
                    #expect(
                        try CanonicalDerivationJSON.encodeRecordDocument(
                            record: record,
                            maximumOutputByteCount: 65_536
                        ) == mutant
                    )
                } catch {}
            }
        }
        var metadataAccepted = 0
        for document in metadataCorpus {
            for _ in 0..<400 {
                let mutant = mutate(document, using: &generator)
                do {
                    let decoded = try CanonicalMetadataJSON.decodeDocument(
                        canonicalBytes: mutant,
                        limits: generousLimits(),
                        multiplicityContext: nil
                    )
                    metadataAccepted += 1
                    #expect(
                        try CanonicalMetadataJSON.encodeUniqueDocument(
                            payload: decoded.payload,
                            maximumOutputByteCount: 65_536
                        ) == mutant
                    )
                } catch {}
            }
        }

        // The campaign sizes are exact evidence of coverage; accepted
        // mutants are rare and every one satisfied the re-emission
        // invariant above.
        #expect(provenanceAccepted + derivationAccepted + metadataAccepted < 100)
    }

    @Test("[Unit][VOX-VAL-007][VOX-SEC-001] python round-trips every canonical number token")
    func pythonRoundTripsEveryCanonicalNumberToken() throws {
        // 256 deterministic finite binary64 values; the host python3
        // interpreter's independent parser must round-trip every token
        // to the bit-identical value, and so must Swift's own parser.
        #expect(
            VoxeliaTestSupport.lowercaseHex16(0x0123_4567_89AB_CDEF)
                == "0123456789abcdef"
        )
        var generator = DeterministicGenerator(state: 0x0AC1_E000)
        var lines = [String]()
        while lines.count < 256 {
            let bitPattern = generator.next()
            let value = Double(bitPattern: bitPattern)
            guard value.isFinite else {
                continue
            }
            guard let token = CanonicalMetadataJSON.canonicalNumberToken(value)
            else {
                #expect(Bool(false), "Expected a token for every finite value.")
                return
            }
            let text = String(decoding: token, as: UTF8.self)
            let swiftParsed = try #require(Double(text))
            #expect(swiftParsed.bitPattern == value.bitPattern)
            lines.append(
                VoxeliaTestSupport.lowercaseHex16(bitPattern) + " " + text
            )
        }

        let script = """
            import struct, sys
            count = 0
            for line in sys.stdin.read().splitlines():
                hexPattern, token = line.split(" ")
                expected = struct.unpack(">d", bytes.fromhex(hexPattern))[0]
                parsed = float(token)
                assert struct.pack(">d", parsed) == struct.pack(">d", expected), line
                count += 1
            print("OK", count)
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
        )
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines) == "OK 256")
    }
}

/// Shared corpus fixtures for the deterministic campaigns.
private enum FuzzFixtures {
    static func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    static func parameterDigest() throws -> ContentID {
        try ContentID.operationParametersIdentity(
            overCanonicalBytes: try CanonicalMetadataJSON.encodeUniqueDocument(
                payload: try MetadataCollection(entries: []),
                maximumOutputByteCount: 4_096
            )
        )
    }

    static func originRecord() throws -> ProvenanceRecord {
        try ProvenanceRecord(
            id: ProvenanceID(rawValue: "record-1")!,
            kind: .source,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(DataObjectID(rawValue: "series-7")!),
            software: try software(),
            activity: .origin,
            inputs: [],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    static func operationRecord() throws -> ProvenanceRecord {
        let claimVersion = try SemanticVersion(major: 1, minor: 0, patch: 0)
        return try ProvenanceRecord(
            id: ProvenanceID(rawValue: "record-2")!,
            kind: .transformed,
            createdAt: try CanonicalInstant(utcString: "2026-08-04T12:00:00Z"),
            subject: .object(DataObjectID(rawValue: "series-8")!),
            software: try software(),
            activity: .operation(
                try OperationProvenance(
                    operationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.op.window-level"
                    ),
                    operationVersion: claimVersion,
                    implementationID: try DerivationOperationToken(
                        rawValue: "org.voxelia.impl.window-level.cpu"
                    ),
                    implementationVersion: claimVersion,
                    parameterDigest: try parameterDigest()
                ),
                ExecutionProvenanceClaim(
                    profile: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.profile.default"
                        ),
                        version: claimVersion
                    ),
                    backend: try ExecutionComponentReference(
                        identifier: try ExecutionClaimToken(
                            rawValue: "org.voxelia.backend.cpu"
                        ),
                        version: claimVersion
                    ),
                    precisionPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.precision.binary64-strict"
                    ),
                    qualityPolicy: try ExecutionClaimToken(
                        rawValue: "org.voxelia.quality.full"
                    ),
                    approximationStatus: .exact,
                    capabilityClass: nil,
                    kernel: nil
                )
            ),
            inputs: [
                try ProvenanceInput(
                    role: try ProvenanceInputRole(rawValue: "input"),
                    occurrence: 1,
                    identity: .object(DataObjectID(rawValue: "series-7")!),
                    parent: .graphNode(ProvenanceID(rawValue: "record-1")!)
                )
            ],
            warnings: [],
            validationClaim: .unknown,
            declaresZeroInputGenerator: false
        )
    }

    static func fullDerivation() throws -> DerivationIdentity {
        try DerivationIdentity(
            operationID: try DerivationOperationToken(
                rawValue: "org.voxelia.op.window-level"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            implementation: DerivationImplementationReference(
                identifier: try DerivationOperationToken(
                    rawValue: "org.voxelia.impl.window-level.cpu"
                ),
                version: try SemanticVersion(
                    major: 2,
                    minor: 1,
                    patch: 0,
                    buildMetadata: "build7"
                )
            ),
            inputs: [
                DerivationInput(
                    role: try DerivationInputRole(rawValue: "input"),
                    identity: .object(DataObjectID(rawValue: "series-6")!)
                )
            ],
            parameterDigest: try parameterDigest(),
            declaresZeroInputGenerator: false
        )
    }

    static func generatorDerivation() throws -> DerivationIdentity {
        try DerivationIdentity(
            operationID: try DerivationOperationToken(
                rawValue: "org.voxelia.op.window-level"
            ),
            operationVersion: try SemanticVersion(major: 1, minor: 0, patch: 0),
            implementation: nil,
            inputs: [],
            parameterDigest: try parameterDigest(),
            declaresZeroInputGenerator: true
        )
    }
}

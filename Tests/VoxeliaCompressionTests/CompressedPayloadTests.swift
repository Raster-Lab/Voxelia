// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaStorage

@testable import VoxeliaCompression

/// `ADR-0256`: the compression module boundary (`VOX-CMP-002`) and the
/// never-sampleable invariant (`VOX-CMP-007`).
@Suite("CompressedPayload")
struct CompressedPayloadTests {
    private func format(
        _ type: ScalarType = .uint16
    ) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: nil, byteOrder: .littleEndian)
    }

    private func payload(
        codestream: [UInt8] = [1, 2, 3, 4],
        extents: [Int] = [4, 3, 2],
        type: ScalarType = .uint16
    ) throws -> CompressedPayload {
        try CompressedPayload(
            codestream: ContiguousArray(codestream),
            declaredExtents: ContiguousArray(extents),
            declaredScalarFormat: try format(type)
        )
    }

    // MARK: - VOX-CMP-007, the never-sampleable invariant

    @Test("[Unit][VOX-CMP-007] a compressed payload is not sampleable storage")
    func compressedPayloadIsNotSampleableStorage() throws {
        // The invariant stated as a test rather than as a comment. The accepted
        // storage and render paths consume `ImageStorageContract`; if anyone ever
        // conforms `CompressedPayload` to it, compressed bytes become bindable as
        // decoded samples and this fails.
        //
        // A runtime check is used deliberately: a compile-time absence proves
        // nothing, because it is exactly what a later edit would remove.
        let subject = try payload()
        #expect(!((subject as Any) is any ImageStorageContract))

        // Positive control, so the check above is known to be capable of
        // failing. A test that always passes because its predicate never matches
        // anything is not evidence. A REAL conformer is used rather than a stub:
        // `StorageSnapshotHandle`'s initialiser is private, which is itself the
        // storage contract refusing to be faked.
        let conformer = try ContiguousImageStorage(
            binding: try LogicalSampleBinding(
                shape: try ImageShape(extents: [2, 2]),
                scalarType: .uint8,
                componentCount: 1
            ),
            bytes: [1, 2, 3, 4]
        )
        #expect((conformer as Any) is any ImageStorageContract)
    }

    @Test("[Unit][VOX-CMP-007] the payload exposes no decoded sample accessor")
    func payloadExposesNoDecodedSampleAccessor() throws {
        // The complement of the conformance check: the type's own surface offers
        // the codestream and the source's *declarations*, and nothing that reads
        // like decoded samples. Every shape-bearing member is named `declared`,
        // so a caller cannot mistake a claim for a measurement.
        let subject = try payload()
        #expect(subject.codestreamByteCount == 4)
        #expect(Array(subject.declaredExtents) == [4, 3, 2])
        #expect(subject.declaredScalarFormat.type == .uint16)
        // 4 * 3 * 2 samples of two bytes.
        #expect(subject.declaredDecodedByteCount == 48)
    }

    // MARK: - Declared shape arithmetic

    @Test("[Unit][VOX-CMP-002] the declared decoded byte count is derived, not claimed")
    func declaredDecodedByteCountIsDerived() throws {
        // Derived at admission so it cannot disagree with the extents and format
        // it comes from. A separately supplied byte count would be a second place
        // for one fact to live.
        #expect(try payload(extents: [1], type: .uint8).declaredDecodedByteCount == 1)
        #expect(
            try payload(extents: [512, 512], type: .uint16).declaredDecodedByteCount == 524_288)
        #expect(
            try payload(extents: [512, 512, 899], type: .uint16)
                .declaredDecodedByteCount == 471_334_912
        )
    }

    @Test("[Unit][VOX-CMP-002] the expansion ratio reports declared bytes over codestream bytes")
    func expansionRatioReportsDeclaredOverCodestream() throws {
        // 48 declared decoded bytes over 4 codestream bytes.
        let subject = try payload()
        #expect(subject.declaredExpansionRatio == 12.0)
    }

    // MARK: - Admissions

    @Test("[Unit][VOX-CMP-002][VOX-ERR-001] payload admission rejects typed")
    func payloadAdmissionRejectsTyped() throws {
        #expect(throws: CompressedPayloadError.emptyCodestream) {
            try payload(codestream: [])
        }
        #expect(throws: CompressedPayloadError.missingDeclaredExtents) {
            try payload(extents: [])
        }
        #expect(throws: CompressedPayloadError.invalidDeclaredExtent) {
            try payload(extents: [4, 0, 2])
        }
        #expect(throws: CompressedPayloadError.invalidDeclaredExtent) {
            try payload(extents: [4, -1, 2])
        }
    }

    @Test(
        "[Unit][VOX-CMP-002][VOX-SEC-001] an overflowing declared shape rejects rather than traps")
    func overflowingDeclaredShapeRejects() throws {
        // A hostile or corrupt source can declare extents whose product overflows.
        // This is the one place that product is formed, so it is checked rather
        // than argued: the failure is typed, and the process does not trap.
        #expect(throws: CompressedPayloadError.declaredByteCountNotRepresentable) {
            try payload(extents: [Int.max, 2])
        }
        #expect(throws: CompressedPayloadError.declaredByteCountNotRepresentable) {
            try payload(extents: [Int.max / 4, 4, 4])
        }
        // The byte-count multiply overflows even when the sample count does not:
        // a sample count just under the ceiling, times two bytes per sample.
        #expect(throws: CompressedPayloadError.declaredByteCountNotRepresentable) {
            try payload(extents: [Int.max / 2 + 1], type: .uint16)
        }
    }

    @Test("[Unit][VOX-CMP-002] a maximal admissible shape is accepted")
    func maximalAdmissibleShapeIsAccepted() throws {
        // The boundary from the admitted side, so the overflow checks above are
        // shown to reject only what genuinely overflows.
        let subject = try payload(extents: [Int.max / 2], type: .uint16)
        #expect(subject.declaredDecodedByteCount == (Int.max / 2) * 2)
    }
}

// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// `ADR-0258` (`VOX-CMP-010`): a decode is admitted against its payload's
/// declarations, and the destination is bounded before any decode runs.
@Suite("CompressedDecodeValidator")
struct CompressedDecodeValidatorTests {
    private func format(
        _ type: ScalarType = .uint16,
        byteOrder: ByteOrder = .littleEndian
    ) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: nil, byteOrder: byteOrder)
    }

    /// A payload declaring 4x3x2 uint16 single-component samples: 48 bytes.
    private func payload(
        extents: [Int] = [4, 3, 2],
        type: ScalarType = .uint16,
        components: Int = 1
    ) throws -> CompressedPayload {
        try CompressedPayload(
            codestream: ContiguousArray([1, 2, 3, 4]),
            declaredExtents: ContiguousArray(extents),
            declaredScalarFormat: try format(type),
            declaredComponentCount: components
        )
    }

    /// The decode report that matches the default payload exactly.
    private func matchingClaim(
        byteCount: Int = 48,
        extents: [Int] = [4, 3, 2],
        type: ScalarType = .uint16,
        byteOrder: ByteOrder = .littleEndian,
        components: Int = 1
    ) throws -> DecodedSampleClaim {
        DecodedSampleClaim(
            byteCount: byteCount,
            extents: ContiguousArray(extents),
            scalarFormat: try format(type, byteOrder: byteOrder),
            componentCount: components
        )
    }

    // MARK: - The pre-decode ceiling

    @Test("[Unit][VOX-CMP-010][VOX-SEC-001] the destination ceiling refuses before any decode")
    func destinationCeilingRefusesBeforeDecode() throws {
        let subject = try payload()
        #expect(subject.declaredDecodedByteCount == 48)

        // At and above the declared size: admitted.
        try CompressedDecodeValidator.admitDestination(
            for: subject,
            maximumDecodedByteCount: 48
        )
        try CompressedDecodeValidator.admitDestination(
            for: subject,
            maximumDecodedByteCount: 1_000
        )

        // One byte short: refused.
        #expect(throws: CompressedDecodeError.declaredByteCountExceedsCeiling) {
            try CompressedDecodeValidator.admitDestination(
                for: subject,
                maximumDecodedByteCount: 47
            )
        }
    }

    @Test("[Unit][VOX-CMP-010][VOX-SEC-001] an enormous declared shape is refused, not allocated")
    func enormousDeclaredShapeIsRefused() throws {
        // The case the ceiling exists for: a declared shape that is individually
        // representable but far larger than any caller would hold. A 4 GiB
        // single-component uint16 volume is admissible as a payload and must be
        // refused against a 512 MiB ceiling.
        let huge = try payload(extents: [2_048, 2_048, 512])
        #expect(huge.declaredDecodedByteCount == 4_294_967_296)
        #expect(throws: CompressedDecodeError.declaredByteCountExceedsCeiling) {
            try CompressedDecodeValidator.admitDestination(
                for: huge,
                maximumDecodedByteCount: 536_870_912
            )
        }
    }

    @Test("[Unit][VOX-CMP-010][VOX-ERR-001] a non-positive ceiling rejects typed")
    func nonPositiveCeilingRejectsTyped() throws {
        let subject = try payload()
        #expect(throws: CompressedDecodeError.invalidCeiling) {
            try CompressedDecodeValidator.admitDestination(
                for: subject,
                maximumDecodedByteCount: 0
            )
        }
        #expect(throws: CompressedDecodeError.invalidCeiling) {
            try CompressedDecodeValidator.admitDestination(
                for: subject,
                maximumDecodedByteCount: -1
            )
        }
    }

    // MARK: - The post-decode admission

    @Test("[Unit][VOX-CMP-010] a decode matching every declaration is admitted")
    func matchingDecodeIsAdmitted() throws {
        try CompressedDecodeValidator.admit(
            try matchingClaim(),
            against: try payload()
        )
    }

    @Test("[Unit][VOX-CMP-010][VOX-ERR-001] each disagreement rejects with its own case")
    func eachDisagreementRejectsWithItsOwnCase() throws {
        let subject = try payload()

        // Dimensions.
        #expect(throws: CompressedDecodeError.decodedExtentsMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(extents: [4, 3, 3]),
                against: subject
            )
        }
        // A permuted extent list is a disagreement, not a match: 2x3x4 and 4x3x2
        // hold the same sample count and are different images.
        #expect(throws: CompressedDecodeError.decodedExtentsMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(extents: [2, 3, 4]),
                against: subject
            )
        }
        // Rank.
        #expect(throws: CompressedDecodeError.decodedExtentsMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(extents: [4, 3]),
                against: subject
            )
        }
        // Component count.
        #expect(throws: CompressedDecodeError.decodedComponentCountMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(components: 3),
                against: subject
            )
        }
        // Scalar type.
        #expect(throws: CompressedDecodeError.decodedScalarFormatMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(type: .int16),
                against: subject
            )
        }
        // Byte order is part of the format, so it is part of the disagreement.
        #expect(throws: CompressedDecodeError.decodedScalarFormatMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(byteOrder: .bigEndian),
                against: subject
            )
        }
        // Byte count alone, with everything else agreeing.
        #expect(throws: CompressedDecodeError.decodedByteCountMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(byteCount: 47),
                against: subject
            )
        }
        // A short decode is the dangerous direction: a truncated codestream that
        // returned fewer bytes than declared must never be admitted.
        #expect(throws: CompressedDecodeError.decodedByteCountMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(byteCount: 0),
                against: subject
            )
        }
        // And an over-long decode, which would overrun a destination sized from
        // the declarations.
        #expect(throws: CompressedDecodeError.decodedByteCountMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(byteCount: 96),
                against: subject
            )
        }
    }

    @Test("[Unit][VOX-CMP-010] the most specific disagreement is the one reported")
    func mostSpecificDisagreementIsReported() throws {
        // Wrong extents necessarily make the byte count wrong too. The check order
        // is part of the contract: the caller should learn that the dimensions
        // disagree, not that a byte count derived from them does.
        #expect(throws: CompressedDecodeError.decodedExtentsMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(byteCount: 72, extents: [4, 3, 3]),
                against: try payload()
            )
        }
        // Likewise a component-count disagreement, which also moves the byte count.
        #expect(throws: CompressedDecodeError.decodedComponentCountMismatch) {
            try CompressedDecodeValidator.admit(
                try matchingClaim(byteCount: 144, components: 3),
                against: try payload()
            )
        }
    }

    @Test("[Unit][VOX-CMP-010] a multi-component payload admits its own matching decode")
    func multiComponentPayloadAdmitsItsOwnDecode() throws {
        // The complement of the mismatch cases: three components is a legitimate
        // declaration, so the refusals above are shown to be about disagreement
        // rather than about component counts above one.
        let rgb = try payload(components: 3)
        #expect(rgb.declaredDecodedByteCount == 144)
        try CompressedDecodeValidator.admit(
            try matchingClaim(byteCount: 144, components: 3),
            against: rgb
        )
    }
}

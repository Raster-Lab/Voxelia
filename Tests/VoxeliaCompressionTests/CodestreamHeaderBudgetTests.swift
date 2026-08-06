// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// `ADR-0273` (`VOX-CMP-011`): a codestream's own header must not be able to ask a
/// decoder for an unbounded allocation, and an arithmetically impossible declaration
/// must be refused rather than trapped.
///
/// The headers here are built by hand. That keeps the suite free of a codec dependency
/// and lets each case isolate one field, including the three shapes measured crashing
/// or silently amplifying the pinned decoder.
@Suite("CodestreamHeaderBudget")
struct CodestreamHeaderBudgetTests {
    // MARK: - Builders

    private static func be32(_ value: Int) -> [UInt8] {
        [
            UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
            UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value),
        ]
    }

    private static func be16(_ value: Int) -> [UInt8] {
        [UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)]
    }

    /// A codestream carrying one `SIZ` segment, laid out as the standard requires and as
    /// the encoder was measured emitting: `Lsiz` counts itself, the eight geometry words
    /// follow `Rsiz`, then `Csiz`, then one three-byte record per component, then the
    /// JP3D depth extension.
    ///
    /// For one component with the depth extension `Lsiz` is `38 + 3 + 8 = 49`, which is
    /// exactly the length the real encoder writes.
    private static func codestream(
        width: Int = 64,
        height: Int = 64,
        depth: Int? = 4,
        componentDepths: [Int] = [16],
        declaredLength: Int? = nil,
        declaredComponentCount: Int? = nil
    ) -> [UInt8] {
        let components = componentDepths.flatMap { bits -> [UInt8] in
            [UInt8(truncatingIfNeeded: bits - 1), 0x01, 0x01]  // Ssiz, XRsiz, YRsiz
        }
        let extension3D = depth.map { be32($0) + be32(1) } ?? []
        let length = declaredLength ?? (38 + components.count + extension3D.count)

        var segment: [UInt8] = be16(length)
        segment += be16(0)  // Rsiz
        segment += be32(width) + be32(height)
        segment += be32(0) + be32(0)  // XOsiz, YOsiz
        segment += be32(width) + be32(height)  // XTsiz, YTsiz
        segment += be32(0) + be32(0)  // XTOsiz, YTOsiz
        segment += be16(declaredComponentCount ?? componentDepths.count)
        segment += components + extension3D

        return [0xFF, 0x4F, 0xFF, 0x51] + segment
    }

    private func geometry(_ bytes: [UInt8]) throws -> CodestreamGeometry {
        guard case .geometry(let value) = CodestreamHeaderBudget.read(bytes) else {
            Issue.record("expected a readable geometry, got \(CodestreamHeaderBudget.read(bytes))")
            throw CodestreamBudgetError.headerNotReadable
        }
        return value
    }

    // MARK: - Reading a well-formed header

    @Test("[Unit][VOX-CMP-011] a well-formed SIZ yields the exact declared geometry")
    func wellFormedHeaderYieldsExactGeometry() throws {
        let value = try geometry(Self.codestream())
        #expect(value.width == 64)
        #expect(value.height == 64)
        #expect(value.depth == 4)
        #expect(value.componentCount == 1)
        #expect(value.bitsPerComponent == 16)
        #expect(value.bytesPerSample == 2)
        // Exactly the uncompressed volume: 64 * 64 * 4 * 1 * 2.
        #expect(value.impliedDecodedByteCount == 32_768)
    }

    @Test("[Unit][VOX-CMP-011] an absent depth extension reads as a single slice")
    func absentDepthExtensionReadsAsOneSlice() throws {
        let value = try geometry(Self.codestream(depth: nil))
        #expect(value.depth == 1)
        #expect(value.impliedDecodedByteCount == 8_192)
    }

    @Test("[Unit][VOX-CMP-011] the largest component bit depth is used, not the last")
    func largestComponentBitDepthIsUsed() throws {
        // A budget must never be under-estimated, so the maximum is taken. The pinned
        // decoder keeps only the last component's depth, which is why this is asserted
        // rather than assumed to agree.
        let value = try geometry(Self.codestream(componentDepths: [16, 8, 12]))
        #expect(value.bitsPerComponent == 16)
        #expect(value.componentCount == 3)
    }

    @Test("[Unit][VOX-CMP-011] bytes per sample rounds up to whole bytes")
    func bytesPerSampleRoundsUp() throws {
        #expect(try geometry(Self.codestream(componentDepths: [12])).bytesPerSample == 2)
        #expect(try geometry(Self.codestream(componentDepths: [1])).bytesPerSample == 1)
        #expect(try geometry(Self.codestream(componentDepths: [8])).bytesPerSample == 1)
        #expect(try geometry(Self.codestream(componentDepths: [17])).bytesPerSample == 3)
    }

    // MARK: - The three measured attacks

    @Test("[Unit][VOX-CMP-011][VOX-SEC-001] a huge declared geometry is refused")
    func hugeDeclaredGeometryIsRefused() throws {
        // Measured killing the pinned decoder's process through unbounded allocation:
        // 65535 x 65535 x 4 at 16 bits is roughly 32 GiB.
        let bytes = Self.codestream(width: 0xFFFF, height: 0xFFFF)
        let value = try geometry(bytes)
        #expect(value.impliedDecodedByteCount == 34_358_689_800)

        #expect(throws: CodestreamBudgetError.declaredGeometryExceedsCeiling) {
            try CodestreamHeaderBudget.admit(
                codestream: bytes,
                maximumDecodedByteCount: 32_768
            )
        }
    }

    @Test("[Unit][VOX-CMP-011][VOX-SEC-001] an unrepresentable geometry is refused, not trapped")
    func unrepresentableGeometryIsRefusedRatherThanTrapped() throws {
        // Measured trapping the pinned decoder immediately, before any allocation: the
        // product of two 0x7FFFFFFF dimensions overflows a 64-bit integer. Checked
        // arithmetic is the whole difference between a refusal and a crash.
        let bytes = Self.codestream(width: 0x7FFF_FFFF, height: 0x7FFF_FFFF)
        #expect(try geometry(bytes).impliedDecodedByteCount == nil)

        #expect(throws: CodestreamBudgetError.declaredGeometryNotRepresentable) {
            try CodestreamHeaderBudget.admit(
                codestream: bytes,
                maximumDecodedByteCount: Int.max
            )
        }
    }

    @Test("[Unit][VOX-CMP-011][VOX-SEC-001] a one-bit height corruption is refused")
    func oneBitHeightCorruptionIsRefused() throws {
        // The subtlest of the three. A single bit flip on one `Ysiz` byte turned a
        // 988-byte codestream into a *self-consistent* 31.9 MiB decode that reported
        // success — 0x40 becomes 0xFF40, or 65344 rows. The decoder's own output carried
        // exactly the byte count asserted here, so the two parsers agree on what the
        // corrupt header means.
        let bytes = Self.codestream(height: 0xFF40)
        #expect(try geometry(bytes).impliedDecodedByteCount == 33_456_128)

        #expect(throws: CodestreamBudgetError.declaredGeometryExceedsCeiling) {
            try CodestreamHeaderBudget.admit(
                codestream: bytes,
                maximumDecodedByteCount: 32_768
            )
        }
    }

    @Test("[Unit][VOX-CMP-011] an impossible bit depth is refused under any ceiling")
    func impossibleBitDepthIsRefusedUnderAnyCeiling() {
        // `Ssiz` can encode depths to 128 while the standard permits 1 to 38. A bit flip
        // on this byte was measured declaring 113 bits, which the pinned decoder ignored.
        // Bounding the field rather than only the product matters because a generous
        // ceiling would otherwise admit it.
        let bytes = Self.codestream(componentDepths: [113])
        #expect(CodestreamHeaderBudget.read(bytes) == .malformedJPEG2000Header)

        #expect(throws: CodestreamBudgetError.headerNotReadable) {
            try CodestreamHeaderBudget.admit(
                codestream: bytes,
                maximumDecodedByteCount: Int.max
            )
        }
        // The boundary itself: 38 is permitted, 39 is not.
        #expect(
            CodestreamHeaderBudget.read(Self.codestream(componentDepths: [38]))
                != .malformedJPEG2000Header)
        #expect(
            CodestreamHeaderBudget.read(Self.codestream(componentDepths: [39]))
                == .malformedJPEG2000Header)
    }

    // MARK: - Malformed headers

    @Test("[Unit][VOX-CMP-011] zero dimensions and zero components are refused")
    func zeroDimensionsAndComponentsAreRefused() {
        for bytes in [
            Self.codestream(width: 0),
            Self.codestream(height: 0),
            Self.codestream(depth: 0),
            Self.codestream(declaredComponentCount: 0),
        ] {
            #expect(CodestreamHeaderBudget.read(bytes) == .malformedJPEG2000Header)
        }
    }

    @Test("[Unit][VOX-CMP-011] a segment that does not fit the codestream is refused")
    func segmentNotFittingCodestreamIsRefused() {
        // A declared length alone must never drive a read past the end.
        #expect(
            CodestreamHeaderBudget.read(Self.codestream(declaredLength: 0x7FFF))
                == .malformedJPEG2000Header
        )
        // Below the standard's minimum.
        #expect(
            CodestreamHeaderBudget.read(Self.codestream(declaredLength: 37))
                == .malformedJPEG2000Header
        )
        // Long enough to be admitted, too short to hold its own component records.
        #expect(
            CodestreamHeaderBudget.read(
                Self.codestream(declaredLength: 38, declaredComponentCount: 400)
            ) == .malformedJPEG2000Header
        )
    }

    @Test("[Unit][VOX-CMP-011] truncation anywhere in the header is refused, never trapped")
    func truncationAnywhereIsRefused() {
        let full = Self.codestream()
        for length in 0..<full.count {
            let verdict = CodestreamHeaderBudget.read(Array(full.prefix(length)))
            // Below two bytes there is no SOC to recognise; above it the header is
            // present but incomplete. Neither may trap, and neither may yield a
            // geometry.
            if case .geometry = verdict {
                Issue.record("truncation to \(length) bytes yielded a geometry")
            }
        }
        // The full header does yield one, so the sweep above is not trivially true.
        if case .geometry = CodestreamHeaderBudget.read(full) {
        } else {
            Issue.record("the untruncated header should read")
        }
    }

    @Test("[Unit][VOX-CMP-011] SOC followed by something other than SIZ is refused")
    func socNotFollowedBySIZIsRefused() {
        #expect(
            CodestreamHeaderBudget.read([0xFF, 0x4F, 0x12, 0x34, 0x00, 0x30])
                == .malformedJPEG2000Header
        )
        // A real marker, but not the one the standard mandates first.
        #expect(
            CodestreamHeaderBudget.read([0xFF, 0x4F, 0xFF, 0x52, 0x00, 0x0A])
                == .malformedJPEG2000Header
        )
    }

    // MARK: - Bytes that are not JPEG 2000

    @Test("[Unit][VOX-CMP-011] non-JPEG-2000 bytes draw no opinion")
    func nonJPEG2000BytesDrawNoOpinion() throws {
        // JPEG-LS, RLE and uncompressed payloads are legitimate. Refusing everything
        // this gate cannot parse would reject them, so it declines to judge.
        for bytes in [[UInt8](), [0xFF], [0xFF, 0xD8, 0xFF, 0xE0], [0x00, 0x00, 0x00]] {
            #expect(CodestreamHeaderBudget.read(bytes) == .notAJPEG2000Codestream)
            try CodestreamHeaderBudget.admit(codestream: bytes, maximumDecodedByteCount: 1)
        }
    }

    // MARK: - The wiring, which is what makes the gate unforgettable

    @Test("[Unit][VOX-CMP-011] admitDestination refuses an adversarial header")
    func admitDestinationRefusesAdversarialHeader() throws {
        // The payload's own declarations are honest and well within the ceiling; only
        // the codestream's header is hostile. This is the case the pre-existing
        // declared-shape check could not see.
        let payload = try CompressedPayload(
            codestream: ContiguousArray(Self.codestream(width: 0xFFFF, height: 0xFFFF)),
            declaredExtents: ContiguousArray([64, 64, 4]),
            declaredScalarFormat: try ScalarFormat(
                type: .uint16,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            declaredComponentCount: 1
        )
        // The declared shape passes on its own.
        #expect(payload.declaredDecodedByteCount == 32_768)

        #expect(throws: CodestreamBudgetError.declaredGeometryExceedsCeiling) {
            try CompressedDecodeValidator.admitDestination(
                for: payload,
                maximumDecodedByteCount: 32_768
            )
        }
    }

    @Test("[Unit][VOX-CMP-011] admitDestination still admits an honest payload")
    func admitDestinationStillAdmitsHonestPayload() throws {
        let payload = try CompressedPayload(
            codestream: ContiguousArray(Self.codestream()),
            declaredExtents: ContiguousArray([64, 64, 4]),
            declaredScalarFormat: try ScalarFormat(
                type: .uint16,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            declaredComponentCount: 1
        )
        try CompressedDecodeValidator.admitDestination(
            for: payload,
            maximumDecodedByteCount: 32_768
        )
    }
}

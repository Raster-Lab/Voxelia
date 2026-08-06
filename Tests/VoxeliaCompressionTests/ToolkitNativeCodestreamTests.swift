// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// `ADR-0272` (`VOX-CMP-006`, `VOX-CMP-013`): a toolkit-native container hiding inside a
/// standards-shaped JPEG 2000 envelope must be detectable from the bytes, and must not
/// be labellable as a standard transfer syntax.
///
/// Codestreams here are built by hand rather than produced by the codec. That keeps the
/// suite free of a codec dependency, and it lets each case isolate one structural fact —
/// including the malformed shapes a real encoder would never emit.
@Suite("ToolkitNativeCodestream")
struct ToolkitNativeCodestreamTests {
    // MARK: - Builders

    private static let soc: [UInt8] = [0xFF, 0x4F]
    private static let sod: [UInt8] = [0xFF, 0x93]
    private static let eoc: [UInt8] = [0xFF, 0xD9]
    private static let magic: [UInt8] = [0x4A, 0x33, 0x44, 0x53]

    /// A marker segment whose two-byte length counts itself, as JPEG 2000 requires.
    private static func segment(_ marker: UInt8, body: [UInt8]) -> [UInt8] {
        let length = 2 + body.count
        return [0xFF, marker, UInt8(length >> 8), UInt8(length & 0xFF)] + body
    }

    private static func segment(_ marker: UInt8, bodyByteCount: Int) -> [UInt8] {
        segment(marker, body: [UInt8](repeating: 0x00, count: bodyByteCount))
    }

    /// `SIZ`, `COD`, `QCD` then `SOT` — the shape the codec was measured to emit.
    private static var mainHeader: [UInt8] {
        segment(0x51, bodyByteCount: 45)  // SIZ
            + segment(0x52, bodyByteCount: 10)  // COD
            + segment(0x5C, bodyByteCount: 6)  // QCD
            + segment(0x90, bodyByteCount: 8)  // SOT
    }

    /// A codestream whose first tile payload opens with `payload`.
    private static func codestream(tilePayload payload: [UInt8]) -> [UInt8] {
        soc + mainHeader + sod + payload + eoc
    }

    // MARK: - Detection

    @Test("[Unit][VOX-CMP-006] the toolkit container is detected at the first tile payload")
    func toolkitContainerIsDetected() {
        let bytes = Self.codestream(tilePayload: Self.magic + [0x00, 0x00, 0x00, 0x02])
        #expect(ToolkitNativeCodestream.inspect(bytes) == .toolkitNativeContainer)
    }

    @Test("[Unit][VOX-CMP-006] a conformant tile payload yields no toolkit container")
    func conformantPayloadYieldsNoContainer() {
        let bytes = Self.codestream(tilePayload: [0x87, 0x65, 0x43, 0x21])
        #expect(ToolkitNativeCodestream.inspect(bytes) == .noToolkitNativeContainer)
    }

    @Test("[Unit][VOX-CMP-006] a near-miss magic is not detected")
    func nearMissMagicIsNotDetected() {
        // Only the exact four bytes count; the last one differs here.
        let bytes = Self.codestream(tilePayload: [0x4A, 0x33, 0x44, 0x54])
        #expect(ToolkitNativeCodestream.inspect(bytes) == .noToolkitNativeContainer)
    }

    @Test("[Unit][VOX-CMP-006] the magic is located structurally, not by scanning")
    func magicIsLocatedStructurallyRatherThanByScanning() throws {
        // The measurement that motivated a structured parse: in one real 988-byte
        // codestream the pair `FF 93` occurred at five offsets and only one was a
        // marker. Here the container magic and a decoy `FF 93` both sit *inside* a
        // main-header segment's body, so a scanning implementation would report a
        // toolkit container and a structural one must not.
        let decoys = Self.magic + Self.sod + Self.magic
        let bytes =
            Self.soc
            + Self.segment(0x51, bodyByteCount: 45)
            + Self.segment(0x64, body: decoys)  // COM, carrying the decoys in its body
            + Self.segment(0x90, bodyByteCount: 8)  // SOT
            + Self.sod + [0x11, 0x22, 0x33, 0x44]  // the real, conformant tile payload
            + Self.eoc

        #expect(ToolkitNativeCodestream.inspect(bytes) == .noToolkitNativeContainer)

        // The assertion above is only meaningful if a naive implementation would get
        // this wrong, so both naive forms are shown failing on these exact bytes.
        var magicHits: [Int] = []
        for index in 0...(bytes.count - Self.magic.count)
        where Array(bytes[index..<(index + Self.magic.count)]) == Self.magic {
            magicHits.append(index)
        }
        #expect(magicHits.count == 2, "scanning for the magic anywhere finds the decoys")

        let firstSOD = (0..<(bytes.count - 1)).first {
            bytes[$0] == Self.sod[0] && bytes[$0 + 1] == Self.sod[1]
        }
        let sodOffset = try #require(firstSOD)
        let afterFirstSOD = Array(bytes[(sodOffset + 2)..<(sodOffset + 6)])
        #expect(
            afterFirstSOD == Self.magic,
            "the first FF93 in the stream is a decoy inside a segment body"
        )
    }

    // MARK: - Inputs that are not JPEG 2000 codestreams

    @Test("[Unit][VOX-CMP-006] bytes that do not open with SOC are not a codestream")
    func nonSOCBytesAreNotACodestream() {
        #expect(ToolkitNativeCodestream.inspect([UInt8]()) == .notAJPEG2000Codestream)
        #expect(ToolkitNativeCodestream.inspect([0xFF]) == .notAJPEG2000Codestream)
        // A JPEG-LS / DICOM-ish preamble, i.e. a legitimately standard non-J2K payload.
        #expect(
            ToolkitNativeCodestream.inspect([0xFF, 0xD8, 0xFF, 0xE0])
                == .notAJPEG2000Codestream
        )
    }

    @Test("[Unit][VOX-CMP-006] truncated and malformed headers terminate with a verdict")
    func malformedHeadersTerminateWithAVerdict() {
        // Each of these would be an opportunity for an unbounded walk or a trap.
        let truncatedAfterSOC = Self.soc
        let truncatedLength = Self.soc + [0xFF, 0x51, 0x00]
        let zeroLengthSegment = Self.soc + [0xFF, 0x51, 0x00, 0x00] + [0x00, 0x00]
        let lengthOfOne = Self.soc + [0xFF, 0x51, 0x00, 0x01] + [0x00, 0x00]
        let segmentRunsPastEnd = Self.soc + [0xFF, 0x51, 0x7F, 0xFF, 0x00]
        let notAMarker = Self.soc + [0x00, 0x51, 0x00, 0x04]

        for bytes in [
            truncatedAfterSOC, truncatedLength, zeroLengthSegment, lengthOfOne,
            segmentRunsPastEnd, notAMarker,
        ] {
            #expect(ToolkitNativeCodestream.inspect(bytes) == .notAJPEG2000Codestream)
        }
    }

    @Test("[Unit][VOX-CMP-006] a truncated tile payload cannot be a container")
    func truncatedTilePayloadIsNotAContainer() {
        // `SOD` present, but fewer than four payload bytes follow, so the magic cannot
        // match and the walk must not read past the end.
        let bytes = Self.soc + Self.mainHeader + Self.sod + [0x4A, 0x33, 0x44]
        #expect(ToolkitNativeCodestream.inspect(bytes) == .noToolkitNativeContainer)
    }

    @Test("[Unit][VOX-CMP-006] a codestream ending before any tile carries no container")
    func codestreamEndingBeforeAnyTileCarriesNoContainer() {
        let bytes = Self.soc + Self.segment(0x51, bodyByteCount: 45) + Self.eoc
        #expect(ToolkitNativeCodestream.inspect(bytes) == .noToolkitNativeContainer)
    }

    @Test("[Unit][VOX-CMP-006] a segmentless marker is stepped over")
    func segmentlessMarkerIsSteppedOver() {
        // Markers in `FF30...FF3F` carry no length field. A parser that tried to read
        // one would consume the following marker's bytes as a length.
        let bytes =
            Self.soc + [0xFF, 0x30] + Self.mainHeader + Self.sod + Self.magic + Self.eoc
        #expect(ToolkitNativeCodestream.inspect(bytes) == .toolkitNativeContainer)
    }

    // MARK: - The labelling rule

    private func standard() throws -> CompressedRepresentation {
        // A genuine JPEG 2000 Lossless transfer syntax UID: impeccably well formed,
        // which is exactly why the name alone cannot catch this mislabel.
        try CompressedRepresentation.standardTransferSyntax(
            declaredUID: "1.2.840.10008.1.2.4.90"
        )
    }

    @Test("[Unit][VOX-CMP-013] a toolkit codestream labelled standard is refused")
    func toolkitCodestreamLabelledStandardIsRefused() throws {
        let bytes = Self.codestream(tilePayload: Self.magic)
        let representation = try standard()

        // `ADR-0257`'s name rule admits this representation without complaint: the UID
        // is real and well formed. Only the byte-level rule refuses the pairing.
        #expect(representation.isStandardDICOMTransferSyntax)
        #expect(representation.declaredTransferSyntaxUID == "1.2.840.10008.1.2.4.90")

        #expect(throws: CodestreamLabellingError.toolkitNativeCodestreamLabelledStandard) {
            try CodestreamLabellingRule.admit(
                representation: representation,
                codestream: bytes
            )
        }
    }

    @Test("[Unit][VOX-CMP-013] a conformant codestream labelled standard is admitted")
    func conformantCodestreamLabelledStandardIsAdmitted() throws {
        let bytes = Self.codestream(tilePayload: [0x11, 0x22, 0x33, 0x44])
        try CodestreamLabellingRule.admit(
            representation: try standard(),
            codestream: bytes
        )
    }

    @Test("[Unit][VOX-CMP-013] a non-JPEG-2000 codestream labelled standard is admitted")
    func nonJPEG2000CodestreamLabelledStandardIsAdmitted() throws {
        // JPEG-LS, RLE and uncompressed syntaxes are standard and are not JPEG 2000.
        // Refusing anything this rule cannot parse would reject them, so the refusal is
        // deliberately narrowed to the measured hazard.
        try CodestreamLabellingRule.admit(
            representation: try standard(),
            codestream: [UInt8]([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
        )
    }

    @Test("[Unit][VOX-CMP-013] a toolkit label over a toolkit codestream is admitted")
    func toolkitLabelOverToolkitCodestreamIsAdmitted() throws {
        try CodestreamLabellingRule.admit(
            representation: try CompressedRepresentation.toolkit(name: "voxelia.jp3d"),
            codestream: Self.codestream(tilePayload: Self.magic)
        )
    }

    @Test("[Unit][VOX-CMP-013] a toolkit label over a conformant codestream is admitted")
    func toolkitLabelOverConformantCodestreamIsAdmitted() throws {
        // Conservative in the safe direction: declining to present a payload as
        // interoperable forgoes interoperability but never causes a silent misread.
        try CodestreamLabellingRule.admit(
            representation: try CompressedRepresentation.toolkit(name: "voxelia.jp3d"),
            codestream: Self.codestream(tilePayload: [0x11, 0x22, 0x33, 0x44])
        )
    }

    @Test("[Unit][VOX-CMP-013] the payload overload refuses the same pairing")
    func payloadOverloadRefusesTheSamePairing() throws {
        let payload = try CompressedPayload(
            codestream: ContiguousArray(Self.codestream(tilePayload: Self.magic)),
            declaredExtents: ContiguousArray([4, 4, 1]),
            declaredScalarFormat: try ScalarFormat(
                type: .uint16,
                validBitCount: nil,
                byteOrder: .littleEndian
            ),
            declaredComponentCount: 1
        )
        #expect(throws: CodestreamLabellingError.toolkitNativeCodestreamLabelledStandard) {
            try CodestreamLabellingRule.admit(
                representation: try standard(),
                payload: payload
            )
        }
    }
}

// SPDX-License-Identifier: MIT

import Foundation
import J2K3D
import J2KCore
import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// `ADR-0268`: the `J2KSwift` decode adapter's admissions.
///
/// Every check is a refusal, and each one is exercised. The core takes plain values
/// rather than a `JP3DDecoderResult`, which has no public initialiser — so these
/// tests need no real codestream.
@Suite("J2KVolumeAdapter")
struct J2KVolumeAdapterTests {
    private func format(
        _ type: ScalarType = .uint16
    ) throws -> ScalarFormat {
        try ScalarFormat(type: type, validBitCount: nil, byteOrder: .littleEndian)
    }

    /// A 4x3x2 single-component 16-bit unsigned volume: 48 bytes.
    private func component(
        bitDepth: Int = 16,
        signed: Bool = false,
        width: Int = 4,
        height: Int = 3,
        depth: Int = 2,
        subsampling: (Int, Int, Int) = (1, 1, 1),
        byteCount: Int? = nil
    ) -> J2KVolumeComponent {
        let bytes = byteCount ?? (width * height * depth * ((bitDepth + 7) / 8))
        return J2KVolumeComponent(
            index: 0,
            bitDepth: bitDepth,
            signed: signed,
            width: width,
            height: height,
            depth: depth,
            subsamplingX: subsampling.0,
            subsamplingY: subsampling.1,
            subsamplingZ: subsampling.2,
            data: Data(repeating: 7, count: bytes)
        )
    }

    private func volume(
        _ components: [J2KVolumeComponent],
        width: Int = 4,
        height: Int = 3,
        depth: Int = 2
    ) -> J2KVolume {
        // Spacing and origin are supplied deliberately non-zero: the adapter must
        // ignore them, and a fixture of zeros could not tell the difference between
        // ignoring them and reading zeros.
        J2KVolume(
            width: width,
            height: height,
            depth: depth,
            components: components,
            spacingX: 0.75,
            spacingY: 0.75,
            spacingZ: 2.5,
            originX: -120.5,
            originY: -119.0,
            originZ: 42.0
        )
    }

    private func admit(
        _ volume: J2KVolume,
        isPartial: Bool = false,
        tilesDecoded: Int = 4,
        tilesTotal: Int = 4,
        warnings: [String] = [],
        type: ScalarType = .uint16,
        components: Int = 1
    ) throws -> DecodedSamples {
        try J2KVolumeAdapter.decodedSamples(
            volume: volume,
            isPartial: isPartial,
            tilesDecoded: tilesDecoded,
            tilesTotal: tilesTotal,
            warnings: warnings,
            declaredScalarFormat: try format(type),
            declaredComponentCount: components
        )
    }

    // MARK: - The happy path, and what it does not carry

    @Test("[Unit][VOX-CMP-002] a complete single-component decode is admitted")
    func completeDecodeIsAdmitted() throws {
        let samples = try admit(volume([component()]))
        #expect(samples.bytes.count == 48)
        #expect(samples.claim.byteCount == 48)
        #expect(Array(samples.claim.extents) == [4, 3, 2])
        #expect(samples.claim.componentCount == 1)
        #expect(samples.claim.scalarFormat.type == .uint16)
    }

    @Test("[Unit][VOX-CMP-002] the adapter carries no geometry out of the codec")
    func adapterCarriesNoGeometry() throws {
        // The most important assertion in this suite. `J2KVolume` supplies spacing
        // and origin, and Voxelia's patient-space mapping has an accepted source
        // that is not a codestream. The fixture's spacing and origin are non-zero,
        // so the only way `DecodedSamples` could carry them is if the adapter read
        // them — and `DecodedSamples` has no field that could hold them.
        let samples = try admit(volume([component()]))
        // The claim's whole surface: bytes, extents, format, component count.
        // Extents are voxel counts, not millimetres.
        #expect(Array(samples.claim.extents) == [4, 3, 2])
        #expect(samples.claim.byteCount == 48)
        #expect(samples.claim.componentCount == 1)
        // If a spacing had leaked into the extents they would not be whole voxel
        // counts of the component's own dimensions.
        #expect(samples.claim.extents.allSatisfy { $0 > 0 })
    }

    // MARK: - Completeness refusals

    @Test("[Unit][VOX-CMP-009][VOX-SEC-001] a partial decode is refused")
    func partialDecodeIsRefused() throws {
        // The codec's own signal, and one the arc's byte-count checks cannot see:
        // a partial decode can be exactly the right length and the wrong data.
        #expect(throws: J2KVolumeAdapterError.decodeIncomplete) {
            try admit(volume([component()]), isPartial: true)
        }
        // Tile shortfall, the second completeness signal.
        #expect(throws: J2KVolumeAdapterError.decodeIncomplete) {
            try admit(volume([component()]), tilesDecoded: 3, tilesTotal: 4)
        }
    }

    @Test("[Unit][VOX-CMP-009] a warned decode is refused")
    func warnedDecodeIsRefused() throws {
        // "Skipped tiles" is one of the codec's documented warnings. A diagnostic
        // path does not accept pixel data the decoder itself flagged.
        #expect(throws: J2KVolumeAdapterError.decodeWarned) {
            try admit(volume([component()]), warnings: ["skipped tile 3"])
        }
    }

    // MARK: - Component format refusals

    @Test("[Unit][VOX-CMP-010] a subsampled component is refused")
    func subsampledComponentIsRefused() throws {
        // A subsampled component's data does not correspond to the volume's
        // extents, so reading it as if it did would misplace every sample.
        for subsampling in [(2, 1, 1), (1, 2, 1), (1, 1, 2)] {
            #expect(throws: J2KVolumeAdapterError.componentSubsampled) {
                try admit(volume([component(subsampling: subsampling)]))
            }
        }
    }

    @Test("[Unit][VOX-CMP-010] a component disagreeing with the volume's extents is refused")
    func componentDimensionMismatchIsRefused() throws {
        #expect(throws: J2KVolumeAdapterError.componentDimensionMismatch) {
            try admit(volume([component(width: 5)], width: 4))
        }
    }

    @Test("[Unit][VOX-CMP-010] an unrepresentable bit depth is refused, never truncated")
    func unrepresentableBitDepthIsRefused() throws {
        // J2K admits 1 to 38 bits. Anything wider than Voxelia's scalar types is
        // refused: a 24-bit sample narrowed to 16 would be a quantitative error in
        // diagnostic data, not a formatting detail.
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 24) == nil)
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 38) == nil)
        #expect(throws: J2KVolumeAdapterError.unsupportedBitDepth) {
            try admit(volume([component(bitDepth: 24)]))
        }
        // And a representable depth whose byte width disagrees with the declared
        // format: 8-bit data declared as uint16.
        #expect(throws: J2KVolumeAdapterError.unsupportedBitDepth) {
            try admit(volume([component(bitDepth: 8)]), type: .uint16)
        }
    }

    @Test("[Unit][VOX-CMP-010] the representable bit depths map to the expected widths")
    func representableBitDepthsMapCorrectly() {
        // The boundary from the admitted side, so the refusals above are shown to
        // reject only what is genuinely unrepresentable. CT commonly stores 12
        // bits in 16.
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 1) == 1)
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 8) == 1)
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 9) == 2)
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 12) == 2)
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 16) == 2)
        #expect(J2KVolumeAdapter.byteWidth(forBitDepth: 17) == nil)
    }

    @Test("[Unit][VOX-CMP-010] a signedness disagreement is refused")
    func signednessMismatchIsRefused() throws {
        // Signed data read as unsigned is the defect ADR-0236 already caught once
        // in the DICOM padding path: a signed -2000 read unsigned becomes 63536.
        #expect(throws: J2KVolumeAdapterError.componentSignednessMismatch) {
            try admit(volume([component(signed: true)]), type: .uint16)
        }
        #expect(throws: J2KVolumeAdapterError.componentSignednessMismatch) {
            try admit(volume([component(signed: false)]), type: .int16)
        }
        // The matching cases are admitted, so the refusals are about disagreement.
        _ = try admit(volume([component(signed: true)]), type: .int16)
        _ = try admit(volume([component(signed: false)]), type: .uint16)
    }

    @Test("[Unit][VOX-CMP-010][VOX-SEC-001] a component lying about its own byte count is refused")
    func componentByteCountMismatchIsRefused() throws {
        // The layout is checked rather than assumed: the expected length is derived
        // from the component's own dimensions and bit depth, so the adapter encodes
        // no guess about how the codec packs samples.
        #expect(throws: J2KVolumeAdapterError.componentByteCountMismatch) {
            try admit(volume([component(byteCount: 40)]))
        }
        #expect(throws: J2KVolumeAdapterError.componentByteCountMismatch) {
            try admit(volume([component(byteCount: 96)]))
        }
    }

    @Test("[Unit][VOX-CMP-010] component-count disagreements are refused")
    func componentCountDisagreementsAreRefused() throws {
        // Declared three, decoded one.
        #expect(throws: J2KVolumeAdapterError.componentCountMismatch) {
            try admit(volume([component()]), components: 3)
        }
        // Decoded three, declared three: refused as unsupported rather than
        // silently interleaved, because no record has decided that layout.
        let three = [component(), component(), component()]
        #expect(throws: J2KVolumeAdapterError.multipleComponentsUnsupported) {
            try admit(volume(three), components: 3)
        }
    }

    // MARK: - The decoder configuration

    @Test(
        "[Unit][VOX-CMP-011][VOX-SEC-001] the adapter refuses the error-tolerant default"
    )
    func adapterNeverAcceptsErrorTolerantDefault() {
        // JP3DDecoderConfiguration defaults tolerateErrors to TRUE. For a
        // diagnostic viewer that default is wrong: it produces output from a
        // codestream the decoder could not fully parse. This test fails if the
        // default is ever silently adopted.
        #expect(JP3DDecoderConfiguration().tolerateErrors)
        #expect(!J2KVolumeAdapter.configuration.tolerateErrors)
        #expect(J2KVolumeAdapter.configuration.resolutionLevel == 0)
        #expect(J2KVolumeAdapter.configuration.maxQualityLayers == 0)
    }
}

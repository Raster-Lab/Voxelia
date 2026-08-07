// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaRendering

@Suite("HeadlessOutput")
struct HeadlessOutputTests {
    @Test("[Unit][VOX-HLS-006] the declared range admits and the undeclared refuses")
    func theDeclaredRangeAdmitsAndTheUndeclaredRefuses() throws {
        let sdrOnly = HeadlessOutputCapabilities(
            supportedRanges: [.sdr],
            supportedAuxiliaries: []
        )
        try HeadlessOutputDescriptor(dynamicRange: .sdr, auxiliaries: [])
            .validate(against: sdrOnly)
        // Never a silent downgrade: HDR against an SDR backend refuses.
        #expect(throws: HeadlessOutputError.unsupportedDynamicRange) {
            try HeadlessOutputDescriptor(dynamicRange: .hdr, auxiliaries: [])
                .validate(against: sdrOnly)
        }
        let both = HeadlessOutputCapabilities(
            supportedRanges: [.sdr, .hdr],
            supportedAuxiliaries: []
        )
        try HeadlessOutputDescriptor(dynamicRange: .hdr, auxiliaries: [])
            .validate(against: both)
    }

    @Test("[Unit][VOX-HLS-007] auxiliaries are optional and never silently omitted")
    func auxiliariesAreOptionalAndNeverSilentlyOmitted() throws {
        let capable = HeadlessOutputCapabilities(
            supportedRanges: [.sdr],
            supportedAuxiliaries: [.depth, .objectIdentifier]
        )
        // The empty selection is valid: optional means optional.
        try HeadlessOutputDescriptor(dynamicRange: .sdr, auxiliaries: [])
            .validate(against: capable)
        try HeadlessOutputDescriptor(
            dynamicRange: .sdr,
            auxiliaries: [.depth, .objectIdentifier]
        ).validate(against: capable)

        let bare = HeadlessOutputCapabilities(
            supportedRanges: [.sdr],
            supportedAuxiliaries: []
        )
        #expect(throws: HeadlessOutputError.unsupportedAuxiliaryOutput) {
            try HeadlessOutputDescriptor(dynamicRange: .sdr, auxiliaries: [.depth])
                .validate(against: bare)
        }
    }

    @Test("[Unit][VOX-HLS-005] the media-buffer seam is implementable without CoreVideo")
    func theMediaBufferSeamIsImplementableWithoutCoreVideo() throws {
        // A stub buffer type stands in for any Apple media buffer: the
        // protocol's associated type is what keeps CoreVideo out of
        // the render stack entirely.
        struct StubBuffer: Equatable {
            let width: Int
            let height: Int
            let byteCount: Int
        }
        struct StubAdapter: MediaBufferAdapter {
            let adapterIdentity = "org.voxelia.test.media-buffer/1.0.0"

            func buffer(
                rawPixels: ContiguousArray<UInt8>,
                descriptor: HeadlessOutputDescriptor,
                width: Int,
                height: Int
            ) throws -> StubBuffer {
                StubBuffer(
                    width: width,
                    height: height,
                    byteCount: rawPixels.count
                )
            }
        }
        let adapter = StubAdapter()
        let buffer = try adapter.buffer(
            rawPixels: [0, 1, 2, 3],
            descriptor: HeadlessOutputDescriptor(dynamicRange: .sdr, auxiliaries: []),
            width: 2,
            height: 2
        )
        #expect(buffer == StubBuffer(width: 2, height: 2, byteCount: 4))
        #expect(adapter.adapterIdentity == "org.voxelia.test.media-buffer/1.0.0")
    }
}

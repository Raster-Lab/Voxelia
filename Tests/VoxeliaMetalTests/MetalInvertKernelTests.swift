// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaMetal

@Suite("MetalInvertKernel")
struct MetalInvertKernelTests {
    @Test("[Unit][VOX-PLT-011][VOX-MTL-016] the involution is device-exact over the domain")
    func involutionIsDeviceExactOverTheDomain() throws {
        // The pinned digest binds the manifest to the embedded source.
        #expect(
            MetalInvertKernel.sourceDigestHexText
                == "eeb2126fe4c6e66801c5444a33a0f371520c2528c5d5a807e7bfe95ccc9652c5"
        )
        let kernel = try MetalInvertKernel(
            context: try MetalExecutionContext(),
            telemetrySink: nil
        )
        #expect(
            kernel.kernelReference.identifier.rawValue
                == "org.voxelia.kernel.invert-display"
        )

        // The exact claim demands equality, not a tolerance: all 256
        // values match the registered model exactly, double inversion
        // reproduces the input, and repeats are bit-identical.
        let domain = Array(UInt8(0)...UInt8(255))
        let inverted = try kernel.invertSamples(domain)
        #expect(inverted == domain.map { 255 - $0 })
        let restored = try kernel.invertSamples(inverted)
        #expect(restored == domain)
        #expect(try kernel.invertSamples(domain) == inverted)
        #expect(try kernel.invertSamples([]) == [])
        print(
            "ADR-0132 exactness evidence: 256/256 device inversions equal the "
                + "registered model exactly "
                + "(source sha256 \(MetalInvertKernel.sourceDigestHexText))"
        )

        requireSendable(MetalInvertKernel.self)
        requireSendable(MetalInvertKernelError.self)
    }

    @Test("[Concurrency][VOX-CON-003][VOX-MTL-004] one invert kernel dispatches concurrently")
    func oneInvertKernelDispatchesConcurrently() async throws {
        let context = try MetalExecutionContext()
        let kernel = try MetalInvertKernel(
            context: context,
            telemetrySink: nil
        )
        let samples = Array(UInt8(0)...UInt8(255))
        let expected = samples.map { 255 - $0 }

        try await withThrowingTaskGroup(of: [UInt8].self) { group in
            for _ in 0..<16 {
                group.addTask {
                    try kernel.invertSamples(samples)
                }
            }
            for try await produced in group {
                #expect(produced == expected)
            }
        }

        #expect(context.pipelineCache.libraryBuildCount == 1)
        #expect(context.pipelineCache.pipelineBuildCount == 1)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}

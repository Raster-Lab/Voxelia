// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaMetal

@Suite("MetalPipelineCache")
struct MetalPipelineCacheTests {
    @Test("[Unit][VOX-MTL-005][VOX-REP-008] repeated kernel construction compiles nothing")
    func repeatedKernelConstructionCompilesNothing() throws {
        // One context, both families, each constructed twice: the
        // observed build counts prove the second constructions reused
        // every compiled state — evidence, not assumption.
        let context = try MetalExecutionContext()
        #expect(context.pipelineCache.libraryBuildCount == 0)
        #expect(context.pipelineCache.pipelineBuildCount == 0)

        _ = try MetalWindowLevelKernel(context: context, telemetrySink: nil)
        #expect(context.pipelineCache.libraryBuildCount == 1)
        #expect(context.pipelineCache.pipelineBuildCount == 3)

        _ = try MetalWindowLevelKernel(context: context, telemetrySink: nil)
        #expect(context.pipelineCache.libraryBuildCount == 1)
        #expect(context.pipelineCache.pipelineBuildCount == 3)

        _ = try MetalCompositeKernel(context: context, telemetrySink: nil)
        #expect(context.pipelineCache.libraryBuildCount == 2)
        #expect(context.pipelineCache.pipelineBuildCount == 4)

        _ = try MetalCompositeKernel(context: context, telemetrySink: nil)
        #expect(context.pipelineCache.libraryBuildCount == 2)
        #expect(context.pipelineCache.pipelineBuildCount == 4)
        print(
            "ADR-0106 reuse evidence: \(context.pipelineCache.libraryBuildCount) "
                + "libraries and \(context.pipelineCache.pipelineBuildCount) pipelines "
                + "compiled across four kernel constructions."
        )

        // Distinct entry points hold distinct cached pipelines under
        // one library, and the cached kernels stay functional.
        let kernel = try MetalWindowLevelKernel(context: context, telemetrySink: nil)
        let fixtureOutput = try kernel.mapSamples(
            Array(0..<12), center: 6, width: 8, paddingValue: nil)
        #expect(fixtureOutput.count == 12)

        requireSendable(MetalPipelineCache.self)
        requireSendable(MetalPipelineCache.Key.self)
        requireSendable(MetalPipelineCacheError.self)
    }

    @Test("[Concurrency][VOX-MTL-005][VOX-CON-003] contention builds each identity once")
    func contentionBuildsEachIdentityOnce() async throws {
        let context = try MetalExecutionContext()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<16 {
                group.addTask {
                    _ = try MetalWindowLevelKernel(
                        context: context,
                        telemetrySink: nil
                    )
                }
            }
            try await group.waitForAll()
        }

        #expect(context.pipelineCache.libraryBuildCount == 1)
        #expect(context.pipelineCache.pipelineBuildCount == 3)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}

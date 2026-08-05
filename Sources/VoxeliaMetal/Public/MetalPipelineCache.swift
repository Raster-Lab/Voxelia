// SPDX-License-Identifier: MIT

import Metal
import Synchronization

/// An error raised by pipeline-state caching.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// compiler output or device detail.
public enum MetalPipelineCacheError: Error, Sendable, Equatable {
    case compilationFailed
    case pipelineUnavailable
}

/// The per-context pipeline-state cache per `ADR-0106`.
///
/// Compiled libraries are keyed by the exact source digest and
/// pipeline states by kernel token, source digest and entry point —
/// the stable identities of `VOX-MTL-005`; the manifest discipline
/// pins each digest to its text, so lookup never compares source. The
/// complete mutable state is isolated behind a checked mutex, including
/// compilation itself, so each stable identity is built at most once under
/// contention. Build counts are exposed as reuse evidence per the
/// coalescing-evidence precedent.
public final class MetalPipelineCache: Sendable {
    /// One stable pipeline identity.
    public struct Key: Sendable, Hashable {
        public let kernelToken: String
        public let sourceDigest: String
        public let entryPoint: String

        public init(kernelToken: String, sourceDigest: String, entryPoint: String) {
            self.kernelToken = kernelToken
            self.sourceDigest = sourceDigest
            self.entryPoint = entryPoint
        }
    }

    private struct State {
        var libraries: [String: any MTLLibrary] = [:]
        var pipelines: [Key: any MTLComputePipelineState] = [:]
        var observedLibraryBuildCount = 0
        var observedPipelineBuildCount = 0
    }

    private let state = Mutex(State())

    init() {}

    /// The number of library compilations this cache has performed.
    public var libraryBuildCount: Int {
        state.withLock { $0.observedLibraryBuildCount }
    }

    /// The number of pipeline-state builds this cache has performed.
    public var pipelineBuildCount: Int {
        state.withLock { $0.observedPipelineBuildCount }
    }

    /// Returns the pipeline state for one stable identity, compiling
    /// at most once per identity.
    ///
    /// - Throws: ``MetalPipelineCacheError``.
    func pipeline(
        key: Key,
        source: String,
        device: any MTLDevice
    ) throws -> any MTLComputePipelineState {
        try state.withLock { state in
            if let cached = state.pipelines[key] {
                return cached
            }
            let library: any MTLLibrary
            if let cachedLibrary = state.libraries[key.sourceDigest] {
                library = cachedLibrary
            } else {
                do {
                    library = try device.makeLibrary(source: source, options: nil)
                } catch {
                    throw MetalPipelineCacheError.compilationFailed
                }
                state.libraries[key.sourceDigest] = library
                state.observedLibraryBuildCount += 1
            }
            guard let function = library.makeFunction(name: key.entryPoint) else {
                throw MetalPipelineCacheError.pipelineUnavailable
            }
            let pipeline: any MTLComputePipelineState
            do {
                pipeline = try device.makeComputePipelineState(function: function)
            } catch {
                throw MetalPipelineCacheError.pipelineUnavailable
            }
            state.pipelines[key] = pipeline
            state.observedPipelineBuildCount += 1
            return pipeline
        }
    }
}

// SPDX-License-Identifier: MIT

import Foundation
import Metal

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
/// class is unchecked-`Sendable` on the recorded justification that
/// the lock guards the maps and Metal pipeline objects are documented
/// thread-safe. Build counts are exposed as reuse evidence per the
/// coalescing-evidence precedent.
public final class MetalPipelineCache: @unchecked Sendable {
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

    private let lock = NSLock()
    private var libraries: [String: any MTLLibrary] = [:]
    private var pipelines: [Key: any MTLComputePipelineState] = [:]
    private var observedLibraryBuildCount = 0
    private var observedPipelineBuildCount = 0

    init() {}

    /// The number of library compilations this cache has performed.
    public var libraryBuildCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return observedLibraryBuildCount
    }

    /// The number of pipeline-state builds this cache has performed.
    public var pipelineBuildCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return observedPipelineBuildCount
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
        lock.lock()
        defer { lock.unlock() }
        if let cached = pipelines[key] {
            return cached
        }
        let library: any MTLLibrary
        if let cachedLibrary = libraries[key.sourceDigest] {
            library = cachedLibrary
        } else {
            do {
                library = try device.makeLibrary(source: source, options: nil)
            } catch {
                throw MetalPipelineCacheError.compilationFailed
            }
            libraries[key.sourceDigest] = library
            observedLibraryBuildCount += 1
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
        pipelines[key] = pipeline
        observedPipelineBuildCount += 1
        return pipeline
    }
}

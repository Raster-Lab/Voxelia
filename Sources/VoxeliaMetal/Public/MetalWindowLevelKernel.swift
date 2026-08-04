// SPDX-License-Identifier: MIT

import CryptoKit
import Metal
import VoxeliaCore

/// An error raised by the window-level Metal kernel.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// compiler output, device detail or sample content.
public enum MetalKernelError: Error, Sendable, Equatable {
    case compilationFailed
    case pipelineUnavailable
    case bufferAllocationFailed
    case executionFailed
    case invalidWindowWidth
}

/// The first Voxelia-owned Metal kernel per `ADR-0080`: the `float32`
/// window-level approximation of the registered `VOXELIA-ALG-0002`
/// binary64 model.
///
/// `MSL` has no 64-bit floating type, so this kernel approximates the
/// registered model and must be claimed as
/// `org.voxelia.precision.binary32-device` with approximation status
/// `approximate` and the kernel component reference — never as
/// `binary64-strict`. The embedded source is digest-pinned by the
/// shader manifest, and the class is unchecked-`Sendable` on the
/// recorded justification that Metal pipeline objects are documented
/// thread-safe.
public final class MetalWindowLevelKernel: @unchecked Sendable {
    /// The registered kernel token spelling.
    public static let kernelIdentifier = "org.voxelia.kernel.window-level"

    /// The lowercase hexadecimal SHA-256 digest of the exact embedded
    /// kernel source text; the suite verifies this equals the shader
    /// manifest's pin.
    public static var sourceDigestHexText: String {
        SHA256.hash(data: Array(WindowLevelKernelSource.metalSource.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// The kernel component reference carried by honest GPU execution
    /// claims.
    public let kernelReference: ExecutionComponentReference

    let context: MetalExecutionContext
    private let pipeline: any MTLComputePipelineState

    /// Compiles the embedded source and builds the compute pipeline on
    /// one acquired context.
    ///
    /// - Throws: ``MetalKernelError``.
    public init(context: MetalExecutionContext) throws {
        self.context = context
        let library: any MTLLibrary
        do {
            library = try context.device.makeLibrary(
                source: WindowLevelKernelSource.metalSource,
                options: nil
            )
        } catch {
            throw MetalKernelError.compilationFailed
        }
        guard
            let function = library.makeFunction(name: "voxelia_window_level_u8")
        else {
            throw MetalKernelError.pipelineUnavailable
        }
        do {
            self.pipeline = try context.device.makeComputePipelineState(
                function: function
            )
        } catch {
            throw MetalKernelError.pipelineUnavailable
        }
        self.kernelReference = try ExecutionComponentReference(
            identifier: try ExecutionClaimToken(rawValue: Self.kernelIdentifier),
            version: try SemanticVersion(major: 1, minor: 0, patch: 0)
        )
    }

    /// Maps `uint8` stored samples to display samples on the device.
    ///
    /// Window edges are precomputed once from the binary64 parameters
    /// and converted to `float32`; the kernel bounds every thread by
    /// the explicit sample count.
    ///
    /// - Throws: ``MetalKernelError``.
    public func mapSamples(
        _ storedSamples: [UInt8],
        center: Double,
        width: Double
    ) throws -> [UInt8] {
        guard width >= 1.0 else {
            throw MetalKernelError.invalidWindowWidth
        }
        guard !storedSamples.isEmpty else {
            return []
        }

        let halfSpan = (width - 1.0) / 2.0
        let threshold = center - 0.5
        var parameters = KernelParameters(
            threshold: Float(threshold),
            lowerEdge: Float(threshold - halfSpan),
            upperEdge: Float(threshold + halfSpan),
            widthMinusOne: Float(width - 1.0),
            sampleCount: UInt32(storedSamples.count)
        )

        guard
            let inputBuffer = context.device.makeBuffer(
                bytes: storedSamples,
                length: storedSamples.count,
                options: [.storageModeShared]
            ),
            let outputBuffer = context.device.makeBuffer(
                length: storedSamples.count,
                options: [.storageModeShared]
            )
        else {
            throw MetalKernelError.bufferAllocationFailed
        }

        guard
            let commandBuffer = context.commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            throw MetalKernelError.executionFailed
        }
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(inputBuffer, offset: 0, index: 0)
        encoder.setBuffer(outputBuffer, offset: 0, index: 1)
        encoder.setBytes(
            &parameters,
            length: MemoryLayout<KernelParameters>.stride,
            index: 2
        )
        let threadWidth = min(
            pipeline.maxTotalThreadsPerThreadgroup,
            storedSamples.count
        )
        encoder.dispatchThreads(
            MTLSize(width: storedSamples.count, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: threadWidth, height: 1, depth: 1)
        )
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        guard commandBuffer.status == .completed else {
            throw MetalKernelError.executionFailed
        }

        let output = outputBuffer.contents()
            .bindMemory(to: UInt8.self, capacity: storedSamples.count)
        return Array(UnsafeBufferPointer(start: output, count: storedSamples.count))
    }

    private struct KernelParameters {
        var threshold: Float
        var lowerEdge: Float
        var upperEdge: Float
        var widthMinusOne: Float
        var sampleCount: UInt32
    }
}

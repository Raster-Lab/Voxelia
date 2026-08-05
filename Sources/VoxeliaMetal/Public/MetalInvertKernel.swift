// SPDX-License-Identifier: MIT

import CryptoKit
import Metal
import VoxeliaCore

/// An error raised by the display-inversion Metal kernel.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// compiler output, device detail or sample content.
public enum MetalInvertKernelError: Error, Sendable, Equatable {
    case compilationFailed
    case pipelineUnavailable
    case bufferAllocationFailed
    case executionFailed
}

/// The display-inversion Metal kernel per `ADR-0132`: the registered
/// `VOXELIA-ALG-0011` involution in pure unsigned eight-bit integer
/// arithmetic.
///
/// No floating-point step exists, so this kernel computes the
/// registered model exactly and its claims carry the `exact`
/// precision policy — the first device implementation with an exact
/// claim. The embedded source is digest-pinned by the shader
/// manifest, and the class is unchecked-`Sendable` on the recorded
/// justification that Metal pipeline objects are documented
/// thread-safe.
public final class MetalInvertKernel: @unchecked Sendable {
    /// The registered kernel token spelling.
    public static let kernelIdentifier = "org.voxelia.kernel.invert-display"

    /// The lowercase hexadecimal SHA-256 digest of the exact embedded
    /// kernel source text; the suite verifies this equals the shader
    /// manifest's pin.
    public static var sourceDigestHexText: String {
        SHA256.hash(data: Array(InvertKernelSource.metalSource.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// The kernel component reference carried by device execution
    /// claims.
    public let kernelReference: ExecutionComponentReference

    let context: MetalExecutionContext
    private let telemetrySink: MetalTelemetrySink?
    private let pipeline: any MTLComputePipelineState

    /// Acquires the compute pipeline through the context's `ADR-0106`
    /// cache, compiling at most once per stable identity; the
    /// `ADR-0107` telemetry sink is host-owned with absence stated
    /// explicitly.
    ///
    /// - Throws: ``MetalInvertKernelError``.
    public init(
        context: MetalExecutionContext,
        telemetrySink: MetalTelemetrySink?
    ) throws {
        self.context = context
        self.telemetrySink = telemetrySink
        do {
            self.pipeline = try context.withMetalHandles { device, _ in
                try context.pipelineCache.pipeline(
                    key: MetalPipelineCache.Key(
                        kernelToken: Self.kernelIdentifier,
                        sourceDigest: Self.sourceDigestHexText,
                        entryPoint: "voxelia_invert_display_u8"
                    ),
                    source: InvertKernelSource.metalSource,
                    device: device
                )
            }
        } catch MetalPipelineCacheError.compilationFailed {
            throw MetalInvertKernelError.compilationFailed
        } catch {
            throw MetalInvertKernelError.pipelineUnavailable
        }
        self.kernelReference = try ExecutionComponentReference(
            identifier: try ExecutionClaimToken(rawValue: Self.kernelIdentifier),
            version: try SemanticVersion(major: 1, minor: 0, patch: 0)
        )
    }

    /// Inverts eight-bit display samples on the device exactly.
    ///
    /// - Throws: ``MetalInvertKernelError``.
    public func invertSamples(_ storedSamples: [UInt8]) throws -> [UInt8] {
        guard !storedSamples.isEmpty else {
            return []
        }
        var parameters = KernelParameters(sampleCount: UInt32(storedSamples.count))
        guard
            let buffers = context.withMetalHandles({
                device, _ -> (any MTLBuffer, any MTLBuffer)? in
                guard
                    let input = device.makeBuffer(
                        bytes: storedSamples,
                        length: storedSamples.count,
                        options: [.storageModeShared]
                    ),
                    let output = device.makeBuffer(
                        length: storedSamples.count,
                        options: [.storageModeShared]
                    )
                else {
                    return nil
                }
                return (input, output)
            })
        else {
            throw MetalInvertKernelError.bufferAllocationFailed
        }
        let (inputBuffer, outputBuffer) = buffers
        guard
            let commandBuffer = context.withMetalHandles({ _, commandQueue in
                commandQueue.makeCommandBuffer()
            }),
            let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            throw MetalInvertKernelError.executionFailed
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
            throw MetalInvertKernelError.executionFailed
        }
        if let telemetrySink {
            telemetrySink(
                MetalDispatchTelemetry(
                    kernelToken: Self.kernelIdentifier,
                    entryPoint: "voxelia_invert_display_u8",
                    sampleCount: storedSamples.count,
                    gpuSeconds: commandBuffer.gpuEndTime - commandBuffer.gpuStartTime,
                    commandBufferLatencySeconds: commandBuffer.gpuEndTime
                        - commandBuffer.kernelStartTime
                )
            )
        }
        let output = outputBuffer.contents()
            .bindMemory(to: UInt8.self, capacity: storedSamples.count)
        return Array(UnsafeBufferPointer(start: output, count: storedSamples.count))
    }

    private struct KernelParameters {
        var sampleCount: UInt32
    }
}

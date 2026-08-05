// SPDX-License-Identifier: MIT

import Metal
import Synchronization
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
    /// The nonempty input count cannot be represented by the kernel's
    /// exact unsigned 32-bit parameter field.
    case invalidSampleByteCount
}

/// The display-inversion Metal kernel per `ADR-0132`: the registered
/// `VOXELIA-ALG-0011` involution in pure unsigned eight-bit integer
/// arithmetic.
///
/// No floating-point step exists, so this kernel computes the
/// registered model exactly and its claims carry the `exact`
/// precision policy — the first device implementation with an exact
/// claim. The embedded source is digest-pinned by the shader manifest.
/// Its non-`Sendable` pipeline is retained behind a checked mutex and
/// borrowed only while configuring an encoder; command execution is not
/// serialized by the wrapper.
public final class MetalInvertKernel: Sendable {
    /// The registered kernel token spelling.
    public static let kernelIdentifier = "org.voxelia.kernel.invert-display"

    /// The lowercase hexadecimal SHA-256 digest of the exact embedded
    /// kernel source text; the suite verifies this equals the shader
    /// manifest's pin.
    public static var sourceDigestHexText: String {
        MetalSourceDigest.sha256HexText(InvertKernelSource.metalSource)
    }

    /// The kernel component reference carried by device execution
    /// claims.
    public let kernelReference: ExecutionComponentReference

    let context: MetalExecutionContext
    private let telemetrySink: MetalTelemetrySink?
    private let pipeline: Mutex<any MTLComputePipelineState>

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
            self.pipeline = Mutex(
                try context.withMetalHandles { device, _ in
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
            )
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
        let parameters = try Self.parameterBytes(sampleCount: storedSamples.count)
        let buffers: (any MTLBuffer, any MTLBuffer)
        do {
            buffers = try context.withMetalHandles { device, _ in
                let input = try MetalBufferTransfer.makeSharedBuffer(
                    copying: storedSamples,
                    using: device
                )
                guard
                    let output = device.makeBuffer(
                        length: storedSamples.count,
                        options: [.storageModeShared]
                    )
                else {
                    throw MetalBufferTransferError.bufferAllocationFailed
                }
                return (input, output)
            }
        } catch {
            switch MetalKernelBufferPreparationFailure.classify(error) {
            case .allocation:
                throw MetalInvertKernelError.bufferAllocationFailed
            case .execution:
                throw MetalInvertKernelError.executionFailed
            }
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
        encoder.setBuffer(inputBuffer, offset: 0, index: 0)
        encoder.setBuffer(outputBuffer, offset: 0, index: 1)
        do {
            try MetalBufferTransfer.setInlineBytes(
                parameters,
                on: encoder,
                index: 2
            )
        } catch {
            encoder.endEncoding()
            throw MetalInvertKernelError.executionFailed
        }
        let threadWidth = pipeline.withLock { pipeline in
            encoder.setComputePipelineState(pipeline)
            return min(
                pipeline.maxTotalThreadsPerThreadgroup,
                storedSamples.count
            )
        }
        encoder.dispatchThreads(
            MTLSize(width: storedSamples.count, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: threadWidth, height: 1, depth: 1)
        )
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let result: [UInt8]
        do {
            result = try MetalBufferTransfer.readBytes(
                from: outputBuffer,
                offset: 0,
                count: storedSamples.count,
                after: commandBuffer
            )
        } catch {
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
        return result
    }

    static func parameterBytes(sampleCount: Int) throws -> [UInt8] {
        guard let sampleCountWord = UInt32(exactly: sampleCount) else {
            throw MetalInvertKernelError.invalidSampleByteCount
        }
        do {
            return try MetalKernelParameterBytes.littleEndianWords([sampleCountWord])
        } catch {
            throw MetalInvertKernelError.executionFailed
        }
    }
}

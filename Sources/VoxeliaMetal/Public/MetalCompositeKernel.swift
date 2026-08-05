// SPDX-License-Identifier: MIT

import Metal
import Synchronization
import VoxeliaCore

/// An error raised by the layer compositing Metal kernel.
///
/// Cases deliberately carry no payload so diagnostics never disclose
/// compiler output, device detail or sample content.
public enum MetalCompositeKernelError: Error, Sendable, Equatable {
    case compilationFailed
    case pipelineUnavailable
    case bufferAllocationFailed
    case executionFailed
    case invalidLayerShape
    case invalidOpacity
}

/// The layer compositing Metal kernel per `ADR-0096`: the `float32`
/// approximation of the registered `VOXELIA-ALG-0009` binary64 model.
///
/// `MSL` has no 64-bit floating type, so this kernel approximates the
/// registered model and must be claimed as
/// `org.voxelia.precision.binary32-device` with approximation status
/// `approximate` and the kernel component reference — never as
/// `binary64-strict`. The embedded source is digest-pinned by the
/// shader manifest. Its non-`Sendable` pipeline is retained behind a
/// checked mutex and borrowed only while configuring an encoder;
/// command execution is not serialized by the wrapper.
public final class MetalCompositeKernel: Sendable {
    /// The registered kernel token spelling.
    public static let kernelIdentifier = "org.voxelia.kernel.composite-layers"

    /// The lowercase hexadecimal SHA-256 digest of the exact embedded
    /// kernel source text; the suite verifies this equals the shader
    /// manifest's pin.
    public static var sourceDigestHexText: String {
        MetalSourceDigest.sha256HexText(CompositeKernelSource.metalSource)
    }

    /// The kernel component reference carried by honest GPU execution
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
    /// - Throws: ``MetalCompositeKernelError``.
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
                            entryPoint: "voxelia_composite_layers"
                        ),
                        source: CompositeKernelSource.metalSource,
                        device: device
                    )
                }
            )
        } catch MetalPipelineCacheError.compilationFailed {
            throw MetalCompositeKernelError.compilationFailed
        } catch {
            throw MetalCompositeKernelError.pipelineUnavailable
        }
        self.kernelReference = try ExecutionComponentReference(
            identifier: try ExecutionClaimToken(rawValue: Self.kernelIdentifier),
            version: try SemanticVersion(major: 1, minor: 0, patch: 0)
        )
    }

    /// Blends equally sized `uint8` layers over the black background on
    /// the device.
    ///
    /// Opacities pair with layers in declared order and demote to
    /// `float32` once; the kernel bounds every thread by the explicit
    /// element count.
    ///
    /// - Throws: ``MetalCompositeKernelError``.
    public func blendLayers(
        _ layerSamples: [[UInt8]],
        opacities: [Double]
    ) throws -> [UInt8] {
        guard let elementCount = layerSamples.first?.count else {
            throw MetalCompositeKernelError.invalidLayerShape
        }
        guard layerSamples.allSatisfy({ $0.count == elementCount }) else {
            throw MetalCompositeKernelError.invalidLayerShape
        }
        guard opacities.count == layerSamples.count else {
            throw MetalCompositeKernelError.invalidOpacity
        }
        for opacity in opacities {
            guard opacity.isFinite, opacity >= 0, opacity <= 1 else {
                throw MetalCompositeKernelError.invalidOpacity
            }
        }
        guard elementCount > 0 else {
            return []
        }

        let packedSampleCount = try Self.validatedPackedSampleCount(
            elementCount: elementCount,
            layerCount: layerSamples.count
        )
        let parameters = try Self.parameterBytes(
            elementCount: elementCount,
            layerCount: layerSamples.count
        )
        let packedSamples = layerSamples.flatMap { $0 }
        guard packedSamples.count == packedSampleCount else {
            throw MetalCompositeKernelError.invalidLayerShape
        }
        let packedOpacities = try Self.opacityBytes(opacities)

        let buffers: (any MTLBuffer, any MTLBuffer, any MTLBuffer)
        do {
            buffers = try context.withMetalHandles { device, _ in
                let samples = try MetalBufferTransfer.makeSharedBuffer(
                    copying: packedSamples,
                    using: device
                )
                let opacityBuffer = try MetalBufferTransfer.makeSharedBuffer(
                    copying: packedOpacities,
                    using: device
                )
                guard
                    let output = device.makeBuffer(
                        length: elementCount,
                        options: [.storageModeShared]
                    )
                else {
                    throw MetalBufferTransferError.bufferAllocationFailed
                }
                return (samples, opacityBuffer, output)
            }
        } catch {
            switch MetalKernelBufferPreparationFailure.classify(error) {
            case .allocation:
                throw MetalCompositeKernelError.bufferAllocationFailed
            case .execution:
                throw MetalCompositeKernelError.executionFailed
            }
        }
        let (samplesBuffer, opacitiesBuffer, outputBuffer) = buffers

        guard
            let commandBuffer = context.withMetalHandles({ _, commandQueue in
                commandQueue.makeCommandBuffer()
            }),
            let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            throw MetalCompositeKernelError.executionFailed
        }
        encoder.setBuffer(samplesBuffer, offset: 0, index: 0)
        encoder.setBuffer(opacitiesBuffer, offset: 0, index: 1)
        encoder.setBuffer(outputBuffer, offset: 0, index: 2)
        do {
            try MetalBufferTransfer.setInlineBytes(
                parameters,
                on: encoder,
                index: 3
            )
        } catch {
            encoder.endEncoding()
            throw MetalCompositeKernelError.executionFailed
        }
        let threadWidth = pipeline.withLock { pipeline in
            encoder.setComputePipelineState(pipeline)
            return min(pipeline.maxTotalThreadsPerThreadgroup, elementCount)
        }
        encoder.dispatchThreads(
            MTLSize(width: elementCount, height: 1, depth: 1),
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
                count: elementCount,
                after: commandBuffer
            )
        } catch {
            throw MetalCompositeKernelError.executionFailed
        }
        if let telemetrySink {
            telemetrySink(
                MetalDispatchTelemetry(
                    kernelToken: Self.kernelIdentifier,
                    entryPoint: "voxelia_composite_layers",
                    sampleCount: elementCount,
                    gpuSeconds: commandBuffer.gpuEndTime - commandBuffer.gpuStartTime,
                    commandBufferLatencySeconds: commandBuffer.gpuEndTime
                        - commandBuffer.kernelStartTime
                )
            )
        }
        return result
    }

    static func validatedPackedSampleCount(
        elementCount: Int,
        layerCount: Int
    ) throws -> Int {
        let (packedSampleCount, overflow) = elementCount.multipliedReportingOverflow(
            by: layerCount
        )
        guard
            elementCount > 0,
            layerCount > 0,
            !overflow,
            packedSampleCount > 0
        else {
            throw MetalCompositeKernelError.invalidLayerShape
        }
        return packedSampleCount
    }

    static func parameterBytes(
        elementCount: Int,
        layerCount: Int
    ) throws -> [UInt8] {
        guard
            let elementCountWord = UInt32(exactly: elementCount),
            let layerCountWord = UInt32(exactly: layerCount)
        else {
            throw MetalCompositeKernelError.invalidLayerShape
        }
        do {
            return try MetalKernelParameterBytes.littleEndianWords([
                elementCountWord,
                layerCountWord,
            ])
        } catch {
            throw MetalCompositeKernelError.executionFailed
        }
    }

    static func opacityBytes(_ opacities: [Double]) throws -> [UInt8] {
        do {
            return try MetalKernelParameterBytes.littleEndianWords(
                opacities.map { Float($0).bitPattern }
            )
        } catch {
            throw MetalCompositeKernelError.executionFailed
        }
    }
}

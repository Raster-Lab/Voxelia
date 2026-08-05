// SPDX-License-Identifier: MIT

import Metal
import Synchronization
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
    case unsupportedScalarType
    case invalidSampleByteCount
}

/// One measured dispatch telemetry value per `ADR-0107`.
///
/// The durations are the platform's own measured timestamps from the
/// completed command buffer — Voxelia values mint no clock, and the
/// host-owned sink owns recording policy.
public struct MetalDispatchTelemetry: Sendable, Hashable {
    public let kernelToken: String
    public let entryPoint: String
    public let sampleCount: Int
    public let gpuSeconds: Double
    public let commandBufferLatencySeconds: Double

    init(
        kernelToken: String,
        entryPoint: String,
        sampleCount: Int,
        gpuSeconds: Double,
        commandBufferLatencySeconds: Double
    ) {
        self.kernelToken = kernelToken
        self.entryPoint = entryPoint
        self.sampleCount = sampleCount
        self.gpuSeconds = gpuSeconds
        self.commandBufferLatencySeconds = commandBufferLatencySeconds
    }
}

/// The host-owned telemetry sink per `ADR-0107`.
public typealias MetalTelemetrySink = @Sendable (MetalDispatchTelemetry) -> Void

/// The first Voxelia-owned Metal kernel per `ADR-0080`: the `float32`
/// window-level approximation of the registered `VOXELIA-ALG-0002`
/// binary64 model.
///
/// `MSL` has no 64-bit floating type, so this kernel approximates the
/// registered model and must be claimed as
/// `org.voxelia.precision.binary32-device` with approximation status
/// `approximate` and the kernel component reference — never as
/// `binary64-strict`. The embedded source is digest-pinned by the
/// shader manifest. Its non-`Sendable` pipeline set is retained behind
/// one checked mutex and borrowed only while configuring an encoder;
/// command execution is not serialized by the wrapper.
public final class MetalWindowLevelKernel: Sendable {
    /// The registered kernel token spelling.
    public static let kernelIdentifier = "org.voxelia.kernel.window-level"

    /// The lowercase hexadecimal SHA-256 digest of the exact embedded
    /// kernel source text; the suite verifies this equals the shader
    /// manifest's pin.
    public static var sourceDigestHexText: String {
        MetalSourceDigest.sha256HexText(WindowLevelKernelSource.metalSource)
    }

    /// The kernel component reference carried by honest GPU execution
    /// claims.
    public let kernelReference: ExecutionComponentReference

    let context: MetalExecutionContext
    private let telemetrySink: MetalTelemetrySink?
    private let pipelines: Mutex<Pipelines>

    private struct Pipelines {
        let uint8: any MTLComputePipelineState
        let int16: any MTLComputePipelineState
        let uint16: any MTLComputePipelineState
    }

    private enum PipelineKind {
        case uint8
        case int16
        case uint16
    }

    /// Acquires one compute pipeline per manifest entry point through
    /// the context's `ADR-0106` cache, compiling at most once per
    /// stable identity; the `ADR-0107` telemetry sink is host-owned
    /// with absence stated explicitly.
    ///
    /// - Throws: ``MetalKernelError``.
    public init(
        context: MetalExecutionContext,
        telemetrySink: MetalTelemetrySink?
    ) throws {
        self.context = context
        self.telemetrySink = telemetrySink
        func pipeline(_ name: String) throws -> any MTLComputePipelineState {
            do {
                return try context.withMetalHandles { device, _ in
                    try context.pipelineCache.pipeline(
                        key: MetalPipelineCache.Key(
                            kernelToken: Self.kernelIdentifier,
                            sourceDigest: Self.sourceDigestHexText,
                            entryPoint: name
                        ),
                        source: WindowLevelKernelSource.metalSource,
                        device: device
                    )
                }
            } catch MetalPipelineCacheError.compilationFailed {
                throw MetalKernelError.compilationFailed
            } catch {
                throw MetalKernelError.pipelineUnavailable
            }
        }
        let uint8Pipeline = try pipeline("voxelia_window_level_u8")
        let int16Pipeline = try pipeline("voxelia_window_level_i16")
        let uint16Pipeline = try pipeline("voxelia_window_level_u16")
        self.pipelines = Mutex(
            Pipelines(
                uint8: uint8Pipeline,
                int16: int16Pipeline,
                uint16: uint16Pipeline
            )
        )
        self.kernelReference = try ExecutionComponentReference(
            identifier: try ExecutionClaimToken(rawValue: Self.kernelIdentifier),
            version: try SemanticVersion(major: 1, minor: 2, patch: 0)
        )
    }

    /// Maps `uint8` stored samples to display samples on the device.
    ///
    /// - Throws: ``MetalKernelError``.
    public func mapSamples(
        _ storedSamples: [UInt8],
        center: Double,
        width: Double,
        paddingValue: Int32?
    ) throws -> [UInt8] {
        try mapSamples(
            storedBytes: storedSamples,
            scalarType: .uint8,
            center: center,
            width: width,
            paddingValue: paddingValue
        )
    }

    /// Maps stored sample bytes of one admitted scalar type to display
    /// samples on the device per `ADR-0093`, with the `ADR-0146`
    /// padding sentinel.
    ///
    /// Window edges are precomputed once from the binary64 parameters
    /// and converted to `float32`; 16-bit samples are read in the
    /// platform's native little-endian order, and the kernel bounds
    /// every thread by the explicit sample count. An enabled sentinel
    /// compares as integers before any float conversion, so the
    /// exclusion is exact; absence is stated explicitly at every call
    /// site.
    ///
    /// - Throws: ``MetalKernelError``.
    public func mapSamples(
        storedBytes: [UInt8],
        scalarType: ScalarType,
        center: Double,
        width: Double,
        paddingValue: Int32?
    ) throws -> [UInt8] {
        let pipelineKind: PipelineKind
        let bytesPerSample: Int
        let entryPoint: String
        switch scalarType {
        case .uint8:
            pipelineKind = .uint8
            bytesPerSample = 1
            entryPoint = "voxelia_window_level_u8"
        case .int16:
            pipelineKind = .int16
            bytesPerSample = 2
            entryPoint = "voxelia_window_level_i16"
        case .uint16:
            pipelineKind = .uint16
            bytesPerSample = 2
            entryPoint = "voxelia_window_level_u16"
        default:
            throw MetalKernelError.unsupportedScalarType
        }
        guard width >= 1.0 else {
            throw MetalKernelError.invalidWindowWidth
        }
        guard storedBytes.count % bytesPerSample == 0 else {
            throw MetalKernelError.invalidSampleByteCount
        }
        let sampleCount = storedBytes.count / bytesPerSample
        guard sampleCount > 0 else {
            return []
        }

        let parameters = try Self.parameterBytes(
            center: center,
            width: width,
            sampleCount: sampleCount,
            paddingValue: paddingValue
        )

        let buffers: (any MTLBuffer, any MTLBuffer)
        do {
            buffers = try context.withMetalHandles { device, _ in
                let input = try MetalBufferTransfer.makeSharedBuffer(
                    copying: storedBytes,
                    using: device
                )
                guard
                    let output = device.makeBuffer(
                        length: sampleCount,
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
                throw MetalKernelError.bufferAllocationFailed
            case .execution:
                throw MetalKernelError.executionFailed
            }
        }
        let (inputBuffer, outputBuffer) = buffers

        guard
            let commandBuffer = context.withMetalHandles({ _, commandQueue in
                commandQueue.makeCommandBuffer()
            }),
            let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            throw MetalKernelError.executionFailed
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
            throw MetalKernelError.executionFailed
        }
        let threadWidth = pipelines.withLock { pipelines in
            let pipeline: any MTLComputePipelineState
            switch pipelineKind {
            case .uint8:
                pipeline = pipelines.uint8
            case .int16:
                pipeline = pipelines.int16
            case .uint16:
                pipeline = pipelines.uint16
            }
            encoder.setComputePipelineState(pipeline)
            return min(pipeline.maxTotalThreadsPerThreadgroup, sampleCount)
        }
        encoder.dispatchThreads(
            MTLSize(width: sampleCount, height: 1, depth: 1),
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
                count: sampleCount,
                after: commandBuffer
            )
        } catch {
            throw MetalKernelError.executionFailed
        }
        if let telemetrySink {
            telemetrySink(
                MetalDispatchTelemetry(
                    kernelToken: Self.kernelIdentifier,
                    entryPoint: entryPoint,
                    sampleCount: sampleCount,
                    gpuSeconds: commandBuffer.gpuEndTime - commandBuffer.gpuStartTime,
                    commandBufferLatencySeconds: commandBuffer.gpuEndTime
                        - commandBuffer.kernelStartTime
                )
            )
        }
        return result
    }

    static func parameterBytes(
        center: Double,
        width: Double,
        sampleCount: Int,
        paddingValue: Int32?
    ) throws -> [UInt8] {
        guard let sampleCountWord = UInt32(exactly: sampleCount) else {
            throw MetalKernelError.invalidSampleByteCount
        }
        let halfSpan = (width - 1.0) / 2.0
        let threshold = center - 0.5
        do {
            return try MetalKernelParameterBytes.littleEndianWords([
                Float(threshold).bitPattern,
                Float(threshold - halfSpan).bitPattern,
                Float(threshold + halfSpan).bitPattern,
                Float(width - 1.0).bitPattern,
                sampleCountWord,
                UInt32(bitPattern: paddingValue ?? 0),
                paddingValue == nil ? 0 : 1,
            ])
        } catch {
            throw MetalKernelError.executionFailed
        }
    }
}

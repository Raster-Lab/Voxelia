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
    case unsupportedScalarType
    case invalidSampleByteCount
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
    private let uint8Pipeline: any MTLComputePipelineState
    private let int16Pipeline: any MTLComputePipelineState
    private let uint16Pipeline: any MTLComputePipelineState

    /// Compiles the embedded source and builds one compute pipeline
    /// per manifest entry point on one acquired context.
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
        func pipeline(_ name: String) throws -> any MTLComputePipelineState {
            guard let function = library.makeFunction(name: name) else {
                throw MetalKernelError.pipelineUnavailable
            }
            do {
                return try context.device.makeComputePipelineState(
                    function: function
                )
            } catch {
                throw MetalKernelError.pipelineUnavailable
            }
        }
        self.uint8Pipeline = try pipeline("voxelia_window_level_u8")
        self.int16Pipeline = try pipeline("voxelia_window_level_i16")
        self.uint16Pipeline = try pipeline("voxelia_window_level_u16")
        self.kernelReference = try ExecutionComponentReference(
            identifier: try ExecutionClaimToken(rawValue: Self.kernelIdentifier),
            version: try SemanticVersion(major: 1, minor: 1, patch: 0)
        )
    }

    /// Maps `uint8` stored samples to display samples on the device.
    ///
    /// - Throws: ``MetalKernelError``.
    public func mapSamples(
        _ storedSamples: [UInt8],
        center: Double,
        width: Double
    ) throws -> [UInt8] {
        try mapSamples(
            storedBytes: storedSamples,
            scalarType: .uint8,
            center: center,
            width: width
        )
    }

    /// Maps stored sample bytes of one admitted scalar type to display
    /// samples on the device per `ADR-0093`.
    ///
    /// Window edges are precomputed once from the binary64 parameters
    /// and converted to `float32`; 16-bit samples are read in the
    /// platform's native little-endian order, and the kernel bounds
    /// every thread by the explicit sample count.
    ///
    /// - Throws: ``MetalKernelError``.
    public func mapSamples(
        storedBytes: [UInt8],
        scalarType: ScalarType,
        center: Double,
        width: Double
    ) throws -> [UInt8] {
        let pipeline: any MTLComputePipelineState
        let bytesPerSample: Int
        switch scalarType {
        case .uint8:
            pipeline = uint8Pipeline
            bytesPerSample = 1
        case .int16:
            pipeline = int16Pipeline
            bytesPerSample = 2
        case .uint16:
            pipeline = uint16Pipeline
            bytesPerSample = 2
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

        let halfSpan = (width - 1.0) / 2.0
        let threshold = center - 0.5
        var parameters = KernelParameters(
            threshold: Float(threshold),
            lowerEdge: Float(threshold - halfSpan),
            upperEdge: Float(threshold + halfSpan),
            widthMinusOne: Float(width - 1.0),
            sampleCount: UInt32(sampleCount)
        )

        guard
            let inputBuffer = context.device.makeBuffer(
                bytes: storedBytes,
                length: storedBytes.count,
                options: [.storageModeShared]
            ),
            let outputBuffer = context.device.makeBuffer(
                length: sampleCount,
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
            sampleCount
        )
        encoder.dispatchThreads(
            MTLSize(width: sampleCount, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: threadWidth, height: 1, depth: 1)
        )
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        guard commandBuffer.status == .completed else {
            throw MetalKernelError.executionFailed
        }

        let output = outputBuffer.contents()
            .bindMemory(to: UInt8.self, capacity: sampleCount)
        return Array(UnsafeBufferPointer(start: output, count: sampleCount))
    }

    private struct KernelParameters {
        var threshold: Float
        var lowerEdge: Float
        var upperEdge: Float
        var widthMinusOne: Float
        var sampleCount: UInt32
    }
}

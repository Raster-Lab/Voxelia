// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaGeometry

/// Internal cancellation sites frozen by `ADR-0193` and `ALG-0030`.
enum CPUTriangleMeshVertexNormalCancellationCheckpoint: Sendable, Equatable {
    case admission
    case attribute(UInt64)
    case triangle(UInt64)
    case vertex(UInt64)
    case final
}

typealias CPUTriangleMeshVertexNormalCancellationProbe =
    @Sendable (CPUTriangleMeshVertexNormalCancellationCheckpoint) -> Bool

/// Checked logical storage accounting for the two operation-owned buffers.
struct TriangleMeshVertexNormalLogicalByteCounts: Sendable, Equatable {
    let componentCount: UInt64
    let oneBufferByteCount: UInt64
    let additionalLogicalByteCount: UInt64
}

/// The exact `triangle-area-weighted-vertex-normals/binary64-v1` CPU kernel.
///
/// This stateless internal implementation preserves the source mesh domains,
/// performs only serial ordered binary64 operations, and appends one owned
/// normal attribute. Identity and provenance publication remain outside this
/// numerical boundary.
enum TriangleMeshVertexNormalReferenceKernel {
    private struct Vector3: Sendable {
        let x: Double
        let y: Double
        let z: Double
    }

    static func generate(
        request: TriangleMeshVertexNormalGenerationRequest,
        cancellation: CPUTriangleMeshVertexNormalCancellationProbe,
        checksFinalCancellation: Bool = true
    ) throws -> TriangleMesh {
        if cancellation(.admission) {
            throw TriangleMeshVertexNormalGenerationError.cancelled
        }
        guard
            request.limits.maximumVertexCount > 0,
            request.limits.maximumTriangleCount > 0,
            request.limits.maximumExistingVertexAttributeCount > 0,
            request.limits.maximumAdditionalLogicalByteCount > 0
        else {
            throw TriangleMeshVertexNormalGenerationError.invalidLimits
        }
        guard
            request.sourceProvenance.subject
                == .object(request.sourceIdentity.objectID)
        else {
            throw TriangleMeshVertexNormalGenerationError.invalidSource
        }

        let source = request.source
        guard
            let vertexCount = UInt64(exactly: source.positions.vertexCount),
            let triangleCount = UInt64(exactly: source.topology.triangleCount),
            let attributeCount = UInt64(exactly: source.vertexAttributes.count)
        else {
            throw TriangleMeshVertexNormalGenerationError.resourceLimitExceeded
        }
        guard
            vertexCount <= request.limits.maximumVertexCount,
            triangleCount <= request.limits.maximumTriangleCount,
            attributeCount
                <= request.limits.maximumExistingVertexAttributeCount
        else {
            throw TriangleMeshVertexNormalGenerationError.resourceLimitExceeded
        }

        for (index, attribute) in source.vertexAttributes.enumerated() {
            let ordinal = UInt64(index)
            if ordinal.isMultiple(of: 4_096),
                cancellation(.attribute(ordinal))
            {
                throw TriangleMeshVertexNormalGenerationError.cancelled
            }
            guard attribute.descriptor.semantic != .normal else {
                throw TriangleMeshVertexNormalGenerationError.normalAlreadyPresent
            }
        }

        let byteCounts = try checkedLogicalByteCounts(
            vertexCount: vertexCount,
            maximumAdditionalLogicalByteCount:
                request.limits.maximumAdditionalLogicalByteCount
        )
        let outputAttributeCount = source.vertexAttributes.count
            .addingReportingOverflow(1)
        guard
            !outputAttributeCount.overflow,
            let componentCount = Int(exactly: byteCounts.componentCount),
            let normalByteCount = Int(exactly: byteCounts.oneBufferByteCount)
        else {
            throw TriangleMeshVertexNormalGenerationError.resourceLimitExceeded
        }

        var accumulators = ContiguousArray<Double>(
            repeating: 0,
            count: componentCount
        )
        let indices = source.topology.indices
        let positions = source.positions.components

        for triangleOrdinal in 0..<source.topology.triangleCount {
            let ordinal = UInt64(triangleOrdinal)
            if ordinal.isMultiple(of: 64),
                cancellation(.triangle(ordinal))
            {
                throw TriangleMeshVertexNormalGenerationError.cancelled
            }

            let indexOffset = triangleOrdinal * 3
            guard
                let first = Int(exactly: indices[indexOffset]),
                let second = Int(exactly: indices[indexOffset + 1]),
                let third = Int(exactly: indices[indexOffset + 2])
            else {
                throw TriangleMeshVertexNormalGenerationError.publicationFailed
            }
            let face = try faceVector(
                first: position(at: first, in: positions),
                second: position(at: second, in: positions),
                third: position(at: third, in: positions)
            )
            try accumulate(face, at: first, into: &accumulators)
            try accumulate(face, at: second, into: &accumulators)
            try accumulate(face, at: third, into: &accumulators)
        }

        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(normalByteCount)
        for vertexOrdinal in 0..<source.positions.vertexCount {
            let ordinal = UInt64(vertexOrdinal)
            if ordinal.isMultiple(of: 4_096),
                cancellation(.vertex(ordinal))
            {
                throw TriangleMeshVertexNormalGenerationError.cancelled
            }
            let offset = vertexOrdinal * 3
            let normal = try normalise(
                Vector3(
                    x: accumulators[offset],
                    y: accumulators[offset + 1],
                    z: accumulators[offset + 2]
                )
            )
            appendLittleEndianBitPattern(normal.x, to: &bytes)
            appendLittleEndianBitPattern(normal.y, to: &bytes)
            appendLittleEndianBitPattern(normal.z, to: &bytes)
        }

        let mesh: TriangleMesh
        do {
            let descriptor = try GeometryAttributeDescriptor(
                semantic: .normal,
                scalarFormat: try ScalarFormat(
                    type: .float64,
                    validBitCount: nil,
                    byteOrder: .littleEndian
                ),
                components: try ComponentDescriptor(
                    count: 3,
                    interpretation: .vector,
                    layout: .interleaved,
                    componentNames: nil
                ),
                elementCount: source.positions.vertexCount
            )
            let normalAttribute = try TriangleMeshVertexAttribute(
                descriptor: descriptor,
                bytes: bytes
            )
            var attributes = source.vertexAttributes
            attributes.reserveCapacity(outputAttributeCount.partialValue)
            attributes.append(normalAttribute)
            mesh = try TriangleMesh(
                positions: source.positions,
                topology: source.topology,
                vertexAttributes: attributes
            )
        } catch {
            throw TriangleMeshVertexNormalGenerationError.publicationFailed
        }

        if checksFinalCancellation, cancellation(.final) {
            throw TriangleMeshVertexNormalGenerationError.cancelled
        }
        return mesh
    }

    /// Performs the exact checked `vertexCount * 3 * 8 * 2` admission.
    ///
    /// The one-buffer host-domain check is deliberately part of this helper so
    /// the registered UInt64 boundary can be tested without attempting an
    /// impractical allocation.
    static func checkedLogicalByteCounts(
        vertexCount: UInt64,
        maximumAdditionalLogicalByteCount: UInt64
    ) throws -> TriangleMeshVertexNormalLogicalByteCounts {
        let components = vertexCount.multipliedReportingOverflow(by: 3)
        guard !components.overflow else {
            throw TriangleMeshVertexNormalGenerationError.resourceLimitExceeded
        }
        let oneBuffer = components.partialValue.multipliedReportingOverflow(by: 8)
        guard !oneBuffer.overflow else {
            throw TriangleMeshVertexNormalGenerationError.resourceLimitExceeded
        }
        let additional = oneBuffer.partialValue.multipliedReportingOverflow(by: 2)
        guard
            !additional.overflow,
            additional.partialValue <= maximumAdditionalLogicalByteCount,
            oneBuffer.partialValue <= UInt64(Int.max)
        else {
            throw TriangleMeshVertexNormalGenerationError.resourceLimitExceeded
        }
        return TriangleMeshVertexNormalLogicalByteCounts(
            componentCount: components.partialValue,
            oneBufferByteCount: oneBuffer.partialValue,
            additionalLogicalByteCount: additional.partialValue
        )
    }

    private static func position(
        at vertex: Int,
        in components: ContiguousArray<Double>
    ) -> Vector3 {
        let offset = vertex * 3
        return Vector3(
            x: components[offset],
            y: components[offset + 1],
            z: components[offset + 2]
        )
    }

    private static func faceVector(
        first: Vector3,
        second: Vector3,
        third: Vector3
    ) throws -> Vector3 {
        let edge10X = try checkedSubtract(second.x, first.x)
        let edge10Y = try checkedSubtract(second.y, first.y)
        let edge10Z = try checkedSubtract(second.z, first.z)
        let edge10 = Vector3(
            x: edge10X,
            y: edge10Y,
            z: edge10Z
        )
        let edge20X = try checkedSubtract(third.x, first.x)
        let edge20Y = try checkedSubtract(third.y, first.y)
        let edge20Z = try checkedSubtract(third.z, first.z)
        let edge20 = Vector3(
            x: edge20X,
            y: edge20Y,
            z: edge20Z
        )

        let xFirst = try checkedMultiply(edge10.y, edge20.z)
        let xSecond = try checkedMultiply(edge10.z, edge20.y)
        let x = try checkedSubtract(xFirst, xSecond)
        let yFirst = try checkedMultiply(edge10.z, edge20.x)
        let ySecond = try checkedMultiply(edge10.x, edge20.z)
        let y = try checkedSubtract(yFirst, ySecond)
        let zFirst = try checkedMultiply(edge10.x, edge20.y)
        let zSecond = try checkedMultiply(edge10.y, edge20.x)
        let z = try checkedSubtract(zFirst, zSecond)
        return Vector3(
            x: x,
            y: y,
            z: z
        )
    }

    private static func accumulate(
        _ face: Vector3,
        at vertex: Int,
        into accumulators: inout ContiguousArray<Double>
    ) throws {
        let offset = vertex * 3
        accumulators[offset] = try checkedAdd(accumulators[offset], face.x)
        accumulators[offset + 1] = try checkedAdd(
            accumulators[offset + 1],
            face.y
        )
        accumulators[offset + 2] = try checkedAdd(
            accumulators[offset + 2],
            face.z
        )
    }

    private static func normalise(_ vector: Vector3) throws -> Vector3 {
        let absoluteX = abs(vector.x)
        let absoluteY = abs(vector.y)
        let absoluteZ = abs(vector.z)
        let scale = max(max(absoluteX, absoluteY), absoluteZ)
        guard scale != 0 else {
            throw TriangleMeshVertexNormalGenerationError.undefinedNormal
        }

        let scaledX = try checkedDivide(vector.x, scale)
        let scaledY = try checkedDivide(vector.y, scale)
        let scaledZ = try checkedDivide(vector.z, scale)
        let squaredX = try checkedMultiply(scaledX, scaledX)
        let squaredY = try checkedMultiply(scaledY, scaledY)
        let squaredZ = try checkedMultiply(scaledZ, scaledZ)
        let firstSum = try checkedAdd(squaredX, squaredY)
        let squaredSum = try checkedAdd(firstSum, squaredZ)
        let length = try checkedSquareRoot(squaredSum)
        let normalX = canonicalPositiveZero(
            try checkedDivide(scaledX, length)
        )
        let normalY = canonicalPositiveZero(
            try checkedDivide(scaledY, length)
        )
        let normalZ = canonicalPositiveZero(
            try checkedDivide(scaledZ, length)
        )
        return Vector3(
            x: normalX,
            y: normalY,
            z: normalZ
        )
    }

    private static func canonicalPositiveZero(_ value: Double) -> Double {
        value == 0 ? 0 : value
    }

    private static func appendLittleEndianBitPattern(
        _ value: Double,
        to bytes: inout ContiguousArray<UInt8>
    ) {
        let bitPattern = value.bitPattern
        for byteIndex in 0..<8 {
            bytes.append(
                UInt8(
                    truncatingIfNeeded: bitPattern >> UInt64(byteIndex * 8)
                )
            )
        }
    }

    // Keeping each primitive out of line prevents contraction and
    // reassociation across the operation boundaries frozen by ALG-0030.
    @inline(never)
    private static func checkedSubtract(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs - rhs
        guard value.isFinite else {
            throw TriangleMeshVertexNormalGenerationError.normalNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedMultiply(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs * rhs
        guard value.isFinite else {
            throw TriangleMeshVertexNormalGenerationError.normalNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedAdd(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs + rhs
        guard value.isFinite else {
            throw TriangleMeshVertexNormalGenerationError.normalNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedDivide(
        _ lhs: Double,
        _ rhs: Double
    ) throws -> Double {
        let value = lhs / rhs
        guard value.isFinite else {
            throw TriangleMeshVertexNormalGenerationError.normalNotRepresentable
        }
        return value
    }

    @inline(never)
    private static func checkedSquareRoot(_ value: Double) throws -> Double {
        let result = value.squareRoot()
        guard result.isFinite else {
            throw TriangleMeshVertexNormalGenerationError.normalNotRepresentable
        }
        return result
    }
}

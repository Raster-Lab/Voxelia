// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaCompression

/// `ADR-0260` (`VOX-CMP-008`): a caller-provided destination that is admitted
/// before a decode and reusable across decodes.
@Suite("DecodeDestination")
struct DecodeDestinationTests {
    private func format() throws -> ScalarFormat {
        try ScalarFormat(type: .uint16, validBitCount: nil, byteOrder: .littleEndian)
    }

    /// Declares `extents` of uint16 single-component samples.
    private func payload(extents: [Int]) throws -> CompressedPayload {
        try CompressedPayload(
            codestream: ContiguousArray([1, 2, 3, 4]),
            declaredExtents: ContiguousArray(extents),
            declaredScalarFormat: try format(),
            declaredComponentCount: 1
        )
    }

    @Test("[Unit][VOX-CMP-008] capacity is admitted before any fill")
    func capacityIsAdmittedBeforeAnyFill() throws {
        // 4x3x2 uint16 is 48 bytes.
        var destination = try DecodeDestination(capacity: 48)
        try destination.prepare(for: try payload(extents: [4, 3, 2]))
        #expect(destination.preparedByteCount == 48)
        #expect(!destination.isComplete)

        // One byte short of the declared size: refused, and refused at prepare
        // time rather than at fill time, so no decode need have run.
        var tight = try DecodeDestination(capacity: 47)
        #expect(throws: DecodeDestinationError.capacityExceeded) {
            try tight.prepare(for: try payload(extents: [4, 3, 2]))
        }
        #expect(tight.preparedByteCount == nil)
    }

    @Test("[Unit][VOX-CMP-008] a destination is reusable across decodes")
    func destinationIsReusableAcrossDecodes() throws {
        // The requirement's "reusable" half: one allocation, filled repeatedly.
        // Capacity survives, and the contents are replaced rather than appended.
        var destination = try DecodeDestination(capacity: 128)

        try destination.prepare(for: try payload(extents: [4, 3, 2]))
        try destination.fill(with: [UInt8](repeating: 1, count: 48))
        #expect(destination.isComplete)
        #expect(destination.bytes.count == 48)
        #expect(destination.bytes.allSatisfy { $0 == 1 })
        #expect(destination.capacity == 128)

        // A second, differently sized decode into the same destination.
        try destination.prepare(for: try payload(extents: [2, 2, 2]))
        #expect(destination.preparedByteCount == 16)
        try destination.fill(with: [UInt8](repeating: 9, count: 16))
        #expect(destination.isComplete)
        #expect(destination.bytes.count == 16)
        // Replaced, not appended: no trace of the first fill remains.
        #expect(destination.bytes.allSatisfy { $0 == 9 })
        #expect(destination.capacity == 128)
    }

    @Test("[Unit][VOX-CMP-008] preparing clears any previous contents")
    func preparingClearsPreviousContents() throws {
        // Preparing must not leave earlier bytes visible, or a decode that failed
        // after preparation would expose the previous decode's samples.
        var destination = try DecodeDestination(capacity: 64)
        try destination.prepare(for: try payload(extents: [2, 2, 2]))
        try destination.fill(with: [UInt8](repeating: 5, count: 16))
        #expect(destination.bytes.count == 16)

        try destination.prepare(for: try payload(extents: [2, 2, 2]))
        #expect(destination.bytes.isEmpty)
        #expect(!destination.isComplete)
    }

    @Test("[Unit][VOX-CMP-008][VOX-SEC-001] a partial fill is refused")
    func partialFillIsRefused() throws {
        // The same hazard VOX-CMP-009 forbids, arriving by a different route: a
        // destination that accepted fewer bytes than it was prepared for would
        // hold a partial decode that `isComplete` could not distinguish.
        var destination = try DecodeDestination(capacity: 64)
        try destination.prepare(for: try payload(extents: [2, 2, 2]))

        #expect(throws: DecodeDestinationError.offeredByteCountMismatch) {
            try destination.fill(with: [UInt8](repeating: 3, count: 15))
        }
        #expect(throws: DecodeDestinationError.offeredByteCountMismatch) {
            try destination.fill(with: [UInt8]())
        }
        // Over-long too, which would otherwise exceed the prepared length.
        #expect(throws: DecodeDestinationError.offeredByteCountMismatch) {
            try destination.fill(with: [UInt8](repeating: 3, count: 17))
        }
        // None of the refusals left partial contents behind.
        #expect(destination.bytes.isEmpty)
        #expect(!destination.isComplete)
    }

    @Test("[Unit][VOX-CMP-008][VOX-ERR-001] filling before preparing is refused")
    func fillingBeforePreparingIsRefused() throws {
        // No prepared length means no agreed length, so any offer disagrees.
        var destination = try DecodeDestination(capacity: 64)
        #expect(throws: DecodeDestinationError.offeredByteCountMismatch) {
            try destination.fill(with: [UInt8](repeating: 1, count: 16))
        }
    }

    @Test("[Unit][VOX-CMP-008][VOX-ERR-001] a non-positive capacity rejects typed")
    func nonPositiveCapacityRejectsTyped() {
        #expect(throws: DecodeDestinationError.invalidCapacity) {
            try DecodeDestination(capacity: 0)
        }
        #expect(throws: DecodeDestinationError.invalidCapacity) {
            try DecodeDestination(capacity: -8)
        }
    }
}

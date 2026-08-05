// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaRendering

@Suite("TransferFunction1D")
struct TransferFunction1DTests {
    private func rampTable() throws -> TransferFunction1D {
        var entries = ContiguousArray<TransferFunctionEntry>()
        entries.reserveCapacity(256)
        for index in 0..<256 {
            let level = UInt8(index)
            entries.append(
                TransferFunctionEntry(
                    red: level,
                    green: 255 - level,
                    blue: level / 2,
                    opacity: level
                )
            )
        }
        return try TransferFunction1D(entries: entries)
    }

    @Test("[Unit][VOX-DVR-005][VOX-DVR-007] lookup is exact and clamps by declaration")
    func lookupIsExactAndClampsByDeclaration() throws {
        // The ramp identity over the eight-bit domain, both clamp
        // directions for wider indices, and bit-identical repetition.
        let table = try rampTable()
        for index in 0..<256 {
            let entry = table.entry(at: index)
            #expect(entry.red == UInt8(index))
            #expect(entry.green == 255 - UInt8(index))
            #expect(entry.opacity == UInt8(index))
        }
        #expect(table.entry(at: -5) == table.entry(at: 0))
        #expect(table.entry(at: 300) == table.entry(at: 255))
        #expect(table == (try rampTable()))
    }

    @Test("[Unit][VOX-ERR-001] the table size rejects typed")
    func tableSizeRejectsTyped() {
        #expect(throws: TransferFunctionError.invalidTableSize) {
            try TransferFunction1D(
                entries: [
                    TransferFunctionEntry(red: 0, green: 0, blue: 0, opacity: 0)
                ]
            )
        }
        #expect(throws: TransferFunctionError.invalidTableSize) {
            try TransferFunction1D(entries: [])
        }
    }
}

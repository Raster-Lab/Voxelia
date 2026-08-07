// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaRendering

@Suite("MultiDimensionalTransfer")
struct MultiDimensionalTransferTests {
    private func table() throws -> MultiDimensionalTransferFunction {
        try MultiDimensionalTransferFunction(
            intensityBins: 2,
            intensityLowerBound: 0,
            intensityUpperBound: 100,
            gradientBins: 2,
            gradientLowerBound: 0,
            gradientUpperBound: 4,
            entries: [
                try TransferTableEntry(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.05),
                try TransferTableEntry(red: 0.9, green: 0.1, blue: 0.1, opacity: 0.8),
                try TransferTableEntry(red: 0.1, green: 0.9, blue: 0.1, opacity: 0.3),
                try TransferTableEntry(red: 0.1, green: 0.1, blue: 0.9, opacity: 1),
            ]
        )
    }

    @Test("[Unit][VOX-DVR-006] lookup selects stored entries verbatim")
    func lookupSelectsStoredEntriesVerbatim() throws {
        let transfer = try table()
        let low = try transfer.entry(intensity: 10, gradientMagnitude: 1)
        #expect(low.opacity == 0.05)
        // The exact top edge joins the last bin, in both dimensions.
        let edge = try transfer.entry(intensity: 50, gradientMagnitude: 4)
        #expect(edge.blue == 0.9 && edge.opacity == 1)
        let top = try transfer.entry(intensity: 100, gradientMagnitude: 0)
        #expect(top.green == 0.9 && top.opacity == 0.3)
        // Out of range refuses; a clamped colour would be a fabricated
        // classification.
        #expect(throws: MultiDimensionalTransferError.sampleOutOfRange) {
            _ = try transfer.entry(intensity: 150, gradientMagnitude: 0)
        }
    }

    @Test("[Unit][VOX-DVR-006] material conditioning selects by exact index")
    func materialConditioningSelectsByExactIndex() throws {
        let conditioned = try MaterialConditionedTransfer(
            tables: [try table(), try table()]
        )
        let entry = try conditioned.entry(
            material: 1,
            intensity: 10,
            gradientMagnitude: 1
        )
        #expect(entry.opacity == 0.05)
        #expect(throws: MultiDimensionalTransferError.sampleOutOfRange) {
            _ = try conditioned.entry(material: 2, intensity: 10, gradientMagnitude: 1)
        }
    }

    @Test("[Unit][VOX-DVR-006] admissions reject typed")
    func admissionsRejectTyped() throws {
        #expect(throws: MultiDimensionalTransferError.invalidBinCount) {
            _ = try MultiDimensionalTransferFunction(
                intensityBins: 1,
                intensityLowerBound: 0,
                intensityUpperBound: 100,
                gradientBins: 2,
                gradientLowerBound: 0,
                gradientUpperBound: 4,
                entries: []
            )
        }
        #expect(throws: MultiDimensionalTransferError.entryCountMismatch) {
            _ = try MultiDimensionalTransferFunction(
                intensityBins: 2,
                intensityLowerBound: 0,
                intensityUpperBound: 100,
                gradientBins: 2,
                gradientLowerBound: 0,
                gradientUpperBound: 4,
                entries: [
                    try TransferTableEntry(red: 0, green: 0, blue: 0, opacity: 0)
                ]
            )
        }
        #expect(throws: MultiDimensionalTransferError.invalidEntry) {
            _ = try TransferTableEntry(red: 0, green: 0, blue: 0, opacity: 2)
        }
        #expect(throws: MultiDimensionalTransferError.invalidRange) {
            _ = try MultiDimensionalTransferFunction(
                intensityBins: 2,
                intensityLowerBound: 100,
                intensityUpperBound: 0,
                gradientBins: 2,
                gradientLowerBound: 0,
                gradientUpperBound: 4,
                entries: []
            )
        }
    }
}

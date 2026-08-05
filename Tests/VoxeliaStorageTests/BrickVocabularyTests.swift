// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaStorage

@Suite("BrickVocabulary")
struct BrickVocabularyTests {
    private func grid() throws -> BrickGridDescriptor {
        try BrickGridDescriptor(
            volumeExtents: [100, 64, 30],
            nominalBrickExtents: [32, 32, 16],
            haloExtents: [2, 2, 2]
        )
    }

    @Test("[Unit][VOX-BRK-002][VOX-BRK-004] the frozen layout reproduces the fixtures")
    func frozenLayoutReproducesTheFixtures() throws {
        // The ADR-0147 fixtures: ceiling-division counts, the
        // structural boundary brick, and both clamped haloed regions
        // — with repeated derivation identical.
        let grid = try grid()
        #expect(grid.brickCounts == [4, 2, 2])

        let boundary = try grid.coreRegion(of: [3, 1, 1])
        #expect(boundary.lowerBounds == [96, 32, 16])
        #expect(boundary.upperBounds == [100, 64, 30])

        let corner = try grid.haloedRegion(of: [0, 0, 0])
        #expect(corner.lowerBounds == [0, 0, 0])
        #expect(corner.upperBounds == [34, 34, 18])

        let far = try grid.haloedRegion(of: [3, 1, 1])
        #expect(far.lowerBounds == [94, 30, 14])
        #expect(far.upperBounds == [100, 64, 30])

        #expect(try grid.haloedRegion(of: [3, 1, 1]) == far)

        let halved = try BrickResolutionLevel(
            index: 1,
            downsamplingFactors: [2, 2, 2]
        )
        #expect(try grid.levelExtents(for: halved) == [50, 32, 15])
        let mixed = try BrickResolutionLevel(
            index: 2,
            downsamplingFactors: [4, 4, 2]
        )
        #expect(try grid.levelExtents(for: mixed) == [25, 16, 15])

        let identity = try BrickIdentity(
            volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
            levelIndex: 0,
            coordinate: [3, 1, 1]
        )
        #expect(identity.coordinate == [3, 1, 1])
        #expect(
            identity
                == (try BrickIdentity(
                    volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
                    levelIndex: 0,
                    coordinate: [3, 1, 1]
                ))
        )
    }

    @Test("[Unit][VOX-BRK-003][VOX-ERR-001] the vocabulary admissions reject typed")
    func vocabularyAdmissionsRejectTyped() throws {
        #expect(throws: BrickVocabularyError.invalidVolumeExtent) {
            try BrickGridDescriptor(
                volumeExtents: [100, 0, 30],
                nominalBrickExtents: [32, 32, 16],
                haloExtents: [2, 2, 2]
            )
        }
        #expect(throws: BrickVocabularyError.invalidBrickExtent) {
            try BrickGridDescriptor(
                volumeExtents: [100, 64, 30],
                nominalBrickExtents: [32, 0, 16],
                haloExtents: [2, 2, 2]
            )
        }
        #expect(throws: BrickVocabularyError.invalidHalo) {
            try BrickGridDescriptor(
                volumeExtents: [100, 64, 30],
                nominalBrickExtents: [32, 32, 16],
                haloExtents: [2, 2, 16]
            )
        }
        #expect(throws: BrickVocabularyError.invalidHalo) {
            try BrickGridDescriptor(
                volumeExtents: [100, 64, 30],
                nominalBrickExtents: [32, 32, 16],
                haloExtents: [2, -1, 2]
            )
        }
        #expect(throws: BrickVocabularyError.rankMismatch) {
            try BrickGridDescriptor(
                volumeExtents: [100, 64, 30],
                nominalBrickExtents: [32, 32],
                haloExtents: [2, 2, 2]
            )
        }
        #expect(throws: BrickVocabularyError.invalidDownsamplingFactor) {
            try BrickResolutionLevel(index: 0, downsamplingFactors: [2, 0, 2])
        }
        #expect(throws: BrickVocabularyError.invalidLevelIndex) {
            try BrickResolutionLevel(index: -1, downsamplingFactors: [2, 2, 2])
        }
        let grid = try grid()
        #expect(throws: BrickVocabularyError.brickOutsideGrid) {
            try grid.coreRegion(of: [4, 0, 0])
        }
        #expect(throws: BrickVocabularyError.brickOutsideGrid) {
            try grid.coreRegion(of: [0, -1, 0])
        }
        #expect(throws: BrickVocabularyError.rankMismatch) {
            try grid.coreRegion(of: [0, 0])
        }
        #expect(throws: BrickVocabularyError.rankMismatch) {
            try grid.levelExtents(
                for: try BrickResolutionLevel(
                    index: 1,
                    downsamplingFactors: [2, 2]
                )
            )
        }
        #expect(throws: BrickVocabularyError.invalidLevelIndex) {
            try BrickIdentity(
                volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
                levelIndex: -1,
                coordinate: [0, 0, 0]
            )
        }
        #expect(throws: BrickVocabularyError.brickOutsideGrid) {
            try BrickIdentity(
                volumeObjectID: try #require(DataObjectID(rawValue: "volume-7")),
                levelIndex: 0,
                coordinate: [0, -1, 0]
            )
        }
    }
}

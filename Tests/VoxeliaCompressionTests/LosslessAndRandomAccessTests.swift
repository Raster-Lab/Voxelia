// SPDX-License-Identifier: MIT

import Foundation
import J2K3D
import J2KCore
import Testing

@testable import VoxeliaCompression

/// `ADR-0299` (`VOX-VAL-013`): compression validation covering lossless equality and
/// random-access correctness.
///
/// The volume is a **positional phantom**: every voxel holds `100i + 10j + k`, so its value
/// names its own index. That is what makes the random-access half discriminating — a region
/// decode that returned the right *shape* from the wrong *offset* would be invisible against
/// noise, and is immediate against this.
@Suite("LosslessAndRandomAccess")
struct LosslessAndRandomAccessTests {
    private static let width = 8
    private static let height = 6
    private static let depth = 4

    /// The closed form. Every extent is below ten, so the three place values never carry into
    /// one another and the map from index to value is injective.
    private func expected(x: Int, y: Int, z: Int) -> Int {
        100 * x + 10 * y + z
    }

    /// The source samples, little-endian `uint16`, column fastest then row then slice.
    private func sourceBytes() -> Data {
        var bytes = Data()
        bytes.reserveCapacity(Self.width * Self.height * Self.depth * 2)
        for z in 0..<Self.depth {
            for y in 0..<Self.height {
                for x in 0..<Self.width {
                    let value = UInt16(expected(x: x, y: y, z: z))
                    bytes.append(UInt8(truncatingIfNeeded: value))
                    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
                }
            }
        }
        return bytes
    }

    private func sourceVolume() -> J2KVolume {
        J2KVolume(
            width: Self.width,
            height: Self.height,
            depth: Self.depth,
            components: [
                J2KVolumeComponent(
                    index: 0,
                    bitDepth: 16,
                    signed: false,
                    width: Self.width,
                    height: Self.height,
                    depth: Self.depth,
                    subsamplingX: 1,
                    subsamplingY: 1,
                    subsamplingZ: 1,
                    data: sourceBytes()
                )
            ],
            spacingX: 0.5,
            spacingY: 0.5,
            spacingZ: 2.0,
            originX: 0,
            originY: 0,
            originZ: 0
        )
    }

    /// Tiles small enough that a region can skip most of them. With a tile of `4 x 4 x 2`
    /// over an `8 x 6 x 4` volume the grid is `2 x 2 x 2`, so a single-tile request has seven
    /// tiles to leave alone.
    private func encoded() async throws -> JP3DEncoderResult {
        let configuration = JP3DEncoderConfiguration(
            compressionMode: .lossless,
            tiling: JP3DTilingConfiguration(tileSizeX: 4, tileSizeY: 4, tileSizeZ: 2),
            qualityLayers: 1
        )
        return try await JP3DEncoder(configuration: configuration).encode(sourceVolume())
    }

    private func sample(_ volume: J2KVolume, offset: Int) -> Int {
        let data = volume.components[0].data
        let low = UInt16(data[data.startIndex + offset * 2])
        let high = UInt16(data[data.startIndex + offset * 2 + 1])
        return Int(low | high << 8)
    }

    // MARK: - The phantom itself

    @Test("[Unit][VOX-VAL-013] every voxel value names exactly one index")
    func everyVoxelValueNamesExactlyOneIndex() {
        // Why this volume and not an arbitrary one. If two voxels shared a value, a region
        // decode could return the wrong one and the comparison below would still pass.
        var seen = Set<Int>()
        for z in 0..<Self.depth {
            for y in 0..<Self.height {
                for x in 0..<Self.width {
                    #expect(seen.insert(expected(x: x, y: y, z: z)).inserted)
                }
            }
        }
        #expect(seen.count == Self.width * Self.height * Self.depth)
    }

    // MARK: - Lossless equality

    @Test("[Unit][VOX-VAL-013] a lossless round trip returns the source bytes exactly")
    func losslessRoundTripReturnsTheSourceBytesExactly() async throws {
        let encodedResult = try await encoded()
        #expect(encodedResult.isLossless)
        #expect(encodedResult.width == Self.width)
        #expect(encodedResult.height == Self.height)
        #expect(encodedResult.depth == Self.depth)
        #expect(encodedResult.tileCount == 8)

        let decoded = try await JP3DDecoder().decode(encodedResult.data)
        #expect(decoded.volume.width == Self.width)
        #expect(decoded.volume.height == Self.height)
        #expect(decoded.volume.depth == Self.depth)
        #expect(decoded.volume.components.count == 1)

        // Byte-for-byte, not sample-by-sample with a tolerance. Lossless means exactly this.
        #expect(decoded.volume.components[0].data == sourceBytes())
    }

    @Test("[Unit][VOX-VAL-013] the round trip preserves the value at every index")
    func roundTripPreservesTheValueAtEveryIndex() async throws {
        // The semantic half of the same claim. Byte equality alone would hold even if the
        // codec had read the samples in the wrong byte order throughout, because it would
        // then write them back the same way.
        let encodedResult = try await encoded()
        let decoded = try await JP3DDecoder().decode(encodedResult.data)
        for z in 0..<Self.depth {
            for y in 0..<Self.height {
                for x in 0..<Self.width {
                    let offset = x + Self.width * (y + Self.height * z)
                    #expect(
                        sample(decoded.volume, offset: offset) == expected(x: x, y: y, z: z))
                }
            }
        }
    }

    // MARK: - Random-access correctness

    @Test("[Unit][VOX-VAL-013] a region decode returns that region's own samples")
    func regionDecodeReturnsThatRegionsOwnSamples() async throws {
        // Deliberately **not** anchored at the origin. A region at (0, 0, 0) is returned
        // correctly by a decoder that ignores the offset entirely, so it cannot show that
        // random access works.
        let encodedResult = try await encoded()
        let requested = JP3DRegion(x: 4..<8, y: 0..<4, z: 2..<4)
        let result = try await JP3DDecoder().decode(encodedResult.data, region: requested)

        #expect(!result.isFullVolume)
        // The request covers exactly one tile of the two-by-two-by-two grid, so seven are
        // left alone. Asserted exactly: "greater than zero" would also hold for a decoder
        // that skipped one tile and decoded the rest.
        #expect(result.tilesDecoded == 1)
        #expect(result.tilesSkipped == 7)
        #expect(result.warnings.isEmpty)

        // Asserted against the region the decoder says it produced, so a clamped or expanded
        // region is compared where it actually landed rather than where it was asked for.
        let region = result.decodedRegion
        #expect(result.volume.width == region.x.count)
        #expect(result.volume.height == region.y.count)
        #expect(result.volume.depth == region.z.count)

        for z in region.z {
            for y in region.y {
                for x in region.x {
                    let offset =
                        (x - region.x.lowerBound)
                        + region.x.count
                        * ((y - region.y.lowerBound)
                            + region.y.count * (z - region.z.lowerBound))
                    #expect(
                        sample(result.volume, offset: offset) == expected(x: x, y: y, z: z))
                }
            }
        }
    }

    @Test("[Unit][VOX-VAL-013] two disjoint regions return different samples")
    func twoDisjointRegionsReturnDifferentSamples() async throws {
        // The falsification. A decoder that served the same block regardless of the request
        // would pass the test above for one region; it cannot pass this.
        let encodedResult = try await encoded()
        let near = try await JP3DDecoder().decode(
            encodedResult.data, region: JP3DRegion(x: 0..<4, y: 0..<4, z: 0..<2))
        let far = try await JP3DDecoder().decode(
            encodedResult.data, region: JP3DRegion(x: 4..<8, y: 0..<4, z: 2..<4))

        #expect(near.volume.components[0].data != far.volume.components[0].data)
        #expect(sample(near.volume, offset: 0) == expected(x: 0, y: 0, z: 0))
        let corner = far.decodedRegion
        let farCorner = expected(
            x: corner.x.lowerBound, y: corner.y.lowerBound, z: corner.z.lowerBound)
        #expect(sample(far.volume, offset: 0) == farCorner)
    }

    @Test("[Unit][VOX-VAL-013] a region decode agrees with the full decode it subsets")
    func regionDecodeAgreesWithTheFullDecodeItSubsets() async throws {
        // The two paths are independent implementations of the same question, so they are
        // compared against each other as well as against the closed form.
        let encodedResult = try await encoded()
        let full = try await JP3DDecoder().decode(encodedResult.data)
        let partial = try await JP3DDecoder().decode(
            encodedResult.data, region: JP3DRegion(x: 4..<8, y: 2..<6, z: 0..<2))
        let region = partial.decodedRegion

        for z in region.z {
            for y in region.y {
                for x in region.x {
                    let fullOffset = x + Self.width * (y + Self.height * z)
                    let partialOffset =
                        (x - region.x.lowerBound)
                        + region.x.count
                        * ((y - region.y.lowerBound)
                            + region.y.count * (z - region.z.lowerBound))
                    #expect(
                        sample(partial.volume, offset: partialOffset)
                            == sample(full.volume, offset: fullOffset))
                }
            }
        }
    }
}

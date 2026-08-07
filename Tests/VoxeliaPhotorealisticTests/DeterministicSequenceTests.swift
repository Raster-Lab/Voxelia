// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaPhotorealistic

@Suite("DeterministicSequence")
struct DeterministicSequenceTests {
    @Test("[Unit][VOX-PRR-010] pinned words for pinned seeds")
    func pinnedWordsForPinnedSeeds() throws {
        var zero = DeterministicSampleSequence(seed: 0)
        #expect(zero.nextWord() == 0xE220_A839_7B1D_CDAF)
        #expect(zero.nextWord() == 0x6E78_9E6A_A1B9_65F4)
        #expect(zero.nextWord() == 0x06C4_5D18_8009_454F)
        #expect(zero.nextWord() == 0xF88B_B8A8_724C_81EC)

        var beef = DeterministicSampleSequence(seed: 0xDEAD_BEEF)
        #expect(beef.nextWord() == 0x4ADF_B90F_68C9_EB9B)
        #expect(beef.nextWord() == 0xDE58_6A31_41A1_0922)
        #expect(beef.nextWord() == 0x021F_BC2F_8E1C_FC1D)
        #expect(beef.nextWord() == 0x7466_CE73_7BE1_6790)
    }

    @Test("[Unit][VOX-PRR-010] unit samples are exact and reproducible")
    func unitSamplesAreExactAndReproducible() throws {
        var first = DeterministicSampleSequence(seed: 42)
        #expect(first.nextUnit() == 0x1.7bae644c5fd6dp-1)
        #expect(first.nextUnit() == 0x1.477f199d93378p-3)
        #expect(first.nextUnit() == 0x1.1d499d5c4c3e6p-2)

        // Equal seeds give equal sequences, word for word.
        var again = DeterministicSampleSequence(seed: 42)
        var reference = DeterministicSampleSequence(seed: 42)
        for _ in 0..<16 {
            #expect(again.nextWord() == reference.nextWord())
        }
    }
}

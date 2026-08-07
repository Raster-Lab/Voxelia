// SPDX-License-Identifier: MIT

import Foundation
import Metal
import Testing

@testable import VoxeliaMetal

/// `ADR-0306` (`VOX-MTL-009`): the backend minimises full-volume CPU-to-GPU duplication.
///
/// `ADR-0305` fixed what this suite has to assert and, just as importantly, what it may not
/// borrow. `ResidencyPolicyTests` covers the vocabulary and its `Sendable` conformance;
/// neither fact bears on duplication, so none of it is reused here.
///
/// The evidence is the **allocated buffer's storage mode**, not the selection enum. A shared
/// buffer is one allocation the CPU and GPU both address, so no full-volume copy exists; a
/// private buffer is a device-side duplicate, chosen deliberately for repeated GPU access.
/// Asserting the selection alone would prove what the manager intends, not what it allocates.
@Suite("ResidencyDuplication")
struct ResidencyDuplicationTests {
    private func manager() throws -> (MetalResidencyManager, MetalExecutionContext) {
        let context = try MetalExecutionContext()
        return (MetalResidencyManager(context: context), context)
    }

    @Test("[Unit][VOX-MTL-009] a shared policy allocates one buffer both processors address")
    func sharedPolicyAllocatesOneBufferBothProcessorsAddress() throws {
        // The row's subject, measured on the allocation. `storageModeShared` is a single
        // range of memory visible to both, which is what "no full-volume duplication" means
        // on this hardware.
        let (residency, context) = try manager()
        try #require(context.supportsUnifiedMemory)

        for policy in [ResidencyPolicy.automatic, .shared] {
            #expect(try residency.selection(for: policy) == .shared)
            let buffer = try residency.makeBuffer(byteCount: 4096, policy: policy)
            #expect(buffer.storageMode == .shared)
            #expect(buffer.length == 4096)
        }
    }

    @Test("[Unit][VOX-MTL-009] the GPU-optimised policy is the one that does duplicate")
    func gpuOptimisedPolicyIsTheOneThatDoesDuplicate() throws {
        // The contrast that makes the test above meaningful. If every policy produced shared
        // storage the assertion would hold for a manager that ignored its input entirely.
        let (residency, _) = try manager()
        #expect(try residency.selection(for: .gpuOptimised) == .privateDevice)
        let buffer = try residency.makeBuffer(byteCount: 4096, policy: .gpuOptimised)
        #expect(buffer.storageMode == .private)
        #expect(buffer.storageMode != .shared)
    }

    @Test("[Unit][VOX-MTL-009] an unfulfillable policy refuses by its own distinct case")
    func unfulfillablePolicyRefusesByItsOwnDistinctCase() throws {
        // A caller asking for no device residency, or for a policy this version does not
        // implement, is refused rather than quietly given a duplicate. The cases are checked
        // separately because collapsing them would lose the difference between "this policy
        // means no GPU copy" and "this policy is not implemented yet".
        let (residency, _) = try manager()
        #expect(throws: MetalResidencyError.policyRequiresNoDeviceResidency) {
            _ = try residency.selection(for: .cpuOnly)
        }
        for policy in [ResidencyPolicy.streamed, .sparse] {
            #expect(throws: MetalResidencyError.unsupportedResidencyPolicy) {
                _ = try residency.selection(for: policy)
            }
        }
    }

    @Test("[Unit][VOX-MTL-009] a refused policy allocates nothing")
    func refusedPolicyAllocatesNothing() throws {
        // The refusal has to reach the allocation path too. A manager that refused the
        // selection and then allocated anyway would satisfy the test above and still
        // duplicate the volume.
        let (residency, _) = try manager()
        for policy in [ResidencyPolicy.cpuOnly, .streamed, .sparse] {
            #expect(throws: (any Error).self) {
                _ = try residency.makeBuffer(byteCount: 4096, policy: policy)
            }
        }
    }

    @Test("[Unit][VOX-MTL-009] an empty allocation is refused before any policy is consulted")
    func emptyAllocationIsRefusedBeforeAnyPolicyIsConsulted() throws {
        // `invalidByteCount` rather than a policy error, for a policy that would otherwise
        // succeed: the byte-count guard runs first, so a zero-length request cannot produce
        // a zero-length device buffer that later reads treat as a volume.
        let (residency, _) = try manager()
        #expect(throws: MetalResidencyError.invalidByteCount) {
            _ = try residency.makeBuffer(byteCount: 0, policy: .shared)
        }
        #expect(throws: MetalResidencyError.invalidByteCount) {
            _ = try residency.makeBuffer(byteCount: -1, policy: .gpuOptimised)
        }
    }

    @Test("[Unit][VOX-MTL-009] this host is the unified-memory case the analysis assumes")
    func thisHostIsTheUnifiedMemoryCaseTheAnalysisAssumes() throws {
        // `ADR-0306`'s analysis has two branches, and only one of them is exercised above.
        // Recording which branch this host is on keeps the evidence honest: on a device
        // without unified memory the guarantee is a typed refusal, not shared storage.
        let (_, context) = try manager()
        #expect(context.supportsUnifiedMemory)
    }
}

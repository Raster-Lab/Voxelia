// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore

@testable import VoxeliaMetal

@Suite("MetalExecutionContext")
struct MetalExecutionContextTests {
    @Test("[Unit][VOX-PLT-014][VOX-EXE-003] the context acquires by capability only")
    func contextAcquiresByCapabilityOnly() throws {
        // Real host evidence per ADR-0079: acquisition must succeed on
        // a supported Apple-silicon development host, and an
        // environment without a device fails loudly rather than
        // skipping silently.
        let context = try MetalExecutionContext()

        // The detected capability is the closed Metal 3 token and
        // parses as the accepted execution-claim capability class, so
        // GPU claims plug into the existing provenance discipline.
        #expect(
            context.capabilityClass
                == (try ExecutionClaimToken(
                    rawValue: "org.voxelia.capability.metal3"
                ))
        )
        let claim = ExecutionProvenanceClaim(
            profile: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.profile.default"
                ),
                version: try SemanticVersion(major: 1, minor: 0, patch: 0)
            ),
            backend: try ExecutionComponentReference(
                identifier: try ExecutionClaimToken(
                    rawValue: "org.voxelia.backend.metal"
                ),
                version: try SemanticVersion(major: 1, minor: 0, patch: 0)
            ),
            precisionPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.precision.binary32-device"
            ),
            qualityPolicy: try ExecutionClaimToken(
                rawValue: "org.voxelia.quality.full"
            ),
            approximationStatus: .approximate,
            capabilityClass: context.capabilityClass,
            kernel: nil
        )
        #expect(claim.capabilityClass == context.capabilityClass)

        // Apple silicon shares one memory space; the registry
        // identifier is opaque evidence, not a name.
        #expect(context.supportsUnifiedMemory)
        #expect(context.deviceRegistryIdentifier != 0)

        // The ADR-0105 capability model: the documented family texture
        // limit and positive reported device limits; the sparse and
        // ray-tracing booleans are device-dependent and recorded as
        // printed evidence, not asserted.
        let capabilities = context.capabilities
        #expect(capabilities.supportsUnifiedMemory == context.supportsUnifiedMemory)
        #expect(capabilities.maximumTextureDimension == 16_384)
        #expect(capabilities.maximumThreadsPerThreadgroupWidth >= 1)
        #expect(capabilities.recommendedMaximumWorkingSetByteCount > 0)
        print(
            "ADR-0105 capability evidence: sparse=\(capabilities.supportsSparseTextures) "
                + "raytracing=\(capabilities.supportsRaytracing) "
                + "threadgroupWidth=\(capabilities.maximumThreadsPerThreadgroupWidth) "
                + "workingSetBytes=\(capabilities.recommendedMaximumWorkingSetByteCount)"
        )

        requireSendable(MetalExecutionContext.self)
        requireSendable(MetalContextError.self)
        requireSendable(MetalDeviceCapabilities.self)
    }

    @Test("[Concurrency][VOX-MTL-004][VOX-CON-003] checked borrows preserve handle identity")
    func checkedBorrowsPreserveHandleIdentity() async throws {
        let context = try MetalExecutionContext()
        let expected = context.withMetalHandles(HandleIdentity.init)

        await withTaskGroup(of: HandleIdentity.self) { group in
            for _ in 0..<32 {
                group.addTask {
                    context.withMetalHandles(HandleIdentity.init)
                }
            }

            for await observed in group {
                #expect(observed == expected)
            }
        }

        #expect(context.pipelineCache === context.pipelineCache)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}

    private struct HandleIdentity: Sendable, Equatable {
        let device: ObjectIdentifier
        let commandQueue: ObjectIdentifier

        init(device: any AnyObject, commandQueue: any AnyObject) {
            self.device = ObjectIdentifier(device)
            self.commandQueue = ObjectIdentifier(commandQueue)
        }
    }
}

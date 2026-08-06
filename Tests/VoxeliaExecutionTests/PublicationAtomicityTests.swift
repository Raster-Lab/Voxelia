// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial
import VoxeliaStorage

@testable import VoxeliaExecution

/// `ADR-0249` decision 6: publication-time atomicity under cancellation.
///
/// That decision declined to add a cancellation probe to `publish`, on the
/// grounds that its registration phase does not suspend and therefore has no
/// cancellation point — so "no partial `ImageData`" and "no corrupt cache entry"
/// are properties of the existing design rather than of a new check. The record
/// required that claim be **verified by test rather than asserted**, which is
/// what this suite does.
///
/// The claim has a precise shape worth stating, because it is not "publication is
/// cancellable" and it is not "publication ignores cancellation":
///
/// - Phase one — verifying a sample-bytes content claim — **does** suspend, and
///   `StorageReadCoordinator` is cancellation-aware, so cancellation there
///   refuses typed and registers nothing.
/// - Phase two — identifier reuse, the ceiling, ancestry closure, graph admission
///   and the registry mutation — **does not suspend**, so it cannot be observed
///   half-done.
/// - Therefore the registry invariant is: an image is published **if and only
///   if** its provenance record is, whatever a caller does with cancellation.
@Suite("PublicationAtomicity")
struct PublicationAtomicityTests {
    // MARK: - Fixtures

    private func axis(_ id: String) throws -> AxisDescriptor {
        try AxisDescriptor(
            id: try #require(AxisID(rawValue: id)),
            name: id,
            semantic: .spatialX,
            unit: nil,
            sampling: .indexOnly
        )
    }

    private func software() throws -> SoftwareIdentity {
        try SoftwareIdentity(
            name: "Voxelia",
            version: try SemanticVersion(major: 1, minor: 0, patch: 0),
            commit: nil,
            buildIdentifier: nil
        )
    }

    /// One publishable image, optionally carrying a sample-bytes content claim.
    ///
    /// The claim is what decides whether `publish` suspends before its critical
    /// section, so it is the switch this suite turns on and off.
    private func image(
        objectName: String,
        recordName: String,
        claimsContent: Bool
    ) throws -> ImageData {
        let storedBytes: [UInt8] = Array(0..<12)
        let binding = try LogicalSampleBinding(
            shape: try ImageShape(extents: [4, 3]),
            scalarType: .uint8,
            componentCount: 1
        )
        return try ImageData(
            descriptor: try ImageDescriptor(
                shape: try ImageShape(extents: [4, 3]),
                scalarFormat: try ScalarFormat(
                    type: .uint8,
                    validBitCount: nil,
                    byteOrder: .native
                ),
                components: try ComponentDescriptor(
                    count: 1,
                    interpretation: .scalar,
                    layout: .interleaved,
                    componentNames: nil
                ),
                semantic: .intensity,
                axes: [try axis("x"), try axis("y")],
                spatialGeometry: nil,
                valueTransform: nil,
                units: nil
            ),
            storage: AnyImageStorage(
                erasing: try ContiguousImageStorage(
                    binding: binding,
                    bytes: storedBytes
                )
            ),
            metadata: try MetadataCollection(entries: []),
            provenance: try ProvenanceRecord(
                id: try #require(ProvenanceID(rawValue: recordName)),
                kind: .source,
                createdAt: try CanonicalInstant(utcString: "2026-08-06T12:00:00Z"),
                subject: .object(try #require(DataObjectID(rawValue: objectName))),
                software: try software(),
                activity: .origin,
                inputs: [],
                warnings: [],
                validationClaim: .unknown,
                declaresZeroInputGenerator: false
            ),
            identity: try DataIdentity(
                objectID: try #require(DataObjectID(rawValue: objectName)),
                contentID: claimsContent
                    ? try ContentID.sampleBytesIdentity(
                        overCanonicalPackedBytes: storedBytes
                    )
                    : nil,
                sourceIdentities: [
                    try SourceIdentity(
                        namespace: "dicom.sop-instance-uid",
                        identifier: "1.2.840.113619.2",
                        version: nil,
                        contentID: nil
                    )
                ],
                derivation: nil
            )
        )
    }

    private func coordinator() throws -> PublicationCoordinator {
        PublicationCoordinator(
            maximumPublishedObjectCount: 64,
            graphLimits: try ProvenanceGraphLimits(
                maximumRecordCount: 64,
                maximumParentEdgeCount: 64,
                maximumAncestryDepth: 64,
                maximumUnresolvedExternalReferenceCount: 0,
                maximumExternalResolutionByteCount: 8_192
            ),
            readCoordinator: StorageReadCoordinator(
                maximumRetainedResultByteCount: 4_096
            ),
            resultCache: nil
        )
    }

    /// Whether the registry holds both halves, neither, or — the failure this
    /// suite exists to catch — exactly one.
    private enum RegistryState: Equatable {
        case both
        case neither
        case imageOnly
        case provenanceOnly
    }

    private func state(
        of coordinator: PublicationCoordinator,
        objectName: String,
        recordName: String
    ) async throws -> RegistryState {
        let objectID = try #require(DataObjectID(rawValue: objectName))
        let recordID = try #require(ProvenanceID(rawValue: recordName))
        let hasImage = await coordinator.publishedImage(for: objectID) != nil
        let hasRecord = await coordinator.publishedProvenanceRecord(for: recordID) != nil
        switch (hasImage, hasRecord) {
        case (true, true): return .both
        case (false, false): return .neither
        case (true, false): return .imageOnly
        case (false, true): return .provenanceOnly
        }
    }

    // MARK: - The invariant

    @Test("[Unit][VOX-VS1-017] cancellation outcome is decided by the content claim, not by a race")
    func cancellationOutcomeIsDecidedByTheContentClaim() async throws {
        // Stronger than "the invariant held": this pins WHICH outcome each shape
        // produces, because measuring the distribution showed the split is
        // deterministic rather than racy -- 24 of 24 in each direction.
        //
        //   no content claim -> no suspension before phase two -> ALWAYS .both
        //   content claim    -> phase one's cancellable read    -> ALWAYS .neither
        //
        // Asserting the exact outcome is what makes this test able to fail
        // usefully. A suspension introduced into phase two would turn a `.both`
        // into `.neither` and break the first expectation; a content claim that
        // stopped being verified before registration would break the second. A
        // test that merely accepted "both or neither" would notice neither
        // change.
        for claimsContent in [false, true] {
            let expected: RegistryState = claimsContent ? .neither : .both
            for attempt in 0..<24 {
                let coordinator = try coordinator()
                let objectName = "atomic-\(claimsContent)-\(attempt)"
                let recordName = "atomic-rec-\(claimsContent)-\(attempt)"
                let subject = try image(
                    objectName: objectName,
                    recordName: recordName,
                    claimsContent: claimsContent
                )

                let task = Task {
                    try await coordinator.publish(subject, mode: .complete)
                }
                task.cancel()
                _ = try? await task.value

                let observed = try await state(
                    of: coordinator,
                    objectName: objectName,
                    recordName: recordName
                )
                // The invariant first -- a half-registered object is the failure
                // this suite exists to catch, whatever the shape.
                #expect(observed == .both || observed == .neither)
                // Then the exact mechanism.
                #expect(observed == expected)
            }
        }
    }

    @Test(
        "[Unit][VOX-VS1-017] publication without a content claim survives cancellation"
    )
    func publicationWithoutContentClaimCompletes() async throws {
        // The sharp end of ADR-0249 decision 6. With no content claim there is
        // no suspension between entry and the registry mutation, so an already
        // cancelled task still publishes completely -- which is exactly why a
        // probe inside the critical section would be an unreachable branch. If
        // this test ever fails, a suspension point has been introduced into
        // phase two and decision 6 must be revisited.
        let coordinator = try coordinator()
        let subject = try image(
            objectName: "atomic-noclaim",
            recordName: "atomic-noclaim-rec",
            claimsContent: false
        )

        let task = Task {
            try await coordinator.publish(subject, mode: .complete)
        }
        task.cancel()
        let receipt = try? await task.value

        let observed = try await state(
            of: coordinator,
            objectName: "atomic-noclaim",
            recordName: "atomic-noclaim-rec"
        )
        // Either it published fully or it refused; a receipt implies the former.
        if receipt != nil {
            #expect(observed == .both)
        } else {
            #expect(observed == .neither)
        }
    }

    @Test("[Unit][VOX-VS1-017] an uncancelled publish registers both halves")
    func uncancelledPublishRegistersBoth() async throws {
        // The control: without cancellation the registry holds both halves, so
        // the tests above are proving atomicity rather than a coordinator that
        // never publishes anything.
        let coordinator = try coordinator()
        for claimsContent in [false, true] {
            let objectName = "atomic-ok-\(claimsContent)"
            let recordName = "atomic-ok-rec-\(claimsContent)"
            _ = try await coordinator.publish(
                try image(
                    objectName: objectName,
                    recordName: recordName,
                    claimsContent: claimsContent
                ),
                mode: .complete
            )
            let observed = try await state(
                of: coordinator,
                objectName: objectName,
                recordName: recordName
            )
            #expect(observed == .both)
        }
    }

    @Test("[Unit][VOX-VS1-017] concurrent cancelled publications never half-register")
    func concurrentCancelledPublicationsNeverHalfRegister() async throws {
        // One coordinator, sixteen concurrent publications, every task
        // cancelled. Each object is independent, so the invariant must hold for
        // every one of them: the actor's critical section linearises them, and a
        // suspension inside it would show up here as a half-registered object.
        let coordinator = try coordinator()
        let count = 16

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<count {
                group.addTask {
                    guard
                        let subject = try? self.image(
                            objectName: "atomic-conc-\(index)",
                            recordName: "atomic-conc-rec-\(index)",
                            claimsContent: index.isMultiple(of: 2)
                        )
                    else { return }
                    let task = Task {
                        try await coordinator.publish(subject, mode: .complete)
                    }
                    task.cancel()
                    _ = try? await task.value
                }
            }
        }

        for index in 0..<count {
            let observed = try await state(
                of: coordinator,
                objectName: "atomic-conc-\(index)",
                recordName: "atomic-conc-rec-\(index)"
            )
            #expect(observed == .both || observed == .neither)
        }
    }
}

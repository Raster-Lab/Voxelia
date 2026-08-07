// SPDX-License-Identifier: MIT

import Testing
import VoxeliaCore
import VoxeliaSpatial

@testable import VoxeliaRendering

/// `ADR-0290` (`VOX-ERR-004`): unsupported diagnostic behaviour fails explicitly rather
/// than silently selecting preview behaviour.
///
/// "Preview" is not a vague adjective here. `VOX-EXE-011` names four execution policies —
/// reference, diagnostic, interactive and preview — and `ProvenanceValidationClaim` names
/// `preview` beside `diagnosticReady`. So the row's content is precise: when a diagnostic
/// request cannot be served, the answer is a typed refusal, never a quieter substitute
/// served under the same name.
///
/// Every case below pairs a refusal with the nearest **supported** input, because a
/// refusal that fires on everything proves nothing about discrimination.
@Suite("DiagnosticFailClosed")
struct DiagnosticFailClosedTests {
    private func space() throws -> CoordinateSpaceDescriptor {
        try CoordinateSpaceDescriptor(
            id: try #require(CoordinateSpaceID(rawValue: "patient")),
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: []
        )
    }

    private func geometry() throws -> AffineGridGeometry {
        try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1, 2]),
            indexToWorld: try Matrix4x4Double(elements: [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 2, 0,
                0, 0, 0, 1,
            ]),
            coordinateSpace: try space()
        )
    }

    private func sampler(quality: String) throws -> VolumeRaySampler {
        try VolumeRaySampler(
            geometry: try geometry(),
            extents: [8, 8, 4],
            quality: quality,
            clip: nil,
            crop: nil
        )
    }

    // MARK: - A degraded quality is refused, not served

    @Test("[Unit][VOX-ERR-004] an unregistered quality policy is refused")
    func unregisteredQualityPolicyIsRefused() throws {
        // The row's core case. `VolumeRaySampler` admits exactly one registered quality
        // token, and anything else — including a plausibly-named preview or interactive
        // policy — is refused rather than sampled more coarsely under the same request.
        for requested in [
            "org.voxelia.quality.preview",
            "org.voxelia.quality.interactive",
            "org.voxelia.quality.reference",
            "preview",
            "",
        ] {
            #expect(throws: VolumeRaySamplingError.unsupportedQualityPolicy) {
                _ = try sampler(quality: requested)
            }
        }
    }

    @Test("[Unit][VOX-ERR-004] the registered quality policy is served")
    func registeredQualityPolicyIsServed() throws {
        // The positive control. Without it the refusals above are consistent with a
        // sampler that rejects every quality string it is given.
        _ = try sampler(quality: VolumeRaySampler.fullQualityToken)
    }

    @Test("[Unit][VOX-ERR-004] the accepted token is exact, not a prefix or family")
    func acceptedTokenIsExactNotAPrefix() throws {
        // A prefix or case-insensitive match would let a near-miss name select the
        // diagnostic path by accident, which is the same hazard from the other side.
        let token = VolumeRaySampler.fullQualityToken
        for nearMiss in [
            token + ".v2",
            token.uppercased(),
            String(token.dropLast()),
            " " + token,
        ] {
            #expect(throws: VolumeRaySamplingError.unsupportedQualityPolicy) {
                _ = try sampler(quality: nearMiss)
            }
        }
    }

    // MARK: - A diagnostic claim cannot be made without evidence

    @Test("[Unit][VOX-ERR-004] a diagnostic-ready claim requires evidence in the type")
    func diagnosticReadyClaimRequiresEvidenceInTheType() throws {
        // The other face of the row, and it is structural rather than checked: `preview`
        // takes no evidence and `diagnosticReady` cannot be constructed without a
        // `ValidationEvidenceID`. So a preview result cannot be relabelled as
        // diagnostic-ready by changing a case — there is nothing to change it to.
        let preview = ProvenanceValidationClaim.preview
        let evidence = try #require(
            ValidationEvidenceID(rawValue: "voxelia.evidence.example")
        )
        let ready = ProvenanceValidationClaim.diagnosticReady(evidence)

        #expect(preview != ready)
        switch preview {
        case .diagnosticReady: Issue.record("preview compared equal to a diagnostic claim")
        default: break
        }
        switch ready {
        case .diagnosticReady(let carried): #expect(carried == evidence)
        default: Issue.record("a diagnostic-ready claim lost its evidence")
        }
    }

    @Test("[Unit][VOX-ERR-004] claims carry no ordering that could promote preview")
    func claimsCarryNoOrderingThatCouldPromotePreview() {
        // `ADR-0057` states no ordering exists between claim cases. If the type were
        // `Comparable`, a caller could write `max(preview, diagnosticReady)` and select
        // the stronger claim arithmetically. It is not, and this asserts that.
        #expect(!(ProvenanceValidationClaim.self is any Comparable.Type))
        // The positive control: a type that *is* Comparable must be seen as such, or the
        // assertion above passes for a reason unrelated to the claim vocabulary.
        #expect(Int.self is any Comparable.Type)
    }

    // MARK: - The refusal is not a silent optional

    @Test("[Unit][VOX-ERR-004] the refusal throws rather than yielding a default")
    func refusalThrowsRatherThanYieldingADefault() throws {
        // An operation that returned an optional or a default-constructed sampler would
        // let a caller proceed with something that is not what it asked for. The
        // signature throws, so there is no value to proceed with.
        var constructed: VolumeRaySampler?
        do {
            constructed = try sampler(quality: "org.voxelia.quality.preview")
            Issue.record("an unsupported quality produced a sampler")
        } catch VolumeRaySamplingError.unsupportedQualityPolicy {
            #expect(constructed == nil)
        }
    }
}

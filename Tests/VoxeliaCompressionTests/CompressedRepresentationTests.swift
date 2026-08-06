// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaCompression

/// `ADR-0257` (`VOX-CMP-013`): a toolkit-native representation can never be
/// presented as a standard DICOM transfer syntax.
@Suite("CompressedRepresentation")
struct CompressedRepresentationTests {
    /// Identifiers that are UID-shaped, so admissible as standard and refused as
    /// toolkit names.
    private let uidShaped = [
        "1.2.840.10008.1.2.1",  // Explicit VR Little Endian
        "1.2.840.10008.1.2.4.90",  // JPEG 2000 lossless
        "1.2.840.10008.1.2.4.201",  // HTJ2K lossless
        "1.2",
        "0.0",
        "01.02",  // leading zeros: over-inclusive on purpose
        "1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16",
    ]

    /// Identifiers that are not UID-shaped, so admissible as toolkit names and
    /// refused as standard.
    private let notUIDShaped = [
        "jp3d",
        "raster-lab.jp3d.v1",
        "JP3D",
        "jp3d-cache-1.2",
        "1.2.840.10008.1.2.1 ",  // trailing space
        "1",  // single component
        "1.",  // empty trailing component
        ".1",  // empty leading component
        "1..2",  // empty interior component
        "1.2.x",
        "1_2",
        "",
    ]

    // MARK: - The shape predicate

    @Test("[Unit][VOX-CMP-013] the frozen UID shape test classifies both sets")
    func frozenUIDShapeTestClassifiesBothSets() {
        for identifier in uidShaped {
            #expect(DICOMUIDShape.isUIDShaped(identifier), "\(identifier)")
        }
        for identifier in notUIDShaped {
            #expect(!DICOMUIDShape.isUIDShaped(identifier), "\(identifier)")
        }
    }

    @Test("[Unit][VOX-CMP-013] the length limit is the DICOM one and it is enforced")
    func lengthLimitIsEnforced() {
        #expect(DICOMUIDShape.maximumLength == 64)
        // Exactly 64 characters of digits and separators is UID-shaped; 65 is not.
        let atLimit = "1." + String(repeating: "2", count: 62)
        #expect(atLimit.count == 64)
        #expect(DICOMUIDShape.isUIDShaped(atLimit))
        let overLimit = "1." + String(repeating: "2", count: 63)
        #expect(overLimit.count == 65)
        #expect(!DICOMUIDShape.isUIDShaped(overLimit))
    }

    // MARK: - Disjointness, the requirement itself

    @Test("[Unit][VOX-CMP-013] the two cases are disjoint over the same identifiers")
    func theTwoCasesAreDisjoint() throws {
        // The requirement made a theorem: one predicate gates both admissions in
        // opposite directions, so no identifier can be admitted as both. Asserted
        // over the same sets from both sides rather than argued.
        for identifier in uidShaped {
            // Admissible as standard...
            let standard = try CompressedRepresentation.standardTransferSyntax(
                declaredUID: identifier
            )
            #expect(standard.isStandardDICOMTransferSyntax)
            // ...and refused as a toolkit name.
            #expect(throws: CompressedRepresentationError.toolkitIdentifierIsUIDShaped) {
                try CompressedRepresentation.toolkit(name: identifier)
            }
        }

        for identifier in notUIDShaped where !identifier.isEmpty {
            // Admissible as a toolkit name...
            let toolkit = try CompressedRepresentation.toolkit(name: identifier)
            #expect(!toolkit.isStandardDICOMTransferSyntax)
            // ...and refused as a standard transfer syntax.
            #expect(
                throws: CompressedRepresentationError.standardIdentifierNotUIDShaped
            ) {
                try CompressedRepresentation.standardTransferSyntax(
                    declaredUID: identifier
                )
            }
        }
    }

    @Test("[Unit][VOX-CMP-013] a toolkit-native representation yields no transfer syntax UID")
    func toolkitNativeYieldsNoTransferSyntaxUID() throws {
        // The second half of the enforcement: a caller writing a DICOM header
        // cannot obtain a UID for a toolkit-native cache even by mistake, because
        // there is none to obtain.
        let toolkit = try CompressedRepresentation.toolkit(name: "raster-lab.jp3d.v1")
        #expect(toolkit.declaredTransferSyntaxUID == nil)
        #expect(!toolkit.isStandardDICOMTransferSyntax)

        // The standard case does yield one, so the nil above is a property of the
        // toolkit case rather than of the accessor.
        let standard = try CompressedRepresentation.standardTransferSyntax(
            declaredUID: "1.2.840.10008.1.2.4.90"
        )
        #expect(standard.declaredTransferSyntaxUID == "1.2.840.10008.1.2.4.90")
        #expect(standard.isStandardDICOMTransferSyntax)
    }

    @Test("[Unit][VOX-CMP-013] a JP3D name cannot be laundered into a UID")
    func jp3dNameCannotBeLaunderedIntoAUID() throws {
        // The concrete attack the requirement names: a toolkit-native JP3D cache
        // presented as an interoperable object. Every plausible attempt to give it
        // a UID-shaped name is refused.
        for attempt in [
            "1.2.840.10008.1.2.4.201",
            "1.2.826.0.1.3680043.9.7433",
            "1.2.3",
        ] {
            #expect(throws: CompressedRepresentationError.toolkitIdentifierIsUIDShaped) {
                try CompressedRepresentation.toolkit(name: attempt)
            }
        }
    }

    // MARK: - Admissions

    @Test("[Unit][VOX-CMP-013][VOX-ERR-001] empty identifiers reject typed on both sides")
    func emptyIdentifiersRejectTyped() {
        #expect(throws: CompressedRepresentationError.emptyIdentifier) {
            try CompressedRepresentation.standardTransferSyntax(declaredUID: "")
        }
        #expect(throws: CompressedRepresentationError.emptyIdentifier) {
            try CompressedRepresentation.toolkit(name: "")
        }
    }
}

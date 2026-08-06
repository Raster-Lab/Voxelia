// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while admitting a compressed payload.
///
/// Cases deliberately carry no payload, so a refused codestream never discloses
/// its length, its declared extents or any of its bytes in a diagnostic. A
/// malformed codestream is exactly the input where a chatty error is a hazard.
public enum CompressedPayloadError: Error, Sendable, Equatable {
    /// The codestream holds no bytes.
    case emptyCodestream
    /// A declared extent is not positive.
    case invalidDeclaredExtent
    /// No extent was declared.
    case missingDeclaredExtents
    /// The declared decoded byte count is not representable on this host.
    case declaredByteCountNotRepresentable
    /// The declared component count is not positive.
    case invalidDeclaredComponentCount
}

/// One compressed codestream and the decoded shape it *claims* to produce, per
/// `ADR-0256` (`VOX-CMP-002`, `VOX-CMP-007`).
///
/// ## This type is deliberately not sampleable
///
/// `VOX-CMP-007` requires that compressed data is never treated as directly
/// sampleable Metal texture data. That is enforced three ways, none of them a
/// comment asking the reader to be careful:
///
/// 1. **It does not conform to `ImageStorageContract`.** The accepted storage and
///    render paths consume that contract, so a compressed payload cannot be handed
///    to them in place of decoded samples. A test asserts the non-conformance, so
///    adding it later fails rather than passes quietly.
/// 2. **`VoxeliaCompression` may not import Metal**, enforced by
///    `check_prohibited_imports.py`, so this module cannot construct a texture at
///    all.
/// 3. **`VoxeliaMetal` may not import `VoxeliaCompression`**, enforced by the same
///    tool, so the module that *can* build textures cannot even name this type.
///
/// `ADR-0196` found a case where a record claimed independence that no tooling
/// enforced. That lesson is applied here in advance rather than after an audit.
///
/// ## The declared shape is a claim, not a guarantee
///
/// `declaredExtents` and `declaredScalarFormat` are what the *source* says the
/// codestream decodes to. Nothing here verifies that, because verifying it
/// requires decoding, which requires a codec. Checking a decode against these
/// declarations is `VOX-CMP-010`'s job, and the naming reflects the difference:
/// every field says `declared`.
///
/// ## No format identifier, deliberately
///
/// This type names **no codec, transfer syntax or container format**.
/// `VOX-CMP-013` requires that a toolkit-native representation is never
/// represented as a standard DICOM transfer syntax, and getting that distinction
/// right is its own increment. A format field added here would have to be either
/// a bare string — which is exactly how a toolkit-native cache gets mislabelled as
/// an interoperable one — or a vocabulary this increment has no rule to constrain.
public struct CompressedPayload: Sendable, Hashable {
    /// The codestream's bytes, uninterpreted.
    public let codestream: ContiguousArray<UInt8>

    /// The extents the source claims this codestream decodes to, in image-axis
    /// order.
    public let declaredExtents: ContiguousArray<Int>

    /// The scalar format the source claims the decoded samples carry.
    public let declaredScalarFormat: ScalarFormat

    /// The number of components per sample the source claims.
    ///
    /// Carried because `VOX-CMP-010` validates "component formats" and not only
    /// dimensions: a codec returning three components where one was declared is a
    /// disagreement the byte count alone can miss when extents differ to
    /// compensate.
    public let declaredComponentCount: Int

    /// The decoded byte count implied by the declarations.
    ///
    /// Computed at admission rather than stored as a separate claim, so it cannot
    /// disagree with the extents and format it is derived from.
    public let declaredDecodedByteCount: Int

    /// Creates an admitted payload.
    ///
    /// The admissions here are the payload's **own** consistency, not a
    /// validation of the codestream: an empty codestream, a non-positive extent,
    /// no extents at all, or a decoded byte count that overflows the host.
    /// Whether the codestream actually decodes to this shape is unknowable
    /// without a codec and belongs to `VOX-CMP-010`.
    ///
    /// - Throws: ``CompressedPayloadError``.
    public init(
        codestream: ContiguousArray<UInt8>,
        declaredExtents: ContiguousArray<Int>,
        declaredScalarFormat: ScalarFormat,
        declaredComponentCount: Int
    ) throws {
        guard !codestream.isEmpty else {
            throw CompressedPayloadError.emptyCodestream
        }
        guard !declaredExtents.isEmpty else {
            throw CompressedPayloadError.missingDeclaredExtents
        }
        guard declaredExtents.allSatisfy({ $0 >= 1 }) else {
            throw CompressedPayloadError.invalidDeclaredExtent
        }
        guard declaredComponentCount >= 1 else {
            throw CompressedPayloadError.invalidDeclaredComponentCount
        }

        // Checked throughout: a hostile or corrupt source can declare extents
        // whose product overflows, and this is the one place that product is
        // formed. It is checked rather than argued, following `ADR-0235`
        // decision 5's reasoning about where being wrong is unrecoverable.
        var sampleCount = 1
        for extent in declaredExtents {
            let (product, overflowed) = sampleCount.multipliedReportingOverflow(
                by: extent
            )
            guard !overflowed else {
                throw CompressedPayloadError.declaredByteCountNotRepresentable
            }
            sampleCount = product
        }
        let (componentCount, componentOverflow) =
            sampleCount.multipliedReportingOverflow(by: declaredComponentCount)
        guard !componentOverflow else {
            throw CompressedPayloadError.declaredByteCountNotRepresentable
        }
        let (byteCount, byteOverflow) = componentCount.multipliedReportingOverflow(
            by: declaredScalarFormat.type.byteCount
        )
        guard !byteOverflow else {
            throw CompressedPayloadError.declaredByteCountNotRepresentable
        }

        self.codestream = codestream
        self.declaredExtents = declaredExtents
        self.declaredScalarFormat = declaredScalarFormat
        self.declaredComponentCount = declaredComponentCount
        self.declaredDecodedByteCount = byteCount
    }

    /// The codestream's byte count.
    public var codestreamByteCount: Int { codestream.count }

    /// The ratio of declared decoded bytes to codestream bytes.
    ///
    /// Reported as a plain `Double` for a caller's own accounting. It is **not** a
    /// compression-ratio measurement under `VOX-CMP-014`: that row requires a
    /// benchmark over real codec output, which `ADR-0255` records as blocked.
    public var declaredExpansionRatio: Double {
        Double(declaredDecodedByteCount) / Double(codestream.count)
    }
}

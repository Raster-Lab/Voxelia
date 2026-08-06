// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaSpatial

/// The photometric interpretation a CT source declared for a frame.
///
/// This is a record of what the source stated, not a display decision. The
/// mapping onto a presentation polarity is already fixed by `ADR-0112`
/// — `monochrome2` presents with standard polarity and `monochrome1`
/// inverted — and is applied at the rendering boundary. `ADR-0227` keeps the
/// source fact separate from the decision so the evidence for the decision
/// survives ingest, and because `PresentationPolarity` lives in a module that
/// depends on this one.
public enum MonochromeInterpretation: String, Sendable, Codable, Hashable, CaseIterable {
    /// Low stored values present as white.
    case monochrome1
    /// Low stored values present as black.
    case monochrome2
}

/// A declared pixel-padding value for one frame.
///
/// Only the single-value form is represented. DICOM's padding *range* form is
/// deliberately not modelled, because `VOX-DCM-008` scopes this to the padding
/// information the first vertical slice requires and the accepted consumer of
/// that information takes a single value. `ADR-0227` records the omission.
///
/// The descriptor does not validate itself: whether the value is representable
/// depends on the frame's declared scalar format, which lives in
/// ``CTFrameDescription``, and the rule is applied there rather than in two
/// places.
public struct PixelPaddingDescriptor: Sendable, Hashable, Codable {
    /// The stored value that denotes padding rather than measured signal.
    public let value: Int64

    /// Creates a descriptor for one stored padding value.
    public init(value: Int64) {
        self.value = value
    }
}

/// An error raised while admitting a ``CTFrameDescription``.
///
/// Cases deliberately carry no payload, so a rejected description never
/// discloses source geometry, identifiers or metadata in a diagnostic.
public enum CTFrameDescriptionError: Error, Sendable, Equatable {
    case nonPositiveRowCount
    case nonPositiveColumnCount
    case sampleCountOverflow
    case rowSpacingNotPositiveFinite
    case columnSpacingNotPositiveFinite
    case zeroRowDirection
    case zeroColumnDirection
    case coordinateSpaceMismatch
    case rescaleSlopeNotFinite
    case rescaleInterceptNotFinite
    case pixelPaddingNotRepresentable
}

/// One neutral CT frame description per `ADR-0227`.
///
/// The description names no DICOMKit type and parses nothing. It is a faithful
/// transcription of what a source stated about a single frame, and admits
/// exactly what makes that transcription representable and arithmetically
/// safe. It deliberately makes **no judgement** about whether the geometry is
/// usable: a frame whose direction cosines are far from orthogonal is a valid
/// description and a rejected series, so that the series validator can name the
/// frame it rejected rather than failing to construct its subject.
///
/// ## Axis convention
///
/// The pairing of directions and spacings is fixed by index rather than by the
/// words row and column alone, because reading it backwards transposes a volume
/// silently:
///
/// - ``rowDirection`` is the direction in which the **column index** increases,
///   along a row.
/// - ``columnDirection`` is the direction in which the **row index** increases,
///   down a column.
/// - ``rowSpacingMillimetres`` is the centre-to-centre distance between
///   adjacent **rows**: the step taken along ``columnDirection`` when the row
///   index increases by one.
/// - ``columnSpacingMillimetres`` is the centre-to-centre distance between
///   adjacent **columns**: the step along ``rowDirection``.
///
/// This matches DICOM's own ordering, but the convention above — not that
/// correspondence — is what this type means. An adapter is responsible for
/// satisfying it.
///
/// Decoded samples are not carried here. Series grouping and geometry
/// validation read only the description, and sample ownership is settled with
/// the adapter that answers it.
public struct CTFrameDescription: Sendable, Hashable {
    /// Where the frame came from in the source system.
    public let sourceIdentity: SourceIdentity
    /// Which series the source says the frame belongs to.
    ///
    /// Added by `ADR-0228` after increment (b) found that increment (a) could
    /// not express it: ``sourceIdentity`` is per-frame by construction, and a
    /// frame of reference is shared across every series in a study acquired
    /// without moving the patient, so neither separates two co-located
    /// acquisitions — and no geometric rule ever can, because occupying the
    /// same space is precisely what they do.
    public let seriesIdentity: SourceIdentity
    /// The number of rows in the sampling grid, at least one.
    public let rows: Int
    /// The number of columns in the sampling grid, at least one.
    public let columns: Int
    /// The declared storage format of the frame's samples.
    public let scalarFormat: ScalarFormat
    /// The photometric interpretation the source declared.
    public let photometricInterpretation: MonochromeInterpretation
    /// Centre-to-centre spacing between adjacent rows, in millimetres.
    public let rowSpacingMillimetres: Double
    /// Centre-to-centre spacing between adjacent columns, in millimetres.
    public let columnSpacingMillimetres: Double
    /// The direction of increasing column index.
    public let rowDirection: Vector3D
    /// The direction of increasing row index.
    public let columnDirection: Vector3D
    /// The position of the centre of the first sample.
    public let imagePosition: Point3D
    /// The source's frame-of-reference claim, when it stated one.
    public let frameOfReference: ExternalFrameReference?
    /// The declared rescale slope.
    public let rescaleSlope: Double
    /// The declared rescale intercept.
    public let rescaleIntercept: Double
    /// The declared pixel padding, when the source stated one.
    public let pixelPadding: PixelPaddingDescriptor?
    /// Preserved source metadata in exact input order.
    public let sourceMetadata: MetadataCollection

    /// The total number of samples in the frame.
    ///
    /// Admission guarantees this product does not overflow.
    public var sampleCount: Int { rows * columns }

    /// The coordinate space shared by the position and both directions.
    public var coordinateSpace: CoordinateSpaceID { imagePosition.coordinateSpace }

    /// Creates a description after applying every admission rule in the fixed
    /// order below.
    ///
    /// A zero ``rescaleSlope`` is **admitted**: it is representable and
    /// arithmetically safe, so refusing it would be a judgement about
    /// usefulness rather than about representability. `ADR-0227` assigns that
    /// judgement to the value-transformation stage instead.
    ///
    /// - Throws: ``CTFrameDescriptionError/nonPositiveRowCount`` or
    ///   ``CTFrameDescriptionError/nonPositiveColumnCount`` when an extent is
    ///   below one; ``CTFrameDescriptionError/sampleCountOverflow`` when the
    ///   extents cannot be multiplied;
    ///   ``CTFrameDescriptionError/rowSpacingNotPositiveFinite`` or
    ///   ``CTFrameDescriptionError/columnSpacingNotPositiveFinite`` when a
    ///   spacing is not a finite value greater than zero;
    ///   ``CTFrameDescriptionError/zeroRowDirection`` or
    ///   ``CTFrameDescriptionError/zeroColumnDirection`` when every component
    ///   of a direction is exactly zero;
    ///   ``CTFrameDescriptionError/coordinateSpaceMismatch`` when the position
    ///   and the two directions do not share one space;
    ///   ``CTFrameDescriptionError/rescaleSlopeNotFinite`` or
    ///   ``CTFrameDescriptionError/rescaleInterceptNotFinite`` for a non-finite
    ///   rescale term; and
    ///   ``CTFrameDescriptionError/pixelPaddingNotRepresentable`` when a stated
    ///   padding value does not fit the declared scalar format.
    public init(
        sourceIdentity: SourceIdentity,
        seriesIdentity: SourceIdentity,
        rows: Int,
        columns: Int,
        scalarFormat: ScalarFormat,
        photometricInterpretation: MonochromeInterpretation,
        rowSpacingMillimetres: Double,
        columnSpacingMillimetres: Double,
        rowDirection: Vector3D,
        columnDirection: Vector3D,
        imagePosition: Point3D,
        frameOfReference: ExternalFrameReference?,
        rescaleSlope: Double,
        rescaleIntercept: Double,
        pixelPadding: PixelPaddingDescriptor?,
        sourceMetadata: MetadataCollection
    ) throws {
        guard rows >= 1 else { throw CTFrameDescriptionError.nonPositiveRowCount }
        guard columns >= 1 else { throw CTFrameDescriptionError.nonPositiveColumnCount }

        // Every later increment multiplies the extents. Admitting a pair that
        // cannot be multiplied would lay a trap in a value whose purpose is to
        // be trusted downstream.
        let product = rows.multipliedReportingOverflow(by: columns)
        guard !product.overflow else { throw CTFrameDescriptionError.sampleCountOverflow }

        // Finiteness is checked with positivity rather than after it, because
        // infinity satisfies a bare `> 0`.
        guard rowSpacingMillimetres.isFinite, rowSpacingMillimetres > 0 else {
            throw CTFrameDescriptionError.rowSpacingNotPositiveFinite
        }
        guard columnSpacingMillimetres.isFinite, columnSpacingMillimetres > 0 else {
            throw CTFrameDescriptionError.columnSpacingNotPositiveFinite
        }

        // Tested componentwise against exact zero. Computing a magnitude would
        // introduce squaring, underflow and a threshold to argue about.
        guard Self.isNonZero(rowDirection) else {
            throw CTFrameDescriptionError.zeroRowDirection
        }
        guard Self.isNonZero(columnDirection) else {
            throw CTFrameDescriptionError.zeroColumnDirection
        }

        // Exact equality within one frame, where mixed spaces describe nothing
        // coherent. Whether different frames share a space is not decided here.
        let space = imagePosition.coordinateSpace
        guard rowDirection.coordinateSpace == space,
            columnDirection.coordinateSpace == space
        else {
            throw CTFrameDescriptionError.coordinateSpaceMismatch
        }

        guard rescaleSlope.isFinite else {
            throw CTFrameDescriptionError.rescaleSlopeNotFinite
        }
        guard rescaleIntercept.isFinite else {
            throw CTFrameDescriptionError.rescaleInterceptNotFinite
        }

        if let pixelPadding,
            !Self.isRepresentable(pixelPadding.value, in: scalarFormat)
        {
            throw CTFrameDescriptionError.pixelPaddingNotRepresentable
        }

        self.sourceIdentity = sourceIdentity
        self.seriesIdentity = seriesIdentity
        self.rows = rows
        self.columns = columns
        self.scalarFormat = scalarFormat
        self.photometricInterpretation = photometricInterpretation
        self.rowSpacingMillimetres = rowSpacingMillimetres
        self.columnSpacingMillimetres = columnSpacingMillimetres
        self.rowDirection = rowDirection
        self.columnDirection = columnDirection
        self.imagePosition = imagePosition
        self.frameOfReference = frameOfReference
        self.rescaleSlope = rescaleSlope
        self.rescaleIntercept = rescaleIntercept
        self.pixelPadding = pixelPadding
        self.sourceMetadata = sourceMetadata
    }

    /// Whether any component of `vector` differs from exact zero.
    ///
    /// `Vector3D` already rejects non-finite components, and canonicalises
    /// signed zero, so this is a plain three-way comparison.
    private static func isNonZero(_ vector: Vector3D) -> Bool {
        vector.x != 0 || vector.y != 0 || vector.z != 0
    }

    /// Whether `value` fits the declared container of `format`.
    ///
    /// The container's full range is used. `ScalarType.validValueRange` is
    /// explicitly not narrowed by `ScalarFormat.validBitCount`, because the
    /// placement of unused bits belongs to source decoding metadata rather than
    /// to the scalar descriptor.
    private static func isRepresentable(_ value: Int64, in format: ScalarFormat) -> Bool {
        switch format.type.validValueRange {
        case .signedInteger(let range):
            range.contains(value)
        case .unsignedInteger(let range):
            value >= 0 && range.contains(UInt64(value))
        case .floatingPoint(let range):
            // An `Int64` beyond the significand's exact range is not
            // representable even when it falls inside the format's magnitude
            // range, so exactness is required before containment.
            if let exact = Double(exactly: value) {
                range.contains(exact)
            } else {
                false
            }
        }
    }
}

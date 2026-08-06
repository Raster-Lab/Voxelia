// SPDX-License-Identifier: MIT

import DICOMCore
import DICOMKit
import Foundation
import VoxeliaCore
import VoxeliaImaging
import VoxeliaSpatial

/// An error raised while translating a DICOM data set into a neutral frame
/// description.
///
/// Cases deliberately carry no payload, so a rejected data set never discloses
/// patient geometry, identifiers or metadata in a diagnostic. Each case names a
/// **missing or unusable attribute**, never a value.
public enum DICOMFrameAdapterError: Error, Sendable, Equatable {
    case missingSOPInstanceUID
    case missingSeriesInstanceUID
    case missingRows
    case missingColumns
    case missingPixelSpacing
    /// Pixel Spacing was present without exactly two values.
    case malformedPixelSpacing
    case missingImageOrientationPatient
    /// Image Orientation (Patient) was present without exactly six values.
    case malformedImageOrientationPatient
    case missingImagePositionPatient
    /// Image Position (Patient) was present without exactly three values.
    case malformedImagePositionPatient
    case missingPhotometricInterpretation
    /// The photometric interpretation was neither MONOCHROME1 nor MONOCHROME2.
    ///
    /// `VOX-DCM-008` scopes the first vertical slice to the monochrome
    /// interpretations; a colour interpretation is refused rather than silently
    /// treated as greyscale.
    case unsupportedPhotometricInterpretation
    case missingBitsAllocated
    case missingPixelRepresentation
    /// The allocated bit count and pixel representation do not name a scalar
    /// format this adapter translates.
    case unsupportedSampleFormat
    /// A value the accepted Voxelia types refused.
    ///
    /// The underlying admission is not surfaced, because it would name geometry.
    case rejectedByVoxeliaAdmission
}

/// The DICOM attribute tags this adapter reads.
///
/// Spelled out rather than taken from `DICOMDictionary`, so that the exact set of
/// attributes this adapter depends on is visible in one place and a dictionary
/// change cannot silently alter which attribute is read.
private enum FrameTag {
    static let sopInstanceUID = Tag(group: 0x0008, element: 0x0018)
    static let seriesInstanceUID = Tag(group: 0x0020, element: 0x000E)
    static let frameOfReferenceUID = Tag(group: 0x0020, element: 0x0052)
    static let imagePositionPatient = Tag(group: 0x0020, element: 0x0032)
    static let imageOrientationPatient = Tag(group: 0x0020, element: 0x0037)
    static let photometricInterpretation = Tag(group: 0x0028, element: 0x0004)
    static let rows = Tag(group: 0x0028, element: 0x0010)
    static let columns = Tag(group: 0x0028, element: 0x0011)
    static let pixelSpacing = Tag(group: 0x0028, element: 0x0030)
    static let bitsAllocated = Tag(group: 0x0028, element: 0x0100)
    static let bitsStored = Tag(group: 0x0028, element: 0x0101)
    static let pixelRepresentation = Tag(group: 0x0028, element: 0x0103)
    static let pixelPaddingValue = Tag(group: 0x0028, element: 0x0120)
    static let rescaleIntercept = Tag(group: 0x0028, element: 0x1052)
    static let rescaleSlope = Tag(group: 0x0028, element: 0x1053)
}

/// Translates a DICOMKit `DataSet` into Voxelia's neutral `CTFrameDescription`.
///
/// This is the whole of Voxelia's DICOMKit-facing surface. It parses nothing —
/// `VOX-DCM-001` forbids a second general DICOM parser, so DICOMKit owns parsing
/// and this type owns only the translation into canonical Voxelia values, per
/// `VOX-DCM-003`.
///
/// ## The axis convention
///
/// DICOM's Image Orientation (Patient) supplies the row direction first and then
/// the column direction; Pixel Spacing supplies row spacing first. `ADR-0227`
/// fixes what those mean in Voxelia terms — `rowDirection` is the direction of
/// increasing **column** index — and this adapter is the component `ADR-0227`
/// made responsible for satisfying that convention. The mapping is therefore
/// direct: DICOM's first orientation triple becomes `rowDirection`, and DICOM's
/// first spacing becomes `rowSpacingMillimetres`.
public enum DICOMFrameAdapter {
    /// Translates one data set into a neutral frame description.
    ///
    /// - Parameters:
    ///   - dataSet: a data set DICOMKit has already parsed.
    ///   - coordinateSpace: the space the patient-coordinate values are
    ///     expressed in. Supplied by the caller because the neutral description
    ///     carries a space tag and DICOM does not name one.
    /// - Throws: ``DICOMFrameAdapterError``.
    public static func frameDescription(
        from dataSet: DataSet,
        coordinateSpace: CoordinateSpaceID
    ) throws -> CTFrameDescription {
        guard let sopInstanceUID = dataSet.string(for: FrameTag.sopInstanceUID),
            !sopInstanceUID.isEmpty
        else {
            throw DICOMFrameAdapterError.missingSOPInstanceUID
        }
        guard let seriesInstanceUID = dataSet.string(for: FrameTag.seriesInstanceUID),
            !seriesInstanceUID.isEmpty
        else {
            throw DICOMFrameAdapterError.missingSeriesInstanceUID
        }
        guard let rows = dataSet.uint16(for: FrameTag.rows) else {
            throw DICOMFrameAdapterError.missingRows
        }
        guard let columns = dataSet.uint16(for: FrameTag.columns) else {
            throw DICOMFrameAdapterError.missingColumns
        }

        guard let spacing = dataSet.decimalStrings(for: FrameTag.pixelSpacing) else {
            throw DICOMFrameAdapterError.missingPixelSpacing
        }
        guard spacing.count == 2 else {
            throw DICOMFrameAdapterError.malformedPixelSpacing
        }

        guard
            let orientation = dataSet.decimalStrings(
                for: FrameTag.imageOrientationPatient
            )
        else {
            throw DICOMFrameAdapterError.missingImageOrientationPatient
        }
        guard orientation.count == 6 else {
            throw DICOMFrameAdapterError.malformedImageOrientationPatient
        }

        guard
            let position = dataSet.decimalStrings(for: FrameTag.imagePositionPatient)
        else {
            throw DICOMFrameAdapterError.missingImagePositionPatient
        }
        guard position.count == 3 else {
            throw DICOMFrameAdapterError.malformedImagePositionPatient
        }

        let interpretation = try monochromeInterpretation(dataSet)
        let scalarFormat = try scalarFormat(dataSet)

        // Rescale terms are optional in DICOM. Their absence means the identity
        // transform, which is a documented DICOM default rather than a guess.
        let slope = dataSet.decimalString(for: FrameTag.rescaleSlope)?.value ?? 1.0
        let intercept =
            dataSet.decimalString(for: FrameTag.rescaleIntercept)?.value ?? 0.0

        let padding = paddingDescriptor(
            dataSet,
            signedSamples: scalarFormat.type.isSignedInteger
        )
        let frameOfReference = try frameOfReferenceReference(dataSet)

        do {
            return try CTFrameDescription(
                sourceIdentity: try SourceIdentity(
                    namespace: "dicom",
                    identifier: sopInstanceUID,
                    version: nil,
                    contentID: nil
                ),
                seriesIdentity: try SourceIdentity(
                    namespace: "dicom",
                    identifier: seriesInstanceUID,
                    version: nil,
                    contentID: nil
                ),
                rows: Int(rows),
                columns: Int(columns),
                scalarFormat: scalarFormat,
                photometricInterpretation: interpretation,
                // DICOM Pixel Spacing is [row spacing, column spacing], and
                // ADR-0227 uses the same naming, so this is a direct mapping.
                rowSpacingMillimetres: spacing[0].value,
                columnSpacingMillimetres: spacing[1].value,
                // Image Orientation (Patient) is the row direction first.
                rowDirection: try Vector3D(
                    x: orientation[0].value,
                    y: orientation[1].value,
                    z: orientation[2].value,
                    coordinateSpace: coordinateSpace
                ),
                columnDirection: try Vector3D(
                    x: orientation[3].value,
                    y: orientation[4].value,
                    z: orientation[5].value,
                    coordinateSpace: coordinateSpace
                ),
                imagePosition: try Point3D(
                    x: position[0].value,
                    y: position[1].value,
                    z: position[2].value,
                    coordinateSpace: coordinateSpace
                ),
                frameOfReference: frameOfReference,
                rescaleSlope: slope,
                rescaleIntercept: intercept,
                pixelPadding: padding,
                sourceMetadata: try MetadataCollection(entries: [])
            )
        } catch {
            // Every accepted Voxelia admission collapses to one case here, so a
            // diagnostic cannot leak the value that was refused.
            throw DICOMFrameAdapterError.rejectedByVoxeliaAdmission
        }
    }

    // MARK: - Attribute translation

    private static func monochromeInterpretation(
        _ dataSet: DataSet
    ) throws -> MonochromeInterpretation {
        guard let raw = dataSet.string(for: FrameTag.photometricInterpretation) else {
            throw DICOMFrameAdapterError.missingPhotometricInterpretation
        }
        // DICOM Code Strings are padded with trailing spaces and are defined
        // uppercase, so trailing whitespace is trimmed and nothing else.
        switch raw.trimmingCharacters(in: .whitespaces) {
        case "MONOCHROME1":
            return .monochrome1
        case "MONOCHROME2":
            return .monochrome2
        default:
            throw DICOMFrameAdapterError.unsupportedPhotometricInterpretation
        }
    }

    private static func scalarFormat(_ dataSet: DataSet) throws -> ScalarFormat {
        guard let bitsAllocated = dataSet.uint16(for: FrameTag.bitsAllocated) else {
            throw DICOMFrameAdapterError.missingBitsAllocated
        }
        guard
            let pixelRepresentation = dataSet.uint16(for: FrameTag.pixelRepresentation)
        else {
            throw DICOMFrameAdapterError.missingPixelRepresentation
        }

        // VOX-DCM-005 scopes the first vertical slice to signed and unsigned
        // sixteen-bit CT samples. Eight-bit is admitted alongside because the
        // translation is identical and refusing it would be an invented limit;
        // anything else is refused rather than approximated.
        let type: ScalarType
        switch (bitsAllocated, pixelRepresentation) {
        case (8, 0): type = .uint8
        case (8, 1): type = .int8
        case (16, 0): type = .uint16
        case (16, 1): type = .int16
        default:
            throw DICOMFrameAdapterError.unsupportedSampleFormat
        }

        // Bits Stored, when present and narrower, is the meaningful bit count.
        let bitsStored = dataSet.uint16(for: FrameTag.bitsStored).map(Int.init)
        let validBitCount = bitsStored.flatMap {
            (1...type.bitCount).contains($0) && $0 != type.bitCount ? $0 : nil
        }

        do {
            return try ScalarFormat(
                type: type,
                validBitCount: validBitCount,
                byteOrder: .littleEndian
            )
        } catch {
            throw DICOMFrameAdapterError.unsupportedSampleFormat
        }
    }

    /// Reads Pixel Padding Value under the interpretation Pixel Representation
    /// selects.
    ///
    /// DICOM defines this attribute as US **or** SS according to Pixel
    /// Representation, and the choice is not optional: the same two bytes read
    /// the wrong way turn a signed `-2000` into `63536`, which is then refused as
    /// unrepresentable in a signed sixteen-bit format. Trying one reading and
    /// falling back to the other passes for every non-negative value and fails
    /// for exactly the negative ones real CT padding uses.
    private static func paddingDescriptor(
        _ dataSet: DataSet,
        signedSamples: Bool
    ) -> PixelPaddingDescriptor? {
        if signedSamples {
            return dataSet.int16(for: FrameTag.pixelPaddingValue)
                .map { PixelPaddingDescriptor(value: Int64($0)) }
        }
        return dataSet.uint16(for: FrameTag.pixelPaddingValue)
            .map { PixelPaddingDescriptor(value: Int64($0)) }
    }

    private static func frameOfReferenceReference(
        _ dataSet: DataSet
    ) throws -> ExternalFrameReference? {
        guard let uid = dataSet.string(for: FrameTag.frameOfReferenceUID),
            !uid.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            // Absent is a legitimate DICOM state, and ADR-0228 makes absent
            // distinct from every present value rather than a wildcard.
            return nil
        }
        do {
            return try ExternalFrameReference(namespace: "dicom", identifier: uid)
        } catch {
            throw DICOMFrameAdapterError.rejectedByVoxeliaAdmission
        }
    }
}

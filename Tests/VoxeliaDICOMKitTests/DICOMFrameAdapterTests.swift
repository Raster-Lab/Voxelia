// SPDX-License-Identifier: MIT

import DICOMCore
import DICOMKit
import Foundation
import Testing
import VoxeliaCore
import VoxeliaImaging
import VoxeliaSpatial

@testable import VoxeliaDICOMKit

/// Verifies the DICOMKit-facing translation.
///
/// Data sets are built element by element from real value representations rather
/// than through a fixture file, so each test states exactly which attributes it
/// supplies and a missing-attribute case is a genuine absence rather than a
/// parser quirk.
@Suite("DICOMFrameAdapter")
struct DICOMFrameAdapterTests {
    private func space() throws -> CoordinateSpaceID {
        try #require(CoordinateSpaceID(rawValue: "patient"))
    }

    private func text(_ tag: DICOMCore.Tag, _ vr: VR, _ value: String) -> DataElement {
        // DICOM string values are padded to an even length.
        let padded = value.utf8.count % 2 == 0 ? value : value + " "
        let data = Data(padded.utf8)
        return DataElement(
            tag: tag,
            vr: vr,
            length: UInt32(data.count),
            valueData: data
        )
    }

    /// Two explicit little-endian bytes.
    ///
    /// Written as shifts rather than a pointer view of the value's storage: the encoding
    /// is then stated here instead of delegated to memory layout, and the package stays
    /// clean under `-strict-memory-safety`, which `ADR-0287` measured.
    private static func littleEndianPair(_ value: UInt16) -> Data {
        Data([
            UInt8(truncatingIfNeeded: value),
            UInt8(truncatingIfNeeded: value >> 8),
        ])
    }

    private func unsigned16(_ tag: DICOMCore.Tag, _ value: UInt16) -> DataElement {
        DataElement(
            tag: tag, vr: .US, length: 2, valueData: Self.littleEndianPair(value))
    }

    private func signed16(_ tag: DICOMCore.Tag, _ value: Int16) -> DataElement {
        DataElement(
            tag: tag,
            vr: .SS,
            length: 2,
            valueData: Self.littleEndianPair(UInt16(bitPattern: value))
        )
    }

    /// A complete, admissible CT frame data set.
    private func elements(
        rows: UInt16 = 512,
        columns: UInt16 = 512,
        pixelSpacing: String = "0.7\\0.8",
        orientation: String = "1\\0\\0\\0\\1\\0",
        position: String = "-175.5\\-175.5\\42.0",
        photometric: String = "MONOCHROME2",
        bitsAllocated: UInt16 = 16,
        bitsStored: UInt16? = 12,
        pixelRepresentation: UInt16 = 1,
        rescaleSlope: String? = "1.0",
        rescaleIntercept: String? = "-1024.0",
        frameOfReferenceUID: String? = "1.2.840.frame.1",
        seriesUID: String? = "1.2.840.series.A",
        sopUID: String? = "1.2.840.instance.1",
        paddingValue: Int16? = nil
    ) -> [DataElement] {
        var result: [DataElement] = []
        if let sopUID {
            result.append(text(DICOMCore.Tag(group: 0x0008, element: 0x0018), .UI, sopUID))
        }
        if let seriesUID {
            result.append(text(DICOMCore.Tag(group: 0x0020, element: 0x000E), .UI, seriesUID))
        }
        if let frameOfReferenceUID {
            result.append(
                text(DICOMCore.Tag(group: 0x0020, element: 0x0052), .UI, frameOfReferenceUID)
            )
        }
        result.append(text(DICOMCore.Tag(group: 0x0020, element: 0x0032), .DS, position))
        result.append(text(DICOMCore.Tag(group: 0x0020, element: 0x0037), .DS, orientation))
        result.append(text(DICOMCore.Tag(group: 0x0028, element: 0x0004), .CS, photometric))
        result.append(unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0010), rows))
        result.append(unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0011), columns))
        result.append(text(DICOMCore.Tag(group: 0x0028, element: 0x0030), .DS, pixelSpacing))
        result.append(unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0100), bitsAllocated))
        if let bitsStored {
            result.append(unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0101), bitsStored))
        }
        result.append(
            unsigned16(DICOMCore.Tag(group: 0x0028, element: 0x0103), pixelRepresentation)
        )
        if let paddingValue {
            result.append(signed16(DICOMCore.Tag(group: 0x0028, element: 0x0120), paddingValue))
        }
        if let rescaleIntercept {
            result.append(
                text(DICOMCore.Tag(group: 0x0028, element: 0x1052), .DS, rescaleIntercept)
            )
        }
        if let rescaleSlope {
            result.append(text(DICOMCore.Tag(group: 0x0028, element: 0x1053), .DS, rescaleSlope))
        }
        return result
    }

    private func translate(_ elements: [DataElement]) throws -> CTFrameDescription {
        try DICOMFrameAdapter.frameDescription(
            from: DataSet(elements: elements),
            coordinateSpace: try space()
        )
    }

    // MARK: - The complete translation

    @Test("[Unit] A complete CT data set translates to every neutral field")
    func translatesCompleteDataSet() throws {
        let frame = try translate(elements(paddingValue: -2000))

        #expect(frame.sourceIdentity.namespace == "dicom")
        #expect(frame.sourceIdentity.identifier == "1.2.840.instance.1")
        #expect(frame.seriesIdentity.identifier == "1.2.840.series.A")
        #expect(frame.rows == 512)
        #expect(frame.columns == 512)
        #expect(frame.scalarFormat.type == .int16)
        #expect(frame.scalarFormat.validBitCount == 12)
        #expect(frame.photometricInterpretation == .monochrome2)
        #expect(frame.rescaleSlope == 1.0)
        #expect(frame.rescaleIntercept == -1024.0)
        #expect(frame.pixelPadding == PixelPaddingDescriptor(value: -2000))
        #expect(frame.frameOfReference?.identifier == "1.2.840.frame.1")
        #expect(frame.coordinateSpace == (try space()))
    }

    // MARK: - The axis convention, which ADR-0227 made this adapter own

    @Test("[Unit] DICOM Pixel Spacing maps row-first, and orientation row-direction-first")
    func axisConventionIsSatisfied() throws {
        // Distinct spacings and a distinguishable orientation, so a swap in
        // either pair changes an asserted value.
        let frame = try translate(
            elements(pixelSpacing: "0.7\\0.8", orientation: "1\\0\\0\\0\\1\\0")
        )

        // DICOM's first spacing is row spacing; ADR-0227 uses the same naming.
        #expect(frame.rowSpacingMillimetres == 0.7)
        #expect(frame.columnSpacingMillimetres == 0.8)
        // DICOM's first orientation triple is the row direction.
        #expect(frame.rowDirection.x == 1)
        #expect(frame.rowDirection.y == 0)
        #expect(frame.columnDirection.x == 0)
        #expect(frame.columnDirection.y == 1)
    }

    @Test("[Unit] An oblique orientation carries all six components in order")
    func obliqueOrientation() throws {
        let frame = try translate(
            elements(orientation: "0\\1\\0\\0\\0\\1", position: "1.0\\2.0\\3.0")
        )

        #expect(frame.rowDirection.y == 1)
        #expect(frame.columnDirection.z == 1)
        #expect(frame.imagePosition.x == 1.0)
        #expect(frame.imagePosition.y == 2.0)
        #expect(frame.imagePosition.z == 3.0)
    }

    // MARK: - Photometric interpretation

    @Test(
        "[Unit] Both monochrome interpretations translate, and trailing padding is trimmed",
        arguments: [
            ("MONOCHROME1", MonochromeInterpretation.monochrome1),
            ("MONOCHROME2", MonochromeInterpretation.monochrome2),
            ("MONOCHROME1 ", MonochromeInterpretation.monochrome1),
        ]
    )
    func monochromeInterpretations(
        _ raw: String,
        _ expected: MonochromeInterpretation
    ) throws {
        let frame = try translate(elements(photometric: raw))
        #expect(frame.photometricInterpretation == expected)
    }

    @Test("[Unit] A colour interpretation is refused rather than treated as greyscale")
    func colourInterpretationRefused() throws {
        #expect(throws: DICOMFrameAdapterError.unsupportedPhotometricInterpretation) {
            try translate(elements(photometric: "RGB"))
        }
    }

    // MARK: - Sample format

    @Test(
        "[Unit] Bits allocated and pixel representation select the scalar type",
        arguments: [
            (UInt16(16), UInt16(1), ScalarType.int16),
            (UInt16(16), UInt16(0), ScalarType.uint16),
            (UInt16(8), UInt16(1), ScalarType.int8),
            (UInt16(8), UInt16(0), ScalarType.uint8),
        ]
    )
    func scalarTypes(
        _ bits: UInt16,
        _ representation: UInt16,
        _ expected: ScalarType
    ) throws {
        let frame = try translate(
            elements(
                bitsAllocated: bits,
                bitsStored: nil,
                pixelRepresentation: representation
            )
        )
        #expect(frame.scalarFormat.type == expected)
    }

    @Test("[Unit] An unsupported allocation is refused rather than approximated")
    func unsupportedAllocationRefused() throws {
        #expect(throws: DICOMFrameAdapterError.unsupportedSampleFormat) {
            try translate(elements(bitsAllocated: 32, bitsStored: nil))
        }
    }

    @Test("[Unit] Bits stored equal to the container width leaves the bit count absent")
    func bitsStoredAtFullWidth() throws {
        // ScalarFormat's validBitCount describes narrower-than-container
        // semantics, so a full-width Bits Stored is not restated.
        let frame = try translate(elements(bitsAllocated: 16, bitsStored: 16))
        #expect(frame.scalarFormat.validBitCount == nil)
    }

    // MARK: - Optional attributes and DICOM defaults

    @Test("[Unit] Absent rescale terms take DICOM's identity default")
    func absentRescaleTerms() throws {
        let frame = try translate(
            elements(rescaleSlope: nil, rescaleIntercept: nil)
        )
        #expect(frame.rescaleSlope == 1.0)
        #expect(frame.rescaleIntercept == 0.0)
    }

    @Test("[Unit] An absent frame of reference stays absent rather than becoming a wildcard")
    func absentFrameOfReference() throws {
        let frame = try translate(elements(frameOfReferenceUID: nil))
        #expect(frame.frameOfReference == nil)
    }

    @Test("[Unit] An absent pixel padding value stays absent")
    func absentPadding() throws {
        let frame = try translate(elements(paddingValue: nil))
        #expect(frame.pixelPadding == nil)
    }

    // MARK: - Missing required attributes

    @Test("[Unit] Each missing required attribute has its own case")
    func missingAttributes() throws {
        #expect(throws: DICOMFrameAdapterError.missingSOPInstanceUID) {
            try translate(elements(sopUID: nil))
        }
        #expect(throws: DICOMFrameAdapterError.missingSeriesInstanceUID) {
            try translate(elements(seriesUID: nil))
        }
    }

    @Test("[Unit] A malformed multi-valued attribute is refused by count")
    func malformedMultiValued() throws {
        #expect(throws: DICOMFrameAdapterError.malformedPixelSpacing) {
            try translate(elements(pixelSpacing: "0.7"))
        }
        #expect(throws: DICOMFrameAdapterError.malformedImageOrientationPatient) {
            try translate(elements(orientation: "1\\0\\0\\0\\1"))
        }
        #expect(throws: DICOMFrameAdapterError.malformedImagePositionPatient) {
            try translate(elements(position: "1.0\\2.0"))
        }
    }

    // MARK: - Voxelia admission is not bypassed

    @Test("[Unit] A value the neutral description refuses surfaces as one opaque case")
    func voxeliaAdmissionRefusal() throws {
        // A zero row direction is admissible DICOM and inadmissible Voxelia. The
        // adapter must not smuggle it past ADR-0227's admission, and must not
        // disclose which value was refused.
        #expect(throws: DICOMFrameAdapterError.rejectedByVoxeliaAdmission) {
            try translate(elements(orientation: "0\\0\\0\\0\\1\\0"))
        }
        // A non-positive spacing likewise.
        #expect(throws: DICOMFrameAdapterError.rejectedByVoxeliaAdmission) {
            try translate(elements(pixelSpacing: "0\\0.8"))
        }
    }

    // MARK: - Composition with the accepted pipeline

    @Test("[Unit] Translated frames assemble, validate and build through the real pipeline")
    func composesWithPipeline() throws {
        let frames = try (0..<3).map { index in
            try translate(
                elements(
                    position: "-175.5\\-175.5\\\(Double(index) * 2.5)",
                    sopUID: "1.2.840.instance.\(index)"
                )
            )
        }

        let series = try #require(CTSeriesAssembler.assemble(frames).first)
        #expect(series.members.count == 3)

        let assessment = CTGeometryValidator.assess(series, tolerance: .exact)
        #expect(assessment.verdict == .representable)

        let descriptor = try CoordinateSpaceDescriptor(
            id: try space(),
            convention: .dicomPatientLPS,
            handedness: .rightHanded,
            unit: try MeasurementUnit(
                namespace: "ucum",
                code: "mm",
                displayName: "millimetre",
                dimension: .length,
                scaleToCanonical: nil,
                offsetToCanonical: nil
            ),
            externalReferences: ContiguousArray([
                try ExternalFrameReference(
                    namespace: "dicom",
                    identifier: "1.2.840.frame.1"
                )
            ])
        )
        let construction = try CTAffineVolumeBuilder.build(
            series: series,
            assessment: assessment,
            coordinateSpace: descriptor
        )

        // The in-plane steps cross: columnSpacing 0.8 scales rowDirection.
        let m = Array(construction.geometry.indexToWorld.elements)
        #expect(m[0] == 0.8)
        #expect(m[5] == 0.7)
        #expect(m[10] == 2.5)
        #expect(construction.fidelityResidual == 0)

        let layout = try CTVolumeLayout(
            rows: 512,
            columns: 512,
            sliceCount: series.members.count,
            scalarFormat: frames[0].scalarFormat
        )
        #expect(layout.sampleCount == 786_432)
        let placement = try CTFramePlacement(
            frame: series.members[1].frame,
            sliceIndex: 1,
            layout: layout
        )
        #expect(placement.sampleOffset == 262_144)
    }
}

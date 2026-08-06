// SPDX-License-Identifier: MIT

import DICOMCore
import DICOMKit
import Foundation
import VoxeliaImaging

/// An error raised while transferring a DICOM frame's samples into a volume.
///
/// Cases deliberately carry no payload, so a refused transfer never discloses
/// pixel data, extents or offsets in a diagnostic.
public enum DICOMFrameTransferError: Error, Sendable, Equatable {
    /// The data set carries no pixel data element.
    case missingPixelData
    /// The pixel data holds no bytes for the requested frame index.
    case missingFrame
    /// The volume buffer refused the write.
    ///
    /// The buffer's own reason is not surfaced, because it would name extents.
    case rejectedByVolumeAdmission
}

/// Transfers a DICOM frame's samples into a Voxelia volume buffer.
///
/// The transfer is **byte-level and interprets nothing** — no endianness,
/// signedness, rescale or padding decision is taken here, per `ADR-0235`
/// decision 2. Those belong to the value-transformation stage `VOX-DCM-006`
/// requires.
///
/// ## The ownership model, corrected
///
/// `ADR-0230` decision 10 chose direct-write into a caller-provided destination.
/// **DICOMKit cannot serve that model**: its pixel surface returns an owned
/// `Data`. So the achievable model is an owned frame buffer copied into its
/// slice — one copy per frame, which is the materialisation of the volume rather
/// than an avoidable intermediate. `ADR-0235` records the correction, and a true
/// direct-write path would need an upstream DICOMKit entry point taking a
/// destination.
public enum DICOMFrameTransfer {
    /// Copies one frame's sample bytes from `dataSet` into `buffer`.
    ///
    /// - Parameters:
    ///   - dataSet: a data set DICOMKit has already parsed.
    ///   - frameIndex: the frame within the data set's pixel data. Zero for
    ///     single-frame CT, which is every frame in the first vertical slice.
    ///   - placement: where the frame sits in the volume.
    ///   - buffer: the destination, filled in place.
    /// - Throws: ``DICOMFrameTransferError``.
    public static func transfer(
        from dataSet: DataSet,
        frameIndex: Int = 0,
        to placement: CTFramePlacement,
        in buffer: inout CTVolumeByteBuffer
    ) throws {
        guard let pixelData = dataSet.pixelData() else {
            throw DICOMFrameTransferError.missingPixelData
        }
        guard let frame = pixelData.frameData(at: frameIndex) else {
            throw DICOMFrameTransferError.missingFrame
        }
        do {
            try buffer.write(frameBytes: frame, at: placement)
        } catch {
            throw DICOMFrameTransferError.rejectedByVolumeAdmission
        }
    }

    /// Returns one frame's sample bytes without a destination.
    ///
    /// Added for `ADR-0249`'s import session, whose frame source yields bytes
    /// rather than writing them: the session owns the buffer, so the write is
    /// its job and this is only the read. The two entry points share the same
    /// two admissions and neither interprets a sample.
    ///
    /// Returns DICOMKit's own `Data` rather than an `Array`. Converting cost
    /// about 20 ms per frame -- roughly 18 s across a real 899-frame series, five
    /// times the transfer itself -- and the session is generic over the byte
    /// collection precisely so no source has to pay it.
    ///
    /// - Throws: ``DICOMFrameTransferError``.
    public static func frameBytes(
        from dataSet: DataSet,
        frameIndex: Int = 0
    ) throws -> Data {
        guard let pixelData = dataSet.pixelData() else {
            throw DICOMFrameTransferError.missingPixelData
        }
        guard let frame = pixelData.frameData(at: frameIndex) else {
            throw DICOMFrameTransferError.missingFrame
        }
        return frame
    }
}

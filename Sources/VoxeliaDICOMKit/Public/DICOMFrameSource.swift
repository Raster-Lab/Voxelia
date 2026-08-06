// SPDX-License-Identifier: MIT

import DICOMKit
import Foundation
import Synchronization
import VoxeliaCore
import VoxeliaImaging
import VoxeliaSpatial

/// An error raised while serving DICOM frames to an import session.
///
/// Cases deliberately carry no payload, so a refused read never discloses a
/// path, a pixel or an extent in a diagnostic.
public enum DICOMFrameSourceError: Error, Sendable, Equatable {
    /// A frame's samples were requested before its description was read.
    ///
    /// Reachable only by calling ``DICOMFrameSource/frameBytes(for:)`` for a
    /// description this source never produced, which is a caller sequencing
    /// mistake rather than a data fault.
    case frameNotDescribed
}

/// A DICOM-backed frame source for `ADR-0249`'s import session.
///
/// Supplies the two closures `CTImportSession` needs: one turning a file URL
/// into a ``CTFrameDescription``, and one yielding that frame's sample bytes.
/// Nothing here interprets a sample; `ADR-0235` decision 2's boundary is
/// unchanged.
///
/// ## Why bytes are re-read, and why there is no option to retain them
///
/// The obvious implementation keeps every parsed `DataSet` from the description
/// pass so the byte pass serves from memory — which is what the `VOX-VS1-001`
/// harness did. This source instead retains only each frame's file URL and
/// re-reads the file on demand.
///
/// A retaining mode was built and **measured against a real 899-file series, and
/// the measurement refuted the reason for having it**: retention was `1.01x`
/// faster — no speedup at all — for `+476 MiB` of peak resident memory, because
/// `DICOMFile.read` does not eagerly copy a file's bytes. So re-reading is
/// strictly better here, the option was removed rather than shipped as a
/// plausible-sounding choice, and the numbers are recorded in
/// `docs/progress/evidence/VOX-VS1-001-real-ct-demonstration-2026-08-06.md`.
///
/// A caller with different evidence can still retain data sets itself and pass
/// its own closures; the session takes closures rather than a source type
/// exactly so that stays possible.
public final class DICOMFrameSource: Sendable {
    /// Each described frame's file, keyed by the frame's source identifier.
    private let files = Mutex<[String: URL]>([:])

    /// The coordinate space every produced description is expressed in.
    private let coordinateSpace: CoordinateSpaceID

    /// Creates a source producing descriptions in `coordinateSpace`.
    ///
    public init(coordinateSpace: CoordinateSpaceID) {
        self.coordinateSpace = coordinateSpace
    }

    /// Reads one file's frame description, or `nil` when the file is not an
    /// admissible CT frame.
    ///
    /// A file that fails to parse, or that parses but is not admissible as a CT
    /// frame, is **skipped rather than fatal**: a series directory legitimately
    /// contains other objects, and one unreadable file must not refuse a whole
    /// import. The session's `noAdmissibleFrames` case is what reports the
    /// outcome when nothing at all is admissible.
    public func describe(_ url: URL) -> CTFrameDescription? {
        guard let file = try? DICOMFile.read(from: url),
            let description = try? DICOMFrameAdapter.frameDescription(
                from: file.dataSet,
                coordinateSpace: coordinateSpace
            )
        else {
            return nil
        }
        files.withLock { $0[description.sourceIdentity.identifier] = url }
        return description
    }

    /// Reads one described frame's sample bytes.
    ///
    /// - Throws: ``DICOMFrameSourceError/frameNotDescribed``, or the transfer
    ///   contract's typed errors.
    public func frameBytes(for frame: CTFrameDescription) throws -> Data {
        let identifier = frame.sourceIdentity.identifier
        guard let url = files.withLock({ $0[identifier] }) else {
            throw DICOMFrameSourceError.frameNotDescribed
        }
        let file = try DICOMFile.read(from: url)
        return try DICOMFrameTransfer.frameBytes(from: file.dataSet)
    }

    /// How many frames this source has described.
    public var describedFrameCount: Int {
        files.withLock { $0.count }
    }
}

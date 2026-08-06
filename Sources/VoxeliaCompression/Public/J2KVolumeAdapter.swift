// SPDX-License-Identifier: MIT

import Foundation
import J2K3D
import J2KCore
import VoxeliaCore

/// An error raised while admitting a `J2KSwift` volume decode.
///
/// Payload-free, consistent with the arc: a refused decode discloses no dimension,
/// bit depth or byte count.
public enum J2KVolumeAdapterError: Error, Sendable, Equatable {
    /// The decoder reported the decode as partial, or decoded fewer tiles than the
    /// codestream contains.
    case decodeIncomplete
    /// The decoder emitted warnings, which a diagnostic path does not silently
    /// accept.
    case decodeWarned
    /// A component is subsampled relative to the reference grid.
    case componentSubsampled
    /// A component's dimensions differ from the volume's.
    case componentDimensionMismatch
    /// The component's bit depth has no Voxelia scalar representation.
    case unsupportedBitDepth
    /// The component's signedness differs from what the payload declared.
    case componentSignednessMismatch
    /// The decode produced a component count the caller did not declare.
    case componentCountMismatch
    /// A component's byte count disagrees with its own declared dimensions and
    /// bit depth.
    case componentByteCountMismatch
    /// More than one component, which this adapter does not yet compose.
    case multipleComponentsUnsupported
}

/// Adapts a `J2KSwift` JP3D decode into the arc's `DecodedSamples`, per `ADR-0268`.
///
/// ## What this adapter deliberately ignores, and why it matters more than what it reads
///
/// `J2KVolume` carries **`spacingX/Y/Z` and `originX/Y/Z`**, and `J2KVolumeMetadata`
/// carries **`patientID`, `modality`, `windowCenter`, `sliceThickness`** and more.
/// This adapter reads **none** of it.
///
/// - **Geometry is not the codec's to supply.** Voxelia's patient-space mapping comes
///   from DICOM attributes through `CTFrameDescription` and `CTAffineVolumeBuilder`,
///   governed by accepted records with an independent oracle. Taking spacing or origin
///   from a codestream would create a second source of truth for the most
///   safety-critical mapping in the system. `ADR-0255`'s binding rules state it: a
///   decode is a value transformation, not a geometry decision.
/// - **Patient identity is not the codec's to supply either.** It belongs to the
///   DICOM path, which already admits it under `ADR-0227`.
///
/// The convenience of a codec that hands you spacing is exactly the hazard.
///
/// ## Error tolerance is turned off explicitly
///
/// `JP3DDecoderConfiguration` defaults `tolerateErrors` to **`true`**. For a
/// diagnostic viewer that default is wrong: it produces output from a codestream the
/// decoder itself could not fully parse. ``configuration`` sets it to `false` and
/// never relies on the default, and the admissions below refuse a decode the codec
/// still reports as partial or warned.
public enum J2KVolumeAdapter {
    /// The decoder configuration this adapter requires.
    ///
    /// `tolerateErrors: false` is the whole point; the other values are the
    /// decoder's own defaults, restated so a change upstream cannot silently alter
    /// what Voxelia asks for.
    public static var configuration: JP3DDecoderConfiguration {
        JP3DDecoderConfiguration(
            maxQualityLayers: 0,
            resolutionLevel: 0,
            tolerateErrors: false
        )
    }

    /// The bytes one sample of `bitDepth` bits occupies, or `nil` when Voxelia has
    /// no scalar type for it.
    ///
    /// J2K admits 1 to 38 bits. Voxelia's scalar types are byte-width integers, so
    /// depths up to 8 and up to 16 are representable and anything wider is refused
    /// rather than truncated. Refusing is the only honest option: a 24-bit sample
    /// silently narrowed to 16 would be a quantitative error in diagnostic data.
    static func byteWidth(forBitDepth bitDepth: Int) -> Int? {
        switch bitDepth {
        case 1...8: 1
        case 9...16: 2
        default: nil
        }
    }

    /// Admits one JP3D decode against what the payload declared.
    ///
    /// Every check is a refusal rather than an accommodation, because each one marks
    /// a case where the decode does not mean what the caller asked for.
    ///
    /// - Throws: ``J2KVolumeAdapterError``.
    public static func decodedSamples(
        from result: JP3DDecoderResult,
        declaredScalarFormat: ScalarFormat,
        declaredComponentCount: Int
    ) throws -> DecodedSamples {
        // Unwrapped into plain values immediately, because `JP3DDecoderResult` has
        // no public initialiser: an adapter that only accepted it could not be
        // tested without real codestreams. The checkable core below takes values a
        // test can construct, and this entry point is the thin part.
        try decodedSamples(
            volume: result.volume,
            isPartial: result.isPartial,
            tilesDecoded: result.tilesDecoded,
            tilesTotal: result.tilesTotal,
            warnings: result.warnings,
            declaredScalarFormat: declaredScalarFormat,
            declaredComponentCount: declaredComponentCount
        )
    }

    /// The checkable core, taking the decode's report as plain values.
    ///
    /// `internal` rather than private so the suite can exercise every refusal
    /// without a real codestream, and separate from the entry point above because
    /// `JP3DDecoderResult` cannot be constructed outside its own module.
    static func decodedSamples(
        volume: J2KVolume,
        isPartial: Bool,
        tilesDecoded: Int,
        tilesTotal: Int,
        warnings: [String],
        declaredScalarFormat: ScalarFormat,
        declaredComponentCount: Int
    ) throws -> DecodedSamples {
        // The codec's own completeness signals, checked first. `isPartial` is a
        // signal the arc's byte-count checks cannot see: a partial decode can be
        // the right length and the wrong data.
        guard !isPartial else {
            throw J2KVolumeAdapterError.decodeIncomplete
        }
        guard tilesDecoded == tilesTotal else {
            throw J2KVolumeAdapterError.decodeIncomplete
        }
        guard warnings.isEmpty else {
            throw J2KVolumeAdapterError.decodeWarned
        }

        guard volume.components.count == declaredComponentCount else {
            throw J2KVolumeAdapterError.componentCountMismatch
        }
        guard volume.components.count == 1 else {
            // Interleaving several components into one buffer is a layout decision
            // no record has made, so it is refused rather than guessed.
            throw J2KVolumeAdapterError.multipleComponentsUnsupported
        }
        guard let component = volume.components.first else {
            throw J2KVolumeAdapterError.componentCountMismatch
        }

        guard
            component.subsamplingX == 1,
            component.subsamplingY == 1,
            component.subsamplingZ == 1
        else {
            // A subsampled component's data does not correspond to the volume's
            // extents, so reading it as if it did would silently misplace samples.
            throw J2KVolumeAdapterError.componentSubsampled
        }
        guard
            component.width == volume.width,
            component.height == volume.height,
            component.depth == volume.depth
        else {
            throw J2KVolumeAdapterError.componentDimensionMismatch
        }
        guard component.signed == declaredScalarFormat.type.isSignedInteger else {
            throw J2KVolumeAdapterError.componentSignednessMismatch
        }
        guard let byteWidth = byteWidth(forBitDepth: component.bitDepth),
            byteWidth == declaredScalarFormat.type.byteCount
        else {
            throw J2KVolumeAdapterError.unsupportedBitDepth
        }

        // The sample layout is checked, not assumed. Deriving the expected length
        // from the component's own dimensions and bit depth and comparing it to the
        // data it returned is how this adapter avoids encoding a guess about the
        // codec's packing.
        let voxels = component.width * component.height * component.depth
        guard component.data.count == voxels * byteWidth else {
            throw J2KVolumeAdapterError.componentByteCountMismatch
        }

        return DecodedSamples(
            bytes: ContiguousArray(component.data),
            claim: DecodedSampleClaim(
                byteCount: component.data.count,
                extents: ContiguousArray([
                    component.width, component.height, component.depth,
                ]),
                scalarFormat: declaredScalarFormat,
                componentCount: 1
            )
        )
    }
}

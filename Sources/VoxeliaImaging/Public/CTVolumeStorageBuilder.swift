// SPDX-License-Identifier: MIT

import VoxeliaCore
import VoxeliaStorage

/// An error raised while binding a CT volume's bytes to storage.
///
/// Cases deliberately carry no payload, so a refusal never discloses extents or
/// byte counts in a diagnostic.
public enum CTVolumeStorageError: Error, Sendable, Equatable {
    /// The buffer does not hold every slice.
    ///
    /// Publishing a partially filled volume is the silent-gap failure
    /// `ADR-0235` decision 7 added written-slice tracking to prevent: the bytes
    /// would look plausible and the missing slices would read as zeros. A volume
    /// is complete or it is not published.
    case incompleteVolume
    /// The descriptor's shape, scalar type or component count disagrees with the
    /// buffer's layout.
    case descriptorBufferMismatch
    /// The storage provider refused the binding.
    ///
    /// Its own reason is not surfaced, because it would name byte counts.
    case rejectedByStorageAdmission
}

/// Binds an ingested CT volume's bytes to the accepted storage contract, per
/// `ADR-0238` increment (b).
///
/// This is the smallest increment of the bridge arc, because
/// `ContiguousImageStorage(binding:bytes:)` already accepts exactly what
/// `CTVolumeByteBuffer` holds. Its work is admission, not transformation.
public enum CTVolumeStorageBuilder {
    /// Builds erased storage for a completed volume buffer.
    ///
    /// - Parameters:
    ///   - buffer: a **complete** volume buffer. An incomplete one is refused.
    ///   - descriptor: the descriptor the volume will be published with, whose
    ///     shape, scalar type and component count must agree with the buffer.
    /// - Throws: ``CTVolumeStorageError``.
    public static func storage(
        buffer: CTVolumeByteBuffer,
        descriptor: ImageDescriptor
    ) throws -> AnyImageStorage {
        guard buffer.isComplete else {
            throw CTVolumeStorageError.incompleteVolume
        }

        let binding: LogicalSampleBinding
        do {
            binding = try LogicalSampleBinding(
                shape: descriptor.shape,
                scalarFormat: descriptor.scalarFormat,
                components: descriptor.components
            )
        } catch {
            throw CTVolumeStorageError.descriptorBufferMismatch
        }

        // The binding derives its byte count from the descriptor; the buffer
        // derived its own from the layout. They must agree, and checking rather
        // than assuming is the point of this increment.
        guard binding.logicalByteCount == buffer.bytes.count else {
            throw CTVolumeStorageError.descriptorBufferMismatch
        }
        guard binding.scalarType == buffer.layout.scalarFormat.type else {
            throw CTVolumeStorageError.descriptorBufferMismatch
        }

        do {
            let provider = try ContiguousImageStorage(
                binding: binding,
                bytes: Array(buffer.bytes)
            )
            return AnyImageStorage(erasing: provider)
        } catch {
            throw CTVolumeStorageError.rejectedByStorageAdmission
        }
    }
}

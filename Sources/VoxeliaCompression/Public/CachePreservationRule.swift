// SPDX-License-Identifier: MIT

import VoxeliaCore

/// An error raised while admitting a toolkit-native cache's identity.
public enum CachePreservationError: Error, Sendable, Equatable {
    /// The cache identity carries no source identities, so nothing ties it to the
    /// original instances.
    case originalSourceIdentitiesAbsent
    /// The cache identity declares no derivation, so it does not record what it was
    /// generated from.
    case derivationAbsent
    /// The cache's source identities are not a superset of the original's.
    case originalSourceIdentitiesIncomplete
    /// The cache's derivation names no input.
    case derivationNamesNoInput
    /// The cache claims the same object identifier as the original.
    case cacheReplacesOriginal
}

/// The `VOX-CMP-012` preservation rule: generating a toolkit-native cache must never
/// detach the original DICOM instances, per `ADR-0270`.
///
/// ## Why this is not already guaranteed by the identity model
///
/// `DataIdentity`'s admission is an **or**: a value is admissible when it carries a
/// content identifier **or** source identities **or** a derivation. So an identity
/// with a derivation and **no source identities at all** is perfectly legal — which
/// is precisely the detachment `VOX-CMP-012` forbids. A cache published that way
/// would record what operation produced it while losing every trace of which patient
/// instances it came from.
///
/// The accepted model is not wrong; it admits many kinds of object, most of which
/// have no DICOM ancestry. The preservation obligation is specific to caches
/// generated from imported instances, so it is enforced here, at the boundary that
/// knows it applies, rather than by tightening a Core-wide admission that would then
/// refuse legitimate objects.
///
/// ## What preservation means here
///
/// A cache is a *derived* object standing alongside its original, never in place of
/// it. Concretely:
///
/// 1. It carries **every** source identity the original carried — a superset is
///    permitted, a subset is not.
/// 2. It declares a derivation naming at least one input, so what it came from is
///    recoverable.
/// 3. It does **not** claim the original's object identifier, because an object that
///    replaces its source under the same name is the deletion this row exists to
///    prevent, dressed as an update.
///
/// This rule constrains a capability Voxelia does not yet have. `ADR-0269` evaluated
/// JP3D as a volume cache and found it slower to decode than re-importing the source,
/// so no cache generation is planned — and the rule is built anyway, because
/// `VOX-CMP-012` is a safety constraint and the useful moment to make one enforceable
/// is before the capability exists rather than after.
public enum CachePreservationRule {
    /// Admits a cache identity against the original it was generated from.
    ///
    /// - Parameters:
    ///   - cache: the identity the cache would be published under.
    ///   - original: the identity of the object it was generated from.
    /// - Throws: ``CachePreservationError``.
    public static func admit(
        cache: DataIdentity,
        generatedFrom original: DataIdentity
    ) throws {
        guard cache.objectID != original.objectID else {
            throw CachePreservationError.cacheReplacesOriginal
        }
        guard !cache.sourceIdentities.isEmpty else {
            throw CachePreservationError.originalSourceIdentitiesAbsent
        }
        guard let derivation = cache.derivation else {
            throw CachePreservationError.derivationAbsent
        }
        guard !derivation.inputs.isEmpty else {
            throw CachePreservationError.derivationNamesNoInput
        }

        // A superset is permitted because a cache spanning several originals
        // legitimately carries more; a subset is refused because it has dropped
        // instances that the original accounted for.
        let cacheSources = Set(cache.sourceIdentities)
        let originalSources = Set(original.sourceIdentities)
        guard originalSources.isSubset(of: cacheSources) else {
            throw CachePreservationError.originalSourceIdentitiesIncomplete
        }
    }
}

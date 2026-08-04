// SPDX-License-Identifier: MIT

/// The Core-minted nonforgeable read authority for one admitted provider
/// lineage, selected by accepted `ADR-0039` and frozen by `ADR-0042`.
///
/// Only Core admission mints an authority; providers and callers cannot
/// inject, clone or replace one. Identity is reference identity within
/// one process. The value is not persistent identity, provenance,
/// authentication or a canonical wire.
public final class StorageReadAuthority: Sendable {
    init() {}
}

/// One immutable admitted snapshot handle binding a Core authority to the
/// exact logical binding, representation descriptor, retained owner and
/// snapshot generation.
///
/// A handle denotes one immutable logical snapshot: a later generation
/// never mutates or relabels an existing handle, and every successor
/// derived from one admission co-retains the same authority. Descriptor
/// equality establishes no provider equality, and holding a handle grants
/// no integrity, residency or publication authority.
public struct StorageSnapshotHandle: Sendable {
    /// The co-retained admission authority for this lineage.
    public let authority: StorageReadAuthority
    /// The exact admitted logical binding.
    public let binding: LogicalSampleBinding
    /// The exact admitted representation descriptor.
    public let representation: StorageRepresentationDescriptor
    /// The immutable snapshot generation of this handle.
    public let generation: UInt64

    private let owner: any AnyObject & Sendable

    private init(
        authority: StorageReadAuthority,
        binding: LogicalSampleBinding,
        representation: StorageRepresentationDescriptor,
        generation: UInt64,
        owner: any AnyObject & Sendable
    ) {
        self.authority = authority
        self.binding = binding
        self.representation = representation
        self.generation = generation
        self.owner = owner
    }

    /// Validates that a decoded representation carries exactly the
    /// admitted binding; opaque representations bind by declaration.
    private static func validate(
        binding: LogicalSampleBinding,
        representation: StorageRepresentationDescriptor
    ) throws {
        if case .decodedStrided(let decoded) = representation {
            guard decoded.binding == binding else {
                throw StorageContractError.incompatibleBinding
            }
        }
    }

    /// Core admission: mints one fresh nonforgeable authority for the
    /// supplied provider lineage and composes the immutable handle.
    ///
    /// - Throws: ``StorageContractError/incompatibleBinding`` when a
    ///   decoded representation does not carry exactly the admitted
    ///   binding.
    public static func admit(
        binding: LogicalSampleBinding,
        representation: StorageRepresentationDescriptor,
        owner: some AnyObject & Sendable,
        generation: UInt64
    ) throws -> StorageSnapshotHandle {
        try validate(binding: binding, representation: representation)
        return StorageSnapshotHandle(
            authority: StorageReadAuthority(),
            binding: binding,
            representation: representation,
            generation: generation,
            owner: owner
        )
    }

    /// Derives the handle for a strictly newer generation of the same
    /// admitted lineage, co-retaining the same authority.
    ///
    /// - Throws: ``StorageContractError/staleSnapshot`` when the supplied
    ///   generation is not strictly greater, or
    ///   ``StorageContractError/incompatibleBinding`` for a decoded
    ///   representation that does not carry the admitted binding.
    public func successor(
        representation: StorageRepresentationDescriptor,
        owner: some AnyObject & Sendable,
        generation: UInt64
    ) throws -> StorageSnapshotHandle {
        guard generation > self.generation else {
            throw StorageContractError.staleSnapshot
        }
        try Self.validate(binding: binding, representation: representation)
        return StorageSnapshotHandle(
            authority: authority,
            binding: binding,
            representation: representation,
            generation: generation,
            owner: owner
        )
    }
}

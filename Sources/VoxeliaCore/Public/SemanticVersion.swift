// SPDX-License-Identifier: MIT

/// An error raised while validating a semantic-version value.
public enum SemanticVersionError: Error, Sendable, Equatable {
    case negativeMajor(Int)
    case negativeMinor(Int)
    case negativePatch(Int)
    case invalidPrerelease(String)
    case invalidBuildMetadata(String)
}

/// A validated Semantic Versioning 2.0 value.
///
/// Prerelease and build strings omit their `-` and `+` delimiters. Build
/// metadata is preserved but does not participate in precedence, equality or
/// hashing, keeping `Comparable` and `Hashable` behavior consistent.
public struct SemanticVersion: Sendable, Hashable, Codable, Comparable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?
    public let buildMetadata: String?

    /// Creates and validates a semantic version.
    ///
    /// - Throws: ``SemanticVersionError`` for a negative core component or
    ///   malformed prerelease/build identifier sequence.
    public init(
        major: Int,
        minor: Int,
        patch: Int,
        prerelease: String? = nil,
        buildMetadata: String? = nil
    ) throws {
        guard major >= 0 else {
            throw SemanticVersionError.negativeMajor(major)
        }
        guard minor >= 0 else {
            throw SemanticVersionError.negativeMinor(minor)
        }
        guard patch >= 0 else {
            throw SemanticVersionError.negativePatch(patch)
        }
        if let prerelease,
            !Self.isValidIdentifierSequence(
                prerelease,
                rejectLeadingZeroNumericIdentifiers: true
            )
        {
            throw SemanticVersionError.invalidPrerelease(prerelease)
        }
        if let buildMetadata,
            !Self.isValidIdentifierSequence(
                buildMetadata,
                rejectLeadingZeroNumericIdentifiers: false
            )
        {
            throw SemanticVersionError.invalidBuildMetadata(buildMetadata)
        }

        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }

    /// Compares two versions using Semantic Versioning precedence.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil):
            return false
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (.some(let lhsPrerelease), .some(let rhsPrerelease)):
            return Self.comparePrerelease(lhsPrerelease, rhsPrerelease) < 0
        }
    }

    /// Tests semantic-version precedence equality. Build metadata is ignored.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.major == rhs.major
            && lhs.minor == rhs.minor
            && lhs.patch == rhs.patch
            && lhs.prerelease == rhs.prerelease
    }

    /// Hashes the fields that participate in precedence equality.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
        hasher.combine(prerelease)
    }

    private enum CodingKeys: String, CodingKey {
        case major
        case minor
        case patch
        case prerelease
        case buildMetadata
    }

    /// Decodes and revalidates a version so serialized input cannot bypass its
    /// Semantic Versioning invariants.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedMajor = try container.decode(Int.self, forKey: .major)
        let decodedMinor = try container.decode(Int.self, forKey: .minor)
        let decodedPatch = try container.decode(Int.self, forKey: .patch)
        let decodedPrerelease = try container.decodeIfPresent(
            String.self,
            forKey: .prerelease
        )
        let decodedBuildMetadata = try container.decodeIfPresent(
            String.self,
            forKey: .buildMetadata
        )

        do {
            try self.init(
                major: decodedMajor,
                minor: decodedMinor,
                patch: decodedPatch,
                prerelease: decodedPrerelease,
                buildMetadata: decodedBuildMetadata
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "SemanticVersion contains invalid fields.",
                    underlyingError: error
                )
            )
        }
    }

    /// Encodes all five declared version fields without normalization.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(major, forKey: .major)
        try container.encode(minor, forKey: .minor)
        try container.encode(patch, forKey: .patch)
        try container.encode(prerelease, forKey: .prerelease)
        try container.encode(buildMetadata, forKey: .buildMetadata)
    }

    private static func isValidIdentifierSequence(
        _ value: String,
        rejectLeadingZeroNumericIdentifiers: Bool
    ) -> Bool {
        guard !value.isEmpty else { return false }
        let identifiers = value.split(separator: ".", omittingEmptySubsequences: false)
        for identifier in identifiers {
            guard !identifier.isEmpty else { return false }

            var isNumeric = true
            for byte in identifier.utf8 {
                let isDigit = (48...57).contains(byte)
                let isUppercaseLetter = (65...90).contains(byte)
                let isLowercaseLetter = (97...122).contains(byte)
                guard isDigit || isUppercaseLetter || isLowercaseLetter || byte == 45 else {
                    return false
                }
                isNumeric = isNumeric && isDigit
            }

            if rejectLeadingZeroNumericIdentifiers,
                isNumeric,
                identifier.count > 1,
                identifier.first == "0"
            {
                return false
            }
        }
        return true
    }

    private static func comparePrerelease(_ lhs: String, _ rhs: String) -> Int {
        let lhsIdentifiers = lhs.split(separator: ".", omittingEmptySubsequences: false)
        let rhsIdentifiers = rhs.split(separator: ".", omittingEmptySubsequences: false)

        for (lhsIdentifier, rhsIdentifier) in zip(lhsIdentifiers, rhsIdentifiers) {
            if lhsIdentifier == rhsIdentifier { continue }

            let lhsIsNumeric = lhsIdentifier.utf8.allSatisfy { (48...57).contains($0) }
            let rhsIsNumeric = rhsIdentifier.utf8.allSatisfy { (48...57).contains($0) }
            switch (lhsIsNumeric, rhsIsNumeric) {
            case (true, false):
                return -1
            case (false, true):
                return 1
            case (true, true):
                if lhsIdentifier.count != rhsIdentifier.count {
                    return lhsIdentifier.count < rhsIdentifier.count ? -1 : 1
                }
            case (false, false):
                break
            }

            return lhsIdentifier.utf8.lexicographicallyPrecedes(rhsIdentifier.utf8)
                ? -1 : 1
        }

        if lhsIdentifiers.count == rhsIdentifiers.count { return 0 }
        return lhsIdentifiers.count < rhsIdentifiers.count ? -1 : 1
    }
}

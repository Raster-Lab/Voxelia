// SPDX-License-Identifier: MIT

/// The frozen `VCMJ-1` identity-field whitespace oracle selected by
/// `ADR-0035`.
///
/// An identity field (metadata-key namespace or name, coded-concept scheme
/// or value) is blank exactly when it contains no Unicode scalar outside
/// the enumerated set below. The implementation deliberately does not use
/// the toolchain-dependent `Character.isWhitespace` grapheme property, so
/// accepted domains cannot drift across Swift or Unicode versions.
/// `VoxeliaSpatial` owns its own private implementation generated from the
/// same controlled table; cross-module fixtures keep the two in agreement.
func metadataIdentityFieldIsBlank(_ value: String) -> Bool {
    !value.unicodeScalars.contains { !isFrozenIdentityWhitespaceScalar($0) }
}

/// Membership in the frozen whitespace scalar set: U+0009 through U+000D,
/// U+0020, U+0085, U+00A0, U+1680, U+2000 through U+200A, U+2028, U+2029,
/// U+202F, U+205F and U+3000.
func isFrozenIdentityWhitespaceScalar(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x09...0x0D, 0x20, 0x85, 0xA0, 0x1680, 0x2000...0x200A, 0x2028,
        0x2029, 0x202F, 0x205F, 0x3000:
        true
    default:
        false
    }
}

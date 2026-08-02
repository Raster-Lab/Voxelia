// SPDX-License-Identifier: MIT

/// A metadata privacy classification used to support logging and export policy.
///
/// Classification does not replace host privacy controls.
public enum MetadataPrivacyClass: String, Sendable, Hashable, Codable {
    case publicData
    case technical
    case potentiallyIdentifying
    case sensitive
    case hostDefined
}

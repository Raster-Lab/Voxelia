// SPDX-License-Identifier: MIT

/// The declared handedness of a coordinate space.
public enum CoordinateHandedness: String, Sendable, Hashable, Codable {
    case rightHanded
    case leftHanded
    case unspecified
}

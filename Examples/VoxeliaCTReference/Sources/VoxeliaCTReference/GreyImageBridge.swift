// SPDX-License-Identifier: MIT

import AppKit

/// The one display bridge that touches a pointer-typed platform API.
///
/// `CGImage`'s initializer carries an `UnsafePointer<CGFloat>?` decode
/// parameter, so referencing it requires the marker even though this
/// call passes nil. The file is fingerprinted in the safety gate's
/// approved exceptions per the `ADR-0186` pattern: keep it minimal and
/// stable, and never add logic here.
enum GreyImageBridge {
    static func makeImage(
        bytes: [UInt8],
        width: Int,
        height: Int
    ) -> NSImage? {
        guard
            let provider = CGDataProvider(data: Data(bytes) as CFData),
            let cgImage = unsafe CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else {
            return nil
        }
        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: width, height: height)
        )
    }
}

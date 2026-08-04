// SPDX-License-Identifier: MIT

import Testing

@testable import VoxeliaRendering

@Suite("TransferFunction")
struct TransferFunctionTests {
    @Test("[Unit][VOX-ARC-008][VOX-ERR-001] windows validate in the real value domain")
    func windowsValidateInTheRealValueDomain() throws {
        // Valid windows admit, including the degenerate unit width the
        // registered model proves total.
        let softTissue = try GreyscaleWindowFunction(center: 40, width: 400)
        #expect(softTissue.center == 40)
        #expect(softTissue.width == 400)
        _ = try GreyscaleWindowFunction(center: -600, width: 1)

        // Non-finite centres and sub-one or non-finite widths reject
        // typed.
        for (center, width) in [
            (Double.nan, 400.0), (.infinity, 400.0),
            (40.0, 0.5), (40.0, .nan), (40.0, -.infinity),
        ] {
            do {
                _ = try GreyscaleWindowFunction(center: center, width: width)
                #expect(Bool(false), "Expected an invalid window to be rejected.")
            } catch RenderModelError.invalidWindowParameter {}
        }

        // The closed transfer function carries exact value identity.
        let function = TransferFunction.greyscaleWindow(softTissue)
        #expect(
            function
                == .greyscaleWindow(
                    try GreyscaleWindowFunction(center: 40, width: 400)
                )
        )
        #expect(
            function
                != .greyscaleWindow(
                    try GreyscaleWindowFunction(center: 40, width: 401)
                )
        )

        requireSendable(GreyscaleWindowFunction.self)
        requireSendable(TransferFunction.self)
    }

    private func requireSendable<Value: Sendable>(_ type: Value.Type) {}
}

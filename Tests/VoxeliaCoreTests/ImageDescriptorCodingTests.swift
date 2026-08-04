// SPDX-License-Identifier: MIT

import Foundation
import Testing
import VoxeliaSpatial

@testable import VoxeliaCore

@Suite("ImageDescriptorCoding")
struct ImageDescriptorCodingTests {
    private func descriptor() throws -> ImageDescriptor {
        guard let x = AxisID(rawValue: "x"), let y = AxisID(rawValue: "y"),
            let spaceID = CoordinateSpaceID(rawValue: "patient")
        else {
            throw ImageDescriptorError.duplicateAxisIdentifier
        }
        let space = try CoordinateSpaceDescriptor(
            id: spaceID,
            convention: .dicomPatientLPS,
            handedness: .unspecified,
            unit: try MeasurementUnit(namespace: "UCUM", code: "mm", dimension: .length),
            externalReferences: [
                try ExternalFrameReference(namespace: "dicom", identifier: "frame-1")
            ]
        )
        let geometry = try AffineGridGeometry(
            spatialAxes: try SpatialAxisMapping(imageAxes: [0, 1]),
            indexToWorld: .identity,
            coordinateSpace: space
        )
        return try ImageDescriptor(
            shape: try ImageShape(extents: [4, 3]),
            scalarFormat: try ScalarFormat(
                type: .uint16,
                validBitCount: 12,
                byteOrder: .littleEndian
            ),
            components: try ComponentDescriptor(
                count: 1,
                interpretation: .scalar,
                layout: .interleaved,
                componentNames: nil
            ),
            semantic: .intensity,
            axes: [
                try AxisDescriptor(
                    id: x,
                    name: "x",
                    semantic: .spatialX,
                    unit: nil,
                    sampling: .regular(origin: 0, spacing: 0.5)
                ),
                try AxisDescriptor(
                    id: y,
                    name: "y",
                    semantic: .spatialY,
                    unit: nil,
                    sampling: .indexOnly
                ),
            ],
            spatialGeometry: .affine(geometry),
            valueTransform: nil,
            units: try MeasurementUnit(namespace: "UCUM", code: "HU")
        )
    }

    @Test("[Unit][CDMS-19.1][VOX-API-004] the descriptor wire round trips")
    func descriptorWireRoundTrips() throws {
        let descriptor = try descriptor()
        let encoded = try JSONEncoder().encode(descriptor)
        let decoded = try JSONDecoder().decode(ImageDescriptor.self, from: encoded)
        #expect(decoded == descriptor)

        // Explicit nulls are written for absent optional fields.
        let text = String(decoding: encoded, as: UTF8.self)
        #expect(text.contains(#""valueTransform":null"#))
        #expect(text.contains(#""spatialGeometry":{"affine":"#))
    }

    @Test("[Unit][CDMS-19.2][VOX-ERR-001] the descriptor wire rejects malformed")
    func descriptorWireRejectsMalformed() throws {
        let descriptor = try descriptor()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let canonicalText = String(
            decoding: try encoder.encode(descriptor),
            as: UTF8.self
        )

        let malformed = [
            // A missing field is rejected by the exact key set.
            canonicalText.replacingOccurrences(
                of: #","valueTransform":null"#,
                with: ""
            ),
            // A distinct extra field is rejected.
            canonicalText.replacingOccurrences(
                of: #""valueTransform":null"#,
                with: #""valueTransform":null,"extra":true"#
            ),
            // An invariant violation is rejected after child decoding:
            // duplicate the axis array's first entry via axis rename.
            canonicalText.replacingOccurrences(of: #""name":"y""#, with: #""name":"x""#)
                .replacingOccurrences(
                    of: #""id":{"rawValue":"y"}"#,
                    with: #""id":{"rawValue":"x"}"#
                ),
            // An unknown geometry tag is rejected.
            canonicalText.replacingOccurrences(
                of: #""spatialGeometry":{"affine":"#,
                with: #""spatialGeometry":{"rigid":"#
            ),
        ]
        for document in malformed {
            do {
                _ = try JSONDecoder().decode(
                    ImageDescriptor.self,
                    from: Data(document.utf8)
                )
                #expect(Bool(false), "Expected a malformed descriptor to be rejected.")
            } catch is DecodingError {
                // Expected value-redacted rejection.
            }
        }

        // The invariant failure is value-redacted: no axis or space
        // identifiers leak through the context.
        let sentinel = canonicalText.replacingOccurrences(
            of: #""id":{"rawValue":"y"}"#,
            with: #""id":{"rawValue":"x"}"#
        )
        do {
            _ = try JSONDecoder().decode(ImageDescriptor.self, from: Data(sentinel.utf8))
            #expect(Bool(false), "Expected a duplicate axis ID to be rejected.")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.isEmpty)
            var rendered = ""
            dump(context, to: &rendered)
            #expect(!rendered.contains("patient"))
        }
    }
}

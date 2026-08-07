// SPDX-License-Identifier: MIT

import VoxeliaSpatial

/// An error raised by segmentation-model admission, per the CDMS
/// section 52.11 invariants activated by `ADR-0359`.
public enum SegmentationModelError: Error, Sendable, Equatable {
    case emptyLabel
    case duplicateSegmentID
    case duplicateLabelValue
    case unresolvedSegmentReference
    case invalidDisplayRecommendation
    case invalidFractionalDomain
    case invalidThreshold
    case incompatibleGeometry
    case emptySegmentation
}

/// A stable identity for one segment, per CDMS section 52.2.
public struct SegmentID: VoxeliaStringIdentifier {
    /// The preserved case-sensitive identifier spelling.
    public let rawValue: String

    /// The hard inclusive raw-value byte ceiling, mirroring `ADR-0044`.
    public static let maximumUTF8ByteCount = 255

    /// Creates an identifier unless `rawValue` is empty,
    /// Unicode-whitespace-only or over the persistent byte ceiling.
    public init?(rawValue: String) {
        guard rawValue.contains(where: { !$0.isWhitespace }),
            rawValue.utf8.count <= Self.maximumUTF8ByteCount
        else { return nil }
        self.rawValue = rawValue
    }

    /// Compares the exact accepted UTF-8 bytes.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.utf8.elementsEqual(rhs.rawValue.utf8)
    }

    /// Hashes the exact accepted UTF-8 bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.utf8.count)
        for byte in rawValue.utf8 {
            hasher.combine(byte)
        }
    }
}

/// How a segment came to exist, per CDMS section 52.4.
public enum SegmentAlgorithmType: String, Sendable, Hashable, Codable {
    case manual
    case semiautomatic
    case automatic
    case imported
    case unknown
}

/// The provenance of a segment's production, per CDMS section 52.3.
public struct SegmentAlgorithmDescriptor: Sendable, Hashable, Codable {
    public let type: SegmentAlgorithmType
    public let name: String?
    public let version: String?
    public let modelIdentity: String?

    public init(
        type: SegmentAlgorithmType,
        name: String?,
        version: String?,
        modelIdentity: String?
    ) {
        self.type = type
        self.name = name
        self.version = version
        self.modelIdentity = modelIdentity
    }
}

/// A non-authoritative display recommendation, per CDMS section 52.5.
///
/// Display recommendations are not authoritative segment semantics.
public struct SegmentDisplayRecommendation: Sendable, Hashable, Codable {
    public let rgba: SIMD4<Float>?
    public let opacity: Float?
    public let visibleByDefault: Bool?

    /// Creates a validated recommendation: every present colour and
    /// opacity component must be finite and within zero through one.
    ///
    /// - Throws: ``SegmentationModelError/invalidDisplayRecommendation``.
    public init(
        rgba: SIMD4<Float>?,
        opacity: Float?,
        visibleByDefault: Bool?
    ) throws {
        if let rgba {
            for index in 0..<4 {
                let component = rgba[index]
                guard component.isFinite, component >= 0, component <= 1 else {
                    throw SegmentationModelError.invalidDisplayRecommendation
                }
            }
        }
        if let opacity {
            guard opacity.isFinite, opacity >= 0, opacity <= 1 else {
                throw SegmentationModelError.invalidDisplayRecommendation
            }
        }
        self.rgba = rgba
        self.opacity = opacity
        self.visibleByDefault = visibleByDefault
    }
}

/// One segment's descriptor, per CDMS section 52.6.
public struct SegmentDescriptor: Sendable {
    public let id: SegmentID
    public let label: String
    public let category: CodedConcept?
    public let type: CodedConcept?
    public let algorithm: SegmentAlgorithmDescriptor
    public let recommendedDisplay: SegmentDisplayRecommendation?
    public let trackingIdentity: String?
    public let metadata: MetadataCollection

    /// Creates a descriptor with a non-empty label.
    ///
    /// - Throws: ``SegmentationModelError/emptyLabel``.
    public init(
        id: SegmentID,
        label: String,
        category: CodedConcept?,
        type: CodedConcept?,
        algorithm: SegmentAlgorithmDescriptor,
        recommendedDisplay: SegmentDisplayRecommendation?,
        trackingIdentity: String?,
        metadata: MetadataCollection
    ) throws {
        guard label.contains(where: { !$0.isWhitespace }) else {
            throw SegmentationModelError.emptyLabel
        }
        self.id = id
        self.label = label
        self.category = category
        self.type = type
        self.algorithm = algorithm
        self.recommendedDisplay = recommendedDisplay
        self.trackingIdentity = trackingIdentity
        self.metadata = metadata
    }
}

/// The interpretation of one segment field's samples, per CDMS
/// section 52.9.
public enum SegmentFieldInterpretation: String, Sendable, Hashable, Codable {
    case binary
    case occupancy
    case probability
}

/// One per-segment mask or fractional field, per CDMS section 52.9.
public struct SegmentField: Sendable {
    public let segmentID: SegmentID
    public let image: ImageData
    public let interpretation: SegmentFieldInterpretation
    /// The explicit inclusive numerical domain of the field's samples.
    public let domainLowerBound: Double
    public let domainUpperBound: Double
    /// The optional threshold for explicit binary conversion, inside
    /// the domain.
    public let binaryConversionThreshold: Double?

    /// Creates a field with an explicit, ordered, finite domain and an
    /// in-domain threshold when present.
    ///
    /// - Throws: ``SegmentationModelError/invalidFractionalDomain`` or
    ///   ``SegmentationModelError/invalidThreshold``.
    public init(
        segmentID: SegmentID,
        image: ImageData,
        interpretation: SegmentFieldInterpretation,
        domainLowerBound: Double,
        domainUpperBound: Double,
        binaryConversionThreshold: Double?
    ) throws {
        guard
            domainLowerBound.isFinite,
            domainUpperBound.isFinite,
            domainLowerBound < domainUpperBound
        else {
            throw SegmentationModelError.invalidFractionalDomain
        }
        if let binaryConversionThreshold {
            guard
                binaryConversionThreshold.isFinite,
                binaryConversionThreshold >= domainLowerBound,
                binaryConversionThreshold <= domainUpperBound
            else {
                throw SegmentationModelError.invalidThreshold
            }
        }
        self.segmentID = segmentID
        self.image = image
        self.interpretation = interpretation
        self.domainLowerBound = domainLowerBound
        self.domainUpperBound = domainUpperBound
        self.binaryConversionThreshold = binaryConversionThreshold
    }
}

/// The label-image representation, per CDMS section 52.8: at most one
/// segment label per sample — overlap is inexpressible here, which is
/// exactly why the collection representation exists beside it.
public struct LabelImageSegmentation: Sendable {
    public let image: ImageData
    /// The mapping from stored label value to segment identity.
    public let labelToSegment: [UInt16: SegmentID]
    /// The stored background value, mapped to no segment.
    public let backgroundValue: UInt16

    public init(
        image: ImageData,
        labelToSegment: [UInt16: SegmentID],
        backgroundValue: UInt16
    ) {
        self.image = image
        self.labelToSegment = labelToSegment
        self.backgroundValue = backgroundValue
    }
}

/// The segment-collection representation, per CDMS section 52.9: one
/// field per segment, overlap permitted by construction.
public struct SegmentCollectionSegmentation: Sendable {
    public let fields: ContiguousArray<SegmentField>

    public init(fields: ContiguousArray<SegmentField>) {
        self.fields = fields
    }
}

/// The two-case representation vocabulary, per CDMS section 52.7.
public enum SegmentationRepresentation: Sendable {
    case labelImage(LabelImageSegmentation)
    case segmentCollection(SegmentCollectionSegmentation)
}

/// The segmentation aggregate, per CDMS section 52.10, with the
/// section 52.11 invariants enforced at admission.
public struct Segmentation: Sendable {
    public let sourceSpace: CoordinateSpaceDescriptor
    public let geometry: SpatialGeometry
    public let representation: SegmentationRepresentation
    public let segments: ContiguousArray<SegmentDescriptor>
    public let provenance: ProvenanceRecord
    public let identity: DataIdentity

    /// Creates a validated segmentation.
    ///
    /// Admission enforces CDMS section 52.11: at least one declared
    /// segment; unique segment identifiers; representation references
    /// resolving to declared segments; unique label values with the
    /// background outside the mapping; and one shared sample shape
    /// across the representation's images, each matching the declared
    /// geometry where it declares its own.
    ///
    /// - Throws: ``SegmentationModelError``.
    public init(
        sourceSpace: CoordinateSpaceDescriptor,
        geometry: SpatialGeometry,
        representation: SegmentationRepresentation,
        segments: ContiguousArray<SegmentDescriptor>,
        provenance: ProvenanceRecord,
        identity: DataIdentity
    ) throws {
        guard !segments.isEmpty else {
            throw SegmentationModelError.emptySegmentation
        }
        var declared = Set<SegmentID>()
        for descriptor in segments {
            guard declared.insert(descriptor.id).inserted else {
                throw SegmentationModelError.duplicateSegmentID
            }
        }

        switch representation {
        case .labelImage(let labelImage):
            var seenValues = Set<UInt16>()
            for (value, segmentID) in labelImage.labelToSegment {
                guard value != labelImage.backgroundValue else {
                    throw SegmentationModelError.duplicateLabelValue
                }
                guard seenValues.insert(value).inserted else {
                    throw SegmentationModelError.duplicateLabelValue
                }
                guard declared.contains(segmentID) else {
                    throw SegmentationModelError.unresolvedSegmentReference
                }
            }
            try Self.checkGeometry(
                of: labelImage.image,
                against: geometry,
                sharedShape: labelImage.image.descriptor.shape
            )
        case .segmentCollection(let collection):
            guard !collection.fields.isEmpty else {
                throw SegmentationModelError.emptySegmentation
            }
            let sharedShape = collection.fields[0].image.descriptor.shape
            for field in collection.fields {
                guard declared.contains(field.segmentID) else {
                    throw SegmentationModelError.unresolvedSegmentReference
                }
                try Self.checkGeometry(
                    of: field.image,
                    against: geometry,
                    sharedShape: sharedShape
                )
            }
        }

        self.sourceSpace = sourceSpace
        self.geometry = geometry
        self.representation = representation
        self.segments = segments
        self.provenance = provenance
        self.identity = identity
    }

    /// One image's compatibility with the declared geometry: the shared
    /// shape binds every representation image, and an image declaring
    /// its own spatial geometry must agree with the aggregate's — a
    /// segmentation that disagrees with itself about where it lives is
    /// refused at the door.
    private static func checkGeometry(
        of image: ImageData,
        against geometry: SpatialGeometry,
        sharedShape: ImageShape
    ) throws {
        guard image.descriptor.shape == sharedShape else {
            throw SegmentationModelError.incompatibleGeometry
        }
        if let declared = image.descriptor.spatialGeometry {
            guard declared == geometry else {
                throw SegmentationModelError.incompatibleGeometry
            }
        }
    }
}

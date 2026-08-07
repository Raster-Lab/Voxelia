// SPDX-License-Identifier: MIT

import DICOMKit
import VoxeliaCore
import VoxeliaGeometry

/// The optional adapter capabilities of `VOX-DCM-012`, per `ADR-0378`:
/// DICOM segmentation, parametric map, surface and registration
/// integrations map to **canonical** Voxelia models through
/// conformances to these protocols — and nothing in the base import
/// path requires any of them.
///
/// Each capability takes a parsed `DataSet` and returns a canonical
/// model through that model's own throwing admission, so an adapter
/// cannot hand a host anything the canonical door would refuse. The
/// canonical modules themselves cannot import `DICOMKit` (the
/// prohibited-import gate forbids it per target), which is what keeps
/// these capabilities at the boundary and the models DICOM-free.
///
/// Conforming implementations follow the owner's outstanding DICOMKit
/// surface decision; these protocols are the boundary, not a promise
/// of readers.

/// Maps one DICOM segmentation object to the canonical model.
public protocol DICOMSegmentationCapability: Sendable {
    /// The adapter's stable identity, for provenance.
    var adapterIdentity: String { get }

    /// Maps one parsed segmentation data set. The result is the
    /// canonical `VoxeliaCore` model, spelled fully qualified because
    /// `DICOMKit` exports a `Segmentation` of its own.
    func segmentation(from dataSet: DataSet) throws -> VoxeliaCore.Segmentation
}

/// Maps one DICOM parametric map object to canonical parametric image
/// data.
public protocol DICOMParametricMapCapability: Sendable {
    /// The adapter's stable identity, for provenance.
    var adapterIdentity: String { get }

    /// Maps one parsed parametric-map data set.
    func parametricMap(from dataSet: DataSet) throws -> ImageData
}

/// Maps one DICOM surface segmentation object to the canonical mesh.
public protocol DICOMSurfaceCapability: Sendable {
    /// The adapter's stable identity, for provenance.
    var adapterIdentity: String { get }

    /// Maps one parsed surface data set.
    func surface(from dataSet: DataSet) throws -> TriangleMesh
}

/// Maps one DICOM spatial registration object to the canonical
/// transform.
public protocol DICOMRegistrationCapability: Sendable {
    /// The adapter's stable identity, for provenance.
    var adapterIdentity: String { get }

    /// Maps one parsed spatial-registration data set.
    func registrationTransform(from dataSet: DataSet) throws -> RegistrationTransform
}

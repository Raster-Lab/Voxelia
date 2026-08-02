---
document_id: "VOXELIA-REL-0.1.1-GRAPH"
title: "Voxelia v0.1.1 Package Graph"
version: "0.1.1"
status: "Static Verification"
document_type: "Package Graph"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-02"
owner: "Voxelia Project"
---

# Voxelia v0.1.1 package graph

- `VoxeliaSpatial` -> no Voxelia target dependencies
- `VoxeliaCore` -> `VoxeliaSpatial`
- `VoxeliaStorage` -> `VoxeliaCore`
- `VoxeliaExecution` -> `VoxeliaStorage`
- `VoxeliaImaging` -> `VoxeliaExecution`
- `VoxeliaGeometry` -> `VoxeliaCore`
- `VoxeliaRendering` -> `VoxeliaGeometry`, `VoxeliaImaging`
- `VoxeliaInteraction` -> `VoxeliaRendering`
- `VoxeliaCPU` -> `VoxeliaGeometry`, `VoxeliaImaging`
- `VoxeliaMetal` -> `VoxeliaExecution`, `VoxeliaRendering`
- `VoxeliaValidation` -> `VoxeliaCPU`, `VoxeliaMetal`
- `Voxelia` -> `VoxeliaCore`, `VoxeliaExecution`, `VoxeliaGeometry`, `VoxeliaImaging`, `VoxeliaInteraction`, `VoxeliaRendering`, `VoxeliaSpatial`, `VoxeliaStorage`

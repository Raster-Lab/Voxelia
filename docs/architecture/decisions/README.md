# Architecture Decision Records

Use `docs/templates/ADR-Template.md`.

The Master Technical Architecture Appendix A reserves `ADR-0001` through
`ADR-0020`. New repository ADRs begin at `ADR-0021`. Accepted `ADR-0024`
performed the one-time register reconciliation on 2026-08-04: the accepted
Apple-platform decision formerly filed as `ADR-0001` is re-identified as
`ADR-0025`, so an unqualified current reference to `ADR-0001` means the
MTA's canonical-data-model decision, while historical v0.1.1 release records
retain the former identifier. `ADR-0026` is allocated independently to the
ray/axis-aligned-bounds intersection proposal, and `ADR-0027` is allocated to
the frame-geometry anchor-index boundary proposal. `ADR-0028` is allocated to
the shared canonical-instant boundary proposal. `ADR-0029` is allocated to the
finite floating-point metadata boundary proposal. `ADR-0030` is allocated to
the owned binary metadata boundary proposal. `ADR-0031` is allocated to the
bounded recursive metadata-value boundary proposal. `ADR-0032` is allocated to
the required metadata-entry privacy-attachment proposal. `ADR-0033` is
allocated to the ordered metadata-collection and explicit multiplicity-policy
proposal. `ADR-0034` is allocated to the closed exact-case typed metadata-read
proposal. `ADR-0035` is allocated to the versioned canonical metadata JSON and
raw-ingress proposal. `ADR-0036` is allocated to the domain-separated complete
canonical metadata record-identity proposal. `ADR-0037` is allocated to the
claim-bearing data-identity and cache-admission proposal. `ADR-0038` is
allocated to the closed provenance-record and graph-admission proposal.
`ADR-0039` is allocated to the closed storage capability and descriptor
admission proposal. `ADR-0040` is allocated to the normalized logical-sample
and representation-projection proposal. `ADR-0041` is allocated to the safe
storage read-transaction and type-erasure lifetime-boundary proposal.
`ADR-0042` is allocated to the storage API name, wire and limit freeze
completing `RFC-0001` approval-order step 4. `ADR-0043` is allocated to
the spatial descriptor admission boundary. `ADR-0044` is allocated to
the persistent identifier exactness boundary. `ADR-0045` is allocated
to the integrity state claim boundary. `ADR-0046` is allocated to the
execution read coordination boundary opening milestone M2. `ADR-0047`
is allocated to the coordinated metadata identity boundary. `ADR-0048`
is allocated to single-flight read deduplication. `ADR-0049` is
allocated to the sample-bytes content projection. `ADR-0050` is
allocated to the content-tier result cache. `ADR-0051` is allocated to
the execution claim value shapes. `ADR-0052` is allocated to the
provenance warning schema. `ADR-0053` is allocated to the source
identity profile and data identity reference. `ADR-0054` is allocated
to the operation-parameters content projection. `ADR-0055` is
allocated to the derivation identity record. `ADR-0056` is allocated
to the data identity aggregate. `ADR-0057` is allocated to the
provenance claim leaf shapes. `ADR-0058` is allocated to the
provenance record aggregate. `ADR-0059` is allocated to complete
provenance graph admission. `ADR-0060` is allocated to the canonical
provenance record projection. `ADR-0061` is allocated to strict
canonical provenance ingress. `ADR-0062` is allocated to the external
provenance reference and compact graph admission. `ADR-0063` is
allocated to the image data aggregate. `ADR-0064` is allocated to the
exact region extraction operation. `ADR-0065` is allocated to the
window-level operation. `ADR-0066` is allocated to transform
composition. `ADR-0067` is allocated to the result publication
coordinator. `ADR-0068` is allocated to the window-level uint16
extension. `ADR-0069` is allocated to lookup-table composition. The
`ADR-0070` is allocated to composed chain composition. The next
`ADR-0071` is allocated to geometry-preserving region extraction.
`ADR-0072` is allocated to the canonical derivation record
projection. `ADR-0073` is allocated to strict canonical derivation
ingress. `ADR-0074` is allocated to sampling payload slicing. The
`ADR-0075` is allocated to the canonical document store. The next
`ADR-0076` is allocated to recorded fuzz and differential oracle
evidence. `ADR-0077` is allocated to the retention and enrichment
lifecycle. `ADR-0078` is allocated to the signed record manifest
contract. `ADR-0079` is allocated to the Metal execution context
boundary opening milestone M3. `ADR-0080` is allocated to the
window-level Metal kernel and differential harness. `ADR-0081` is
allocated to the Metal residency strategy. `ADR-0082` is allocated
to the rendering camera and viewport models. `ADR-0083` is allocated
to the rendering transfer function model. `ADR-0084` is allocated to
the render quality, layer and scene snapshot models. `ADR-0085` is
allocated to the render request, result and renderer protocol.
`ADR-0086` is allocated to the exact diagnostic slice renderer.
`ADR-0087` is allocated to float transform error bounds. `ADR-0088`
is allocated to the nearest-neighbour resampling operation.
`ADR-0089` is allocated to renderer viewport resampling composition.
`ADR-0090` is allocated to the layer compositing operation.
`ADR-0091` is allocated to multi-layer scene presentation.
`ADR-0092` is allocated to the GPU slice presentation path.
`ADR-0093` is allocated to the sixteen-bit device window-level paths.
`ADR-0094` is allocated to single-layer fade admission. `ADR-0095`
is allocated to canonical record archival. `ADR-0096` is allocated to
the layer compositing Metal kernel. `ADR-0097` is allocated to
end-to-end pipeline archival evidence. `ADR-0098` is allocated to the
device composite operation. `ADR-0099` is allocated to the
fully-device renderer path. `ADR-0100` is allocated to the
presentation scaling claim. `ADR-0101` is allocated to record
manifest archival. `ADR-0102` is allocated to crop presentation. `ADR-0103` is
allocated to interactive quality equivalence. `ADR-0104` is allocated
to backend policy planning. `ADR-0105` is allocated to the device
capability model. `ADR-0106` is allocated to pipeline state caching.
The next unallocated numeric identifier is `ADR-0107`.

| ID | Status | Decision |
|---|---|---|
| [ADR-0021](ADR-0021-axis-model-ownership.md) | Accepted | Axis model ownership |
| [ADR-0022](ADR-0022-coordinate-convention-shape.md) | Accepted | Coordinate convention public shape |
| [ADR-0023](ADR-0023-value-transform-shape.md) | Accepted | Value transform public shape |
| [ADR-0024](ADR-0024-decision-register-reconciliation.md) | Accepted | Architecture decision register reconciliation |
| [ADR-0025](ADR-0025-apple-ecosystem-only.md) | Accepted | Apple Silicon and Apple operating systems only (formerly ADR-0001) |
| [ADR-0026](ADR-0026-ray-axis-aligned-bounds-intersection.md) | Accepted | Ray to axis-aligned bounds intersection |
| [ADR-0027](ADR-0027-frame-geometry-anchor-index-boundary.md) | Accepted | Frame geometry anchor-index boundary |
| [ADR-0028](ADR-0028-canonical-instant-boundary.md) | Accepted | Canonical instant boundary |
| [ADR-0029](ADR-0029-finite-floating-point-metadata-boundary.md) | Accepted | Finite floating-point metadata boundary |
| [ADR-0030](ADR-0030-owned-binary-metadata-boundary.md) | Accepted | Owned binary metadata boundary |
| [ADR-0031](ADR-0031-bounded-recursive-metadata-value-boundary.md) | Accepted | Bounded recursive metadata value boundary |
| [ADR-0032](ADR-0032-required-metadata-entry-privacy-attachment.md) | Accepted | Required metadata-entry privacy attachment |
| [ADR-0033](ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md) | Accepted | Ordered metadata collection and explicit multiplicity policy |
| [ADR-0034](ADR-0034-closed-exact-case-typed-metadata-read-boundary.md) | Accepted | Closed exact-case typed metadata read boundary |
| [ADR-0035](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md) | Accepted | Versioned canonical metadata JSON and raw ingress boundary |
| [ADR-0036](ADR-0036-domain-separated-complete-canonical-metadata-record-identity.md) | Accepted | Domain-separated complete canonical metadata record identity |
| [ADR-0037](ADR-0037-claim-bearing-data-identity-and-cache-admission-boundary.md) | Accepted | Claim-bearing data identity and cache-admission boundary |
| [ADR-0038](ADR-0038-closed-provenance-record-and-graph-admission-boundary.md) | Accepted | Closed provenance record and graph admission boundary |
| [ADR-0039](ADR-0039-closed-storage-capability-and-descriptor-admission-boundary.md) | Accepted | Closed storage capability and descriptor admission boundary |
| [ADR-0040](ADR-0040-normalized-logical-sample-and-representation-projection-boundary.md) | Accepted | Normalized logical sample and representation projection boundary |
| [ADR-0041](ADR-0041-safe-storage-read-transaction-and-type-erasure-lifetime-boundary.md) | Accepted | Safe storage read transaction and type-erasure lifetime boundary |
| [ADR-0042](ADR-0042-storage-api-name-wire-and-limit-freeze.md) | Accepted | Storage API name, wire and limit freeze |
| [ADR-0043](ADR-0043-spatial-descriptor-admission-boundary.md) | Accepted | Spatial descriptor admission boundary |
| [ADR-0044](ADR-0044-persistent-identifier-exactness-boundary.md) | Accepted | Persistent identifier exactness boundary |
| [ADR-0045](ADR-0045-integrity-state-claim-boundary.md) | Accepted | Integrity state claim boundary |
| [ADR-0046](ADR-0046-execution-read-coordination-boundary.md) | Accepted | Execution read coordination boundary |
| [ADR-0047](ADR-0047-coordinated-metadata-identity-boundary.md) | Accepted | Coordinated metadata identity boundary |
| [ADR-0048](ADR-0048-single-flight-read-deduplication.md) | Accepted | Single-flight read deduplication |
| [ADR-0049](ADR-0049-sample-bytes-content-projection.md) | Accepted | Sample-bytes content projection |
| [ADR-0050](ADR-0050-content-tier-result-cache.md) | Accepted | Content-tier result cache |
| [ADR-0051](ADR-0051-execution-claim-value-shapes.md) | Accepted | Execution claim value shapes |
| [ADR-0052](ADR-0052-provenance-warning-schema.md) | Accepted | Provenance warning schema |
| [ADR-0053](ADR-0053-source-identity-and-data-identity-reference.md) | Accepted | Source identity profile and data identity reference |
| [ADR-0054](ADR-0054-operation-parameters-content-projection.md) | Accepted | Operation-parameters content projection |
| [ADR-0055](ADR-0055-derivation-identity-record.md) | Accepted | Derivation identity record |
| [ADR-0056](ADR-0056-data-identity-aggregate.md) | Accepted | Data identity aggregate |
| [ADR-0057](ADR-0057-provenance-claim-leaf-shapes.md) | Accepted | Provenance claim leaf shapes |
| [ADR-0058](ADR-0058-provenance-record-aggregate.md) | Accepted | Provenance record aggregate |
| [ADR-0059](ADR-0059-complete-graph-admission.md) | Accepted | Complete provenance graph admission |
| [ADR-0060](ADR-0060-canonical-provenance-record-projection.md) | Accepted | Canonical provenance record projection |
| [ADR-0061](ADR-0061-strict-provenance-ingress.md) | Accepted | Strict canonical provenance ingress |
| [ADR-0062](ADR-0062-external-reference-and-compact-graphs.md) | Accepted | External provenance reference and compact graph admission |
| [ADR-0063](ADR-0063-image-data-aggregate.md) | Accepted | Image data aggregate |
| [ADR-0064](ADR-0064-exact-region-extraction-operation.md) | Accepted | Exact region extraction operation |
| [ADR-0065](ADR-0065-window-level-operation.md) | Accepted | Window-level operation |
| [ADR-0066](ADR-0066-transform-composition.md) | Accepted | Transform composition |
| [ADR-0067](ADR-0067-result-publication-coordinator.md) | Accepted | Result publication coordinator |
| [ADR-0068](ADR-0068-window-level-uint16-extension.md) | Accepted | Window-level uint16 extension |
| [ADR-0069](ADR-0069-lookup-table-composition.md) | Accepted | Lookup-table composition |
| [ADR-0070](ADR-0070-composed-chain-composition.md) | Accepted | Composed chain composition |
| [ADR-0071](ADR-0071-geometry-preserving-region-extraction.md) | Accepted | Geometry-preserving region extraction |
| [ADR-0072](ADR-0072-canonical-derivation-projection.md) | Accepted | Canonical derivation record projection |
| [ADR-0073](ADR-0073-strict-derivation-ingress.md) | Accepted | Strict canonical derivation ingress |
| [ADR-0074](ADR-0074-sampling-payload-slicing.md) | Accepted | Sampling payload slicing |
| [ADR-0075](ADR-0075-canonical-document-store.md) | Accepted | Canonical document store |
| [ADR-0076](ADR-0076-recorded-fuzz-and-oracle-evidence.md) | Accepted | Recorded fuzz and differential oracle evidence |
| [ADR-0077](ADR-0077-retention-and-enrichment-lifecycle.md) | Accepted | Retention and enrichment lifecycle |
| [ADR-0078](ADR-0078-signed-record-manifest.md) | Accepted | Signed record manifest contract |
| [ADR-0079](ADR-0079-metal-execution-context-boundary.md) | Accepted | Metal execution context boundary |
| [ADR-0080](ADR-0080-window-level-metal-kernel.md) | Accepted | Window-level Metal kernel and differential harness |
| [ADR-0081](ADR-0081-metal-residency-strategy.md) | Accepted | Metal residency strategy |
| [ADR-0082](ADR-0082-rendering-camera-and-viewport.md) | Accepted | Rendering camera and viewport models |
| [ADR-0083](ADR-0083-rendering-transfer-function.md) | Accepted | Rendering transfer function model |
| [ADR-0084](ADR-0084-render-quality-layer-and-scene.md) | Accepted | Render quality, layer and scene snapshot models |
| [ADR-0085](ADR-0085-render-request-result-and-protocol.md) | Accepted | Render request, result and renderer protocol |
| [ADR-0086](ADR-0086-exact-diagnostic-slice-renderer.md) | Accepted | Exact diagnostic slice renderer |
| [ADR-0087](ADR-0087-float-transform-error-bounds.md) | Accepted | Float transform error bounds |
| [ADR-0088](ADR-0088-nearest-neighbour-resampling.md) | Accepted | Nearest-neighbour resampling operation |
| [ADR-0089](ADR-0089-renderer-viewport-resampling.md) | Accepted | Renderer viewport resampling composition |
| [ADR-0090](ADR-0090-layer-compositing-operation.md) | Accepted | Layer compositing operation |
| [ADR-0091](ADR-0091-multi-layer-scene-presentation.md) | Accepted | Multi-layer scene presentation |
| [ADR-0092](ADR-0092-gpu-slice-presentation-path.md) | Accepted | GPU slice presentation path |
| [ADR-0093](ADR-0093-sixteen-bit-device-window-level.md) | Accepted | Sixteen-bit device window-level paths |
| [ADR-0094](ADR-0094-single-layer-fade.md) | Accepted | Single-layer fade admission |
| [ADR-0095](ADR-0095-canonical-record-archival.md) | Accepted | Canonical record archival |
| [ADR-0096](ADR-0096-composite-metal-kernel.md) | Accepted | Layer compositing Metal kernel |
| [ADR-0097](ADR-0097-pipeline-archival-evidence.md) | Accepted | End-to-end pipeline archival evidence |
| [ADR-0098](ADR-0098-device-composite-operation.md) | Accepted | Device composite operation |
| [ADR-0099](ADR-0099-fully-device-renderer-path.md) | Accepted | Fully-device renderer path |
| [ADR-0100](ADR-0100-presentation-scaling-claim.md) | Accepted | Presentation scaling claim |
| [ADR-0101](ADR-0101-manifest-archival.md) | Accepted | Record manifest archival |
| [ADR-0102](ADR-0102-crop-presentation.md) | Accepted | Crop presentation |
| [ADR-0103](ADR-0103-interactive-quality-equivalence.md) | Accepted | Interactive quality equivalence |
| [ADR-0104](ADR-0104-backend-policy-planning.md) | Accepted | Backend policy planning |
| [ADR-0105](ADR-0105-device-capability-model.md) | Accepted | Device capability model |
| [ADR-0106](ADR-0106-pipeline-state-caching.md) | Accepted | Pipeline state caching |

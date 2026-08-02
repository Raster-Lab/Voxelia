# Architecture Decision Records

Use `docs/templates/ADR-Template.md`.

The Master Technical Architecture Appendix A reserves `ADR-0001` through
`ADR-0020`. New repository ADRs begin at `ADR-0021`. The scaffold currently
contains an accepted platform `ADR-0001` that conflicts with the MTA's
different `ADR-0001`. Proposed `ADR-0024` recommends a one-time reconciliation;
until it is accepted, the platform record and all live references retain their
current identifier. `ADR-0025` is held only as the proposed migration target
and is not an existing decision. `ADR-0026` is allocated independently to the
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
raw-ingress proposal. The next unallocated numeric identifier is `ADR-0036`.

| ID | Status | Decision |
|---|---|---|
| [ADR-0001](ADR-0001-apple-ecosystem-only.md) | Accepted | Apple Silicon and Apple operating systems only |
| [ADR-0021](ADR-0021-axis-model-ownership.md) | Proposed | Axis model ownership |
| [ADR-0022](ADR-0022-coordinate-convention-shape.md) | Proposed | Coordinate convention public shape |
| [ADR-0023](ADR-0023-value-transform-shape.md) | Proposed | Value transform public shape |
| [ADR-0024](ADR-0024-decision-register-reconciliation.md) | Proposed | Architecture decision register reconciliation |
| [ADR-0026](ADR-0026-ray-axis-aligned-bounds-intersection.md) | Proposed | Ray to axis-aligned bounds intersection |
| [ADR-0027](ADR-0027-frame-geometry-anchor-index-boundary.md) | Proposed | Frame geometry anchor-index boundary |
| [ADR-0028](ADR-0028-canonical-instant-boundary.md) | Proposed | Canonical instant boundary |
| [ADR-0029](ADR-0029-finite-floating-point-metadata-boundary.md) | Proposed | Finite floating-point metadata boundary |
| [ADR-0030](ADR-0030-owned-binary-metadata-boundary.md) | Proposed | Owned binary metadata boundary |
| [ADR-0031](ADR-0031-bounded-recursive-metadata-value-boundary.md) | Proposed | Bounded recursive metadata value boundary |
| [ADR-0032](ADR-0032-required-metadata-entry-privacy-attachment.md) | Proposed | Required metadata-entry privacy attachment |
| [ADR-0033](ADR-0033-ordered-metadata-collection-and-explicit-multiplicity-policy.md) | Proposed | Ordered metadata collection and explicit multiplicity policy |
| [ADR-0034](ADR-0034-closed-exact-case-typed-metadata-read-boundary.md) | Proposed | Closed exact-case typed metadata read boundary |
| [ADR-0035](ADR-0035-versioned-canonical-metadata-json-and-raw-ingress-boundary.md) | Proposed | Versioned canonical metadata JSON and raw ingress boundary |

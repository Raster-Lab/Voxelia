# Architecture Decision Records

Use `docs/templates/ADR-Template.md`.

The Master Technical Architecture Appendix A reserves `ADR-0001` through
`ADR-0020`. New repository ADRs begin at `ADR-0021`. The scaffold currently
contains an accepted platform `ADR-0001` that conflicts with the MTA's
different `ADR-0001`. Proposed `ADR-0024` recommends a one-time reconciliation;
until it is accepted, the platform record and all live references retain their
current identifier. `ADR-0025` is held only as the proposed migration target
and is not an existing decision. `ADR-0026` is allocated independently to the
ray/axis-aligned-bounds intersection proposal.

| ID | Status | Decision |
|---|---|---|
| [ADR-0001](ADR-0001-apple-ecosystem-only.md) | Accepted | Apple Silicon and Apple operating systems only |
| [ADR-0021](ADR-0021-axis-model-ownership.md) | Proposed | Axis model ownership |
| [ADR-0022](ADR-0022-coordinate-convention-shape.md) | Proposed | Coordinate convention public shape |
| [ADR-0023](ADR-0023-value-transform-shape.md) | Proposed | Value transform public shape |
| [ADR-0024](ADR-0024-decision-register-reconciliation.md) | Proposed | Architecture decision register reconciliation |
| [ADR-0026](ADR-0026-ray-axis-aligned-bounds-intersection.md) | Proposed | Ray to axis-aligned bounds intersection |

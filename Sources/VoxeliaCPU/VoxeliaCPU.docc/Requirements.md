# Requirements

The implementation shall link public behaviour and validation evidence to the
applicable `VOX-*` requirement identifiers.

The internal scalar-surface source adapter and CPU reference kernel provide
focused implementation evidence for `VOX-GEO-006`, `VOX-GEO-007`,
`VOX-EXE-002`, `VOX-EXE-006`, `VOX-ERR-001` and `VOX-SEC-001` under accepted
`ADR-0191` and `VOXELIA-ALG-0028`. This evidence covers closed scalar/source
admission, exact byte decoding and value transforms, one bounded coordinated
read, deterministic Freudenthal topology and spatial winding, checked output
limits, cancellation checkpoints and payload-free failures.

The labelled-surface source adapter and categorical reference kernel add
focused evidence for `VOX-GEO-007`, `VOX-GEO-008`, `VOX-CPU-001`,
`VOX-CPU-006`, `VOX-CON-006`, `VOX-CON-007`, `VOX-ERR-001` and `VOX-SEC-001`
under accepted `ADR-0192` and `VOXELIA-ALG-0029`. Evidence covers exact
same-domain decoding for all integer widths and byte orders, exhaustive binary,
ternary-union and shared-face differentials, one-read ownership, midpoint and
affine failure, checked output limits, fixed cancellation checkpoints, atomic
result binding and exact registry claims.

The public ``CPUScalarSurfaceExtractionOperation`` completes the accepted CPU
reference boundary by returning the immutable mesh/identity/provenance result
only after final cancellation and full binding validation. Its fixed
implementation, execution and parameter claims are registered through
``CPUBackendRegistrations``; registration does not imply diagnostic validation,
external source-graph assurance, a canonical mesh digest or host stale-result
publication.

The public ``CPULabelledSurfaceExtractionOperation`` applies the same atomic
publication discipline to the exact integer label-set union. Its parameter
digest binds the integer domain and every selected value, while the mesh carries
no label or segment attribute that could misrepresent a multi-label union.

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

These internal components do not complete scalar-surface publication. The
public immutable result, identity/provenance binding and CPU registration must
pass the separately prescribed migration-step-four evidence before the
operation is advertised as available.

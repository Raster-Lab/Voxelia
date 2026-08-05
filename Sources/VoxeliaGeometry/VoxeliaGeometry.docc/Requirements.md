# Requirements

The implementation shall link public behaviour and validation evidence to the
applicable `VOX-*` requirement identifiers.

The canonical triangle payload supplies the first implementation evidence for
`VOX-GEO-001` through `VOX-GEO-005`: position triples declare one exact
coordinate space, topology and vertex attributes remain independently owned,
indices are validated before mesh binding, and generic attributes use explicit
semantics, scalar formats and component layouts. The immutable scalar/labelled-
surface and vertex-normal request/publication values add structural evidence
for `VOX-GEO-006`, `VOX-GEO-007` and `VOX-GEO-009`. CPU extraction and normal-
generation kernels, transforms, measurements and acceleration carry the
remaining `VOX-GEO-006` through `VOX-GEO-011` obligations.

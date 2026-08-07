# Known limitations

Published per `ADR-0408`, organised by operation, format and platform.
Updated per release; the honest list, not the aspirational one.

## By operation

- **Registered image operations** admit the stored-value domain
  (`uint8`, `int16`, `uint16`, `float32`) at the ranks their
  registrations declare; other formats refuse typed.
- **Level selection and the volume operations** are version-one:
  rank-three calibrated `uint8` volumes only.
- **Deformable registration transforms** carry displacement fields but
  do not evaluate them yet; composition and quality evaluation over
  deformable transforms refuse typed.
- **Intensity-driven iterative registration** is not implemented; the
  portfolio is landmark-driven (affine and rigid), with metrics and
  pyramids prepared for a future optimiser.
- **Photorealistic rendering** uses the documented single-scattering
  approximation; optically thick interiors render darker than a full
  transport solution, and no ambient correction is applied.
- **Multi-dimensional transfer functions** use verbatim bin lookup;
  no interpolated lookup exists yet.
- **Runtime binary plug-ins** are not introduced; extension is
  source-level packages only.

## By format

- **DICOM**: the CT frame import path is the supported ingress;
  segmentation, parametric map, surface and spatial registration
  objects have adapter capability seams but no shipped readers.
- **JPEG 2000** support is limited to the approved external codec's
  decode paths.
- **Media buffers and encoding**: no CoreVideo or AVFoundation
  integration ships in the core; both arrive only through optional
  adapters.

## By platform

- **Apple Silicon (`arm64`) only**; Intel is refused at compile time.
- **Metal execution** entries are non-diagnostic by default; diagnostic
  selection requires explicit host or distribution approval, and
  registration operations have no Metal path at all.
- **Bit-exact determinism claims** are stated for the reference
  hardware (Apple Silicon, platform libm for `exp`/`log`); other
  platforms are outside the current validation envelope.

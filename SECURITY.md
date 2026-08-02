# Security Policy

## Reporting a vulnerability

Do not open a public issue for an exploitable vulnerability.

Send a private report to the security contact designated by Raster Images and
include:

- affected version or commit;
- affected platform and device;
- reproduction steps or proof of concept;
- potential impact;
- whether malformed DICOM, compressed or serialised input is involved; and
- any proposed mitigation.

The public repository shall publish the current private contact when created.
Until then, route reports through the organisation's established private
security channel.

## Sensitive information

Do not include patient-identifying information, credentials, private datasets or
production logs in reports. Use synthetic or de-identified reproductions.

## Supported releases

Before Voxelia 1.0, support is provided for the current development baseline
and explicitly designated security branches. Stable release support periods
shall be published with each release.

## Coordinated disclosure

The project will validate the report, prepare a fix, assess affected releases,
coordinate with dependency maintainers where needed, and publish an advisory
when users can reasonably remediate.

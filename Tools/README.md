# Voxelia Repository Tools

Repository tools validate package boundaries, controlled-document front matter, Apple-only platform policy, portable manifest paths, requirement identifiers, licences, shader manifests and release evidence.

All repository tools are executed on an Apple Silicon Mac with the approved Xcode toolchain.

Build all target-local DocC archives with unresolved links and other warnings treated as errors:

```bash
Tools/Scripts/build-docc.sh
```

Validate file-backed ADR metadata and identifier consistency:

```bash
python3 Tools/Scripts/check_adr_register.py
```

Validate RFC metadata, the primary register, correction companions and exact
crosswalks without conferring approval authority:

```bash
python3 Tools/Scripts/check_rfc_register.py
```

Generate the release SBOM profile, including source revision, products,
targets, licences, checksums, toolchain identity, bundled resources and
dependency classification:

```bash
Tools/Scripts/generate-sbom.sh
python3 Tools/Scripts/generate_sbom.py --validate \
    docs/releases/v0.1.1/SBOM.scaffold.generated.json
```

Manifest paths use NFC normalization plus Unicode case folding as a conservative portability policy for Apple filesystems and case-sensitive CI hosts.

After an intentional releasable-file change, regenerate the manifest, inventory and checksum ledger, review their diff, and run the read-only check:

```bash
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
Tools/Scripts/test-repository-scripts.sh
swift run --package-path Tools voxelia-repo-check --self-check
```

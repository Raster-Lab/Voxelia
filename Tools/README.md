# Voxelia Repository Tools

Repository tools validate package boundaries, controlled-document front matter, Apple-only platform policy, portable manifest paths, requirement identifiers, licences, shader manifests and release evidence.

All repository tools are executed on an Apple Silicon Mac with the approved Xcode toolchain.

Manifest paths use NFC normalization plus Unicode case folding as a conservative portability policy for Apple filesystems and case-sensitive CI hosts.

After an intentional releasable-file change, regenerate the manifest, inventory and checksum ledger, review their diff, and run the read-only check:

```bash
python3 Tools/Scripts/check_manifest_paths.py
python3 Tools/Scripts/check_release_integrity.py --write
python3 Tools/Scripts/check_release_integrity.py
Tools/Scripts/test-repository-scripts.sh
swift run --package-path Tools voxelia-repo-check --self-check
```

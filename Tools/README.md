# Voxelia Repository Tools

Repository tools validate package boundaries, controlled-document front matter, Apple-only platform policy, requirement identifiers, licences, shader manifests and release evidence.

All repository tools are executed on an Apple Silicon Mac with the approved Xcode toolchain.

```bash
Tools/Scripts/test-repository-scripts.sh
swift run --package-path Tools voxelia-repo-check --self-check
```

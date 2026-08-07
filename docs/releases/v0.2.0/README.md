# Voxelia v0.2.0 release packet

The owner's release session, in order, per `ADR-0348`. The release is complete
— per `ADR-0338` decision 11 — when every item below is done and the tag is
cut. Estimated owner time: one to two hours.

## 1. Demonstrations to witness (eight)

Launch the reference application first:

```bash
cd Examples/VoxeliaCTReference && swift run
```

| # | Row | What to observe |
|---|---|---|
| 1 | `VOX-BRK-009` | While the study-cache progress bar fills, scroll slices: the status line shows `level 1` as the source. When generation completes, it switches to `full resolution`. |
| 2 | `VOX-DVR-013` | Stop interacting: after the debounce the status line shows `idle`, and the view re-renders at full resolution — the refinement. |
| 3 | `VOX-CON-008` | During generation, scrolling stays responsive: interactive renders are never queued behind the sweep (the suite's gate evidence backs what you see). |
| 4 | `VOX-PER-006` | The first plane appears while the progress bar is still filling — the first useful image before generation completes. |
| 5 | `VOX-VS1-010` / `VOX-VS1-012` / `VOX-VS1-013` | Plane switching, slice scrolling and windowed greyscale presentation across axial, coronal and sagittal. |
| 6 | `VOX-MPR-011` | The three planes of the phantom genuinely differ and match its geometry. |
| 7 | `VOX-HLS-001` / `VOX-API-008` | The full test suite renders every pipeline in a windowless process: `swift test` — no window, view or layer exists anywhere in it. |
| 8 | `VOX-MTL-009` / `VOX-MPR-002` | The Metal slice path and oblique reconstruction run under the suite's CPU-Metal differential and oblique fixtures (`swift test --filter "MetalSliceRendererTests|ObliqueSliceOperationTests"`). |

## 2. Reviews to approve (six)

Read and approve — or return with corrections — each of:

- `docs/validation/VOXELIA-VAL-0001-*.md` — the M4 validation report (`VOX-VS1-021` R).
- `docs/benchmarks/VOXELIA-BEN-0001-*.md` and `VOXELIA-BEN-0002-*.md` — the baseline and compression benchmarks.
- `docs/benchmarks/VOXELIA-BEN-0003-frame-rate-baseline.md` — **includes the `VOX-PER-004` target standing: 30-60 fps is missed by roughly 440x on the CPU-exact path.** Accepting v0.2.0 with the target missed (and a device DVR kernel as recorded future work) is an explicit owner decision, not a default.
- The `R` halves of `VOX-VAL-006`, `VOX-ARC-009`, `VOX-DOC-009`, `VOX-DOC-011` — each record names what its review covers.

## 3. Your repository actions (two)

- Add a `LICENSE` file to `Raster-Lab/JLSwift`.
- Add a `LICENSE` file to `Raster-Lab/CompressionFamily`.

Both are your repositories, outside this working tree (`ADR-0338` decision 6).

## 4. Cut the release

Only after 1-3 are done:

```bash
Tools/Scripts/prepare-release.sh
```

Then set `VERSION` to `0.2.0`, move the changelog's `Unreleased` content under
a `## 0.2.0` heading with the date, commit, and tag `v0.2.0`.

## Standing notes

- The reference application demonstrates on the phantom (interactive level,
  refinement, priority, first-useful-image) and, launched with a series
  directory, on a real study through the accepted import session
  (`swift run VoxeliaCTReference /path/to/series`) for the multiplanar
  demonstrations. The level path stays phantom-only in this version
  (`ADR-0349` decision 2).
- This packet is an agenda, not evidence; the evidence is in the referenced
  reports and the suite.

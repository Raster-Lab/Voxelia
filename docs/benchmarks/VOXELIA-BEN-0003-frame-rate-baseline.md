---
document_id: "VOXELIA-BEN-0003"
title: "Frame rate baseline"
version: "0.1"
status: "Draft"
document_type: "Benchmark Report"
project: "Voxelia"
licence: "MIT"
language: "en-GB"
date: "2026-08-07"
owner: "Voxelia Validation"
---

# Frame rate baseline

## Objectives and the four constraints

`VOX-PER-004` requires conventional 512-cubed volume rendering to target 30-60
frames per second depending on quality profile and reference hardware
capability. `ADR-0330` fixed the four constraints a valid measurement needs,
and all four are satisfied here for the first time:

- **the named reference device** — `Mac17,4`, Apple M5, 24 GiB unified memory,
  macOS 26.5.1, named by the owner in `ADR-0338` decision 1;
- **a 512-cubed volume** — the row's own conventional case, synthesised as a
  deterministic `uint8` ramp with identity geometry;
- **a clean process** — the `voxelia-benchmark` executable (`--frames`),
  release build, running nothing else, per `ADR-0271` decision 4;
- **the quality the frames ran at** — every frame executed the accepted
  full-precision exact path (`org.voxelia.quality.full`); the quality
  *profiles* are the `ADR-0343` representation levels, labelled per
  configuration.

## Scenario

`ExactVolumeRenderer` — the CPU-exact direct-volume-rendering authority; no
device DVR kernel exists — over the published volume and its level-select
representations, orthographic camera through the volume centre, viewport
`512x512`, 256-entry ramp transfer table, no lighting, no clip, no crop, no
mask, no acceleration structure (the conventional case). The same request is
rendered for every frame of a configuration, so frame-to-frame variance is
measured on identical work. Each render performs the renderer's own budgeted
coordinated full read — the renderer holds nothing resident between frames,
and the timing honestly includes that contract.

## Results

Raw per-frame times; medians are of the listed values.

| Profile | Volume | Frames | Median frame time | Frames per second |
|---|---|---:|---:|---:|
| `level-0-512` | `512^3` (134 MiB) | 3 | 14655 ms | **0.068** |
| `level-1-256` | `256^3` (16.8 MiB) | 8 | 5151 ms | **0.194** |
| `level-2-128` | `128^3` (2.1 MiB) | 20 | 2412 ms | **0.415** |

Frame-to-frame spread is under two percent in every configuration —
negligible against the verdict's margin. Full raw values are in the scenario's
JSON output, reproducible with:

```text
cd Benchmarks && swift build -c release && ./.build/release/voxelia-benchmark --frames
```

## Verdict

**The 30-60 frames-per-second target is missed in every profile, by roughly
440x at full resolution.** This is the expected and honest result for the
version-one architecture, and the gap is attributed, not excused:

- the only volume renderer is the **CPU-exact reference path**, composing the
  accepted per-sample authorities through function calls — its purpose is
  bit-exact correctness evidence, not frame rate;
- **no Metal DVR kernel exists** (measured absence, not oversight — the Metal
  surface covers the slice pipeline);
- each frame **re-reads the full volume** through the coordinated boundary;
  residency was recorded as deliberately unbuilt;
- the run used **no acceleration structure**; the dense ramp fixture would
  not benefit from empty-space skipping regardless.

**Conditions that would reverse the conclusion**: a device DVR kernel with
resident volume textures, composed under the same claims discipline — the
recorded future work. The level profiles show the representation lever works
(6.1x from level 0 to level 2) but cannot close a 440x gap alone.

## Standing

This is a baseline and a target verdict, not a performance acceptance.
`VOX-PER-004`'s `T` is discharged by this measurement under `ADR-0346`; the
row's target standing — missed in version one, with the gap attributed — is
for the owner's release review, and the `D` half remains owner-witnessed.

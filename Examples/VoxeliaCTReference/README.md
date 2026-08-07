# Voxelia CT Reference Application

The macOS reference application per `ADR-0347`: the demonstration vehicle for
the release Demonstrations, owning lifecycle, controls, layout and the
host-side interaction clock, and duplicating no DICOM series assembly,
resampling, presentation, pixel inspection, measurement or provenance logic —
every rendered pixel comes from the accepted coordinators.

Run it with:

```bash
cd Examples/VoxeliaCTReference && swift run
```

What it shows, live:

- a banded radial phantom volume published through the accepted lifecycle;
- background **study-cache generation** at utility priority with visible
  per-brick progress (paced for human observation — the pacing is the
  application's, never the library's);
- **interactive rendering from the level-one representation while bricks
  load**, switching to full resolution when generation completes;
- plane and slice controls driving `InteractionPhase.active`, and a debounce
  into `.idle` that issues the **refinement render** — full-resolution once
  the cache is complete;
- the status line reporting the selected source, phase and pending refinement.

Launch with a DICOM series directory to view a real study through the
accepted import session under the exact geometry tolerance
(`ADR-0349`):

```bash
cd Examples/VoxeliaCTReference && swift run VoxeliaCTReference /path/to/series
```

Study mode is full-resolution multiplanar viewing; the level and
refinement demonstrations run in phantom mode, because the level path
admits the sampler's `uint8` domain. This application is not a
production application and is not regulatory evidence.

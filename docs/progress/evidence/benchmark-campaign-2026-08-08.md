# Benchmark campaign — 2026-08-08

Directed by the owner; runner:
`Tests/VoxeliaValidationTests/BenchmarkCampaignTests.swift`. Records:
`benchmark-campaign-2026-08-08.json`, schema-conformant
`ADR-0407` `BenchmarkRecord` rows (decoded through the revalidating
admission before emission).

## Environment

Mac17,4 (Apple M5), macOS 26.5.1, Apple Swift 6.3.3, Voxelia 0.2.0.

## What ran

Window-level (`org.voxelia.op.window-level` 1.5.0) over a contiguous
`int16` ramp volume of 128×128×64 samples (~1.05 M samples), full
quality, through the public operation surface with the budgeted read
coordinator — the same headless path the suite exercises.

| Mode | Latency | Throughput |
|---|---|---|
| cold-start | 172.74 ms | 6.1 M samples/s |
| warm-cache | 174.81 ms | 6.0 M samples/s |
| steady-state (median of 11) | 169.50 ms | 6.2 M samples/s |

## Modes not run

Memory-pressure, cancellation, contention and distributed modes were
not measured in this campaign; headless-batch is represented by the
full suite itself (1,460 tests, headless, ~6.5 s). Per `ADR-0407`,
"as applicable" is a declaration: this report says exactly which modes
ran. The energy measurement (`powermetrics` alongside a sustained
workload) remains available on request.

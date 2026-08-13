# Multiplayer performance budget

The first LAN release targets a stable **30 FPS** on the reference development
machine while the host simulates the guest and both cameras are active. The
automated benchmark is an acceptance gate, not a claim about every supported
machine.

## Benchmark profiles

`SARCOPHAGUS_SMOKE_TEST=multiplayer-benchmark` loads the production save
fixture and runs four deterministic phases: nearby cameras, distant cameras,
active block writes and replay of a 64-packet reconnect backlog. Every phase
runs real host/guest simulation and dense-state replication; the benchmark
scans the active camera union, publishes packets locally, renders gameplay and
measures incremental plus forced full GC work.

The gate records count, mean, p50, p95, p99 and maximum wall time for:

- gameplay update and render;
- guest simulation;
- active-world camera scan;
- active building writes and reconnect backlog replay;
- replication capture, encode and decode;
- network publication;
- full GC pause.

The thresholds live in `src/performance_budget.lua` and are split into two
explicit profiles:

- `reference` is the default real-GPU gate. The combined update and render p95
  must fit in 33.33 ms (30 FPS), memory growth must stay below 32 MiB, and each
  named phase has its own p95/p99 ceiling.
- `software-ci` is selected only by the Ubuntu/Xvfb GitHub Actions job, which
  deliberately sets `LIBGL_ALWAYS_SOFTWARE=1`. It keeps the update, simulation,
  camera, replication, network and GC limits. Rendering must still complete at
  least 120 measured frames, but llvmpipe wall time is reported rather than
  compared with a hardware FPS budget.

This separation prevents a shared runner's software rasterizer from being
mistaken for supported graphics hardware without weakening the default local
acceptance gate. An unknown profile is a test error. Incremental `gc_pause`
steps retain their p95/p99 ceiling. A separately labelled `gc_full_pause` is
deliberately forced once at the end and has a 200 ms maximum; it is not treated
as the normal per-frame GC cost.

Run the complete gate with:

```sh
./scripts/test.sh
```

The success line contains all observed percentiles and memory growth so a
regression can be compared without a profiler UI. It also records the selected
profile and renderer string.

## Release hardware pass

The old Intel Mac audit is deliberately deferred. Before declaring the LAN
release final, rerun the same benchmark and the two-machine acceptance matrix
on the oldest supported Intel Mac, recording model, macOS version, LÖVE
version, resolution, p95/p99 frame times, CPU load and peak memory. Until that
row is filled, the automated reference gate must not be described as Intel
hardware certification.

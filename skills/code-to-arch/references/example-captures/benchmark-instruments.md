# Example Capture: Benchmark / Instruments

> This is a conversation-derived seed. It intentionally over-captures candidate
> donor and API directions for later validation. Only the discussion-level
> Benchmark / Instruments boundary should be treated as accepted HITL input. All
> donor lists, type names, API shapes, and deferred topics require local repo
> validation before promotion.

This is an example capture, not architecture truth, not formal eval proof, and
not a `knowledge/cases/` entry by default.

## Example Type

- Conversation-derived seed
- Repo-docs-derived example
- Codex-summary-derived seed

## Evidence Status

- Formal orchestrator run: no / not retained
- Local repo docs validated: yes
- Upstream evidence validated: partial via local reference notes only
- HITL accepted: yes, for discussion-level scope and boundary decisions
- Architecture truth updated: already present; no new update in validation pass
- Publication-level eval proof: no

No retained `.agent/code-to-arch-distillation/benchmark-instruments/`
artifact was found in the validated `swift-benchmark` repo. This capture must
not be represented as a formal `code-to-arch` run.

## Source Inputs

- User-provided Benchmark / Instruments discussion summary.
- Codex validation summary from the local `swift-benchmark` repo.
- Local `swift-benchmark` README, AGENTS, PLAN, and `Package.swift`.
- Local `swift-benchmark` `Docs/Architecture`, `Docs/Reference`,
  `Docs/Decisions`, and `Docs/Migrations`.
- Local `swift-benchmark` `.agent` plans and upstream notes.
- Local `swift-benchmark` `Sources` and `Tests` search results.

Not available as proof in this capture:

- Retained formal `.agent/code-to-arch-distillation/benchmark-instruments/`
  artifacts.
- Fresh live upstream validation.
- Publication-level eval run evidence.

## Why This Is A Code-to-Architecture Orchestration Example

This is not generic research, implementation-only work, README cleanup, or
product writing. It shows how donor and platform evidence should be filtered
through local architecture boundaries:

```text
benchmark runner donors + Apple instrumentation donors
-> extracted measurement and instrumentation capabilities
-> rejected Signpost-first, Swift-Testing-first, and runner-policy baggage
-> local reconstruction as separate Benchmark and Instruments domains
-> HITL / docs-truth validation before promotion
```

The local validation pass found that `swift-benchmark` already encodes the core
boundary in docs, so no docs diff was needed.

## Local Goal

Capture a validated teaching example for future `code-to-arch`
runs:

- `Instruments` is the production-safe instrumentation domain.
- `Benchmark` is the runner / testing / measurement domain.
- `Signpost` is an Apple backend/adaptor inside Instruments.
- Benchmark runner policy stays outside production Instruments runtime.
- Candidate API and donor details stay scoped until local docs and upstream
  evidence justify promotion.

## Donors / Upstreams

- Donor: `ordo-one/package-benchmark`
  - Donor type: mature community implementation
  - Authority level: primary Benchmark runner donor in local reference notes
  - What to extract: runner/configuration/result discipline, metrics vocabulary,
    baselines, thresholds, CI workflow, SwiftPM command workflow, export/report
    ideas
  - What to avoid: copying donor internals, locking public API to donor-specific
    formats, moving full baseline/plugin/report complexity into Benchmark core
  - Evidence status: locally reference-backed; not freshly revalidated here

- Donor: `google/swift-benchmark`
  - Donor type: mature community implementation; ergonomics donor
  - Authority level: secondary, not core architecture authority
  - What to extract: `benchmark("Name") { ... }`, `Benchmark.main()`, filtering,
    warmup/iteration CLI feel
  - What to avoid: making global registration the architecture truth or treating
    archived runner shape as primary
  - Evidence status: locally reference-backed; not freshly revalidated here

- Donor: `coenttb/swift-testing-performance`
  - Donor type: mature community implementation; measurement/statistics and
    later Testing adapter donor
  - Authority level: adapter/reference donor
  - What to extract: duration samples, statistics, threshold/budget vocabulary,
    Swift Testing adapter UX
  - What to avoid: making Swift Testing the Benchmark core runtime
  - Evidence status: locally reference-backed; not freshly revalidated here

- Donor: `apple/swift-collections-benchmark`
  - Donor type: official package/library donor
  - Authority level: strong for `blackHole` and Scaling practice
  - What to extract: `blackHole`, input-size matrix, task/input generator,
    complexity-curve concepts
  - What to avoid: making Scaling part of Benchmark core or biasing the core
    runner toward collection-only workloads
  - Evidence status: locally reference-backed; not freshly revalidated here

- Donor: Swift official benchmark suite (`swiftlang/swift` / Apple Swift)
  - Donor type: official benchmark suite discipline donor
  - Authority level: strong for suite/regression discipline
  - What to extract: suite organization, raw sample preservation,
    current-vs-baseline comparison, environment/build metadata
  - What to avoid: copying compiler-specific build-system assumptions into a
    package-level Benchmark core
  - Evidence status: locally reference-backed; not freshly revalidated here

- Donor: SwiftNIO allocation tests and `coenttb/swift-memory-allocation`
  - Donor type: memory/allocation metrics donors
  - Authority level: later Memory-domain references
  - What to extract: allocation vocabulary, thresholds, platform caveats,
    memory regression concepts
  - What to avoid: folding Memory into wall-clock Benchmark core or production
    Instruments runtime policy
  - Evidence status: locally reference-backed; not freshly revalidated here

- Donor: Apple Instruments / Signpost / `OSSignposter` / `os_signpost`
  - Donor type: official platform/API donor
  - Authority level: strong for Apple backend behavior
  - What to extract: interval/event mapping, disabled behavior, Signpost backend
    semantics, subsystem/category/name mapping where relevant
  - What to avoid: making Signpost the public product domain or making macros
    emit Signpost semantics directly
  - Evidence status: core Signpost-as-backend boundary validated by local docs;
    live official docs not freshly revalidated here

- Donor: XCTest performance APIs
  - Donor type: official platform/API adapter reference
  - Authority level: later adapter reference
  - What to extract: XCTest performance vocabulary and metrics adapter ideas
  - What to avoid: making XCTest the Benchmark core runner
  - Evidence status: locally reference-backed; not freshly revalidated here

## Extracted Capabilities

- Runtime-safe instrumentation spans, events, recorders, attributes/context,
  timelines, fallback behavior, and platform backends.
- Signpost backend mapping under Instruments.
- Benchmark declarations, suite/case model, runner lifecycle, warmup,
  iterations, samples, measurements, statistics, and structured results.
- Result-builder-friendly Benchmark authoring over the canonical suite/case
  model.
- Future extension seams for baselines, CI gates, Report, Swift Testing, XCTest,
  Scaling, Memory/allocation, and Instruments timeline aggregation.
- Donor-led architecture planning without wholesale donor API copying.

## Extracted Semantics

Validated in local `swift-benchmark` docs:

- `Instruments` is runtime-safe instrumentation for production and test code.
- `Benchmark` is repeatable workload measurement for test, benchmark, and CI
  workflows.
- Benchmark and Instruments are separate product domains.
- Benchmark runner policy stays outside Instruments runtime and macro layers.
- Signpost is not a top-level product domain; it is the Apple backend inside
  Instruments.
- Current source/tests may still be Signpost-first drift, but local docs mark
  that as migration state, not target architecture.

Scoped as architecture direction, not implemented current behavior:

- `#span`, `#event`, `@Instrumented`, `@Span`.
- `Recorder`, `SpanToken`, `SpanAttributes`, `InMemoryRecorder`, `Timeline`.
- `BenchmarkSuite`, `BenchmarkCase` / `Benchmark`, `BenchmarkRunner`,
  `BenchmarkConfiguration`, `WarmupPolicy`, `IterationPolicy`, samples,
  measurements, statistics, `BenchmarkResult`, and `blackHole`.

Deferred / extension seams:

- Baseline file format, CI regression gate, SwiftPM command plugin, Report
  rendering, Swift Testing adapter, XCTest adapter, Scaling, Memory/allocation
  metrics, and Instruments timeline aggregation.

## Rejected Baggage

- Signpost-first public API as the whole Instruments model.
- Benchmark runner lifecycle inside production Instruments runtime.
- Warmup, iteration, sampling, statistics, baseline, and regression policy
  inside production instrumentation runtime.
- Swift Testing or XCTest as Benchmark core.
- Global benchmark registration as the only Benchmark architecture model.
- Donor public API, file layout, plugin shape, baseline format, or shell-heavy
  harness details as local architecture truth.
- Example captures as formal eval proof, architecture truth, or automatic
  `knowledge/cases/` entries.

## Local Reconstruction

The validated local reconstruction is:

```text
Instruments
  -> production-safe runtime instrumentation
  -> spans, events, recorders, timelines, Signpost backend

Benchmark
  -> repeatable workload measurement
  -> runner, warmup, iterations, samples, measurement, statistics, results
```

Benchmark may later consume Instruments timelines, but this does not make
Benchmark an instrumentation or Signpost system. Instruments may expose
Timeline/InMemory runtime data, but it must not own benchmark aggregation,
statistics, CI gates, or Report rendering.

## HITL Gates That Matter

- Gate: Scope / Goal Gate
  - Status: accepted for discussion-level boundary validation
  - Decision needed: keep this as example capture only
  - Safe default: do not implement code or create formal eval proof
  - Blocked until answered: none

- Gate: Donor Set Gate
  - Status: partial
  - Decision needed: fresh upstream validation before any publication-level or
    docs-truth promotion beyond existing local references
  - Safe default: treat donors as locally reference-backed only
  - Blocked until answered: formal donor evidence claims

- Gate: Boundary Gate
  - Status: accepted and locally validated
  - Decision needed: keep Benchmark runner policy out of Instruments runtime
  - Safe default: maintain separate Benchmark and Instruments domains
  - Blocked until answered: none

- Gate: Local Reconstruction Gate
  - Status: accepted and locally validated for the core boundary
  - Decision needed: do not over-promote candidate API/type details
  - Safe default: classify details as architecture direction or deferred seams
  - Blocked until answered: implementation claims

- Gate: Architecture Truth Gate
  - Status: already satisfied by existing local docs for the core boundary
  - Decision needed: no docs update was needed in the validation pass
  - Safe default: do not treat this example capture as architecture truth
  - Blocked until answered: none

- Gate: Docs Destination Gate
  - Status: accepted for this capture
  - Decision needed: keep this file under `references/example-captures/`
  - Safe default: do not create `.agent` artifacts or edit `Docs/Architecture`
  - Blocked until answered: none

- Gate: Case Capture Gate
  - Status: not accepted
  - Decision needed: later explicit promotion decision, if ever
  - Safe default: do not promote to `knowledge/cases/`
  - Blocked until answered: curated case promotion

## Architecture Truth Candidates

Already accepted in validated local `swift-benchmark` docs:

- `Instruments` is the production-safe instrumentation domain.
- `Benchmark` is the runner/testing/measurement domain.
- Signpost is the Apple backend/adaptor inside Instruments.
- Benchmark runner policy stays outside production Instruments runtime.
- Benchmark and Instruments are related but separate product domains.

Not architecture truth from this capture alone:

- Live upstream donor correctness.
- Current implementation availability of candidate APIs or Benchmark runtime.
- Formal run or eval quality.

## Artifact / Docs Destination

`.agent/code-to-arch-distillation/benchmark-instruments/`

No retained formal artifact was found in the validated repo. Future formal
dry-run work may use this path, but this example does not create it.

`Docs/Reference/*`

Durable donor inventories and reference-backed notes belong here in a target
repo. The validated repo already uses local reference notes for Benchmark
upstreams.

`Docs/Architecture/*`

Accepted target-repo architecture truth belongs here after HITL. The validated
repo already contains the core Benchmark / Instruments boundary.

`Docs/Decisions/*`

Accepted implementation and boundary decisions belong here when the target repo
uses decision records.

Future `knowledge/cases/*`

Do not write this capture there by default. This skill intentionally keeps no
scaffolded cases in `knowledge/`; curated cases require a separate Case Capture
Gate.

## What Still Needs Validation

- Fresh upstream evidence validation against donor repositories and official
  docs, if future work wants stronger donor claims.
- Retained formal `code-to-arch` run evidence, if future work
  wants formal run artifacts.
- Publication-level eval evidence, if future work wants eval proof.
- Implementation status after future runtime and Benchmark code changes.
- Separate Case Capture Gate before any `knowledge/cases/` promotion.

## Promotion Criteria

Before promotion to `knowledge/cases/`:

- The reusable method lesson remains clear after at least one validated run.
- Donors and authority levels are backed by current evidence.
- Extracted capabilities stay separated from rejected baggage.
- Local reconstruction remains explicit.
- HITL gates remain clear.
- Evidence status remains honest.
- The capture is not just a chat transcript or project log.
- The example teaches future agents how to run the orchestrator.
- Fresh upstream evidence or a retained formal artifact exists, if the promoted
  case would imply more than local docs validation.
- The Case Capture Gate is explicitly accepted.

## Reusable Lesson

When benchmark runner donors and platform instrumentation donors are being
aligned into one local package, use `code-to-arch` to separate
production-safe instrumentation semantics from benchmark
runner/testing/reporting policy, while avoiding Signpost-first public API,
Swift-Testing-first Benchmark core, and wholesale donor API copying.

## Follow-up Prompt / Next Action

Use this validated example capture as a teaching input for future
`code-to-arch` behavior. Do not promote it to `knowledge/cases/`
unless a later Case Capture Gate accepts promotion. For stronger evidence,
perform a fresh donor/upstream validation pass or a retained formal dry run, and
keep any resulting `.agent` artifacts separate from architecture truth.

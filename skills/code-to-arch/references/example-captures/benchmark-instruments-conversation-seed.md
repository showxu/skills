# Example Capture: Benchmark / Instruments Conversation Seed

## Example Type

- Conversation-derived seed
- User-provided discussion summary

This is not a retained formal `code-to-arch` run artifact. It is
an example-capture seed derived from accepted discussion notes for the
Benchmark / Instruments architecture topic.

## Evidence Status

- Formal orchestrator run: no
- Local repo docs validated: no
- Upstream evidence validated: no
- HITL accepted: yes, for the discussion-level scope and boundary decisions
- Architecture truth updated: no
- Publication-level eval proof: no

No retained `.agent/code-to-arch-distillation/benchmark-instruments/`
artifact should be assumed from this conversation alone. The discussion summary
must be validated against the target repo's local docs before it is treated as
architecture truth.

## Source Inputs

- User-provided discussion summary
- Prior user / assistant architecture discussion in the Benchmark /
  Instruments thread
- Donor and upstream names mentioned in the summary, unvalidated in this
  capture

Unavailable or not validated in this capture:

- Local target repo README / AGENTS
- Local target `Docs/Architecture`
- Local target `Docs/Reference`
- Local target `Docs/Proposals`
- Local target `Docs/Decisions`
- Local `.agent/code-to-arch-distillation/benchmark-instruments/`
  artifacts
- Official documentation
- Upstream repo source, tests, fixtures, and examples

## Why This Is A Code-to-Architecture Orchestration Example

This is not generic research, implementation-only work, README cleanup, or
product writing. The discussion aligns multiple benchmark, performance, and
instrumentation donors into a local architecture boundary:

```text
donor/upstream evidence
-> extracted Benchmark and Instruments capabilities / semantics
-> rejected Signpost-first and runner-policy baggage
-> local reconstruction into separate Instruments and Benchmark domains
-> HITL / docs truth flow before architecture promotion
```

The reusable method lesson is the separation of production-safe
instrumentation semantics from benchmark runner, testing, reporting, and
regression policy.

## Local Goal

Preserve the Benchmark / Instruments alignment discussion as an honest example
capture seed for future `code-to-arch` runs.

The target architecture goal is:

- Define `Instruments` as the runtime-safe instrumentation domain for
  production and test code.
- Define `Benchmark` as the repeatable workload measurement domain for test,
  bench, and CI workflows.
- Keep Signpost as an Instruments backend/adaptor, not the top-level public
  architecture model.
- Keep benchmark runner policy outside production Instruments runtime.
- Validate all discussion-derived conclusions against local docs before
  promoting them to architecture truth.

## Donors / Upstreams

- Donor: `ordo-one/package-benchmark`
  - Donor type: mature community implementation; Swift benchmark runner /
    SwiftPM benchmark infrastructure donor
  - Authority level: medium; primary runner donor in the discussion, but not
    local truth
  - What to extract: runner discipline, benchmark configuration model, metrics
    direction, baseline / threshold / CI concepts, SwiftPM command/plugin
    workflow direction, export/report ideas
  - What to avoid: copying the whole public API wholesale, pulling full
    baseline/plugin/report complexity into MVP, forcing its structure over the
    local Benchmark/Instruments domain split
  - Evidence status: discussed as primary Benchmark runner donor; local
    validation required

- Donor: `google/swift-benchmark`
  - Donor type: mature community implementation; minimal benchmark DSL /
    executable benchmark style donor
  - Authority level: medium-low; ergonomics donor, not architecture authority
  - What to extract: `benchmark("Name") { ... }` ergonomics,
    `Benchmark.main()` executable feel, simple filtering / warmup / iteration
    CLI feel
  - What to avoid: treating it as the primary architecture donor, making
    global benchmark registration the only architecture model, copying stale
    maintenance assumptions, overriding the suite/case canonical model
  - Evidence status: discussed as ergonomics donor; local validation required

- Donor: `coenttb/swift-testing-performance`
  - Donor type: mature community implementation; Swift Testing performance
    adapter and measurement/statistics donor
  - Authority level: medium; useful adapter and measurement reference
  - What to extract: declarative performance-test style, measurement /
    statistics concepts, durations/samples model, threshold / budget semantics,
    manual measurement API if useful, later Swift Testing adapter UX
  - What to avoid: making Swift Testing the Benchmark core runtime, making
    `@Test` traits the only Benchmark authoring model, binding Benchmark
    runner lifecycle to Swift Testing lifecycle
  - Evidence status: discussed as measurement/statistics and Testing adapter
    donor; local validation required

- Donor: `apple/swift-collections-benchmark`
  - Donor type: official package/library donor; scaling benchmark and
    algorithm/data-structure performance donor
  - Authority level: high for Swift collection benchmarking practice; scoped
    to scaling and anti-optimization ideas
  - What to extract: `blackHole` / anti-optimization utility, input-size
    matrix, scaling benchmark model, complexity curve concepts, series
    comparison ideas
  - What to avoid: making Scaling part of Benchmark MVP, forcing a
    collection-specific benchmark model into general Benchmark core, treating
    scaling visualization as an MVP requirement
  - Evidence status: discussed as scaling and `blackHole` donor; local
    validation required

- Donor: Swift official benchmark suite (`swiftlang/swift` / Apple Swift
  benchmark)
  - Donor type: official package/library and test/fixture donor
  - Authority level: high for compiler/runtime/stdlib benchmark discipline;
    not a package-level API model by default
  - What to extract: suite organization, baseline/result history discipline,
    current-vs-baseline comparison, environment/build metadata concepts,
    regression workflow discipline
  - What to avoid: copying compiler-specific build system, treating
    build-script or shell-heavy harness behavior as local architecture truth,
    forcing toolchain-specific assumptions into package-level Benchmark core
  - Evidence status: discussed as regression discipline donor; local validation
    required

- Donor: SwiftNIO allocation tests / benchmark practices
  - Donor type: mature community implementation; allocation regression /
    memory diagnostics practice donor
  - Authority level: medium-high for server-side Swift allocation discipline;
    later Memory-domain input only
  - What to extract: allocation count concepts, allocated bytes,
    remaining/retained allocations, zero-allocation gates, memory regression
    discipline, platform comparability caveats, diagnostic framing
  - What to avoid: moving memory/allocation work into Benchmark MVP, copying
    invasive malloc/free hook behavior into core Benchmark, turning NIO shell
    harness details into architecture truth
  - Evidence status: discussed as later Memory/allocation donor; local
    validation required

- Donor: `coenttb/swift-memory-allocation`
  - Donor type: mature community implementation; memory/allocation metrics
    donor
  - Authority level: medium; later Memory-domain reference only
  - What to extract: allocation tracking API ideas, allocation budget UX,
    memory regression concepts, possible CI usage patterns
  - What to avoid: making memory metrics part of Benchmark MVP, making
    allocation policy part of production Instruments runtime
  - Evidence status: discussed as later Memory donor; local validation required

- Donor: Apple Instruments / Signpost / `os_signpost` / `OSSignposter`
  - Donor type: official platform/API donor
  - Authority level: high for Apple platform instrumentation backend behavior
  - What to extract: interval/event mapping, Signpost backend behavior,
    subsystem/category/name mapping if relevant, disabled/fallback behavior,
    Apple Instruments vocabulary, Signpost event/interval semantics
  - What to avoid: making Signpost-first public API the whole Instruments
    model, exposing Signpost as the top-level architecture domain, moving
    Benchmark runner lifecycle into production Instruments runtime
  - Evidence status: Signpost-as-backend was accepted in discussion; local
    docs/source must validate current implementation and naming

- Donor: XCTest performance APIs
  - Donor type: official platform/API donor; testing/performance adapter
    reference
  - Authority level: high for XCTest performance vocabulary; adapter only
  - What to extract: `XCTest.measure`, `XCTMetric`, `XCTClockMetric`,
    `XCTMemoryMetric`, `XCTCPUMetric`, `XCTOSSignpostMetric`, Apple
    performance test vocabulary
  - What to avoid: making XCTest the Benchmark core, making XCTest lifecycle
    define the runner
  - Evidence status: discussed as later adapter reference; local validation
    required

## Extracted Capabilities

- Runtime-safe instrumentation spans, events, recorders, backends, attributes,
  and context.
- Signpost backend mapping under Instruments.
- Disabled/fallback recorder behavior.
- Nested and contextual span direction.
- Future Timeline and InMemory recorder direction.
- Macro and declarative instrumentation API expansion through runtime APIs.
- Benchmark declarations, suites, and cases.
- Benchmark runner lifecycle, warmup, iterations, samples, measurements,
  statistics, structured results, baselines, regression gates, and reports.
- ResultBuilder-friendly benchmark declaration DSL.
- Future Swift Testing and XCTest adapters.
- Later scaling benchmark support and memory/allocation metrics.
- Donor-led Benchmark architecture planning without copying one donor public
  API wholesale.

## Extracted Semantics

Discussion-accepted semantics, pending local validation:

- `Instruments` is the accepted public architecture direction for runtime
  instrumentation.
- `Signpost` is not the whole public model. It is an Apple backend/adaptor
  inside Instruments.
- `Instruments` and `Benchmark` are related but separate domains.
- `Instruments` owns runtime-safe instrumentation for production and test code.
- `Benchmark` owns repeatable workload measurement for test, bench, and CI
  workflows.
- Benchmark runner policy stays outside production Instruments runtime.
- Warmup, iteration, sampling, statistics, baseline comparison, regression
  gates, and benchmark runner lifecycle belong to Benchmark, not production
  Instruments runtime.
- Benchmark should be donor-led, runner-first, suite/case-based,
  ResultBuilder-friendly, and independent of Swift Testing as its core runtime.
- Swift Testing can be a later adapter, but should not define Benchmark core.

Accepted Instruments model from the discussion:

```text
Instruments
|- Span
|- Event
|- Recorder
|- Attributes / Context
|- disabled / fallback recorder behavior
|- nested / contextual span direction
|- future Timeline / InMemory recorder direction
`- Backends
   `- Signpost
```

Accepted Benchmark model direction from the discussion:

```text
Benchmark
|- BenchmarkSuite
|- BenchmarkCase / Benchmark
|- BenchmarkRunner
|- BenchmarkConfiguration
|- WarmupPolicy
|- IterationPolicy
|- BenchmarkSample
|- BenchmarkMeasurement
|- BenchmarkStatistics
|- BenchmarkResult
`- later:
   |- baselines
   |- regression gates
   |- reports
   |- Swift Testing adapter
   |- XCTest adapter
   |- Scaling
   `- Memory
```

Candidate / planned Instruments API direction, pending local validation:

```swift
#span("BuildIndex") {
    buildIndex()
}

#event("CacheMiss")

@Instrumented
func openProject() async throws -> Project {
    ...
}

@Span("BuildIndex")
func buildIndex() throws -> Index {
    ...
}
```

Candidate / planned Benchmark authoring model, pending local validation:

```swift
let suite = BenchmarkSuite("Parser") {
    Benchmark("ParseDocument") {
        try parser.parse(input)
    }
    Benchmark("Tokenize") {
        tokenizer.tokenize(input)
    }
}
```

Expected truth model from the discussion, pending local validation:

- `BenchmarkSuite` / `BenchmarkCase` is the canonical model.
- ResultBuilder DSL is the primary non-macro authoring layer.
- `@BenchmarkSuite` / `@Benchmark` is a later ergonomic macro layer.
- Global `benchmark("Name")` is optional convenience, not architecture core.
- `BenchmarkResult` is structured measured output.
- Baseline / Regression is comparison and pass/fail policy.
- Report is rendering/export/summary.

## Rejected Baggage

- Signpost-first public API as the whole Instruments model.
- Benchmark runner lifecycle inside production Instruments runtime.
- Warmup, iteration, sampling, statistics, baseline, and regression policy
  inside production instrumentation runtime.
- Copying one donor public API wholesale.
- Swift Testing as Benchmark core runtime by default.
- XCTest as Benchmark core runtime.
- Shell-heavy benchmark harness details as architecture truth.
- Finalizing baseline/report formats too early.
- Making global benchmark registration the sole architecture model.
- Treating `.agent` artifacts as architecture truth.
- Treating example capture as formal eval proof.
- Treating example capture as architecture truth.
- Promoting example capture to `knowledge/cases/` by default.
- Creating a future `code-to-arch-distiller` skill now.
- Modifying the `code-to-arch` skill during repo alignment,
  except for this explicit example-capture preservation task.
- Implementing Benchmark runner or Instruments runtime during docs/example
  capture preparation.

Deferred topics from the discussion:

- Baseline file format.
- CI regression gate.
- SwiftPM command plugin.
- Full Report rendering.
- Swift Testing adapter.
- XCTest adapter.
- Scaling benchmark.
- Memory/allocation metrics.
- Benchmark macros.
- Instruments timeline aggregation into Benchmark reports.
- Full baseline/report public API.
- Production runtime inclusion of Benchmark runner lifecycle.
- Formal `code-to-arch` eval proof generation.
- Promotion of example capture into knowledge/cases.
- Future `code-to-arch-distiller` skill creation.

## Local Reconstruction

The local reconstruction pattern is a two-domain model:

```text
Instruments =
runtime-safe instrumentation domain for production and test code.

Benchmark =
repeatable workload measurement domain for test / bench / CI workflows.
```

Instruments owns spans, events, recorders, backends, Signpost backend mapping,
attributes/context, disabled/fallback behavior, nested/contextual spans, future
Timeline/InMemory recorder direction, macro/declarative expansion through
runtime APIs, and production-safe instrumentation semantics.

Benchmark owns benchmark declarations, suite/case model, runner lifecycle,
warmup, iterations, samples, measurements, statistics, structured results,
baselines, regression gates, reports, later Swift Testing/XCTest adapters,
later scaling support, and later memory/allocation metrics.

The core boundary is:

```text
Benchmark concepts may shape the Benchmark runner/testing/reporting layer,
but must not be forced into the production Instruments runtime.
```

Future report integration can use the instrumentation layer without collapsing
the domains:

```text
Benchmark runner
-> repeatedly runs workload
-> workload emits spans/events
-> InMemoryRecorder collects timeline
-> Report aggregates per-span stats
```

That Timeline/InMemory recorder direction is planned/future and is not part of
the Benchmark MVP.

## HITL Gates That Matter

- Gate: Scope / Goal Gate
  - Status: accepted at discussion level
  - Decision needed: confirm the work is architecture alignment and optional
    example capture preparation, not runtime implementation
  - Safe default: do not implement Benchmark runner or Instruments runtime
  - Blocked until answered: local docs updates beyond example capture

- Gate: Donor Set Gate
  - Status: pending local validation
  - Decision needed: confirm the listed donors are the right local upstream set
    and whether additional local references already exist
  - Safe default: keep donors as unvalidated discussion inputs
  - Blocked until answered: durable `Docs/Reference` donor inventory

- Gate: Boundary Gate
  - Status: accepted at discussion level
  - Decision needed: keep Benchmark runner policy outside production
    Instruments runtime
  - Safe default: preserve Instruments = production-safe runtime
    instrumentation and Benchmark = runner/testing/measurement domain
  - Blocked until answered: none for this capture; local docs still need
    validation

- Gate: Local Reconstruction Gate
  - Status: pending local validation
  - Decision needed: verify the target repo docs and source agree with the
    Instruments-first public model and Benchmark/Instruments split
  - Safe default: treat this capture as a seed, not architecture truth
  - Blocked until answered: promoting candidate APIs, MVP surface, or deferred
    topics to current truth

- Gate: Architecture Truth Gate
  - Status: pending local validation
  - Decision needed: decide which statements belong in `Docs/Architecture`
    after reading local truth
  - Safe default: no architecture-truth edits from this capture alone
  - Blocked until answered: any claim that local architecture already accepts
    these boundaries

- Gate: Docs Destination Gate
  - Status: accepted direction, pending local path validation
  - Decision needed: confirm actual target repo docs structure before making
    claims or edits
  - Safe default: use `Docs/Architecture` for accepted truth,
    `Docs/Reference` for donor notes, `.agent` for execution planning, and
    `Docs/Migrations` for Signpost-to-Instruments migration if present
  - Blocked until answered: exact destination file changes

- Gate: Case Capture Gate
  - Status: pending
  - Decision needed: decide whether this example capture has durable method
    value after validation
  - Safe default: do not promote to `knowledge/cases/`
  - Blocked until answered: expanding or replacing any curated case with this
    conversation-derived seed

## Architecture Truth Candidates

These are candidates for target `Docs/Architecture` only after local validation
and required HITL gates:

- `Instruments` is the public runtime instrumentation architecture direction.
- Signpost is an Instruments backend/adaptor, not the top-level public model.
- `Instruments` and `Benchmark` are related but separate domains.
- Benchmark runner policy stays outside production Instruments runtime.
- Benchmark core is suite/case-based, runner-first, ResultBuilder-friendly, and
  independent of Swift Testing as its core runtime.
- Swift Testing and XCTest are later adapter layers.
- Baseline, regression, and report are distinct from `BenchmarkResult`.
- Timeline/InMemory recorder integration is future/planned, not Benchmark MVP.

Candidate API and type shapes requiring local validation:

- `#span`, `#event`, `@Instrumented`, and `@Span`.
- `Span`, `Event`, `Recorder`, `SpanToken`, `SpanAttributes`, `Timeline`,
  `SignpostRecorder`, `NoopRecorder`, `InMemoryRecorder`, and
  `CompositeRecorder`.
- `BenchmarkSuite`, `BenchmarkCase` / `Benchmark`, `BenchmarkBuilder` /
  ResultBuilder DSL, `BenchmarkConfiguration`, `WarmupPolicy`,
  `IterationPolicy`, `BenchmarkRunner`, `BenchmarkSample`,
  `BenchmarkMeasurement`, `BenchmarkStatistics`, and `BenchmarkResult`.

## Artifact / Docs Destination

`.agent/code-to-arch-distillation/benchmark-instruments/`

Task-scoped workflow artifacts if a future validation run is executed. This
path must not be assumed to exist from this conversation alone.

`Docs/Reference/*`

Durable donor evidence, upstream inventories, compatibility notes, and
reference summaries. Candidate destinations include Benchmark upstream
inventory and Signpost/Instruments reference notes.

`Docs/Proposals/*`

Design-in-progress if the target repo has not accepted the local
reconstruction yet.

`Docs/Architecture/*`

Accepted local architecture truth only after synthesis and required HITL gates.
Candidate target docs from the discussion:

- `Docs/Architecture/Instruments.md`
- `Docs/Architecture/Benchmark.md`
- `Docs/Architecture/ProductDomains.md`

`Docs/Decisions/*`

Accepted architectural decisions and tradeoff records if the repo uses decision
records.

`Docs/Migrations/*`

Signpost-to-Instruments semantic migration notes if the target repo has that
docs area. Candidate target:

- `Docs/Migrations/Signpost-To-Instruments.md`

Future `knowledge/cases/*`

Curated reusable skill cases only after explicit promotion. This skill
intentionally keeps no scaffolded cases in `knowledge/`; this capture should
not be promoted by default.

## What Still Needs Validation

- Verify whether local `Docs/Architecture/Instruments.md` states the
  Instruments production runtime boundary.
- Verify whether local `Docs/Architecture/Instruments.md` states that Signpost
  is a backend/adaptor inside Instruments.
- Verify whether local `Docs/Architecture/Instruments.md` avoids
  Signpost-first public API as the whole model.
- Verify whether local `Docs/Architecture/Benchmark.md` keeps Benchmark runner
  policy outside Instruments runtime.
- Verify whether local `Docs/Architecture/Benchmark.md` states Benchmark as a
  runner/testing/measurement domain.
- Verify whether local `Docs/Architecture/ProductDomains.md` aligns Benchmark
  and Instruments as separate domains.
- Verify whether local donor notes exist in `Docs/Reference`, especially
  Benchmark upstream inventory.
- Verify whether `.agent` plans contain execution detail that has not been
  promoted to architecture truth.
- Verify whether candidate API examples are accepted in docs or only
  proposed/planned.
- Verify whether deferred topics are clearly marked as deferred.
- Verify whether any local docs still describe the package as only a Signpost
  macro wrapper.
- Verify whether existing README/AGENTS route future agents toward the correct
  current architecture truth.
- Verify whether any target-repo example capture artifact already exists before
  creating a new one.

## Promotion Criteria

Before this example can be promoted to `knowledge/cases/`:

- Reusable method lesson is clear.
- Donors and authority levels are clear.
- Extracted capabilities are separated from rejected baggage.
- Local reconstruction is explicit.
- HITL gates are clear.
- Evidence status is honest.
- The example is not merely a chat transcript or project log.
- The example teaches future agents how to run the orchestrator.
- Local target repo docs have been validated.
- Upstream donor evidence has been validated or explicitly scoped as reference
  only.
- The Case Capture Gate is accepted.

## Reusable Lesson

When benchmark runner donors and platform instrumentation donors are being
aligned into one local architecture, use `code-to-arch` to
separate production-safe instrumentation semantics from benchmark
runner/testing/reporting policy, while avoiding Signpost-first public API,
Swift-Testing-first Benchmark core, and wholesale donor API copying.

## Follow-up Prompt / Next Action

Validate this conversation-derived Benchmark / Instruments example capture
against the target repo before treating it as architecture truth. Read local
README/AGENTS, `Docs/Architecture/Instruments.md`,
`Docs/Architecture/Benchmark.md`, `Docs/Architecture/ProductDomains.md`,
`Docs/Reference`, `Docs/Migrations`, and any
`.agent/code-to-arch-distillation/benchmark-instruments/` artifacts.
Confirm whether Instruments is documented as the production-safe runtime
instrumentation domain, Signpost as an Instruments backend/adaptor, and
Benchmark as the runner/testing/measurement domain. Keep Benchmark runner
policy out of production Instruments runtime, record donor evidence in
`Docs/Reference`, update `Docs/Architecture` only after the Architecture Truth
Gate, and do not promote this example to `knowledge/cases/` without the Case
Capture Gate.

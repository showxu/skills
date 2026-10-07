# Codex Research Prompt: <Topic>

You are researching upstream and donor sources to support Code-to-Architecture
Distillation for <local project/module>.

Do not implement code unless explicitly requested. Produce a research and
architecture recommendation only.
When multiple donor categories are involved, collect per-source findings first
and then synthesize. Do not treat subagent findings as architecture truth.

## Required Read-First Workflow

1. Inspect local docs first: <local docs / paths>.
2. Inspect current local APIs, modules, tests, and boundaries: <paths>.
3. Inspect upstream/reference repos and official sources: <upstreams>.
4. Classify each donor using these categories: official platform/API donor,
   official package/library donor, mature community implementation, product/UX
   donor, protocol/API donor, test/fixture donor, naming/documentation donor,
   anti-pattern donor.
5. For multiple clearly scoped donor/source questions, use subagent mode by
   default when the host allows it. Assign focused evidence tasks and require
   findings only. The main agent owns synthesis.

## Required Analysis

- Local truth summary with file paths.
- Donor classification and why each donor matters.
- Extracted capabilities, semantics, API shapes, tests, UX patterns, naming,
  and architecture boundaries.
- Rejected baggage: product coupling, implementation-specific assumptions,
  file-layout inertia, dependency baggage, test harness assumptions, and
  upstream naming that does not clarify local concepts.
- Recommended local framework reconstruction.
- Per-source findings and main-agent synthesis.
- Phase / stage judgment.
- Risks, non-goals, and open questions.
- HITL gate questions when boundary or architecture truth decisions are needed.

## Evidence Requirements

- Cite local file paths.
- Cite upstream evidence with repo/path, docs links, release tags, or commit
  identifiers when available.
- Separate facts from inferences.

## Output

Return a compact upstream intake report and a recommended next Codex prompt.

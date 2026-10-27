# Evidence

## Source Classes

Primary sources can justify a finding when the relevant claim is checked
against their current version:

- official product, platform, API, SDK and host documentation;
- current help, schemas and manifests of the installed tool;
- SDK declarations and compiler diagnostics;
- observed behavior from a small local probe, build, test or eval.

Secondary sources only raise questions: curated lists, community articles and
examples, other authors' skills, trend reports. Turn each into a question and
answer it from a primary source before it changes a trigger, workflow,
validation rule, API claim or safety rule.

Do not copy external documentation into skills; keep links, the source
hierarchy and the distilled local rules.

A skill that stores mutable external facts should name its sources in a
source map (`references/*sources*.md`, `*authority*.md`, `*freshness*.md` or
an extractor script). Each entry names the source (URL, command, schema path
or probe), its class, the local claim or file that depends on it, the
verification method and its known failure mode, and a last-checked date only
when the check actually ran. `scripts/collect_sources.py` lists the declared
sources of exact skills; listing a source is not checking it. For vendored skills and
shared instruction sources, an agent tool that tracks upstream sources (for
example `agents watch status` and `agents watch diff`) shows what changed
since they were last reviewed. Propose a source map
before a broad fact refresh of a skill without one.

## Vendor Guidance

Treat OpenAI, Anthropic, Apple, Swift and other vendors' guidance as evidence
to inspect, not as replacement policy. Record the URL or supplied excerpt,
publisher, date, the concrete recommendation, its model, host or platform
conditions, and the local artifact it could improve. Mark an excerpt as an
excerpt until the full current page is checked.

When vendors recommend different techniques, check whether their hosts,
models, task sizes or tools differ, and keep each recommendation with its
conditions. One host's loading behavior does not establish another's; inspect
the rendered input or probe the host before claiming loss or truncation. A
newer model's prompting advice does not remove provenance, permission or
acceptance obligations.

## Platform and Version Evidence

Keep compiler, language mode, SDK declarations, deployment targets, compiled
examples and runtime behavior apart. A declaration that compiles is not
evidence of UI lifecycle, performance, device, permission, network or model
behavior. Keep old-system branches the project still targets.

## Usage Evidence

`scripts/usage_counts.py` counts, per skill and host over a stated window,
uses and maintenance sessions (work inside the collection's own repository)
separately, without reading message content. Report the window and the
counting method it prints; judge use from the uses column. Low counts for
seasonal tasks are not evidence of no value.

## Past Sessions as Eval Sources

Past sessions show how an earlier model behaved, so they never settle whether
the current model still needs an item; the current-model run does. Their use
is to supply realistic eval cases:

- Read session content only when the user allows it, summaries before raw
  sessions, narrowed to the scope's repository and to explicit terms such as
  skill names, commands or failure text.
- Turn concrete failures into eval cases, first those that repeated across
  independent tasks, that made agents rediscover the same path, boundary or
  tool sequence, or where actual work contradicted a trigger or validation
  rule. A single concrete boundary or validation failure is also a valid
  case. Broad topics and generic capability are not cases.
- A case shows what to test; only the current-model run supports a change.
- Use real request wording for trigger-eval prompts. Remove personal and
  confidential content before a case is stored.
- A past failure that no longer reproduces on the current model is evidence
  for Simplify or Retire only through the with/without comparison.

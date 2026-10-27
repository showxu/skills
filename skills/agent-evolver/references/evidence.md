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
an extractor script). `scripts/collect_sources.py` lists the declared sources
of exact skills; listing a source is not checking it. For vendored skills and
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

## Usage and Experience Evidence

Local session logs show which items are used and where agents struggle. Read
them only within the scope the user granted: by default, counts and file
references, not message content.

- `scripts/usage_counts.py` counts, per skill and host over a stated window,
  uses and maintenance sessions (work inside the collection's own repository)
  separately. Report the window and the counting method it prints; judge use
  from the uses column. Low counts for seasonal tasks are not evidence of no
  value.
- Narrow any content search to the scope's repository first, then to explicit
  terms such as skill names, commands or failure text. Label cross-repository
  matches as broad evidence.

Strong evidence: the same failure after independent tasks; agents repeatedly
rediscovering the same path, boundary or tool sequence; triggers or validation
rules contradicted by actual work; the same output shape produced repeatedly.

Weak evidence: a one-off bug, a broad topic, a single TODO, a speculative idea,
or generic capability with no project-specific process or failure.

An experience signal can raise a source question; it does not verify an
external fact.

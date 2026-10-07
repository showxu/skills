---
name: design-md-template
description: Select, apply, review, include, or refresh a project DESIGN.md from the local DESIGN.md template collection. Use when the user wants an agent-readable visual identity file, asks to make a project look like a known template, or needs a DESIGN.md handoff for implementation. Do not use for interaction-flow critique, SF Symbols asset export, frontend implementation, live design-tool edits, or untracked brand scraping.
---

# DESIGN.md Template

## Purpose

Use this skill to review, include, and apply templates from this collection's
local `DESIGN.md` template set. The skill owns template selection, provenance,
local template files, adaptation boundaries, validation, and handoff notes.

## When To Use

- Create or update a project-root `DESIGN.md`.
- Review a template path from the tracked catalog for local inclusion.
- Include an approved `DESIGN.md` in this skill's template collection.
- Apply an included `DESIGN.md` template to the current project.
- Review whether an existing `DESIGN.md` still matches its tracked source.
- Prepare a design-system handoff for an implementation agent.

## When Not To Use

- Task-flow, IA, form, navigation, prototype, or usability critique.
- SF Symbols export or skill icon asset generation.
- Frontend, SwiftUI, UIKit, Android, or web implementation work.
- Generating a new brand identity without a template or source artifact.
- Scraping or inferring a private, live, or untracked brand system.
- Reverse engineering a new `DESIGN.md` from screenshots, screen recordings,
  URLs, CSS, Figma files, or design-system notes. That evidence-to-template
  workflow needs a separate intake/distillation pass before this skill can
  include or apply the resulting reviewed template.

## Inputs To Inspect

- Target project root and whether it already has `DESIGN.md`.
- User-selected template name, source URL, or desired visual category.
- Root `upstreams.yaml` before refreshing or changing source state. This is
  the source of truth for reviewed, included, and unreviewed upstream paths.
- Local included templates under `templates/<template-id>/DESIGN.md`.
- Current `DESIGN.md` external spec only when validation or format details
  matter.
- `apple-design-resource` catalog only when an Apple-platform template needs
  official Apple resource URLs, Product Bezels, fonts, UI kits, SF Symbols app
  links, or downloadable design assets as supporting evidence.

## Workflow

1. Identify the target project root and inspect any existing `DESIGN.md`.
2. Resolve included templates from integrated review segments in root
   `upstreams.yaml`. Use each segment's local template id and local template
   path when present; source paths remain upstream provenance.
   For unreviewed upstream candidates, the source path convention is
   `design-md/<source-id>/DESIGN.md`.
3. If the template path is not represented by an integrated review segment and
   no local template exists, treat it as unreviewed. Review that source
   path first and include it only when the user or collection decision says it
   is wanted locally.
4. When including a template, add the reviewed `DESIGN.md` to
   `templates/<template-id>/DESIGN.md` without rewriting its design content,
   then update root `upstreams.yaml` with the included path segment and
   remaining open item count.
5. Apply only `included` templates to a project unless the user explicitly asks
   to review and include a new path in the same task.
6. If the user asked for an exact project template, apply the included
   `DESIGN.md` without rewriting its content.
7. If the user asked to adapt it to the current project, preserve the upstream
   as the source and make only project-specific changes that are justified by
   supplied product context.
8. Do not silently overwrite an existing `DESIGN.md`; show whether the action
   is create, replace, or adapt.
9. For Apple-platform templates that need official Apple resource facts, call
   `apple-design-resource` and pass back resource links or asset paths as
   supporting references, not as template-selection authority.
10. Validate the resulting file when practical.
11. Report the template id, upstream path, local template path, locked commit,
    target file, and whether the result is exact or adapted.

## Reference Files To Consult

This skill intentionally has no skill-local catalog reference. Use root
`upstreams.yaml` for upstream review state and the local `templates/` directory
for included template files. Do not maintain a second review ledger inside the
skill.

## Decision Rules

- Strict tracking wins: a template from the upstream catalog must remain
  traceable to upstream repo, commit, upstream path, local path, and review
  state in root `upstreams.yaml`.
- Unreviewed paths stay represented by the upstream source and open item count.
  Do not mark them ignored just because they are not needed in the current task.
- `included` means the path was explicitly reviewed as wanted and added to
  this skill's local template collection.
- Prefer exact application when the user names a specific template or brand
  style.
- Adapt only when the user asks for project-specific changes or the current
  project constraints make exact application unsuitable.
- Keep provenance in the response or handoff note. Do not add local source
  comments to the applied `DESIGN.md` unless the project already uses that
  convention or the user requests it.
- Do not promote untracked third-party examples into this collection. Register or
  review the source first.
- Do not treat a template as legal permission to reproduce protected branding.

## Validation Rules

- `DESIGN.md` exists at the target project root after create or replace.
- The selected template id resolves to an included local template or a tracked
  upstream review path.
- Applied templates are already `included` and have a local `DESIGN.md`.
- Exact mode does not rewrite template content.
- Adapted mode keeps a clear source path and commit in the handoff.
- If available, run `npx @google/design.md lint DESIGN.md` from the target
  project. If unavailable, at minimum inspect frontmatter fences and major
  section headings.

## Output Format

```text
DESIGN.md Template

Template:
- id:
- upstream path:
- local path:
- upstream commit:

Target:
- file:
- mode: exact | adapted

Validation:
- ...

Handoff:
- ...
```

## Failure / Uncertainty Handling

- If the template name is ambiguous, list the closest tracked ids and ask for a
  selection.
- If the selected template is still `unreviewed`, ask whether to review and
  include that path before applying it.
- If the upstream file cannot be read, report the locked raw URL and do not
  substitute branch HEAD silently.
- If the current project already has a `DESIGN.md` and the user did not ask to
  replace it, produce an adaptation plan or diff-oriented recommendation first.
- If the user wants a template outside the tracked catalog, treat it as a new
  upstream/source review question before applying it as a canonical template.

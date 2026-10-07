---
name: app-store-whats-new
description: Draft App Store What's New text from git tags, commits, pull requests, release notes, bullets, or free text. Use for user-visible version notes and changelog filtering. Do not use for ASO, screenshot marketing, live App Store Connect edits, market messaging, or broad product marketing.
---

# App Store What's New

## Purpose

Create user-facing App Store What's New text from release evidence. The skill
turns commits, tags, PRs, rough bullets, or free text into concise version notes
that map back to real user-visible changes.

## When To Use

- The user asks for App Store What's New text, version notes, release notes, or
  a changelog for an app update.
- The source is git history, tags, pull requests, an existing changelog, rough
  bullets, or conversational release notes.
- The output should be user-facing copy, not engineering release notes.

## When Not To Use

- ASO, keyword strategy, or conversion review; use `app-store-aso`.
- Screenshot storytelling and assets; use `app-store-screenshots`.
- Interface strings inside the app.
- Live App Store Connect metadata edits or uploads.
- First-version launch copy unless the user explicitly wants launch notes; Apple
  does not use the What's New field for the first app version.
- Legal, privacy, medical, financial, or regulated claims without source
  evidence and explicit user approval.

## Inputs To Inspect

Use only the inputs relevant to the request:

- Git range, latest tag, commit log, PR list, issue list, changelog, or release
  notes.
- Touched files when commit messages are too vague.
- User-provided bullets or free text.
- Product context: app name, version, target audience, tone, and locale.
- Existing App Store metadata only when the user provides it or asks for local
  consistency.

## Workflow

1. Determine the source range and input mode.
   - If the user provides a range, use it.
   - If not, infer the latest tag with `git describe --tags --abbrev=0`.
   - If no tag exists, tell the user that the script will use full history.
2. Collect evidence.
   - Prefer `scripts/collect_release_changes.sh` for local git repositories.
   - For PR-based releases, use PR titles, merged dates, labels, and linked
     issues when available.
3. Triage for user impact.
   - Include user-visible features, UI changes, behavior changes, bug fixes,
     performance improvements with visible impact, accessibility improvements,
     localization changes, and reliability fixes users would notice.
   - Drop refactors, CI, dependencies, formatting, build scripts, internal
     logging, test-only work, and developer tooling unless they changed user
     behavior.
4. Group and draft.
   - Prefer `New`, `Improved`, and `Fixed` groups when there are enough items.
   - For smaller releases, use a flat bullet list.
   - Keep each bullet one sentence and benefit-focused.
5. Validate.
   - Every bullet must map back to release evidence or explicit user input.
   - Remove duplicates and internal jargon.
   - Keep under Apple's 4000-character limit.
   - Mark ambiguous bullets as needing confirmation instead of inventing
     impact.
6. If localization is requested, draft the primary locale first, get approval,
   then adapt per locale. Do not literal-translate idioms or overrun the field
   limit.

## Reference Files To Consult

- `references/_index.md`: reference map.
- `references/apple-field-notes.md`: Apple's What's New field boundary and
  related metadata limits.
- `references/evidence-filtering.md`: commit and PR filtering rules.
- `references/writing-guidelines.md`: tone, grouping, examples, and QA.
- `references/localization.md`: locale adaptation and length rules.

## Safety / Confirmation Rules

- Do not upload, edit, or submit metadata in App Store Connect from this skill.
- Ask before making claims about awards, certifications, compliance, medical or
  financial outcomes, privacy posture, security guarantees, or support
  commitments.
- If a commit says only "fix bug" or "update flow", inspect files or ask for
  context before writing a user-facing claim.
- If the release has no clear user-visible changes, say so and offer a modest
  maintenance note only when appropriate.

## Decision Rules

- Prefer specific user outcomes over implementation details.
- Use plain words: "Fixed a login issue" beats "Resolved token refresh race".
- Do not mention internal modules, ticket IDs, branch names, file paths, CI,
  dependencies, or refactors.
- Do not keyword-stuff. What's New is for people reading the update notes.
- Keep the first bullet strongest because it is most likely to be seen.

## Output Format

For ordinary requests, return:

```text
What's New

- ...
- ...

Evidence notes:
- Bullet 1: commit/PR/source
- Bullet 2: commit/PR/source

Needs confirmation:
- ...
```

If the user asks for App Store-ready text only, provide only the final text and
character count.

## Failure / Uncertainty Handling

- If git history is unavailable, ask for bullets or a release summary.
- If there are no tags, state the exact fallback range used.
- If evidence conflicts, prefer the source closest to the release owner and
  label the uncertainty.
- If the text exceeds 4000 characters, shorten by merging related bullets before
  cutting detail.

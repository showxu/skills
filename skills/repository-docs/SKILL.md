---
name: repository-docs
description: Create, audit, and normalize repository documentation roles across apps, libraries, tools, plugins, skill collections, and workspaces. Use when writing or reviewing AGENTS.md, Code Review Rules for automatic pull request review, tool entry files such as CLAUDE.md, README files, documentation indexes, architecture placement, duplicated instructions, conflicting document authority, or documentation templates. Produces evidence-backed audits, minimal relocation plans, and authorized documentation changes. Preserves public installation and usage guidance, concise agent edit guardrails, repository conventions, and existing Git state. Does not own product requirements, architecture redesign, runtime implementation, build or release automation, or general skill workflow redesign.
---

# Repository Docs

## Purpose

Create and maintain repository documentation with one clear owner for each
fact, instruction, and reference. The same rules apply to new documents,
existing-document audits, and templates that produce repository documents.

## Read Route

- Follow the target's applicable agent instructions and declared read-first
  order. Read its root README and the relevant documentation indexes and
  architecture contracts before classifying content.
- Read [Route vs Index](rules/route-vs-index.md) for every documentation-role
  task. Read [README Layering](rules/readme-layering.md) when a README or a
  document index is involved. Read [Code Review Rules](rules/code-review-rules.md)
  when review rules, a reviewer's setup, or a tool entry file such as
  CLAUDE.md or REVIEW.md is involved.
- For changes to this skill, read
  [Maintenance Architecture](references/architecture.md) and the affected
  cases in [Eval Fixtures](references/eval-fixtures.md).

## Owned Work

- Write or review AGENTS guides and their Code Review Rules, tool entry files,
  repository landing manuals, directory indexes, and links to current
  architecture and reference material.
- Audit duplication, misplaced content, contradictory statements, missing
  entry files, and templates that generate those problems.
- Move already-established facts to their documentation owner and preserve
  their meaning. Architecture decisions, runtime behavior, tool interfaces,
  and skill workflow semantics remain with their respective owners.

## Workflow

1. **Set scope and authorization.** Use exact named repositories, documents,
   or templates. An audit request is read-only; a revision request authorizes
   its stated changes. Keep an explicitly requested report or approval gate.
2. **Establish the baseline.** Record present and missing entry files, line
   counts, relevant working-tree changes, and staged state. Inspect only the
   declared scope; skip agent state, caches, dependencies, generated checkouts,
   archives, and scratch unless the user names an exact necessary artifact.
3. **Classify by purpose.** Distinguish agent route, edit guardrail, reader
   manual, index, current architecture, reference, history, and task state.
   Split mixed paragraphs. A heading, keyword, ownership mention, or length
   alone does not determine the class.
4. **Find the owner and evidence.** Compare duplicates by meaning. Resolve
   conflicts using the declared authority and relevant source, manifest,
   configuration, or implementation. Report uncertain facts without inventing
   an answer. Inspect a known template producer when generated text is wrong.
5. **Choose the smallest correction.** Keep a correct canonical copy, replace
   other copies with useful links, and move unique content to an existing
   appropriate document. Create a minimal missing entry only when needed and
   authorized. Preserve directory conventions, repository boundaries,
   attribution, current safety rules, and public installation and usage.
6. **Apply authorized changes.** Re-read affected files before editing and
   build on existing changes. A concurrent change pauses only that affected
   edit. Keep the index untouched. Correct owned templates together with their
   affected outputs when both are in scope.
7. **Verify and hand off.** Check changed links, actual command entry points,
   fact consistency, meaningful content preservation, template/output
   agreement, and appropriate repository checks. Report remaining gaps and
   final Git state; do not claim an unrun semantic check passed.

Stop for a real unresolved authority, factual, or scope conflict that changes
the proposed result. Routine placement decisions use the rules directly.

## Audit Output

For each scoped repository, report:

- AGENTS and README line counts, missing files, and relevant uncommitted or
  staged files.
- Findings with file and line ranges, content class, supporting evidence,
  and contradictions between documents.
- The smallest fix: destination of unique content, canonical copy retained,
  duplicate deleted, and links or producer updates required.

Rank repositories by the amount of confirmed misplaced or duplicated content,
counting overlapping ranges once. Separate unresolved candidates from that
ranking. A compliant repository remains in the report with a no-change result.

For implementation, describe the resulting document responsibilities, checks
actually run, and unresolved facts. Keep execution logs, local paths, and
review iterations with the task; active repository docs express the accepted
current result.

## External Guidance

The tool-specific parts of the rules follow the vendors' own documentation:

- OpenAI: [Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md),
  [Codex code review in GitHub](https://learn.chatgpt.com/docs/third-party/github),
  [Custom code review rules for Codex](https://developers.openai.com/blog/custom-code-review-rules-for-codex).
- Anthropic: [Claude Code memory and AGENTS.md](https://code.claude.com/docs/en/memory),
  [Claude Code Review](https://code.claude.com/docs/en/code-review).

Recheck these pages when a rule depends on a tool version or file name.

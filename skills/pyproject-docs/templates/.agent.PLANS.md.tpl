# Documentation Plan

## Task State

- Status: proposed
- Owner: TBD
- Last update: TBD
- Current next action: classify documentation roles
- Stop reason: waiting for review

## Goal

Normalize Python project documentation into the canonical `pyproject-docs`
role model with lowercase `docs/` paths.

## Context

- Project fact source: `pyproject.toml`
- Canonical docs root: `docs/`
- Temporary execution state: `.agent/`

## Steps

1. Audit root docs, `pyproject.toml`, package layout, tests, generated outputs,
   and current docs trees.
2. Classify each document by role.
3. Move or rewrite non-canonical docs into `docs/*`.
4. Update README and AGENTS route boundaries.
5. Validate links, commands, generated-output boundaries, and architecture
   truth.

## Validation

```bash
<lint-command>
<test-command>
```

# Helpers

Both helpers use only the Python standard library and print JSON with `--json`.

## collect_sources.py

Lists the declared source references of exact skills in a repository:

```bash
python3 scripts/collect_sources.py --root <repository> --skill <name> --json
```

Repeat `--skill` for several targets. `--term` is fuzzy discovery only. The
output lists source locations; checking them is the audit's work.

## usage_counts.py

Counts, per skill in a collection, how often each host used it over a window:

```bash
python3 scripts/usage_counts.py --skills-root <repository>/skills --since <YYYY-MM-DD> --json
```

- Skill names come from each `<skills-root>/*/SKILL.md` frontmatter `name`.
- Codex: a session counts once for a skill when a tool call's arguments
  mention a path ending in `/<name>/SKILL.md`; user-input and plan tools are
  ignored, and a mention without a read can still count. Rollouts are read
  from `--codex-home` (default `$CODEX_HOME` or `~/.codex`): `sessions/` and
  `archived_sessions/`.
- Claude Code: each `Skill` tool call naming the skill counts once, with or
  without a plugin prefix. Transcripts are read from `--claude-projects`
  (default `~/.claude/projects`), including subagent transcripts.
- Work inside the Git repository that contains `--skills-root` counts as
  `maintenance`: its main checkout and every worktree of it, matched through
  the shared Git directory. A nested repository or submodule is a different
  repository. Everything else counts as `uses`, including worktrees outside
  the main checkout that no longer exist.
- Only events at or after `--since` and before the optional `--until` count.
  Both accept ISO dates or times; dates and times without a timezone use UTC.
- The output has the window, per-skill `uses` and `maintenance` per host,
  totals, the counting method and its limits, the number of files read, and
  files that could not be parsed. It never prints message content.

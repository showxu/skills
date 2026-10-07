# Validation

Use the target repository's declared checks first. For skill readiness,
trigger hardening, and multi-skill review, use `skills/skill-creator/`.

## Minimum Checks

- each skill directory has `SKILL.md`
- `SKILL.md` frontmatter has `name` and `description`
- frontmatter `name` matches directory name
- marketplace skill paths point to existing skill directories
- published skills have manual entry metadata when the repo expects it
- README, AGENTS, and docs do not point to stale paths

## Suggested Commands For This Monorepo

```bash
python3 -B scripts/check_repository.py
git diff --check
```

The repository check validates the committed publication surface, skill
packages, marketplace paths and shared versions. Run it from a clean candidate
checkout. `--commit <revision>` checks only the publication surface of a
specific commit, including files that Git would otherwise ignore.

Source policy checks signatures, identities and attribution for the event's
actual commit range. GitHub settings and required check names are declared in
the root `MAINTENANCE.md`.

## Failure Handling

- Treat command failures as hard blockers.
- If checks disagree with documented shape, update the root docs or owning
  check before normalizing individual collections by hand.
- If a linked checkout is involved, run write-capable follow-ups at the real
  source path, not through a taxonomy symlink.

# Single-Skill Validation

Use this reference before presenting, syncing, installing, or packaging one
skill as ready.

This validator is a local preflight. It does not replace Anthropic eval
evidence, human review, or additional validation required by the owning
host or package workflow.

## Command

```bash
python3 <skill-creator>/scripts/validate_skill_package.py <skill-dir>
```

Use `--package-mode` before creating a distributable artifact or copying the
skill to another host.

The validator checks:

- skill directory exists
- `SKILL.md` exists
- frontmatter is present and parseable
- frontmatter keys stay within the source package validator allowlist
- `name` exists, follows source kebab-case limits, and matches the directory
  name
- `description` exists, avoids angle brackets, and stays within the source
  metadata budget
- `compatibility`, when present, stays within the source length limit
- optional resource roots are directories when present
- `agents/openai.yaml`, when present, contains expected Codex UI keys
- Python helper scripts compile
- known non-portable package contents are reported

## Package Builder

```bash
python3 <skill-creator>/scripts/package_skill.py \
  <skill-dir> \
  <output-directory>
```

`package_skill.py` follows the Anthropic source zip-based `.skill` archive
path. It prefers `scripts/quick_validate.py`; when PyYAML is unavailable, it
falls back to `scripts/validate_skill_package.py --package-mode`.

This fallback does not change the archive shape.

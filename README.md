# Skills

Reusable skills for Codex and Claude Code, covering product planning, design,
Web development, go-to-market work, software engineering, and skill authoring.
Each skill lives in `skills/<name>/`; its `SKILL.md` describes its task,
requirements, workflow, and supporting resources.

## Codex

The `showxu-skills` marketplace publishes one `showxu-skills` plugin containing
the repository's `skills/` directory.

```bash
codex plugin marketplace add showxu/skills --ref main
codex plugin add showxu-skills@showxu-skills
```

Restart Codex after installation. To refresh the marketplace:

```bash
codex plugin marketplace upgrade showxu-skills
```

Check the installed version afterward. Marketplace refresh and installed-plugin
activation depend on the host version.

For a local manifest check from this checkout:

```bash
codex_test_home="$PWD/.build/plugin-check/codex"
mkdir -p "$codex_test_home"
CODEX_HOME="$codex_test_home" codex plugin marketplace add "$PWD"
CODEX_HOME="$codex_test_home" codex plugin list --available --json
```

The marketplace's Git source installs the published repository root. Working
tree installation checks use an isolated local marketplace as described in
[skill authoring](docs/skill-authoring.md#plugin-distribution).

## Claude Code

The `skills` marketplace publishes six plugin groups. Choose the group that
fits the task:

```bash
claude plugin marketplace add showxu/skills
claude plugin install product-management@skills
claude plugin install design-and-user-experience@skills
claude plugin install build-webapp@skills
claude plugin install go-to-market@skills
claude plugin install software-engineering@skills
claude plugin install skill-toolkit@skills
```

These are individual choices; groups overlap and installing several can expose
the same skill through several plugins. Restart Claude Code after installation.
To update an installed group, for example:

```bash
claude plugin marketplace update skills
claude plugin update skill-toolkit@skills
```

For local testing from this checkout:

```bash
claude_test_home="$PWD/.build/plugin-check/claude"
mkdir -p "$claude_test_home"
CLAUDE_CONFIG_DIR="$claude_test_home" claude plugin validate .
CLAUDE_CONFIG_DIR="$claude_test_home" claude plugin marketplace add "$PWD"
CLAUDE_CONFIG_DIR="$claude_test_home" claude plugin install skill-toolkit@skills
```

## Direct skill installation

Use either plugins or direct installation for a skill. Installing the same
skill through both routes can load it twice. Direct copies or links suit local
authoring; plugins provide versioned distribution.

After cloning this repository, copy the selected `skills/<name>/` directory to
the host's user skill directory, or link it for local editing. For example,
from the checkout root:

```bash
mkdir -p "$HOME/.agents/skills"
ln -s "$PWD/skills/skill-distiller" "$HOME/.agents/skills/skill-distiller"

mkdir -p "$HOME/.claude/skills"
ln -s "$PWD/skills/skill-distiller" "$HOME/.claude/skills/skill-distiller"
```

Choose an unused destination and restart the host afterward. Requirements vary
by skill; consult its `SKILL.md` before using bundled helpers.

## Repository index

- [Documentation index](docs/README.md): architecture, lifecycle, and reference
  documentation.
- [Repository layout](docs/repository-layout.md): artifact ownership and
  placement.
- [Skill authoring](docs/skill-authoring.md): trigger contracts, maintenance,
  package validation, and plugin versions.
- [Marketplace groups](docs/collection-taxonomy.md): capability routing.
- [Agent guide](AGENTS.md): editing routes and guardrails.
- [upstreams.yaml](upstreams.yaml): upstream sources and review provenance.
- `skills/`: skill instructions, references, scripts, templates, and assets.

## License

Original material, including independently written and distilled skill
workflows, is licensed under the [MIT License](LICENSE), copyright showxu.
Verbatim upstream copies and retained third-party resources keep their licenses
and notices beside them. Those notices govern the corresponding material; the
root license does not replace them.
Third-party design downloads and private research artifacts are excluded from
distribution.

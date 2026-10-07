# Plugin Distribution For Skills

Use this reference when a repository's finished skills should also install as
a Claude Code plugin, a Codex plugin, or both. Each skill still passes its own
package preflight first; plugin manifests only publish skills that are ready.

This reference owns manifest mechanics, version labels, install docs, and
isolated install checks. It does not own installing or managing plugins on a
user's machine, and it does not decide which skills form a collection or a
group. The collection's own taxonomy or authoring docs own that choice.

## Choose The Route

- Direct skill installs (copy, link, or edit mode) suit the author's own daily
  use: edits apply in place, and one directory serves every agent that reads
  it.
- Plugins suit distribution: each host installs a versioned copy from a
  marketplace, so edits reach users only through an update.
- Do not install the plugin on a machine that already installs the same skills
  directly. Each skill would load twice.
- Plugins can also carry hooks or MCP servers. Declare only what the plugin
  actually ships.

## Claude Code

- Marketplace file: `.claude-plugin/marketplace.json` with `name`, `owner`,
  `metadata`, and `plugins`.
- One source tree can publish per-skill or grouped plugins: each entry uses
  `"source": "./"`, `"strict": false`, and a `skills` list of skill folders.
- Each installed plugin gets its own copy of the whole source tree, without
  `.git`. Symlinks are copied as links, so a link that points outside the
  repository breaks on any other machine. Keep published skills as real
  folders.
- Version label: the entry's `version` when set, otherwise the source
  repository commit. `metadata.version` does not label plugins.
- A pinned entry `version` blocks updates until it changes: `claude plugin
  update` reports the plugin as current and keeps stale content. Pin only when
  every release bumps it; otherwise leave it unset so each commit is a new
  version.
- Users update with `claude plugin marketplace update <marketplace>`, then
  `claude plugin update <plugin>@<marketplace>`, then restart.

## Codex

- Marketplace file: `.agents/plugins/marketplace.json`. Each plugin entry has a
  `source` such as `{"source": "local", "path": "<plugin-root>"}`, a `policy`,
  and a `category`.
- Codex CLI 0.139.0 requires local source paths to start with `./` and name a
  nonempty normal subdirectory. For a plugin at the repository root, use a Git
  source such as `{"source": "url", "url": "https://github.com/<owner>/<repo>.git", "ref": "main"}`.
  Test its working tree through a temporary parent marketplace with a local
  `./release` source; test the published Git source separately.
- Plugin manifest: `<plugin-root>/.codex-plugin/plugin.json` with `name`,
  `version`, `description`, `skills`, and `interface`. `skills` names one
  folder, not a list.
- Install copies the whole plugin root, including `.git`, into a cache keyed by
  plugin name and `version`. Symlinked skill folders are dropped from the copy.
- A collection therefore ships as one plugin rooted at the repository, with
  `"skills": "./skills/"`. Groups would need real copies of each group's skill
  folders; do not fake groups with symlinks.
- From a local marketplace, re-running `codex plugin add <plugin>@<marketplace>`
  recopies the current working tree, uncommitted edits included, even at the
  same version. A version bump replaces the cached copy.
- Git marketplaces accept `owner/repo[@ref]`, HTTPS, or SSH URLs.
  `codex plugin marketplace upgrade` refreshes their snapshots; how installed
  copies follow an upgrade is untested.

## Versions And Docs

- Use one release version across hosts: the Codex `plugin.json` `version`, the
  Claude `metadata.version`, and any pinned Claude entry `version`.
- Give each host a README install section with the exact marketplace and plugin
  names, a local-testing command, and the "plugin or direct install, not both"
  note. Keep direct-install instructions in their own section.
- Record which files publish what, and the version rule, in the collection's
  authoring docs. Repository facts stay there, not in this reference.

## Verify Before Presenting

1. Parse every manifest as JSON.
2. Run `claude plugin validate <repo>` for the Claude marketplace.
3. Record checksums of the real host configuration files.
4. Install into throwaway host homes: point `CLAUDE_CONFIG_DIR` and
   `CODEX_HOME` at temporary directories, add the marketplace from the
   repository path, and install each plugin.
5. Compare the cached skill folders with the published ones: every expected
   `SKILL.md` is present, and none is a dropped or dangling link.
6. Delete the temporary homes and confirm the real configuration checksums are
   unchanged.

These are observed host behaviors, not host contracts. Re-run the isolated
check when a host CLI changes, and mark anything not exercised as untested.

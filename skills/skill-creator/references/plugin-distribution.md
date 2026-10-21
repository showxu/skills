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
- Plugins publish a collection under one identity. Remote marketplace
  installations use versioned copies; Claude relative-path plugins from a
  local-directory marketplace load directly from the checkout.
- In each host, choose either the plugin or direct installation for the same
  skills so each skill loads once.
- Plugins can also carry hooks or MCP servers. Declare only what the plugin
  actually ships.

## Claude Code

- Marketplace file: `.claude-plugin/marketplace.json` with `name`, `owner`,
  `metadata`, and `plugins`.
- For a collection plugin, define its identity in
  `.claude-plugin/plugin.json`: `name`, `version`, `description`, and any
  supported author, homepage, repository, license, or keyword fields.
- Publish one marketplace entry with the plugin's `name`, `description`, and
  `"source": "./"`. Claude discovers `skills/<name>/SKILL.md` automatically.
  Keep the version in the plugin manifest.
- Add a local checkout with `claude plugin marketplace add <repo-path>`, then
  `claude plugin install <plugin>@<marketplace>`. Relative-path plugins in
  local-directory marketplaces load in place. Source edits take effect at the
  next session start or `/reload-plugins`.
- Other marketplace origins copy plugins into the cache. Keep distributed
  skills and supporting resources inside the plugin root.
- Remote users update with `claude plugin marketplace update <marketplace>`,
  then `claude plugin update <plugin>@<marketplace>`, then restart or reload.
  Bump the manifest version for a new published release.
- The [manifest reference](https://code.claude.com/docs/en/plugins-reference)
  defines identity and component fields; the
  [loading reference](https://code.claude.com/docs/en/plugins/loading#in-place-and-copied-plugins)
  defines when source files load in place.

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

- Use one release version across hosts: the Claude and Codex `plugin.json`
  `version` fields and the Claude marketplace `metadata.version`.
- Give each host a README install section with the exact marketplace and plugin
  names, a local-testing command, and the "plugin or direct install, not both"
  note. Keep direct-install instructions in their own section.
- Record which files publish what in the collection's authoring docs, and its
  version source and mirrors in its VERSIONING. Repository facts stay there,
  not in this reference.

## Verify Before Presenting

1. Parse every manifest as JSON.
2. Run `claude plugin validate <repo>` for the Claude marketplace.
3. Record checksums of the real host configuration files you will compare,
   naming each file.
4. Create two empty temporary directories and use them as throwaway host
   homes: point `CLAUDE_CONFIG_DIR` and `CODEX_HOME` at them, add the
   marketplace from the repository path, and install each plugin. Both
   directories must exist before the first host command.
5. Check the installed version with `claude plugin list --json` and the skill
   inventory with `claude plugin details <plugin>@<marketplace>`: every
   expected skill is listed once.
6. Delete the temporary homes and compare the real configuration checksums.
   When one differs, record the file, the changed fields, and whether the
   check can be shown to have caused the change; a running host app may
   also write these files. Report the difference instead of claiming the
   configuration was untouched.

These are observed host behaviors, not host contracts. Pointing the
variables at temporary homes is not shown to stop every host process from
writing the real configuration; step 6 is the check. Re-run the isolated
check when a host CLI changes, and mark anything not exercised as untested.

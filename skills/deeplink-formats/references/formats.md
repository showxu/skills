# Deeplink Format Reference

Use this reference after `deeplink-formats` triggers. It records practical
deeplink formats, support levels, verification commands, output wrappers, and
failure modes.

## Support Ledger

| Target | Primary route | Support | Fallback | Evidence |
|---|---|---|---|---|
| VS Code file | `vscode://file/<absolute-path>:<line>:<column>` | Supported when VS Code is installed | `code -g '<absolute-path>:<line>:<column>'` | Official VS Code CLI/URL docs and local `code --help`. |
| VS Code folder | `vscode://file/<absolute-folder>/` | Supported when VS Code is installed | `code '<absolute-folder>'` | Official VS Code URL docs. |
| VS Code settings | `vscode://settings/<setting.name>` | Supported when VS Code is installed | `code` then open settings manually | Official VS Code URL docs. |
| Cursor file/folder | Treat `cursor://file/...` as inferred unless locally smoke-tested | Inferred/local only | `cursor -g '<absolute-path>:<line>:<column>'` or `cursor '<absolute-folder>'` | Local app registers `cursor://`; local Cursor CLI supports `--goto`. Public Cursor docs verified here cover MCP install deeplinks, not general file routes. |
| Cursor MCP install | `cursor://anysphere.cursor-deeplink/mcp/install?...` | Supported for MCP install links | `cursor --add-mcp '<json>'` when appropriate | Official Cursor deeplink docs and local Cursor CLI. |
| Xcode file/line | Do not rely on `xcode://` file routes without a route-specific test | Partial | `xed --line <line> '<absolute-path>'` or `xed --project '<workspace-or-package>' '<absolute-path>'` | Local Xcode registers URL schemes; local `xed --help` supports `--line` and `--project`. |
| Codex thread/settings | Treat `codex://...` routes as host-specific until verified | Unknown/local only | Plain thread identifier, URL, or workspace path | Local Codex app registers `codex://`; no route-specific public evidence recorded here. |
| Claude Desktop | Treat `claude://...` routes as host-specific until verified | Unknown/local only | Plain thread identifier, URL, or workspace path | Local Claude app registers `claude://`; no route-specific public evidence recorded here. |
| CLI-only tool | No standard app URL | Not available | documented CLI command | Requires tool-specific help output. |

## Verification Commands

Inspect registered schemes:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' /Applications/<App>.app/Contents/Info.plist
```

Check editor CLIs:

```bash
command -v code cursor xed
code --help
cursor --help
xed --help
```

Run a live route smoke test only with user confirmation:

```bash
open '<scheme>://...'
```

## Output Templates

Slack:

```text
<vscode://file/<absolute-path>:<line>:<column>|Open in VS Code>
```

Markdown:

```markdown
[Open in VS Code](vscode://file/<absolute-path>:<line>:<column>)
```

CLI fallback:

```bash
code -g '<absolute-path>:<line>:<column>'
cursor -g '<absolute-path>:<line>:<column>'
xed --line <line> '<absolute-path>'
```

## Link Format Rules

- Use absolute paths for local file and folder targets.
- Quote shell paths in fallback commands.
- Keep Slack labels short, for example `Open in VS Code` or `Open in Xcode`.
- Include both the formatted link and the fallback command when recipient
  machine support is uncertain.
- Do not embed tokens, signed URLs, private credentials, or long prompt text in
  generated URLs.
- For app schemes that are only registered locally, say `local scheme exists`
  rather than `supported route`.

## Failure Modes

- URL scheme is registered but route path is ignored by the app.
- Recipient machine does not have the app installed.
- CLI exists locally but is not installed on the recipient machine.
- Slack or another destination escapes, truncates, or rewrites the URL.
- File path is machine-local and cannot be opened by a different recipient.
- Line/column format differs between URL scheme and CLI fallback.

## Source Notes

- Seed source: ComposioHQ `awesome-codex-skills/agent-deep-links/` at
  `14667b4850a3d99b23f8fbc0cf73c879ef219c66`.
- Source-specific guardrails preserved here: support levels, Slack-safe output,
  local verification before support claims, fallback commands, and explicit
  unsupported/unknown states.

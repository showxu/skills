---
name: deeplink-formats
description: Look up and verify deeplink, URL scheme, editor file route, settings route, and CLI fallback formats for local developer apps such as Codex, Cursor, VS Code, Xcode, Claude, local files, and folders. Use when a user asks what deeplink shape to use, whether a route is supported, how to format a Slack or Markdown app link, or what fallback open command to provide. Do not use for Swift/Xcode debugging, editing target files, or opening apps automatically without confirmation.
---

# Deeplink Formats

## Purpose

Provide deeplink knowledge: route formats, support levels, verification checks,
output wrappers, and fallback commands for local developer apps.

This skill owns the link-format knowledge, not the underlying product work.

## When To Use

- The user asks what deeplink, URL scheme, or editor route format to use.
- The user asks for a clickable link for Slack, Markdown, an issue, a doc, or
  another output surface.
- The user asks whether an app supports a URL scheme or editor deep link.
- The output needs a file/folder link plus a reliable CLI fallback command.
- The target app or object involves Codex, Cursor, VS Code, Xcode, local files,
  folders, or similar developer tools.

## When Not To Use

- Do not use this for Swift/Xcode build, debug, Simulator, or Instruments work;
  route that to the Swift or app-development skill that owns the task.
- Do not use this to edit files or inspect code semantics; this skill only
  provides route formats, support levels, links, and fallback commands.
- Do not auto-open a URL scheme or app unless the user explicitly wants a
  local smoke test.
- Do not claim a route is supported just because an app registers a URL scheme.

## Inputs To Inspect

- Target app and target object: thread, file, folder, settings page, prompt,
  issue, web URL, or documentation page.
- Destination surface: Slack, Markdown, terminal command, issue comment, or
  plain text.
- Local evidence: app bundle URL schemes, CLI help, official docs, or prior
  user-provided route.
- Whether the recipient machine is expected to have the app or CLI installed.

## Workflow

1. Identify the destination surface and target object.
2. Read `references/formats.md` for the current support matrix and output
   templates relevant to the target app.
3. Verify support before marking a link as supported:
   - URL schemes: inspect the app bundle `CFBundleURLTypes`.
   - CLI fallback: run `<tool> --help` or equivalent.
   - Official route formats: prefer current official docs.
4. Choose the output shape:
   - Slack: `<url|label>`
   - Markdown: `[label](url)`
   - Terminal fallback: quoted shell command
   - Unknown support: plain path plus "needs local verification"
5. Include a fallback command whenever support is partial, inferred, or
   recipient-machine dependent.
6. Report uncertainty explicitly.

## Decision Rules

- VS Code file/folder URLs can be used when the recipient has VS Code installed
  and the route shape is from official VS Code docs.
- Cursor has a registered `cursor://` scheme and a VS Code-compatible CLI on
  this machine, but file URL routes must be treated as local/inferred unless
  verified for the recipient environment.
- Xcode has URL schemes, but file/line opening should prefer `xed --line` until
  a specific Xcode URL route is verified.
- Codex and Claude app schemes may exist locally; treat thread/settings route
  shapes as host-specific unless verified in the current app.
- For Slack, use short labels and avoid putting secrets, tokens, private query
  strings, or long prompts inside the URL.

## Validation Rules

Use non-mutating checks by default:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' /Applications/<App>.app/Contents/Info.plist
command -v code cursor xed
code --help
cursor --help
xed --help
```

Only run `open '<scheme>://...'` when the user wants a live local smoke test.

## Output Format

Return a compact link-format block:

```text
Target: <app/object>
Primary: <url|label or Markdown link>
Fallback: <quoted command or absolute path>
Support: supported | local-verified | inferred | unknown
Notes: <one sentence if needed>
```

For multiple links, use a small table with `Target`, `Link`, `Fallback`, and
`Support`.

## Failure / Uncertainty Handling

- If the app is not installed locally, say that support is unverified and give
  the documented route or CLI fallback separately.
- If a URL scheme exists but no route is documented, provide the scheme evidence
  and a fallback instead of inventing a route.
- If the destination surface might escape or rewrite URLs, provide both a
  formatted link and a raw URL/command.

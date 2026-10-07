# Host Compatibility

This skill is Anthropic-compatible but runs in Codex hosts as a local skill.

## Codex Behavior

- The upstream helper scripts remain local shell tools.
- The primary durable artifact is `bundle.html` from the temporary artifact
  workspace.
- In Codex, present the generated artifact by path, browser target, or rendered
  verification evidence depending on the task.

## Non-Claims

- This skill does not provide Claude-native artifact display semantics.
- This skill does not create production frontend architecture by default.
- Promotion from artifact to real Web app implementation belongs to
  `webapp-builder`.
- This skill does not own product behavior or Figma operations.

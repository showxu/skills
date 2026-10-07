# Eval Fixtures

## Fixture 1: Extract Current Xcode

Prompt:

```text
Extract the Xcode system prompts from my currently selected Xcode and maintain
them under the skill references.
```

Expected behavior:

- Uses `xcode-select --print-path` through the extractor script.
- Generates a versioned directory under `references/generated/`.
- Reports prompt, documentation, and support-file counts.
- Does not paste raw prompt contents into the response.

## Fixture 2: Specific Xcode App

Prompt:

```text
Refresh the IDEIntelligenceChat resources from /Applications/Xcode-beta.app.
```

Expected behavior:

- Runs the extractor with `--xcode-app /Applications/Xcode-beta.app`.
- Fails clearly if the app or resources path is missing.
- Keeps generated output in the skill reference artifact tree.

## Fixture 3: Mirror Versus Local Source

Prompt:

```text
artemnovichkov/xcode-26-system-prompts updated. Should we absorb its prompt
rules into our Swift skills?
```

Expected behavior:

- Treats the GitHub repository as a signal/mirror, not an official source.
- Recommends local Xcode extraction and manifest comparison first.
- Requires a separate upstream/distillation decision before changing skill
  behavior from prompt text.

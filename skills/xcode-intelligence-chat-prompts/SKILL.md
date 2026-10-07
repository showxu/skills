---
name: xcode-intelligence-chat-prompts
description: Extract, refresh, index, compare, or maintain local Xcode IDEIntelligenceChat prompt templates and companion bundle artifacts, including .idechatprompttemplate files, AdditionalDocumentation markdown, AgentVersions.plist, IDEIntelligenceChat.xcplugindata, vocab, and support files, as generated skill reference artifacts. Use when asked about Xcode intelligence chat prompts, Xcode system prompts, IDEIntelligenceChat.framework bundle contents, or maintaining those artifacts from a local Xcode.app. Do not use for absorbing Apple prompt text as local behavioral rules, implementing Swift code, Apple HIG review, DESIGN.md templates, or App Store work.
---

# Xcode Intelligence Chat Prompts

## Purpose

Use this skill to maintain a local, reproducible snapshot of Xcode's
`IDEIntelligenceChat.framework` resources under this skill's `references/`
tree. The skill owns extraction, hashing, indexing, and drift comparison of
those resources. It does not make the extracted Apple text into authoritative
local skill instructions by itself.

The primary source is the user's installed Xcode bundle. Public mirrors such as
`artemnovichkov/xcode-26-system-prompts` are signal sources for file names and
release drift, not authority over the local Xcode installation.

## When To Use

- Extract or refresh Xcode system prompt templates from a local Xcode app.
- Extract or refresh Xcode `AdditionalDocumentation` markdown for local
  reference.
- Produce a manifest, hashes, counts, or an index of
  `IDEIntelligenceChat.framework` resources.
- Compare which prompt, documentation, or support files changed between Xcode
  snapshots.
- Maintain generated artifacts under
  `skills/xcode-intelligence-chat-prompts/references/generated/`.

## When Not To Use

- Do not copy extracted prompt instructions into another skill as behavior
  rules without a separate upstream/distillation decision.
- Do not treat GitHub mirrors as official Apple sources.
- Do not answer Swift, SwiftUI, UIKit, AppKit, or Xcode build questions from
  extracted docs when official Apple documentation or owning Swift skills are
  required.
- Do not use this for Apple HIG critique, `DESIGN.md` template selection, App
  Store operations, or generic prompt engineering.

## Inputs To Inspect

- Local Xcode developer path from `xcode-select --print-path`, or a provided
  `Xcode.app`, `Contents/Developer`, or `IDEIntelligenceChat` resources path.
- Existing generated snapshot directories under `references/generated/`.
- The generated `manifest.json` and `INDEX.md` for each snapshot.
- `upstreams.yaml` row `artemnovichkov-xcode-26-system-prompts` only as a
  mirror/signal cursor.

## Workflow

1. Identify the source Xcode:
   - default: `xcode-select --print-path`
   - explicit app: `--xcode-app /Applications/Xcode.app`
   - explicit developer dir: `--developer-dir .../Contents/Developer`
   - explicit resources dir: `--resources-dir .../IDEIntelligenceChat.framework/Versions/A/Resources`
2. Run the extractor script. Use `--clean` when refreshing an existing
   versioned snapshot.
3. Review `manifest.json` for source path, Xcode version/build, counts, file
   hashes, and generated paths.
4. Review `INDEX.md` for a human-scannable file list.
5. If comparing snapshots, diff their `manifest.json` file lists and hashes
   before reading raw extracted files.
6. Keep any downstream skill changes separate from extraction. Raw extracted
   text is evidence, not an accepted local rule.

## Script Usage

Extract the currently selected Xcode into this skill's generated references:

```bash
python3 skills/xcode-intelligence-chat-prompts/scripts/extract_xcode_intelligence_chat_prompts.py --clean
```

Extract from a specific Xcode app:

```bash
python3 skills/xcode-intelligence-chat-prompts/scripts/extract_xcode_intelligence_chat_prompts.py \
  --xcode-app /Applications/Xcode.app \
  --clean
```

Dry-run source discovery and counts without writing files:

```bash
python3 skills/xcode-intelligence-chat-prompts/scripts/extract_xcode_intelligence_chat_prompts.py --dry-run
```

## Generated Reference Layout

```text
references/generated/
├── <xcode-version-build>/
│   ├── README.md
│   ├── INDEX.md
│   ├── manifest.json
│   ├── prompts/
│   ├── additional-documentation/
│   └── support/
├── latest-README.md
└── latest-manifest.json
```

`references/generated/` is for local generated artifacts. Keep committed
instructions and durable behavior in `SKILL.md`, scripts, and small reference
files.

## Decision Rules

- Prefer manifest and hash comparisons before reading raw prompt contents.
- Record source provenance as `local-xcode-bundle`; record public GitHub
  mirrors only as `signal`.
- Keep extracted Apple content out of the active skill body unless a separate
  review accepts a distilled, non-verbatim local rule.
- If an extracted `AdditionalDocumentation` topic overlaps a Swift or Apple
  platform skill, route implementation guidance to the owning skill and cite
  official Apple docs when authoritative guidance is needed.
- If Xcode is missing or the resources directory is absent, report the exact
  path checked and ask for the intended Xcode app path.

## Validation Rules

- The extractor succeeds with the selected Xcode path.
- `manifest.json` is valid JSON and every listed generated file exists.
- File counts are nonzero for prompt templates.
- `INDEX.md` and `latest-manifest.json` are generated.
- Repository validation still passes after adding or editing this skill.

## Output Format

```text
Xcode Intelligence Chat Prompts

Source:
- Xcode:
- Resources:

Generated:
- Snapshot:
- Prompts:
- Additional docs:
- Support files:

Validation:
- Manifest:
- Index:
- Notes:
```

## Failure / Uncertainty Handling

- If multiple Xcode apps are installed and `xcode-select` points to the wrong
  one, rerun with `--xcode-app` or `--developer-dir`.
- If generated artifacts are large or proprietary, keep them local under
  `references/generated/` and avoid copying their contents into responses.
- If the user asks to make behavioral skill changes from extracted content,
  first prepare a separate upstream/distillation decision instead of directly
  pasting prompt text.

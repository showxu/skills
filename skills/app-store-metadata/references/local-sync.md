# Local Sync

## Local Review First

This skill can plan sync work, validate local files, and review dry-run output.
It should not perform live App Store Connect writes by default.

## Common Local Shapes

Canonical JSON layout:

```text
metadata/
├── app-info/
│   ├── en-US.json
│   └── fr-FR.json
└── version/
    └── 1.2.3/
        ├── en-US.json
        └── fr-FR.json
```

Version JSON example:

```json
{
  "description": "Plain text description",
  "keywords": "focus,timer,notes",
  "promotionalText": "A focused update for your daily workflow.",
  "supportUrl": "https://example.com/support",
  "marketingUrl": "https://example.com",
  "whatsNew": "Improved sync reliability."
}
```

App-info JSON example:

```json
{
  "name": "Example App",
  "subtitle": "Plan focused work",
  "privacyPolicyUrl": "https://example.com/privacy"
}
```

`.strings` files can also represent localizations:

```text
"description" = "Plain text description";
"keywords" = "focus,timer,notes";
"whatsNew" = "Improved sync reliability.";
```

## Dry-Run Planning

When the user has an App Store Connect CLI:

- confirm exact flags with `--help`
- prefer explicit IDs over names
- run read/list commands before planning writes
- use dry-run or validate modes when available
- stop before commands that change live metadata unless the user explicitly
  confirms and a live-operation skill owns the action

## Useful Local Validation

```bash
python3 skills/app-store-metadata/scripts/validate_metadata.py \
  --metadata-dir ./metadata
```

For one JSON file:

```bash
python3 skills/app-store-metadata/scripts/validate_metadata.py \
  --file ./metadata/version/1.2.3/en-US.json
```

# Localization

## Workflow

1. Pick a source locale and freeze the slide intent before translation.
2. Translate the user outcome, not the literal English headline.
3. Rebuild line breaks per locale.
4. Re-export screenshots for every locale and device family that needs custom
   copy or imagery.
5. Validate each localized export for dimensions, alpha, text fit, and
   screenshot order.

## Rules

- Keep slide count and filenames stable across locales unless the store record
  intentionally differs.
- Do not leave English captions in localized screenshots unless the app
  intentionally uses English in that market.
- German, French, Portuguese, Spanish, and similar languages often need shorter
  claims than the English source.
- For RTL locales such as Arabic, Hebrew, Persian, and Urdu, set canvas
  direction to RTL and mirror asymmetric layouts intentionally.
- Keep locale-specific claims true. Do not translate unsupported awards,
  ranking claims, compliance claims, or pricing statements.
- If localized app previews are missing, App Store product pages may fall back
  to another available language; screenshot planning should still make the
  intended screenshot locale explicit.

## Folder Shape

Use a simple Apple-only structure unless a project already has a stronger
convention:

```text
public/screenshots/
├── iphone/
│   ├── en-US/
│   └── de-DE/
└── ipad/
    ├── en-US/
    └── de-DE/
```

For single-locale work, omit locale folders only if the generator and export
script remain obvious.

## Localized QA

- Confirm every source-locale slide has a corresponding target-locale slide.
- Check text expansion at actual export resolution.
- Check device frame alignment after swapping localized raw captures.
- Check RTL composition manually; automated mirroring is not enough.
- Validate screenshots after export, not only the source captures.

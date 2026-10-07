# Localization Workflow

## Metadata Localization Is Not Binary Localization

App Store metadata localization is separate from localizing the app binary in
Xcode. The primary language is the fallback when no better localization matches
the customer's storefront and device language.

## Workflow

1. Identify primary locale and target locales.
2. Separate app-info fields from version-localization fields.
3. Translate description, promotional text, support/marketing URLs, and What's
   New where relevant.
4. Adapt keywords per locale instead of literal-translating the English list.
5. Validate every locale independently.
6. Flag locales that are missing required fields or using copied primary-locale
   keywords.

## Rules

- Keep app names untranslated unless the product owner asks for localized names.
- Subtitle is short; adapt the promise instead of forcing a literal sentence.
- Keywords should reflect local search behavior and fit 100 bytes.
- Description should preserve structure but read naturally in the target
  language.
- URLs may differ by locale; do not assume one global URL is correct.
- Do not truncate translations mid-sentence to fit limits; rewrite them.

## Review Checklist

- Each target locale has the expected fields.
- No non-primary locale blindly repeats primary-locale keywords unless that is
  intentional.
- Character and byte limits pass per locale.
- Privacy/support URLs are valid and locale-appropriate.
- Claims remain true after translation.

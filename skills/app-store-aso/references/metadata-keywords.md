# Metadata And Keywords

Use this reference for keyword and metadata optimization. Route copywriting-only
tasks to `app-store-metadata`; use this skill when optimization, search
coverage, market fit, or conversion strategy is involved.

## Apple-Backed Rules

- Use accurate, relevant keywords that describe the app's features and
  functionality.
- Keywords are limited to 100 bytes total.
- Separate keyword terms with commas and no spaces after commas. Spaces may be
  used inside multi-word phrases.
- Avoid duplicate words.
- Do not duplicate the app name or company name in keywords.
- Do not use competing app names, unauthorized trademarks, celebrity names,
  irrelevant terms, inappropriate terms, or objectionable terms.
- Avoid category names, the word "app", plurals already covered by singular
  terms, and special characters unless they are part of the brand identity.
- Promotional text should not be used to display keywords because Apple says it
  does not affect search ranking.

## Local Audit Rules

- **Keyword waste**: flag keyword terms that duplicate app name or subtitle
  words.
- **Underutilized fields**: flag keyword fields below 90 bytes and subtitles
  below 20 characters as optimization warnings, not Apple errors.
- **Bad separators**: flag `, `, `;`, and `|` in keywords.
- **Missing fields**: flag empty subtitle, keywords, description, or What's
  New in the latest version metadata.
- **Cross-locale keyword duplication**: flag non-primary locales whose keyword
  fields exactly match the primary locale.
- **Description coverage**: report whether important keyword terms appear
  naturally in the description for conversion continuity. Do not call this an
  Apple indexing requirement.

## Keyword Selection Heuristics

- Prefer specific terms that match user intent over broad high-competition
  terms.
- Treat popularity scores and competitor gaps as evidence only when the user
  provides current data or an external tool output.
- Prefer single useful words when they create valuable combinations with name
  and subtitle terms; use multi-word phrases only when the phrase is the real
  search intent.
- Keep each locale independent. Translation is not enough; keywords should
  reflect local search behavior.
- For non-Latin locales, tokenization can be script-specific. Do not assume
  whitespace splitting works for Chinese, Japanese, Korean, or Arabic.

## Metadata Roles

- App name and subtitle carry both discovery and conversion burden because
  users see them.
- Keywords are invisible to users and should be relevance-dense.
- Description should explain value, proof, use cases, and trust clearly.
- Promotional text is for timely conversion messaging.
- What's New belongs to release communication, not keyword stuffing.

## Category Fit

Apple says the primary category is important for discoverability and should be
the most relevant category for the app. Treat category selection as a fit and
expectation question, not a loophole:

- recommend categories only when they accurately reflect core functionality
- compare likely user intent and competitor placement when the user supplies
  data
- avoid category changes without App Store Connect state and explicit user
  confirmation
- do not claim a category will rank better without evidence

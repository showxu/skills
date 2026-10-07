# Writing Guidelines

## Goals

- Make the update clear to people deciding whether to update or reopen the app.
- Include meaningful user-visible changes.
- Stay honest: every bullet should map to release evidence or explicit user
  input.
- Keep the text concise enough to scan on a product page.

## Copy Rules

- Use plain language and user outcomes.
- Prefer concrete verbs: Added, Improved, Fixed, Updated, Made, Reduced.
- Keep each bullet to one sentence.
- Use 5 to 10 bullets for larger releases; use fewer when the evidence is
  smaller.
- Put the most important user-visible change first.
- Avoid internal names, ticket IDs, implementation details, file paths, and
  technical jargon.
- Avoid generic filler such as "bug fixes and performance improvements" when
  specific fixes are known.

## Structure Options

Flat list:

```text
- Added voice input for faster search.
- Improved feed scrolling performance.
- Fixed a login issue that could unexpectedly sign some users out.
```

Grouped list:

```text
New
- Added voice input for faster search.

Improved
- Improved feed scrolling performance.

Fixed
- Fixed a login issue that could unexpectedly sign some users out.
```

## Bad To Better

| Weak | Better |
| --- | --- |
| Fixed token refresh race condition | Fixed a login issue that could unexpectedly sign some users out. |
| Implemented lazy image loading | Improved scrolling performance in image-heavy lists. |
| Added settings v2 | Added a clearer settings layout. |
| Refactored sync engine | Improved sync reliability. |

## QA Checklist

- Every bullet ties to a real change.
- No duplicate bullets describe the same work.
- No internal jargon, issue keys, branch names, or file paths.
- No unsupported marketing claims.
- Final text is under 4000 characters.
- If the user asked for paste-ready output, no evidence notes are mixed into the
  final App Store text.

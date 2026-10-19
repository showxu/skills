---
name: Organization family
description: Shared visual identity and presentation contract for an organization and its repositories.
---

## Overview

Replace the bracketed placeholders with accepted organization inputs before
applying this template. This file owns family visual decisions; each product
owns its meaning, interface and claims. Consumers record this file's accepted
revision and digest when resolving rendering recipes.

- Organization display name: `<organization-display-name>`
- Visitor promise: `<accepted-organization-promise>`
- Umbrella mark: `<accepted-umbrella-mark-source>`
- Account avatar: `<accepted-avatar-source>`
- Supported appearances: light and dark

Keep the umbrella mark distinct from the account avatar where the identity
system defines both. A distribution repository without its own logo uses the
logo of the product it distributes. Inputs and exports have one owner.

## Colors

| Role | Light | Dark | Owner |
| --- | --- | --- | --- |
| Surface | `<light-surface>` | `<dark-surface>` | Family identity |
| Primary text | `<light-ink>` | `<dark-ink>` | Family identity |
| Secondary text | `<light-muted>` | `<dark-muted>` | Family identity |
| Accent | `<light-accent>` | `<dark-accent>` | Family identity |
| Border | `<light-border>` | `<dark-border>` | Family identity |

Choose actual values from accepted identity evidence. Verify contrast in each
appearance. Consumers do not import another organization's palette.

## Typography

Family faces and their licensed sources are declared in Presentation below.
GitHub profile text uses GitHub's own typography; artwork does not impose fonts
on the rendered README.

## Layout

Keep member icon geometry, spacing and alignment consistent across the family.
Presentation dimensions below are renderer defaults to accept or override;
product names, descriptions and source paths remain inputs.

## Components

Use the accepted umbrella and repository marks. Do not redraw icons during a
profile or social-card refresh. Keep textual claims as text wherever the
surface supports it.

## Presentation

### Typography

| Role | Accepted family | Source and license |
| --- | --- | --- |
| Artwork owner label | `<owner-label-font-family>` | `<font-source-and-license>` |
| Artwork title | `<title-font-family>` | `<font-source-and-license>` |
| Artwork About sentence | `<body-font-family>` | `<font-source-and-license>` |
| Terminal | `<monospace-font-family>` | `<font-source-and-license>` |
| Website | `<website-font-family-and-fallbacks>` | `<font-source-and-license>` |

Resolve fonts into the renderer recipe. Bundle fonts only when redistribution
is permitted; outline social-card lettering and retain the layout receipt.

### Social card

Default canvas: 1280 × 640 px. Show owner, icon, title and complete About
sentence. Default About size: 32 px, at most three lines. Default title range:
72 to 40 px; wrap at meaningful separators only after one-line fitting fails.
Use accepted colors above. Review exact exported bytes in light and dark.

| Field | Source | Adaptation rule |
| --- | --- | --- |
| Owner | Repository's actual account/organization owner | Use the accepted display label |
| Title | Product/repository information set | Preserve its complete accepted title |
| About | Repository's accepted About sentence | Preserve all words; no truncation |
| Icon | Logo shown in the repository README header | Use the product logo for a distribution repository with no own logo |

### Website

Use the public catalog's promise, job groups, ordering and umbrella identity.
Resolve typography, colors, spacing and responsive layout from this DESIGN.
The website owns its implementation and routes; link to accepted documentation
and release channels. Do not maintain a second membership list.

| Field | Source |
| --- | --- |
| Owner | Organization identity |
| Title | Public catalog promise |
| About | Public catalog secondary line; member outcome sentences in rows |
| Icon | Catalog umbrella mark and repository icons |

### Terminal

Render actual recorded commands and successful output, with source revision,
executable/input digests, toolchain and normalization evidence kept outside
public prose. Use light and dark exports through `<picture>` with a fallback.
Resolve surface, bar, border, prompt, command, output and dim colors from the
accepted palette, and the terminal family from Typography. Defaults are 14 px
type, 21 px line height, 20 px padding and 10 px corner radius. Keep private
paths out of the recording; do not fabricate command output.

### Profile

The public profile lives in `.github/profile/README.md`; the member profile
lives in private `.github-private/profile/README.md`. Both use the shared
profile renderer. The public catalog owns presentation copy, navigation,
groups, order and repository icons. Member input contains maintenance links,
a pinned catalog revision/digest and each repository's operational
`default_branch`, CI workflow and release facts.

| Token | Value | Role |
| --- | --- | --- |
| `public_header_icon_size` | 128 px | Public umbrella mark |
| `member_header_icon_size` | 64 px | Member umbrella mark |
| `public_row_icon_size` | 40 px | Public repository rows |
| `member_row_icon_size` | 24 px | Member repository rows |
| `badge_style` | `flat` | Live badges linked to their evidence |

Accept or replace these defaults and resolve them into a DESIGN-bound JSON
recipe. Token names are renderer fields, independent of this document's
Markdown layout. Use positive integer pixel sizes and a supported badge style.

| Field | Public profile source | Member profile source |
| --- | --- | --- |
| Owner | Catalog organization login/display name | Same pinned catalog |
| Title | Catalog visitor promise | Catalog display name plus “maintainer dashboard” |
| About | Catalog secondary line and repository outcomes | Public website/profile link and member maintenance navigation |
| Icon | Catalog umbrella mark and repository README-header icons | Same catalog icons at member sizes |

Public layout: centered umbrella mark, promise heading, secondary line,
documentation/contributing/security/support navigation, an optional quick
start, then job-grouped rows with icon, linked name and outcome; optional
maintainer line from input.

Member layout: smaller umbrella mark and dashboard title, public entry link,
maintenance navigation, catalog-ordered groups with icon/name/CI/release rows,
then organization-wide open-PR, open-issue and Dependabot-PR searches. Link
shared policy in `.github`; keep status live. Content must be shareable with
any member. No credentials, private paths or unpublished plans belong here.

Render HTML tables and theme-aware `<picture>` only on supported GitHub
surfaces. Keep text as text, check exact generated bytes, reconcile membership
with public non-archived inventory except `.github`, and review both profiles
in light and dark.

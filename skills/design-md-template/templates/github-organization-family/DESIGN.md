---
version: alpha
name: Organization family
description: Shared visual identity and presentation tokens for an organization and its repositories.
colors:
  primary: "#2F5BD3"
  primary-dark: "#8AB4F8"
  ink: "#1A1A1A"
  ink-dark: "#F2F2F2"
  terminal-surface: "#FCFCFC"
  terminal-surface-dark: "#14161A"
  terminal-bar: "#F0F0F0"
  terminal-bar-dark: "#1E2126"
  terminal-border: "#DADADA"
  terminal-border-dark: "#33373F"
  terminal-output: "#404040"
  terminal-output-dark: "#C8CACF"
  terminal-dim: "#666666"
  terminal-dim-dark: "#8E929B"
  social-preview-background: "#F5F5F5"
  social-preview-muted: "#555555"
typography:
  terminal:
    fontFamily: Google Sans Code
    fontSize: 14px
    fontWeight: 400
    lineHeight: 21px
    fontVariation: "'MONO' 1"
  social-preview-title:
    fontFamily: Google Sans Code
    fontSize: 72px
    fontWeight: 700
    lineHeight: 82.8px
    fontVariation: "'MONO' 0"
  social-preview-owner:
    fontFamily: Google Sans Code
    fontSize: 28px
    fontWeight: 500
    lineHeight: 28px
    fontVariation: "'MONO' 0"
  social-preview-body:
    fontFamily: Google Sans Code
    fontSize: 32px
    fontWeight: 400
    lineHeight: 44px
    fontVariation: "'MONO' 0"
rounded:
  terminal: 10px
spacing:
  terminal-padding: 20px
  terminal-title-bar: 34px
  terminal-min-width: 560px
  hairline: 1px
  social-preview-padding: 64px
  social-preview-gap: 64px
  social-preview-stack: 24px
  social-preview-icon: 384px
  profile-header-icon: 128px
  profile-member-header-icon: 64px
  profile-row-icon: 40px
  profile-member-row-icon: 24px
components:
  terminal:
    backgroundColor: "{colors.terminal-surface}"
    textColor: "{colors.terminal-output}"
    typography: "{typography.terminal}"
    rounded: "{rounded.terminal}"
    padding: "{spacing.terminal-padding}"
    width: "{spacing.terminal-min-width}"
  terminal-dark:
    backgroundColor: "{colors.terminal-surface-dark}"
    textColor: "{colors.terminal-output-dark}"
  terminal-frame:
    backgroundColor: "{colors.terminal-border}"
    size: "{spacing.hairline}"
  terminal-frame-dark:
    backgroundColor: "{colors.terminal-border-dark}"
  terminal-title-bar:
    backgroundColor: "{colors.terminal-bar}"
    textColor: "{colors.terminal-dim}"
    height: "{spacing.terminal-title-bar}"
  terminal-title-bar-dark:
    backgroundColor: "{colors.terminal-bar-dark}"
    textColor: "{colors.terminal-dim-dark}"
  terminal-prompt:
    backgroundColor: "{colors.terminal-surface}"
    textColor: "{colors.primary}"
  terminal-prompt-dark:
    backgroundColor: "{colors.terminal-surface-dark}"
    textColor: "{colors.primary-dark}"
  terminal-command:
    backgroundColor: "{colors.terminal-surface}"
    textColor: "{colors.ink}"
  terminal-command-dark:
    backgroundColor: "{colors.terminal-surface-dark}"
    textColor: "{colors.ink-dark}"
  social-preview:
    backgroundColor: "{colors.social-preview-background}"
    textColor: "{colors.ink}"
    typography: "{typography.social-preview-title}"
    padding: "{spacing.social-preview-padding}"
    size: "{spacing.social-preview-icon}"
  social-preview-gap:
    width: "{spacing.social-preview-gap}"
    height: "{spacing.social-preview-stack}"
  social-preview-owner:
    backgroundColor: "{colors.social-preview-background}"
    textColor: "{colors.ink}"
    typography: "{typography.social-preview-owner}"
  social-preview-about:
    backgroundColor: "{colors.social-preview-background}"
    textColor: "{colors.social-preview-muted}"
    typography: "{typography.social-preview-body}"
  profile-header:
    size: "{spacing.profile-header-icon}"
  profile-member-header:
    size: "{spacing.profile-member-header-icon}"
  profile-row:
    size: "{spacing.profile-row-icon}"
  profile-member-row:
    size: "{spacing.profile-member-row-icon}"
---

# Organization family Design

## Overview

This file owns the family's visual decisions; each repository owns its
meaning, interface and claims, and the organization catalog owns copy,
membership, order and icon selection. Replace `name`, `description` and the
bracketed placeholders with accepted organization inputs before applying it.

- Organization display name: `<organization-display-name>`
- Visitor promise: `<accepted-organization-promise>`
- Umbrella mark: `<accepted-umbrella-mark-source>`
- Account avatar: `<accepted-avatar-source>`

Keep the umbrella mark distinct from the account avatar where the identity
system defines both.

This file follows Google's [DESIGN.md format](https://github.com/google-labs-code/design.md)
(`version: alpha`). Every token lives in the front matter; the sections below
explain intent and cite token names instead of values. CI lints this file
with the official `@google/design.md` parser and rejects any error or warning.
`github-readme-design`'s toolchain renders terminal demos, social previews and
organization profiles from these tokens through the same parser.

## Colors

The palette is a neutral stand-in: replace every color with accepted identity
evidence before an applied DESIGN counts as complete. The linter checks
contrast for each component pair.

`primary` marks what a reader acts on: the terminal prompt and, on the
website, links and accents. `primary-dark` carries the same hue on dark
surfaces. `ink` and `ink-dark` carry titles and commands.

The `terminal-*` colors build a quiet window around a session: surface, a
slightly deeper title bar and a hairline border. Output is one step softer
than commands, so the eye goes to what was typed; `terminal-dim` is reserved
for the window title.

The `social-preview-*` colors are the card's ground and the muted tone of its
About sentence. Icon colors belong to the icon entries in Iconography.

## Typography

The default family is one variable font that carries every lettering role
through its axes; each typography token selects a weight and a variation.
Terminal sessions and code are set monospaced so output keeps its column grid;
titles, labels and body text are set proportional. Keep the default or
replace it with the organization's licensed variable family and the axis
values that select each design.

- Font file: `<organization-fonts-directory>/<variable-font-file>`
- Source and license: `<font-source-and-license>`

Rendered lettering is converted to glyph outlines from that file, so every
reader sees the same letterforms whatever fonts they have installed. Bundle
the font only when its license permits redistribution, with the license
beside it.

## Layout

A terminal window is never narrower than `terminal-min-width` and grows with
its widest line, up to the width of GitHub's README column; a session that
does not fit is shortened, never scaled down. The title bar is
`terminal-title-bar` tall and the session sits `terminal-padding` from every
edge.

A social preview fills GitHub's 1280×640 canvas: an icon square of
`social-preview-icon` set `social-preview-padding` from the left edge, then
the text column after `social-preview-gap`, with `social-preview-stack`
between owner, title and About.

The public profile and the member dashboard size the umbrella mark with
`profile-header-icon` and `profile-member-header-icon`, and repository icons
with `profile-row-icon` and `profile-member-row-icon`.

## Elevation & Depth

Presentation surfaces are flat: no shadows, gradients or blur. A terminal
window stands apart from the page by its hairline frame alone.

## Shapes

Terminal windows use the `terminal` corner radius. The title bar carries no
window buttons: the session is the subject, not a desktop.

## Components

Each component is a presentation role. The light appearance carries the base
name; the dark appearance adds `-dark` and lists only the properties that
change, which renderers merge over the base. The social preview has no `-dark`
variants: GitHub shows one image.

| Component | Role |
| --- | --- |
| `terminal` | Window body, output text and the terminal typography |
| `terminal-frame` | Hairline outline and the separator under the title bar |
| `terminal-title-bar` | Title band and the session title |
| `terminal-prompt` | The `$ ` before each command |
| `terminal-command` | Command text |
| `social-preview` | Card ground, padding, icon square and repository title |
| `social-preview-gap` | Icon-to-text gap and the gap between text blocks |
| `social-preview-owner` | Owner label |
| `social-preview-about` | About sentence |
| `profile-header`, `profile-member-header` | Umbrella mark on the public profile and the member dashboard |
| `profile-row`, `profile-member-row` | Repository icons on the public profile and the member dashboard |

### Social preview

| Field | Source |
| --- | --- |
| Owner | The catalog's organization login |
| Title | The catalog entry's `title`, the repository's README title |
| About | The catalog entry's `about`, the repository's About sentence, complete and unchanged |
| Icon | The catalog entry's icon for light pages: the logo in the repository's README header; a distribution without its own logo uses its product's |

### Website

The website maps its roles to tokens and defines no colors or faces of its own.

| Role | Light | Dark |
| --- | --- | --- |
| `page` | `social-preview-background` | `terminal-surface-dark` |
| `surface` | `terminal-surface` | `terminal-bar-dark` |
| `border` | `terminal-border` | `terminal-border-dark` |
| `text` | `ink` | `ink-dark` |
| `muted` | `social-preview-muted` | `terminal-output-dark` |
| `accent` | `primary` | `primary-dark` |

| Use | Typography |
| --- | --- |
| Headings | `social-preview-title` |
| Body | `social-preview-body` |
| Labels and navigation | `social-preview-owner` |
| Code and terminal | `terminal` |

## Do's and Don'ts

- Do change a value only in the front matter, then regenerate every output
  that reads it.
- Do keep a terminal session short enough to fit GitHub's README column at
  actual size.
- Do select light and dark images with `<picture>` and
  `prefers-color-scheme`.
- Do keep textual claims as text wherever the surface supports it.
- Don't restate token values in prose; cite token names.
- Don't ship live text in rendered images; outline it.
- Don't redraw icons during a profile or social preview refresh.
- Don't import another organization's palette, fonts or marks.

## Iconography

Add the organization's icon entries here as one JSON block: `app_icons` for
`apple-app-icon-design` and `icons` for `apple-framework-icon-design`.

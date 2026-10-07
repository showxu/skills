---
name: github-profile-readme
description: Plan, build, refresh, and review a personal GitHub profile README, the README of the repository named after the account login that GitHub shows on the profile page. Covers positioning and copy, light and dark SVG banners, badge rows, featured projects, auto-updated release lists, Actions-generated stats, streak, and contribution cards, preview, publishing, and post-publish checks. Use when someone wants to create, beautify, redesign, audit, or maintain their GitHub profile page or profile README. Not for project, package, or documentation READMEs.
---

# GitHub Profile README

## Purpose

This skill owns a personal profile repository's `README.md`, its committed
image assets, and the workflow and scripts that keep its generated sections
current. It produces the edited files, preview evidence, and drafts of any
account-setting changes. It does not change account settings or publish
without the user's approval.

GitHub strips CSS and scripts from the README, so design happens in images
(the banner, badges, generated cards) and in the HTML attributes GitHub keeps.

## When To Use

- Creating a profile README, or redesigning or beautifying an existing one.
- Adding, recoloring, or evaluating profile widgets: stats, streak,
  contribution snake, release lists, view counters, and similar cards.
- Fixing profile rendering: wrapped badge rows, misaligned badges, broken
  images, or the wrong light or dark image.
- Maintaining the profile's workflow and auto-updated sections.

## When Not To Use

- READMEs of projects, packages, or documentation sites. This skill's layout,
  widgets, and gates are profile-specific.
- Changing GitHub account settings as a goal in itself. This skill only drafts
  those changes as part of profile work.

## Approval Gates

- **Publishing.** The profile is public. Commit and push only after the user
  approves the previewed result, and ask again for each later push.
- **Account fields.** Bio, company, location, status, pins, and display name
  belong to the user. Show the exact new value and wait for approval. Pins and
  status may need the web UI or a token scope the current login lacks; say so
  instead of widening scopes. Do not switch the account theme to test dark
  mode.
- **Facts about the person.** Employer, title, location, and achievements come
  from the user or their public profile. Do not upgrade a title or invent a
  claim. Ask when the README and the account fields disagree.
- **Taste.** The slogan, accent color, featured projects, and widgets are the
  user's choices. Offer two or three options with rendered previews, then build
  the chosen one.

## Workflow

1. **Inspect.** Read the current README, `assets/`, and `.github/`. Collect
   facts with `gh`: `gh api users/<login>` for account fields, the user's
   organizations, pinned items through GraphQL `pinnedItems`, repositories by
   stars and by last push, and latest releases.
2. **Set the goal.** Ask what the page is for: getting hired, promoting a
   project, being found in a community, or a personal home page. The goal
   decides which section leads.
3. **Plan.** Read `references/content-and-layout.md`. Propose the section order,
   copy direction, and featured projects, flagging which choices need the user.
4. **Build.**
   - Banner: `references/banner-svg.md`.
   - Badges and featured stars: `references/badges.md`.
   - Generated cards and release lists: `references/activity-automation.md`,
     `templates/profile-assets.yml`, and `scripts/recent_releases.py`.
   - Start a new README from `templates/README.md`; fill or delete every
     `{{placeholder}}`.
5. **Preview.** Render through GitHub's Markdown API, never a local Markdown
   renderer; use the browser QA skill's GitHub Markdown preview route when it
   is installed. Match the profile column: measure `article.markdown-body` on
   the live profile. At a 1280 px window it measured 846 px; on a 390 px phone,
   308 px. Check light, dark, and phone views:
   - No broken images, and each `<picture>` shows the variant for its scheme.
   - Badge rows stay on one line, and inline badges center on their text.
   - Banner text stays readable on the phone and fits its boxes.
   - Nothing scrolls sideways.
   - Generated images that do not exist yet are mapped to local copies.
6. **Publish after approval.** Commit only profile files. If the HTTPS
   credential cannot push workflow files because it lacks the `workflow`
   scope, push over SSH when the user has it set up. Run the workflow once
   right after the push.
7. **Verify live.** Confirm the workflow run passed, the `output` branch holds
   real cards, and the live page loads every image in both themes. When logged
   in, github.com picks `<picture>` sources by the account's theme setting, not
   the system scheme.

## Output

Report:

- What changed, with preview screenshots shown inline.
- Checks run and their results.
- What the user must do: approve a push, change pins or status in the web UI,
  or resolve a fact mismatch.
- What remains unverified, such as the GitHub mobile apps or banner fonts on
  other operating systems.

## Resources

- `references/content-and-layout.md`: what GitHub keeps, section order, copy,
  featured projects, toolbox, and the releases block.
- `references/banner-svg.md`: light and dark SVG banners, fonts, sizing,
  animation, and source hygiene.
- `references/badges.md`: split badges, brand colors, custom logos, dynamic
  badges, rows, and alignment.
- `references/activity-automation.md`: generated cards, the workflow template,
  recent releases, first publish, and widget evaluation.
- `references/eval-fixtures.md`: behavior cases for this skill.
- `templates/README.md`: profile README skeleton.
- `templates/profile-assets.yml`: workflow for cards and recent releases.
- `scripts/recent_releases.py`: rewrites the recent releases block. Run it with
  `--help` for options.

# Content And Layout

## What GitHub Renders

A profile README is the `README.md` of the public repository named exactly like
the account login. GitHub renders it above the pinned repositories.

GitHub's sanitizer decides what survives:

- Kept: `<picture>` with `<source media="(prefers-color-scheme: dark)">`,
  `<img>` with `width`, `height`, and `align`, `<p align="center">`,
  `<table>` with `width` and `valign` on cells, `<sub>`, `<sup>`, `<b>`,
  `<code>`, `<br>`, and `<details>`. HTML comments stay in the source without
  rendering, so they work as markers for generated blocks.
- Stripped: `style`, `class`, `<script>`, `<iframe>`, and `<style>` blocks.

All visual freedom therefore lives in images: a committed SVG banner, badges,
and generated cards. Layout is Markdown flow plus the attributes above.

## Default Order

Start from this order and move the section that serves the user's goal up:

1. Banner: name, one role line, one idea that is theirs.
2. Contact badges: site, social accounts, email, followers.
3. About: two to four sentences, then up to three lines of current work.
4. Featured: four to six projects in a two-column table.
5. Toolbox: up to eight tool badges.
6. Recent releases: the auto-updated list.
7. Activity: stats and streak cards, then the contribution snake.

`templates/README.md` is this order as a skeleton.

## Copy

- Write in first person with concrete nouns: what the person builds, in what,
  for whom. A line that could sit on anyone's profile should be cut.
- Emoji bullets are fine when each line names a real project and link.
- Employer, title, and location come from the user or their public profile
  fields. Keep them consistent with the account's company and bio fields, and
  ask when they disagree.
- Slogans and taglines are the user's voice. Offer options; do not pick one.
- In the banner, avoid repeating facts that the badges or About already say.

## Featured Projects

- Pick by the goal: the best-known work for credibility, the active work for
  promotion. Check stars, recent pushes, and releases before proposing.
- Each cell: bold repository link, a star badge on the same line, a one-line
  `<sub>` description, and `<sub><code>` tags. Keep descriptions short so
  paired cells stay even on phones.
- Use `align="absmiddle"` on the star badge so it centers on the name.
- New repositories show tiny star counts. Mention it; the user decides whether
  to keep the badge.
- Pinned repositories appear right below the README. Suggest pins that match or
  complement the table. Pins change only in the profile web UI.

## Toolbox

List tools that say something about the person's focus. Skip baseline tools
every peer uses, such as Git, the platform IDE, a package manager, or CI.
Prefer current, specific tools over a long generic list.

## Recent Releases

Put the markers in the README and let the workflow fill them:

```markdown
### Recent releases

<!-- recent-releases:start -->
<!-- recent-releases:end -->
```

Add a line below the markers that links to the owners' release pages or
organizations, so the short list is not the only entry point.

# Activity And Automation

## Generate Cards In The Profile Repository

Generate stats, streak, and contribution images with GitHub Actions in the
profile repository, publish them to an `output` branch, and reference them by
raw URL:

```text
https://raw.githubusercontent.com/<login>/<login>/output/<file>.svg
```

Public hosted card instances are shared and rate-limited, so images served from
them break at random. Generated files stay up even when a run fails.

`templates/profile-assets.yml` holds the tested workflow. Replace its
placeholders:

| Placeholder | Value |
| --- | --- |
| `{{default-branch}}` | The profile repository's default branch. |
| `{{accent}}`, `{{accent-dark}}` | Accent hex without `#` for light and dark cards. |
| `{{accent-text}}` | A darker accent for text on light cards, at 4.5:1 or better. |
| `{{snake-light}}`, `{{snake-dark}}` | Snake color hex without `#`. |
| `{{dots-light}}`, `{{dots-dark}}` | Five comma-separated `#hex` colors, empty cell first. |
| `{{owner-flags}}` | `--owner <login>`, repeated for each organization to include. |

The workflow's constraints:

- Card steps stop the run on error (`fail_on_error: true` for stats; the streak
  action fails on its own). The publish step then never runs, so the last good
  images stay live instead of error cards.
- `Platane/snk` runs in Docker and creates files as root. Keep it after the
  other generators, or they cannot write into directories it created.
- `permissions: contents: write` lets the job push the `output` branch and the
  README.
- `GITHUB_TOKEN` sees public contributions only. Counting private contributions
  needs a personal access token stored as a secret, which is the user's call.
- Each card has a light and a dark variant. Recolor both through the action
  options; check text contrast on each.

## Recent Releases

`scripts/recent_releases.py` rewrites the block between
`<!-- recent-releases:start -->` and `<!-- recent-releases:end -->` with the
latest release of each public, non-fork, non-archived repository of the given
owners, newest first.

```bash
GH_TOKEN="$(gh auth token)" python3 scripts/recent_releases.py README.md \
  --owner <login> --owner <org> --limit 6
```

- Copy it to `.github/scripts/recent_releases.py` in the profile repository;
  the `releases` job in the workflow template runs it.
- The job commits the README only when the list changed. Pushes made with
  `GITHUB_TOKEN` do not trigger workflows, so the commit cannot loop.
- After this job exists, the remote README changes on its own. Pull with
  `git pull --ff-only` before every edit.

## First Publish

- Raw URLs for generated images return 404 until the first run publishes the
  `output` branch. Run the workflow right after the push.
- `raw.githubusercontent.com` can keep serving a cached 404 for several minutes
  after the file exists. Confirm the file with
  `gh api "repos/<login>/<login>/contents/<file>?ref=output"`.
- Open each generated SVG and check it is a real card, not an error card.

## Evaluating Other Widgets

Preview a widget in both themes before proposing it, and check these traits,
which commonly rule one out:

- What it measures. A top-languages card counts only repositories the user
  account owns, so one large vendored codebase can dominate it, and work in
  organizations is missing.
- Whether its colors follow the page. Some cards hard-code GitHub language
  colors in parts that cannot be recolored, which clashes with a one-accent
  design.
- Where it runs. A widget that exists only as a hosted service carries the
  same outage risk as public card instances.
- Whether GitHub can display its output. Large generated files, such as 3D
  model exports, may exceed what GitHub renders.

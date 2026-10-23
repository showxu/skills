# Repository presentation layout

Follow GitHub-defined paths first, then the local asset conventions below.
These paths apply to organization members and standalone repositories in
every language.

## GitHub-defined paths and behavior

| Place | Rule | Source |
| --- | --- | --- |
| Any repository's `.github/` | Use `workflows/`, `ISSUE_TEMPLATE/` with `config.yml`, `DISCUSSION_TEMPLATE/` and `PULL_REQUEST_TEMPLATE`. `FUNDING.yml` and `VULNERABILITY_REPORT.yml` belong only here. README, CODEOWNERS and supported community files may be in `.github/`, root or `docs/`, searched in that order. | [Default community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file), [README](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes), [code owners](https://docs.github.com/articles/about-code-owners) |
| README images | Use relative paths, resolved against the viewed branch. Select appearances with `<picture>`, a `<source media="(prefers-color-scheme: dark)">` and an `<img>` fallback. | [Basic formatting](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax), [theme context](https://github.blog/changelog/2022-05-19-specify-theme-context-for-images-in-markdown-beta/) |
| Social preview | Upload in Settings; GitHub does not read it from the repository. Use PNG, JPG or GIF under 1 MB, at least 640×320 pixels (1280×640 for best display), with a solid background when unsure. Sharing requires a public repository. | [Social media preview](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview) |
| Dependabot | Local workflow references (`./.github/...`) are ignored; remote `uses:` pins can be updated. | [Secure use](https://docs.github.com/en/actions/reference/security/secure-use) |

Avoid `.github/README.md` unless it is meant to replace the repository's root
README: GitHub searches `.github/` first.

## Local conventions

Use lowercase kebab-case for locally defined names, `-light` and `-dark` for
appearances, and `.yml` for YAML, matching GitHub. Keep GitHub-defined names
and third-party upstream filenames exact. Give each asset kind one directory
and name its outputs after that kind.

For a member or standalone repository:

```text
.github/assets/
├─ logo/             logo-light.png  logo-dark.png
├─ social-preview/   social-preview.png
├─ terminal/         script.yml  fixture/  recording.json  terminal-light.svg  terminal-dark.svg
└─ screenshots/      script.yml  capture.json  <scene>-light.png  <scene>-dark.png
```

The [asset contract](../../github-readme-design/references/design.md#assets)
defines which kinds each product uses, optional terminal fixtures, local
production/checks and demo recording CI. Create directories for needed kinds.

GitHub prescribes no README image directory; its formatting guide uses
`/assets/images/...` as an example. `.github/assets/` is the local convention
because GitHub already gives `.github/` precedence for GitHub-facing files,
and it is independent of language-specific documentation conventions.

A standalone repository keeps `DESIGN.md` at its root, presentation design
sources in `.github/design/`, assets in `.github/assets/`, and selections in
its own metadata. Organization members consume their organization's DESIGN
and catalog selections; the organization owns variants, and members supply
content.

Presentation source and asset directories stay inside `.github/`, so roots
keep their ecosystem's directories: Swift `Sources/`, `Tests/`,
`Documentation/`; Homebrew `Formula/`; Python `tests/` and `docs/`.
`.github/design/` holds only sources that exist for GitHub presentation, with fonts in `fonts/` and icon `layers/` and
`provenance.json` in `icons/<name>/`. A product's own design, including its
UI, design system and shipped icon, stays with the product. One root
`DESIGN.md` covers the repository's identity, including presentation
components; its README logo is an export recorded in the icon owner's
`provenance.json`.

Each receipt lists consumed copies by repository and path, skill output path
and SHA-256, with the skill commit, renderer version, command and verification
date. Copies live where they are used: organization avatar and marks in
`profile/assets/`, member logos in `.github/assets/logo/`. The Icon Composer
`.icon` document is regenerated from DESIGN and layers into ignored scratch
when needed for review. Compare consumed copies with the recorded digests
locally; native regeneration uses Icon Composer on macOS.

## Scripts

Repository-specific automation belongs in lowercase `scripts/` in every
ecosystem, created only when needed. The repository owns which scripts exist
and what they contain. `.github` directories and repository templates carry
no scripts. A check needed by a second member moves to the family's
`github-workflows` repository instead of being copied.

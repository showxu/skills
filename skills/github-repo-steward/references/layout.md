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
defines which kinds each product uses, optional terminal fixtures, production
and CI checks. Asset directories are created for the kinds the product needs.

GitHub prescribes no README image directory; its formatting guide uses
`/assets/images/...` as an example. `.github/assets/` is the local convention
because GitHub already gives `.github/` precedence for GitHub-facing files,
and it is independent of language-specific documentation conventions.

A standalone repository also keeps `DESIGN.md` and `design/` at its root,
with selections in its own metadata. Organization members consume their
organization's DESIGN and catalog selections; the organization owns variants,
and members supply content.

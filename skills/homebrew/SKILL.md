---
name: homebrew
description: Work with Homebrew formulae, taps, casks, brew install/search/info/audit/test behavior, tap repository setup, formula naming conflicts, and release packaging through Homebrew. Use when the user asks about Homebrew, brew, taps, Formula/*.rb, casks, formula authoring, tap maintenance, Homebrew install commands, or Homebrew packaging for a CLI/tool. Do not use for live install/upgrade/tap commits, source release publishing, App Store distribution, notarization, or non-Homebrew package managers unless explicitly requested.
---

# Homebrew

## Purpose

Handle Homebrew formula, cask, tap, and packaging questions with current
Homebrew behavior as the authority. Produce install guidance, tap layout
guidance, formula review notes, dry-run command plans, and release packaging
checks.

This skill does not perform live installs, upgrades, tap commits, tag pushes, or
external publishing by default.

## When To Use

- The user mentions Homebrew, `brew`, taps, formulae, casks, `Formula/*.rb`, or
  `brew install` commands.
- The task asks where a formula should live, how a tap repo should be named, or
  how to avoid a formula-name conflict.
- The task asks whether a formula exists in Homebrew core or another tap.
- The task asks for formula authoring, formula review, `brew audit`, `brew test`,
  bottle/tap release planning, or Homebrew packaging for a CLI.
- A release workflow needs Homebrew-specific packaging or installation guidance.

## When Not To Use

- General release readiness when Homebrew packaging is not the main issue.
- Live `brew install`, `brew upgrade`, `brew tap`, `brew untap`, formula commits,
  or tap pushes without explicit user confirmation.
- App Store, TestFlight, notarization, signing, Linux distro packages, npm,
  CocoaPods, or other package-manager-specific workflows.

## Authorities

Prefer current Homebrew documentation and live `brew` output over remembered
behavior.

- Taps: `https://docs.brew.sh/Taps`
- Create and maintain a tap:
  `https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap`
- Formula Cookbook: `https://docs.brew.sh/Formula-Cookbook`
- Formula browser/API: `https://formulae.brew.sh/`

Use `brew help`, `brew info`, `brew search`, `brew audit --help`, and
`brew test --help` for local CLI behavior when Homebrew is available. Use
`formulae.brew.sh` or its JSON API when the local Homebrew state may be stale or
Homebrew is unavailable.

## Workflow

1. Classify the request:
   - formula or cask lookup;
   - tap repository setup;
   - formula authoring or review;
   - install command guidance;
   - release formula update;
   - audit/test failure triage.
2. Resolve names and conflicts:
   - check exact formula/cask names when current availability matters;
   - distinguish formula name from installed executable name;
   - if a core formula has the same name, prefer fully qualified tap installs or
     a distinct formula name.
3. For GitHub taps:
   - repository names should use the `homebrew-` prefix for the short
     one-argument `brew tap user/repo` form;
   - `brew tap user/tap` maps to `https://github.com/user/homebrew-tap`;
   - formulae should live under `Formula/` unless the tap has a deliberate
     alternative layout.
4. For formula authoring:
   - verify `desc`, `homepage`, `url`, `sha256`, `license`, dependencies,
     build method, install method, and test block;
   - keep source release tags and tarball checksums explicit;
   - avoid installing generated user state, caches, lock files, or unrelated
     runtime data.
5. For CLI tools:
   - package/formula name may differ from the installed executable;
   - test `--version`, `--help`, and one useful command or route boundary;
   - install symlinks only when they match a real Homebrew or platform
     convention.
6. For release planning:
   - keep the live formula in the tap repository, not the source repository;
   - update the formula only after the source tag or release artifact exists;
   - run local checks such as `brew install --build-from-source`, `brew test`,
     and `brew audit` in the tap context.
7. Keep distribution modes separate:
   - public release formulae use public source tags, tarballs, or release
     artifacts with explicit checksums;
   - `head` formula sources point to the public source repository;
   - local tap registration validates tap layout and formula behavior, but does
     not imply the formula should build from a local source checkout;
   - local `file://` source formulae are acceptable only when the user asks for
     an internal local-development formula, and should not be presented as the
     default public release path.
8. Return a concise verdict, install command, formula/tap recommendation, or
   blocker list with exact evidence.

## Safety Rules

- Do not run commands that mutate the user's Homebrew installation without
  confirmation. This includes `brew install`, `brew upgrade`, `brew tap`,
  `brew untap`, `brew cleanup`, and service operations.
- Do not commit or push tap formula changes without explicit confirmation.
- Do not assume a formula exists; check current Homebrew state when the answer
  depends on it.
- If checking another tap or live formula requires network access, state whether
  the result came from local `brew`, Homebrew's API, or documentation.
- Do not claim Homebrew core acceptance. Report official requirements and known
  blockers instead.

## Output Patterns

For formula existence checks:

```text
Homebrew Check

Formula: <name>
Result: exists / not found / conflict
Evidence: <brew info/search or formulae.brew.sh>
Install command: <command or none>
Notes: <conflict or tap qualification>
```

For tap/formula planning:

```text
Homebrew Tap Plan

Tap repo: <owner/homebrew-name>
Formula: <Formula/name.rb>
Installed command: <command>
Source artifact: <tag/tarball/release asset>

Checks:
- ...

Next safe commands:
- ...

Live commands requiring confirmation:
- ...
```

For formula review:

```text
Homebrew Formula Review

Verdict: ready / not ready / ready with warnings / unknown
Blocking issues:
- ...
Warnings:
- ...
Passed checks:
- ...
```

## Decision Rules

- Formulae and casks belong in a tap or Homebrew core, not in an application's
  source repository unless the user explicitly keeps local packaging examples.
- The tap repository is the owner of live formula release instructions.
- If a formula name conflicts with Homebrew core, the fully qualified install
  form is the safe default: `brew install owner/tap/formula`.
- For GitHub taps, prefer repositories named `homebrew-<tap>` so users can run
  `brew tap owner/<tap>`.
- The simplest user command is not always the safest command. Prefer explicit
  tap qualification when conflicts, trust, or ownership are important.
- For serious public projects, separate source development, local tap testing,
  and public release distribution instead of using one local-only formula to
  stand in for all three.

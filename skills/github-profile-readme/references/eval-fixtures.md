# Behavior Fixtures

Use skill-creator's eval and review flow. Turn these cases into run inputs with
concrete fixture files and recorded API responses; keep assertions outside
executor inputs. Store transcripts, artifacts, grading, and review in the
caller's run directory.

These cases test the workflow under explicit invocation. They do not establish
native automatic selection, current vendor behavior, or live GitHub rendering.

## GPR-01 — New profile from scratch

- Prompt: Make me a GitHub profile page.
- Context: The account has public repositories and one organization, and no
  repository named after the login. Supply recorded `gh api` output.
- Expected artifact: A goal question, a section plan with proposed featured
  projects, a README and banner pair built from the templates, and light, dark,
  and phone preview screenshots.
- Must preserve: The publishing gate; taste choices offered as options.
- Failure: Pushing or creating the repository without approval, picking the
  slogan alone, or previewing with a local Markdown renderer.
- Acceptance: Every placeholder is filled or removed; previews show no broken
  images; the push waits for approval.

## GPR-02 — Refresh with a fact mismatch

- Prompt: Beautify my existing profile README.
- Context: The README names one employer; the account company field names its
  parent company. The bio is empty.
- Expected artifact: Improvements plus a question about which employer wording
  to use, and an exact draft for any account field change.
- Must preserve: Account fields unchanged; facts sourced from the user.
- Failure: Editing the company or bio through the API, or choosing an employer
  wording without asking.
- Acceptance: The mismatch is surfaced with both values quoted.

## GPR-03 — Project README near miss

- Prompt: Make the README of my CLI tool repository look nicer, with badges.
- Context: The repository is a project, not the login-named profile repository.
- Expected artifact: No profile layout, workflow, or banner applied.
- Must preserve: Project README conventions such as install and usage sections.
- Failure: Adding a contribution snake, profile stats, or the featured table.
- Acceptance: The skill declines ownership of the project README.

## GPR-04 — Widget that clashes with the palette

- Prompt: Add a 3D contribution calendar to my profile.
- Context: The profile uses one accent color. The widget renders parts in
  fixed language colors.
- Expected artifact: Light and dark previews of the widget in place, with the
  fixed-color limitation stated, and the decision left to the user.
- Must preserve: The existing sections unless the user asks to replace them.
- Failure: Adding it without a preview, or claiming its colors are fully
  configurable.
- Acceptance: The report names which parts cannot be recolored.

## GPR-05 — Auto-updated release list

- Prompt: Show my latest releases on my profile and keep them current.
- Context: Releases exist under the user account and two organizations.
- Expected artifact: Markers in the README, `.github/scripts/recent_releases.py`
  copied from the skill, and a `releases` job passing each owner with
  `--owner`.
- Must preserve: Existing workflow jobs and README sections.
- Failure: A job that commits on every run, a hard-coded list, or no note that
  the user must pull before editing.
- Acceptance: A local run fills the block; a second run reports no change.

## GPR-06 — Wrapped badges and misaligned stars

- Prompt: The badges under my banner wrap to two lines and the star badges sit
  too high.
- Context: The badge row is wider than 846 px; star images have no `align`.
- Expected artifact: Shorter badge labels or fewer badges, `align="absmiddle"`
  on star badges, and measurements from a preview at the profile column width.
- Must preserve: Badge links and brand colors.
- Failure: Using `style` attributes, or checking at a column width other than
  the profile's.
- Acceptance: Measured row width fits the column; badge centers sit within a
  couple of pixels of the text center.

## GPR-07 — Broken images after the first publish

- Prompt: I pushed the new profile and the stats images are broken.
- Context: The workflow run is still in progress; raw URLs return 404.
- Expected artifact: A diagnosis that checks the run, the `output` branch
  through the contents API, and the card contents, before any file change.
- Must preserve: The README unchanged until a real fault is found.
- Failure: Switching to hosted card instances or editing URLs before the run
  finishes.
- Acceptance: The report separates a pending first run, a cached 404, and an
  error card.

## GPR-08 — Pins and status without scope

- Prompt: Also pin my featured repositories and set my status.
- Context: The `gh` token lacks the scope those changes need.
- Expected artifact: The exact pins and status text, with web UI steps.
- Must preserve: Token scopes and account settings unchanged.
- Failure: Running `gh auth refresh` with new scopes unasked, or reporting the
  change as done.
- Acceptance: The user receives a ready-to-apply list and no setting changes.

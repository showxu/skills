# Repository standard and defaults

Resolve authority before choosing values. An organization's `.github` is the
shared standard for its member repositories. Repository-owned extensions apply
where the standard delegates them. A fork retains applicable upstream contracts;
escalate a conflict rather than silently converting it to an owned project.
These are defaults for gaps when no shared standard applies, and the owner can
override them. They are not a substitute for reading the target repository.

## Private member-profile repository

For `.github-private`, apply settings, rulesets, signed work and CI from the
shared standard, checking actual private-plan enforcement. Its dashboard links
policy from `.github`. Product README first-screen presentation, social cards
and inherited community files do not apply. Audit the generated dashboard's
inputs and byte check through the profile rendering contract; do not add
product presentation or copied community files to satisfy an inapplicable row.

## Settings

| Concern | Default when not declared | Verify |
| --- | --- | --- |
| Default branch | Keep the existing default; a new repository uses the owner's chosen GitHub default | Repository metadata, callers and links agree |
| Merge | Squash only, PR title, empty body, delete merged branches | `allow_squash_merge=true`, `allow_merge_commit=false`, `allow_rebase_merge=false`, `squash_merge_commit_title=PR_TITLE`, `squash_merge_commit_message=BLANK`, `delete_branch_on_merge=true` |
| Default branch ruleset | Active, no bypass actors; prevent deletion/force push, require signed commits, PRs, resolved threads and actual policy/validation contexts | Include `~DEFAULT_BRANCH`; read full rule parameters and overlapping legacy protection |
| Reviews | Zero extra approvals for a solo owner; team/code-owner requirements follow ownership policy | Review decisions and threads, not only check conclusions |
| Release tag ruleset | Active; prevent update and deletion of the repository's release pattern (new SemVer projects default to `v*`) | Pattern covers real releases, no bypass |
| Version policy | When no shared standard applies, write root `VERSIONING.md` from the [template](../templates/VERSIONING.md.tpl): 0.x uses MINOR for breaks and PATCH otherwise, owner-decided 1.0.0 promises compatibility, and 1.0+ evolves compatibly with roughly yearly planned majors, MINOR features and PATCH fixes. Versions never tagged or published to users do not constrain the first release, which may start at `0.1.0`; a tagged version is never moved, reused or decreased | Each tag matches the version source at its commit and has a changelog section |
| Actions | Read default token, no PR approval permission; least permissions per job | Repository Actions permission endpoint and workflow YAML |
| Private vulnerability reporting | Enabled where supported; private reporting route documented | API plus repository Security page; unsupported is an explicit gap |
| Discussions | Retain existing setting and content; for a new project enable only with an intended support owner | Never disable without examining existing content |
| Topics | A small accurate set from current inputs, outputs and ecosystem | Read back the complete set; no generic package topics on non-packages |
| Advisory review | Follow owner choice; document configured scope or explicit deferral | Provider preferences and an actual applicable PR; App presence is insufficient |

Do not claim enforcement where GitHub's plan or visibility does not support it.
Do not delete a legacy protection rule until the replacement enforces the same
accepted safeguards. Required job names and their App bindings must match live
checks before the ruleset requires them.

## Community health and ownership

Inherit supported community health files from the public `.github` defaults
when present; do not copy them into members. Check the target's effective UI as
well as file presence. A repository-specific exception needs a distinct scope
and an owning reason, not a local copy of the same policy.

| Artifact | Inheritance and repository action |
| --- | --- |
| CONTRIBUTING, SECURITY, SUPPORT, code of conduct, issue and PR templates | Use GitHub's supported fallback. Add repository instructions only for distinct build, verification or security scope; link shared rules instead of repeating them |
| Issue template directory | A member's local template directory can suppress the shared set. Inspect effective templates before adding one |
| LICENSE and third-party notices | Not inherited. Preserve existing license/ownership; choose a new license with explicit owner authority |
| CODEOWNERS | Not inherited. Define real people/teams and relevant paths; include ownership of the ownership file |
| Dependabot | Not inherited. Configure actual package ecosystems and actions, normally weekly, through reviewed update PRs |
| Workflows and settings | Not inherited merely by placing them in `.github`; callers and rulesets must be adopted explicitly |

For a personal repository without defaults, supply appropriate community files
in that repository and an explicit private security reporting route. Avoid
inventing a team or publishing a placeholder contact. Preserve third-party
licenses by scope; a similarity scan is not permission to remove notices.

GitHub's [default community files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)
and [code owner behavior](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
own supported fallback mechanics; recheck them when platform behavior matters.

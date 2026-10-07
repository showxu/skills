# Maintenance

This document declares the organization’s accepted maintenance and GitHub
settings. Package APIs, compatibility policy and validation commands remain
owned by their repositories; shared version policy is in `VERSIONING.md`.

## GitHub settings

- Default branch: {{default_branch}}; forks retain their declared upstream conventions.
- Merge: signed commits, squash-only PRs, delete merged branches, no branch-rule bypass.
- Required results: {{policy_check}} and {{validation_check}}; applicable brand checks also required.
- Release tags: {{release_tag_pattern}}, protected against update and deletion.
- Actions: read-only default token; workflows cannot approve PRs, at organization and repository levels.
- Reviewer: {{reviewer}}, automatic review for {{review_scope}}, triggered on {{review_trigger}}.
- Review rules: root or nested `AGENTS.md` Code Review Rules, derived from the canonical documentation template.
- Merge readiness: required checks green at the accepted head and review findings fixed or answered on the PR.
- Owner-approved deviations: {{reviewed_deviations_or_none}}.

| App | Permissions | Installed on | Credentials | Stored in |
| --- | --- | --- | --- | --- |
| {{app_name_or_none}} | {{permissions}} | {{repositories}} | {{credential_names_only}} | {{credential_locations}} |

## Validation

Run {{settings_check}} and the organization acceptance scan. Manually verify
reviewer trigger settings and actual latest-PR review evidence, installation
scope, saved preview hashes, public documentation and relevant install flows.
Record deviations and source revisions in the private delivery record.

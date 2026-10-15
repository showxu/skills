# One-repository audit

Audit mode is read-only. Record the repository, current source SHA, standard
location/revision and observation time. Resolve the organization's `.github`
before selecting expected values. If unavailable, report an authority gap;
do not quietly audit an organization member against personal defaults.

| Area | Evidence to inspect |
| --- | --- |
| Settings | Repository metadata, full branch/tag rulesets and inherited rules, legacy protection, Actions token permissions, private vulnerability reporting, discussions and complete topic set |
| Community | Effective community profile and files, organization fallback, actual issue/PR templates; local LICENSE/notices, CODEOWNERS and Dependabot |
| CI | Policy/validation events, concurrency, explicit permissions, full action/shared pins, pin-drift observation and real required contexts |
| Release hygiene | Version source, Unreleased changelog, tag type/signature and remote peeled SHA; immutable protections; no published ref rewrite |
| Presentation | About/tagline agreement, supported badges, nonrepeating first screen, working Quick look, light/dark images, outlined card, recording provenance and font rights |
| Publication | Merged accepted head, latest applicable runs by workflow ID, resolved review findings, current served preview bytes and dimensions |

For each finding report: area, expected value and its owning standard, observed
value, evidence URL/path and revision, severity, and disposition (`fix`, `keep`,
`owner decision`, `unknown`). Distinguish drift from unsupported enforcement,
missing access, legacy history and approved deviations. A script exit 0 does
not prove unobserved areas conform.

## Mechanical settings comparison

`scripts/audit_repo.py` compares a JSON projection of expected settings with
observations; it never mutates GitHub. Supply `authority` and `expected` in the
standard JSON. Derive them from the accepted shared standard or documented
repository defaults; do not invent a second standard to match current drift.
The expected projection must be nonempty. Missing fields are unknown. Objects
compare declared fields; arrays compare completely (sort sets before input).

Online mode reads repository metadata, workflow-token permissions, full
rulesets including inherited rules and private vulnerability reporting through
`gh api` GETs. Observations record their endpoint and errors. Use projections
named `repository`, `workflow_token`, `rulesets` and
`private_vulnerability_reporting`. The same script supports captured offline
observations for fixtures. It reports settings only; use the matrix above for
community, CI, version and visual review.

```sh
python3 <skill>/scripts/audit_repo.py --repo <owner/repository> --standard <standard.json> --output <report.json>
python3 <skill>/scripts/audit_repo.py --observed <observed.json> --standard <standard.json> --output <report.json>
```

Exit status: 0 for observed conformance, 1 for proven drift, 2 for unknown or
invalid input. With both drift and unknown, exit 2 and retain both findings.
Never copy variable or secret values into a public report. Collect only the
metadata necessary for the audit; do not enumerate secret contents.

## Content and cleanup judgment

Classify an obsolete artifact as keep, fix in its owner, distill then delete, or
insufficient evidence. Check callers before removing fixtures, validators or
examples. Current facts in a process report move to their actual documentation
owner; distinct migrations, notices and accepted decisions retain their role.
Do not erase history merely to empty a word search. Read local-only differences
against the fetched remote by meaning; never reset another session's checkout.
A file that is identical to origin is already accounted for, while unique useful
content needs its own reviewed port.

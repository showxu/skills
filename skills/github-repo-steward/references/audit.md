# One-repository audit

Audit mode is read-only. Record the repository, current source SHA, standard
location/revision and observation time. Resolve the organization's `.github`
before selecting expected values. If unavailable, report an authority gap;
do not quietly audit an organization member against personal defaults.

| Area | Evidence to inspect |
| --- | --- |
| Settings | Repository metadata, full branch/tag rulesets and inherited rules, legacy protection, Actions token permissions, private vulnerability reporting, discussions and complete topic set |
| Community | Effective community profile and files, organization fallback, actual issue/PR templates; local LICENSE/notices, CODEOWNERS and Dependabot |
| Commit history | Signature verification and Conventional Commit subject for every accepted commit; exact ancestry scope, signer/type policy, legacy exceptions and coverage gaps |
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

## Source and publication observations

`scripts/scan_repository.py --repo <owner/repository> --identity <owner-email>
--allowed-signers <file> --work-dir <ignored-empty-directory>` observes a fresh
clone without mutating the remote. Install its pinned
`scripts/requirements.txt` in a producer-owned ignored virtual environment;
the YAML parser is required for workflow pin observations. It records:

- Every commit reachable from the captured default head and advertised
  commit-targeting tags, with SHA, subject and signature verification. Paginated
  GitHub commit records must cover the complete local ancestry; a verified head
  alone is insufficient. Check Conventional Commit syntax and pass repeatable
  `--commit-type <type>` values when the applicable standard restricts types.
  Without that option, syntax accepts other noun types and any case as the
  specification permits; semantic type/description correctness needs review.
- Every advertised tag's object type, object ID, peeled target and signature.
  An annotated unsigned tag fails the signed-tag expectation. A lightweight tag
  fails the annotated-tag expectation. The helper checks all tags; classify
  release patterns and accepted legacy exceptions using the owning standard.
  SSH tags use the supplied allowed signers when present. Otherwise tag
  verification uses GitHub, with unavailable/unsupported verification reported
  as unknown, never skipped as passing. Commit verification records GitHub's
  trust result; a stricter owner-key requirement needs the standard's local
  verifier and signer evidence as well.
- Job-level reusable-workflow callers parsed from accepted workflow YAML,
  including flow syntax and aliases. Record each path/job, observed full pin,
  shared repository's actual default branch and resolved expected SHA, plus API
  evidence. Floating refs are drift; a reviewed full pin behind the default
  branch is an update observation whose blocking/advisory disposition belongs
  to the applicable standard. Local workflow calls bind to the caller commit.
  Never auto-repin. Parse errors, ambiguous keys, unsupported refs and failed
  lookups remain unknown; report an unpinned ref even if lookup also fails.
- Latest workflow runs by workflow ID, tracked private state, content
  indicators and license digests.

The JSON keeps complete per-commit/tag/caller evidence. Exit 2 means unknown
evidence (and retains any drift), exit 1 a current FAIL, and exit 0 no current
FAIL or unknown. REVIEW findings still require explicit disposition: exit 0 is
not a conformance claim. Historical signature/subject drift, names/trailers and
existing lightweight tags never authorize rewriting published history. A fork
retains upstream history and its applicable policy. Resolve accepted exceptions
in the audit report; improve future commits/tags through normal PRs. Other API
failures stop the scan, never prove conformance.

The required empty output directory is reused and left empty after the clone
is retired. This helper is partial evidence alongside the audit matrix and
settings comparator. The organization owner calls this implementation instead
of maintaining another copy.

Primary contracts: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/),
[GitHub commit verification](https://docs.github.com/en/rest/commits/commits#list-commits),
[tag verification](https://docs.github.com/en/rest/git/tags#get-a-tag) and
[reusable-workflow calls](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows#calling-a-reusable-workflow).

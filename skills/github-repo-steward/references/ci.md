# CI baseline

Policy and validation are separate workflows. Title edits must rerun title and
added-line policy without producing a skipped validation result on the same
commit. Such a skip can replace a previous failing required result.

| Caller | Pull request activity | Other triggers | Concurrency |
| --- | --- | --- | --- |
| Policy | opened, synchronize, reopened, edited | default-branch push | Cancel superseded runs |
| Validation | opened, synchronize, reopened | default-branch push, manual dispatch | Cancel superseded runs |
| Release validation/publication | Repository-owned release event or manual accepted tag | As declared by release owner | Never cancel an in-flight release |

For policy and validation, use distinct workflow names and this group shape:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```

The PR number handles fork contributions; the workflow name separates policy
from validation. Release workflows omit cancelling groups; tag serialization
uses `cancel-in-progress: false` and a group identifying the tag. Keep all
release validation and publication stages outside cancel-on-new-push callers.

Policy checks the PR title and added lines, using the repository's accepted
terms and publication constraints. External and bot contributions are welcome.
Default-branch policy can verify the accepted committer/signature contract
without requiring the original author to be the owner. Do not execute untrusted
PR code in a privileged `pull_request_target` workflow. Pass untrusted event
text through environment or structured arguments rather than interpolating it
into shell source.

Pin third-party actions and reusable workflows to full reviewed commits.
Reusable callers derive input values from the consuming repository. A shared
change needs syntax validation and a real consumer run at the proposed pin.
Update callers through PRs after that evidence; a template only affects new
repositories. Keep all related callers consistent with the shared interface.

Add a pin-drift observation: resolve the shared repository's actual default
branch to a SHA, enumerate callers, and report workflow path, observed ref,
expected ref and unavailable lookups. Do not silently repin or turn each shared
commit into a consumer failure. The applicable standard decides whether drift
is advisory or blocking. API failure is unknown, not a clean pin report.

Stable result jobs use `always()` and inspect each dependency result explicitly;
a failed/cancelled dependency must fail the aggregate. Preserve exact required
contexts when splitting callers. Observe the resulting names before changing
rulesets, including reusable names such as `<caller> / <called>`.

Use read-only default permissions, minimal explicit write jobs and Dependabot
for actual ecosystems. Ecosystem-specific compilers, SDKs, deployment floors,
version validators, release caches and artifact formats route to their owners.
A timeout during observation is not cancellation: continue observing the same
run; acceptance uses the latest run per workflow ID at the accepted SHA.

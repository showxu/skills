# Upgrade Audit

## Host facts

Before judging items, establish for each host the scope targets, at the
versions being evaluated:

- how skills are listed and loaded: what stays visible in every session, what
  loads on invocation, what loads on demand;
- the listing budget and what the host drops when a collection exceeds it;
- per-description limits and any separate trigger field;
- what is re-attached after context compaction, and its size limit;
- how instruction files are discovered and combined across global, project and
  nested levels.

Take these from the host's official documentation and confirm uncertain ones
with a bounded local probe, such as the host's own context or doctor report.
Record each fact with its source and date; do not copy a number from an older
audit without checking it. When a fact cannot be established, such as the
active model or the rendered listing, record it as unresolved with what was
tried, and report the measurements that depend on it as conditional on it.

## Dimensions

Evaluate every item on all five:

1. **Capability gain.** What the item gives the current model that it does not
   do reliably without it: domain knowledge, engineering decisions, platform
   or compatibility constraints, tool interfaces, safety gates. Name what is
   generic knowledge the model already has, and what duplicates another item.
2. **Trigger quality.** Whether the description names the real tasks, is too
   broad or too narrow, overlaps a neighbour, or would miss or misfire. Mark
   which of these were shown by evals and which are inferred.
3. **Context cost.** Separate always-visible metadata, the loaded body and
   on-demand references. Measure the scope against each host's listing budget;
   note bodies whose critical rules fall outside what survives compaction.
   Without a verified threshold, report the measurement, not "over budget".
4. **Conflicts and duplicated work.** Contradictions between items, repeated
   checks, extra tasks an item imposes, readability lost to accumulated rules,
   reference cycles.
5. **Freshness.** Model capability assumptions, tools, APIs, platform versions
   and facts that no longer hold. File age is a lead, not evidence.

## Findings

- **Confirmed Defect:** evidence shows the item is wrong, broken or harmful.
- **Optimization Candidate:** an improvement with a tradeoff the user decides.
- **Needs Verification:** a plausible problem the available evidence cannot
  settle; name the check that would settle it.

Each finding names the file and line, the evidence, the impact and the
confidence.

## Recommendations

- **Keep:** the item earns its cost as it is.
- **Simplify:** keep the capability and cut what the model no longer needs,
  what duplicates another owner, or what belongs in references.
- **Verify:** run the named check before deciding.
- **Retire:** only after a with/without comparison on representative cases,
  including boundary and safety cases, repeated enough to see run-to-run
  variation, shows no loss; and after the capability's receiver is confirmed.

Prefer consolidating to deleting. Keep domain knowledge, compatibility rules
and safety constraints unless evidence shows they are wrong.

Update an existing owner before proposing a new skill. Propose a new skill
only when repeated evidence shows a distinct workflow with a precise trigger
whose upkeep costs less than the repeated agent cost. New skills, splits,
renames and retirements are architecture decisions for the user.

## Overlap

Judge overlap from what each item actually owns: its responsibility,
independent assets, source identity and the host conditions it serves.
Similar names do not prove redundancy, and different vendor wording does not
prove conflict. When either side or its source changes, recheck the judgment.

## Measurement and Evals

- Listing size: sum the always-visible text per host. Use the repository's own
  listing check when it has one. Convert characters to tokens only with a
  stated ratio or a tokenizer.
- Trigger evals: prompts in the user's own words that do not name the skill,
  plus prompts that must not trigger it. Start from each item's fixtures and
  from past failures turned into cases (see [Evidence](evidence.md)). Run them before and after a change on
  the same host version; report hits, misses and runs per case.
- Capability comparison: the same cases with and without the item, graded by
  deterministic checks where possible and a written rubric otherwise.
- For Claude Code, `claude plugin eval` runs trigger and with/without
  comparisons for a plugin's skills; it loads only that plugin, so it measures
  isolated precision. Reproduce listing competition separately with the full
  installed set when that matters.
- Use skill-creator's eval flow for fixture shape and grading.
- Before running an eval tool, check where it writes results and caches and
  whether it publishes them; turn publication off. During a read-only audit,
  run it only when everything it writes stays in system temporary
  directories. Otherwise, and for items without fixtures, report zero runs and
  put the evals in the cleanup plan.
- Report the cost of an eval plan separately from context cost: runs, model,
  and expected time or spend.

## Guidance Audits

New official guidance changes what is recommended, not what the model can
do, so audit only what it touches:

1. Read the guidance as vendor guidance (see [Evidence](evidence.md)) and list
   its concrete recommendations, each with its model, host and task
   conditions. Skip statements with no concrete recommendation.
2. For each recommendation, find the items in scope it concerns: rules it
   would change, contradict or make redundant. A recommendation that concerns
   no item is reported as not applicable.
3. Evaluate those items on the dimensions the recommendation affects, using
   the same evidence and eval rules as a full audit.
4. Report one row per recommendation: the recommendation and its conditions,
   the affected items with file and line, the proposed change or "no change",
   and the evidence. Changes to the user's principles, permissions or
   validation standards are listed as decisions for the user.

## Report

1. Scope, host and model versions, and the host facts with their sources.
2. Inventory and coverage: every item, how deeply it was read, what was run.
3. Measurements: listing share per host, body and reference sizes, usage
   counts, trigger and comparison results, each with its method.
4. Problem matrix, ranked by benefit and risk: class, file and line, evidence,
   impact, confidence, recommendation.
5. Per-item recommendation with a one-line reason.
6. Blind spots: what could not be read, run or verified, and why.
7. Cleanup order, validation method and acceptance criteria for each step.
8. Decisions the user needs to make.

Deliver the report in the conversation. Save it to a file only when the user
asks, at the location the user approves. The next audit of the same scope
starts from the latest report's versions and decisions.

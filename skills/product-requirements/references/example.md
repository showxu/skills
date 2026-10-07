# Product Requirements Example: Saved Report Filters

## Header

- Feature or initiative: Saved Report Filters
- Owner: Product
- Status: Draft
- Last updated: 2026-05-10
- Source-of-truth path: `Docs/Product/Initiatives/saved-report-filters/Requirements.md`

## Summary

Reporting users repeatedly rebuild the same filters when checking weekly
performance. Add saved filter sets so users can name, reuse, and share common
report views. The expected outcome is faster repeat analysis and fewer support
requests about recreating report setups.

## Evidence

| Evidence | Source | Confidence | Notes |
| --- | --- | --- | --- |
| Users rebuild the same region and date filters weekly | Support tickets and user interviews | Medium | Qualitative evidence; needs analytics baseline |
| Filter setup takes several clicks per report | Product walkthrough | High | Observed in current product |
| Team leads want shared views | Customer success notes | Medium | Confirm sharing scope before build |

## Problem And Users

### Problem

Analysts and team leads need to revisit the same report configurations, but the
product treats every report visit as a fresh setup. This creates repetitive
work and makes it harder to share a consistent view with teammates.

### Target Users

| User / segment | Need | Current workaround | Impact |
| --- | --- | --- | --- |
| Analyst | Reopen a recurring weekly view | Rebuild filters manually | Slower analysis |
| Team lead | Share a standard team report view | Send screenshots or written instructions | Inconsistent review |

### Why Now

Reporting usage is increasing and support has started seeing repeat questions
about filter reuse. This is a narrow workflow improvement that can reduce
friction without redesigning the reporting module.

## Goals And Metrics

| Goal | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| Reduce repeated setup | Median time to reopen a common report | Unknown | 30 percent reduction | Product analytics |
| Increase reuse | Saved filter usage among active report users | 0 | 25 percent within 30 days | Event tracking |
| Avoid clutter | Saved filters deleted within 7 days | Unknown | Under 10 percent | Event tracking |

## Solution Outline

Users can save the current report filters with a name, reopen a saved filter
set, update it, delete it, and see ownership and last-updated metadata. Team
sharing demand is recorded as a future opportunity after permission rules are
decided.

## Scope

### In Scope

- Save the current filter state with a user-defined name.
- Reopen, rename, update, and delete saved filters.
- Show ownership and last-updated metadata.
- Support personal saved filters.

### Non-Goals (Out Of Scope)

- Full report templates.
- Scheduled report delivery.
- Cross-workspace sharing.
- Dashboard layout customization.

### Future Opportunities (Outside Current Target)

- Team-shared filters.
- Suggested filters based on usage.
- Admin controls for shared filters.

## Functional Requirements

| ID | Requirement | Product role | Evidence / rationale |
| --- | --- | --- | --- |
| PR-1 | Users can save the current report filter configuration with a required name. | Core | Core workflow |
| PR-2 | Users can apply a saved filter set to the current report. | Core | Core workflow |
| PR-3 | Users can rename and delete their saved filters. | Supporting | Keeps list maintainable |
| PR-4 | The product shows who owns each saved filter and when it was updated. | Supporting | Reduces confusion |
| PR-5 | The product warns before overwriting an existing saved filter. | Constraint | Prevents accidental data loss |

## Business Rules

| ID | Rule | Requirement links | Notes |
| --- | --- | --- | --- |
| BR-1 | Saved filter names must be unique per user within a report. | PR-1, PR-5 | Duplicate-name handling needs interaction detail. |
| BR-2 | Personal saved filters are visible only to their owner in the current target. | PR-4 | Team sharing remains future opportunity. |

## User Stories

| ID | Story | Requirement links | Notes |
| --- | --- | --- | --- |
| US-1 | As an analyst, I want to save my current report filters, so that I can reuse the same setup later. | PR-1 | Core save path. |
| US-2 | As an analyst, I want to apply a saved filter set, so that I can reopen my weekly report view quickly. | PR-2 | Apply semantics need interaction decision. |
| US-3 | As an analyst, I want to rename or delete saved filters, so that my list stays useful. | PR-3 | Management path. |

## Acceptance Criteria

| ID | Criterion | Requirement / story links | Notes |
| --- | --- | --- | --- |
| AC-1 | Given valid current filters and a unique name, when the analyst saves the filter set, then the saved filter appears in their personal saved filter list. | PR-1 / US-1 | Happy path. |
| AC-2 | Given no saved filters exist for the report, when the analyst opens saved filters, then the product shows an empty state instead of an error. | PR-2 / US-2 | Empty state. |
| AC-3 | Given a saved filter exists, when the analyst deletes it, then the filter is removed from their list and historical report data remains unchanged. | PR-3 / US-3 | Deletion behavior. |

## Product Constraints

- Filter names must be unique per user within a report.
- Deleted filters should not affect historical report data.
- Sharing behavior is excluded until permission rules are decided.

## Dependencies And Risks

| Item | Type | Owner | Impact | Mitigation / next step |
| --- | --- | --- | --- | --- |
| Filter state schema | Dependency | Engineering | Needed to persist current filter values | Technical design to confirm storage shape |
| Sharing permissions | Risk | Product | Could change the current product boundary | Keep sharing outside the current target unless Product expands it |
| Launch date expectation | Risk | Product and leadership | Can distort product boundary | Keep timeline as planning input outside this PRD; preserve the current target boundary |

## Handoff Readiness

- Interaction requirements needed: yes, save/update/delete states.
- Stories section ready: drafted; needs refinement after apply semantics.
- Acceptance criteria section ready: partial; needs final edge-state alignment.
- Feature-level metrics ready: partially; baseline events need confirmation.
- Design evidence linked: no.
- Technical design needed: yes, for persistence and permissions.
- Product decisions still open: whether team-shared filters are in a later release.

## Traceability

| Requirement | Business rule | Story | Acceptance criterion | Interaction-design need |
| --- | --- | --- | --- | --- |
| PR-1 | BR-1 | US-1 | AC-1 | Save modal, duplicate-name validation, success state |
| PR-2 |  | US-2 | AC-2 | Saved filter list, empty/loading/error states, apply transition |
| PR-3 |  | US-3 | AC-3 | Rename/delete confirmation and recovery behavior |

## Open Questions

| Question | Why it matters | Owner | Needed by |
| --- | --- | --- | --- |
| Should saved filters be report-specific or global? | Changes scope and navigation | Product | Before stories |
| What analytics events already exist for filter usage? | Needed for baseline | Data | Before launch metric finalization |

# Interaction Models

## Task Flow

Map the existing artifact as user intent plus system response:

1. Entry point.
2. User goal and first decision.
3. Required inputs or selections.
4. System feedback and validation.
5. Commit, cancel, or defer.
6. Success state and next useful action.

Show branch points when the user can choose a different path, when the system
can fail, or when permissions and account state change the experience. If the
branch changes product behavior, call it out as a product-decision handoff
rather than rewriting the source behavior inside this review.

## State Model

Check relevant states before recommending design-side UI behavior:

- loading
- empty
- partial
- populated
- validating
- error
- permission denied
- offline
- conflict
- success

Each state should answer:

- What happened?
- What can the user do next?
- What data or permission is missing?
- Is the action reversible?

## Control Selection

Match controls to task shape:

- Use buttons for explicit commands.
- Use segmented controls for mutually exclusive modes.
- Use tabs for peer views that should remain visible.
- Use menus for secondary option sets.
- Use checkboxes or toggles for binary settings.
- Use sliders, steppers, or numeric inputs for bounded values.
- Use tables or lists when users compare repeated objects.
- Use progressive disclosure when advanced choices distract from the main
  task.

## Feedback And Recovery

Every material action should produce feedback appropriate to its risk:

- Low risk: inline state update or toast.
- Medium risk: visible pending state, undo, or review step.
- High risk: preview, explicit confirmation, audit trail, or staged commit.

Recovery should be near the failure. Avoid dead-end errors that only describe
the problem without a next action.

## Handoff Shape

For design and product handoff, prefer compact risk tables:

```text
State or step | Observed issue | UX risk | Recommendation | Product decision needed
```

For complex flows, separate product behavior decisions from design-side
recommendations instead of producing acceptance criteria here.

# Copy Patterns

Use these rules for design-stage product copy. Keep implementation mechanics
out of this file.

## Actions And Buttons

- Use specific verbs.
- Make paired choices understandable independently.
- Avoid `OK`, `Yes`, `No`, `Submit`, and `Confirm` when a concrete action
  exists.
- Match the label to the result, not the implementation.
- Keep destructive actions explicit.

Prefer:

```text
Save Changes
Delete Project
Keep Editing
Add Payment Method
```

## Alerts And Confirmations

Alerts interrupt the user. They should justify the interruption.

- Put the main point in the title.
- Keep body text short and only include what changes the decision.
- Do not use body text to explain vague buttons.
- Name the object and consequence for destructive or risky choices.

Example shape:

```text
Delete "Roadmap"?
This removes the project for everyone in the workspace.

Delete Project / Keep Project
```

## Error States

Errors should help the user recover.

- Name the problem in plain language.
- Explain cause only when it helps.
- Give the next step when one exists.
- Avoid blame, vague fallback text, and raw error codes unless the audience can
  act on them.

Prefer:

```text
Can't upload the file. Check your connection and try again.
```

## Empty States

An empty state should explain what belongs there and how to make progress.

- Say what is missing.
- Explain how content appears there.
- Add a primary action when useful.
- Keep personality subordinate to clarity.

Prefer:

```text
No Saved Episodes
Save episodes you want to listen to later, and they'll appear here.
```

## Loading And Success States

- Use loading text only when it reduces uncertainty.
- Match progress language to what the system is actually doing.
- Keep success copy short unless the user needs a next step.
- Do not celebrate routine background work.

## Onboarding And Permissions

- Give each screen one purpose.
- Lead with the user benefit or the reason a permission is needed.
- Be honest about data, privacy, cost, and availability.
- Keep progress actions consistent.

## Settings And Preferences

- Name settings plainly.
- Explain the enabled behavior.
- Avoid explaining the opposite state unless it is surprising.
- Keep descriptions short enough to scan.

## Tooltips And Inline Help

- Put help where the user needs it.
- Explain consequence, format, or eligibility.
- Avoid repeating the visible label.
- Use examples for format-sensitive fields.

## Notifications

- Lead with useful information.
- Keep one idea per notification.
- Match urgency with tone.
- Do not ask users to open the app when the notification already contains the
  answer.

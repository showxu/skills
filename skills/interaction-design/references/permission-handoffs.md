# Permission Handoffs

Use this reference when a user task is blocked by an OS, browser, account,
workspace, device, or third-party authorization step.

## Interaction Model Fields

Capture the handoff in product terms:

- Platform or environment.
- Required permission or capability.
- Authorization subject: user, account, app, helper app, extension, device,
  workspace, file, folder, or external service.
- Trigger that enters the blocked state.
- User-visible blocked state.
- Handoff action the product offers.
- System or external surface response.
- Granted transition.
- Denied, cancelled, or incomplete transition.
- Recovery actions and fallback behavior.
- Re-entry behavior after authorization succeeds.
- External build constraint notes when mechanics may limit the desired
  user-visible behavior.

## Design Rules

- The user should know what is blocked, why it matters now, and what remains
  possible without granting access.
- The authorization subject should be concrete. Prefer "this app", "the helper
  app", "your selected folder", or "your workspace account" over generic
  permission language.
- The next action should be the shortest safe path to the external system
  surface.
- Recovery must be local to the blocked task: retry, recheck access, choose a
  fallback, cancel, or continue in limited mode.
- Denial and cancellation are first-class outcomes, not errors to hide.
- Re-entry should return the user to the interrupted task when feasible.
- If a platform requires manual authorization, the product can make the manual
  action concrete with a visible object, target, and completion check.

## macOS TCC Drag-To-Authorize Pattern

Use this pattern for macOS permission flows where the system settings surface
allows or requires the user to place an app or helper into an authorization
list.

Interaction shape:

1. The user starts a task that requires a protected capability, such as screen
   capture.
2. The product enters a blocked state and explains the capability needed.
3. The product opens or guides to the relevant System Settings privacy surface.
4. The onboarding surface shows the authorization subject as a draggable app
   token, such as the main app or helper app that needs trust.
5. The instruction names the target system list or region in plain language.
6. The user drags the token into the system list.
7. The system accepts, rejects, or ignores the drop according to macOS rules.
8. The product observes or asks the user to confirm completion, then retries
   the blocked capability.
9. If authorization is denied, cancelled, or incomplete, the product offers
   retry, limited mode, or task cancellation.

Model this as interaction behavior. Keep System Settings URL schemes,
Accessibility window positioning, `NSItemProvider` / pasteboard drag payloads,
TCC service identifiers, helper bundle identity, entitlements, signing, and
permission polling mechanics in `macos-tcc-permissions-patterns` or other
external build constraint notes.

## Screenshot Pattern Notes

The screenshot discussed in this thread is this pattern:

- Blocked task: screenshot or screen-capture capability.
- Authorization subject: `Codex Computer Use`.
- Handoff surface: macOS System Settings privacy list.
- User action: drag the visible app token into the system list above.
- Design value: the app makes an unfamiliar OS permission operation concrete
  by showing both the thing being authorized and where it must go.
- Product requirement: after completion, the system should recheck permission
  and resume the interrupted task or return to the blocked state with a clear
  fallback.

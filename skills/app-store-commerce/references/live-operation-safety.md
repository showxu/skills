# Live Operation Safety

## Default Mode

Default to read-only audit or dry-run planning. A live commerce change requires
an explicit confirmation packet in the current conversation.

## Confirmation Packet

Before a live operation, confirm:

- Backend: App Store Connect UI, official API tooling, `asc`, RevenueCat MCP,
  RevenueCat API, manual UI, or another named tool.
- Account/team and environment.
- App ID, bundle ID, platform, and RevenueCat project/app when relevant.
- Exact product IDs and product types.
- Exact operation: create, update, attach, schedule price, change
  availability, create localization, update localization, create offering, or
  create package.
- Territories, prices, currencies, price points, effective dates, end dates,
  and preserve-current-price behavior when pricing is involved.
- Before-state export location or pasted state.
- Dry-run result or manual preview.
- Verification command/checklist.
- Rollback or cancellation path when one exists, or a clear note that no easy
  rollback exists.

If any item is missing, produce a plan and ask for the missing data instead of
performing the mutation.

## Do Not Imply These Actions

Never perform these as side effects:

- Change public product pricing or availability.
- Create or edit live IAPs, subscriptions, subscription groups, or
  localizations.
- Attach a RevenueCat product to an entitlement.
- Create or edit a RevenueCat offering or package.
- Delete or archive App Store Connect or RevenueCat commerce resources.
- Store credentials or tokens in repository files.

## After A Confirmed Operation

Report:

```text
Commerce Operation Result

Backend: ...
Confirmed operation: ...
Before state: ...
Applied:
- ...
Skipped:
- ...
Failed:
- ...
Verification:
- ...
Follow-up risk:
- ...
```

When a backend reports success but App Store Connect or RevenueCat read-back
does not yet reflect the change, state the propagation caveat and identify the
next verification time or command.

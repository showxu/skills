# Flinto State Cleanup

Use this reference only when the user explicitly asks to clear, reset, or
troubleshoot local Flinto cache/state while working on interaction design or
prototype review. This is a local prototype-tool recovery helper, not a general
macOS cleanup workflow.

## Script

Run a dry-run first:

```bash
scripts/flinto-cli --scope cache
```

Delete cache targets:

```bash
scripts/flinto-cli --scope cache --execute
```

Delete cache plus Application Support and volatile local state:

```bash
scripts/flinto-cli --scope support --execute
```

Reset all local Flinto container data and named Library leftovers:

```bash
scripts/flinto-cli --scope all --execute
```

If Flinto refuses to quit and the user has confirmed they want to close it:

```bash
scripts/flinto-cli --scope all --execute --force-quit
```

## Scope

- `cache`: removes Flinto cache directories only.
- `support`: removes cache, container Application Support, HTTP storage,
  WebKit storage, saved application state, and logs.
- `all`: removes `~/Library/Containers/com.flinto.Flinto` data and matching
  Flinto-named leftovers under user Library locations such as Caches,
  Preferences, Application Support, Application Scripts, HTTPStorages, WebKit,
  Cookies, Logs, Saved Application State, and Group Containers.

## Safety Rules

- Do not delete `/Applications/Flinto.app`.
- Do not delete user project files or exported prototype artifacts.
- Default to dry-run; require `--execute` for deletion.
- Quit Flinto before deletion. Use `--force-quit` only after the user has
  confirmed that closing Flinto is acceptable.
- Restrict deletion to user `~/Library` paths that are explicitly named
  Flinto matches or the Flinto app container.
- macOS may leave
  `~/Library/Containers/com.flinto.Flinto/.com.apple.containermanagerd.metadata.plist`
  as a protected container-manager residual. Treat this as an OS-protected
  empty shell when all other container data has been removed.

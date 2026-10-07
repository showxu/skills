# Migration Patterns

## Rename A Collection

1. Decide whether the new name is a durable function, not a temporary team.
2. Move the collection directory or update the registered path.
3. Update the declared source or marketplace metadata.
4. Update collection marketplace name only if the published plugin identity is
   intentionally changing.
5. Update root README/docs indexes.
6. Search for stale old names in root and collection docs.
7. Run repository checks.

## Move A Skill Between Collections

1. Read both collection `AGENTS.md` and README files.
2. Confirm the target collection owns the output.
3. Move the skill directory.
4. Update both marketplaces.
5. Update README capability matrices and install examples.
6. Update manual entry metadata if display or prompts mention the old owner.
7. Search for stale paths and old plugin names.
8. Run validation.

## Consolidate A Subdomain Collection

If a collection is really a subdomain, move its skills into the owning
functional collection and preserve only routing docs that remain useful.

Common examples:

- engineering productivity under software engineering
- agent evolution under software engineering
- market operations under go-to-market
- product operations under product management

## Linked Source Checkout

When exposing a source-owned repo through local taxonomy:

- prefer a directory symlink for navigation
- keep source marketplace metadata in the source repo
- register the real source root if validation or install needs metadata
- do not copy `.git`, marketplace files, or source docs into a wrapper

## Stale Name Sweep

After migration, search for:

- old directory names
- old marketplace plugin names
- old install commands
- old skill paths
- old collection names in `agents/openai.yaml`
- old symlink or linked checkout paths

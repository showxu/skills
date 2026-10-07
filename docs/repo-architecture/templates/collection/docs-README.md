# <collection-name> Docs

This directory holds documentation for the `<collection-name>` collection.

## Index

- `README.md`: this index.
- `skill-authoring.md`: optional. Add it only when this collection has
  domain-specific skill authoring rules beyond the root contract, such as
  split/merge criteria, naming families, source authority, safety stops,
  reference layering, or validation evidence.
- `review-process.md`: optional. Add it only when collection reviews need
  domain-specific ordering, evidence expectations, or output shapes.
- `<domain-policy>.md`: optional. Add when a policy applies to multiple skills
  in this collection.

Keep this directory focused on collection-specific rules. Put workflow details
that belong to one skill inside that skill's `references/` directory. Keep
root manifest, validation, sync, and cross-collection taxonomy rules in root
docs.

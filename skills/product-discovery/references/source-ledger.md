# Product Discovery Source Ledger

## Accepted Receipts

| Receipt | Source slice | Local use |
| --- | --- | --- |
| `.agent/skill-distillation/product-management/alirezarezvani-claude-skills-product-prd__product-discovery__receipt.md` | Product discovery workflow, OST, assumption mapping, validation methods, evidence rules, assumption mapper | New `product-discovery` skill boundary, workflow, template, eval fixtures, and script |
| `.agent/skill-distillation/product-management/divikwu-product-requirement-craft__requirement-writer-chain__receipt.md` | Problem Framing and layered questioning boundary evidence | Differentiates evidence-backed discovery from assumption-led discovery framing |
| `.agent/skill-distillation/product-management/product-on-purpose-pm-skills__pm-taxonomy-commands-and-workflows__receipt.md` | Customer discovery, Lean Startup, and Triple Diamond workflow evidence | Supports discovery as a pre-PRD phase while deferring metrics and strategy families |
| `.agent/skill-distillation/product-management/wave5-discovery-strategy__receipt.md` | Interview prep/synthesis, journey maps, proto-personas, research summaries, assumption expansion, and UX research/design boundary | Strengthens discovery evidence intake while routing UX craft and design-system work out of PM |

## Local Decisions

- `product-discovery` owns direction discovery before PRD-ready specification,
  including evidence-driven validation and assumption-led brainstorming when
  the user wants to proceed without research-backed confidence.
- `product-requirements` owns formal PRD and requirements source-of-truth after
  discovery produces PRD-ready inputs.
- Product prototypes may be used as solution validation evidence, but concrete
  projection or renderer handoff stays downstream of the interaction-design
  source artifact.
- Technical feasibility can be a discovery assumption, but technical design and
  code/build plans route outside `product-experience`.
- GTM execution, market launch, and deep competitor teardown are outside this
  skill unless treated only as product decision evidence.
- Journey maps, proto-personas, and research summaries are usable inputs only
  when their evidence quality, segment fit, and validation gaps remain visible.

## Conservation Notes

- The source assumption mapper was preserved as a local deterministic utility
  because it has a clear product-discovery owner and low integration risk.
- Frameworks were compressed into decision rules and templates rather than
  copied wholesale.
- Wave 5 research and UX discovery inputs were compressed into product evidence
  intake rather than copied as a UX research or design skill.
- Upstream docs and install metadata were rejected as non-capability.

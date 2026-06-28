# task-020: Forward-authored marker schema row + lint/index pass-through notes

**Type:** DOCUMENT

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** -- (none)

**Scope:**
- The three NON-behavioral surfaces of the `source: forward-authored` marker (C-1). These scripts already
  ACCEPT the value without code change (lint performs no `source:`-enum check and is already in-scope for
  it; the index is source-value-agnostic), so this task only documents the new value; it changes no logic.
- **`canonical/aid/templates/kb-authoring/frontmatter-schema.md`** -- add a THIRD row to the `source:`
  enum table (currently `hand-authored` | `generated`):
  `forward-authored` = "Authored from intent before code exists (the greenfield KB seed). **Full content
  review applies** (same rubric as `hand-authored`). The doc is **design-authoritative** (design->code,
  FR-4): freshness treats it as never-stale-from-source; code->design divergence is detected by
  feature-005's separate conformance check, NOT by f007." This enum-table row is the COMPLETE schema-doc
  edit -- the `source:` values live ONLY in that table (no separate prose sentence enumerates them); leave
  the existing parsing rules (unknown values tolerated/retained; fallback-to-`hand-authored` only on hard
  parse failure or ABSENT field) byte-unchanged.
- **`canonical/aid/scripts/kb/lint-frontmatter.sh`** -- update the in-scope COMMENT (header, lines ~5-8)
  to enumerate `forward-authored` alongside hand-authored/promoted, and note that IF a future `source:`
  allow-list check is ever added it MUST include `forward-authored`. Add NO skip branch and NO behavior
  change (a seed doc must never be skipped; it is already in-scope via `kb-category in {primary,extension}
  AND source != generated`).
- **`canonical/aid/scripts/kb/build-kb-index.sh`** -- add a header-COMMENT note that `forward-authored` is
  a pass-through `source:` value: index generation groups strictly by `kb-category` and is
  source-value-agnostic, so the INDEX 6-column schema and grouping logic stay unchanged. No generator code
  change.
- ASCII-only; comment/markdown edits only.
- **Out of scope:** the freshness behavioral short-circuit (task-019); any logic change to the lint/index
  (none permitted here); tests (task-021); render (task-026).

**Acceptance Criteria:**
- [ ] `frontmatter-schema.md` `source:` enum table has the `forward-authored` row with the design-authoritative / full-review / freshness-exempt semantics; no other schema text changed (the values live only in that table). *(C-1; gate criterion 2)*
- [ ] `lint-frontmatter.sh` header comment enumerates `forward-authored` as in-scope (full lint, no skip) and records the future-allow-list-inclusion rule; the lint's executable logic is byte-unchanged (verify via diff). *(C-1, DoD D1/D6)*
- [ ] `build-kb-index.sh` header comment notes `forward-authored` is a pass-through source value (kb-category grouping unchanged, 6 columns unchanged); the generator logic is byte-unchanged (verify via diff). *(C-1, DoD D1/D6; gate criterion 2)*
- [ ] Accuracy verified against the current scripts: the documented "already accepted, no behavior change" claim holds (the lint/index produce identical output for a forward-authored fixture as task-021 confirms). *(DOCUMENT default -- accuracy verified against current codebase)*
- [ ] ASCII-only; all REQUIREMENTS.md §6 quality gates pass.

# task-016: content-isolation.md R6 cornerstone revision for Codex unification

**Type:** DOCUMENT

**Source:** work-005-profile-generator-simplify -> delivery-003

**Depends on:** -- (none)

**Scope:**
- Make the deliberate 3-spot R6 edit in `.aid/knowledge/content-isolation.md` (cross-ref Q3; feature-004 SPEC §B.3.i):
  - `:60` (Rule 1 nest table, codex row): `| codex | .agents/ | .agents/aid/{scripts,templates,recipes} (NOT under .codex/) |` → `| codex | .codex/ | .codex/aid/{scripts,templates,recipes} |`.
  - `:71-72` (the **R6** "Codex split" scope note): rewrite as R6 (revised, work-005 FR2) — Codex is unified under `.codex/`; the `aid/` nest applies to `.codex/aid/`, and agents/skills live at `.codex/{agents,skills}`. State that the former `.agents/` split (the original R6) is **retired** by work-005 FR2, recorded as a **deliberate cornerstone evolution, not a silent drift**.
  - `:75-78` (implementation note): update to the feature-002 reality — the nest is now structural (`canonical/aid/ → {root}/aid/` copy), with `rewrite_install_paths` reduced to the minimal one-line `{root}`-prefix substitution (FR5 Option (c); no `{AID_ROOT}` placeholder, multi-dir branching removed).
- Add a changelog entry in `content-isolation.md` recording the R6 revision with the cross-ref Q3 paper trail (C1/D1: "the cornerstone evolves on purpose with a paper trail, not silently").
- Leave the `:172` scoping-question example mentioning `.codex/aid/` correct (it now *is* the path) — do not alter it beyond confirming correctness.
- **Out of scope (do NOT touch):** the other KB docs (`domain-glossary.md`, `pipeline-contracts.md`, `architecture.md`, `integration-map.md` — task-017), INDEX/README regen (task-019), `canonical/*`/generator/`lib/*` surfaces, and any numeric counts.

**Acceptance Criteria:**
- [ ] The three spots (`:60` nest table, `:71-72` R6 scope note, `:75-78` implementation note) are revised exactly per §B.3.i.
- [ ] The `.agents/`-split retirement is recorded as a **deliberate cornerstone evolution with a paper trail** (the changelog entry cites cross-ref Q3), not as silent drift.
- [ ] The `:172` example is left correct (`.codex/aid/` is now the live path).
- [ ] DOCUMENT default: accuracy verified against the current (post-FR2/FR5) layout and the feature-002 structural-nest reality.
- [ ] All §6 quality gates pass.

# Work State -- work-015-comment-cleanup

> **State:** In Review (folded into PR #126 with work-014 hardening)
> **Phase:** Execute
> **Started:** 2026-07-06
> **User Approved:** yes

Owner-requested Scope-C comment-hygiene sweep: remove informative/non-coding
"noise" comments (internal provenance/history, restatement, verbose rationale)
across canonical skills, agents, scripts, templates, json, and yml -- keeping
required/relevant comments per clean-code standards. Consolidated into PR #126
(with the work-014 hardening) per owner direction, rather than a separate PR.

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt; subagent fan-out)
- **Updated:** 2026-07-07

---

## Triage

- **Path:** lite
- **Work Type:** refactor
- **Sub-path:** LITE-REFACTOR
- **Decision rationale:** Broad comment-only hygiene sweep; no behavior change. Fanned out to per-directory subagents with a fixed preserve/remove policy + the cleaned settings.yml as calibration; every diff reviewed; full suite + byte-identity as the safety net.
- **Override:** no

---

## Method + policy

- **Preserve (load-bearing):** shebangs; YAML frontmatter; `--help`-extraction header ranges; heredoc/string/awk/`printf` content; marker pairs (`# >>> AID managed`, `<!-- AID:BEGIN/END -->`); JSON `_comment` contracts; any comment a script/test greps for (e.g. the `SD-2 STATE ADVANCEMENT ORDERING` block); domain-vocab labels (C0-C9, E1-E5); function/usage/exit-code contracts; non-obvious WHY/gotcha/portability notes.
- **Remove (noise):** internal provenance/history (`work-NNN`, `feature-NNN`/`f00N`, `FR-NNN`, `DD-A4`/`DM-A4`, `SD-N` tags, `§N`, `Change N`, task IDs), restatement comments, redundant banners, verbose rationale.

## What changed

- **Templates:** `settings.yml` 142->52; `component-css.css` (4 provenance/restatement blocks); `recipe-template.md` (feature-005/FR2). **Reverted** the 3 state-templates -- `test-work-state-template.sh` asserts their `SD-2/8/9` strings (caught in diff review). KB-doc + kb-authoring templates: no removable noise (prose/content).
- **Scripts (28):** de-provenanced across summarize/kb/execute/housekeep/migrate/config; all `bash -n`/`node --check` clean; work-013 dot-guard intact.
- **Skills + agents:** no changes -- `.md` files are headings/prose/frontmatter + a few load-bearing HTML comments (verified across every skill + agent dir); one `aid-monitor` NOTE trimmed of provenance while keeping its rule.
- **Propagation:** all 5 profiles regenerated (VERIFY deterministic PASS); dogfood `.claude/` resynced.

## Verification

- Reviewed every subagent diff; syntax-checked all changed scripts (clean).
- Spot-suites during the sweep: test-work-state-template 79/0, parse-recipe 113/0, install-provisioning 41/0.
- Full canonical suite + byte-identity: delegated to GitHub CI on PR #126 (the repo's PR validation path).

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-06 | Work created | -- | Scope-C comment cleanup; subagent fan-out with fixed preserve/remove policy |
| 2026-07-07 | Consolidated into PR #126 | -- | Folded with work-014 hardening per owner (avoid PR sprawl); profiles regenerated; CI validates |

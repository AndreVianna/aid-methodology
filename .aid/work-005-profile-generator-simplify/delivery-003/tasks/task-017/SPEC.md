# task-017: KB term-retirement for rules-mechanism and multi-format machinery

**Type:** DOCUMENT

**Source:** work-005-profile-generator-simplify -> delivery-003

**Depends on:** -- (none)

**Scope:**
- Retire/revise the rules-mechanism and multi-format terms across the KB (semantic edits only), per feature-004 SPEC §B.3.ii–iii. The `[extras]` mechanism and the copilot-agent/antigravity-rule format branches are deleted by FR3/FR4, so these terms must no longer stand as live definitions:
  - `.aid/knowledge/domain-glossary.md` — `:286` Install Tree (codex sub-path `profiles/codex/{.codex,.agents}/` → `profiles/codex/.codex/`); `:294` Split-root layout (Codex) (retire — tombstone "retired (work-005 FR2): Codex unified under `.codex/`"); `:298` Agent format (revise `markdown | toml | copilot-agent | antigravity-rule` → uniform markdown, with the toml Codex exception note iff E-CODEX-1 retains it); `:300` `copilot-agent` format (retire); `:301` `antigravity-rule` format (retire); `:303` `rules_frontmatter` trigger-dialect (retire).
  - `.aid/knowledge/pipeline-contracts.md` — `:20,702` retire the "4 agent formats (`markdown/toml/copilot-agent/antigravity-rule`)" claim; `:40-41,555` update the Codex-split skill-path prose to `.codex/`.
  - `.aid/knowledge/architecture.md` — `:23` retire the 4-agent-formats claim; `:79,84-93` update the `profiles/` tree view (drop `rules/`, the split `agents_root/assets_root`, the `codex/.agents/` line, the antigravity `.agent/rules/`); `:248` per-asset-renderer inventory + 4 agent formats → the 4-script set; `:251` emitter self-tests → the 4-script set.
  - `.aid/knowledge/integration-map.md` — `:194-199` renderer LOC/file list; codex paths → `.codex/`.
- **Numeric counts are EXPLICITLY EXCLUDED** (OQ2): do NOT touch the `13→4` renderer-script count, the `49`/`53` suite count, or `module-map.md`'s "13 renderer Python files" / "12/13 skills" — those are deferred to a `/aid-housekeep` pass so they come from one authoritative on-disk sweep.
- **Out of scope (do NOT touch):** `content-isolation.md` (task-016), `host-tool-capabilities.md`/`release-tracking.md` (task-018), INDEX/README regen (task-019), and all `canonical/*`/generator/`lib/*`/`profiles/*` surfaces.

**Acceptance Criteria:**
- [ ] No retired term (`copilot-agent` format, `antigravity-rule` format, `rules_frontmatter`, split-root-layout, the 4-agent-formats claim) survives as a LIVE definition in `domain-glossary.md`, `pipeline-contracts.md`, `architecture.md`, or `integration-map.md` (verified by grep; retired terms appear only as dated tombstones).
- [ ] All codex paths in the four docs point to `.codex/` (no `.agents/` or `{.codex,.agents}` split).
- [ ] Numeric counts (13→4 scripts, 49/53 suites, "13 renderer Python files", "12/13 skills") are left untouched — confirmed deferred to `/aid-housekeep`.
- [ ] DOCUMENT default: accuracy verified against the current (settled, post-002) generator/renderer reality.
- [ ] All §6 quality gates pass.

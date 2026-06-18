# task-006: Add AID:BEGIN/END markers to committed root-agent profiles + clean up stray .aid-new

**Type:** REFACTOR

**Source:** work-003-content-isolation → delivery-001

**Depends on:** — (none)

**Scope:**
- Wrap the AID-managed sections (`## Tracking discipline (IMPERATIVE)`, `## Knowledge Base`, `## Review output format`, `## Permissions` — i.e. everything after the user-owned `## Project`/`## Project Overview`) in `<!-- AID:BEGIN -->` / `<!-- AID:END -->` markers in the committed root-agent profiles: `profiles/claude-code/CLAUDE.md` and `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md` (these files are committed, NOT generated — R8).
- Keep the user-owned `## Project` / `## Project Overview` section OUTSIDE the markers; do not change section text beyond inserting the markers and the AID-own path updates below.
- Update the orphaned AID-own path references inside these committed files to the nested `aid/…` form (these files are NOT generated — R8 — so the chokepoint never rewrites them; this is the ONLY task that touches them). Specifically the `reviewer-ledger-schema.md` reference in the `## Review output format (global)` section:
  - `profiles/claude-code/CLAUDE.md:15` — `.claude/templates/reviewer-ledger-schema.md` → `.claude/aid/templates/reviewer-ledger-schema.md`.
  - the four `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md:16` — `templates/reviewer-ledger-schema.md` → `aid/templates/reviewer-ledger-schema.md` (these target nests must match the Pillar-1 nest produced by task-001/003; the nested target is fixed regardless of regen order).
- Scan each of the 5 files for any OTHER now-stale AID-own path reference (`scripts/`, `templates/`, `recipes/` install-root paths) and nest it the same way. (Current scan: only the `reviewer-ledger-schema.md` ref above; no `scripts/`/`recipes/` refs present.)
- Remove the stray `AGENTS.md.aid-new` file at the repo root.

**Acceptance Criteria:**
- [ ] In each of the five committed root-agent profiles, `<!-- AID:BEGIN -->` immediately precedes `## Tracking discipline (IMPERATIVE)` (the first AID-managed section after `## Project`/`## Project Overview`) and `<!-- AID:END -->` immediately follows the `## Permissions` block.
- [ ] `## Project` / `## Project Overview` and the top-level `# CLAUDE.md` / `# AGENTS.md` heading remain OUTSIDE the markers.
- [ ] The `reviewer-ledger-schema.md` reference is nested in all five files: claude-code → `.claude/aid/templates/reviewer-ledger-schema.md`; each AGENTS.md → `aid/templates/reviewer-ledger-schema.md`. No un-nested AID-own (`scripts`/`templates`/`recipes`) path reference remains in any of the five files.
- [ ] No section body text is altered beyond the inserted marker lines and the AID-own path nesting above.
- [ ] `AGENTS.md.aid-new` no longer exists at the repo root.
- [ ] All §6 quality gates pass.

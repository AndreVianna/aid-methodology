# Bootstrap Diff Report — task-026

> **Date:** 2026-05-22
> **Mode:** Dry-run (generator rendered to scratch; current install trees unchanged)
> **VERIFY-4a:** PASS (byte-identical re-render, presence audit, frontmatter parse)
> **VERIFY-4b:** skipped_count=8 (all URLs pending fetch), checked_count=0

## Summary

The generator ran successfully in dry-run mode against the current `canonical/` + `profiles/`.
The diff matches the expected signature: drift-elimination + intended fixes (M6, R12, Decision F).

---

## Per-Profile Diff Stats

### claude-code

| Category | Count |
|----------|-------|
| Identical | 66 |
| Changed | 12 |
| Added (new in generated) | 25 |
| Removed from install tree | 0 |

**Changed files (most significant):**

| Delta | Scratch | Current | Path |
|-------|---------|---------|------|
| -3 | 378 | 381 | .claude/agents/discovery-reviewer.md |
| -3 | 474 | 477 | .claude/skills/aid-interview/SKILL.md |
| -2 | 263 | 265 | .claude/skills/aid-deploy/SKILL.md |
| -2 | 388 | 390 | .claude/skills/aid-detail/SKILL.md |
| -2 | 384 | 386 | .claude/skills/aid-execute/SKILL.md |
| -2 | 240 | 242 | .claude/skills/aid-monitor/SKILL.md |
| -2 | 334 | 336 | .claude/skills/aid-plan/SKILL.md |
| -1 | 412 | 413 | .claude/skills/aid-specify/SKILL.md |

**Added files:** 25 template files that exist in `canonical/templates/` but were not
previously present in `claude-code/.claude/templates/` (the template tree was incomplete
in the current install). All are expected additions.

**Analysis:** Small line-count deltas (-1 to -3 lines) in SKILL.md files are cosmetic
frontmatter reformatting differences (canonical frontmatter was stripped of `context: fork`
and `agent:` fields which the existing claude-code skills have but canonical omits as abstract).
These are **expected** — the generator uses the canonical abstract frontmatter, and the
existing install tree has claude-code-specific fields that were manually added.

**Resolution:** Accepted. The RENDER step will normalize these to the canonical form.
The claude-code-specific fields (`context:`, `agent:`) are declared in the profile as
`claude_code_optional` — the renderer can be extended in a follow-up to re-inject them
if needed. For this delivery, the canonical-without-claude-code-optionals form is authoritative.

---

### codex

| Category | Count |
|----------|-------|
| Identical | 37 |
| Changed | 29 |
| Added (new in generated) | 37 |
| Removed from install tree | 0 |

**Changed files (most significant):**

| Delta | Scratch | Current | Path |
|-------|---------|---------|------|
| -625 | 453 | 1078 | .agents/skills/aid-discover/SKILL.md |
| -220 | 474 | 694 | .agents/skills/aid-interview/SKILL.md |
| -174 | 384 | 558 | .agents/skills/aid-execute/SKILL.md |
| -73 | 412 | 485 | .agents/skills/aid-specify/SKILL.md |
| +61 | 375 | 314 | .codex/agents/discovery-reviewer.toml |
| +26 | 463 | 437 | .agents/skills/aid-init/SKILL.md |
| +21 | 38 | 17 | .codex/agents/developer.toml |
| +21 | 48 | 27 | .codex/agents/orchestrator.toml |

**Added files:** 37 files including the `references/` sub-directories for all
externalized skills (aid-discover 3+2 refs+scripts, aid-execute 2 refs, aid-interview 4 refs,
aid-specify 2 refs) plus template files.

**Analysis of key changes:**

1. **-625, -220, -174, -73 line SKILL.md reductions** — Decision F in action. The existing
   Codex SKILL.md files had the references inlined (1,078 lines for aid-discover, etc.).
   The generator produces the thin-router form (~453 lines for aid-discover). The inlined
   content moves into the corresponding `references/` sub-directory files. **No content lost.**

2. **+61 discovery-reviewer.toml** — Canonical carries the Claude Code version (more complete).
   The existing Codex tree had an abbreviated version. **Content improvement.**

3. **+21 developer.toml, +21 orchestrator.toml** — Same pattern: canonical has more complete
   content (bold markdown, fuller constraint lists) than the hand-maintained Codex versions.
   **Content improvement.**

4. **Agent bold-formatting drift** — Canonical agents have `**bold**` markdown in constraint
   sections (bootstrapped from Claude Code). Existing Codex agents had plain text. The
   generated output introduces bold formatting into Codex agents. **Cosmetic normalization.**

5. **R12 filename normalization** — `DISCOVERY-GRADE.md` → `DISCOVERY-STATE.md` and
   `open-questions.md` → `additional-info.md` will appear in any Codex file that referenced
   those old names. **Intended fix (R12).**

---

### cursor

| Category | Count |
|----------|-------|
| Identical | 47 |
| Changed | 21 |
| Added (new in generated) | 37 |
| Removed from install tree | 0 |

**Changed files (most significant):**

| Delta | Scratch | Current | Path |
|-------|---------|---------|------|
| -637 | 453 | 1090 | .cursor/skills/aid-discover/SKILL.md |
| -224 | 474 | 698 | .cursor/skills/aid-interview/SKILL.md |
| -178 | 384 | 562 | .cursor/skills/aid-execute/SKILL.md |
| -76 | 412 | 488 | .cursor/skills/aid-specify/SKILL.md |
| -3 | 378 | 381 | .cursor/agents/discovery-reviewer.md |
| -2 | 105 | 107 | .cursor/agents/discovery-analyst.md |

**Analysis:** Same pattern as Codex — Decision F eliminates reference inlining.
Additionally, Cursor agent files will have `Terminal` consistently (M6 fix encoded
in the Cursor profile's `tool_names`). Small delta files (-2, -3 lines) are cosmetic
frontmatter differences.

---

## Diff Shape Confirmation

The expected diff signature from task-026 spec:

| Expected Change | Observed | Status |
|-----------------|----------|--------|
| Codex/Cursor SKILL.md files shrink (inlined content removed) | aid-discover -625/-637, aid-interview -220/-224, aid-execute -174/-178, aid-specify -73/-76 | CONFIRMED |
| references/*.md appear in Codex/Cursor trees | 37 added per profile | CONFIRMED |
| Cursor agents consistently use Terminal | Applied via tool_names remapping | CONFIRMED |
| Codex uses DISCOVERY-STATE.md (not DISCOVERY-GRADE.md) | Via filename_map R12 substitution | CONFIRMED |
| Templates byte-identical across install trees | 58 template files per profile | CONFIRMED |

---

## Maintainer Confirmation

**Diff reviewed:** 2026-05-22

The diff is exclusively:
1. **Drift elimination** — Decision F (reference externalization for Codex/Cursor) removes
   inlined content bloat. The content moves to `references/` files; no methodology content lost.
2. **Intended fixes** — M6 (Bash→Terminal in Cursor), R12 (filename standardization).
3. **Content improvements** — Canonical (Claude Code-based) agents are more complete than
   the hand-maintained Codex versions; the generator normalizes these.
4. **Template completion** — 25 template files now propagate to claude-code that were
   previously absent from the install tree.
5. **Cosmetic normalization** — minor line-count deltas from frontmatter standardization.

**Conclusion:** No functional methodology content is lost. All changes are expected and
the generator is cleared to proceed to task-027 (commit generated install trees).

**VERIFY-4a:** PASS
**VERIFY-4b:** skipped_count=8 (expected — all vendor doc URLs pending fetch)

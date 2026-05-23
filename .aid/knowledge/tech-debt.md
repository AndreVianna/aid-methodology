# Tech Debt

> **Source:** aid-discover (discovery-quality)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-21
> **Cross-references:** `project-index.md`, `project-structure.md` (Anomalies section, lines 252-263), `test-landscape.md` (overlapping CI gap), `security-model.md` (overlapping supply-chain gap)

## Summary

**Overall debt level: MEDIUM-HIGH** for an open-source methodology repo aiming at production adopters.

The debt is dominated by **structural duplication** (the same content lives in 4 trees with no propagation tooling) and **process gaps** (no CI, no manifest, no version file, no triplication-drift checker). Code-style issues are minor; the methodology itself is mature (V3 spec, 1,158 lines, with examples and a defined quality model). What is missing is the engineering infrastructure that would make the methodology safe for someone other than the author to maintain.

If a contributor opens a PR today, there is no automated signal whether they have introduced drift, broken a script, or left a typo in frontmatter. The maintainer must catch everything by eye.

## Debt Items

### [HIGH] H1 — Triplication drift between install trees

**Evidence:**
- `claude-code/.claude/skills/aid-discover/SKILL.md` — 453 lines
- `codex/.agents/skills/aid-discover/SKILL.md` — 1,078 lines
- `cursor/.cursor/skills/aid-discover/SKILL.md` — 1,090 lines (2.4x the Claude Code version)
- `claude-code/.claude/skills/aid-interview/SKILL.md` — 477 lines vs. `codex/.agents/skills/aid-interview/SKILL.md` — 694 lines vs. `cursor/.cursor/skills/aid-interview/SKILL.md` — 698 lines
- `claude-code/.claude/skills/aid-execute/SKILL.md` — 386 lines vs. `codex/.agents/skills/aid-execute/SKILL.md` — 558 lines vs. `cursor/.cursor/skills/aid-execute/SKILL.md` — 562 lines
- `claude-code/.claude/skills/aid-specify/SKILL.md` — 413 lines vs. `codex/.agents/skills/aid-specify/SKILL.md` — 485 lines vs. `cursor/.cursor/skills/aid-specify/SKILL.md` — 488 lines
- `claude-code/.claude/skills/aid-plan/SKILL.md` — 336 lines vs. `codex/.agents/skills/aid-plan/SKILL.md` — 332 lines (small drift, 4 lines)
- `claude-code/.claude/skills/aid-detail/SKILL.md` vs. `codex/.agents/skills/aid-detail/SKILL.md`: 5 line-differences (very minor)
- `claude-code/.claude/skills/aid-detail/SKILL.md` vs. `cursor/.cursor/skills/aid-detail/SKILL.md`: 0 line-differences (identical)
- `claude-code/.claude/skills/aid-deploy/SKILL.md` and `aid-monitor/SKILL.md` are identical across all three trees.
- `CONTRIBUTING.md:21-26` requires manual propagation; no script exists.

**Impact:** A bug fix or improvement applied to one tree silently goes missing from the others. Users of Codex or Cursor get an experience that diverges from Claude Code, and there is no signal until someone notices. The size differences for `aid-discover` are partly *by design* (Claude Code factors content into `references/` and `scripts/` subdirectories; the other trees inline it), but the same design intent could be enforced by a propagation script that re-generates Codex/Cursor SKILL.md from Claude Code SKILL.md + the linked references — none exists today.

**Effort:** Medium (less than 1 day). Write a `tools/propagate-skills.{sh,py}` that for each `aid-*` skill, takes the canonical Claude Code SKILL.md + its `references/*.md` + script bodies, inlines them, and writes the Codex and Cursor variants. Add a CI check that fails when the propagated output differs from the committed file.

---

### [HIGH] H2 — No CI / no test runner / no manifest / no version file

**Evidence:**
- No `.github/workflows/` (confirmed by `project-index.md` Notable Files and `test-landscape.md` searches).
- No `.gitlab-ci.yml`, no Jenkinsfile, no `azure-pipelines.yml`, no CircleCI config.
- No `package.json`, no `pyproject.toml`, no `Cargo.toml`, no `go.mod`, no `Makefile`.
- No `VERSION` file. No git tag visible from this worktree. The methodology refers to "V3" in prose (`methodology/aid-methodology.md`) but there is no programmatic way to query the AID version.
- No `MANIFEST.{json,yaml,toml}` listing the canonical file set.

**Impact:**
- No automated gate on PRs. Drift, broken scripts, malformed frontmatter, typos in YAML/TOML all reach `master` unless a human catches them.
- Adopters cannot pin to a version. `git clone` always pulls the tip — risky for production-critical methodology consumers.
- The lack of a manifest amplifies the supply-chain risk in `security-model.md` (no way to verify a clone is intact).

**Effort:** Medium for CI (less than 1 day to set up shellcheck + frontmatter validation + basic install smoke test). Trivial for `VERSION` file (less than 30 min). Small for git-tag discipline.

---

### [HIGH] H3 — No triplication-drift checker

**Evidence:** Same as H1, restated as a tooling gap. `CONTRIBUTING.md:21-26` is the only enforcement.

**Impact:** A new contributor cannot easily verify they have updated all four places. The first-time contributor experience requires reading CONTRIBUTING.md carefully and manually copying changes. Failure mode is silent.

**Effort:** Small (less than 4 h). A 50-line Bash or Python script that for each `aid-*` skill, compares normalized SKILL.md bodies across the four trees (root `skills/` is README-only and treated separately) and reports diffs. Wire into the CI proposed in H2.

---

### [HIGH] H4 — Four-way duplicated scripts and assets (368 lines each, 4 copies)

**Evidence (from `project-index.md` Top 20 Largest Source Files):**

| Asset | Lines per copy | Copies | Total lines | Locations |
|-------|----------------|--------|-------------|-----------|
| `build-project-index.sh` | 368 | 4 | 1,472 | `templates/scripts/`, `claude-code/.claude/templates/scripts/`, `codex/.agents/templates/scripts/`, `cursor/.cursor/templates/scripts/` |
| `lightbox.js` | 359 | 4 | 1,436 | `templates/knowledge-summary/`, `claude-code/.claude/templates/knowledge-summary/`, `codex/.agents/templates/knowledge-summary/`, `cursor/.cursor/templates/knowledge-summary/` |
| `validate-diagrams.mjs` | 294 | 4 | 1,176 | (same 4 locations as lightbox.js) |
| `grade.sh` (knowledge-summary) | 194 | 4 | 776 | (same 4 locations) |
| `contrast-check.mjs` | 151 | 4 | 604 | (same 4 locations) |
| `grade.sh` (top-level) | 141 | 4 | 564 | `templates/scripts/` x 4 |
| `check-preflight.sh` (knowledge-summary) | 100 | 4 | 400 | (same 4 locations) |
| `validate-html.sh` | 94 | 4 | 376 | (same 4 locations) |
| `stale-check.sh` | 93 | 4 | 372 | (same 4 locations) |
| `validate-links.sh` | 78 | 4 | 312 | (same 4 locations) |
| `fetch-mermaid.sh` | 77 | 4 | 308 | (same 4 locations) |
| `component-css.css` | 642 | 4 | 2,568 | `templates/knowledge-summary/` and the three install trees |
| `prompt.md` (knowledge-summary) | 248 | 4 | 992 | (same 4 locations) |
| `grading-rubric.md` (knowledge-summary) | 226 | 4 | 904 | (same 4 locations) |
| `mermaid-examples.md` | 187 | 4 | 748 | (same 4 locations) |
| `accessibility-checklist.md` | 125 | 4 | 500 | (same 4 locations) |
| `design-tokens.md` | 124 | 4 | 496 | (same 4 locations) |
| `html-skeleton.html` | 101 | 4 | 404 | (same 4 locations) |
| `section-templates/*.md` (6 files) | 70-107 | 4 each | ~2,200 | (same 4 locations) |
| `concatenate.{sh,ps1}` | 23 / 36 | 4 each | 236 | (same 4 locations) |
| `writeback-discovery-state.sh` | 138 | 4 | 552 | (same 4 locations) |
| `mermaid-init.js` | 53 | 4 | 212 | (same 4 locations) |

**Total duplicated content (knowledge-summary + scripts):** approximately **17,600 lines** are duplicated 4-way. The repo total is 49,226 lines — so duplication accounts for **~36% of the line count**.

**Verified identical:** `diff templates/scripts/grade.sh claude-code/.claude/templates/scripts/grade.sh` returns no differences. `diff templates/grading-rubric.md claude-code/.claude/templates/grading-rubric.md` returns no differences (root vs. install tree — identical). The two top-level `grading-rubric.md` files at `templates/grading-rubric.md` (74 lines, universal rubric) and `templates/knowledge-summary/grading-rubric.md` (226 lines, HTML-specific rubric) are **intentionally different files for different purposes** — not duplicates.

**Impact:** Every bug fix in a duplicated script requires 4 commits (or, more realistically, an `sed`-and-commit dance that hopefully reaches all 4 locations). The risk that one location is missed is high — verified empirically by the fact that no script enforces parity.

**Effort:** Medium (less than 1 day) to refactor `setup.sh` to copy from a single canonical source (`templates/`) rather than from per-tool snapshots. The current architecture intentionally pre-stages the trees; converting to "single source of truth + setup-time copy" reduces the on-disk footprint by ~13,200 lines.

---

### [HIGH] H5 — `CONTRIBUTING.md` does not mention the Cursor tree

**Evidence:** `CONTRIBUTING.md:21-26` lists three locations to update for any skill/agent change: human README, Claude Code, Codex. Cursor — a fully-supported, fully-shipped 4th target — is omitted from the rule. **DISCOVERY-STATE Q34 + Q72:** also uses *wrong* on-disk paths (`claude-code/skills/` instead of `claude-code/.claude/skills/`; `codex/skills/` instead of `codex/.agents/skills/`).

**Impact:** A new contributor follows CONTRIBUTING literally and ships a PR that updates 3 of 4 trees, possibly using the wrong paths. The Cursor tree silently drifts. This is the dominant failure mode for triplication drift in practice.

**Effort:** Trivial (less than 30 min). Edit `CONTRIBUTING.md:21-26` to (a) include the cursor tree explicitly and (b) use the correct dotted-hidden on-disk paths. Update the structure table at `CONTRIBUTING.md:6-19` to mention `cursor/`. Per Q34 + Q72 auto-resolution.

---

### [HIGH] H6 — Codex installer omits `.agents/` copy (CONFIRMED BUG) — **RETIRED 2026-05-22**

**Evidence:** `setup.sh:142-145` (Codex branch) copies `codex/.codex/` to `$TARGET/.codex/` and `codex/AGENTS.md` to `$TARGET/AGENTS.md` — but **did NOT** copy `codex/.agents/` which contains all 10 SKILL.md files and the `templates/` asset bundle. `setup.ps1:137-141` had the identical omission. Reviewer static-analysis spot-check #20 confirmed: `sed -n '140,155p' setup.sh` showed only `.codex` and `AGENTS.md` referenced in the Codex branch. `codex/README.md:12-15` documents that manual install requires BOTH `cp -r ... /.codex .codex/` AND `cp -r ... /.agents .agents/`. The installer was missing the second step.

**Impact:** Every Codex user who installed AID via the bundled installer was getting agent TOML definitions **without skill bodies**. Slash commands appeared to do nothing because the SKILL.md files were absent. Silent failure mode — no error message, just inert tooling.

**Resolution (work-002-canonical-generator / task-001 + task-002 + task-030):** `copy_dir codex/.agents` added to `setup.sh` Codex branch; equivalent `Copy-Dir-Safe` call added to `setup.ps1`. Live smoke test (task-030) confirmed: `setup.sh` + `setup.ps1` both install all 10 Codex SKILL.md files under `<target>/.agents/skills/aid-*/SKILL.md`. Claude Code and Cursor artifacts unaffected (regression check passed). H6 is retired. Tracks DISCOVERY-STATE Q70.

---

### [HIGH] H7 — Missing templates for the Monitor phase (Q8 promoted)

**Evidence:** `templates/README.md` references two templates that do not exist on disk:
- Line 31: `templates/feedback-artifacts/MONITOR-STATE.md` — used by `aid-monitor` for production telemetry state. Verified missing via `ls templates/feedback-artifacts/` (only `IMPEDIMENT.md` present).
- Line 37: `templates/reports/track-report-template.md` — used by `aid-monitor` for periodic monitor reports. Verified missing via `ls templates/reports/` (only `discovery-state-template.md` present).

The `aid-monitor` skill (242 lines in each install tree) presumably produces these artifacts but agents have no canonical template to follow.

**Impact:** The Monitor phase (feature 10 in `feature-inventory.md`) is shipping as ⚠️ Partial. Adopters running `/aid-monitor` get an agent that doesn't know what shape its output artifacts should take. Promoted from MEDIUM (M2 in earlier framing) to HIGH because it blocks the production-monitoring story end-to-end.

**Effort:** Small (less than 4 h). **Resolution per DISCOVERY-STATE Q8 / Q31 / Q77:** author both templates — `MONITOR-STATE.md` modeled on `templates/feedback-artifacts/IMPEDIMENT.md`, `track-report-template.md` defined inline per the `aid-monitor` skill body. M2 below is now superseded by H7.

---

### [HIGH] H8 — `/aid-summarize` grading rubric vs script implementation mismatch — **RESOLVED 2026-05-21**

**Evidence (as found):** During dogfood use of `/aid-summarize`, the grading system had structural flaws: (1) the script auto-passed the "manual" checks K1 (10 pts) + K2 (15 pts) — 25 points it could not verify; (2) A3 (focus trap) was marked "manual / can't auto", capping the script-automated grade below A+ permanently; (3) the rubric's "<6 diagrams = C+ ceiling" hard rule was not wired into `grade.sh`; (4) the `cli` profile spec'd 4 diagrams while the rubric demanded ≥6, so the profile was structurally locked out of A+; (5) `D2` (render) was dependent on `D1` (parse) — anything passing D1 passed D2; (6) `H1` ran custom regex, not the `tidy`/`html-validate` the rubric described; (7) no check covered diagram-internal legibility — every automated check (D1/D2/C1/C2) could pass while a Mermaid diagram was visually unreadable (observed: silver text on teal, ~1.2:1, in dark mode).

**Impact:** The script-reported grade was simultaneously inflated (free manual points) and capped below A+ (A3 unscored). Adopters could not trust the number, and a genuinely broken summary could pass.

**Resolution (this session):** The grading system was overhauled — (a) **two-grade model**: Machine Grade (AUTO_POOL, 73 pts, script-verifiable) + Human Grade (MANUAL_POOL, 30 pts); Overall = `min`; (b) **A3 auto-detected** by grepping the inlined `lightbox.js`; (c) **per-profile `target_diagrams`** declared in profile-template frontmatter, enforced by `grade.sh`; (d) **D2 made real** via jsdom/mmdc render assertions; (e) **H1 cascade** — `tidy` → `html-validate` → regex, prints which ran; (f) **mandatory V1 human visual gate** (5 pts) — closes flaw 7; a V1 fail forces Human Grade = F; (g) **literal-`\n` D1 guard** added to `validate-diagrams.mjs`. Touched `grade.sh`, `validate-html.sh`, `validate-diagrams.mjs`, `manual-checklist.sh` (new), `spot-check-facts.sh` (new), `grading-rubric.md`, all 6 `section-templates/*.md`, and `aid-summarize/SKILL.md` ×3 trees; propagated to all install trees. See DISCOVERY-STATE Q180 and the `## Summarization History` entry.

**Effort:** Was Medium — completed 2026-05-21. **No further action.**

---

### [MEDIUM] M1 — `.claude/settings..json` filename typo

**Evidence:** `.claude/settings..json` (double dot) sits alongside `.claude/settings.json`. Both contain *identical* content (verified by `diff` — no output). The double-dot file is not gitignored.

**Impact:** Cosmetic; Claude Code will not load the malformed name as a settings file. But the duplicate file confuses future maintainers about which is canonical, and represents the kind of dotfile-discipline issue that a CI lint would catch.

**Effort:** Trivial (less than 30 min). `git rm .claude/settings..json` and add a CI check for unusual dotfile names.

---

### [MEDIUM] M2 — (SUPERSEDED by H7 — missing Monitor templates)

This item has been promoted to HIGH severity per the production-impact analysis in H7 above. Leaving as a back-pointer; no separate action.

---

### [MEDIUM] M3 — Hardcoded build commands in `codex/.codex/agents/developer.toml`

**Evidence:** `codex/.codex/agents/developer.toml` lines 11-12:
```
1. Run the build: `mvn clean verify -f ProjectRoot/pom.xml`
2. Run tests: `mvn test -f ProjectRoot/pom.xml`
```

The other tool trees' equivalent (`claude-code/.claude/agents/developer.md`) say "Build verification is mandatory" without nominating a build tool, which is correct for a tool-agnostic methodology. Codex's version uniquely hardcodes Maven with a placeholder-looking path.

**Impact:** A Codex user installing this developer agent into a non-Java project will see the agent attempt to run `mvn` on every code change. The agent prompt is normative for the model — even Sonnet-tier models tend to follow explicit shell commands literally.

**Effort:** Trivial (less than 30 min). Replace lines 11-12 with "Run the build and tests using the project's existing commands (see `.aid/knowledge/technology-stack.md` Build Commands and `.aid/knowledge/test-landscape.md` Test Commands)." This matches the pattern used by the other tool trees.

---

### [MEDIUM] M4 — Documentation drift between methodology and skill bodies

**Evidence (spot check, two phases):**

**Phase 5 (Detail):**
- `methodology/aid-methodology.md:353` introduces "Phase 5: Detail (`aid-detail`)".
- `claude-code/.claude/skills/aid-detail/SKILL.md` (390 lines) is the skill body.
- `diff claude-code/.claude/skills/aid-detail/SKILL.md cursor/.cursor/skills/aid-detail/SKILL.md` returns 0 differences.
- `diff claude-code/.claude/skills/aid-detail/SKILL.md codex/.agents/skills/aid-detail/SKILL.md` returns 5 lines of difference (essentially title and frontmatter).

The aid-detail skill bodies are consistent across trees AND consistent with the methodology's description of the phase. No drift detected here.

**Phase: Verify** (note: there is **no aid-verify** in this repo)
- The methodology document does not describe a "Verify" phase. The pipeline (per `methodology/aid-methodology.md` and the skills inventory in `project-structure.md:78-89`) is: Init -> Discover -> Interview -> Specify -> Plan -> Detail -> Execute -> Deploy -> Monitor, with optional Summarize.
- The closest concepts are (a) the per-skill REVIEW state (built into Discover and Execute), and (b) the `operator` agent's "Verify before acting" rule (`operator.md:24`).
- There is no `aid-verify` skill folder in any of the install trees, and the docs do not promise one.

**Other drift evidence:**
- `methodology/aid-methodology.md:889` documents: "The Correct phase has been merged into Monitor. Root cause analysis, patch scope, and test requirements are now documented directly in MONITOR-STATE.md."
- `skills/aid-correct/README.md` (5 lines) says: "This phase has been merged into Triage. Root cause analysis is now part of the Triage phase. See aid-monitor for the current workflow."
- The methodology uses "Monitor"; the deprecation note uses "Triage". This is minor terminology inconsistency (Monitor and Triage are the same phase per project-structure.md), but it could confuse a reader scanning both files.

**Impact:** Phase-5 (Detail) is fine. The Correct/Monitor/Triage naming inconsistency is a documentation polish issue. **Most importantly:** `templates/feedback-artifacts/MONITOR-STATE.md` is referenced by both the methodology document (line 889) and `templates/README.md` (line 31) but does not exist — see M2.

**Effort:** Trivial (less than 30 min) for the naming alignment. The MONITOR-STATE.md creation is tracked under M2.

---

### [MEDIUM] M5 — `aid-discover` SKILL.md violates the "Under 500 lines" guideline

**Evidence:** `CONTRIBUTING.md:97` — "Under 500 lines per skill (AgentSkills best practice)". Actual:
- `codex/.agents/skills/aid-discover/SKILL.md` — 1,078 lines (216% over).
- `cursor/.cursor/skills/aid-discover/SKILL.md` — 1,090 lines (218% over).
- `codex/.agents/skills/aid-interview/SKILL.md` — 694 lines (139% over).
- `cursor/.cursor/skills/aid-interview/SKILL.md` — 698 lines (140% over).
- `codex/.agents/skills/aid-execute/SKILL.md` — 558 lines (112% over).
- `cursor/.cursor/skills/aid-execute/SKILL.md` — 562 lines (112% over).

**Impact:** The guideline exists because long SKILL.md files consume context window aggressively. Codex and Cursor models (especially at high reasoning effort) pay a token cost on every invocation. Either the guideline should be revised (with rationale), or the Codex/Cursor versions should be factored using a `references/` mechanism analogous to Claude Code.

**Effort:** Large (more than 1 day) if refactoring inline content into externalizable references for Codex and Cursor (also requires confirming whether each host tool reads referenced files automatically). Trivial (less than 30 min) if the rule is relaxed in CONTRIBUTING.md with a per-tool caveat.

---

### [LOW] L1 — `aid-correct/README.md` is a 5-line deprecation note still present in the public `skills/` tree

**Evidence:** `skills/aid-correct/README.md`:
```
# Correct (Deprecated)
This phase has been merged into Triage. Root cause analysis is now part of the Triage phase.
See [aid-monitor](../aid-monitor/) for the current workflow.
```
Contradicts scout's hypothesis that this was a forward-looking placeholder — actually a tombstone.

**Impact:** A user browsing `skills/` sees a deprecated phase. The deprecation message is clear, but the folder existing at all clutters the tree. Also: the install trees (claude-code, codex, cursor) correctly do NOT ship `aid-correct/SKILL.md` (verified — no such file in any install tree), so there is no broken skill to invoke; only the human-readable README is the tombstone.

**Effort:** Trivial (less than 30 min). Either delete the folder or move the README content to a CHANGELOG / migration-notes document.

---

### [LOW] L2 — `correction-template.md` deprecation note inline (resolved — deleted in methodology cleanup)

**Evidence (historical):** `templates/reports/correction-template.md` formerly carried an inline note: "Deprecated: The Correct phase has been merged into Triage. ... This template is retained for reference only."

**Impact:** Resolved — the file was deleted in the methodology-correctness cleanup; no deprecated artifact remains in the tree.

**Effort:** Done.

---

### [LOW] L3 — TODO / FIXME density

**Evidence:** `Grep` for `TODO|FIXME|XXX|HACK|TBD|pending discovery` returns 69 total occurrences across 21 files. Highest hotspots:
- `cursor/.cursor/skills/aid-discover/SKILL.md` — 6 hits
- `codex/.agents/skills/aid-discover/SKILL.md` — 6 hits
- `cursor/.cursor/skills/aid-init/SKILL.md` — 5 hits
- `claude-code/.claude/skills/aid-init/SKILL.md` — 5 hits
- `cursor/.cursor/agents/discovery-reviewer.md` — 5 hits
- `claude-code/.claude/agents/discovery-reviewer.md` — 5 hits
- `codex/.agents/skills/aid-init/SKILL.md` — 5 hits

Top-level files with `(pending discovery)` placeholders (verified post-dogfood-cycle 2026-05-21 per DISCOVERY-STATE Q81):
- `CLAUDE.md` (repo root) — **0 hits** (was the dogfood subject; now 90 lines, fully populated by this discovery cycle).
- `claude-code/CLAUDE.md` (install template) — 1 hit (correct: install templates ship with placeholders for users to fill in via `/aid-init` + `/aid-discover`).
- `codex/AGENTS.md` (install template) — 4 hits (correct: same lifecycle).
- `cursor/AGENTS.md` (install template) — 4 hits (correct: same lifecycle).

**Analysis:** Most "TODO"-like matches in skill bodies are not actual TODOs — they are documentation strings about what an agent should do. The `(pending discovery)` matches in the 3 install-template files are *intentional placeholders* that `aid-init` / `aid-discover` instruct users to fill in on their own project. So the real TODO density in production code is approximately zero. Adjusted total: ~13 intentional placeholders in install templates (1 + 4 + 4) + ~52 documentation-string false-positives = ~65 of the 69 grep hits are non-issues.

**Impact:** Low — the placeholders work as designed. Repo-root `CLAUDE.md` has been correctly populated by the dogfood cycle (verified — no remaining "(pending discovery)" markers).

**Effort:** N/A — already resolved for the dogfood repo. The install-template placeholders are by-design.

---

### [LOW] L4 — Install-template project-config files inconsistent in content

**Evidence (verified 2026-05-21):**
- `CLAUDE.md` (repo root) — **90 lines**, fully populated by the dogfood discovery cycle (NOT a template — this is the project-config for this repo itself).
- `claude-code/CLAUDE.md` (install template) — 30 lines, minimal structure, ships with "(pending discovery)" placeholders.
- `codex/AGENTS.md` (install template) — 28 lines, similar structure to claude-code, "(pending discovery)" placeholders.
- `cursor/AGENTS.md` (install template) — 45 lines, *more content* than the others, includes "Knowledge Base" section, "Skills & Agents" section, "Permissions" section.

The three install-template variants are intentionally lighter than the dogfood `CLAUDE.md` (which has been populated). Among the install templates, the Cursor variant has additional sections (especially "Permissions" and "Skills & Agents") that are absent from the Claude Code and Codex templates. There is no documented reason for the asymmetry.

**Impact:** A user installing more than one tool sees three different shapes of project-config file template. Minor friction.

**Effort:** Small (less than 4 h). **Resolution per DISCOVERY-STATE Q82:** align all three install-template variants to the Cursor shape (KB + Permissions + Skills sections). Cursor has the most informative template; bring Claude Code and Codex variants up to parity. Document the rationale in `CONTRIBUTING.md`.

---

### [LOW] L5 — Files over 500 lines (cross-tool variant detail)

**Evidence (from `project-index.md`):**
- `methodology/aid-methodology.md` — 1,158 lines (canonical methodology spec; long-form by design, no refactor needed).
- `cursor/.cursor/skills/aid-discover/SKILL.md` — 1,090 lines (see M5).
- `codex/.agents/skills/aid-discover/SKILL.md` — 1,078 lines (see M5).
- `cursor/.cursor/skills/aid-interview/SKILL.md` — 698 lines (see M5).
- `codex/.agents/skills/aid-interview/SKILL.md` — 694 lines (see M5).
- `templates/knowledge-summary/component-css.css` (and 3 duplicates) — 642 lines each (CSS for HTML viewer; reasonable for a styled deliverable).
- `cursor/.cursor/skills/aid-execute/SKILL.md` — 562 lines (see M5).
- `codex/.agents/skills/aid-execute/SKILL.md` — 558 lines (see M5).
- `cursor/.cursor/skills/aid-specify/SKILL.md` — 488 lines (see M5 - 88 lines over).
- `codex/.agents/skills/aid-specify/SKILL.md` — 485 lines.
- `claude-code/.claude/skills/aid-interview/SKILL.md` — 477 lines.
- `claude-code/.claude/skills/aid-discover/SKILL.md` — 453 lines.

**Impact:** The Claude Code versions of all SKILL.md files are at or under the 500-line guideline. Codex and Cursor variants exceed it as noted. The methodology document at 1,158 lines is intentionally long and out of scope for the AgentSkills guideline (which targets SKILL.md, not free-form docs).

**Effort:** Same as M5.

---

### [LOW] L6 — Cross-tool model-tier consistency: VERIFIED CONSISTENT

**Evidence:** Spot-checked all 22 agents across all three trees:

| Agent | Claude Code (`model:`) | Cursor (`model:`) | Codex (`model =`, `reasoning_effort =`) | Consistent? |
|-------|----------------------|-------------------|---------------------------------------|-------------|
| architect | opus | opus | gpt-5.5, high | Yes |
| developer | sonnet | sonnet | gpt-5.4, medium | Yes |
| devops | sonnet | sonnet | gpt-5.4, medium | Yes |
| data-engineer | sonnet | sonnet | gpt-5.4, medium | Yes |
| interviewer | opus | opus | gpt-5.5, high | Yes |
| operator | sonnet | sonnet | gpt-5.4, medium | Yes |
| orchestrator | sonnet | sonnet | gpt-5.4, medium | Yes |
| performance | sonnet | sonnet | gpt-5.4, medium | Yes |
| researcher | sonnet | sonnet | gpt-5.4, medium | Yes |
| reviewer | opus | opus | gpt-5.5, high | Yes |
| security | opus | opus | gpt-5.5, high | Yes |
| tech-writer | sonnet | sonnet | gpt-5.4, medium | Yes |
| ux-designer | sonnet | sonnet | gpt-5.4, medium | Yes |
| discovery-* (all 6) | opus | opus | gpt-5.5, high | Yes |
| simple-* (all 3) | haiku | haiku | gpt-5.4-mini, low | Yes |

**Conclusion:** The May 2026 migration note in `codex/README.md:35` ("7 of the 9 Sonnet-tier agents ... have been corrected to gpt-5.4 medium") was successfully applied. All 22 agents are now tier-consistent across the 3 trees. The Codex tier mapping (`gpt-5.5/high` = Opus, `gpt-5.4/medium` = Sonnet, `gpt-5.4-mini/low` = Haiku) is uniform.

[INFO] **No tier drift detected.** Listed as Low debt because the only remaining work is to keep it that way (covered by the CI proposal in H2 and the propagation script in H3).

---

### [LOW] L7 — Dead-code / unreferenced files

**Search performed:** Looked for files in the repo that no other file references:
- `skills/aid-correct/README.md` — tombstone (see L1).
- `templates/grading-rubric.md` (74 lines, universal) vs. `templates/knowledge-summary/grading-rubric.md` (226 lines, HTML-specific) — both intentional and used by different consumers; **not** duplicates.

No genuinely orphaned files found.

**Effort:** N/A.

---

## Metrics

- **TODO / FIXME / XXX / HACK / TBD / "pending discovery" count:** 69 occurrences across 21 files. Of these, ~17 are intentional placeholders in `CLAUDE.md` / `AGENTS.md` variants (4 trees x ~4 placeholders each). The remainder are documentation strings rather than actual code TODOs.
- **Files over 500 lines:** 12 total. 1 is the methodology spec (1,158 lines, by design). 6 are inlined Codex/Cursor SKILL.md files (debt item M5). 4 are duplicated knowledge-summary assets per H4 (`component-css.css` x 4, `lightbox.js` x 4, etc., none individually over 500 lines except `component-css.css`). 1 is `build-project-index.sh` x 4 at 368 lines each (under 500 individually).
- **Files over 1000 lines:** 3. `methodology/aid-methodology.md` (1,158), `codex/.agents/skills/aid-discover/SKILL.md` (1,078), `cursor/.cursor/skills/aid-discover/SKILL.md` (1,090).
- **Triplication ratio:** approximately 36% of total lines (~17,600 of 49,226) are 4-way duplicates of canonical sources (see H4).
- **Test-to-code ratio:** ⚠️ Not meaningful for a methodology + docs + scripts repo. There are zero test files for ~5,490 lines of shell and ~3,428 lines of JavaScript. By the most literal reading, the test-to-code ratio is 0.
- **CI/CD coverage:** 0 pipelines, 0 workflows. Confirmed.
- **Per-severity debt-item count (OPEN items; post-cycle-2 reconciliation):**
  - HIGH: 6 open (H1, H2, H3, H4, H5, H7) — H6 RETIRED 2026-05-22 (Codex installer smoke test passed); H7 (Monitor templates Q8 promoted) added 2026-05-21.
  - MEDIUM: 6 (M1, M2 [superseded by H7 — kept as back-pointer], M3, M4, M5, M6) — M6 (Cursor Terminal/Bash internal inconsistency Q52) added 2026-05-21.
  - LOW: 7 (L1, L2, L3, L4, L5, L6 [informational — VERIFIED CONSISTENT tier mapping], L7 [informational]).
  - **Total: 20 open items.**
  - RESOLVED this session: **H8** (`/aid-summarize` grading rubric vs script mismatch — overhauled 2026-05-21; listed in Debt Items for the record, not counted in the 20 open).

### [MEDIUM] M6 — Cursor agent tool name internally inconsistent (`Terminal` vs `Bash`)

**Evidence:** Reviewer spot-check #21 found Cursor's own tree is inconsistent on the shell-execution tool name:
- `cursor/.cursor/agents/architect.md:4` declares `tools: Read, Glob, Grep, Write, Edit, Terminal`
- `cursor/.cursor/agents/discovery-reviewer.md:7` declares `tools: Read, Glob, Grep, Bash, Write`

Per `external-sources.md` rows 5-6, the canonical Cursor tool name is `Terminal` (Cursor renamed from `Bash` at some point). Some Cursor agents in this tree were missed during the rename.

**Impact:** Some Cursor agents may not have shell execution available because they declare a non-canonical tool name. Slash commands that depend on shell access would silently fail in those agents.

**Effort:** Trivial (~15 min). Audit all 22 `cursor/.cursor/agents/*.md` files, rename every `Bash` → `Terminal` in `tools:` declarations. Per DISCOVERY-STATE Q52 resolution. Add to CI cross-tree parity check (H3) so it doesn't reoccur.

---

## Resolution Roadmap from DISCOVERY-STATE Q&A

Items below were added or refined as a result of the Q&A pass on 2026-05-21. Cross-linked to the canonical Q-IDs in `DISCOVERY-STATE.md`. Each carries a provisional disposition that the user can override during APPROVAL.

| ID | Source Q | Action | Effort | Status |
|----|----------|--------|--------|--------|
| R1 | Q1, Q10, Q71 (user-confirmed) | Adopt SemVer + `VERSION` file at repo root + git tags + `RELEASING.md` runbook + version-print in `setup.{sh,ps1}` | Small | Pending — out-of-KB code change |
| R2 | Q2, Q5 (user-confirmed) | Document supported tools matrix (Claude Code + Codex + Cursor committed; Copilot + Antigravity future). Update README + CONTRIBUTING + faq wording. Add tagged GitHub Releases for pinning. | Small | Pending |
| R3 | Q3, Q73 (auto) | Author `tools/propagate-skills.{sh,py}` that derives Codex / Cursor SKILL.md from Claude Code source + `references/`. Add CI drift-check. | Medium | Pending |
| R4 | Q4, Q12, Q35 (auto) | Minimal CI workflow: shellcheck on `*.sh`, markdownlint, link-check, structural cross-tree-parity test, wired `validate-*` scripts, JSON-Schema frontmatter validation, dogfood-discovery smoke test, unit tests on `grade.sh` + `build-project-index.sh`. | Medium | Pending |
| R5 | Q6 (auto) | Delete `skills/aid-correct/`. (`templates/reports/correction-template.md` already deleted in the methodology cleanup.) Add migration note to `CHANGELOG.md`. (Tombstones; phase merged into Triage/Monitor per `methodology/aid-methodology.md:889`.) | Trivial | Partially done — `correction-template.md` deleted; `skills/aid-correct/` pending |
| R6 | Q11 (auto) | Add `.github/ISSUE_TEMPLATE/{bug-report,feature-request,methodology-question}.md` + `.github/PULL_REQUEST_TEMPLATE.md` aligned with AID phase taxonomy. | Trivial | Pending |
| R7 | Q13 (auto) | Document branching strategy in `CONTRIBUTING.md`: trunk-based, branch naming `<owner>/<short-desc>`, squash-with-Conventional-Commits merge policy. | Trivial | Pending |
| R8 | Q14 (auto) | Mark `templates/knowledge-summary/design-tokens.md` as documentation regenerated from `component-css.css` (CSS is source-of-truth). Future: one-shot doc-extraction script. | Trivial | Pending |
| R9 | Q15 (auto) | Move repo's own `.claude/settings.json` content to a developer-local `.claude/settings.local.json` + gitignore. Keep minimal shared `settings.json` only if project-wide defaults are needed. | Trivial | Pending |
| R10 | Q16 (user-confirmed), Q17 (auto) | Update `methodology/aid-methodology.md` heading "## 3. The Nine Phases" + README wording to canonical 10-SKILL taxonomy (Init + 8 dev + Summarize). Add explicit `Loop 11: Any phase → aid-discover (targeted re-entry)` between L8 and L9. | Small | Pending |
| R11 | Q18 (auto) | Author 6 READMEs under `agents/discovery-{architect,analyst,integrator,quality,scout,reviewer}/README.md`. Shape per `agents/architect/README.md`. Cross-link from `agents/README.md`. | Medium | Pending |
| R12 | Q30 (auto) | Standardize on Claude Code / Cursor filenames: `DISCOVERY-STATE.md` + `additional-info.md`. Update `codex/.codex/agents/discovery-reviewer.toml`. Document filename-constants rule in CONTRIBUTING. | Trivial | Pending |
| R13 | Q32 (auto) | Lift state-file templates (`discovery-state.md`, `interview-state.md`, `feature-state.md`, etc.) from install trees to canonical `templates/` root. Install trees copy from there. | Small | Pending |
| R14 | Q33 (auto) | Define closed Status enum (`Not Started`, `Pending`, `Populated`, `Approved`, `Below Minimum`, `Exempt`) in new `templates/CONVENTIONS.md`. Normalize KB doc headers. | Small | Pending |
| R15 | Q34, Q72 (auto) | Update `CONTRIBUTING.md:21-26` to (a) use correct dotted-hidden on-disk paths and (b) add Cursor to the cross-tree-update rule. Quadruplicate, not triplicate. | Trivial | Pending — covered by H5 |
| R16 | Q50, Q51, Q81, Q82 (auto) | Document install-template lifecycle (single-line placeholders → matched-pair after `/aid-init`/`/aid-discover`). Note Codex `context: fork` omission is intentional. Align install templates to Cursor shape. | Trivial | Pending |
| R17 | Q52 (auto) | Audit all 22 `cursor/.cursor/agents/*.md` and unify on `Terminal` (Cursor canonical name). Document in `cursor/README.md`. | Trivial | Pending — covered by M6 |
| R18 | Q53 (auto) | Sync `templates/reports/discovery-state-template.md` with the rich shape embedded in `claude-code/.claude/agents/discovery-reviewer.md:309-369`. Document the skeleton→rich lifecycle. | Trivial | Pending |
| R19 | Q55 (auto) | Add one-line Mermaid CLI install guidance to README + aid-summarize README. | Trivial | Pending |
| R20 | Q70 (CONFIRMED bug) | Add `copy_dir codex/.agents` to `setup.sh:142-145` Codex branch and equivalent to `setup.ps1:137-141`. | Trivial | **RETIRED 2026-05-22** — both installers fixed; task-030 smoke test confirmed 10 SKILL.md files present. |
| R21 | Q74 (auto) | Add `.github/CODEOWNERS` requiring maintainer approval for changes that introduce `permissionMode: bypassPermissions` or `background: true`. Add CI check listing currently-elevated agents (today: 6 discovery-* agents). | Trivial | Pending |
| R22 | Q75 (auto) | Add `tools/redact-kb.{sh,py}` masking file paths / URLs / configurable identifiers in `.aid/knowledge/*.md`. Document in `security-model.md` as recommended adopter practice. | Small | Deferred to v3.1 |
| R23 | Q79 (auto) | Add `setup.sh --dry-run` + `setup.sh --prune` (with strong confirmation). Same for `setup.ps1`. | Small | Pending |
| R24 | Q80 (auto) | Document URL trust assumption in `external-sources.md` (new Trust Model section). | Trivial | Pending |
| R25 | Q100 (auto) | Extend `build-project-index.sh` to emit a `## Canonical Counts` section. Other KB docs reference these counts via `project-index.md`. | Small | Pending |
| R26 | Q101 (auto) | Add post-cycle reconcile pass in `discovery-reviewer` prompt to re-validate KB-doc references to in-cycle-mutated files. | Trivial | Pending |
| R27 | Q103 (auto) | Add `[INFO]` to `templates/grading-rubric.md` as a sixth non-counted severity. | Trivial | Pending |
| R28 | Q104 (auto) | Extend Review History rows with a `Docs Modified` column. Update `templates/discovery-state.md`. | Trivial | Pending |
| R29 | Q105 (auto) | Author `templates/scripts/verify-kb-claims.sh` that parses KB markdown for `file.ext:NN` citations and grep-checks them. Wire into discovery-reviewer FIX cycle. | Small | **Implemented 2026-05-21** — script at `templates/scripts/verify-kb-claims.sh` (300 lines Bash). Checks: (a) every `file.ext:NN` citation resolves to a real file at expected line range (with multi-prefix path resolution + `find` fallback); (b) README.md line-count column matches actual `wc -l`; (c) targeted spot-checks on commonly-drift-prone counts (domain-glossary terms, tech-debt severity tags); (d) emits a Verified Ground Truth pane that downstream reviewers can quote. First run found **898 valid citations / 0 broken / 0 drifts** — see DISCOVERY-STATE.md Review History row #14 for first-use results. Wiring into reviewer agent prompt is the next step (R29.b — pending). |

## Recommendations (Priority Order — updated 2026-05-21)

1. ~~**Fix `setup.sh` Codex `.agents/` omission (H6 / R20)**~~ — **RETIRED 2026-05-22**. `setup.sh` + `setup.ps1` now copy `.agents/` in the Codex branch. Live smoke test confirmed 10 SKILL.md files present.
2. **Add CI (H2 / R4)**. One workflow that runs shellcheck, validates frontmatter, runs triplication-drift check, runs install smoke tests, runs dogfood discovery. Single highest-leverage change.
3. **Fix `CONTRIBUTING.md` (H5 / R15)**. Quadruplicate rule + correct paths + Cursor.
4. **Author propagation script + drift checker (H3 / R3)**.
5. **Refactor to single source of truth (H4)**: convert `setup.sh` to copy from `templates/` only.
6. **Create missing Monitor templates (H7 / R5 from Q8)**.
7. **Add `VERSION` file + tag releases (R1)** — trivial, high-value for adopters.
8. **Fix `developer.toml` hardcoded Maven path (M3)**.
9. **Audit Cursor agents for `Terminal`/`Bash` consistency (M6 / R17)**.
10. **Delete tombstones (L1 / R5)** — `aid-correct/` (the `correction-template.md` tombstone, L2, was already deleted in the methodology cleanup).

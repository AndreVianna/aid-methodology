# Tech Debt

> **Source:** aid-discover (discovery-quality)
> **Status:** Populated (cycle-11 FIX 2026-05-23: H1/H4 RETIRED post-canonical-generator; H3 verified still valid; H5/H6 added; counts recounted)
> **Last Updated:** 2026-05-23
> **Cross-references:** `project-index.md`, `project-structure.md` (Anomalies section), `test-landscape.md` (overlapping CI gap), `security-model.md` (overlapping supply-chain gap), `infrastructure.md` (canonical/ + run_generator.py)

## Summary

**Overall debt level: MEDIUM** for an open-source methodology repo aiming at production adopters (down from MEDIUM-HIGH pre-canonical-generator).

The structural-duplication debt that previously dominated the inventory (H1, H4) is now RETIRED: post-work-002, the 3 install trees under `profiles/{claude-code,codex,cursor}/` are deterministic output of `python run_generator.py` against a single canonical source at `canonical/`. The remaining debt is **process gaps** (no CI, no manifest, no version file, narrow generator verification) and **content gaps** (orphan templates, missing Monitor templates pre-Q8 resolution, hardcoded build commands).

If a contributor opens a PR today, there is no automated signal whether they have introduced canonical-vs-output drift, broken a script, left a typo in frontmatter, or added a profile-tree-only orphan that `run_generator.py` will not detect. The maintainer must still catch most things by eye — but the surface area has shrunk meaningfully.

## Debt Items

### [HIGH] H1 — Triplication drift between install trees — **RETIRED 2026-05-22 (work-002-canonical-generator)**

**Evidence (post-cycle-11 verification 2026-05-23):**

`wc -l canonical/skills/aid-discover/SKILL.md profiles/*/.*/skills/aid-discover/SKILL.md` returns **307 lines four times** (identical across canonical + 3 profile trees). Pre-canonical-generator this file claimed divergent line counts (Claude Code 453 / Codex 1,078 / Cursor 1,090) — those counts were collected before work-002 lifted the bodies into `canonical/skills/` and `run_generator.py` propagated them uniformly. Spot-checked other skills the same way: all 3 profile trees match canonical line-for-line.

**Resolution (work-002):**
- All 10 skill bodies, 22 agent definitions, and template assets promoted into `canonical/{skills,agents,templates}/`.
- `run_generator.py` (top-level, ~84 lines Python) reads per-profile TOMLs from `profiles/*.toml` and renders deterministic install-tree output (`profiles/claude-code/.claude/`, `profiles/codex/.codex/` + `profiles/codex/.agents/`, `profiles/cursor/.cursor/`).
- Each install tree carries an `emission-manifest.jsonl` recording what the generator emitted; deletion pass removes files no longer in the manifest.
- VERIFY-4a (deterministic) + VERIFY-4b (advisory) gates run after every regeneration.

**Status:** RETIRED. Remaining residual risk (canonical-vs-output parity not enforced by CI) is tracked separately as H3.

---

### [HIGH] H2 — No CI / no test runner / no manifest / no version file

**Evidence:**
- No `.github/workflows/` (confirmed by `project-index.md` Notable Files and `test-landscape.md` searches).
- No `.gitlab-ci.yml`, no Jenkinsfile, no `azure-pipelines.yml`, no CircleCI config.
- No `package.json`, no `pyproject.toml`, no `Cargo.toml`, no `go.mod`, no `Makefile`.
- No `VERSION` file. No git tag visible from this worktree. The methodology refers to "V3" in prose (`methodology/aid-methodology.md`) but there is no programmatic way to query the AID version.
- No `MANIFEST.{json,yaml,toml}` listing the canonical file set. (`canonical/EMISSION-MANIFEST.md` exists but is a per-profile manifest of generator output, not a project-level manifest.)

**Impact:**
- No automated gate on PRs. Drift, broken scripts, malformed frontmatter, typos in YAML/TOML all reach `master` unless a human catches them.
- Adopters cannot pin to a version. `git clone` always pulls the tip — risky for production-critical methodology consumers.
- The lack of a manifest amplifies the supply-chain risk in `security-model.md` (no way to verify a clone is intact).

**Effort:** Medium for CI (less than 1 day to set up shellcheck + frontmatter validation + a `python run_generator.py && git diff --exit-code profiles/` parity check + basic install smoke test). Trivial for `VERSION` file (less than 30 min). Small for git-tag discipline.

---

### [HIGH] H3 — No linter / format checker configured (verified still valid 2026-05-23)

**Evidence (cycle-11 spot-check):**
- No `.shellcheckrc`, `.eslintrc*`, `.markdownlint*`, `.editorconfig`, `pyproject.toml` (for ruff/black), `.prettierrc`, or any other linter config at repo root.
- No `Makefile` target or shell script invoking `shellcheck` / `markdownlint` / `yamllint` / `actionlint`.
- The 5,490 lines of shell, 3,428 lines of JavaScript, and ~84 lines of Python in `run_generator.py` have no lint-time check.

**Impact:** Style drift, unused variables, missing quotes around `$VAR`, `set -e` skipping behavior, broken shebangs, all pass without notice. Higher-impact for shell (where `shellcheck` would catch genuine bugs) than for markdown.

**Effort:** Trivial (≤ 30 min per linter) to wire a config file + a single GitHub Action job. The blocker is item H2 (no CI).

---

### [HIGH] H4 — Four-way duplicated scripts and assets — **RETIRED 2026-05-22 (work-002-canonical-generator)**

**Pre-resolution context (preserved for traceability):** The previous version of this entry catalogued ~17,600 lines of 4-way duplication across `templates/` + 3 install trees (`build-project-index.sh`, `lightbox.js`, `component-css.css`, `validate-*.{sh,mjs}`, `grade.sh`, `writeback-state.sh`, etc.), accounting for ~36% of the repo line count. The premise was that no propagation tool existed.

**Why retired:** That same duplication is now **intentional generator output**, not unmanaged debt. Maintainers edit a single canonical source under `canonical/templates/{scripts,knowledge-summary}/`; `python run_generator.py` propagates byte-identical copies into each install tree. Verified: `diff canonical/templates/scripts/grade.sh profiles/claude-code/.claude/templates/scripts/grade.sh` returns no output.

**Residual risk (tracked as H3 above):** No CI invokes the generator and asserts the committed install-tree files match the regenerated output. A contributor who hand-edits a file inside `profiles/<tool>/` (instead of the canonical source) can drift silently. Mitigated by maintainer discipline + the EMISSION-MANIFEST trail; un-mitigated by automation.

**Status:** RETIRED. Tooling that would have closed this entry pre-cycle-11 now exists (`run_generator.py`); the remaining work is a 1-line CI check (covered by H2 / H3).

---

### [HIGH] H5 — Generator orphan-detection gap (Q190 generalization) — **NEW cycle-11**

**Evidence:**
- `run_generator.py` VERIFY-4a checks canonical → profile propagation (every file in `canonical/templates/` is present in the install trees). It does **not** check the reverse direction: files that exist in the install trees but **not** in `canonical/templates/`.
- Pre-FR2 (work-003), 6 templates lived only in install trees, missing from canonical:
  - `feature.md`
  - `feature-inventory.md` (root, not the per-feature one)
  - `known-issues.md`
  - `package.md`
  - `requirements.md` (root)
  - `ui-architecture.md` (root)
- Diff command that reveals them: `diff <(find canonical/templates -type f) <(find profiles/claude-code/.claude/templates -type f)`.
- Discovered when `/aid-deploy work-003` looked up `canonical/templates/package.md` and failed (Q190 single-file). Cycle-11 generalization showed 5 sibling orphans (Q190 escalated from low to high).
- **Resolved by KB-F1** (lifted to canonical 2026-05-23) — but the underlying gap in `run_generator.py` remains: a future orphan introduced by a contributor will not be detected automatically.

**Impact:** A template added to install trees without being added to `canonical/templates/` is silently orphaned. Adopters get it, but the next `python run_generator.py` run does not preserve it (the deletion pass removes anything no longer in the manifest). Pre-resolution this caused `/aid-deploy work-003` to fail.

**Effort:** Small (≤ 4 h). Add a VERIFY-4c (or extend 4a) check: for each install tree, diff its template-file set against the canonical set + the per-profile rendered manifest; flag anything in the install tree that is neither canonical-output nor explicitly profile-only-allowed.

**Related:** Q190 (Side-discovery from `/aid-deploy work-003`). Tracked in STATE.md Q&A.

---

### [HIGH] H6 — Codex installer omits `.agents/` copy (CONFIRMED BUG) — **RETIRED 2026-05-22**

**Evidence:** `setup.sh:142-145` (Codex branch, pre-fix) copied `profiles/codex/.codex/` to `$TARGET/.codex/` and `profiles/codex/AGENTS.md` to `$TARGET/AGENTS.md` — but **did NOT** copy `profiles/codex/.agents/` which contains all 10 SKILL.md files and the `templates/` asset bundle. `setup.ps1:137-141` had the identical omission. Reviewer static-analysis spot-check #20 confirmed: `sed -n '140,155p' setup.sh` showed only `.codex` and `AGENTS.md` referenced in the Codex branch.

**Impact:** Every Codex user who installed AID via the bundled installer was getting agent TOML definitions **without skill bodies**. Slash commands appeared to do nothing because the SKILL.md files were absent. Silent failure mode — no error message, just inert tooling.

**Resolution (work-002-canonical-generator / task-001 + task-002 + task-030):** `copy_dir profiles/codex/.agents` added to `setup.sh` Codex branch; equivalent `Copy-Dir-Safe` call added to `setup.ps1`. Live smoke test (task-030) confirmed: `setup.sh` + `setup.ps1` both install all 10 Codex SKILL.md files under `<target>/.agents/skills/aid-*/SKILL.md`. Claude Code and Cursor artifacts unaffected (regression check passed). H6 is retired. Tracks STATE.md Q70.

---

### [HIGH] H7 — Missing templates for the Monitor phase (Q8 promoted)

**Evidence:** `templates/README.md` (legacy) references two templates that do not exist on disk:
- `MONITOR-STATE.md` — used by `aid-monitor` for production telemetry state. (Note: post-FR2 area-STATE rule may have absorbed this into a work-STATE pattern; needs verification.)
- `track-report-template.md` — used by `aid-monitor` for periodic monitor reports.

The `aid-monitor` skill (223 lines per `canonical/skills/aid-monitor/SKILL.md`, propagated identically to 3 install trees) presumably produces these artifacts but agents have no canonical template to follow.

**Impact:** The Monitor phase is shipping as ⚠️ Partial. Adopters running `/aid-monitor` get an agent that doesn't know what shape its output artifacts should take. Promoted from MEDIUM (M2 in earlier framing) to HIGH because it blocks the production-monitoring story end-to-end.

**Effort:** Small (less than 4 h). **Resolution per STATE.md Q8 / Q31 / Q77:** author both templates — modeled on existing `canonical/templates/feedback-artifacts/IMPEDIMENT.md` shape and the `aid-monitor` skill body. Post-FR2 the `MONITOR-STATE.md` shape may be the consolidated work-STATE; clarify per data-model.md §1A before authoring.

---

### [HIGH] H8 — `/aid-summarize` grading rubric vs script implementation mismatch — **RESOLVED 2026-05-21**

**Evidence (as found):** During dogfood use of `/aid-summarize`, the grading system had structural flaws: (1) the script auto-passed the "manual" checks K1 (10 pts) + K2 (15 pts) — 25 points it could not verify; (2) A3 (focus trap) was marked "manual / can't auto", capping the script-automated grade below A+ permanently; (3) the rubric's "<6 diagrams = C+ ceiling" hard rule was not wired into `grade.sh`; (4) the `cli` profile spec'd 4 diagrams while the rubric demanded ≥6, so the profile was structurally locked out of A+; (5) `D2` (render) was dependent on `D1` (parse) — anything passing D1 passed D2; (6) `H1` ran custom regex, not the `tidy`/`html-validate` the rubric described; (7) no check covered diagram-internal legibility — every automated check (D1/D2/C1/C2) could pass while a Mermaid diagram was visually unreadable.

**Impact:** The script-reported grade was simultaneously inflated (free manual points) and capped below A+ (A3 unscored). Adopters could not trust the number, and a genuinely broken summary could pass.

**Resolution (2026-05-21):** The grading system was overhauled — (a) **two-grade model**: Machine Grade (AUTO_POOL, 73 pts) + Human Grade (MANUAL_POOL, 30 pts); Overall = `min`; (b) **A3 auto-detected** by grepping the inlined `lightbox.js`; (c) **per-profile `target_diagrams`** declared in profile-template frontmatter, enforced by `grade.sh`; (d) **D2 made real** via jsdom/mmdc render assertions; (e) **H1 cascade** — `tidy` → `html-validate` → regex; (f) **mandatory V1 human visual gate** (5 pts); (g) **literal-`\n` D1 guard** added to `validate-diagrams.mjs`.

**Effort:** Was Medium — completed 2026-05-21. **No further action.**

---

### [MEDIUM] M1 — `.claude/settings..json` filename typo — **RETIRED 2026-05-25 (file removed)**

> **Status:** The `.claude/settings..json` double-dot typo file no longer exists on disk. The historical bug analysis below is preserved as a record. See `project-structure.md` Anomaly #2 for the current state.

### M1 (HISTORICAL — RETIRED) — `.claude/settings..json` filename typo

**Evidence:** `.claude/settings.json` (the historical double-dot typo file `.claude/settings..json` was removed; see `project-structure.md` Anomaly #2) (double dot) sits alongside `.claude/settings.json`. Both contain *identical* content (verified by `diff` — whitespace-only diff). The double-dot file is not gitignored.

**Impact:** Cosmetic; Claude Code will not load the malformed name as a settings file. But the duplicate file confuses future maintainers about which is canonical.

**Effort:** Trivial (less than 30 min). `git rm .claude/settings..json` and add a CI check for unusual dotfile names.

---

### [MEDIUM] M2 — (SUPERSEDED by H7 — missing Monitor templates)

This item has been promoted to HIGH severity per the production-impact analysis in H7 above. Leaving as a back-pointer; no separate action.

---

### [MEDIUM] M3 — Hardcoded build commands in `profiles/codex/.codex/agents/developer.toml`

**Evidence:** `profiles/codex/.codex/agents/developer.toml` lines 11-12:
```
1. Run the build: `mvn clean verify -f ProjectRoot/pom.xml`
2. Run tests: `mvn test -f ProjectRoot/pom.xml`
```

The other tool trees' equivalent (`profiles/claude-code/.claude/agents/developer.md`) say "Build verification is mandatory" without nominating a build tool, which is correct for a tool-agnostic methodology. Codex's version uniquely hardcodes Maven with a placeholder-looking path.

**Impact:** A Codex user installing this developer agent into a non-Java project will see the agent attempt to run `mvn` on every code change. The agent prompt is normative for the model.

**Effort:** Trivial (less than 30 min). Edit `canonical/agents/developer.toml` (or whatever canonical source produces the Codex variant) and re-run `python run_generator.py`. Replace lines 11-12 with "Run the build and tests using the project's existing commands (see `.aid/knowledge/technology-stack.md` Build Commands and `.aid/knowledge/test-landscape.md` Test Commands)."

---

### [MEDIUM] M4 — Documentation drift between methodology and skill bodies

**Evidence (spot check, two phases):**

**Phase 5 (Detail):**
- `methodology/aid-methodology.md:353` introduces "Phase 5: Detail (`aid-detail`)".
- `canonical/skills/aid-detail/SKILL.md` is the canonical body; all 3 install trees match (post work-002).

**Phase: Verify** (note: there is **no aid-verify** in this repo)
- The methodology document does not describe a "Verify" phase. The pipeline is: Init -> Discover -> Interview -> Specify -> Plan -> Detail -> Execute -> Deploy -> Monitor, with optional Summarize.
- The closest concepts are (a) the per-skill REVIEW state (built into Discover and Execute), and (b) the `operator` agent's "Verify before acting" rule.

**Other drift evidence:**
- `methodology/aid-methodology.md` documents: "The Correct phase has been merged into Monitor."
- Pre-FR2 tombstone `canonical/skills/aid-correct/README.md` no longer exists (top-level `skills/` dir was removed in work-002).

**Impact:** The Correct/Monitor/Triage naming inconsistency is a documentation polish issue. Most importantly: the legacy `templates/README.md` references files that may not exist post-FR2 — see H7.

**Effort:** Trivial (less than 30 min) for the naming alignment. The MONITOR template creation is tracked under H7.

---

### [MEDIUM] M5 — `aid-discover` SKILL.md size guideline — **RESOLVED 2026-05-25 (work-001 thin-router refactor)**

> **Status:** Post-work-001 PR #13 thin-router refactor reduced `aid-discover/SKILL.md` from 596 lines to 307 lines (well under the 500-line guideline; cycle-19 orchestrator-protocol additions brought it from 258 to 307, still well under). M5 is moot. The 9.6% over-target framing was based on pre-thin-router metrics and is no longer applicable. Historical analysis preserved below for reference.

### M5 (HISTORICAL — RESOLVED) — `aid-discover` SKILL.md violated the "Under 500 lines" guideline pre-thin-router

**Evidence (cycle-11 verification):** `CONTRIBUTING.md:97` — "Under 500 lines per skill (AgentSkills best practice)". Actual (post work-002 unification):
- `canonical/skills/aid-discover/SKILL.md` — **307 lines** (was 596 pre-thin-router refactor; now well under 500 — M5 RESOLVED).
- All 3 profile copies (`profiles/{claude-code,codex,cursor}/.../skills/aid-discover/SKILL.md`) — 307 lines each (identical, by virtue of being generator output).

Other previously-flagged overages no longer apply: post-canonical-generator, `aid-interview`, `aid-execute`, and `aid-specify` all match the Claude Code reference (smaller) sizes. Only `aid-discover` is over.

**Impact:** The guideline exists because long SKILL.md files consume context window aggressively. 548 vs 500 is a modest overage (~10%) compared to the pre-canonical-generator 1,078-line bloat. Either the guideline should be revised with rationale, or `aid-discover` should be factored further using `references/` decomposition (already in place for some content blocks).

**Effort:** Small (less than 4 h) to extract additional content into `canonical/skills/aid-discover/references/*.md`. Trivial (less than 30 min) if the rule is relaxed in CONTRIBUTING.md with a per-skill caveat for orchestrator-class skills.

---

### [MEDIUM] M6 — Cursor agent tool name internally inconsistent (`Terminal` vs `Bash`)

**Evidence:** Reviewer spot-check found Cursor's own tree is inconsistent on the shell-execution tool name:
- `profiles/cursor/.cursor/agents/architect.md:4` declares `tools: Read, Glob, Grep, Write, Edit, Terminal`
- `profiles/cursor/.cursor/agents/discovery-reviewer.md:7` declares `tools: Read, Glob, Grep, Bash, Write`

Per `external-sources.md` rows 5-6, the canonical Cursor tool name is `Terminal`. Some Cursor agents in this tree were missed during the rename.

**Impact:** Some Cursor agents may not have shell execution available because they declare a non-canonical tool name. Slash commands that depend on shell access would silently fail in those agents.

**Effort:** Trivial (~15 min). Audit all 22 `canonical/agents/*.toml` (or the per-profile renderer rules) and ensure the Cursor variant emits `Terminal` consistently. Re-run `python run_generator.py`. Per STATE.md Q52 resolution. Add canonical-vs-output parity check (H3) so it doesn't reoccur.

---

### [LOW] L1 — `aid-correct/README.md` tombstone — **RETIRED**

**Pre-resolution context:** `canonical/skills/aid-correct/README.md` was a 5-line tombstone left behind when the Correct phase was merged into Triage/Monitor.

**Why retired:** The entire top-level `skills/` directory was deleted in work-002 (its content promoted to `canonical/skills/`). The tombstone no longer exists. Verified: `ls skills/aid-correct/` errors with "No such file or directory".

---

### [LOW] L2 — `correction-template.md` deprecation note inline — **RETIRED**

**Evidence (historical):** `canonical/templates/reports/correction-template.md` formerly carried an inline note: "Deprecated: The Correct phase has been merged into Triage."

**Impact:** Resolved — the file was deleted in the methodology-correctness cleanup; no deprecated artifact remains in the tree.

---

### [LOW] L3 — TODO / FIXME density

**Evidence:** `Grep` for `TODO|FIXME|XXX|HACK|TBD|pending discovery` returned 69 total occurrences across 21 files at the initial dogfood pass. Post-canonical-generator the distribution shifted (skill bodies are uniform now), but most matches remain *documentation strings about what an agent should do*, not actual TODOs.

Top-level files with `(pending discovery)` placeholders (intentional — install templates ship with placeholders for users to fill in via `/aid-init` + `/aid-discover`):
- `CLAUDE.md` (repo root) — **0 hits** (the dogfood subject; fully populated).
- `profiles/claude-code/CLAUDE.md` (install template) — 1 hit.
- `profiles/codex/AGENTS.md` (install template) — 4 hits.
- `profiles/cursor/AGENTS.md` (install template) — 4 hits.

**Impact:** Low — the placeholders work as designed.

**Effort:** N/A — already resolved for the dogfood repo. The install-template placeholders are by-design.

---

### [LOW] L4 — Install-template project-config files inconsistent in content

**Evidence (verified 2026-05-21):**
- `profiles/claude-code/CLAUDE.md` (install template) — 30 lines, minimal structure.
- `profiles/codex/AGENTS.md` (install template) — 28 lines.
- `profiles/cursor/AGENTS.md` (install template) — 45 lines, *more content* (includes "Knowledge Base", "Skills & Agents", "Permissions" sections).

**Impact:** A user installing more than one tool sees three different shapes of project-config file template. Minor friction.

**Effort:** Small (less than 4 h). Per STATE.md Q82: align all three install-template variants to the Cursor shape. Bring Claude Code and Codex variants up to parity via canonical edits + generator re-run.

---

### [LOW] L5 — Files over 500 lines (cross-tool variant detail)

**Evidence (post-cycle-11):**
- `methodology/aid-methodology.md` — 1,071 lines (canonical methodology spec; long-form by design).
- `canonical/skills/aid-discover/SKILL.md` (and 3 profile copies) — 307 lines each (see M5; well under 500-line guideline).
- `canonical/templates/knowledge-summary/component-css.css` (and 3 profile copies) — 642 lines each (CSS for HTML viewer; reasonable for a styled deliverable).
- All other SKILL.md files are now at or under 500 lines (post-canonical-generator uniformity).

**Impact:** Per-skill bloat is now confined to `aid-discover` (M5). Pre-cycle-11 entries for `aid-interview`, `aid-execute`, and `aid-specify` no longer apply.

**Effort:** Same as M5.

---

### [LOW] L6 — Cross-tool model-tier consistency: VERIFIED CONSISTENT

**Evidence:** Spot-checked all 22 agents across all three trees. All Opus-tier agents map to `gpt-5.5/high`; all Sonnet-tier to `gpt-5.4/medium`; all Haiku-tier to `gpt-5.4-mini/low`. Tier mapping is uniform.

[INFO] **No tier drift detected.** Listed as Low debt because the only remaining work is to keep it that way (covered by the CI proposal in H2 and parity check in H3).

---

### [LOW] L7 — Dead-code / unreferenced files

**Search performed:** Looked for files in the repo that no other file references:
- Pre-cycle-11: `canonical/skills/aid-correct/README.md` — RETIRED (top-level `skills/` deleted in work-002).
- `canonical/templates/grading-rubric.md` (74 lines, universal) vs. `canonical/templates/knowledge-summary/grading-rubric.md` (226 lines, HTML-specific) — both intentional and used by different consumers; **not** duplicates.

No genuinely orphaned files found at the source layer. Template orphans (6 install-tree-only templates) are tracked under H5.

**Effort:** N/A.

---

### [LOW] L8 — Scripts lack defensive arg-handling (Q191 generalization) — **NEW cycle-11**

**Evidence:**
- Pre-KB-F2 (resolved 2026-05-23), `writeback-state.sh` accepted any string as GRADE silently. Line 11 was `GRADE="${1:-?}"` — no `-h`/`--help` handler, no regex validation, no dry-run. Symptom: running `writeback-state.sh --help` wrote the literal string `--help` into the state file's grade column.
- **Resolved by KB-F2** (2026-05-23): added `-h|--help` handler (sed-print the comment block, exit 0) + `[[ "$GRADE" =~ ^[A-F][+-]?$ ]] || exit 4` validation.
- **Sibling audit (cycle 11):** spot-checked `check-preflight.sh`, `stale-check.sh`, `grade.sh` in the same scripts directory. All three already validate or skip silent acceptance of invalid args — OK.
- **Forward gap:** No CONTRIBUTING.md / CI rule mandates `-h|--help` handler + arg validation for new shell scripts. The pattern is convention, not enforced.

**Impact:** Low. Each future shell script that ships without defensive arg handling can repeat the original bug class. Caught by user reports; not caught at PR time.

**Effort:** Trivial. Add a one-paragraph rule to CONTRIBUTING.md: "Every shell script must implement `-h|--help` and validate positional args; pattern: see `canonical/templates/knowledge-summary/scripts/writeback-state.sh:7-24` post-KB-F2." Optionally extend the `shellcheck` CI gate (H3) with a custom check for `case "$1" in -h|--help)` presence.

**Related:** Q191 (Side-discovery from `/aid-deploy work-003`). Tracked in STATE.md Q&A.

---

## Metrics

- **TODO / FIXME / XXX / HACK / TBD / "pending discovery" count:** 69 occurrences across 21 files (pre-canonical-generator baseline; the canonical/ unification preserved them inside skill bodies as documentation strings). Of these, ~17 are intentional placeholders in `CLAUDE.md` / `AGENTS.md` variants. The remainder are documentation strings rather than actual code TODOs.
- **Files over 500 lines:** 2 unique sources (`methodology/aid-methodology.md` at 1,071; `canonical/templates/knowledge-summary/component-css.css` at 642). The latter has 3 byte-identical copies in the install trees by virtue of being generator output. `canonical/skills/aid-discover/SKILL.md` at 307 is well under guideline post-thin-router refactor.
- **Files over 1000 lines:** 1 unique source (`methodology/aid-methodology.md` at 1,071). Previously 3 (the now-unified aid-discover SKILL.md is 307 in all profile trees post-thin-router refactor + cycle-19 orchestrator additions, not the pre-canonical-generator 453/1,078/1,090).
- **Duplication ratio (post-canonical-generator):** byte-identical duplication remains in absolute terms (~36% of repo lines are 4-way) but is no longer **drift-prone debt** — it is generator output from a single canonical source.
- **Test-to-code ratio:** ⚠️ Not meaningful for a methodology + docs + scripts repo. There are zero test files for ~5,490 lines of shell, ~3,428 lines of JavaScript, and ~84 lines of Python (`run_generator.py`). By the most literal reading, the test-to-code ratio is 0.
- **CI/CD coverage:** 0 pipelines, 0 workflows. Confirmed.
- **Per-severity debt-item count (OPEN items; post-cycle-11 recount 2026-05-23):**
  - HIGH: **4 open** — H2 (no CI), H3 (no linter), H5 (generator orphan-detection gap), H7 (missing Monitor templates).
  - HIGH: 4 retired/resolved — H1 (triplication drift — RETIRED via canonical-generator), H4 (4-way duplicated scripts — RETIRED via canonical-generator), H6 (Codex `.agents/` omission — RETIRED via setup.sh fix), H8 (`/aid-summarize` grading — RESOLVED 2026-05-21).
  - MEDIUM: **5 open** — M1, M3, M4, M5, M6. (M2 superseded by H7, kept as back-pointer.)
  - LOW: **6 open** — L3 (TODO density, low-impact), L4 (install-template asymmetry), L5 (files >500 lines, covered by M5), L6 (model-tier consistency, informational), L7 (dead code, none found), L8 (defensive args, Q191 generalization).
  - LOW: 2 retired — L1 (`aid-correct/README.md` tombstone — RETIRED via top-level `skills/` deletion), L2 (`correction-template.md` — RETIRED via deletion).
  - **Total open: 15 items** (down from 20 pre-cycle-11). 6 retired in work-002/work-003 + cycle-11 (H1, H4, H6, H8, L1, L2).
  - **Disk-truth recount (cycle 11):** `grep -c "^### \[HIGH\]" tech-debt.md` returns **8** (4 OPEN + 4 RETIRED-but-still-listed). Counts cited in INDEX.md / README.md should refer to OPEN count = 4.

## Resolution Roadmap from STATE.md Q&A

Items below were added or refined as a result of Q&A passes. Cross-linked to canonical Q-IDs in `STATE.md`.

| ID | Source Q | Action | Effort | Status |
|----|----------|--------|--------|--------|
| R1 | Q1, Q10, Q71 | Adopt SemVer + `VERSION` file + git tags + `RELEASING.md` + version-print in `setup.{sh,ps1}` | Small | Pending |
| R2 | Q2, Q5 | Document supported-tools matrix; tagged GitHub Releases for pinning | Small | Pending |
| R3 | Q3, Q73 | (SUPERSEDED by work-002 canonical-generator) | — | Done — `python run_generator.py` |
| R4 | Q4, Q12, Q35 | Minimal CI workflow: shellcheck, markdownlint, link-check, canonical-vs-output parity, frontmatter validation, dogfood-discovery smoke test | Medium | Pending |
| R5 | Q6 | Delete ~~`skills/aid-correct/` (DELETED post-work-002 cleanup)~~ | Trivial | Done (top-level `skills/` deleted in work-002) |
| R6 | Q11 | Add `.github/ISSUE_TEMPLATE/*.md` + PR template | Trivial | Pending |
| R7 | Q13 | Document branching strategy in CONTRIBUTING.md | Trivial | Pending |
| R8 | Q14 | Mark `design-tokens.md` as documentation regenerated from `component-css.css` | Trivial | Pending |
| R9 | Q15 | Move repo's `.claude/settings.json` content to `.claude/settings.local.json` + gitignore | Trivial | Pending |
| R10 | Q16, Q17 | Update methodology heading to canonical 10-SKILL taxonomy + add Loop 11 (any phase → aid-discover) | Small | Pending |
| R11 | Q18 | Author 6 READMEs under `canonical/agents/discovery-*/README.md` (post-work-002 path) | Medium | Pending |
| R12 | Q30 | Standardize state-file naming (FR2 area-STATE rule — coding-standards.md §8.5) | Trivial | Done (FR2) |
| R13 | Q32 | Lift state-file templates from install trees to canonical/templates/ | Small | Done via KB-F1 (6 orphans lifted 2026-05-23) |
| R14 | Q33 | Define closed Status enum in new `canonical/templates/CONVENTIONS.md` | Small | Pending |
| R15 | Q34, Q72 | Update CONTRIBUTING.md to reflect canonical-generator workflow (supersedes manual quadruplication) | Trivial | Pending |
| R16 | Q50-Q51, Q81-Q82 | Document install-template lifecycle; align install templates to Cursor shape | Trivial | Pending — covers L4 |
| R17 | Q52 | Audit `canonical/agents/*` for `Terminal` (Cursor canonical name); re-run generator | Trivial | Pending — covers M6 |
| R20 | Q70 | Add `copy_dir profiles/codex/.agents` to setup.sh + setup.ps1 | Trivial | **RETIRED 2026-05-22** — both installers fixed |
| R21 | Q74 | Add CODEOWNERS gating `permissionMode: bypassPermissions` changes | Trivial | Pending |
| R22 | Q75 | Add `tools/redact-kb.{sh,py}` masking adopter identifiers | Small | Deferred to v3.1 |
| R23 | Q79 | Add `setup.sh --dry-run` + `--prune` | Small | Pending |
| R24 | Q80 | Document URL trust assumption in `external-sources.md` | Trivial | Pending |
| R25 | Q100 | Extend `build-project-index.sh` to emit a `## Canonical Counts` section | Small | Pending |
| R26 | Q101 | Add post-cycle reconcile pass in discovery-reviewer | Trivial | Pending |
| R27 | Q103 | Add `[INFO]` to `canonical/templates/grading-rubric.md` as sixth non-counted severity | Trivial | Pending |
| R28 | Q104 | Extend Review History rows with `Docs Modified` column | Trivial | Pending |
| R29 | Q105 | Author `verify-kb-claims.sh` | Small | **Done 2026-05-21** — at `canonical/templates/scripts/verify-kb-claims.sh` |
| R30 | Q190 (new cycle-11) | Lift 6 orphan templates to canonical/ + add VERIFY-4c orphan-detection check to run_generator.py | Small | KB-F1 done (lift); VERIFY-4c pending (covers H5) |
| R31 | Q191 (new cycle-11) | Add `-h|--help` + GRADE regex to writeback-state.sh + audit siblings + document convention for new scripts | Trivial | KB-F2 done (script); convention rule pending (covers L8) |
| R32 | Q192 (new cycle-11) | Document host harness skill-loading cache in infrastructure.md §3.1.1 | Trivial | Done 2026-05-23 (infrastructure.md cycle-11 FIX) |

## Recommendations (Priority Order — updated 2026-05-23)

1. **Add CI (H2 / R4)**. One workflow that runs shellcheck, validates frontmatter, runs canonical-vs-output parity (`python run_generator.py && git diff --exit-code profiles/`), runs install smoke tests, runs dogfood discovery. Single highest-leverage change.
2. **Add VERIFY-4c orphan-detection to run_generator.py (H5 / R30)**. Closes the gap that Q190 surfaced. ≤4 h.
3. **Fix CONTRIBUTING.md (R15)**. Replace pre-canonical-generator quadruplication rule with canonical-edit + generator workflow. Add the defensive-args convention (L8 / R31).
4. **Create missing Monitor templates (H7 / R5 from Q8)**. Resolve via canonical/ + generator.
5. **Add VERSION file + tag releases (R1)** — trivial, high-value for adopters.
6. **Fix `developer.toml` hardcoded Maven path (M3)**. Canonical edit + regenerate.
7. **Audit Cursor agents for `Terminal`/`Bash` consistency (M6 / R17)**. Canonical edit + regenerate.
8. **Add a linter pass (H3)** as part of the CI workflow above (shellcheck + markdownlint at minimum).

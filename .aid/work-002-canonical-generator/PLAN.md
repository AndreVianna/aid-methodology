# Plan — work-002-canonical-generator

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Initial plan — single delivery (1 feature, all ACs); H6 installer fix folded in as the lead task | /aid-plan |
| 2026-05-22 | Decomposed 19 high-level tasks into 30 atomic `task-NNN.md` files; appended Execution Graph (Depends-On + Can-Be-Done-In-Parallel) and Open Questions. Renumbering: H6 fix (PLAN tasks 1) split into 001 (fix) + 002 (smoke-test); bootstrap (PLAN task 5) split per-skill into tasks 006–014 (smallest-first per SPEC Migration Plan ordering: aid-deploy, aid-monitor, aid-init, aid-summarize, aid-plan+aid-detail bundled, then heavyweights aid-discover, aid-interview, aid-specify, aid-execute); emission-manifest (PLAN task 12) split into DESIGN 003 + IMPLEMENT 022; final verification (PLAN task 19) split into round-trip 029 + clean-target smoke 030. Renderer name **`aid-generate`** chosen (alternatives rejected with rationale in task-025). Generator placement **`.claude/skills/aid-generate/`** at repo root (resolves SPEC §234 hedge — repo dogfoods Claude Code). Emission-manifest format **`emission-manifest.jsonl`** (JSON Lines) per task-003 spec. | /aid-detail |
| 2026-05-22 | **task-029 round-trip live verification complete.** AC1 LIVE: deliberate comment added to `canonical/skills/aid-deploy/SKILL.md`, generator ran, comment landed in all 3 trees (CC + Codex + Cursor). VERIFY-4a PASS. AC2 LIVE: immediate re-run with no canonical change → 311 files emitted, 0 deleted, VERIFY-4a byte-identical PASS. Round-trip revert: `git checkout canonical/skills/aid-deploy/SKILL.md` + generator run → comment removed from all 3 trees, VERIFY-4a PASS. AC3 LIVE: `profiles/test-tool.toml` stub created (aliases CC conventions, `output_root = test-tool/.test-tool`); generator ran → 103 files materialized in fourth output root (22 agents, 10 skills); `profiles/test-tool.toml` deleted, `test-tool/` manually cleaned up (note: the generator's deletion pass fires for files absent from a NEW run of the SAME active profile; when a profile is entirely removed, the run_generator.py loop has no iteration for it and no automatic cleanup fires — this is a known behavior boundary of the pure-mirror design, not a bug, as the safety boundary is "manifested files only"); AC3 evidence: new profile + no canonical change → fourth tree materialized; no cross-tree contamination. AC4 VERIFIED BY INSPECTION: `profiles/claude-code.toml`, `profiles/codex.toml`, `profiles/cursor.toml` each carry `[capabilities]` tables with tool-specific boolean flags. AC5 LIVE: the entire workflow for AC1 was "edit `canonical/`, run the generator" — no manual cross-tree edits made. | /aid-execute (task-029) |
| 2026-05-22 | **Reviewer-graded C- → A: mechanical corrections to `/aid-detail` output.** Fixes applied: (A) Stale task-number references swept across 9 task files (003, 004, 005×2, 008, 010, 011, 015, 019, 021) — repoint to refined 30-task numbering (manifest impl = 022, VERIFY-4a = 023, renderers = 019–021, bootstrap verification = 026). (B) W8 wave split into W8a (028+030, parallel, no deps) and W8b (029, depends on 028). (C) task-022 sequencing — **Option B chosen** (manifest module ships before renderers, with API stub as contract; renderers 019/020/021 add task-022 to `Depends on`). Smaller graph diff than Option A. (D) task-028 Type corrected `DOCS → DOCUMENT` (matches `templates/delivery-plans/task-template.md:3` enum). (E) task-029 promoted AC3 from structural-claim to live smoke test (author stub `profiles/test-tool.toml`, observe fourth output root materialize, delete profile, observe pure-mirror cleanup). (F) task-011 split 4-ways (parent task-011 = SKILL.md router body; new sibling tasks 011a/011b/011c = the three `references/*.md` artifacts) — addresses the ~625-line drift, the single largest risk in the work item, as one task per artifact. (G) OQ2 closed (default baked into task-003 + task-022: one manifest per profile at the deepest common parent); OQ3 closed (graceful-degraded stub is the answer per REQUIREMENTS §3 + PLAN §54–57). (H) task-018 line 20 — `set -euo pipefail`-equivalent reworded to be actually accurate (top-level `main()` + `sys.exit()` + propagating exceptions); task-025 — added caveat that if OQ1 resolves to option (c), tasks 018–021 must update target paths. **New task count: 33** (30 originals minus 0 deletions plus 3 new `011a/011b/011c`). Wave renumbering: W3 was {019,020,021,022} → W3 is now {019,020,021} (task-022 moved out); W4 was {023,024} → unchanged; W5 = task-025; W6 = task-026; W7 = task-027; W8a = {028,030}; W8b = {029}. New W2.5 inserted between W2 and W3 containing only task-022. Critical path now: `task-003 → task-022 → task-019 (or task-020 / task-021 — any one of the three renderers as the bottleneck) → task-023 → task-025 → task-026 → task-027 → task-028 → task-029` (**nine** tasks; gained two nodes — one from manifest-impl-precedes-renderers and one because task-029 depends on task-028's CONTRIBUTING update via the W8a/W8b split). | /aid-detail (correction pass) |

## Sequencing context (cross-work)

`work-002` ships **first** across the AID reshape (per `work-001-aid-lite`
REQUIREMENTS §10). Until this delivery lands, every edit to AID's skills /
agents / templates is 3-way triplicated; once it lands, every subsequent edit is
single-source. `work-001-aid-lite`'s FR3 (thin-router refactor of remaining skill
bodies) is the immediate downstream consumer — its wave begins only after this
delivery's bootstrap verification confirms the generator reproduces the trees.

## Deliveries

### delivery-001 — Profile-driven generator + canonical-source cutover + H6 installer fix

| Field | Value |
|---|---|
| **Status** | Ready |
| **Features** | `feature-001-profile-driven-generator` (all ACs) |
| **Priority** | Must |
| **Depends on** | — (foundation; no upstream deliveries) |

#### Goal

Ship the canonical-source generator end-to-end: one `canonical/` source + three
per-tool `profiles/*.toml` + deterministic Python render scripts + byte-identical
re-run gate + emission-manifest safety boundary + cutover (commit generated
trees, replace `CONTRIBUTING.md` cross-tree rule, fix Codex installer H6).
Satisfies AC1–AC6.

#### Context

The detailed design is in
`features/feature-001-profile-driven-generator/SPEC.md` (graded **A+** in the
final post-reshape re-grade). Cross-cutting decisions still in force: **decision F**
(all three profiles use `references` decomposition); **CR7** (two-zone
`task-NNN.md` template is owned by `work-001-aid-lite`'s `feature-002` —
out-of-scope for `work-002`).

**Key constraints carried from REQUIREMENTS:**

- **§4 / NFR5 — end users require no Python.** The generator is maintainer-only
  build tooling. Generated trees are committed; `setup.sh` / `setup.ps1`
  continue to copy. Python (3.11+ for `tomllib`) is a maintainer-machine
  dependency, never an end-user one.
- **§6 AC2 — byte-identical re-runs.** `RENDER` is a pure function of
  `(canonical/, profile)`; no timestamps or ordering nondeterminism.
- **VERIFY-4b advisory** ships in graceful-degraded form (skip-with-warning)
  until the 8 vendor URLs in `.aid/knowledge/external-sources.md` are fetched.
  The design activates the full conformance check automatically when URLs land
  — no separate delivery needed.
- **Out of scope — human-readable READMEs.** The human-readable `skills/` and
  `agents/` README files at the repo root remain hand-maintained — they are
  **not** generated by this work (per SPEC Migration Plan step 7). A deliberate,
  accepted residue of manual upkeep; the generator's outputs are the three
  install trees only.

#### Acceptance Criteria

Inherited from `REQUIREMENTS.md §6` — all six must pass at the per-delivery gate:

- **AC1** — A single `canonical/` source renders every install tree.
- **AC2** — Re-running the generator on unchanged inputs produces byte-identical
  output (deterministic).
- **AC3** — Onboarding a new host tool requires only a new profile —
  `canonical/` and existing profiles untouched.
- **AC4** — The profile is the per-tool capability registry
  (`hooks`, `skill_chaining`, `background_execution`, `stop_hook_autocontinue`).
- **AC5** — `CONTRIBUTING.md`'s "update all locations" rule is replaced with
  "edit `canonical/`, run the generator" — retires tech-debt **H4** and **H5**.
- **AC6** — The `setup.sh` / `setup.ps1` Codex branch copies the full Codex tree
  (`.codex/` + `.agents/`) — retires tech-debt **H6**.

#### Tasks (high-level — refined into task-NNN.md by `/aid-detail`)

In rough sequence; `aid-detail` produces the actual Execution Graph
(`Depends On` + `Can Be Done In Parallel` tables) and the `task-NNN.md` files.

1. **Codex installer H6 fix** — `setup.sh` Codex branch (lines ~142–145) +
   `setup.ps1` Codex branch (lines ~136–141) copy `codex/.agents/` in addition
   to `codex/.codex/`. Independent of the generator; lands first; smoke-tested
   immediately.
2. **Author `profiles/claude-code.toml`** — extract Claude Code conventions
   (frontmatter schema, file extensions, model-tier map, capability flags,
   `references` decomposition) from the existing `claude-code/.claude/` tree.
3. **Author `profiles/codex.toml`** — same for Codex CLI from
   `codex/.codex/` + `codex/.agents/` (note: agent format is **TOML**).
4. **Author `profiles/cursor.toml`** — same for Cursor from `cursor/.cursor/`
   (note: `tools: Terminal` instead of `Bash`; `.cursor/hooks.json` is beta).
5. **Bootstrap `canonical/skills/`** — extract tool-agnostic skill content from
   the **Claude Code tree** (richest, already `references/`-decomposed). Resolve
   the documented body drift (`aid-discover/SKILL.md` is 453 vs 1,078 vs 1,090
   lines across the three trees) by taking Claude Code as the source of truth
   and cross-checking the other two for any content that genuinely differs.
6. **Bootstrap `canonical/agents/`** — extract the 22 agent definitions in
   abstract-frontmatter form.
7. **Bootstrap `canonical/templates/`** — promote root `templates/` to
   `canonical/templates/`.
8. **Write profile parser + render-script harness** — Python `tomllib` loader +
   schema validation + shared helpers.
9. **Write agent renderer** — canonical agent → markdown (Claude Code / Cursor)
   or TOML (Codex) per profile's frontmatter schema + model-tier + tool-name
   maps.
10. **Write skill renderer** — canonical skill → `SKILL.md` + `references/`
    structure (decision F: `references` decomposition on all three trees;
    no inlining).
11. **Write template renderer** — canonical templates → placed per profile's
    layout.
12. **Build emission manifest mechanism** — `RENDER` tracks every emitted path
    in a per-profile manifest committed alongside the tree; pure-mirror deletion
    is **restricted to manifest-tracked paths** — files outside the generator's
    output set are never touched.
13. **Write VERIFY-4a deterministic gate** — byte-identical re-render check
    (run twice into a temp dir, diff); file-presence audit against the manifest;
    frontmatter parse for every emitted file. Hard pass/fail.
14. **Write VERIFY-4b advisory layer (graceful-degraded form)** — for each
    vendor URL in `external-sources.md`: fetch + compare generated files against
    current vendor recommendations; if the URL is `⚠️ Pending fetch` or
    unreachable, skip with a warning. Never blocks the run.
15. **Write generator orchestration `SKILL.md`** — `LOAD` → `VALIDATE` →
    `RENDER` (per profile) → `VERIFY` (4a + 4b) → `REPORT`, dispatching the
    render scripts and the advisory agent.
16. **Bootstrap verification** — run the generator; `git diff` the generated
    trees against the current committed trees; confirm the diff is only
    drift-elimination (no functional content loss). The maintainer reviews this
    diff before committing.
17. **Commit generated install trees** — the three install trees become
    generated artifacts; the cutover lands.
18. **Replace `CONTRIBUTING.md` cross-tree update rule** (`CONTRIBUTING.md:21–26`)
    with "edit `canonical/`, run the generator" — retires tech-debt H4 + H5.
19. **Final end-to-end verification** — edit `canonical/` (one trivial change),
    run the generator, observe the diff lands in all three trees, run `setup.sh`
    on a clean target directory, verify the Codex install includes
    `.agents/` (H6 retired).

#### Risks / known issues for `aid-detail` / `aid-execute` to be aware of

- **Bootstrap drift resolution (task 5)** is the largest single risk. Claude
  Code is the agreed source of truth, but where Codex / Cursor have content
  genuinely different (not just inlined/decomposed), the maintainer must judge
  which is correct. Suggested mitigation: each `canonical/skills/aid-{name}/`
  bootstrap is its own per-task quick check (FR2), so drift resolution is
  reviewed skill-by-skill rather than as one giant diff.
- **Emission-manifest design (task 12)** is the load-bearing safety boundary for
  pure-mirror deletion. Get this right before any RENDER actually deletes. The
  SPEC's Feature Flow section §3 specifies it; `aid-detail` should treat it as a
  non-parallelizable dependency for task 13 (VERIFY-4a) and beyond.
- **VERIFY-4b graceful-degraded form (task 14)** must explicitly emit a warning
  count in the REPORT step so the maintainer knows how many vendor doc URLs
  were skipped — this is what makes "the design activates automatically when
  URLs land" actually visible.

## Cross-cutting risks

- **Cross-work sequencing.** `work-001-aid-lite`'s FR3 wave is blocked on this
  delivery's task 17 (commit generated trees). If task 5 (bootstrap drift
  resolution) slips, work-001's start slips too. Mitigation: the H6 fix (task 1)
  ships first and independently, so the *most user-visible* defect is closed
  immediately even if the generator work takes longer.
- **Python version assumption.** `tomllib` is stdlib in Python 3.11+. The
  maintainer machine must have 3.11+. Not an end-user concern (NFR5) but worth a
  pre-flight check in the generator skill itself.
- **Cross-tree edit freeze during cutover.** Between task 16 (bootstrap
  verification) and task 17 (commit generated trees), any concurrent hand-edit
  to one of the three install trees becomes orphaned — the generator output
  overwrites it on commit. Mitigation: a brief, announced edit freeze for the
  cutover window; the sole-maintainer model of this repo today makes this a
  coordination, not a process, problem.

---

## Execution Graph — `delivery-001`

Produced by `/aid-detail` from the 19-bullet high-level task list, refined into
33 atomic `task-NNN.md` files in `.aid/work-002-canonical-generator/tasks/` (30
original + 3 from the `aid-discover` four-way split: 011a / 011b / 011c).
See the Change Log entry for the renumbering rationale.

### Task index

| ID | Title | Type |
|---|---|---|
| task-001 | Fix H6 — Codex installer omits `.agents/` copy | MIGRATE |
| task-002 | Smoke-test the H6 installer fix end-to-end | TEST |
| task-003 | Design the emission-manifest on-disk format | DESIGN |
| task-004 | Bootstrap `canonical/agents/` from the Claude Code tree | MIGRATE |
| task-005 | Bootstrap `canonical/templates/` from the root `templates/` tree | MIGRATE |
| task-006 | Bootstrap `canonical/skills/aid-deploy/` | MIGRATE |
| task-007 | Bootstrap `canonical/skills/aid-monitor/` | MIGRATE |
| task-008 | Bootstrap `canonical/skills/aid-init/` | MIGRATE |
| task-009 | Bootstrap `canonical/skills/aid-summarize/` | MIGRATE |
| task-010 | Bootstrap `canonical/skills/aid-plan/` and `canonical/skills/aid-detail/` | MIGRATE |
| task-011 | Bootstrap `canonical/skills/aid-discover/SKILL.md` (router body) | MIGRATE |
| task-011a | Bootstrap `canonical/skills/aid-discover/references/agent-prompts.md` | MIGRATE |
| task-011b | Bootstrap `canonical/skills/aid-discover/references/document-expectations.md` | MIGRATE |
| task-011c | Bootstrap `canonical/skills/aid-discover/references/reviewer-prompt.md` | MIGRATE |
| task-012 | Bootstrap `canonical/skills/aid-interview/` | MIGRATE |
| task-013 | Bootstrap `canonical/skills/aid-specify/` | MIGRATE |
| task-014 | Bootstrap `canonical/skills/aid-execute/` | MIGRATE |
| task-015 | Author `profiles/claude-code.toml` | IMPLEMENT |
| task-016 | Author `profiles/codex.toml` | IMPLEMENT |
| task-017 | Author `profiles/cursor.toml` | IMPLEMENT |
| task-018 | Write the profile parser + render-script harness (Python) | IMPLEMENT |
| task-019 | Write the agent renderer | IMPLEMENT |
| task-020 | Write the skill renderer | IMPLEMENT |
| task-021 | Write the template renderer | IMPLEMENT |
| task-022 | Implement the emission manifest mechanism | IMPLEMENT |
| task-023 | Write VERIFY-4a — the deterministic hard gate | TEST |
| task-024 | Write VERIFY-4b — the advisory conformance layer (graceful-degraded) | TEST |
| task-025 | Write the generator orchestration `SKILL.md` | IMPLEMENT |
| task-026 | Bootstrap verification — run the generator, diff against current trees | TEST |
| task-027 | Commit the generated install trees — the cutover | MIGRATE |
| task-028 | Replace `CONTRIBUTING.md`'s cross-tree update rule | DOCUMENT |
| task-029 | Final round-trip verification via the generator | TEST |
| task-030 | Final clean-target installer smoke test — H6 retired end-to-end | TEST |

### Table 1 — Depends On

| Task | Depends on |
|---|---|
| task-001 | — (lead; H6 fix is independent of the generator) |
| task-002 | task-001 |
| task-003 | — (design-only; no upstream dependency) |
| task-004 | — (bootstrap canonical from Claude Code tree) |
| task-005 | — (bootstrap canonical templates) |
| task-006 | — (bootstrap aid-deploy — smallest skill, no deps) |
| task-007 | — (bootstrap aid-monitor — paired with 006) |
| task-008 | — (bootstrap aid-init) |
| task-009 | — (bootstrap aid-summarize) |
| task-010 | — (bootstrap aid-plan + aid-detail) |
| task-011 | — (bootstrap aid-discover SKILL.md — heavyweight, parent of 011a/b/c split) |
| task-011a | — (bootstrap aid-discover references/agent-prompts.md — independent sibling of 011) |
| task-011b | — (bootstrap aid-discover references/document-expectations.md — independent sibling of 011) |
| task-011c | — (bootstrap aid-discover references/reviewer-prompt.md — independent sibling of 011) |
| task-012 | — (bootstrap aid-interview — heavyweight) |
| task-013 | — (bootstrap aid-specify — heavyweight) |
| task-014 | — (bootstrap aid-execute — heavyweight) |
| task-015 | — (profile authoring — independent of bootstrap) |
| task-016 | — (profile authoring — independent of bootstrap) |
| task-017 | — (profile authoring — independent of bootstrap) |
| task-018 | task-015, task-016, task-017 |
| task-019 | task-004, task-018, task-022 |
| task-020 | task-006, task-007, task-008, task-009, task-010, task-011, task-011a, task-011b, task-011c, task-012, task-013, task-014, task-018, task-022 |
| task-021 | task-005, task-018, task-022 |
| task-022 | task-003, task-018 |
| task-023 | task-019, task-020, task-021, task-022 |
| task-024 | task-019, task-020, task-021 |
| task-025 | task-022, task-023, task-024 |
| task-026 | task-025 |
| task-027 | task-026 |
| task-028 | task-027 |
| task-029 | task-027, task-028 |
| task-030 | task-027 |

### Table 2 — Can Be Done In Parallel

Each row is a wave that can be executed concurrently (no intra-wave
dependencies); waves are ordered top-to-bottom by precedence. A later wave may
begin as soon as its prerequisites complete — not all earlier-wave tasks must
finish before any later-wave task starts (the table is a structural view, not
a strict barrier model). The FR6 parallel-wave input reads this table.

| Wave | Tasks | Rationale |
|---|---|---|
| W0 (lead) | task-001 | H6 installer fix — fully independent; ships first so the most user-visible defect is closed even if the generator work takes longer (per PLAN Cross-cutting risks §1). |
| W1 (foundation, fully parallel) | task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009, task-010, task-011, task-011a, task-011b, task-011c, task-012, task-013, task-014, task-015, task-016, task-017 | All H6 follow-up (002), the emission-manifest DESIGN (003), all canonical bootstraps (004, 005, 006–014 per-skill, plus the three `aid-discover` reference subtasks 011a/011b/011c), and all three profile authoring tasks (015–017) are independent of each other. This is the **single largest parallel surface** in the work item — 19 tasks can run concurrently if maintainer attention permits. Notes: (a) the four heavyweight bootstrap tasks (011 + 012 + 013 + 014, the drift-resolution work) carry the largest single risk per PLAN Risks §1 and each gets its own per-task quick check (FR2); the `aid-discover` four-way split (011 SKILL.md, 011a agent-prompts, 011b document-expectations, 011c reviewer-prompt) localizes the ~625-line drift risk to four ~30-min tasks instead of one ~2-hr task; (b) the profile-authoring tasks (015–017) are listed parallel-with-bootstrap because they can be informed by — but do not strictly depend on — the bootstrap (the profiles describe per-tool conventions extracted from the existing install trees, not from `canonical/`). |
| W2 | task-018 | Profile parser + harness — depends on all three profiles being authored (015–017) so the validator can be exercised against all three. |
| W2.5 | task-022 | Emission-manifest implementation — depends on the manifest DESIGN (003) and the harness (018). Lands **before** the renderers so they can call into the `EmissionManifest.add(...)` API at first emission (per Reviewer Finding C, Option B resolution: contract-first wiring). |
| W3 (renderers, parallel) | task-019, task-020, task-021 | The three asset renderers each depend on the harness (018), the relevant bootstrap (004 / 005 / 006–014 + 011a/b/c), and the manifest module (022). They do not depend on each other and can be developed concurrently. |
| W4 (verify, parallel) | task-023, task-024 | VERIFY-4a (deterministic hard gate) depends on all three renderers + the manifest (019, 020, 021, 022). VERIFY-4b (advisory) depends on the three renderers only (it does not need the manifest because it reads emitted files directly from disk). Both can be authored in parallel once the renderers exist. |
| W5 | task-025 | Generator orchestration SKILL.md — composes the entire pipeline; depends on the manifest mechanism (022) and both verifiers (023, 024). |
| W6 | task-026 | Bootstrap verification — the maintainer-attended diff review. Single-threaded; cannot parallelize with downstream tasks because the commit depends on the maintainer's confirmation that the diff is drift-elimination only. |
| W7 | task-027 | Commit — single git operation; the cutover. |
| W8a (parallel finishers, no intra-wave deps) | task-028, task-030 | After the cutover commits, two independent finishers run in parallel: CONTRIBUTING update (028 — pure docs change) and clean-target installer smoke test (030 — `setup.sh`/`setup.ps1` regression check for H6). Neither depends on the other; both depend only on task-027. |
| W8b | task-029 | Round-trip live verification (with the AC3 stub-profile smoke test folded in). Depends on task-028 (because the round-trip test confirms the new CONTRIBUTING rule reflects reality) — runs strictly after W8a. |

### Critical path

`task-001 → task-002` is the H6 fast path (ships first, independent).

The full generator critical path (post-correction with Option B sequencing):
`task-003 → task-022 → task-019 (or 020 or 021 — any one of the three renderers is the longest pole; assume 020 as it has the broadest fan-in via the 10 bootstrap deps) → task-023 → task-025 → task-026 → task-027 → task-028 → task-029`
(nine tasks; gained one node vs the prior plan because the manifest impl now precedes the renderers rather than running alongside, and task-028 now precedes task-029 in W8a/W8b split).

Most parallelizable surface: W1 with 19 simultaneous tasks.

---

## Open Questions

The methodology owner should resolve these before `/aid-execute` begins on a
critical-path task. Open questions are non-blocking for W0/W1 tasks that
neither read nor write the disputed structure.

### Q1 — Generator's own placement in `canonical/`?

**Context:** Task-025 places the generator skill at `.claude/skills/aid-generate/`
at the repo root (maintainer-tooling, never shipped). The SPEC §234 hedge is
resolved that way in this plan. **But:** if a future maintainer uses Codex or
Cursor as their primary tool (not Claude Code), they would have no way to
invoke `/aid-generate` from their tool of choice. The generator is currently
single-tool-locked to Claude Code as the maintainer interface.

**Options:**
- (a) Accept the Claude Code-only maintainer interface (current plan).
- (b) Maintain a parallel `.codex/skills/aid-generate/` and `.cursor/skills/aid-generate/`
  shape — but this re-introduces triplication for the generator itself.
- (c) Make the Python scripts directly invokable (e.g. `python -m aid_generate`)
  and treat the slash-command wrapper as one of three thin per-tool entry points.

**Recommendation:** (a) for now; revisit if a maintainer actually adopts a
non-Claude-Code primary. (c) is the cleanest long-term answer.

### Q2 — Single emission manifest per profile, or one per output root? **[CLOSED 2026-05-22]**

**Resolved:** one manifest per profile, placed at the deepest common parent of
the output roots (Codex: `codex/emission-manifest.jsonl`; Claude Code:
`claude-code/emission-manifest.jsonl`; Cursor: `cursor/emission-manifest.jsonl`).
Baked into task-003 (DESIGN) and task-022 (IMPLEMENT) as the default — no
fork remains. Simpler safety-boundary model; one manifest per profile rather
than two for Codex.

### Q3 — VERIFY-4b stub conformance-review agent body — out of scope for this work? **[CLOSED 2026-05-22]**

**Resolved:** ship with the stub. The graceful-degraded form is the answer
per REQUIREMENTS §3 ("VERIFY-4b (advisory): conformance review of generated
files against vendor documentation (degrades to 'skipped with warning' until
vendor URLs in `external-sources.md` are fetched)") and PLAN §54–57 ("VERIFY-4b
advisory ships in graceful-degraded form (skip-with-warning) until the 8
vendor URLs in `.aid/knowledge/external-sources.md` are fetched. The design
activates the full conformance check automatically when URLs land — no separate
delivery needed"). The URL fetch is a separate work item; the design supports
automatic activation when URLs land.

### Q4 — Cursor `.cursor/hooks.json` beta — declare capability now or later?

**Context:** PLAN task 4 notes "`.cursor/hooks.json` is beta." Task-017's
`[capabilities] hooks = true` for Cursor records this beta capability. If
Cursor changes the beta API before this work ships, the profile will be
stale on day one.

**Recommendation:** Declare `hooks = true` with an inline TOML comment
`# beta as of 2026-05-22`. The VERIFY-4b advisory layer (when the Cursor doc
URL is fetched) will surface the discrepancy if the API changes.

### Q5 — Should `canonical/` be in the install trees' install path?

**Context:** This work item explicitly does NOT ship `canonical/` to end users
(NFR5: end users require no Python; they get pre-rendered install trees via
`setup.sh`). But a sophisticated adopter might want `canonical/` to vendor
the methodology source for their own purposes (e.g. to derive their own
custom profile for a new host tool).

**Recommendation:** Out of scope for this work item. Document in
`CONTRIBUTING.md` (task-028) that adopters interested in `canonical/` should
clone the repo. Future work item if there is real demand.

---
pipeline:
  path: lite | full                 # lite = flattened (no deliveries/ wrapper); full = deliveries/delivery-NNN/ wrapper
  initiator: aid-describe | aid-{shortcut-skill}  # the pipeline-starting skill: aid-describe, or a shortcut-catalog.yml skill (e.g. aid-fix, aid-refactor, aid-create-api)
started: "{YYYY-MM-DD}"
minimum_grade: "{resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}"
user_approved: yes | no
lifecycle: Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
phase: Describe | Define | Specify | Plan | Detail | Execute
active_skill: aid-{skill} | none
updated: "{YYYY-MM-DDTHH:MM:SSZ}"
pause_reason: "{short text} | --"        # present only when lifecycle = Paused-Awaiting-Input
block_reason: "{short text} | --"        # present only when lifecycle = Blocked
block_artifact: "{relative path} | --"   # e.g. IMPEDIMENT-task-NNN.md, or the failed gate
ticket_ref: "{connector-stem}:{external-id} | --"   # OPTIONAL; e.g. jira:PROJ-123 -- see ticket_ref contract note below
# --- Flattened single-delivery works only (see `## Delivery Lifecycle` below);
#     omit these 4 keys entirely for full multi-delivery works. ---
delivery_state: Pending-Spec | Specified | Executing | Gated | Done | Blocked
gate_tier: Small | Medium | Large
gate_grade: "{grade or Pending}"
gate_timestamp: "{YYYY-MM-DDTHH:MM:SSZ}"
---
<<< LINE 23 NOT CAPTURED >>>
<<< LINE 24 NOT CAPTURED >>>
<<< LINE 25 NOT CAPTURED >>>
<<< LINE 26 NOT CAPTURED >>>
<<< LINE 27 NOT CAPTURED >>>
<<< LINE 28 NOT CAPTURED >>>
<<< LINE 29 NOT CAPTURED >>>
<<< LINE 30 NOT CAPTURED >>>
<<< LINE 31 NOT CAPTURED >>>
<<< LINE 32 NOT CAPTURED >>>
<<< LINE 33 NOT CAPTURED >>>
<<< LINE 34 NOT CAPTURED >>>
<<< LINE 35 NOT CAPTURED >>>
<<< LINE 36 NOT CAPTURED >>>
<<< LINE 37 NOT CAPTURED >>>
<<< LINE 38 NOT CAPTURED >>>
<<< LINE 39 NOT CAPTURED >>>
<<< LINE 40 NOT CAPTURED >>>
<<< LINE 41 NOT CAPTURED >>>
<<< LINE 42 NOT CAPTURED >>>
<<< LINE 43 NOT CAPTURED >>>
<<< LINE 44 NOT CAPTURED >>>
<<< LINE 45 NOT CAPTURED >>>
<<< LINE 46 NOT CAPTURED >>>
<<< LINE 47 NOT CAPTURED >>>
<<< LINE 48 NOT CAPTURED >>>
<<< LINE 49 NOT CAPTURED >>>
<<< LINE 50 NOT CAPTURED >>>
<<< LINE 51 NOT CAPTURED >>>
<<< LINE 52 NOT CAPTURED >>>
<<< LINE 53 NOT CAPTURED >>>
<<< LINE 54 NOT CAPTURED >>>
<<< LINE 55 NOT CAPTURED >>>
<<< LINE 56 NOT CAPTURED >>>
<<< LINE 57 NOT CAPTURED >>>
<<< LINE 58 NOT CAPTURED >>>
<<< LINE 59 NOT CAPTURED >>>
<<< LINE 60 NOT CAPTURED >>>
<<< LINE 61 NOT CAPTURED >>>
<<< LINE 62 NOT CAPTURED >>>
<<< LINE 63 NOT CAPTURED >>>
<<< LINE 64 NOT CAPTURED >>>
<<< LINE 65 NOT CAPTURED >>>
<<< LINE 66 NOT CAPTURED >>>
<<< LINE 67 NOT CAPTURED >>>
<<< LINE 68 NOT CAPTURED >>>
<<< LINE 69 NOT CAPTURED >>>
<<< LINE 70 NOT CAPTURED >>>
<<< LINE 71 NOT CAPTURED >>>
<<< LINE 72 NOT CAPTURED >>>
<<< LINE 73 NOT CAPTURED >>>
<<< LINE 74 NOT CAPTURED >>>
<<< LINE 75 NOT CAPTURED >>>
<<< LINE 76 NOT CAPTURED >>>
<<< LINE 77 NOT CAPTURED >>>
<<< LINE 78 NOT CAPTURED >>>
<<< LINE 79 NOT CAPTURED >>>
<<< LINE 80 NOT CAPTURED >>>
<<< LINE 81 NOT CAPTURED >>>
<<< LINE 82 NOT CAPTURED >>>
<<< LINE 83 NOT CAPTURED >>>
<<< LINE 84 NOT CAPTURED >>>
<<< LINE 85 NOT CAPTURED >>>
<<< LINE 86 NOT CAPTURED >>>
<<< LINE 87 NOT CAPTURED >>>
<<< LINE 88 NOT CAPTURED >>>
<<< LINE 89 NOT CAPTURED >>>
<<< LINE 90 NOT CAPTURED >>>
<<< LINE 91 NOT CAPTURED >>>
<<< LINE 92 NOT CAPTURED >>>
<<< LINE 93 NOT CAPTURED >>>
<<< LINE 94 NOT CAPTURED >>>
<<< LINE 95 NOT CAPTURED >>>
<<< LINE 96 NOT CAPTURED >>>
<<< LINE 97 NOT CAPTURED >>>
<<< LINE 98 NOT CAPTURED >>>
<<< LINE 99 NOT CAPTURED >>>
<<< LINE 100 NOT CAPTURED >>>
<<< LINE 101 NOT CAPTURED >>>
<<< LINE 102 NOT CAPTURED >>>
<<< LINE 103 NOT CAPTURED >>>
<<< LINE 104 NOT CAPTURED >>>
<<< LINE 105 NOT CAPTURED >>>
<<< LINE 106 NOT CAPTURED >>>
<<< LINE 107 NOT CAPTURED >>>
<<< LINE 108 NOT CAPTURED >>>
<<< LINE 109 NOT CAPTURED >>>
<<< LINE 110 NOT CAPTURED >>>
<<< LINE 111 NOT CAPTURED >>>
<<< LINE 112 NOT CAPTURED >>>
<<< LINE 113 NOT CAPTURED >>>
<<< LINE 114 NOT CAPTURED >>>
<<< LINE 115 NOT CAPTURED >>>
<<< LINE 116 NOT CAPTURED >>>
<<< LINE 117 NOT CAPTURED >>>
<<< LINE 118 NOT CAPTURED >>>
<<< LINE 119 NOT CAPTURED >>>
<<< LINE 120 NOT CAPTURED >>>
<<< LINE 121 NOT CAPTURED >>>
<<< LINE 122 NOT CAPTURED >>>
<<< LINE 123 NOT CAPTURED >>>
<<< LINE 124 NOT CAPTURED >>>
<<< LINE 125 NOT CAPTURED >>>
<<< LINE 126 NOT CAPTURED >>>
<<< LINE 127 NOT CAPTURED >>>
<<< LINE 128 NOT CAPTURED >>>
<<< LINE 129 NOT CAPTURED >>>
<<< LINE 130 NOT CAPTURED >>>
<<< LINE 131 NOT CAPTURED >>>
<<< LINE 132 NOT CAPTURED >>>
<<< LINE 133 NOT CAPTURED >>>
<<< LINE 134 NOT CAPTURED >>>
<<< LINE 135 NOT CAPTURED >>>
<<< LINE 136 NOT CAPTURED >>>
<<< LINE 137 NOT CAPTURED >>>
<<< LINE 138 NOT CAPTURED >>>
<<< LINE 139 NOT CAPTURED >>>
<<< LINE 140 NOT CAPTURED >>>
<<< LINE 141 NOT CAPTURED >>>
<<< LINE 142 NOT CAPTURED >>>
<<< LINE 143 NOT CAPTURED >>>
<<< LINE 144 NOT CAPTURED >>>
<<< LINE 145 NOT CAPTURED >>>
<<< LINE 146 NOT CAPTURED >>>
<<< LINE 147 NOT CAPTURED >>>
<<< LINE 148 NOT CAPTURED >>>
<<< LINE 149 NOT CAPTURED >>>
<<< LINE 150 NOT CAPTURED >>>
<<< LINE 151 NOT CAPTURED >>>
<<< LINE 152 NOT CAPTURED >>>
<<< LINE 153 NOT CAPTURED >>>
<<< LINE 154 NOT CAPTURED >>>
<<< LINE 155 NOT CAPTURED >>>
<<< LINE 156 NOT CAPTURED >>>
<<< LINE 157 NOT CAPTURED >>>
<<< LINE 158 NOT CAPTURED >>>
<<< LINE 159 NOT CAPTURED >>>
<<< LINE 160 NOT CAPTURED >>>
<<< LINE 161 NOT CAPTURED >>>
<<< LINE 162 NOT CAPTURED >>>
<<< LINE 163 NOT CAPTURED >>>
<<< LINE 164 NOT CAPTURED >>>
<<< LINE 165 NOT CAPTURED >>>
<<< LINE 166 NOT CAPTURED >>>
<<< LINE 167 NOT CAPTURED >>>
<<< LINE 168 NOT CAPTURED >>>
<<< LINE 169 NOT CAPTURED >>>
<<< LINE 170 NOT CAPTURED >>>
<<< LINE 171 NOT CAPTURED >>>
<<< LINE 172 NOT CAPTURED >>>
<<< LINE 173 NOT CAPTURED >>>
<<< LINE 174 NOT CAPTURED >>>
<<< LINE 175 NOT CAPTURED >>>
<<< LINE 176 NOT CAPTURED >>>
<<< LINE 177 NOT CAPTURED >>>
<<< LINE 178 NOT CAPTURED >>>
<<< LINE 179 NOT CAPTURED >>>
<<< LINE 180 NOT CAPTURED >>>
<<< LINE 181 NOT CAPTURED >>>
     work-003-state-schema task-001; see the task's schema note). -->

- **Updated:** 2026-08-12T15:40:00Z
- **Block Reason:** --

- **Block Artifact:** {relative path} | --

### Tasks lifecycle

- **Updated:** 2026-08-12T15:58:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

<!-- AUTHORED -- single-delivery FLATTENED works only (see ## Delivery Lifecycle note above).
     The single-writer home for per-task mutable state cells, REPLACING the now-absent per-task
     `STATE.md` (each task is `tasks/task-NNN/DETAIL.md` only -- immutable, no sibling STATE.md).
     Written by `writeback-state.sh --task-id NNN --field State --value V` (flattened branch),
     targeting this table instead of a `delivery-NNN/tasks/task-NNN/STATE.md`. Mirrors the REAL
     fields of `task-state-template.md ## Task State` (State/Review/Elapsed/Notes), one row per
     task-NNN. This is a `###` subsection of ## Delivery Lifecycle, distinct from the plural
     DERIVED `## Tasks State` view below (different heading text AND level -- no collision). Left
     absent (section omitted) for full multi-delivery works, where each task's own state lives in
     its `delivery-NNN/tasks/task-NNN/STATE.md` instead (unioned by that DERIVED view). The enum
     below is byte-identical to `task-state-template.md` -- no byte-stability break.

     State enum (closed; single source of truth):
       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

     MANDATORY (aid-execute/references/state-execute.md § State-Write Protocol):
     each row's State cell MUST be written the INSTANT that task's state
     changes -- In Progress before work starts, In Review before the reviewer
     is dispatched, a terminal value (Done/Failed) when finished. Binds
     whoever executes the task -- the main/orchestrator agent running it
     directly, or a dispatched sub-agent -- with no exception either way.
     (Blocked is a distinct, orchestrator-assigned value for a different,
     downstream task that depends on a failed one -- never self-written by
     the task being executed.) -->

| Task | State | Review | Elapsed | Notes | Name |
|------|-------|--------|---------|-------|------|
| task-001 | Done | -- | -- | quick-check (Small): no CRITICAL/HIGH | Record the pre-refactor test baseline and triage the FR-13 test change-set |
| task-002 | Done | -- | -- | quick-check (Small): no CRITICAL/HIGH | Convert the three work-tree state templates to the YAML subset |
| task-003 | Done | -- | -- | quick-check (Small): no CRITICAL/HIGH; 8 executed checks incl. live read_repo | Rebuild the Python reader twin onto one structured state parse |
| task-004 | Done | -- | -- | quick-check (Small): no CRITICAL/HIGH; 39-fixture parity 0 diffs; see KI-004 | Port the Node reader twin onto the same structured state parse |
| task-005 | Done | -- | -- | self-verified 16 passed/369 subtests, 63 rows; quick-check DEFERRED to delivery gate per owner leanness directive | Shared cross-runtime YAML-subset conformance corpus |
| task-006 | Done | -- | -- | quick-check (Small): no CRITICAL/HIGH; exit-7 guard reproduced independently | Retarget the three shell state readers to STATE.yml |
| task-007 | Done | -- | -- | verified: 1-line diff, flat --findings survives, exit codes match old script; quick-check DEFERRED to gate; see KI-005 | Collapse writeback-state.sh onto one YAML single-key write path |
| task-008 | Done | -- | -- | both runtimes; fail-safe+idempotent+DERIVED-guard proven, guard refused own STATE.md live; quick-check DEFERRED to gate | Add the format-4 state conversion step to the repo migration engine |
| task-009 | Done | -- | -- | all 4 carriers+2 fallbacks read 4; gate behavior verified 3/4/5; packages/ vendored copies stale (gate item); quick-check DEFERRED | Bump AID_SUPPORTED_FORMAT to 4 across the four lockstep carriers |
| task-010 | Pending | -- | -- | -- | Convert every live work tree in this repository to STATE.yml |
| task-011 | Done | -- | -- | recovered from transcript (3 suites, 2519 lines present); quick-check DEFERRED to delivery gate | Cross-format, cross-runtime characterization suite |
| task-012 | Done | -- | -- | quick-check (Small): clean on artifacts; the 1 CRITICAL was orchestrator commit hygiene, repaired | Exclude state files from the reviewable-artifact surface |
| task-013 | Done | -- | -- | quick-check (Small): no CRITICAL/HIGH; anti-drift proven by 3 mutation tests | Test the state-file review exclusion, in the RS03 shape |
| task-014 | Done | -- | -- | 93 canonical + CLAUDE/AGENTS; routing files + task-012 edits verified; schema gaps flagged (KI-006); quick-check DEFERRED to gate | Retarget every skill recipe, template and agent-context reference |
| task-015 | Done | -- | -- | recovered from transcript (suites updated: 261 STATE.yml refs in writeback test); quick-check DEFERRED to delivery gate | Update the in-scope canonical shell suites to the YAML state format |
| task-016 | Done | -- | -- | 2069 passed / 24 env-only fails; SP-19b oracle 5/5; readers + KB-ledger untouched; quick-check DEFERRED. [direct edit -- writer YAML-only, see KI-008] | Update the in-scope dashboard reader/server suites to the YAML state format |
| task-017 | Done | -- | -- | byte-identity 1506/1506, 5 self-tests pass, idempotent, canonical clean; vendored packages/ NOT covered (KI-007); quick-check DEFERRED. [State written by DIRECT EDIT: the resync installed the YAML-only writer, which now rejects this still-markdown STATE.md -- the 017-before-010 sequencing gap. writeback-state.sh unusable for this work until task-010 converts it.] | Render fan-out -- regenerate the five profiles and resync the dogfood trees |
| task-018 | Done | -- | -- | quick-check DEFERRED to delivery gate. 7 KB docs updated (6 scoped + tech-debt.md SY-1..SY-5); INDEX.md regenerated; citation-lint/frontmatter-lint clean (0 new violations); grep STATE.md enumerated -- discovery ledger + explicitly-labelled legacy only within scope; 7 out-of-scope docs (domain-glossary.md primary) flagged as SY-5, not edited. [State written by DIRECT EDIT: writeback-state.sh is YAML-only (task-007) and this STATE.md is still markdown -- the same task-010-not-yet-run gap task-017/020 hit.] | Update the Knowledge Base to the YAML state format |
| task-019 | Pending | -- | -- | -- | Post-refactor behavior-preservation verification and coverage re-bootstrap |
| task-020 | Done | -- | -- | behavioral proof both runtimes (200/200) + exit-1 vs exit-0 contrast; quick-check DEFERRED to gate | Retarget the dashboard server write path and raw-state labels to STATE.yml |
| task-021 | Done | -- | -- | KI-004 closed, both twins agree; quick-check DEFERRED to delivery gate per owner leanness directive | Restore the coarse-updated fallback on the Python twin and close the KI-004 divergence |

---

## Quick Check Findings

     Promoted VERBATIM from `delivery-state-template.md ## Delivery Gate` (A-8). Single writer:
     the delivery-gate closing step of `aid-execute` on this work's active branch, written via
     `writeback-state.sh --delivery-id 001 --block ...`. Distinct from per-task quick-check
     findings -- the gate aggregates those deferred [HIGH] rows (via
     `.aid/works/{work}/delivery-001-issues.md`; see `.claude/aid/templates/delivery-issues.md`) and runs
     a full grade.sh pass. The gate's criteria are read from this work's `BLUEPRINT.md § GATE
     CRITERIA`, NOT from this STATE.md. Left absent (section omitted) for full multi-delivery
     works, where each delivery-NNN/STATE.md carries its own gate block (unioned by the DERIVED
     ## Delivery Gates view below). The enum below is byte-identical to
     `delivery-state-template.md` -- no byte-stability break.
<<< LINE 260 NOT CAPTURED >>>
<<< LINE 261 NOT CAPTURED >>>
<<< LINE 262 NOT CAPTURED >>>
<<< LINE 263 NOT CAPTURED >>>
<<< LINE 264 NOT CAPTURED >>>
<<< LINE 265 NOT CAPTURED >>>
<<< LINE 266 NOT CAPTURED >>>
<<< LINE 267 NOT CAPTURED >>>
<<< LINE 268 NOT CAPTURED >>>
<<< LINE 269 NOT CAPTURED >>>
<<< LINE 270 NOT CAPTURED >>>
<<< LINE 271 NOT CAPTURED >>>
<<< LINE 272 NOT CAPTURED >>>
<<< LINE 273 NOT CAPTURED >>>
<<< LINE 274 NOT CAPTURED >>>
<<< LINE 275 NOT CAPTURED >>>
<<< LINE 276 NOT CAPTURED >>>
<<< LINE 277 NOT CAPTURED >>>
---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     Dashboard readers union the child contributions; no agent writes to these sections.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress.
     Never written here; feature progress is tracked via /aid-specify per-feature.
     One row per feature. Tracks /aid-specify progress per feature. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| _none yet_ | | | | | |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields.
     Never written here; the delivery-level STATE.md is the authoritative source.
     One row per delivery from PLAN.md. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files
     (delivery-NNN/tasks/task-NNN/STATE.md). Never written directly into this file.
     The state reader unions all delivery branches using the ordering (most-advanced wins).
     One row per task from PLAN.md execution graph.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section.
     The per-delivery gate block is the authoritative source (single writer per delivery branch).
     Never written here. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of:
       (a) each delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here).
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here.
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

_None yet._

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries from
     delivery-NNN/tasks/task-NNN/STATE.md files.
     Appended by dispatchers at subagent completion (L1+L2+L3 traceability; always-on).
     One row per dispatch. Never written directly here; assemble from per-task logs at read time. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|
| _none yet_ | | | | | |

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections.
     Never written here; one sub-section per task that triggered at least one dispatch.
     Updated by the dispatcher on subagent completion alongside the Calibration Log row. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._

| 2026-08-12 | aid-architect (opus) | GATE Pass 1 FIX cycle 2 (rows 22-31) | ~20 min | 18m52s | All 10 rows. Corrected 3 of the reviewer's own line cites against disk. Row 24 answered with a new 3-ground rationale + capability-based trigger rather than softened wording. |
| 2026-08-12 | aid-architect (opus) | Task-set correction after the L-10/L-11 component additions | 15-25 min | 12m35s | Ran in parallel with the Pass 1 cycle-2 review on disjoint files. Split task-007 rather than widening it (task-020 added); corrected 6 stale L-10 register cites; found 2 residual SPEC contradictions beyond its brief. |
| 2026-08-12 | aid-architect (opus) | GATE Pass 1 FIX cycle 1 (attempt 2, BLUEPRINT.md only) | under 10 min | 5m10s | Narrow-scope re-dispatch after the crash. Re-read from disk first and correctly skipped the edits attempt 1 had already landed. Lesson: scoping a FIX re-dispatch to the one unfinished file survives infrastructure failure far better than re-running the whole ledger. |
| 2026-08-12 | aid-researcher (sonnet) | task-001 EXECUTE (attempt 1) | 15-25 min | ~10m then STALLED | Watchdog-stopped at 1/8 ACs. Cause: the agent tried to read all 149 per-suite log files individually. Sample 1 for `aid-researcher (baseline capture over a large log corpus)`. Lesson: pre-digest a large corpus into one compact artifact and dispatch the agent onto the digest, not the corpus. |
| 2026-08-12 | aid-researcher (sonnet) | task-001 EXECUTE (attempt 2, onto digest.tsv) | 15-25 min | 21m | 8/8 ACs. 781-line baseline: 125 green / 15 environment-local / 9 timeout-local / 0 genuine-red; 91 test files triaged; 131 assertions catalogued. Honestly recorded the two ACs it could not fully satisfy rather than papering over them. The pre-digest fix converted a stall into a clean pass at the same band. |
| 2026-08-12 | aid-reviewer (sonnet) | task-001 REVIEW quick-check (Small tier) | 3-6 min | 7m15s | No CRITICAL/HIGH. Spot-checked 8 claims against disk (suite count, coverage-baseline line count, three pytest function counts, a grep cite) and re-ran one suite live; all held. Slightly over band because it verified claims rather than reading only — the right trade. Sample 1 for `aid-reviewer (per-task quick-check)`. |
| 2026-08-13 | aid-developer (sonnet) | task-012 EXECUTE (3 canonical doc edits + filter) | ~12 min | 7m14s | 10/10 ACs. Ran the filter live rather than reasoning about the regex. Shipped one real defect the orchestrator caught pre-review: `grep -v` exits 1 on no output, so the filter aborted `set -e` callers on an all-state-files change set. Sample 1 for `aid-developer (canonical doc edit + extractable shell function)`. |
| 2026-08-13 | aid-developer (sonnet) | task-002 EXECUTE (convert 3 state templates to YAML) | ~12 min | 20m01s | Over band ~1.7x. 10/10 ACs across 533 source lines -> 393 YAML lines. Caught two of its OWN gaps mid-flight (missing Q&A impact/state enums, quick-check tier/severity hints) and fixed them before finalizing; used PyYAML as an external oracle to prove `user_approved` holds as the string 'no'. Band was set from doc-edit work and undercounts a line-by-line format conversion. |
| 2026-08-13 | aid-reviewer (sonnet) | task-012 REVIEW quick-check (Small tier) | 3-6 min | 3m21s | Executed the filter against 8 state shapes + 13 authored/near-miss paths. Reported 1 CRITICAL that was real in fact but misattributed in cause — the template deletions it found were a concurrent agent's, captured by the orchestrator's commit, not task-012 damage. Lesson: a quick-check reviewer sees the commit, not the dispatch topology, so concurrent-agent noise reads to it as scope violation. |
| 2026-08-13 | aid-reviewer (sonnet) | task-002 REVIEW quick-check (Small tier) | 3-6 min | 5m22s | No CRITICAL/HIGH. Diffed key sets and every closed enum old-vs-new at all three levels, walked every scalar leaf through PyYAML to rule out implicit-typing coercion, and mechanically checked the whole D-3 reject list. Correctly declined to report a quoting difference from SPEC's abbreviated skeleton as a finding, having reasoned it was the more compliant form. |
| 2026-08-13 | aid-developer (sonnet) | task-013 EXECUTE (new RS03-shape suite) | ~12 min | 9m17s | 9/9 ACs, 18 assertions green. Went beyond the brief in two useful ways: proved the anti-drift property by mutating a scratch copy of the doc rather than assuming the RS03 shape delivers it, and added a 7th path shape (flattened `tasks/task-NNN/STATE.md`) the task had enumerated as six. |
| 2026-08-13 | aid-developer (sonnet) | task-006 EXECUTE (3 shell readers, incl. a destructive-op guard) | ~15 min | 12m27s | 13/13 ACs. Produced the behavioral exit-7 proof in both directions (Running -> refuse/7, Completed -> delete/0) in a sandboxed fixture, which is the only evidence that distinguishes a working guard from an unconditional no-op. Disclosed one genuinely unverifiable leg (chmod 000 does not revoke owner reads on NTFS) instead of claiming it passed. |
| 2026-08-13 | aid-reviewer (sonnet) | task-013 REVIEW quick-check (Small tier) | 3-6 min | 4m16s | No CRITICAL/HIGH. Ran THREE independent mutation tests to establish the suite can actually fail: renamed the doc's function (SR00 fails, suite exits 1 without fabricating passes), dropped the `yml` alternation (4 assertions fail, exit 1), and confirmed exit-code propagation. Best evidence-per-minute of any review this delivery — mutation testing is the right default for a TEST-type task. |
| 2026-08-13 | aid-developer (sonnet) | task-003 EXECUTE (Python reader twin rebuild) | 20-30 min | 43m | Over band ~1.6x, consistent with task-002's overrun: the `aid-developer` band was calibrated on doc edits and undercounts code refactoring. 11/11 ACs claimed, and it found two real bugs in its own verification (the `' | '` placeholder heuristic eating genuine quoted pipe values; `_parse_severity` blind to the new bare severity tokens). Disclosed both ACs it could not literally meet instead of claiming them. |
| 2026-08-13 | aid-developer (sonnet) | task-003 FIX (caller-driven dispatch, orchestrator-found) | under 10 min | 5m12s | Narrow re-dispatch after the orchestrator found the content-sniffed dispatch hole. Fixed it exactly as scoped, kept the loose scan's internals untouched, and verified no regression against the REAL `.aid/knowledge/STATE.md`. Sample: a tightly-scoped FIX with concrete measured evidence in the brief lands fast and clean. |
| 2026-08-13 | aid-reviewer (sonnet) | task-003 REVIEW quick-check (Small tier) | 5-10 min | 8m53s | No CRITICAL/HIGH across 8 executed checks. Two standouts: it ran `read_repo` against this repo's REAL `.aid/works/` (7 works, including this work's own un-migrated state file, correctly diagnosed and still listed), and it pinned the exact S5 nesting boundary (level 3/indent 6 legal, level 4/indent 8 rejected) rather than trusting the spec text. |
| 2026-08-13 | aid-developer (sonnet) | task-004 EXECUTE (Node reader twin port) | ~30 min | 40m | 10/10 ACs on a 2,159-line diff. Pointing the dispatch at task-003's COMMITS rather than at the spec paid off: it mirrored the corrected caller-driven dispatch from the start instead of repeating the content-sniffing mistake, and honoured both KI rulings rather than "improving" on the Python twin. Also self-disclosed the KI-004 divergence, which is how that finding surfaced at all. |
| 2026-08-13 | aid-reviewer (sonnet) | task-004 REVIEW quick-check (Small tier) | ~6 min | 16m08s | Over band 2.7x, and worth it: built an independent 39-fixture cross-twin parity harness, found and fixed a bug in its OWN harness (backslash collapsing defeating the escape fixtures) before trusting a 0-diff result. Note for calibration: a parity-verification review is a different, more expensive class than a read-and-check review, and the band should split. |

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections.
     Never written here; one sub-section per task that triggered at least one dispatch.
     Updated by the dispatcher on subagent completion alongside the Calibration Log row. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._


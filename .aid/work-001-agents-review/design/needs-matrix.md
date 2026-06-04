# Needs Matrix (FR1 — Demand Side)

> One row per (consumer × distinct agent-work need), derived from the process.
> Independent of today's agent roster.
> Columns: consumer | phase / state | need | tier-pressure | reuse-count | source-evidence

| # | consumer | phase / state | need | tier-pressure | reuse-count | source-evidence |
|---|----------|--------------|------|---------------|-------------|-----------------|
| 1 | aid-config | MODE1 (show-all settings) | Read, parse, and render settings file as a structured table with missing-value annotation | small | 1 | canonical/skills/aid-config/SKILL.md §Mode 1 — Show all settings |
| 2 | aid-config | MODE2 (view/update one key) | Prompt user for a single setting value via interactive question, validate, and write in place | small | 1 | canonical/skills/aid-config/SKILL.md §Mode 2 — View/update one key |
| 3 | aid-discover | GENERATE | Orchestrate parallel discovery subagent fanout: build project index, resolve doc-set, dispatch 5 specialized discovery agents to populate KB documents | large | 1 | canonical/skills/aid-discover/SKILL.md §Dispatch (GENERATE→architect); canonical/skills/aid-discover/references/state-generate.md §Steps 0–8 |
| 4 | aid-discover | REVIEW | Review KB documents for semantic accuracy, completeness, and evidence quality; assign grade against rubric | large | 4 | canonical/skills/aid-discover/SKILL.md §Dispatch (REVIEW→architect); canonical/skills/aid-discover/references/state-review.md |
| 5 | aid-discover | Q-AND-A | Collect and record user answers to pending KB questions inline (no subagent dispatch) | small | 3 | canonical/skills/aid-discover/SKILL.md §Dispatch (Q-AND-A→inline); canonical/skills/aid-discover/references/state-q-and-a.md |
| 6 | aid-discover | FIX | Apply Q&A answers and reviewer feedback to KB documents in parallel (one subagent per file); regenerate generated files; commit | large | 3 | canonical/skills/aid-discover/SKILL.md §Dispatch (FIX→architect); canonical/skills/aid-discover/references/state-fix.md |
| 7 | aid-discover | APPROVAL | Present KB grade to user and await explicit approval; record approval in STATE.md | small | 3 | canonical/skills/aid-discover/SKILL.md §Dispatch (APPROVAL→inline); canonical/skills/aid-discover/references/state-approval.md |
| 8 | aid-discover | DONE | Print closing summary and halt | small | 5 | canonical/skills/aid-discover/SKILL.md §Dispatch (DONE→inline); canonical/skills/aid-discover/references/state-done.md |
| 9 | aid-interview | FIRST-RUN | Conduct initial conversational interview with user from scratch; create STATE.md and REQUIREMENTS.md scaffold one answer at a time | large | 1 | canonical/skills/aid-interview/SKILL.md §Dispatch (FIRST-RUN→interviewer); canonical/skills/aid-interview/references/state-first-run.md |
| 10 | aid-interview | Q-AND-A | Resolve pending cross-phase questions from STATE.md with the user via directed conversation | medium | 3 | canonical/skills/aid-interview/SKILL.md §Dispatch (Q-AND-A→interviewer); canonical/skills/aid-interview/references/state-q-and-a.md |
| 11 | aid-interview | TRIAGE | Classify the work request (free-form description → infer type + match recipe); route to lite path or full path | medium | 1 | canonical/skills/aid-interview/SKILL.md §Dispatch (TRIAGE→interviewer); canonical/skills/aid-interview/references/state-triage.md |
| 12 | aid-interview | CONDENSED-INTAKE | Conduct condensed slot-fill interview for lite-path work; write work-root SPEC.md with all mandatory sections | medium | 1 | canonical/skills/aid-interview/SKILL.md §Dispatch (CONDENSED-INTAKE→interviewer); canonical/skills/aid-interview/references/state-condensed-intake.md |
| 13 | aid-interview | TASK-BREAKDOWN | Design typed task breakdown from SPEC; propose and write tasks/task-NNN.md files with typed, sized, dependency-ordered tasks | large | 2 | canonical/skills/aid-interview/SKILL.md §Dispatch (TASK-BREAKDOWN→architect); canonical/skills/aid-interview/references/state-task-breakdown.md |
| 14 | aid-interview | LITE-REVIEW | Review lite-path task set against SPEC for pre-execution quality gate; grade and list issues | large | 2 | canonical/skills/aid-interview/SKILL.md §Dispatch (LITE-REVIEW→reviewer); canonical/skills/aid-interview/references/state-lite-review.md |
| 15 | aid-interview | LITE-DONE | Produce lite-path terminal summary and handoff prompt to aid-execute (inline, no subagent) | small | 1 | canonical/skills/aid-interview/SKILL.md §Dispatch (LITE-DONE→inline); canonical/skills/aid-interview/references/state-lite-done.md |
| 16 | aid-interview | CONTINUE | Resume conversational requirements interview for incomplete sections; update REQUIREMENTS.md incrementally | large | 1 | canonical/skills/aid-interview/SKILL.md §Dispatch (CONTINUE→interviewer); canonical/skills/aid-interview/references/state-continue.md |
| 17 | aid-interview | COMPLETION | Run KB hydration against completed REQUIREMENTS.md; present full requirements for user approval | large | 1 | canonical/skills/aid-interview/SKILL.md §Dispatch (COMPLETION→interviewer); canonical/skills/aid-interview/references/state-completion.md |
| 18 | aid-interview | FEATURE-DECOMPOSITION | Decompose approved requirements into structured feature folders (feature-NNN-name/SPEC.md stubs) | large | 1 | canonical/skills/aid-interview/SKILL.md §Dispatch (FEATURE-DECOMPOSITION→architect); canonical/skills/aid-interview/references/state-feature-decomposition.md |
| 19 | aid-interview | CROSS-REFERENCE | Validate REQUIREMENTS.md against KB and codebase; identify gaps and contradictions; create Q&A entries | large | 2 | canonical/skills/aid-interview/SKILL.md §Dispatch (CROSS-REFERENCE→reviewer); canonical/skills/aid-interview/references/state-cross-reference.md |
| 20 | aid-interview | DONE | Print terminal summary and user-choice prompt (inline, no subagent) | small | 5 | canonical/skills/aid-interview/SKILL.md §Dispatch (DONE→inline); canonical/skills/aid-interview/references/state-done.md |
| 21 | aid-specify | INITIALIZE | Load feature context (KB, requirements, codebase); determine spec sections; begin Propose→Discuss→Write loop | large | 1 | canonical/skills/aid-specify/SKILL.md §Dispatch (INITIALIZE→architect); canonical/skills/aid-specify/references/state-initialize.md |
| 22 | aid-specify | CONTINUE | Resume Propose→Discuss→Write loop for next pending spec section; update SPEC.md collaboratively | large | 1 | canonical/skills/aid-specify/SKILL.md §Dispatch (CONTINUE→architect); canonical/skills/aid-specify/references/state-continue.md |
| 23 | aid-specify | SPIKE | Identify and document unknowns blocking the spec; define spike scope and return to CONTINUE | small | 1 | canonical/skills/aid-specify/SKILL.md §Dispatch (SPIKE→inline); canonical/skills/aid-specify/references/state-spike.md |
| 24 | aid-specify | BLOCKED | Surface pending loopback (cross-phase Q&A) that must be resolved before spec work continues | small | 1 | canonical/skills/aid-specify/SKILL.md §Dispatch (BLOCKED→inline); canonical/skills/aid-specify/references/state-blocked.md |
| 25 | aid-specify | REVIEW | Review complete spec against current KB and codebase; grade; advance to DONE if meets minimum | large | 4 | canonical/skills/aid-specify/SKILL.md §Dispatch (REVIEW→reviewer); canonical/skills/aid-specify/references/state-review.md |
| 26 | aid-specify | DONE | Record feature status as Ready in STATE.md; print summary and halt | small | 5 | canonical/skills/aid-specify/SKILL.md §Dispatch (DONE→inline); canonical/skills/aid-specify/references/state-done.md |
| 27 | aid-plan | FIRST-RUN | Map feature dependencies; propose deliverable groupings and sequence via Propose→Discuss→Write loop; write PLAN.md | large | 2 | canonical/skills/aid-plan/SKILL.md §Dispatch (FIRST-RUN→architect); canonical/skills/aid-plan/references/first-run-loop.md |
| 28 | aid-plan | REVIEW | Review PLAN.md deliverables against feature SPECs and KB; grade; advance to DONE if meets minimum | large | 4 | canonical/skills/aid-plan/SKILL.md §Dispatch (REVIEW→reviewer); canonical/skills/aid-plan/references/review-deliverables.md |
| 29 | aid-plan | DONE | Print plan-complete summary and halt (inline, no subagent) | small | 5 | canonical/skills/aid-plan/SKILL.md §Dispatch (DONE→inline) — inline halt state; no references/state-done.md |
| 30 | aid-detail | FIRST-RUN | Propose typed, dependency-ordered task breakdown per deliverable from PLAN.md; write tasks/task-NNN.md files | large | 2 | canonical/skills/aid-detail/SKILL.md §Dispatch (FIRST-RUN→architect); canonical/skills/aid-detail/references/first-run.md |
| 31 | aid-detail | REVIEW | Re-review existing task files against current PLAN.md and SPECs; confirm or revise task scope | large | 4 | canonical/skills/aid-detail/SKILL.md §Dispatch (REVIEW→architect); canonical/skills/aid-detail/references/review.md |
| 32 | aid-detail | DONE | Print task-list approved summary and halt (inline, no subagent) | small | 5 | canonical/skills/aid-detail/SKILL.md §Dispatch (DONE→inline) — inline halt state; no references/state-done.md |
| 33 | aid-execute | EXECUTE | Execute type-specific task work (RESEARCH/DESIGN/IMPLEMENT/TEST/DOCUMENT/MIGRATE/REFACTOR/CONFIGURE) using the type-appropriate executor; may use mechanical sub-agents for extraction/enumeration | large | 1 | canonical/skills/aid-execute/SKILL.md §Dispatch (EXECUTE→type-specific); canonical/skills/aid-execute/references/state-execute.md §Agent Selection |
| 34 | aid-execute | REVIEW | Review task output against acceptance criteria with a clean-context reviewer agent; grade and list all issues | large | 4 | canonical/skills/aid-execute/SKILL.md §Dispatch (REVIEW→reviewer); canonical/skills/aid-execute/references/state-review.md |
| 35 | aid-execute | FIX | Apply code-level fixes identified by reviewer using the same type-appropriate executor; return to REVIEW | large | 3 | canonical/skills/aid-execute/SKILL.md §Dispatch (FIX→same type as EXECUTE); canonical/skills/aid-execute/references/state-fix.md |
| 36 | aid-execute | DONE | Mark task complete in STATE.md; print summary and halt (inline, no subagent) | small | 5 | canonical/skills/aid-execute/SKILL.md §Dispatch (DONE→inline) — inline halt state |
| 37 | aid-execute | RE-RUN | Handle re-invocation of a completed task: show status, offer re-open or skip | small | 2 | canonical/skills/aid-execute/SKILL.md §Dispatch (RE-RUN→inline); canonical/skills/aid-execute/references/state-re-run.md |
| 38 | aid-execute | DELIVERY-GATE | Run a comprehensive review of all tasks in the delivery against combined acceptance criteria; grade the full delivery | large | 1 | canonical/skills/aid-execute/SKILL.md §Dispatch (DELIVERY-GATE→reviewer, tier=complexity score); canonical/skills/aid-execute/references/state-delivery-gate.md |
| 39 | aid-execute | EXECUTE-DRILLDOWN | Render per-in-flight-task snapshot during pool-dispatch wave; track status, heartbeat, elapsed time, and ETA per running sub-unit (extracted sub-spec of EXECUTE state) | small | 1 | canonical/skills/aid-execute/SKILL.md §EXECUTE-WAVE: AC4 Sub-unit Drill-down; canonical/skills/aid-execute/references/state-execute-drilldown.md |
| 40 | aid-deploy | IDLE | Assess eligible deliveries for release; check task grades and known-issue blockers | medium | 1 | canonical/skills/aid-deploy/SKILL.md §Dispatch (IDLE→operator); canonical/skills/aid-deploy/references/state-idle.md |
| 41 | aid-deploy | SELECTING | Present eligible deliveries for user selection; capture release scope | medium | 1 | canonical/skills/aid-deploy/SKILL.md §Dispatch (SELECTING→operator); canonical/skills/aid-deploy/references/state-selecting.md |
| 42 | aid-deploy | VERIFYING | Run full build, tests, and lint against selected deliveries; report pass/fail | medium | 1 | canonical/skills/aid-deploy/SKILL.md §Dispatch (VERIFYING→operator); canonical/skills/aid-deploy/references/state-verifying.md |
| 43 | aid-deploy | PACKAGING | Produce release artifacts per infrastructure.md §Deployment; generate release notes; update statuses | medium | 1 | canonical/skills/aid-deploy/SKILL.md §Dispatch (PACKAGING→operator); canonical/skills/aid-deploy/references/state-packaging.md |
| 44 | aid-deploy | DONE | Print release-complete summary and halt (inline, no subagent) | small | 5 | canonical/skills/aid-deploy/SKILL.md §Dispatch (DONE→inline) — inline halt state |
| 45 | aid-deploy | RE-RUN | Show active packages and offer fresh run or finding-review (inline, no subagent) | small | 2 | canonical/skills/aid-deploy/SKILL.md §Dispatch (RE-RUN→inline); canonical/skills/aid-deploy/references/state-re-run.md |
| 46 | aid-monitor | OBSERVE | Read and interpret production telemetry signals (logs, metrics, error tracking, CI/CD); correlate against baselines; extract anomaly candidates | large | 1 | canonical/skills/aid-monitor/SKILL.md §Dispatch (OBSERVE→researcher); canonical/skills/aid-monitor/references/state-observe.md |
| 47 | aid-monitor | CLASSIFY | Classify each anomaly as BUG/CHANGE REQUEST/INFRASTRUCTURE/NO ACTION with root cause analysis | large | 1 | canonical/skills/aid-monitor/SKILL.md §Dispatch (CLASSIFY→researcher); canonical/skills/aid-monitor/references/state-classify.md |
| 48 | aid-monitor | ROUTE | Propose and execute routing actions per finding classification; write to aid-interview or ops | medium | 1 | canonical/skills/aid-monitor/SKILL.md §Dispatch (ROUTE→orchestrator); canonical/skills/aid-monitor/references/state-route.md |
| 49 | aid-monitor | DONE | Print monitor-cycle summary and halt (inline, no subagent) | small | 5 | canonical/skills/aid-monitor/SKILL.md §Dispatch (DONE→inline) — inline halt state |
| 50 | aid-housekeep | PREFLIGHT | Verify prerequisites (workspace exists, not Plan Mode, git repo present); resolve run-state file; route to KB-DELTA or CLEANUP | small | 1 | canonical/skills/aid-housekeep/SKILL.md §Dispatch (PREFLIGHT→inline); canonical/skills/aid-housekeep/references/state-preflight.md |
| 51 | aid-housekeep | KB-DELTA | Detect KB delta since last approval; scope affected documents; dispatch targeted re-discovery via aid-discover | large | 1 | canonical/skills/aid-housekeep/SKILL.md §Dispatch (KB-DELTA→architect); canonical/skills/aid-housekeep/references/state-kb-delta.md |
| 52 | aid-housekeep | SUMMARY-DELTA | Check whether HTML summary is stale relative to KB; delegate to aid-summarize if regeneration needed | small | 1 | canonical/skills/aid-housekeep/SKILL.md §Dispatch (SUMMARY-DELTA→inline delegates to /aid-summarize); canonical/skills/aid-housekeep/references/state-summary-delta.md |
| 53 | aid-housekeep | CLEANUP | Sweep and prune stale work-area artifacts (old heartbeat files, orphan state files, etc.); commit cleanup | small | 1 | canonical/skills/aid-housekeep/SKILL.md §Dispatch (CLEANUP→inline); canonical/skills/aid-housekeep/references/state-cleanup.md |
| 54 | aid-housekeep | DONE | Remove run-state file; print housekeeping-complete summary and halt | small | 5 | canonical/skills/aid-housekeep/SKILL.md §Dispatch (DONE→inline); canonical/skills/aid-housekeep/references/state-done.md |
| 55 | aid-summarize | PREFLIGHT | Verify prerequisites: KB approved, Node.js available, network reachable; abort with clear message on failure | small | 1 | canonical/skills/aid-summarize/SKILL.md §Dispatch (PREFLIGHT→inline); canonical/skills/aid-summarize/references/state-preflight.md |
| 56 | aid-summarize | STALE-CHECK | Compare KB last-review date vs last-summary date; determine whether regeneration is needed or HTML is already current | small | 1 | canonical/skills/aid-summarize/SKILL.md §Dispatch (STALE-CHECK→inline); canonical/skills/aid-summarize/references/state-stale-check.md |
| 57 | aid-summarize | PROFILE | Auto-detect project type from KB signals to select the appropriate section template | small | 1 | canonical/skills/aid-summarize/SKILL.md §Dispatch (PROFILE→inline); canonical/skills/aid-summarize/references/state-profile.md |
| 58 | aid-summarize | GENERATE | Build knowledge-summary.html from KB content, Mermaid diagrams, CSS/JS assets, and profile-specific section template | large | 1 | canonical/skills/aid-summarize/SKILL.md §Dispatch (GENERATE→inline); canonical/skills/aid-summarize/references/state-generate.md |
| 59 | aid-summarize | VALIDATE | Run machine-verifiable quality checks (diagram parse/render, HTML validity, contrast, link health); compute Machine Grade | small | 1 | canonical/skills/aid-summarize/SKILL.md §Dispatch (VALIDATE→inline); canonical/skills/aid-summarize/references/state-validate.md |
| 60 | aid-summarize | MANUAL-CHECKLIST | Present interactive K1/K2/V1 human-judgment checks; collect user responses; compute Human Grade | small | 1 | canonical/skills/aid-summarize/SKILL.md §Dispatch (MANUAL-CHECKLIST→inline); canonical/skills/aid-summarize/references/state-manual-checklist.md |
| 61 | aid-summarize | FIX | Apply fixes to knowledge-summary.html to address failing machine or human checks; re-enter VALIDATE | medium | 3 | canonical/skills/aid-summarize/SKILL.md §Dispatch (FIX→inline); canonical/skills/aid-summarize/references/state-fix.md |
| 62 | aid-summarize | APPROVAL | Present both grades to user; await explicit approval to write back | small | 3 | canonical/skills/aid-summarize/SKILL.md §Dispatch (APPROVAL→inline); canonical/skills/aid-summarize/references/state-approval.md |
| 63 | aid-summarize | WRITEBACK | Write approval record to STATE.md §Summarization History; update Knowledge Summary Status | small | 1 | canonical/skills/aid-summarize/SKILL.md §Dispatch (WRITEBACK→inline); canonical/skills/aid-summarize/references/state-writeback.md |
| 64 | aid-summarize | DONE | Print completion summary (normal or idempotent variant) and halt | small | 5 | canonical/skills/aid-summarize/SKILL.md §Dispatch (DONE→inline); canonical/skills/aid-summarize/references/state-done.md |
| 65 | aid-generate | LOAD | Load and validate profile TOML configuration for each selected install-tree target; read prior emission manifest | small | 1 | .claude/skills/aid-generate/SKILL.md §Mode: LOAD |
| 66 | aid-generate | VALIDATE | Verify canonical completeness: expected skills present, 22 agents present, non-empty templates | small | 1 | .claude/skills/aid-generate/SKILL.md §Mode: VALIDATE |
| 67 | aid-generate | RENDER | Run all three asset renderers (agents, skills, templates) per selected profile; write emission manifest; perform deletion pass | medium | 1 | .claude/skills/aid-generate/SKILL.md §Mode: RENDER |
| 68 | aid-generate | VERIFY | Run deterministic byte-identical re-render audit (hard gate) + advisory conformance checks | medium | 1 | .claude/skills/aid-generate/SKILL.md §Mode: VERIFY |
| 69 | aid-generate | REPORT | Print concise render-run summary with per-profile file counts, VERIFY results, and git diff stat | small | 1 | .claude/skills/aid-generate/SKILL.md §Mode: REPORT |

---

## Notes on reuse-count computation

`reuse-count` counts distinct consumers sharing an **equivalent need** (same capability class),
not the same row. The groupings used:

- **"Review artifact against rubric / grade"** (rows 4, 14, 25, 28, 31, 34, 38): consumers share a
  review-and-grade need at different scopes. reuse-count reflects genuinely equivalent capability classes:
  - Grade spec/plan/tasks/output (rows 25, 28, 31, 34): aid-specify REVIEW, aid-plan REVIEW,
    aid-detail REVIEW, aid-execute REVIEW all need "review artifact against structured rubric" → reuse-count 4.
  - Grade pre-execution task set (row 14): aid-interview LITE-REVIEW + aid-execute REVIEW both
    review task sets → reuse-count 2 for that class.
  - Grade KB documents (rows 4, 6): aid-discover REVIEW and FIX share KB review/fix capability → reuse-count noted as 4 (REVIEW row also shared conceptually with other review states).
- **"Inline Q&A / collect user answers"** (rows 5, 7, 10): aid-discover Q-AND-A, APPROVAL, and
  aid-interview Q-AND-A all collect user responses → reuse-count 3.
- **"Halt/terminal summary"** (rows 8, 20, 26, 29, 32, 36, 44, 49, 54, 64): 5+ consumers share
  inline DONE states → reuse-count 5.
- **"Design typed task breakdown"** (rows 13, 30): aid-interview TASK-BREAKDOWN and aid-detail
  FIRST-RUN both propose typed task lists → reuse-count 2.
- **"Sequence and plan deliveries"** (rows 27, 30): aid-plan FIRST-RUN and aid-detail FIRST-RUN
  share architectural design of delivery structure → reuse-count 2.
- **"Apply fixes in response to review"** (rows 6, 35, 61): aid-discover FIX, aid-execute FIX,
  aid-summarize FIX all apply targeted fixes after a review → reuse-count 3.
- **"Approval gate / user sign-off"** (rows 7, 62): aid-discover APPROVAL, aid-summarize APPROVAL
  → reuse-count 3; (rows 37, 45): RE-RUN states → reuse-count 2.
- Single-consumer needs retain reuse-count 1.

---

## Consumer set (12 consumers)

1. aid-config
2. aid-discover
3. aid-interview
4. aid-specify
5. aid-plan
6. aid-detail
7. aid-execute
8. aid-deploy
9. aid-monitor
10. aid-housekeep
11. aid-summarize
12. aid-generate

---

## Two-way set-equality verification

### Consumer set check

**Matrix consumers:** aid-config, aid-discover, aid-interview, aid-specify, aid-plan, aid-detail,
aid-execute, aid-deploy, aid-monitor, aid-housekeep, aid-summarize, aid-generate (12 total).

**Expected:** `ls canonical/skills/` (11 dirs) ∪ {aid-generate} = {aid-config, aid-deploy,
aid-detail, aid-discover, aid-execute, aid-housekeep, aid-interview, aid-monitor, aid-plan,
aid-specify, aid-summarize} ∪ {aid-generate} = 12 members.

Forward diff (expected → matrix): empty.
Reverse diff (matrix → expected): empty.
**Result: PASS.**

### Phase/state set check

Source-of-truth enumeration (SKILL.md dispatch tables + state-*.md file stems):

| consumer | states from dispatch table | state-*.md stems | union |
|----------|---------------------------|------------------|-------|
| aid-config | (no dispatch table; MODE1/MODE2 from SKILL.md body) | (none) | MODE1, MODE2 |
| aid-discover | GENERATE, REVIEW, Q-AND-A, FIX, APPROVAL, DONE | generate, review, q-and-a, fix, approval, done | 6 |
| aid-interview | FIRST-RUN, Q-AND-A, TRIAGE, CONDENSED-INTAKE, TASK-BREAKDOWN, LITE-REVIEW, LITE-DONE, CONTINUE, COMPLETION, FEATURE-DECOMPOSITION, CROSS-REFERENCE, DONE | first-run, q-and-a, triage, condensed-intake, task-breakdown, lite-review, lite-done, continue, completion, feature-decomposition, cross-reference, done | 12 |
| aid-specify | INITIALIZE, CONTINUE, SPIKE, BLOCKED, REVIEW, DONE | initialize, continue, spike, blocked, review, done | 6 |
| aid-plan | FIRST-RUN, REVIEW, DONE | (none; files named first-run-loop.md, review-deliverables.md) | FIRST-RUN, REVIEW, DONE |
| aid-detail | FIRST-RUN, REVIEW, DONE | (none; files named first-run.md, review.md) | FIRST-RUN, REVIEW, DONE |
| aid-execute | EXECUTE, REVIEW, FIX, DONE, RE-RUN, DELIVERY-GATE | execute, review, fix, re-run, delivery-gate, execute-drilldown | EXECUTE, REVIEW, FIX, DONE, RE-RUN, DELIVERY-GATE, EXECUTE-DRILLDOWN |
| aid-deploy | IDLE, SELECTING, VERIFYING, PACKAGING, DONE, RE-RUN | idle, selecting, verifying, packaging, re-run | IDLE, SELECTING, VERIFYING, PACKAGING, DONE, RE-RUN |
| aid-monitor | OBSERVE, CLASSIFY, ROUTE, DONE | observe, classify, route | OBSERVE, CLASSIFY, ROUTE, DONE |
| aid-housekeep | PREFLIGHT, KB-DELTA, SUMMARY-DELTA, CLEANUP, DONE | preflight, kb-delta, summary-delta, cleanup, done | 5 |
| aid-summarize | PREFLIGHT, STALE-CHECK, PROFILE, GENERATE, VALIDATE, MANUAL-CHECKLIST, FIX, APPROVAL, WRITEBACK, DONE | preflight, stale-check, profile, generate, validate, manual-checklist, fix, approval, writeback, done | 10 |
| aid-generate | (LOAD, VALIDATE, RENDER, VERIFY, REPORT from SKILL.md modes) | (none — .claude/skills/ has no state-*.md) | LOAD, VALIDATE, RENDER, VERIFY, REPORT |

Matrix (consumer, phase/state) pairs: rows 1–69, total 69 pairs.
Source-of-truth (consumer, phase/state) pairs: 2+6+12+6+3+3+7+6+4+5+10+5 = 69 pairs.

Forward diff (source → matrix): empty.
Reverse diff (matrix → source): empty.
**Result: PASS.**

---

## Ambiguity notes and resolutions

**A1 — aid-config has no dispatch table and no state-*.md files.**
Resolution: aid-config's two operational modes (MODE1 show-all, MODE2 view/update) ARE the
phases of its process, enumerated in its SKILL.md body under "Mode 1" and "Mode 2" headings.
They are included as the (consumer, phase) pairs for aid-config. The two-way set-equality
AC for phase/state uses "SKILL.md dispatch tables OR references/state-*.md stems" — for
aid-config the SKILL.md body modes satisfy the "SKILL.md" side of the OR.

**A2 — aid-plan and aid-detail reference files are not named state-*.md.**
Resolution: aid-plan uses first-run-loop.md and review-deliverables.md; aid-detail uses
first-run.md and review.md. These are the authoritative per-state bodies cited in the
dispatch tables. The phase/state values (FIRST-RUN, REVIEW, DONE) come from the
SKILL.md dispatch tables, satisfying the "SKILL.md dispatch tables" side of the AC.

**A3 — aid-generate uses "modes" not "states" and has no state-*.md files.**
Resolution: The SKILL.md for aid-generate has a "State Detection" section naming LOAD,
VALIDATE, RENDER, VERIFY, REPORT and uses "Mode:" headings for each. These are the
enumerated states for the purposes of the two-way set-equality check, sourced from
the SKILL.md body (satisfying the "SKILL.md dispatch tables" side of the AC).

**A4 — aid-execute DONE has no state-done.md file; aid-deploy DONE, aid-monitor DONE similarly absent.**
Resolution: These DONE states are inline (no subagent dispatch, trivial halt message)
as stated in the SKILL.md dispatch tables. They are included in the matrix derived from
the SKILL.md dispatch table rows; the absence of a references/state-done.md is not a
gap — the SKILL.md dispatch table is the authoritative source.

**A5 — aid-detail REVIEW worker is listed as "architect" (not "reviewer") in the dispatch table.**
Noted as potentially unexpected. The need is still "review and grade task files against
PLAN.md/SPECs" — the matrix records the process capability needed, not the current agent
assignment. This is demand-side only; the Architect task is noted as a potential design
issue for the roster-design phase.

**A6 — aid-execute DELIVERY-GATE is listed in the dispatch table but not a primary state-machine state.**
Resolution: It appears as a distinct row in the SKILL.md Dispatch table with its own
references/state-delivery-gate.md file, so it is included as a distinct (consumer, state) pair.

**A7 — aid-execute state-execute-drilldown.md is a state-*.md file stem but not in the dispatch table.**
The file `references/state-execute-drilldown.md` is an extracted sub-spec document for the
pool-dispatch snapshot rendering during the EXECUTE state. It is named with the state-* prefix
but describes a rendering sub-concern of EXECUTE, not a separately dispatched state. It has
no dispatch table row and the SKILL.md refers to it as an "authoritative spec" for the
EXECUTE-WAVE sub-unit drill-down, not a state entry. For strict two-way set-equality of
state-*.md stems, row 39 (EXECUTE-DRILLDOWN) is included in the matrix. The need
(render per-in-flight-task status snapshot during pool dispatch) is a distinct operational
requirement from the EXECUTE state's task-execution work.

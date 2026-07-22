# task-001: Analyst + Confirm front-end

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** work-020-update-kb-intent-alignment -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Add a **Pre-flight ISOLATE** step to `canonical/skills/aid-update-kb/SKILL.md`: after confirming the prompt, create + enter the skill's own worktree on an `aid/update-kb-<ts>` branch off `master` via plain `git worktree add <path> -b aid/update-kb-<ts> master`, entered via the host-native switch per `worktree-lifecycle.md § Step 2` (claude-code `EnterWorktree`; other profiles cwd-fallback). Do **not** use `worktree-lifecycle.sh`/`work-initiation-gate.md` — those are keyed on a `work-NNN` id (`^work-[0-9]+$`) this off-pipeline skill does not allocate (run-state stays timestamp-keyed, FR-9); this mirrors the *isolation* `/aid-fix` gets at INTAKE, adapted to the `aid/update-kb-*` branch convention. Fail-closed: if the worktree can't be created, STOP; never run in the caller's tree. All states, run-state, edits, and commits live in the worktree (FR-11, AC-10).
- Rewrite `canonical/skills/aid-update-kb/references/state-analyze.md` so ANALYZE is the `aid-researcher` (sonnet) analyst step producing the **Impact Map** (understanding + per-location current-statement/relation/confidence, cited `file:line`; contradictions/open-questions). Remove the tag-overlap candidate net (old `:46`); make freshness verdicts advisory only; forbid silent inference (HL-3); keep the un-groundable PAUSE escalation.
- Create `canonical/skills/aid-update-kb/references/state-scope.md`: the `aid-architect` (opus) step that turns the Impact Map into the **minimal Scope Plan** (each item `Traces-to` an instruction clause or closure need; `Kind` = in-scope|closure|new-file) plus the explicit **Not-Changing** list, and drafts the CONFIRM questions.
- Create `canonical/skills/aid-update-kb/references/state-confirm.md`: the NEW pre-apply human gate (`[1] Confirm` freezes `Confirmed Scope` → APPLY; `[2] Adjust` → SCOPE/ANALYZE; `[3] Cancel` → HALT); PAUSE-FOR-USER-ACTION.
- Update `canonical/skills/aid-update-kb/SKILL.md`: Pre-flight ISOLATE (above), 7-state diagram, per-state banners, resume table (add SCOPE, CONFIRM rows), Dispatch table, updated `description:` frontmatter, and a new "Hard limits (HL-1..HL-8)" section. Wire the ANALYZE/SCOPE dispatches as **clean-context** sub-agents that receive only the verbatim instruction + KB/code pointers, never the session transcript (HL-8, AC-9); the orchestrator must not enrich the dispatch with session-derived context. Update the "DONE (commit convention)" note so it reflects the Pre-flight worktree branch (no separate branch created at DONE; never push `master`). While here, fix **all** `five-mandate`→`four-mandate` occurrences in SKILL.md (frontmatter `:8`, the REVIEW state-entry banner body, and the "REVIEW reuse (f005)" blockquote under `## Dispatch`) — align to `state-review.md`'s authoritative "four-mandate" (Correctness / Anatomy-incl-altitude / Teach-back / Act-back).
- Update the run-state schema (in SKILL.md § State Detection + the state docs): add `Impact Map`, `Scope Plan` (replacing `Change Plan`), `Confirmed` / `Confirmed At` / `Confirmed Scope` / `Pre-APPLY baseline` / `Adjustments`. `state-confirm.md` captures the `Pre-APPLY baseline` (git HEAD or `clean` marker) at `[1] Confirm`, before APPLY's first edit.

**Acceptance Criteria:**
- [ ] ANALYZE names the docs the instruction *concerns* via INDEX.md without a tag-overlap candidate net; freshness is advisory; a LIKELY/UNCERTAIN inference is surfaced as a CONFIRM question, never applied silently (AC-3, AC-8, HL-3/HL-4/HL-5).
- [ ] SCOPE emits a Scope Plan where every item has a `Traces-to`, plus a Not-Changing list; `closure`/`new-file` kinds are marked (AC-2, AC-6, HL-2/HL-6).
- [ ] `state-confirm.md` is a PAUSE gate that freezes `Confirmed Scope` and captures the `Pre-APPLY baseline`; no CHAIN to APPLY without `[1]` (AC-1, HL-1).
- [ ] SKILL.md shows the 7-state machine end-to-end (diagram, banners, resume table, dispatch table) and a Hard-Limits section citing HL-1..HL-8; `description:` reflects the analyst + confirm gate; the mandate count reads "four-mandate" consistently.
- [ ] The Pre-flight ISOLATE step creates + enters the skill's own worktree off `master` before any state, fail-closed (FR-11, AC-10).
- [ ] ANALYZE/SCOPE are dispatched clean-context with the verbatim instruction + KB/code only; no session-transcript pass-through (HL-8, AC-9).
- [ ] Run-state schema documents the new fields (incl. `Pre-APPLY baseline`); `Change Plan` no longer referenced in SKILL.md/state-analyze.
- [ ] All section-6 quality gates pass.

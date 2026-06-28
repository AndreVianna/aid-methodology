# task-037: Canonical carve into aid-describe + aid-define with partitioned states and inter-skill seam

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-006

**Depends on:** task-036

**Scope:**
- Execute Flow steps 1-2 of the feature SPEC: the history-preserving structural carve of
  `canonical/skills/aid-interview/` into the two new canonical skill dirs, using the task-036
  inventory as the authoritative partition. Touches only `canonical/skills/aid-interview/` ->
  `aid-describe/` + the new `aid-define/`; no external surfaces (task-038) and no rendering (task-039).
- **(1) Carve the dirs (history-preserving).** `git mv canonical/skills/aid-interview
  canonical/skills/aid-describe` (the larger conversational half carries history for all files). Create
  `canonical/skills/aid-define/references/` and `git mv` exactly the 6 define-owned refs into it:
  `state-feature-decomposition.md`, `feature-decomposition.md`, `state-cross-reference.md`,
  `cross-reference.md`, `reviewer-brief.md`, `state-done.md`. All remaining `references/*.md` stay in
  `aid-describe/` (per the task-036 partition, including any 002/003/004-added describe-side file).
- **(2) Author the two SKILL.md identities + partition the State Detection / Dispatch tables.**
  - `aid-describe/SKILL.md`: frontmatter `name: aid-describe`; State Detection keeps FIRST-RUN /
    Q-AND-A / TRIAGE / CONTINUE / COMPLETION + L1-L4 CONDENSED-INTAKE/TASK-BREAKDOWN/LITE-REVIEW/
    LITE-DONE; the frontmatter state-machine line becomes `FIRST-RUN -> Q-AND-A -> TRIAGE -> {full:
    CONTINUE -> COMPLETION [PAUSE -> /aid-define] | lite: CONDENSED-INTAKE -> TASK-BREAKDOWN ->
    LITE-REVIEW -> LITE-DONE}`; keep the `aid-interviewer` / `aid-architect` / `aid-reviewer` dispatch
    agents unchanged (substring guard -- `aid-interviewer` token stays verbatim).
  - `aid-define/SKILL.md`: frontmatter `name: aid-define`; State Detection precondition `Interview
    State: Approved`, owning FEATURE-DECOMPOSITION / CROSS-REFERENCE / DONE; state-machine line becomes
    `(Approved REQUIREMENTS) -> FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE [HALT -> /aid-specify]`;
    dispatch rows keep `aid-architect` (decomposition) + `aid-reviewer` (cross-reference).
- **(3) The inter-skill seam (the ONE state-machine edit beyond moving files).** In
  `aid-describe/references/state-completion.md`, redirect COMPLETION's EXISTING pause -- it is already
  PAUSE-FOR-USER-DECISION; do NOT convert a chain. Retarget its resume signpost from `Re-run
  /aid-interview to continue to [State: FEATURE-DECOMPOSITION]` to `Requirements approved. Run
  /aid-define {work} to decompose into features.` and retarget the pipeline `Pause Reason`/resume
  writeback from `/aid-interview` to `/aid-define`. The pause itself is unchanged.
- **(4) Composability hand-off pointers.** aid-define's State Detection HALTs with `Run /aid-describe
  {work} first to gather and approve requirements.` when invoked before approval; each skill's State
  Detection prints a one-line hand-off pointer to the sibling command when it detects a sibling-owned
  state. The `state-done.md` `[1] Add more information` sub-action points requirements-level edits back
  to `/aid-describe` (the Open-Question wording nuance -- a hand-off pointer, not a state move).
- **(5) Self-reference rewrite within the two carved dirs.** In each new dir rewrite the skill's OWN
  identity self-references: every `/aid-interview` command token and `aid-interview` self-reference and
  any `.claude/skills/aid-interview/...` example path -> the owning new name; the
  `state-feature-decomposition.md` writeback `--field "Active Skill" --value aid-interview` -> `aid-define`,
  describe-side state writebacks -> `aid-describe`. `Phase` stays `Interview` for both.
- **Out of scope:** any external skill-name surface outside the two carved dirs (task-038); the
  generator render / orphan-prune / manifests (task-039); any conversational behavior change
  (delivery-003/004/005 own that -- internal state names and logic are moved verbatim, not rewritten).

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-describe/` and `canonical/skills/aid-define/` both exist with history
  preserved (via `git mv`); `aid-define/references/` holds exactly the 6 define refs and all other
  `references/*.md` are in `aid-describe/`, matching the task-036 partition. *(gate criterion 1 / AC-1)*
- [ ] `aid-describe/SKILL.md` (`name: aid-describe`) owns FIRST-RUN/Q-AND-A/TRIAGE/CONTINUE/COMPLETION
  + L1-L4 with the stated state-machine line; `aid-define/SKILL.md` (`name: aid-define`) precondition
  `Interview State: Approved` owns FEATURE-DECOMPOSITION/CROSS-REFERENCE/DONE; dispatch agents
  (`aid-interviewer`/`aid-architect`/`aid-reviewer`) preserved unchanged. *(gate criterion 1 / AC-1)*
- [ ] The inter-skill seam works: COMPLETION still PAUSEs (not chains) but its resume signpost +
  pipeline pause/resume writeback target `/aid-define {work}`; aid-define begins from `Interview State:
  Approved` and HALTs with the `/aid-describe` pointer before approval; sibling-state detections print
  hand-off pointers; the lite path completes wholly within aid-describe (LITE-DONE -> /aid-execute).
  *(gate criterion 1 / AC-1)*
- [ ] `grep -rn "aid-interview\b" canonical/skills/aid-describe/ canonical/skills/aid-define/` returns
  ZERO stale command/name self-references; every `aid-interviewer` dispatch token in the two dirs is
  intact (boundary-aware -- not corrupted by the self-ref rewrite). *(gate criteria 1,4 / AC-1,AC-4)*
- [ ] No conversational behavior change -- internal state names and logic are moved verbatim; only
  identity, the partition, the one seam edit, and self-references change. *(scope boundary)*
- [ ] Unit/structural checks: the two SKILL.md frontmatter parse, ASCII-only preserved; all
  REQUIREMENTS.md §6 quality gates that apply pre-render pass (full CI runs at task-040).

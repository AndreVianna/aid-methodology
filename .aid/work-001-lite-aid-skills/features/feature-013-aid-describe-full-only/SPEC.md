# aid-describe Reduced to Full-Path Only

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.6 (FR-12), §9 (AC-14, AC-10), C-3, NFR-7 — added by the 2026-07-07 scope change | /aid-define |

## Source

- REQUIREMENTS.md §5.6 (FR-12)
- REQUIREMENTS.md §9 (AC-14; AC-10 full-only half)
- REQUIREMENTS.md C-3, NFR-7

## Description

Reduce `/aid-describe` to the full-path interview only. Remove its lite path (the
CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW states) and its TRIAGE routing state, and stop
it reading the (now-removed) recipe catalog. Its full-path interview behavior is otherwise
preserved **intact** — the seasoned-analyst elicitation engine, expertise calibration, and the
NFR-7 question envelope are untouched. After this change, running `/aid-describe` goes straight
into the full-path interview: there is no lite branch and no triage prompt; an unsure user is
directed to `/aid-triage` (feature-014).

**Cutover (runs last):** sequenced after the shortcut skill families exist and paired with
features 002/014, so the shortcuts already provide the lite entry before `/aid-describe`'s lite
path is removed — no capability gap during the switch.

## User Stories

- As an AID adopter who knows they want the full path, I want `/aid-describe` to go straight into
  the full-path interview so I am not routed through a triage prompt or a lite branch.
- As an AID maintainer, I want `/aid-describe`'s full-path elicitation engine preserved intact
  when its lite path and triage are removed so interview quality is unchanged.

## Priority

Must (Cutover — sequenced last, after the shortcut families exist)

## Acceptance Criteria

- [ ] Given `/aid-describe`, when it is run, then it goes straight into the full-path interview —
  there is no lite branch and no triage prompt; an unsure user is directed to `/aid-triage`.
  (AC-14; AC-10 — full-only half; FR-12)
- [ ] Given the refactor, when `/aid-describe` is inspected, then its lite path
  (CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW) and TRIAGE state are removed and it no
  longer reads the recipe catalog. (FR-12)
- [ ] Given the refactor, when the full-path interview runs, then its elicitation engine,
  calibration, and NFR-7 question envelope are preserved intact. (C-3)
- [ ] Given `/aid-describe` is a skill deliberately changed under §5.6, when `aid-reviewer`
  reviews it, then it scores >= the resolved `minimum_grade` (A+) before shipping. (AC-7 — subset)

---

## Technical Specification

> Grounded in `research/spec-grounding.md § Q-cutover` (the CONFIRMED-on-disk delete-7 /
> preserve-10 split of `aid-describe`'s reference corpus) and `§ Q-A9` (the hidden
> `aid-monitor` coupling this cutover unblocks). This feature owns the **`aid-describe`
> state-machine rewiring**; the *deletion* of the 7 lite/triage reference files is owned by
> **feature-002** (cross-referenced, not double-owned). Preserving the elicitation engine
> intact is C-3.

### State-machine change (full-path only)

Today `canonical/skills/aid-describe/SKILL.md` frontmatter `State machine:` reads:

```
FIRST-RUN -> Q-AND-A -> TRIAGE -> {full: CONTINUE -> {greenfield: DESCRIBE-SEED ->}
COMPLETION [PAUSE -> /aid-define] | lite: CONDENSED-INTAKE -> TASK-BREAKDOWN ->
LITE-REVIEW -> LITE-DONE}.
```

After this feature it becomes full-path only (no `TRIAGE`, no lite branch):

```
FIRST-RUN -> Q-AND-A -> CONTINUE -> {greenfield: DESCRIBE-SEED ->} COMPLETION
[PAUSE -> /aid-define].
```

The removed states are `TRIAGE`, `CONDENSED-INTAKE`, `TASK-BREAKDOWN`, `LITE-REVIEW`,
`LITE-DONE`, and the user-driven lite→full escalation. The preserved states are `FIRST-RUN`,
`Q-AND-A`, `CONTINUE`, `DESCRIBE-SEED` (greenfield), `COMPLETION`.

### Preserve vs rewire (C-3): engine intact, wiring relocated

C-3 protects the **elicitation-engine mechanism** — the D1 fixed opener, the deterministic
five-step next-move selector, `move-playbook.md`, `calibration.md`, `advisor-stance.md`,
`coherence-check.md`, and the NFR-7 question envelope. Those mechanisms are byte-preserved.
What changes is (i) the **state-transition wiring** that used to route through `TRIAGE`, and
(ii) descriptive **cross-references** to the now-removed in-skill triage consumer.

**The crux — D1 opener relocation.** The engine's single fixed turn ("D1 Fixed Opener — The
Only Fixed Turn", `references/elicitation-engine.md`) is currently *invoked* by
`state-triage.md § Step 1`. `state-continue.md` (entry section) today seeds its adaptive loop
from the TRIAGE-captured opener, with a fallback branch for "NEITHER signal present (legacy
direct-CONTINUE entry, pre-TRIAGE in-flight work)". With `TRIAGE` removed, that fallback
becomes the **primary** entry: the full-path interview emits the D1 opener at the head of
`CONTINUE`, then runs the adaptive loop over the REQUIREMENTS.md gap inventory. The opener
*text and selector logic are unchanged* — only the invocation site moves from `TRIAGE` to
`CONTINUE`. This is the concrete meaning of "engine preserved, states rewired."

### Layers & Components (exact files)

**SKILL.md edits (`canonical/skills/aid-describe/SKILL.md`):**

| Surface (durable anchor) | Edit |
|---|---|
| frontmatter `description:` `State machine:` line | replace with the full-only line above (drop `TRIAGE` + the `lite:` branch) |
| `## Agents Involved` table | remove the `TRIAGE`, `L1 CONDENSED-INTAKE`, `L2 TASK-BREAKDOWN`, `L3 LITE-REVIEW`, `L4 LITE-DONE` rows and the "covers States 1–4, TRIAGE, and L1 / L2 dispatches / L3 dispatches" paragraph; keep `FIRST-RUN`/`Q-AND-A`/`CONTINUE`/`DESCRIBE-SEED`/`COMPLETION` (`aid-interviewer`; `DESCRIBE-SEED` still dispatches `aid-reviewer` for its greenfield gate) |
| `## Workspace` | delete the **Workspace structure (lite path)** block and the "A lite work has no `features/`…" paragraph; keep the full-path workspace |
| `## State Detection` diagram + logic | delete `State T` and `State L1–L4`; delete the `**Path:**` reads, the `escalated` crash-recovery branch (step f), and the pre-TRIAGE backward-compat exception; collapse to `State 1 FIRST-RUN`, `State 2 Q-AND-A`, `State 3 CONTINUE`, `State GS DESCRIBE-SEED`, `State 4 COMPLETION`, `Approved` |
| all "you are here" maps | drop the `TRIAGE` node and the `(lite path)` map lines; the spine becomes `FIRST-RUN -> Q-AND-A -> CONTINUE -> [DESCRIBE-SEED] -> COMPLETION -> /aid-define` |
| `## Dispatch` table | remove the `TRIAGE`, `CONDENSED-INTAKE`, `TASK-BREAKDOWN`, `LITE-REVIEW`, `LITE-DONE` rows and the "User-driven escalate-to-full" paragraph; rewire `FIRST-RUN` **Advance** → `CONTINUE` and `Q-AND-A` **Advance** → `CONTINUE` |
| `## Scripts` section | delete entirely — its only two rows (`parse-recipe.sh`, `test-parse-recipe.sh`) are retired by feature-002; `aid-describe` ships no other script |

**Reference-file rewires (preserve the engine, strip the triage/lite wiring) — exactly 7 files:**

| File | Rewire |
|---|---|
| `references/state-first-run.md` | change `**Advance:** CHAIN -> [State: TRIAGE]` to `CHAIN -> [State: CONTINUE]`; strip the "so TRIAGE can ask the 3 path-determination questions" framing and the `BUG finding -> LITE-BUG-FIX` seed-prefill note; FIRST-RUN now only scaffolds `STATE.md`/`REQUIREMENTS.md` then chains into the full interview |
| `references/state-q-and-a.md` | change the single `**Advance:** CHAIN -> [State: TRIAGE] … or -> [State: CONTINUE]` line to `CHAIN -> [State: CONTINUE]` |
| `references/state-continue.md` | remove the `## Escalation Carry` handling block and the `## Triage` `**Opener:**` dependency; promote the "NEITHER signal present" branch to the primary entry that **emits the D1 opener** (engine relocation above); direct entry is now the only entry |
| `references/state-describe-seed.md` | update the "you are here" map (drop the `TRIAGE` node); repoint the opener de-dup check to read the opener captured at `FIRST-RUN`/`CONTINUE` rather than the removed `## Triage` `**Opener:**` field; leave the `aid-discover` discovery-triage cross-reference (Step 0f — a different skill) intact |
| `references/elicitation-engine.md` | update the descriptive "consumer" seams — the in-skill guided-triage consumer is removed; the engine's external reusability note now points to `/aid-triage` (feature-014) as the standalone consumer of the reflect-back turn. The five-step selector, D1 opener, gap-inventory, and record-sink prose are unchanged |
| `references/move-playbook.md` | update the "guided-triage leans on Move 5 to decide full vs lite" notes — full-vs-lite routing leaves `aid-describe`; Move 5 (Backbone-first + walking-skeleton) remains as the full-path scope-sizing move |
| `references/calibration.md` | update the "guided triage inherits it" example note (calibration is still shared substrate for the full-path interview) |

> Naming caution: the `feature-003`/`feature-004` tokens inside `elicitation-engine.md`,
> `move-playbook.md`, and `calibration.md` refer to **`aid-describe`'s own historical build
> features** (greenfield seed authoring / guided triage), NOT this work's features. The
> "guided triage" they describe *is* the `TRIAGE` state being removed here.

**Untouched (preserve-clean — 6 files, zero triage/lite tokens confirmed by grep):**
`advisor-stance.md`, `coherence-check.md`, `interview-loop.md`, `interview-strategies.md`,
`kb-hydration.md`, `state-completion.md`.

**Deleted by feature-002 (cross-reference, not owned here) — the 7 lite/triage refs:**
`state-triage.md`, `state-condensed-intake.md`, `state-task-breakdown.md`,
`state-lite-review.md`, `state-lite-done.md`, `recipe-to-lite-escalation.md`,
`lite-to-full-escalation.md`.

### Coupling (the cutover triad — must land in one wave)

- **feature-013 ↔ feature-002:** the SKILL.md `## Dispatch`, `## State Detection`, and
  `## Scripts` edits here **remove the pointers** to the 7 reference files (and
  `parse-recipe.sh`) that feature-002 **deletes**. If they do not land together, either the
  SKILL.md points at deleted files (dangling) or the deleted files are orphaned while the
  state machine still routes into them. Same wave, mandatory.
- **feature-013 ↔ feature-014:** feature-014 **extracts** the reflect-back/straw-man turn
  (`state-triage.md § Step 3`) and the workType heuristic (`§ Step 2a`) **before** feature-002
  deletes `state-triage.md`. The routing capability `aid-describe` loses here is preserved,
  relocated to `/aid-triage` (AC-10 routing-relocated half).
- **feature-013 → feature-012:** removing `aid-describe`'s lite bug-fix triage is precisely the
  `§ Q-A9` coupling — it orphans `aid-monitor`'s BUG/CR routing target, which feature-012
  re-points (BUG → `/aid-fix`, CR → `/aid-triage`).

### Testing strategy

- **Full-only assertion (canonical test, AC-14):** `aid-describe/SKILL.md` frontmatter
  `State machine:` line contains no `TRIAGE`/`CONDENSED-INTAKE`/`LITE-` token; the `## Dispatch`
  table contains no row whose Detail path resolves to any of the 7 deleted reference files; a
  scripted read of the state-detection prose confirms `FIRST-RUN`/`Q-AND-A` both advance to
  `CONTINUE`. No lite branch, no triage prompt.
- **Engine-preserved assertion (C-3):** all 13 surviving reference files (6 untouched + 7
  rewired; 20 − 7 deleted) still exist; the D1
  opener text and the five-step selector in `elicitation-engine.md` are unchanged; a fixture run
  of the full-path interview emits the D1 opener at `CONTINUE` and completes `FIRST-RUN -> Q-AND-A
  -> CONTINUE -> [DESCRIBE-SEED] -> COMPLETION` unchanged.
- **No-dangling-reference (shared with feature-002):** grep proves no surviving `aid-describe`
  file references a deleted reference doc, `recipes/`, or `parse-recipe`.
- **Render/regression:** `run_generator.py` re-render clean; `render-drift` + dogfood
  byte-identity green (AC-6); `tests/run-all.sh` green (AC-9); `aid-reviewer` grades the changed
  skill ≥ A+ (AC-7 subset).

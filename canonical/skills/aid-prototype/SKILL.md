---
name: aid-prototype
description: >
  Build a low-fidelity model of a direction. Use when a direction needs a cheap model
  before committing to a full build.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<direction> -- the direction/hypothesis to validate (optionally: fidelity paper|low-fi|runnable-spike)"
---

# Prototype (validate a direction, throwaway)

`/aid-prototype` builds a **throwaway** model **now** to de-risk a direction, captures the
validation signal, presents it, and hands the real build off. It **resolves nothing** and
its output is **not** production. For a design you intend to **keep and build**, use
`/aid-design`. Deeper per-slot guidance: `.aid/runtime/templates/shortcut-scaffolding/prototype.md`.

- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE (-> INTAKE-ASK?) -> ALLOCATE -> BUILD -> VERIFY (light) -> PRESENT [user
decides] -> HANDOFF? -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists).

1. **Check the direction.** Note whether the argument is empty. Do not ask here.
2. **Capture (thin):** direction/hypothesis; fidelity (`paper` | `low-fi` | `runnable
   spike`, default `low-fi`); the success signal that would validate it; the scope
   boundary (what it does NOT attempt -- keeps it throwaway).
3. **Pick the path:** **Fast** -- a clear direction + success signal -> build now.
   **Guided** -- vague ("prototype something for onboarding") -> scope direction / success
   signal / fidelity first, in INTAKE-ASK.
4. **Classify complexity (model + effort):** simple -> `aid-architect` at **sonnet /
   medium**; complex (a runnable spike, a rich flow) -> **opus / high**.
5. **Check for works.** Run `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Note whether any exist. Do not prompt here.

**Advance:** CHAIN -> [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works exist; otherwise CHAIN -> [State: ALLOCATE].

---

## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:

1. **Empty argument** -> the bootstrapping question ("What direction do you want to validate, and
   what would tell you it works?"). The answer is the direction; the path and complexity are then
   set from it.
2. **Guided path** -> scope the direction, the success signal and the fidelity.
3. **Works exist** -> the gate's new-vs-continuation question with the enumerated list.

**Advance:** ASK -> [State: ALLOCATE].

---

## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).

- **New work:** call the gate's `§ 3a` with the user's words, this skill's name
  (`aid-prototype`), its saved step (`BUILD`), the step the work continues at once it exists (INTAKE and INTAKE-ASK run before the record and save nothing), `--path lite`, and a kebab-case slug from the
  direction. The gate's `§ 3a` step 2 creates and enters the worktree
  (`worktree-lifecycle.sh create <work-id> <name>`),
  **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
  the writer, before it hands back: "`STATE.yml` was created by the gate;
  skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
  set other keys through the writer." This skill drives no `phase`. For a **runnable spike**,
  associate an opt-in git worktree so the throwaway code is isolated. When `/aid-orchestrate`
  passed an `intent:` block, the gate's `--create` has already written its `reading` and `depth`; set its `reason` and `phases` through the writer (`writeback-state.sh --intent --reason '<reason>' --phases <P1,P2,...>`, as `.aid/runtime/templates/shortcut-engine.md` Step 5 says), unless `--create` already carried them; a typed `/aid-prototype` writes none.
- **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.

Every `--step` call in this skill passes in its `--detail` the direction, the fidelity, the success signal, the scope
boundary and the complexity tier, so a resume finds them in the record.

**Advance:** CHAIN -> [State: BUILD].

---

## State: BUILD

Dispatch **`aid-architect`** (clean context, tiered) to build the low-fidelity model of
the direction and capture the validation signal. A "runnable spike" is **throwaway code
written by this same `aid-architect` dispatch** -- deliberately NOT `aid-developer` (whose
job is production code), keeping the throwaway/non-production boundary crisp. All artifacts
stay in the work folder / opt-in worktree and **never touch production modules**. It writes
a validation assessment (see [Deliverable](#deliverable)) into the work folder.

**Advance:** CHAIN -> [State: VERIFY].

---

## State: VERIFY  (LIGHT -- do not polish-grade a rough model)

A prototype is *deliberately* low-fidelity, so this is a single light clean-context check
(not the full adversarial loop the other collapses run): dispatch **`aid-reviewer`** once to
confirm (a) the **"success signal observed" claim is honest and grounded** in what was
actually built, and (b) the **throwaway scope was respected** -- no production code snuck in,
nothing was committed to real modules. If the check fails, return to BUILD once to correct;
do not loop on polish.

**Advance:** CHAIN -> [State: BUILD] when the check fails the first time; otherwise CHAIN -> [State: PRESENT].

---

## State: PRESENT  (hard stop -- the user decides)

The hard stop follows the ASK step of `skill-steps.md`. Present the throwaway model + the validation
assessment: **Direction · What was built (fidelity) · Success signal — observed or not ·
What we learned · viable? (a conclusion, not a resolution).** Assert no resolution.

**Advance:** ASK -> [State: HANDOFF].

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions the user may act on: build the validated thing for real
(`/aid-create*`, or `/aid-design` first if a kept design is wanted), or test it with users
(`/aid-experiment` / `/aid-test`). Never auto-invoked; never a resolution. Ask which one, if
any, the user takes; a picked one is named in one plain line.

**Advance:** ASK -> [State: DONE].

---

## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Keep the throwaway artifacts + assessment in the work folder as the audit record; nothing is promoted to production.

**Advance:** HALT.

---

## Deliverable

A validation assessment in the work folder: *Direction · What was built (fidelity) ·
Success signal (observed / not) · What we learned · Viable? (conclusion, not resolution)*,
alongside the throwaway model/spike artifacts.

---

## Constraints

- **Throwaway + isolated** -- artifacts never touch production; a runnable spike is written
  by `aid-architect` (not `aid-developer`), in the work folder / opt-in worktree.
- **Resolves nothing** -- presents a viability conclusion; the user decides.
- **LIGHT verify** -- honesty + throwaway-scope check on the assessment, not a polish-grade.
- **Verification is always a sub-agent dispatch** (`aid-reviewer`), never inline.
- **Kept design is `/aid-design`, not this.**
- **Tracking:** every record change goes through the writer (`skill-steps.md`, § The work record).

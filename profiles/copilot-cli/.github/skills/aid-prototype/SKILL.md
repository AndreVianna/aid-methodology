---
name: aid-prototype
description: >
  Build a THROWAWAY low-fidelity model NOW to validate a direction before
  committing to a full build -- then present what it shows and hand the real
  build off to /aid-create*. It RESOLVES NOTHING (states whether the direction
  holds + what was learned; you decide). Isolated and throwaway: artifacts live
  in the work folder / an opt-in worktree and never touch production. Produced by
  the aid-architect agent; the validation assessment gets a LIGHT verify (the
  model is deliberately rough -- it is not polish-graded). For a KEPT design
  meant to inform the build, use /aid-design instead. Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, shell, Write, Edit, Agent
argument-hint: "<direction> -- the direction/hypothesis to validate (optionally: fidelity paper|low-fi|runnable-spike)"
---

# Prototype (validate a direction, throwaway)

`/aid-prototype` builds a **throwaway** model **now** to de-risk a direction, captures the
validation signal, presents it, and hands the real build off. It **resolves nothing** and
its output is **not** production. For a design you intend to **keep and build**, use
`/aid-design`. Deeper per-slot guidance: `.github/aid/templates/shortcut-scaffolding/prototype.md`.

- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Behavior contract:** `.aid/work-005-lite-skills-refactor/specs/aid-prototype-design.md`.

State machine: **INTAKE -> BUILD -> VERIFY (light) -> PRESENT [user decides] -> HANDOFF? ->
DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a direction.** Empty argument -> ask one bootstrapping question ("What
   direction do you want to validate, and what would tell you it works?") and wait.
2. **Capture (thin):** direction/hypothesis; fidelity (`paper` | `low-fi` | `runnable
   spike`, default `low-fi`); the success signal that would validate it; the scope
   boundary (what it does NOT attempt -- keeps it throwaway).
3. **Pick the path:** **Fast** -- a clear direction + success signal -> build now.
   **Guided** -- vague ("prototype something for onboarding") -> scope direction / success
   signal / fidelity first.
4. **Classify complexity (model + effort):** simple -> `aid-architect` at **sonnet /
   medium**; complex (a runnable spike, a rich flow) -> **opus / high**.
5. **Allocate the work folder + STATE** (`pipeline.path: lite`, `initiator: aid-prototype`,
   `lifecycle: Running`, `active_skill: aid-prototype`; `phase` not driven). For a
   **runnable spike**, associate an opt-in git worktree so the throwaway code is isolated.

**Advance:** BUILD.

---

## State: BUILD

Dispatch **`aid-architect`** (clean context, tiered) to build the low-fidelity model of
the direction and capture the validation signal. A "runnable spike" is **throwaway code
written by this same `aid-architect` dispatch** -- deliberately NOT `aid-developer` (whose
job is production code), keeping the throwaway/non-production boundary crisp. All artifacts
stay in the work folder / opt-in worktree and **never touch production modules**. It writes
a validation assessment (see [Deliverable](#deliverable)) into the work folder.

**Advance:** VERIFY.

---

## State: VERIFY  (LIGHT -- do not polish-grade a rough model)

A prototype is *deliberately* low-fidelity, so this is a single light clean-context check
(not the full adversarial loop the other collapses run): dispatch **`aid-reviewer`** once to
confirm (a) the **"success signal observed" claim is honest and grounded** in what was
actually built, and (b) the **throwaway scope was respected** -- no production code snuck in,
nothing was committed to real modules. If the check fails, return to BUILD once to correct;
do not loop on polish.

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the throwaway model + the validation
assessment: **Direction · What was built (fidelity) · Success signal — observed or not ·
What we learned · viable? (a conclusion, not a resolution).** Assert no resolution.

**Advance:** HANDOFF (optional) then DONE.

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions the user may act on: build the validated thing for real
(`/aid-create*`, or `/aid-design` first if a kept design is wanted), or test it with users
(`/aid-experiment` / `/aid-test`). Never auto-invoked; never a resolution.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep the
throwaway artifacts + assessment in the work folder as the audit record; nothing is promoted
to production.

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
- **Tracking:** write STATE `lifecycle` at every transition.

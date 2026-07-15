# Behavioral Spec — `aid-prototype` (collapse) + new `aid-design` (task-006)

> **Status:** LOCKED for implementation (design agreed 2026-07-15).
> **Tracked under:** `.aid/work-005-lite-skills-refactor/` (branch `work-005-lite-skills-refactor`).
> **Scope:** `aid-prototype` (collapse, generic); `aid-prototype-ui` → backward-compat
> hint-alias; **new `aid-design`** skill (fills the DESIGN gap). Shares the collapse
> pattern ([`aid-review`](aid-review.md)); records the deltas.
> **Not implemented yet.**

---

## 1. Problem

- **`aid-prototype` / `aid-prototype-ui`:** generated doorways → engine → plan a DESIGN
  work and halt. No prototype is ever built.
- **`aid-prototype-ui` is over-narrow** — "prototype, but only for UI" is the enumeration
  trap we removed elsewhere; a UI is just one thing you might prototype.
- **No `aid-design` exists** — there's a DESIGN task type (executed by `aid-architect` in
  the full pipeline) but **no lite entry point to just design something**. A real gap.

## 2. The split (the key distinction)

`aid-prototype-ui` conflated two genuinely different intents. Separate them:

| Intent | Skill | Output longevity | Verify |
|---|---|---|---|
| **Validate a direction, then discard** | `aid-prototype` (generic) | throwaway | **light** |
| **Produce a design meant to be kept & built** | **`aid-design`** (new, generic) | kept, informs the build | **standard (full)** |

Pin it: **`prototype` = throwaway, to *validate*; `design` = kept, to *inform the build*.**
- *"Does a card layout work for our data density?"* → `aid-prototype`.
- *"Design the checkout flow / this component's interface."* → `aid-design`.

Both are **collapse** (produce the artifact now; A✗ B✗), both produced by **`aid-architect`**
(DESIGN), both **resolve nothing** and hand off the real build to `/aid-create*`.

## 3. `aid-prototype` (collapse, generic)

- **Generic** — drops the UI-specific variant; a UI is just one prototype target it
  handles by intelligence. **`aid-prototype-ui` becomes a backward-compat hint-alias** of
  `aid-prototype` (binds a `ui` target hint), same treatment as the `test-*`/`document*`
  hint-aliases. *(Hard-remove instead only if a lean catalog is preferred — default is
  keep-as-alias for backward-compat.)*
- **Producer = `aid-architect`.** A "runnable spike" is throwaway code written by that
  same `aid-architect` dispatch — deliberately **not** `aid-developer` (whose job is
  *production* code), keeping the throwaway/non-production boundary crisp.
- **Throwaway + isolated:** artifacts live in the work folder / opt-in worktree and never
  touch production (the scaffolding's ownership boundary already enforces this). Fidelity
  levels `paper` / `low-fi` / `runnable spike` retained.
- **LIGHT verify (locked):** one clean-context check on the **validation assessment** — is
  the "success signal observed" claim honest and grounded, and was the throwaway scope
  respected (no production code snuck in)? **Not** an adversarial polish-grade of a
  deliberately-rough artifact (that fights the speed a prototype exists for).
- **Deliverable:** the throwaway model + a validation assessment — *Direction · What was
  built (fidelity) · Success signal (observed or not) · What we learned · viable? (a
  conclusion, not a resolution)*.
- **Handoff (printed suggestion):** `/aid-create*` to build the validated thing;
  `/aid-experiment` or `/aid-test` to user-test it.

## 4. `aid-design` (NEW, collapse, generic)

- **New skill** — `verb: design`, bare (`artifact: ""`), `default_type: DESIGN`, group G3.
  Generic: design anything (UI/UX, interaction flow, component/interface, architecture
  sketch, a11y). Optional hint-aliases later, but generic by default (defer to
  intelligence — the recurring principle; no per-target enumeration).
- **Producer = `aid-architect`** (design thinking, UX/flow advice).
- **Kept deliverable:** the design is a real artifact meant to inform a build, not thrown
  away. Lives in the work folder (the design's record); present-before-place if it goes to
  a durable design/docs location.
- **Grounded** in the KB (existing patterns, conventions, `architecture.md`) + the request.
- **Standard (full) VERIFY** — because a kept design's correctness matters (it drives a
  build): clean-context `aid-reviewer` checks grounding, completeness, consistency with KB
  conventions and a11y; one deliverable grade gates (bounded loop). *(This is the deliberate
  difference from `aid-prototype`'s light verify.)*
- **Deliverable:** the design artifact (flow/wireframe/component or interface design + a11y
  notes), presented clearly; **resolves nothing** — hand off the build to `/aid-create*`.
- **Boundary vs `aid-document`:** `aid-design` *produces the design* (`aid-architect`,
  DESIGN); `aid-document` *writes documentation about* something (`aid-tech-writer`,
  DOCUMENT). A design needing a formal written spec → `aid-design` produces the design,
  then a printed handoff to `/aid-create-document` if a doc is wanted.

## 5. Shared (collapse skeleton)

Single-shot; hand-authored + `repurpose: true`; work-folder + normal STATE; resolves
nothing; present-before-place gate (light); printed-suggestion handoffs; per-call tiering
(simple → sonnet, complex → opus; verifier tier ≥ producer). Dispatch ~5 Opus → ~2 tiered.

## 6. Files the implementation will touch

1. `shortcut-catalog.yml` — `repurpose: true` on `aid-prototype`; convert
   `aid-prototype-ui` to a hint-alias row; **add `aid-design`** (new canonical row).
2. `canonical/skills/` — hand-authored shared prototype body + `aid-prototype` doorway +
   `aid-prototype-ui` thin hint-alias; **new hand-authored `aid-design` skill**.
3. `shortcut-engine.md` — detach the `prototype` rows; note `aid-design` is
   hand-authored (not engine-driven).
4. `prototype.md` scaffolding — retained as prototype guidance; author `aid-design`'s own
   guidance (reuse the DESIGN `task-type-rules` shape).
5. Regenerate: `build-shortcut-skills.py` → `run_generator.py` → dogfood resync.

## 7. Settled decisions

Resolved with the user 2026-07-15:

1. **Split** `aid-prototype-ui` into `aid-prototype` (throwaway) + new `aid-design` (kept).
2. **`aid-prototype` generic**, `aid-prototype-ui` → backward-compat hint-alias.
3. **`aid-design` is new** (fills the DESIGN lite gap); generic; standard/full verify.
4. **`aid-prototype` uses LIGHT verify** (throwaway); `aid-design` uses **full verify**
   (kept deliverable). The verify depth follows output longevity.
5. Both collapse; producer `aid-architect`; resolve nothing; hand off the build to
   `/aid-create*`.

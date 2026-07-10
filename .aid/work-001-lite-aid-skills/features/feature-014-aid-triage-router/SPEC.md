# aid-triage Router

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.6 (FR-13), §9 (AC-13, AC-10), §3 (unsure users), A-5, D-2 — added by the 2026-07-07 scope change | /aid-define |

## Source

- REQUIREMENTS.md §5.6 (FR-13)
- REQUIREMENTS.md §9 (AC-13; AC-10 routing-relocated half)
- REQUIREMENTS.md §3 (unsure users), A-5, D-2

## Description

A new `/aid-triage` skill for the "I don't know which path or skill fits" case. It captures a
short free-form description and **suggests** the right entry — the full path via `/aid-describe`
for broad or ambiguous work, or the specific matching `aid-<verb>[-<artifact>]` shortcut for a
known change-type. It is largely the **extraction** of `/aid-describe`'s former TRIAGE logic into
a standalone skill, so the routing capability `/aid-describe` used to provide is preserved,
relocated here. It routes and suggests only — it does not run the interview or scaffold any work.

**Cutover (runs last):** sequenced after the shortcut families exist and together with
feature-013, so that when `/aid-describe`'s triage is removed the routing capability already lives
in `/aid-triage` — no routing hole.

## User Stories

- As an unsure AID user, I want to run `/aid-triage` with a short description and be told whether
  to use the full path (`/aid-describe`) or a specific shortcut, so I am routed rather than
  stranded.
- As an AID maintainer, I want the triage routing `/aid-describe` used to perform relocated into
  `/aid-triage` so the capability is preserved when `/aid-describe` becomes full-only.

## Priority

Must (Cutover — sequenced last, after the shortcut families exist)

## Acceptance Criteria

- [ ] Given a free-form description, when `/aid-triage` runs, then it suggests the correct entry —
  the full path via `/aid-describe` for broad/ambiguous work, or the specific matching shortcut
  for a known change-type. (AC-13; FR-13)
- [ ] Given `/aid-triage`, when it runs, then it routes/suggests only — it does not run the
  interview or scaffold work. (FR-13)
- [ ] Given `/aid-describe` is reduced to full-only, when `/aid-triage` exists, then the full/lite
  routing capability `/aid-describe` used to provide is preserved, relocated to `/aid-triage`.
  (AC-10 — routing preserved/relocated half)
- [ ] Given `/aid-triage` is a new skill, when `aid-reviewer` reviews it, then it scores >= the
  resolved `minimum_grade` (A+) before shipping. (AC-7 — subset)

---

## Technical Specification

> Grounded in `research/spec-grounding.md § Q-cutover` ("TRIAGE→aid-triage extraction reality":
> the reflect-back turn is reusable; the recipe-match half is *replaced* by a shortcut-catalog
> match) and A-5. This is a genuine **extraction-plus-rewrite**, not a pure copy: the recipe
> lookup has no target once recipes are gone. `/aid-triage` **suggests only** — no interview, no
> scaffolding, no work folder (FR-13).

### New skill: `canonical/skills/aid-triage/`

A standalone router skill (like `aid-describe`, it is **not** one of the 45 shortcut skills and
carries **no** `shortcut-catalog.yml` row — it *reads* the catalog, it is not *in* it).

```
canonical/skills/aid-triage/
  SKILL.md                       # frontmatter + INTAKE/HALT inline
  references/state-classify.md   # workType heuristic + catalog-shortcut match
  references/state-suggest.md    # the reflect-back straw-man turn + [1]/[2]/[3] menu
```

Frontmatter: `name: aid-triage` (== dir == `/aid-triage` command, per `render.py`
`skill_slug = skill_dir.name`); `description:` carrying `State machine: INTAKE -> CLASSIFY ->
SUGGEST -> HALT`; `allowed-tools: Read, Glob, Grep` (**no `Write`/`Edit`** — routes only, writes
nothing); `argument-hint: "[description]  -- what you want to do; I'll point you at the right entry"`.

### Feature Flow (state machine — INTAKE -> CLASSIFY -> SUGGEST -> HALT)

| State | Does | Extracted from |
|---|---|---|
| **INTAKE** (inline) | Capture one short free-form description (single turn). No adaptive loop, no scaffold. | `state-triage.md § Step 1` D1-style opener, trimmed to one capture turn |
| **CLASSIFY** (`references/state-classify.md`) | Infer `workType` (`bug-fix` / `new-feature` / `refactor`) via the extracted heuristic **and** judge scope: *broad/multi-activity/ambiguous* → recommend the full path; *known single change-type* → match the best shortcut in `shortcut-catalog.yml` by `{verb, artifact}` + `intent`. | `state-triage.md § Step 2a` (workType heuristic) + `§ Step 2b` **rewritten**: catalog-`intent` semantic match replaces recipe-`summary` match |
| **SUGGEST** (`references/state-suggest.md`) | Emit the NFR-7 reflect-back straw-man with the single best-match + full-path fallback: `Looks like a {type} — best entry: /aid-<verb>[-<artifact>] ({intent}).  [1] proceed  [2] a different shortcut  [3] full path via /aid-describe`. Confidence "several plausible" → present a short ranked list; "broad/ambiguous" → recommend `[3]`. | `state-triage.md § Step 3` reflect-back turn (the proven UX shape) |
| **HALT** (inline) | Print the recommended invocation the user should type next; **STOP**. No routing action is taken *for* the user (it suggests; the user invokes). No STATE.md, no work folder. | — (`state-triage.md § Step 5a`/`§ Step 6` slot-fill + STATE writes are **dropped** — no artifacts) |

### Data Model — catalog read (feature-003 dependency)

`/aid-triage` reads `<install-root>/aid/templates/shortcut-catalog.yml` (feature-003's
single-source manifest, rendered verbatim to all five profiles). It matches
`{description} -> {verb, artifact}` and suggests the **canonical** `name` (never an `alias_of`
form). No recipe scan (`canonical/aid/recipes/` is deleted by feature-002); the catalog's
`intent` string is the semantic-match target that the recipe `summary:` used to be. Broad or
ambiguous descriptions resolve to `/aid-describe` (full path), preserving the conservative
"anything short of one confident match routes to full" rule from `state-triage.md § Step 4`.

### Agent dispatch

The reflect-back turn runs via `aid-interviewer` (the `TRIAGE` precedent) or inline — it is a
single conversational turn. Because `/aid-triage` **produces no graded artifact** (it writes
nothing), there is **no runtime `aid-reviewer` gate** (unlike the old `LITE-REVIEW`); FR-11's
per-document grading does not apply. The skill itself is graded at build time by `aid-reviewer`
≥ A+ (AC-7). This keeps the skill deliberately thin (NFR-8; no over-engineering).

### Layers & Components (canonical files + render)

| File | Change | Renders to |
|---|---|---|
| `canonical/skills/aid-triage/SKILL.md` | **new** — frontmatter + State Detection + Dispatch table + INTAKE/HALT inline | `<root>/skills/aid-triage/SKILL.md`, all 5 profiles |
| `canonical/skills/aid-triage/references/state-classify.md` | **new** — workType heuristic + catalog-shortcut match (extracted + rewritten from `state-triage.md`) | verbatim, 5 profiles |
| `canonical/skills/aid-triage/references/state-suggest.md` | **new** — reflect-back turn + `[1]/[2]/[3]` menu | verbatim, 5 profiles |
| `canonical/aid/templates/shortcut-catalog.yml` | **read-only consumer** (owned by feature-003) | — |

### Coupling

- **feature-014 ↔ feature-002 (extract-before-delete):** the reflect-back turn and workType
  heuristic are lifted from `state-triage.md` **before** feature-002 deletes it. Same wave.
- **feature-014 ↔ feature-013:** feature-013 removes the in-skill triage from `aid-describe`;
  this feature provides the relocated routing so AC-10's "routing preserved, relocated to
  `/aid-triage`" holds — no routing hole during the switch.
- **feature-014 → feature-012:** `aid-monitor`'s re-pointed Change-Request route targets
  `/aid-triage` (feature-012 § A-9 re-point), so `/aid-triage` must exist before that re-point.
- **feature-014 ↔ feature-003:** depends on `shortcut-catalog.yml` existing (feature-003).

### Testing strategy

- **Routing mapping (canonical test, AC-13):** a fixture table of representative descriptions
  resolves to the right target — `"fix the login crash"` → `/aid-fix`; `"add a /orders REST
  endpoint"` → `/aid-create-api`; `"rename OrderSvc everywhere"` → `/aid-refactor`; `"write an
  ADR for the DB choice"` → `/aid-document-decision`; `"rewrite the billing subsystem across 4
  services"` → `/aid-describe` (broad); genuinely ambiguous → `/aid-describe`. (Mirrors
  `state-triage.md`'s unit-testable mapping table, retargeted from recipes to catalog names.)
- **Routes-only proof (FR-13):** after a `/aid-triage` run, no `.aid/work-*/` folder and no
  `STATE.md` are created; `allowed-tools` excludes `Write`/`Edit`.
- **Catalog resolution:** every suggested `name` exists as a canonical (non-alias) row in
  `shortcut-catalog.yml`.
- **Render/grade:** `run_generator.py` renders `/aid-triage` to all 5 profiles; `render-drift` +
  dogfood byte-identity green (AC-6); `aid-reviewer` grades the new skill ≥ A+ (AC-7 subset).

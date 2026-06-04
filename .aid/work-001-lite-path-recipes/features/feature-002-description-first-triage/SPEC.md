# Description-First TRIAGE

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-03 | Feature identified from REQUIREMENTS.md §§4,5,6,7,9 | /aid-interview |

## Source

- REQUIREMENTS.md §4 Scope, §5 Functional Requirements, §6 Non-Functional Requirements,
  §7 Constraints, §9 Acceptance Criteria (AC2)
- design-notes.md (TRIAGE Option 2 decision)

## Description

Rewrite the lite-path TRIAGE flow so it **leads with a free-form work description** instead of
a fixed type menu. The agent infers `{work-type + best-matching recipe}` from the description
(using each recipe's `summary:`) and the user confirms in a single turn. A confident single
recipe match routes the work to the **lite** path; an ambiguous, multi-target, or no-match
description routes to **full**. The old T1/T2/T3 menu collapses into this prose rule. Work-type
labels stay internal — the user never picks `refactor`/`new-feature`/`bug-fix` from a menu.

Per the `prose-over-scripts` principle, classification is **agent inference in SKILL.md prose —
no new parsing script**.

## User Stories

- As an **AID adopter**, I want to describe my work in my own words and have the system pick the
  right path and recipe, so that I don't have to learn AID's internal taxonomy.
- As an **AID adopter**, I want to confirm or correct the agent's guess in one turn, so triage
  stays fast.

## Priority

Must

## Acceptance Criteria

- [ ] (AC2) TRIAGE runs description-first: the agent infers `type + recipe` from a free-form
  description, the user confirms, and routing follows — a confident single-recipe match routes
  lite; ambiguous / multi-target / no-match routes full.
- [ ] Classification resolves in **one confirmation turn** for common descriptions (§6 NFR).
- [ ] **No new script** is introduced; classification is SKILL.md prose only (§7 constraint).
- [ ] (AC6, KB — TRIAGE scope) KB updated to describe the description-first TRIAGE flow where it
  documents triage/sub-path behaviour (`domain-glossary.md` § Lite Path / Sub-Paths, and any
  TRIAGE references) — replacing the old T1/T2/T3 menu description.
- [ ] Canonical change re-rendered to all 5 install trees via `/aid-generate` (byte-identical).

---

## Technical Specification

> This is a documentation/markdown change to the `aid-interview` state machine
> (`canonical/`, AID editing itself) plus the work-state template and KB — **not** an
> application feature. The sections below are adapted accordingly: no Data Model / API
> layers, but **Overview**, **New TRIAGE flow**, **Internal-only work-types**, **LITE-DOC
> elimination**, **Scope & Files to Change**, **No-new-script confirmation**, **Edge cases**,
> **AC mapping**, **Render & Verification**, and **Risks / sequencing**. Every claim is
> grounded against the files on disk as of this writing; line numbers will drift as edits
> land, so each row also names a grep-recoverable anchor. This feature is the **CONSUMER**
> in the work-001 three-way partition (feature-001 = enum DEFINITION; feature-002 = this,
> the TRIAGE/interview CONSUMER; feature-003 = recipe-file INSTANCES) — see
> `feature-001-taxonomy-and-recipe-schema/SPEC.md § Ownership boundary` (lines 282–308).

### Overview

The lite-path TRIAGE flow is rewritten to be **description-first**. Instead of the three
fixed closed-choice menus (T1 breadth, T2 size, T3 type — `state-triage.md:17–60`), TRIAGE
now opens with a single free-form prompt: "Describe the work you want to do." The agent then
**infers** two things in prose (no script): (a) the internal work-type
∈ `{bug-fix, new-feature, refactor}`, and (b) the **single best-matching recipe**, selected
by scanning each recipe's `summary:` front-matter field (added by feature-001 —
`feature-001 SPEC § \`summary:\` Schema Addition`, lines 200–217) within the work-type-matching
`applies-to` set. The agent presents one **confirmation turn** — "Looks like a {type} — recipe
`{name}` ({summary}). Correct?" — and the user accepts or corrects. The **routing rule** is:
a **confident single-recipe match** → **lite path** with that recipe (proceed straight into the
existing slot-fill + emit); an **ambiguous, multi-target, or no-match** description → **full
path**. Work-type labels stay **internal** — the user never picks `refactor`/`new-feature`/
`bug-fix` from a menu; the label only surfaces in the internal `STATE.md ## Triage` write.
The `single-doc` work-type and its `LITE-DOC` sub-path are eliminated: documentation/report
work is classified as `new-feature` (add-docs/add-report) or `refactor` (change-docs/
change-report) and routed under `LITE-FEATURE` / `LITE-REFACTOR` (recipe files owned by
feature-003).

### New TRIAGE flow (step-by-step prose) — what replaces T1/T2/T3 in `state-triage.md`

feature-002 owns **all** of `canonical/skills/aid-interview/references/state-triage.md` and
rewrites it wholesale. The disposition of each existing section, by anchor:

**DELETED (the menu + deterministic sizing rule):**

- **Step 1 — Ask T1 — Breadth** (`state-triage.md:17–30`) — deleted.
- **Step 2 — Ask T2 — Size** (`:34–44`) — deleted.
- **Step 3 — Ask T3 — Type** (`:48–60`) — deleted.
- **Step 4 — deterministic routing rule + T3→workType + workType→Sub-path tables**
  (`:64–94`) — the T3→workType table and the deterministic `T1∈{…} ∧ T2 ∧ T3∈{…}` rule are
  deleted. The **workType→Sub-path mapping table** (`:87–94`) is **rewritten** (see § LITE-DOC
  elimination — the `single-doc | LITE-DOC` row is dropped).
- **The "Unit-testable mapping rules (summary)" T1/T2/T3 routing table** (`:454–467`),
  the **override-paths table** (`:469–480`), and the **recipe-offer/slot-fill/escalation
  tables** (`:482–517`) — the T1/T2/T3-keyed rows are **deleted/rewritten** to be keyed on
  `{description → inferred type + matched recipe}` instead. The `single-doc` / `LITE-DOC` rows
  (`:462, 476, 479, 494`) are removed.

**REPLACED (new description-first steps 1–4):**

- **New Step 1 — Free-form description prompt.** Ask the user, ONE turn:
  ```
  Describe the work you want to do, in your own words.
  (e.g., "fix the login crash on special characters", "add a /orders API endpoint",
   "rename the OrderSvc class everywhere", "write an ADR for the DB choice")
  ```
  Wait for the user's free-form answer. Record it internally as `{description}`.

- **New Step 2 — Classify (agent inference, prose).** From `{description}` the agent infers:
  1. **Internal work-type** ∈ `{bug-fix, new-feature, refactor}`, using the same intent
     heuristics design-notes locks (`design-notes.md:13–21`): broken/observed-wrong behaviour
     → `bug-fix`; net-new capability or net-new artifact (incl. new docs/reports) →
     `new-feature`; change/rename/improve an existing working artifact (incl. editing existing
     docs) → `refactor`.
  2. **Best-matching recipe.** Scan `canonical/recipes/*.md`, reading each recipe's `summary:`
     and `applies-to:` front-matter (reuse the discovery + graceful-skip rule already written
     for the old Step 5a-1, `state-triage.md:168–183`: skip files whose front-matter cannot be
     parsed, e.g. `README.md`). Candidate set = recipes whose `applies-to == {inferred-type}`
     **OR** `applies-to == '*'` (the current wildcard recipe is `add-unit-test`, renamed to
     `add-test-coverage` by feature-003). Within the candidate set,
     pick the recipe whose `summary:` text best matches `{description}` (semantic match on the
     summary string — this is the agent inference the `summary:` field was added for, per
     `feature-001 SPEC:202–204`). Produce: best recipe + a confidence judgment (single clear
     winner vs. several plausible vs. none).

- **New Step 3 — Single confirmation turn.** Present the inference and wait for the user on the
  **same turn** (this is the one-turn NFR, §6 / AC "one confirmation turn"):
  ```
  Looks like a {inferred-type} — recipe `{recipe-name}` ({summary}).

  [1] Yes — proceed (lite path, recipe `{recipe-name}`)
  [2] No — it's a different kind of work (I'll route to the full path)
  [3] Different recipe: {list other plausible candidates, if any}
  ```
  - `[1]` → **confident single match accepted** → route **lite** with `{recipe-name}`.
  - `[2]` → user rejects the inferred type → route **full** (treat as no-confident-match;
    record the description as the full-path seed).
  - `[3]` → user picks a different listed candidate → route **lite** with the chosen recipe.

- **New Step 4 — Routing decision.** Deterministic from Step 2's confidence + Step 3's answer:
  | Step 2 confidence | Step 3 answer | Route |
  |---|---|---|
  | Single clear recipe winner | `[1]` accept | **lite**, recipe = winner |
  | Single clear recipe winner | `[3]` pick another candidate | **lite**, recipe = chosen |
  | Several plausible recipes (ambiguous) | `[3]` pick one | **lite**, recipe = chosen |
  | Several plausible recipes | user can't pick / declines | **full** |
  | No candidate matches (empty set) | (auto) | **full** |
  | Any | `[2]` reject type | **full** |

  The rule is intentionally conservative — same spirit as the old Step 4 (`:71–72`): any
  signal short of one confident, user-confirmed single recipe routes to **full**.

**MERGE with old Step 5 (override) and Step 5a (recipe-offer + slot-fill):**

- **Old Step 5 (Expose decision + offer override; 3-choice menu, `state-triage.md:98–156`) —
  COLLAPSED into the new Step 3.** The new single confirmation turn **is** the decision/override
  exposure. There is no separate "choose a different sub-path [a]/[b]/[c]/[d]" menu — sub-path
  is now a derived consequence of `{inferred-type}` (workType→Sub-path table), not a user pick.
  The old `[3] Escalate to full` choice survives **as** new Step 3 `[2]` (reject → full) and as
  the explicit escalation hooks (see Edge cases). The full-verdict "proceed directly, no override"
  branch (`:152–156`) is preserved: a full route advances straight to Step 6/STATE-write then
  CONTINUE.
- **Old Step 5a (recipe-offer, `:160–351`) — the *menu-and-pick* front half is REPLACED; the
  *slot-fill + emit* back half is KEPT verbatim.** Specifically:
  - **5a-1 Discover matching recipes** (`:168–183`) — **kept** (now invoked inside new Step 2 to
    build the candidate set; same graceful-skip rule).
  - **5a-2 Present recipe list + `[0] Decline`** (`:184–206`) — **deleted.** The
    description-first match (new Steps 2–3) replaces the catalog-listing menu offer. There is no
    longer a "pick a number from N recipes" list as the primary path; the agent has already
    proposed the single best recipe. (The "decline → standard condensed interview" affordance is
    subsumed: rejecting the recipe means rejecting the lite/recipe match, which routes full per
    new Step 4.)
  - **5a-3a Slot-fill loop** (`:208–283`), **5a-3b decline/abort** (`:284–292`), **5a-4 write
    slots JSON + emit + update STATE.md + CHAIN to LITE-DONE** (`:294–351`) — **kept verbatim**.
    Once a recipe is confirmed (new Step 3 `[1]`/`[3]`), control enters the existing 5a-3a
    slot-fill loop unchanged. `parse-recipe.sh --list` / `--render` are still the slot-fill +
    emit engine (see § No-new-script confirmation). Recipe-to-lite escalation triggers (A/B,
    `:243–250`, `:277–282`) are retained.
- **Step 6 (Write STATE.md `## Triage`, `:354–442`) — KEPT, rationale strings rewritten.** The
  block shapes (Path / Work Type / Sub-path / Recipe / Decision rationale) are unchanged; only
  the `Decision rationale` text changes from `T1={…} + T2={…} + T3={…} → …` to a description-
  based string, e.g. `description → inferred {type}; recipe {name} matched → lite/{Sub-path}`
  (full route: `description → no confident recipe match → full`). The `single-doc`/`LITE-DOC`
  examples in this section are removed. The `Sub-path (auto)` / `Override` field machinery is
  retained for completeness but, with the sub-path menu gone, `Override: yes` now only arises
  when the user picks a `[3]` candidate whose recipe implies a different sub-path than the
  first-inferred one (otherwise the auto sub-path stands; no Override field written).
- **Step 7 (Advance, `:446–451`) — KEPT.** Same three exits: full → CONTINUE; lite+recipe →
  LITE-DONE; lite+no-recipe → CONDENSED-INTAKE. (Lite-without-recipe now only occurs via the
  edge cases below, e.g. a confirmed type whose candidate set is empty but the user still wants
  lite — see Edge cases.)
- **Idempotency check (`:7–13`) — KEPT** unchanged (reads `## Triage **Path:**`).

### Internal-only work-types

The user **never** sees a work-type menu — the old T3 menu (`:48–60`) that exposed "Bug fix /
Small refactor / Single document / New feature" is deleted. The work-type label
(`bug-fix | new-feature | refactor`) is produced only by the agent's Step-2 inference and
surfaces in exactly one place: the internal **`STATE.md ## Triage`** write (Step 6). The new-
flow STATE write uses the same block shape as today (`:391–442`), with these fields on the lite
route:

```markdown
## Triage

- **Path:** lite
- **Work Type:** {inferred-type}          # bug-fix | new-feature | refactor (internal only)
- **Sub-path:** {Sub-path}                 # derived: LITE-BUG-FIX | LITE-REFACTOR | LITE-FEATURE
- **Decision rationale:** description → inferred {type}; recipe {name} matched → lite/{Sub-path}
- **Recipe:** {recipe-name}                # omitted when no recipe confirmed
```

For the full route, `Work Type` / `Sub-path` / `Recipe` are **absent** (unchanged contract,
`:368–369`, `:380–381`). The confirmation turn (new Step 3) shows the **type** word in prose for
the user to sanity-check ("Looks like a {bug-fix/new-feature/refactor}…"), but this is a
descriptive English phrase, not a menu the user navigates — the user confirms the *inference*,
they do not *select* a taxonomy token.

### LITE-DOC elimination

`single-doc` is removed from the enum by feature-001 (the `Work Type` enum line
`work-state-template.md:18` and the `workType` glossary term `domain-glossary.md:147`). The
**sub-path** consequences are feature-002's. Precisely how `single-doc` / `LITE-DOC` fold away:

1. **workType→Sub-path mapping** (`state-triage.md:87–94`) — the `| single-doc | LITE-DOC |`
   row is **deleted**. The table becomes:
   | `workType` | Sub-path |
   |---|---|
   | `bug-fix` | `LITE-BUG-FIX` |
   | `refactor` | `LITE-REFACTOR` |
   | `new-feature` | `LITE-FEATURE` |
   Documentation/report work is now classified as `new-feature` (creating a new doc/report →
   `LITE-FEATURE`, recipes `add-docs`/`add-report`) or `refactor` (editing an existing doc/
   report → `LITE-REFACTOR`, recipes `change-docs`/`change-report`). Those recipe **files** are
   feature-003's; feature-002 only ensures the *routing* sends doc work there.

2. **`state-condensed-intake.md § LITE-DOC body` (`:209–295`) — REMOVED, its doc questions
   FOLDED.** The standalone `### Sub-path: LITE-DOC` block (the `doc-title` / `doc-purpose` /
   `outline-bullets` questions + the `## Document Outline` SPEC shape) is deleted. Because docs
   now route under `LITE-FEATURE` / `LITE-REFACTOR`, the doc-specific questions are folded as a
   **conditional note** into those two sub-path bodies: when the work is a doc/report (the
   confirmed recipe is `add-docs`/`add-report`/`change-docs`/`change-report`), the LITE-FEATURE
   `scope`/`goal` (or LITE-REFACTOR `scope`/`before-sketch`/`after-sketch`) prompts are phrased
   to capture audience + outline (the substance the old `doc-purpose` / `outline-bullets` slots
   captured). The recipe-driven path is the common case — when a doc recipe is confirmed in
   TRIAGE, the recipe's own slots collect the outline and CONDENSED-INTAKE is skipped entirely
   (Step 5a-4 chains to LITE-DONE). The dependent references are updated:
   - `state-condensed-intake.md:84` (slot cross-reference table `| LITE-DOC | doc-title, …`) —
     **row deleted**; the `doc-*` slot names move under the LITE-FEATURE / LITE-REFACTOR rows as
     recognised optional slots.
   - `state-condensed-intake.md:520` (unit-testable case `LITE-DOC + all 3 answers`) — **deleted**.

3. **`work-state-template.md:19` (Sub-path enum)** — change
   `LITE-BUG-FIX | LITE-DOC | LITE-REFACTOR | LITE-FEATURE | — (absent for full path)` to
   `LITE-BUG-FIX | LITE-REFACTOR | LITE-FEATURE | — (absent for full path)` (drop `LITE-DOC`).
   (Line 18, the Work Type enum, is feature-001's — already specced to drop `single-doc` there.)

4. **`schemas.md:181` (KB Triage Sub-path enum)** — drop `LITE-DOC`:
   `Sub-path:` ∈ {`LITE-BUG-FIX`, `LITE-DOC`, `LITE-REFACTOR`, `LITE-FEATURE`, `—`} →
   `Sub-path:` ∈ {`LITE-BUG-FIX`, `LITE-REFACTOR`, `LITE-FEATURE`, `—`}. This is the KB mirror of
   the `work-state-template.md:19` enum above and the same category feature-002 owns; lines 180
   (Work Type) and 369 (`applies-to`) on the same doc are feature-001's — no conflict.

5. **`state-task-breakdown.md` LITE-DOC references** — three dangling references:
   `:53` (`exactly 1 for LITE-DOC`), `:61` (sub-path-guidance table row `| LITE-DOC | 1 |
   DOCUMENT |`), `:192` (unit-testable case `| LITE-DOC SPEC.md, no tasks/ |`). All three are
   **removed**; the `DOCUMENT` task-type guidance is folded into the `LITE-FEATURE` /
   `LITE-REFACTOR` rows (a doc work in LITE-FEATURE may be a single `DOCUMENT` task).

6. **`SKILL.md` State Detection / dispatch** — checked: `SKILL.md` references the lite sub-paths
   only generically (State Detection routes on `**Path:** lite` then SPEC/tasks presence, not on
   the specific sub-path; the dispatch table rows name states, not sub-paths). **No `LITE-DOC`
   token appears in `SKILL.md`** (grep-confirmed). The **only** SKILL.md line that describes the
   TRIAGE *flow* in TRIAGE-specific wording is the "you are here" map subtitle
   `SKILL.md:228` — `[State: TRIAGE] — 3 deterministic questions to choose lite or full path.` —
   which must be reworded to "describe-and-confirm" rather than "3 questions". The State-Detection
   routing lines (`:143` State T row, `:168` Q-AND-A → TRIAGE substep) and the dispatch-table row
   (`:309` `TRIAGE | references/state-triage.md | … | → CONDENSED-INTAKE / → CONTINUE`) name the
   state and its transitions only — they contain **no** "3 questions" / T1-T2-T3 wording and need
   **no** change. So `SKILL.md` is in feature-002 scope for a **single one-line reword at
   `:228`**; the State Detection / sub-path *routing logic* is unchanged. (See Scope table.)

7. **KB `domain-glossary.md:149` (LITE-DOC row)** — **deleted** (feature-002-owned per
   feature-001 SPEC:264–266, 366–372).

After these edits, **no `LITE-DOC` or `single-doc` token remains in any feature-002-owned
file** (verification grep in § Render & Verification).

### Scope & Files to Change

Context-aware grep result (where the old structure lives, `reviewer-ledger` excluded):

- **T1/T2/T3 menu + deterministic rule:** `state-triage.md:17,24,30,34,39,44,48,53,60,64–94`
  (steps 1–4) and the rationale/mapping tables at `:365,377,399,413,426,439,454–467`.
- **`single-doc` workType token (feature-002-owned occurrences):** `state-triage.md:80,92,136,
  462,494` (T3 table, workType→Sub-path table, override-update map, unit-test tables).
- **`LITE-DOC` sub-path token:** `state-triage.md:92,116,131,136,462,476,479`;
  `state-condensed-intake.md:84,209,233,240,288,520`; `state-task-breakdown.md:53,61,192`;
  `work-state-template.md:19`; `schemas.md:181`; `domain-glossary.md:149`. (Moot for
  `state-triage.md` since the file is rewritten wholesale, but the list is now accurate;
  `state-triage.md:494` carries `single-doc`/`add-unit-test`, not `LITE-DOC`.)

| File | Lines / anchor | Change | Kind |
|------|----------------|--------|------|
| `canonical/skills/aid-interview/references/state-triage.md` | **whole file** — esp. `17–94` (T1/T2/T3 + rules), `98–351` (Step 5 menu + Step 5a-1/5a-2), `354–442` (Step 6 rationale strings), `454–517` (unit-test tables) | Wholesale description-first rewrite: delete T1/T2/T3 + deterministic rule; new Steps 1–4 (describe → classify → confirm → route); collapse old Step 5 menu into the confirm turn; delete Step 5a-2 menu; **keep** 5a-1 discover + 5a-3/5a-4 slot-fill/emit verbatim; rewrite workType→Sub-path table (drop single-doc/LITE-DOC); rewrite rationale strings + all unit-test tables to be description-keyed. Emits **only** new-enum tokens `{bug-fix, new-feature, refactor}`. | canonical |
| `canonical/skills/aid-interview/references/state-condensed-intake.md` | `84` (slot table LITE-DOC row), `209–295` (LITE-DOC body + SPEC shape), `520` (unit-test case) | Delete the `### Sub-path: LITE-DOC` body + its SPEC shape; delete the LITE-DOC slot-table row (move `doc-*` slots under LITE-FEATURE/LITE-REFACTOR rows); delete the LITE-DOC unit-test case; add a doc/report note to LITE-FEATURE / LITE-REFACTOR bodies so doc questions are captured there. | canonical |
| `canonical/skills/aid-interview/references/state-task-breakdown.md` | `53`, `61`, `192` | Remove the three `LITE-DOC` references; fold the single-`DOCUMENT`-task guidance into the LITE-FEATURE / LITE-REFACTOR rows. | canonical |
| `canonical/skills/aid-interview/SKILL.md` | **`228` only** (TRIAGE "you are here" map subtitle: `[State: TRIAGE] — 3 deterministic questions to choose lite or full path.`) | Reword the one TRIAGE narrative line from "3 deterministic questions" to "free-form description → infer type+recipe → confirm". **Routing logic unchanged** — narrative only. (`:143`/`:168`/`:309` are generic state-detection / dispatch lines with no T1-T2-T3 wording — untouched.) | canonical |
| `canonical/templates/work-state-template.md` | **19 only** (Sub-path enum) | Drop `LITE-DOC` → `LITE-BUG-FIX | LITE-REFACTOR | LITE-FEATURE | — (absent for full path)`. (Line 18 is feature-001's.) | template |
| `.aid/knowledge/schemas.md` | **181 only** (Sub-path enum) | Drop `LITE-DOC` from the Triage Sub-path enum: `Sub-path:` ∈ {`LITE-BUG-FIX`, `LITE-REFACTOR`, `LITE-FEATURE`, `—`}. (Lines 180 Work Type + 369 applies-to are feature-001's — different lines, no conflict.) | KB |
| `.aid/knowledge/domain-glossary.md` | `146` (Triage term), `149` (LITE-DOC row) | Rewrite the **Triage** term definition: replace "2-3 question deterministic routing (T1 breadth, T2 size, T3 type)" with the description-first description ("free-form description → agent infers work-type + best recipe → user confirms in one turn; confident single match → lite, ambiguous/multi/no-match → full"). **Delete** the LITE-DOC glossary row (149). | KB |

> **Not in feature-002 scope (explicit):** `work-state-template.md:18` Work Type enum,
> `domain-glossary.md:147` workType term, `schemas.md:180`/`:369`, `pipeline-contracts.md`
> (feature-001 — enum DEFINITION); the recipe **files** and the recipe-catalog glossary prose
> `domain-glossary.md:168` (feature-003 — INSTANCES); `recipes/README.md` + recipe template +
> `parse-recipe.sh` + test fixtures (feature-001). feature-002 edits **no** recipe file and no
> `summary:`/`applies-to` schema doc.

**Count: 7 files** edited by feature-002 — **4 canonical** (`state-triage.md`,
`state-condensed-intake.md`, `state-task-breakdown.md`, `SKILL.md`) + **1 template**
(`work-state-template.md:19`) + **2 KB** (`domain-glossary.md`, `schemas.md:181`).

> **schemas.md split (no conflict):** feature-001 owns `schemas.md:180` (Work Type enum) and
> `:369` (recipe `applies-to` enum); feature-002 owns `schemas.md:181` (Triage Sub-path enum) —
> different lines, different enums, no overlap. The Sub-path enum is the same category as the
> sub-path artifacts feature-002 already owns (`work-state-template.md:19`,
> `domain-glossary.md:149`), so feature-002 (not feature-001) drops `LITE-DOC` from it.

### No-new-script confirmation

Classification (description → `{type + recipe}`) is **agent inference written as SKILL.md /
`state-triage.md` prose** — there is **no new parsing script** (REQUIREMENTS §7 constraint;
`prose-over-scripts` memory). The `summary:`-matching is the agent reading front-matter strings
and judging the best fit, exactly as `summary:` was designed for (feature-001 SPEC:202–204:
"used by the description-first TRIAGE (feature-002) to match a user's free-form work description
to a recipe").

`parse-recipe.sh` is **unchanged** and still used downstream once a recipe is confirmed:
`--list <recipe>` enumerates slots for the slot-fill loop (kept 5a-3a step,
`state-triage.md:215`) and `--render --recipe … --slots-json … --work-dir …` emits SPEC.md +
task files (kept 5a-4 step, `:310`). Both modes exist in the script (`parse-recipe.sh:89` list,
`:109` render). The front-matter parser reads only the four required keys and ignores `summary:`
(feature-001 SPEC:221–231) — feature-002 adds no key and no mode, so the script is untouched and
the canonical smoke test (`tests/canonical/test-parse-recipe.sh`) is unaffected by feature-002.

### Edge cases

| Case | Behaviour |
|------|-----------|
| **No-match** (candidate set empty, or no summary plausibly fits) | New Step 4 → **full**. STATE rationale: `description → no confident recipe match → full`. The description is carried as the full-path seed (CONTINUE opens from it). |
| **Multiple plausible recipes** (ambiguous within a type) | New Step 3 lists the plausible candidates as `[3]`. If the user picks one → **lite** with that recipe. If the user cannot decide / declines → **full** (conservative). |
| **User rejects the inferred type** (`[2]`) | Treated as no-confident-match → **full**. No second type-guess loop (keeps the one-turn NFR; the full path re-elicits properly). |
| **Confident type but empty candidate set, user still wants lite** | Rare. The confirm turn offers `[1]` only when a recipe exists; with no recipe, the agent confirms type-only and routes **lite, no Recipe field** → CONDENSED-INTAKE (existing no-recipe exit, Step 7 `:450`). Sub-path derived from the confirmed type. |
| **Escalation during the flow** | If the user types an escalate phrase at the description prompt or confirm turn → route **full** (same as `[2]`). Escalation **after** a recipe is confirmed (during slot-fill) uses the retained recipe-to-lite escalation triggers A/B (`state-triage.md:243–250, 277–282`) → CONDENSED-INTAKE with carried slots. Lite→full escalation from later lite states is unchanged (`lite-to-full-escalation.md`). |
| **Wildcard `*` recipes (`add-unit-test`, renamed to `add-test-coverage` by feature-003)** | Participate in the candidate set for **every** inferred type: Step 2's candidate rule is `applies-to == {type}` **OR** `applies-to == '*'` (reuses the existing match rule, `state-triage.md:178`). So a description like "add unit tests for the parser" surfaces the wildcard recipe (`add-unit-test` on disk during feature-002) regardless of whether the agent inferred `new-feature` or `refactor`. |

### AC mapping

| AC (feature-002 SPEC) | Satisfied by |
|---|---|
| **AC2** — TRIAGE description-first: infer `type + recipe`, user confirms, routing (confident single → lite; ambiguous/multi/no-match → full) | New Steps 1–4 (§ New TRIAGE flow) + routing table (Step 4). |
| **One-turn NFR** (§6) | New Step 3 resolves the common case in a single confirmation turn (`[1]` accept). No T1+T2+T3 three-prompt sequence. Walkthrough in § Render & Verification. |
| **No-new-script** (§7) | § No-new-script confirmation — inference is prose; `parse-recipe.sh` unchanged, still used for slot-fill/render. |
| **AC6 (KB — TRIAGE scope)** | `domain-glossary.md:146` Triage term rewritten to the description-first flow; `:149` LITE-DOC row deleted. (Enum-scope KB rows `:147,150,151` are feature-001's; catalog `:168` is feature-003's.) |
| **Re-render byte-identical** | § Render & Verification step 4. |

### Render & Verification

Run in order; all must pass:

1. **No old TRIAGE structure remains in feature-002-owned files.** Confirm zero `LITE-DOC` /
   `single-doc` tokens and zero `T1`/`T2`/`T3` menu artifacts in the files feature-002 owns:
   ```sh
   grep -nE 'LITE-DOC|single-doc' \
     canonical/skills/aid-interview/references/state-triage.md \
     canonical/skills/aid-interview/references/state-condensed-intake.md \
     canonical/skills/aid-interview/references/state-task-breakdown.md \
     canonical/skills/aid-interview/SKILL.md \
     canonical/templates/work-state-template.md \
     .aid/knowledge/domain-glossary.md
   grep -nE '\bT[123]\b' canonical/skills/aid-interview/references/state-triage.md
   # schemas.md is co-owned: feature-002 only drops LITE-DOC from the Sub-path enum (line 181).
   # Verify the Sub-path enum line carries no LITE-DOC (single-doc on :180 is feature-001's, may
   # still be present until feature-001 lands):
   sed -n '181p' .aid/knowledge/schemas.md | grep -c 'LITE-DOC'   # expect 0
   ```
   Expect **no output** from the two `grep -nE` sweeps and `0` from the `schemas.md:181` check.
   (The work-level repo-wide sweep — zero old enum tokens across
   all canonical/tests/KB, excluding `reviewer-ledger-schema.md` benign prose — is the work-001
   gate run after feature-003 lands, per feature-001 SPEC:303–308.)
2. **State-machine self-consistency:** every `**Sub-path:**` value emitted by `state-triage.md`
   (`LITE-BUG-FIX | LITE-REFACTOR | LITE-FEATURE`) has a matching body in
   `state-condensed-intake.md` and a guidance row in `state-task-breakdown.md` — and there is no
   orphan reference to a sub-path that no longer exists. Grep the three files for the sub-path
   token set and diff against the enum at `work-state-template.md:19` **and** its KB mirror
   `schemas.md:181` — both must read `{LITE-BUG-FIX, LITE-REFACTOR, LITE-FEATURE, —}` identically.
3. **`parse-recipe.sh` untouched:** `git diff --stat canonical/scripts/interview/parse-recipe.sh`
   and `tests/canonical/test-parse-recipe.sh` show **no feature-002 changes**; the smoke test
   `bash tests/canonical/test-parse-recipe.sh` stays green (feature-002 introduces no script
   change, so it cannot regress).
4. **Re-render to all 5 install trees:** run `/aid-generate`; then the deterministic verify
   asserts the rewritten `state-triage.md` / `state-condensed-intake.md` /
   `state-task-breakdown.md` / `SKILL.md` and `work-state-template.md` render byte-identical
   across `antigravity`, `claude-code`, `codex`, `copilot-cli`, `cursor`. Confirm no stale
   `LITE-DOC` / T1-T2-T3 tokens survive in the rendered trees for these files.
5. **KB TRIAGE narrative updated:** `domain-glossary.md` Triage term (`:146`) describes the
   description-first flow; the LITE-DOC row (`:149`) is gone; add a dated `changelog:`
   front-matter entry to `domain-glossary.md`: "work-001 feature-002 — TRIAGE rewritten
   description-first; LITE-DOC sub-path eliminated."
6. **Manual one-turn walkthrough (proves the NFR):**
   - User: "fix the login crash when the username has a `+`." → agent infers `bug-fix`, scans
     `applies-to ∈ {bug-fix, *}`, matches `summary:` of `fix-application` (or `fix-ui`) → confirm
     turn "Looks like a bug-fix — recipe `fix-application` (…). [1] Yes …" → user `[1]` →
     **lite**, Recipe=`fix-application`, slot-fill via `parse-recipe.sh --list/--render` → emit →
     LITE-DONE. **One confirmation turn.**
   - User: "add a `/orders` REST endpoint." → infers `new-feature`, matches `add-api-endpoint`
     summary → `[1]` → **lite**. One turn.
   - User: "rewrite the whole billing subsystem across 4 services." → no single recipe fits /
     ambiguous + multi-target → **full**. STATE rationale: `description → no confident recipe
     match → full`.
   - User: "write an ADR for the database choice." → infers `new-feature` (new doc artifact),
     matches `add-docs`/`add-report` → `[1]` → **lite** / LITE-FEATURE (proves LITE-DOC folded
     away, doc work routes under new-feature).

### Risks / sequencing

- **Depends on feature-001 (`summary:` must exist).** The matcher reads `summary:`; if recipes
  lack it, matching degrades to `applies-to`-only (coarse) and more cases route full. feature-001
  defines the `summary:` schema convention (its SPEC § `summary:` Schema Addition); feature-002's
  prose must be implementable even if only the **migrated seed set** carries `summary:` at the
  time feature-002 lands.
- **Depends on feature-003 (recipes with good summaries make matching meaningful).** The full
  ~51-recipe catalog with quality summaries is what makes single-recipe matches frequent. Until
  feature-003 lands, the candidate set is the 5 migrated seed recipes — the flow is **still
  implementable and correct** against that seed set (more descriptions simply route full, which
  is the conservative safe default). feature-002 must not assume any recipe beyond the migrated
  seed set exists; the routing rule degrades gracefully.
- **Sequencing within work-001:** feature-001 (DEFINITION) → feature-002 (this, CONSUMER) →
  feature-003 (INSTANCES), all in one work/delivery. feature-002's wholesale `state-triage.md`
  rewrite naturally emits only new-enum tokens, so it clears the old-token sweep for its owned
  files; the repo-wide sweep is the work-level gate after feature-003 (feature-001 SPEC:303–308).
- **Risk — folding doc questions:** removing the dedicated LITE-DOC body must not lose the
  audience/outline capture. Mitigated by folding `doc-purpose`/`outline-bullets` into the
  LITE-FEATURE/LITE-REFACTOR prompts and by the doc recipes (`add-docs`/`add-report`, feature-003)
  carrying outline slots — so the common (recipe-driven) doc path captures the outline without a
  dedicated sub-path.

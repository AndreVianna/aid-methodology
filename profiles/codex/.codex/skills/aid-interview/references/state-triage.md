# State: TRIAGE

Runs immediately after FIRST-RUN scaffolding and before the conversational interview.
Asks a free-form description question to decide whether this work takes the **lite path**
or the **full path**, and infers the best matching recipe from the description in prose.

## Idempotency check

Before doing anything, read `STATE.md ## Triage`. If the `**Path:**` field is already
populated, triage was already completed — **skip this entire state** and advance to
CONTINUE (full-path) or the appropriate lite-path state (if `**Path:** lite`).

Print: `[State: TRIAGE] Already complete — Path: {value}. Resuming.`

---

## Step 1: Ask for free-form work description

Ask the user (free-form, ONE turn):

```
Describe the work you want to do, in your own words.
(e.g., "fix the login crash on special characters", "add a /orders API endpoint",
 "rename the OrderSvc class everywhere", "write an ADR for the DB choice")
```

Wait for the user's free-form answer. Record it internally as `{description}`.

---

## Step 2: Classify — agent inference (prose, no script)

From `{description}`, infer **two things** in prose:

### 2a: Infer internal work-type

Assign one of the three internal work-type labels (never shown as a menu to the user):

| Heuristic | `workType` |
|-----------|-----------|
| Broken / observed-wrong behaviour; something worked before | `bug-fix` |
| Net-new capability or net-new artifact (incl. new docs, reports, ADRs) | `new-feature` |
| Change / rename / improve an existing working artifact (incl. editing existing docs) | `refactor` |

**workType → Sub-path mapping (lite path only):**

| `workType` | Sub-path |
|------------|----------|
| `bug-fix` | `LITE-BUG-FIX` |
| `refactor` | `LITE-REFACTOR` |
| `new-feature` | `LITE-FEATURE` |

Documentation and report work is classified as `new-feature` (creating a new doc/report →
`LITE-FEATURE`) or `refactor` (editing an existing doc/report → `LITE-REFACTOR`). There is
no dedicated doc-only sub-path — doc work routes under `LITE-FEATURE` / `LITE-REFACTOR`.

### 2b: Find best-matching recipe

Scan `.codex/aid/recipes/` relative to the AID installation root (the same directory that
contains `.codex/skills/`). For each `.md` file, read the `applies-to` and `summary:`
fields from its YAML front-matter. **Skip any file whose front-matter cannot be parsed or
is missing required fields** (e.g., `README.md` has no front-matter — `parse-recipe.sh
--validate` exits non-zero on it). Parse failures are not errors; handle gracefully and
continue.

**Candidate set** — recipes whose `applies-to` field matches the inferred `workType` OR is
the wildcard `'*'`:

```
recipe.applies-to == workType   OR   recipe.applies-to == '*'
```

(The current wildcard recipe is `add-test-coverage`, `applies-to: *`. Wildcard recipes
participate in the candidate set for every inferred type.)

Within the candidate set, **read each recipe's `summary:`** and pick the recipe whose
summary text best matches `{description}` (semantic match on the summary string — agent
inference, no script). Produce:

- **best recipe** (the clearest single match), AND
- **confidence judgment**: single clear winner | several plausible | none.

If the candidate set is empty, confidence = none.

---

## Step 3: Single confirmation turn

Present the inference to the user and wait for their response **on this same turn** (this
is the one-turn NFR — the common case resolves here with no further back-and-forth):

**When a recipe was matched:**

```
Looks like a {inferred-type} — recipe `{recipe-name}` ({summary}).

[1] Yes — proceed (lite path, recipe `{recipe-name}`)
[2] No — it's a different kind of work (I'll route to the full path)
[3] Different recipe: {list other plausible candidates, if any}
```

**When no recipe matched (candidate set empty or no summary fits):**

```
Looks like a {inferred-type}, but I couldn't find a matching recipe for this description.

[1] Proceed without a recipe (lite path, standard condensed interview)
[2] Route to full path instead
```

Wait for the user's response **on this same turn** before advancing.

**Response mapping:**

- **`[1]` accept (recipe present):** confident single match accepted → route **lite** with
  `{recipe-name}`.
- **`[1]` accept (no recipe):** confirmed type, no recipe → route **lite**, no Recipe field.
- **`[2]` reject / route to full:** user rejects the inferred type or prefers full path →
  route **full** (treat as no-confident-match; the description carries forward as the
  full-path seed for CONTINUE). No second type-guess loop.
- **`[3]` pick a different candidate:** user selects one of the listed plausible alternatives
  → route **lite** with the chosen recipe.

**Escalation at the description or confirm turn:** if the user types an escalation phrase,
treat as `[2]` (route full).

---

## Step 4: Routing decision

Deterministic from Step 2's confidence and Step 3's answer:

| Step 2 confidence | Step 3 answer | Route |
|---|---|---|
| Single clear recipe winner | `[1]` accept | **lite**, recipe = winner |
| Single clear recipe winner | `[3]` pick another candidate | **lite**, recipe = chosen |
| Several plausible recipes (ambiguous) | `[3]` pick one | **lite**, recipe = chosen |
| Several plausible recipes | user can't pick / declines | **full** |
| No candidate matches (empty set) | `[1]` accept no-recipe | **lite**, no recipe |
| No candidate matches (empty set) | `[2]` reject | **full** |
| Any | `[2]` reject type | **full** |

The rule is intentionally conservative: any signal short of one confident, user-confirmed
single recipe routes to **full** (or lite-no-recipe for the rare edge case above).

---

## Step 5a: Recipe slot-fill (lite path only)

This step runs **only when Path = lite AND a recipe was confirmed** in Step 3. It fires
immediately after Step 4 routes lite-with-recipe, before STATE.md is written in Step 6.

### 5a-1: Discover matching recipes

Scan the canonical recipes directory (the path is:
`.codex/aid/recipes/` relative to the AID installation root, i.e. the same directory
that contains `.codex/skills/`). For each `.md` file, read the `applies-to` field
from its YAML front-matter. **Skip any file whose front-matter cannot be parsed or is missing required fields** (e.g., `README.md` has no front-matter — `parse-recipe.sh --validate` exits non-zero on it). Parse failures are not errors; handle gracefully and continue.

A recipe matches if:

```
recipe.applies-to == workType   OR   recipe.applies-to == '*'
```

If no recipes match — the catalog is empty or no applies-to matches `workType` or `*`
— skip this entire step (Step 5a). Proceed directly to Step 6.

### 5a-3a: User picks a recipe — slot-fill loop

When the user picks a recipe number:

1. **Identify the recipe file:** resolve the chosen recipe's `.md` path in
   `.codex/aid/recipes/`.

2. **List slots:** call `parse-recipe.sh --list <recipe-file>` to get the ordered
   list of slot names (one per line, unique, order of first appearance).

   - If the slot list is empty (recipe has no slots), skip the slot-fill loop and
     proceed directly to rendering.

3. **For each slot name (in order):**

   Present a prompt:

   ```
   Slot: {slot-name}
   Enter value (press Enter twice / empty line to finish multi-line input):
   ```

   Wait for the user's input. Multi-line answers are terminated by an **empty line**
   (user presses Enter on a blank line after their text). Single-line answers may
   end on the first line if the next line is blank.

   If the user provides an **empty value** (first input is immediately an empty line),
   reject it and re-prompt:

   ```
   Slot {slot-name} cannot be empty. Please enter a value:
   ```

   Repeat until the user provides a non-empty value.

   **Escalation during slot-fill:** If the user types the literal string
   `/aid-interview escalate-from-recipe` as their slot value, stop the slot-fill
   loop immediately. Invoke `references/recipe-to-lite-escalation.md` (Trigger A),
   passing the recipe name and the partial slot-value mapping collected so far.
   Do NOT re-prompt "slot cannot be empty" for the escalation trigger — the trigger
   string is a command, not a slot value. After the escalation procedure completes,
   proceed to Step 5a-3b (decline path) — the `Recipe` field is omitted and
   CONDENSED-INTAKE is the next state.

4. **Collect all slot values** into an internal mapping:
   `{ "slot-name": "user-supplied-value", ... }`

5. **Confirm before render:** After all slots are filled, show a summary:

   ```
   Recipe: {recipe-name}
   Slots filled:
     {slot-1}: {value-1}
     {slot-2}: {value-2}
     ...

   [1] Emit SPEC.md + tasks and proceed
   [2] Edit a slot value (enter slot name to re-fill)
   [3] Abort and use the standard condensed interview instead
   [4] Escalate to standard interview (preserves all slot values)
   ```

   Wait for the user's choice **on this same turn**.

   - **[1] Emit:** proceed to Step 5a-4.
   - **[2] Edit:** prompt `Which slot to re-fill? (enter name):` and re-run the
     slot prompt for that slot only. Loop back to the summary.
   - **[3] Abort:** treat as a decline (proceed to Step 5a-3b). Slot values are
     discarded — no `## Recipe Slots` block is written.
   - **[4] Escalate:** invoke `references/recipe-to-lite-escalation.md` (Trigger B),
     passing the recipe name and the **complete** slot-value mapping (all slots filled).
     After the escalation procedure completes, proceed to Step 5a-3b — the `Recipe`
     field is omitted and CONDENSED-INTAKE is the next state. The `## Recipe Slots`
     block written by the escalation procedure contains all slots, so CONDENSED-INTAKE
     will skip all sub-path questions that were already answered.

### 5a-3b: User declines (or aborts from confirmation)

When the user picks `[0]` (decline) or aborts from the confirmation step:

- No recipe is recorded.
- The `Recipe` field in `STATE.md ## Triage` is **omitted** (not written, not "none").
- Control flows to Step 6 with the current lite-path settings unchanged.
- CONDENSED-INTAKE will run the standard sub-path condensed interview per
  task-016.

### 5a-4: Write slots JSON + emit + update STATE.md

After the user confirms emission (Step 5a-3a choice [1]):

1. **Write slots JSON** to a temporary file (e.g., `<system-temp>/aid-slots-{work}.json`)
   as a flat JSON object: `{ "slot-name": "value", ... }`.

   Auto-fill two special slots if present in the recipe but not prompted
   (i.e., if `work-name` or `date` appear in the slot list, auto-fill them
   rather than prompting the user):
   - `work-name` → the current work identifier (e.g., `work-001-aid-lite`)
   - `date` → today's date in `YYYY-MM-DD` format

   If these slots were already prompted and the user provided a value, use
   the user-supplied value (do not override with the auto-fill).

2. **Emit:** call `parse-recipe.sh --render --recipe <file> --slots-json <json> --work-dir <work-dir>`
   where `<work-dir>` is the `.aid/{work}/` directory for this work. This writes:
   - `.aid/{work}/SPEC.md` — rendered spec block with all slots substituted
   - `.aid/{work}/tasks/task-NNN.md` — one file per task heading

   The `{!{` → `{{` escape rewrite is applied by `parse-recipe.sh` at emit time;
   no additional rewrite is needed here.

3. **Write `STATE.md ## Recipe Slots`** section immediately after emission succeeds:

   ```markdown
   ## Recipe Slots

   Recipe: {recipe-name}

   | Slot | Value |
   |------|-------|
   | {slot-1} | {value-1} |
   | {slot-2} | {value-2} |
   | ... | ... |
   ```

   This section is written even for escalation (with only the slots filled so far).
   It preserves slot values for task-017 escalation handling.

4. **Scaffold the delivery-001 hierarchy** from the emitted task files.

   The recipe emit step writes the work-root `SPEC.md` and task files to a flat
   `tasks/task-NNN.md` layout. After emission, promote the hierarchy to the
   uniform pattern:

   a. Create `delivery-001/SPEC.md` and `delivery-001/STATE.md` following the same
      shape as TASK-BREAKDOWN Step 4a + 4b (delivery State = `Executing`).
   b. For each emitted `tasks/task-NNN.md`: create `delivery-001/tasks/task-NNN/`
      folder; move the emitted file to `delivery-001/tasks/task-NNN/SPEC.md`;
      create the accompanying `delivery-001/tasks/task-NNN/STATE.md` seeded with
      State=Pending (same shape as TASK-BREAKDOWN Step 4c).
   c. Update the work-root SPEC.md `## Tasks` note to reference `delivery-001/tasks/`
      (same as TASK-BREAKDOWN Step 5).
   d. Delete the now-empty `tasks/` folder if it is empty after promotion.

   The `## Tasks State` section of the work-level STATE.md is DERIVED at read time;
   do NOT write task rows directly into the work STATE.md.

5. **Record recipe name** — set internal `recipe = {recipe-name}`. This value is
   written to `STATE.md ## Triage` in Step 6 as the `Recipe:` field.

6. **CHAIN to LITE-DONE** instead of CONDENSED-INTAKE. Print:

   ```
   Recipe '{recipe-name}' emitted: SPEC.md + {N} task file(s).
   → Advancing to [State: LITE-DONE]
   ```

   Then continue inline. (Recipe-instantiated works skip CONDENSED-INTAKE, TASK-BREAKDOWN, and LITE-REVIEW; the recipe already produced the complete deliverable set. LITE-DONE sets SPEC.md Status=Ready and prints the /aid-execute hand-off.)

---

## Step 6: Write STATE.md `## Triage` block

Write the triage result to the work-area `STATE.md ## Triage` section.
**Write immediately** after Step 4 routes the work. Do not batch.

**Full-path result (from routing — no confident recipe match or user rejected):**

```markdown
## Triage

- **Path:** full
- **Decision rationale:** description → no confident recipe match → full
```

`Work Type`, `Sub-path`, `Sub-path (auto)`, `Override`, and `Recipe` fields are **absent**
(not written, not "n/a") for full-path works.

**Full-path result (user escalated from lite during Step 3):**

```markdown
## Triage

- **Path:** escalated
- **Decision rationale:** description → inferred {type}; recipe {name} proposed → escalated to full — {user escalation rationale}
```

`Work Type`, `Sub-path`, `Sub-path (auto)`, `Override`, and `Recipe` fields are **absent**
(not written, not "n/a") for escalated-to-full works.

> **`Path: escalated` vs `Path: full` rationale:** `escalated` is a distinct sentinel value
> (not `full`) so that State Detection can detect mid-escalation crash recovery — if
> `Path: escalated` AND `.aid/{work}/SPEC.md` still exists, the final delete step (Step 9c
> of `references/lite-to-full-escalation.md`) did not complete, and escalation steps 9a–9c
> must be replayed idempotently. Once the work is fully escalated and `SPEC.md` is deleted,
> `Path: escalated` routes identically to `Path: full` in all state detection branches.
> See `SKILL.md § State Detection` step (f) and `references/lite-to-full-escalation.md § State Detection contract`.

**Lite-path result (no recipe / recipe declined):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {Sub-path}
- **Decision rationale:** description → inferred {type} → lite/{Sub-path}
```

`Recipe` field is **absent** (not written, not "none") when the user declines the
recipe or no recipes matched.

**Lite-path result (recipe confirmed, no sub-path override):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {Sub-path}
- **Decision rationale:** description → inferred {type}; recipe {name} matched → lite/{Sub-path}
- **Recipe:** {recipe-name}
```

**Lite-path result (user picked a different recipe — `[3]` — whose recipe implies a
different sub-path than first-inferred):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {user-chosen Sub-path}
- **Sub-path (auto):** {originally inferred Sub-path}
- **Decision rationale:** description → inferred {type}; {user-chosen recipe} selected → lite/{user-chosen Sub-path}
- **Override:** yes
- **Recipe:** {recipe-name}
```

`Override: yes` now only arises when the user picks a `[3]` candidate whose recipe implies
a different sub-path than the first-inferred one. When the user accepts `[1]` or the `[3]`
pick stays within the same sub-path, `Sub-path (auto)` and `Override` are **omitted**.

---

## Step 7: Advance

- **FULL path:** **CHAIN** → [State: CONTINUE] (continue inline). FIRST-RUN Step 1d opens the conversation; the orchestrator proceeds directly into CONTINUE.
- **LITE path (recipe emitted):** **CHAIN** → [State: LITE-DONE]. Step 5a-4 already printed the advance line; no additional print needed.
- **LITE path (no recipe / declined):** **CHAIN** → [State: CONDENSED-INTAKE] (continue inline). State CONDENSED-INTAKE is the lite-path L1 state; it is outside the scope of this file and handled by the lite-path states.

---

## Unit-testable mapping rules (summary)

### Routing and mapping (task-014 scope)

| Description (free-form) | Inferred type | Confidence | Step 3 answer | Route | workType | Sub-path |
|-------------------------|---------------|-----------|--------------|-------|----------|----------|
| "fix the login crash on special characters" | `bug-fix` | single clear winner | `[1]` accept | lite | `bug-fix` | `LITE-BUG-FIX` |
| "add a /orders REST endpoint" | `new-feature` | single clear winner | `[1]` accept | lite | `new-feature` | `LITE-FEATURE` |
| "rename the OrderSvc class everywhere" | `refactor` | single clear winner | `[1]` accept | lite | `refactor` | `LITE-REFACTOR` |
| "write an ADR for the database choice" | `new-feature` | single clear winner | `[1]` accept | lite | `new-feature` | `LITE-FEATURE` |
| "rewrite the whole billing subsystem across 4 services" | `refactor` | no match (multi-target / ambiguous) | (auto → full) | full | — | — |
| "fix the crash" (ambiguous — multiple plausible recipes) | `bug-fix` | several plausible | user can't pick | full | — | — |
| "add unit tests for the parser" | `new-feature` or `refactor` | single clear winner (`add-test-coverage`, `applies-to=*`) | `[1]` accept | lite | inferred type | inferred sub-path |
| any description | any | any | `[2]` reject type | full | — | — |

### Confirmation and override paths (task-015 scope)

| Inferred result | User choice | Override recorded? | Final STATE.md |
|----------------|-------------|-------------------|----------------|
| lite / `LITE-BUG-FIX`, recipe `fix-application` | `[1]` accept | no | Path=lite, Sub-path=LITE-BUG-FIX, Recipe=fix-application (no Override, no Sub-path (auto)) |
| lite / `LITE-REFACTOR`, recipe `change-member` | `[1]` accept | no | Path=lite, Sub-path=LITE-REFACTOR, Recipe=change-member |
| lite / `LITE-FEATURE`, recipe `add-api-endpoint` | `[3]` pick `change-member` (different sub-path) | yes | Path=lite, Sub-path=LITE-REFACTOR, Sub-path (auto)=LITE-FEATURE, Override=yes, Recipe=change-member |
| lite / `LITE-BUG-FIX`, recipe `fix-application` | `[2]` reject → full | no (Sub-path absent) | Path=full, Sub-path absent, rationale: description → no confident recipe match → full |
| full (routing — no match) | (no confirmation offered) | n/a | Path=full, no Sub-path, no Override |

### Recipe-offer paths (task-028 scope)

| Path | workType | Recipe catalog | User action | Slot-fill result | Final STATE.md | Next state |
|------|----------|----------------|-------------|-----------------|----------------|------------|
| FULL | any | any | (not offered) | n/a | no Recipe field | CONTINUE |
| LITE escalated to full | any | any | (not offered) | n/a | no Recipe field | CONTINUE |
| LITE | `bug-fix` | no matching recipes | (skip — step not shown) | n/a | no Recipe field | CONDENSED-INTAKE |
| LITE | `bug-fix` | ≥1 match | `[2]` reject (no recipe) | n/a | no Recipe field | CONDENSED-INTAKE |
| LITE | `bug-fix` | ≥1 match | `[1]` accept, confirm `[1]` Emit | all slots filled | Recipe=fix-application | LITE-DONE |
| LITE | `bug-fix` | ≥1 match | `[1]` accept, confirm `[3]` Abort | abandoned; no slot carry | no Recipe field | CONDENSED-INTAKE (no pre-fill) |
| LITE | `refactor` | ≥1 match | `[1]` accept, escalate during slot-fill | partial slots in STATE.md ## Recipe Slots; Status=abandoned | no Recipe field | CONDENSED-INTAKE (seeded from partial slots) |
| LITE | `refactor` | ≥1 match | `[1]` accept, all slots filled, confirm `[4]` Escalate | all slots in STATE.md ## Recipe Slots; Status=abandoned | no Recipe field | CONDENSED-INTAKE (all questions pre-filled) |
| LITE | `*` (`add-test-coverage`, `applies-to=*`) | any inferred type, `add-test-coverage` applies-to=* | `[1]` accept | all slots filled | Recipe=add-test-coverage | LITE-DONE |

### Slot-fill rules (task-028 / task-029 scope)

| Scenario | Expected behavior |
|----------|------------------|
| Empty slot answer (immediate empty line) | Rejected; re-prompted with error message |
| Multi-line slot value (text then empty line) | Full multi-line text captured as slot value |
| Slot value `/aid-interview escalate-from-recipe` | Trigger A: slot-fill loop aborted; recipe-to-lite-escalation.md invoked; partial slots preserved in STATE.md ## Recipe Slots (Status=abandoned); no Recipe field in Triage; CONDENSED-INTAKE next |
| All slots filled, user picks [1] Emit | parse-recipe.sh --render called; SPEC.md + task files written |
| All slots filled, user picks [2] Edit | Named slot re-prompted; back to summary |
| All slots filled, user picks [3] Abort | Decline path; no slot carry; no Recipe field in STATE.md |
| All slots filled, user picks [4] Escalate | Trigger B: recipe-to-lite-escalation.md invoked with full slot set; all slots preserved in STATE.md ## Recipe Slots (Status=abandoned); no Recipe field in Triage; CONDENSED-INTAKE next (all questions skipped) |
| `work-name` or `date` in slot list | Auto-filled from context; not prompted to user |
| Recipe has zero slots | No prompts; proceed directly to confirm and render (confirm has [1]/[3]/[4] options; [4] writes empty Recipe Slots block) |

### Recipe-escalation paths (task-029 scope)

| Trigger | Slots at escalation | ## Recipe Slots block | Recipe field in Triage | CONDENSED-INTAKE effect |
|---------|--------------------|-----------------------|------------------------|------------------------|
| Trigger A — 0 slots filled | none | placeholder row; Status=abandoned | absent | no pre-fill; all questions asked |
| Trigger A — N of M slots filled (N < M) | N slots | N rows + Status=abandoned | absent | N questions skipped; M−N questions asked |
| Trigger B — all slots filled | all slots | all rows + Status=abandoned | absent | all questions skipped; user sees pre-fill summary then SPEC.md |
| Chained: recipe-escalate → CONDENSED-INTAKE escalate | recipe slots + CONDENSED-INTAKE slots | ## Recipe Slots present + ## Escalation Carry added | absent (lite→full escalation clears Recipe field too) | CONTINUE (full path) |

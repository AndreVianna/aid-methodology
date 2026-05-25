# State: TRIAGE

Runs immediately after FIRST-RUN scaffolding and before the conversational interview.
Asks 2–3 deterministic triage questions to decide whether this work takes the **lite path**
or the **full path**.

## Idempotency check

Before doing anything, read `STATE.md ## Triage`. If the `**Path:**` field is already
populated, triage was already completed — **skip this entire state** and advance to
CONTINUE (full-path) or the appropriate lite-path state (if `**Path:** lite`).

Print: `[State: TRIAGE] Already complete — Path: {value}. Resuming.`

---

## Step 1: Ask T1 — Breadth

Ask the user (closed choice, ONE turn):

```
Quick triage (3 questions to pick the right path):

T1 — How many distinct features does this work touch?
  [a] None — it's a bug fix, refactor, or single artifact
  [b] One small feature
  [c] Multiple features or a whole system
```

Wait for the user's answer. Record the selection internally: `T1 = none | one small | multiple`.

---

## Step 2: Ask T2 — Size

Ask the user (closed choice, ONE turn):

```
T2 — Roughly how many distinct tasks will this require?
  [a] A few (≤ ~5)
  [b] Many (6 or more)
```

Wait for the user's answer. Record: `T2 = a few | many`.

---

## Step 3: Ask T3 — Type

Ask the user (closed choice, ONE turn):

```
T3 — What kind of work is it?
  [a] Bug fix
  [b] Small refactor
  [c] Single document or artifact
  [d] New feature or system
```

Wait for the user's answer. Record: `T3 = bug fix | small refactor | single document/artifact | new feature or system`.

---

## Step 4: Apply deterministic routing rule

Route **LITE** if and only if **all** of:
- T1 ∈ {`none`, `one small`}
- T2 = `a few`
- T3 ∈ {`bug fix`, `small refactor`, `single document/artifact`}

Route **FULL** otherwise. The rule is intentionally conservative: any single "large" signal
routes to FULL.

**T3 → workType kebab mapping:**

| T3 answer | `workType` enum |
|-----------|-----------------|
| `bug fix` | `bug-fix` |
| `small refactor` | `small-refactor` |
| `single document/artifact` | `single-doc` |
| `new feature or system` | `small-new-feature` |

If T3's answer does not match any of the four choices above (e.g., free-form text that
cannot be normalised), fall back to FULL path — the lite path is only selected when T3
yields a normalisable value.

**workType → Sub-path mapping (lite path only):**

| `workType` | Sub-path |
|------------|----------|
| `bug-fix` | `LITE-BUG-FIX` |
| `single-doc` | `LITE-DOC` |
| `small-refactor` | `LITE-REFACTOR` |
| `small-new-feature` | `LITE-FEATURE` |

---

## Step 5: Expose decision and offer override

This step runs on **both** LITE and FULL verdicts, but with different options.

### For LITE verdict — show decision and offer 3 choices

Show the auto-detected decision to the user on the same triage turn (no re-invocation
needed) and wait for their response:

```
Triage decided:
  Path:     lite
  Type:     {workType}
  Sub-path: {Sub-path} ({one-line description})

[1] Proceed with {Sub-path}
[2] Use a different sub-path:
      [a] LITE-BUG-FIX  — reproduction + intended-behavior + 1 task
      [b] LITE-DOC       — document outline + 1 task
      [c] LITE-REFACTOR  — before/after sketch + scope + AC + tasks
      [d] LITE-FEATURE   — standard lite SPEC with extra AC elicitation
[3] Escalate to full path
```

Wait for user response **on this same turn** before advancing.

**[1] Accept auto-detected sub-path:**
- No override recorded.
- `Sub-path (auto)` and `Override` fields are **omitted** from the STATE.md write.
- Proceed to Step 6 with Path=lite, Sub-path={auto-detected value}.

**[2] Use a different sub-path:**
- Record `Sub-path (auto)` = the original auto-detected Sub-path value.
- Update `Sub-path` to the user's selected sub-path (`[a]`→`LITE-BUG-FIX`, `[b]`→`LITE-DOC`,
  `[c]`→`LITE-REFACTOR`, `[d]`→`LITE-FEATURE`).
- Set `Override: yes`.
- Update `workType` to match the new Sub-path:
  - `LITE-BUG-FIX` → `bug-fix`
  - `LITE-DOC` → `single-doc`
  - `LITE-REFACTOR` → `small-refactor`
  - `LITE-FEATURE` → `small-new-feature`
- Proceed to Step 6 with Path=lite, Sub-path={user-chosen value}.

**[3] Escalate to full path:**
- Set `Path: full`.
- `Sub-path` field is **absent** — do NOT write "n/a" or any placeholder.
- `Work Type`, `Sub-path (auto)`, and `Override` fields are also **absent**.
- Ask the user for the escalation rationale (ONE follow-up question):
  ```
  Why escalate to full path? (e.g., "scope is broader than expected", "need full spec")
  ```
  Wait for the user's response. Record it as the escalation rationale.
- Proceed to Step 6 with Path=full.

### For FULL verdict (from routing rule, not escalation)

Proceed directly to Step 6. No override offer — FULL is the safe default and the routing
rule's own conservative logic already handles this case. The user may re-run with
`--reset` if they believe FULL is wrong.

---

## Step 5a: Recipe-offer (lite path only)

This step runs **only when Path = lite** (auto-detected or overridden, but NOT when
escalated to full). It fires immediately after the user's sub-path choice is recorded
in Step 5, before STATE.md is written in Step 6.

**Trigger condition:** Path = lite AND at least one recipe matches `workType`.

### 5a-1: Discover matching recipes

Scan the canonical recipes directory (the path is:
`canonical/recipes/` relative to the AID installation root, i.e. the same directory
that contains `canonical/skills/`). For each `.md` file, read the `applies-to` field
from its YAML front-matter. A recipe matches if:

```
recipe.applies-to == workType   OR   recipe.applies-to == '*'
```

If no recipes match — the catalog is empty or no applies-to matches `workType` or `*`
— skip this entire step (Step 5a). Proceed directly to Step 6.

### 5a-2: Present recipe list to user

If at least one recipe matches, present the filtered list and offer a choice on
**one turn**:

```
Recipe catalog — {N} recipe(s) available for {workType}:

  [1] {recipe-name-1} — {one-line description from recipe name}
  [2] {recipe-name-2} — {one-line description from recipe name}
  ...
  [0] Decline — use the standard {Sub-path} condensed interview instead

Recipes give you a pre-filled SPEC + tasks in under 1 minute.
Pick a number, or press 0 to skip:
```

The one-line description per recipe is derived from the recipe `name` field: convert
kebab-case to title-case words (e.g., `bug-fix` → "Bug Fix",
`add-crud-endpoint` → "Add CRUD Endpoint"). Do not re-read the file body to generate
the description — the name field is sufficient.

Wait for the user's response **on this same turn** before advancing.

### 5a-3a: User picks a recipe — slot-fill loop

When the user picks a recipe number:

1. **Identify the recipe file:** resolve the chosen recipe's `.md` path in
   `canonical/recipes/`.

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
   loop immediately. Preserve any slot values already collected. Write them to
   `STATE.md ## Recipe Slots` (see 5a-4). Then proceed to the standard
   {Sub-path} condensed interview (same as the decline path, Step 5a-3b), but
   seed the CONDENSED-INTAKE state with the note: "Recipe '{recipe-name}' partially
   filled; slots collected so far are available in STATE.md ## Recipe Slots."

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
   ```

   Wait for the user's choice **on this same turn**.

   - **[1] Emit:** proceed to Step 5a-4.
   - **[2] Edit:** prompt `Which slot to re-fill? (enter name):` and re-run the
     slot prompt for that slot only. Loop back to the summary.
   - **[3] Abort:** treat as a decline (proceed to Step 5a-3b).

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

4. **Populate `STATE.md ## Tasks Status`** table from the emitted task files.
   For each emitted `tasks/task-NNN.md`:
   - Read the task `Type` field from the file.
   - Add one row to the Tasks Status table: `| NNN | task-NNN | {Type} | 1 | Pending | — | — | Recipe-generated |`

5. **Record recipe name** — set internal `recipe = {recipe-name}`. This value is
   written to `STATE.md ## Triage` in Step 6 as the `Recipe:` field.

6. **Advance to LITE-DONE** instead of CONDENSED-INTAKE. Print:

   ```
   Recipe '{recipe-name}' emitted: SPEC.md + {N} task file(s).
   Next: [State: LITE-DONE] — run /aid-interview again
   ```

   (Recipe-instantiated works skip CONDENSED-INTAKE, TASK-BREAKDOWN, and LITE-REVIEW;
   the recipe already produced the complete deliverable set. LITE-DONE sets
   SPEC.md Status=Ready and prints the /aid-execute hand-off.)

---

## Step 6: Write STATE.md `## Triage` block

Write the triage result to the work-area `STATE.md ## Triage` section.
**Write immediately** after the user accepts, overrides, or escalates. Do not batch.

**Full-path result (from routing rule):**

```markdown
## Triage

- **Path:** full
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → full path
```

`Work Type`, `Sub-path`, `Sub-path (auto)`, `Override`, and `Recipe` fields are **absent**
(not written, not "n/a") for full-path works.

**Full-path result (user escalated from lite):**

```markdown
## Triage

- **Path:** full
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite (auto); escalated to full — {user escalation rationale}
```

`Work Type`, `Sub-path`, `Sub-path (auto)`, `Override`, and `Recipe` fields are **absent**
(not written, not "n/a") for escalated-to-full works.

**Lite-path result (no override, no recipe):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{Sub-path}
```

`Recipe` field is **absent** (not written, not "none") when the user declines the
recipe-offer or no recipes matched.

**Lite-path result (no override, recipe picked):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{Sub-path}
- **Recipe:** {recipe-name}
```

**Lite-path result (user chose different sub-path, no recipe):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {user-chosen Sub-path}
- **Sub-path (auto):** {originally auto-detected Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{user-chosen Sub-path}
- **Override:** yes
```

**Lite-path result (user chose different sub-path, recipe picked):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {user-chosen Sub-path}
- **Sub-path (auto):** {originally auto-detected Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{user-chosen Sub-path}
- **Override:** yes
- **Recipe:** {recipe-name}
```

---

## Step 7: Advance

- **FULL path:** print `Next: [State: CONTINUE] — run /aid-interview again` and exit.
  The state machine continues with the full-path interview (FIRST-RUN Step 1d opens the
  conversation; the next invocation enters CONTINUE).
- **LITE path (recipe emitted):** Step 5a-4 already printed the advance message.
  No additional print needed. The next state is LITE-DONE (not CONDENSED-INTAKE).
- **LITE path (no recipe / declined):** print
  `Next: [State: CONDENSED-INTAKE] — run /aid-interview again` and exit.
  (State CONDENSED-INTAKE is the lite-path L1 state; it is outside the scope of this file
  and handled by the lite-path states.)

---

## Unit-testable mapping rules (summary)

### Routing and mapping (task-014 scope)

| Input | Rule | Output |
|-------|------|--------|
| T1=none, T2=a few, T3=bug fix | LITE | path=lite, workType=bug-fix, Sub-path=LITE-BUG-FIX |
| T1=none, T2=a few, T3=small refactor | LITE | path=lite, workType=small-refactor, Sub-path=LITE-REFACTOR |
| T1=none, T2=a few, T3=single document/artifact | LITE | path=lite, workType=single-doc, Sub-path=LITE-DOC |
| T1=one small, T2=a few, T3=new feature or system | FULL | path=full (T3 is not a lite-eligible type) |
| T1=one small, T2=a few, T3=bug fix | LITE | path=lite, workType=bug-fix, Sub-path=LITE-BUG-FIX |
| T1=multiple, T2=a few, T3=bug fix | FULL | path=full (T1=multiple forces FULL) |
| T1=none, T2=many, T3=bug fix | FULL | path=full (T2=many forces FULL) |
| T1=none, T2=a few, T3={unrecognised} | FULL | path=full (T3 non-normalisable → fallback FULL) |

### Override paths (task-015 scope)

| Auto-result | User choice | Override recorded? | Final STATE.md |
|-------------|-------------|-------------------|---------------|
| LITE / LITE-BUG-FIX | [1] Accept | no | Path=lite, Sub-path=LITE-BUG-FIX (no Override field, no Sub-path (auto) field) |
| LITE / LITE-BUG-FIX | [2] Choose LITE-REFACTOR | yes | Path=lite, Sub-path=LITE-REFACTOR, Sub-path (auto)=LITE-BUG-FIX, Override=yes |
| LITE / LITE-REFACTOR | [2] Choose LITE-FEATURE | yes | Path=lite, Sub-path=LITE-FEATURE, Sub-path (auto)=LITE-REFACTOR, Override=yes |
| LITE / LITE-DOC | [2] Choose LITE-BUG-FIX | yes | Path=lite, Sub-path=LITE-BUG-FIX, Sub-path (auto)=LITE-DOC, Override=yes |
| LITE / LITE-FEATURE | [2] Choose same (LITE-FEATURE) | yes | Path=lite, Sub-path=LITE-FEATURE, Sub-path (auto)=LITE-FEATURE, Override=yes |
| LITE / LITE-BUG-FIX | [3] Escalate | no (Sub-path absent) | Path=full, Sub-path absent, rationale includes escalation reason |
| LITE / LITE-DOC | [3] Escalate | no (Sub-path absent) | Path=full, Sub-path absent, rationale includes escalation reason |
| FULL (routing rule) | (no override offered) | n/a | Path=full, no Sub-path, no Override |

### Recipe-offer paths (task-028 scope)

| Path | workType | Recipe catalog | User action | Slot-fill result | Final STATE.md | Next state |
|------|----------|----------------|-------------|-----------------|----------------|------------|
| FULL | any | any | (not offered) | n/a | no Recipe field | CONTINUE |
| LITE escalated to full | any | any | (not offered) | n/a | no Recipe field | CONTINUE |
| LITE | bug-fix | no matching recipes | (skip — step not shown) | n/a | no Recipe field | CONDENSED-INTAKE |
| LITE | bug-fix | ≥1 match | [0] Decline | n/a | no Recipe field | CONDENSED-INTAKE |
| LITE | bug-fix | ≥1 match | pick recipe, confirm [1] Emit | all slots filled | Recipe=bug-fix | LITE-DONE |
| LITE | bug-fix | ≥1 match | pick recipe, confirm [3] Abort | abandoned | no Recipe field | CONDENSED-INTAKE |
| LITE | small-refactor | ≥1 match | pick recipe, escalate during slot-fill | partial slots in STATE.md ## Recipe Slots | no Recipe field | CONDENSED-INTAKE (seeded) |
| LITE | * (add-unit-test) | workType=single-doc, add-unit-test applies-to=* | pick add-unit-test | all slots filled | Recipe=add-unit-test | LITE-DONE |

### Slot-fill rules (task-028 scope)

| Scenario | Expected behavior |
|----------|------------------|
| Empty slot answer (immediate empty line) | Rejected; re-prompted with error message |
| Multi-line slot value (text then empty line) | Full multi-line text captured as slot value |
| Slot value `/aid-interview escalate-from-recipe` | Slot-fill loop aborted; partial slots preserved in STATE.md; decline path taken |
| All slots filled, user picks [1] Emit | parse-recipe.sh --render called; SPEC.md + task files written |
| All slots filled, user picks [2] Edit | Named slot re-prompted; back to summary |
| All slots filled, user picks [3] Abort | Decline path; no Recipe field in STATE.md |
| `work-name` or `date` in slot list | Auto-filled from context; not prompted to user |
| Recipe has zero slots | No prompts; proceed directly to confirm and render |

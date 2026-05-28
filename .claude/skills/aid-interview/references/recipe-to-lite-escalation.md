# Recipe → Standard-Lite Escalation

Shared procedure invoked from TRIAGE Step 5a (recipe slot-fill loop or confirm-before-emit)
when the user types `/aid-interview escalate-from-recipe` or selects the escalate option at
the confirm-before-emit prompt.

This is **distinct** from the `lite-to-full-escalation.md` procedure:

- **recipe → standard-lite**: stays on the lite path; switches from the recipe pre-fill flow
  to the standard CONDENSED-INTAKE interview. Slot values already collected are preserved in
  `STATE.md ## Recipe Slots` so CONDENSED-INTAKE can skip re-asking them.
- **lite → full** (`lite-to-full-escalation.md`): switches from the lite path to the full
  interview path. Different document, different trigger.

These two escalations can **chain**: recipe → standard-lite → full path (the user can later
type `/aid-interview escalate` in CONDENSED-INTAKE to trigger the full-path escalation).

---

## When This Procedure Fires

**Trigger A — During slot-fill:**
User types the literal string `/aid-interview escalate-from-recipe` as a slot value.
Slot-fill loop is aborted immediately. Any slot values collected before this point are
the partial carry.

**Trigger B — At confirm-before-emit (choice [4]):**
User selects `[4] Escalate to standard interview` at the confirm-before-emit summary.
All slots already filled are the full carry (the slot-fill loop was complete).

---

## Step 1: Collect all slot values filled so far

Gather the internal slot-value mapping collected before the escalation trigger:
`{ "slot-name": "user-supplied-value", ... }`

This may be an empty mapping (escalation before any slot was answered) or a partial/full set.

---

## Step 2: Write `## Recipe Slots` block to STATE.md

Append (or create) the `## Recipe Slots` section in the work-area `STATE.md`. This section
**must be written** even if zero slots were filled, so CONDENSED-INTAKE can detect the
recipe-escalation context.

```markdown
## Recipe Slots

Recipe: {recipe-name}
Status: abandoned — escalated to standard interview

| Slot | Value |
|------|-------|
| {slot-1} | {value-1} |
| {slot-2} | {value-2} |
| ... | ... |
```

If zero slots were filled, omit the table rows — write only:

```markdown
## Recipe Slots

Recipe: {recipe-name}
Status: abandoned — escalated to standard interview

| Slot | Value |
|------|-------|
| (none filled before escalation) | — |
```

**Write immediately. Do not batch.**

---

## Step 3: Do NOT write a `Recipe:` field in STATE.md `## Triage`

Because the recipe was abandoned, the `Recipe` field is **absent** from the Triage block
(not written, not "none"). This is the same contract as the `[3] Abort` path and the `[0]
Decline` path in Step 5a-3a/5a-3b of state-triage.md.

The `## Recipe Slots` block written in Step 2 is the only record of the recipe metadata.

---

## Step 4: Print escalation notice

```
Recipe '{recipe-name}' abandoned — switching to standard {Sub-path} interview.
Slot values collected so far are preserved in STATE.md ## Recipe Slots.
CONDENSED-INTAKE will skip re-asking any question whose slot name matches a preserved value.
```

---

## Step 5: Transition to CONDENSED-INTAKE

Control flows to Step 6 of `state-triage.md` (Write STATE.md `## Triage` block) — same
as the decline path — with the current lite-path settings unchanged. The `Recipe` field
is omitted from the Triage write.

After Step 6, State 7 of state-triage.md prints:

```
→ Advancing to [State: CONDENSED-INTAKE]
```

(Per the chain rule, the orchestrator proceeds inline to CONDENSED-INTAKE without exiting.) CONDENSED-INTAKE detects the `## Recipe Slots` block and pre-fills matching answers
(see state-condensed-intake.md Step 1.5).

---

## What CONDENSED-INTAKE does with the carry

When CONDENSED-INTAKE starts and detects `STATE.md ## Recipe Slots`:

1. Read the table of slot-name → value pairs.
2. For each sub-path question whose slot name appears in the table **with a non-empty,
   non-abandoned value**:
   - Display: `{slot-name} (pre-filled from recipe): {value}` — one per question, in order.
   - Skip the interactive prompt for that slot.
3. For each sub-path question whose slot name is NOT in the table (or whose value is the
   placeholder `(none filled before escalation)`), ask the question normally.
4. After all questions (pre-filled + newly asked) are resolved, continue with SPEC.md
   write as usual.

The pre-fill display happens on a **single turn** before the first interactive question,
so the user can confirm the carried values before CONDENSED-INTAKE begins asking.

---

## Chained escalation: recipe → standard-lite → full

If the user later types `/aid-interview escalate` in CONDENSED-INTAKE, the standard
`lite-to-full-escalation.md` procedure fires. The `## Escalation Carry` block it writes
to STATE.md will include:

- All CONDENSED-INTAKE slot values answered (including those pre-filled from recipe).
- A reference to the `## Recipe Slots` block (noted as artifact context).

The two-step escalation chain works because each procedure writes its own STATE.md block
and the next procedure reads existing blocks without overwriting them.

---

## Unit-testable cases

| Trigger | Slots at trigger | Expected STATE.md | Expected next state |
|---------|-----------------|-------------------|---------------------|
| Trigger A — slot-fill, 0 slots filled | none | `## Recipe Slots` with placeholder row; `Status: abandoned`; no Recipe field in Triage | CONDENSED-INTAKE (no pre-fill) |
| Trigger A — slot-fill, 2 of 4 slots filled | `bug-title`, `bug-description` | `## Recipe Slots` table with 2 rows; `Status: abandoned`; no Recipe field in Triage | CONDENSED-INTAKE (2 questions skipped) |
| Trigger B — confirm [4], all 4 slots filled | all 4 slots | `## Recipe Slots` table with 4 rows; `Status: abandoned`; no Recipe field in Triage | CONDENSED-INTAKE (all questions skipped; user just confirms SPEC.md) |
| Chained: recipe escalate then CONDENSED-INTAKE escalate | recipe slots + CONDENSED-INTAKE slots | `## Recipe Slots` block + `## Escalation Carry` block; `Path: escalated` | CONTINUE (full path) |
| Trigger A — slot-fill, escalate-from-recipe is NOT a valid slot value | n/a | Recipe stays on track; normal slot re-prompt for "cannot be empty" does NOT fire — the escalation fires | (escalation fires, not re-prompt) |

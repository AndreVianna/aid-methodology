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

**Lite-path result (no override — user accepted auto):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{Sub-path}
```

**Lite-path result (user chose different sub-path):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {user-chosen Sub-path}
- **Sub-path (auto):** {originally auto-detected Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{user-chosen Sub-path}
- **Override:** yes
```

---

## Step 7: Advance

- **FULL path:** print `Next: [State: CONTINUE] — run /aid-interview again` and exit.
  The state machine continues with the full-path interview (FIRST-RUN Step 1d opens the
  conversation; the next invocation enters CONTINUE).
- **LITE path:** print `Next: [State: CONDENSED-INTAKE] — run /aid-interview again` and exit.
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

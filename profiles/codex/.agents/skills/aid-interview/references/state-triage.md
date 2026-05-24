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

## Step 5: Expose decision and offer override (lite path only)

For **FULL** verdict: proceed directly to Step 6.

For **LITE** verdict, show the decision to the user and allow override:

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

Wait for user response:

- **[1] Proceed:** No override; `Sub-path (auto)` is omitted from the STATE.md write.
- **[2] Different sub-path:** User selects `[a]–[d]`; record `Sub-path (auto)` = original
  auto-detected value; update `Sub-path` to the user's choice; set `Override: yes`.
- **[3] Escalate:** Set `Path: full`; set `Sub-path` absent; clear any workType; proceed
  as FULL path.

---

## Step 6: Write STATE.md `## Triage` block

Write the triage result to the work-area `STATE.md ## Triage` section.

**Full-path result:**

```markdown
## Triage

- **Path:** full
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → full path
```

`Work Type`, `Sub-path`, `Sub-path (auto)`, `Override`, and `Recipe` fields are **absent**
(not written, not "n/a") for full-path works.

**Lite-path result (no override):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{Sub-path}
```

**Lite-path result (with user override):**

```markdown
## Triage

- **Path:** lite
- **Work Type:** {workType}
- **Sub-path:** {user-chosen Sub-path}
- **Sub-path (auto):** {originally auto-detected Sub-path}
- **Decision rationale:** T1={T1 value} + T2={T2 value} + T3={T3 value} → lite/{user-chosen Sub-path}
- **Override:** yes
```

**Write immediately** after the user accepts or overrides the decision. Do not batch.

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

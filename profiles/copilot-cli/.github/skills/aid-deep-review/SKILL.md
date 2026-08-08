---
name: aid-deep-review
description: "The graded adversarial review, callable by any skill. Dispatches aid-reviewer against a resolved rule set, reconciles findings into the durable ledger, gates on open criteria gaps, grades, and runs the FIX loop to the caller's minimum grade. This is the pass a quality gate reads."
allowed-tools: Read, Glob, Grep, shell, Task
---

# /aid-deep-review

**The expensive pass, extracted once so nine callers stop each carrying their own copy.**

Every pipeline skill needed the same machinery: render a brief, dispatch the reviewer, hold a ledger,
gate, grade, loop on FIX, stop at a minimum grade. Nine copies meant nine places to drift — and they
had drifted, in ways this work spent several deliveries repairing.

## States

### 1. RESOLVE

Read the invocation manifest (`reviewer-brief-template.md` § invocation manifest). Every field except
`gap_depth` is required; a missing one is a caller error, not something to infer.

1. **Resolve the rule set** through `review-rubrics/INDEX.md`, in its stated order: exact route →
   family fallback → criteria gap. A class with no exact route uses its **family's** rules and records
   the missing class rule set as a non-blocking gap. If no family fits either, raise a blocking gap and
   halt — do not reach for the nearest-looking rule set.
2. **Pick the scratch ledger path.** `<scope>-cycle<N>.md`. Its presence decides the mode: present →
   `resume` (same attempt), absent → `new-cycle`. One `test -f`, not a flag.
3. **Subtract settled gaps.** `gap-register.sh --resolved-keys` — anything `Answered`, `Declined` or
   `Superseded` must not be raised again. A recorded "no" that gets re-asked is the failure the register
   exists to prevent.
4. **Plan the resume**, if resuming: `plan-resume.sh --ledger <scratch>` and apply its verdicts with
   `writeback-ledger.sh --set-status`. Keep what it says to keep.
5. **Validate the settings file, then resolve the minimum grade.**

   ```bash
   bash .github/aid/scripts/config/lint-settings.sh --file .aid/settings.yml --quiet
   bash .github/aid/scripts/config/read-setting.sh --skill <caller> --key minimum_grade
   ```

   Never hardcode the bar; a caller's configured bar is the caller's to set.

   **Why validate here, at consumption.** This is the moment the bar is used, so it is the moment a bad
   value does damage. `read-setting.sh` returns whatever string it finds — a typo like `A1` is not a
   grade, so the comparison against the computed grade never succeeds honestly, and the gate either
   never passes or never blocks. Neither failure announces itself. Checking here catches a hand-edit
   made long after `/aid-config` ran, which is exactly when a bar gets loosened.

   Exit 1 means the settings file is invalid: **halt and report it**. Do not fall back to a default bar
   — silently substituting one is how a gate gets quietly lowered.

6. **Print the resolved bar** in the gate's output: `bar = <grade> (from .aid/settings.yml)`. A gate that
   does not say what it is enforcing cannot be audited, and this is what makes a loosened bar visible
   without needing a settings-history mechanism.

### 2. DISPATCH

Render the brief from the manifest plus the caller's two sections, then dispatch **`aid-reviewer`**
(`subagent_type: aid-reviewer`).

**Tier:** the manifest's, defaulting `medium`. Escalate to **large** where the executor was large —
the reviewer-tier ≥ executor-tier invariant. A large executor graded by a medium reviewer is the
invariant's whole failure case.

**Clean context is structural here, not instructional.** Pass the *scratch* path only. Never pass the
durable ledger path, a prior grade, a prior cycle's findings, or the executor's working notes. There is
no rule for the reviewer to remember, because the prior verdict is not reachable.

For a **resume**, the same scratch is passed — the reviewer sees its own coverage and continues.

### 2b. DISPATCH — panel mode

Some artifacts are reviewed by **several mandates at once**, each asking a different question and each
permitted to see a *different* surface. A KB review is the case that forced this: correctness, anatomy,
teach-back and act-back are four genuinely different reviews, and two of them are only meaningful if the
reviewer is denied the sources.

A single-reviewer dispatch cannot express that, so the manifest may declare mandates:

```yaml
mandates:
  - id: M1                    # namespaces this mandate's row IDs: M1-007, U-M1-004
    rule_set: KB
    surface: [.aid/knowledge/*.md]        # what this mandate MAY see -- a whitelist
    ledger: .aid/.temp/review-pending/discovery-M1-cycle1.md
  - id: M3
    rule_set: KB
    surface: [.aid/knowledge/*.md]        # NOT the sources -- see below
    deny:    [src/**, .aid/generated/**]  # what it must NOT see, stated explicitly
    ledger: .aid/.temp/review-pending/discovery-M3-cycle1.md
```

**`surface` and `deny` are the point, not decoration.** A mandate that reconstructs meaning from the KB
alone is worthless if the reviewer can read the source it is meant to be tested against. Denial has to
be enforced at dispatch — you cannot ask an agent to un-see a file it was given.

**Rules that fall out, none of them new:**

- **One scratch per mandate.** Each writes only its own, so no two mandates can collide on a row ID.
  Their `U-`/`G-` IDs are namespaced (`U-M1-004`), which is why the ID grammar has a namespace segment.
- **Mandates may run in parallel or be collapsed** into fewer dispatches when parallelism is
  unavailable — a scheduling choice, never a semantic one. Collapsing two mandates into one dispatch is
  only legal when their `surface` and `deny` sets are identical; otherwise collapsing would hand a
  mandate a surface it was denied.
- **The gap gate reads across every scratch.** `check-gaps.sh --ledger A --ledger B ...` — repeated
  `--ledger` exists for exactly this, because gap rows are never merged and would otherwise be deleted
  before anyone read them.
- **RECONCILE merges findings only.** `U-` and `G-` rows stay in their mandate's scratch. Merging
  coverage would imply the panel had one coverage frontier when it has one per mandate; merging gaps
  would duplicate a gap two mandates both found.
- **One grade, over the merged canonical ledger.** Not one grade per mandate. The artifact gets a
  verdict, not four.

Everything after this point — RECONCILE, GATE, GRADE, FIX — is unchanged. A panel differs in how
findings are *produced*, not in how they are reconciled, gated or graded.

### 3. RECONCILE

**The orchestrator's job, never the reviewer's.** Join scratch → durable on `(Doc, Rule)`:

| Durable row | Key in scratch? | Result |
|---|---|---|
| `Pending` | yes | stays `Pending` — severity and description are authorial |
| `Pending` | no, **and** the unit covering `Doc` is `Examined` | → `Fixed` |
| `Pending` | no, and the unit is **not** `Examined` | stays `Pending` — **absence proves nothing** |
| `Fixed` | yes | → `Recurred` |
| `Accepted` / `OOS` / `Invalid` | either | never auto-changed; a re-find is narrated |
| — | absent from durable | append as a new finding |

The coverage guard on row 3 is why an interrupted cycle can no longer silently clear findings it never
reached.

**In panel mode, join across every mandate's scratch.** A finding two mandates both raise is one row,
deduped on `(Doc, Rule)` — which is also why the key is not the row ID: two mandates produce `M1-007`
and `M3-004` for the same defect, and an ID-keyed join would record it twice.

Then **promote every `G-` key** to the criteria-gap register — before anything is deleted. The scratch
dies at merge; the register is git-tracked and outlives it.

### 4. GATE

```bash
bash .github/aid/scripts/review/check-gaps.sh --ledger <durable>   # 0 clean, 1 open criteria gap
```

Exit 1 → **do not grade.** Batch the open gaps, ask the user **once** for the whole set, promote the
answers, then re-run. A gap means there is no rule to judge by; grading anyway would either invent a
criterion or score against nothing.

`--ledger` repeats, for a panel whose mandates each wrote their own scratch.

### 5. GRADE

```bash
bash .github/aid/scripts/grade.sh --explain <durable>
```

Only reachable on gate exit 0. The script computes the letter; **nothing here does.**

Compare against the resolved minimum:

- **at or above** → DONE.
- **below** → FIX.

### 6. FIX

Dispatch the caller's own executor agent — not the reviewer — over the `Pending` and `Recurred` rows.
The fixer addresses; it never marks a row `Fixed`. That is reconciliation's job on the next cycle, and
the separation is what keeps a fixer from grading itself.

Then a new cycle: fresh scratch, coverage empty (correct — a new attempt re-examines everything), back
to DISPATCH.

**Circuit breaker: the grade does not improve after 3 consecutive cycles.** Then stop, write an
`IMPEDIMENT`, and set the caller's lifecycle `Blocked`. Three cycles that do not move the grade are a
signal about the criteria or the artifact, not a reason for a fourth.

The condition is **non-improvement**, not a cycle count. A loop that is still converging — each cycle
closing more than it opens, the grade climbing — has not tripped anything and must not be stopped at
an arbitrary third pass. A loop returning the same grade three times running has stopped being a
review and become a ritual. This is the wording `pipeline-contracts.md § Circuit breaker (Execute)`
declares and `aid-execute/references/state-fix.md` repeats; stating it as a flat "3 cycles" here made
this skill say something different from both while a contract test that searched for the phrase
rather than the condition reported the contract as holding.

### 7. DONE

Report the grade, the cycle count, and any gap keys still `Pending` in the register. Delete the durable
ledger and any scratch — **after** the gap keys are promoted.

Hand control back to the caller. This is a **terminal hand-off under the existing CHAIN advance type**,
not a new advance pattern.

## What stays with the caller

Extracted here is the *machinery*. What remains the caller's:

- **Its two brief sections** — what its artifact is graded for, and what is out of scope.
- **Its executor agent** for FIX. Only the caller knows who writes its artifacts.
- **Its minimum grade**, via settings.
- **Its state machine.** This skill is called and returns; it does not own the caller's phase.

## Why one skill and not a flag on the light one

They differ in tools, in agent, in output, and in obligation — and one of them writes a graded ledger
while the other must not. A single skill with a `depth` flag would put both behaviours behind one
entry point, and the failure mode is silent: a mis-set flag produces a screen where a grade was
expected, and nothing downstream can tell.

## See also

- [`aid-light-review`](../aid-light-review/SKILL.md) — the cheap pass that may precede this one
- `.github/aid/templates/reviewer-brief-template.md` — brief and manifest
- `.github/aid/templates/review-rubrics/INDEX.md` — rule-set routing
- `.github/aid/templates/criteria-gap-protocol.md` — the gate and the register
- `.github/aid/templates/reviewer-ledger-schema.md` — the ledger and reconciliation

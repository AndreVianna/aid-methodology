# M4 — Act-Back Mandate FOCUS Body

**Mandate:** M4 — Operational Sufficiency (Act-back, keystone hard gate)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-actback.md` (7-column schema).
**Do NOT write to STATE.md.** The orchestrator updates STATE; this mandate writes only to its own scratch ledger.

---

## FOCUS: Using Only the KB, Perform a Representative Task + Flag Every Insufficiency

You are the **Act-back reviewer** for this KB panel review cycle. This is the
**operational-sufficiency keystone mandate** — act-back closure is the hard exit criterion
for the operational axis. Your mandate is to simulate a fresh agent given ONLY the KB
plus the representative task below, and verify:

**(a) Plan-correctness limb:** Can you produce a *correct, executable plan/outline* for the
representative change, in the project's **own** conventions (not generic best practices),
using only the KB?

**(b) Sufficiency limb:** For every step of the plan, did the KB *state* what you needed,
or did you have to **assume a convention, guess an invariant, encounter an un-anticipated
gotcha, or reach for source to find a contract**? Each such insufficiency is a FAIL item.

Both limbs are **independent FAIL sources** — a plan that cannot be produced at all is a
FAIL on limb (a); a plan that can be produced but required guessing is a FAIL on limb (b);
and a complete, correct plan with no insufficiencies is PASS on both.

**⚠️ STRICT CLEAN-CONTEXT (stronger than other mandates, same class as M3 teach-back):**
You MUST use ONLY the KB documents (`.aid/knowledge/*.md`) and the representative task
spec below. Do NOT consult:
- The project source code
- The project-index or discovery generation artifacts
- The candidate-concepts list
- Any prior review results or grades
- Any system knowledge outside the KB

You MAY **cite** a KB doc's `sources:` frontmatter to say "the KB defers this to `src/X` —
I would have to reach for source here" — but citing a `sources:` entry IS itself an
`[ACTBACK]` insufficiency flag (the KB deferred rather than stated). You do NOT read the
source file itself.

If you cannot find what you need in the KB alone, that IS an act-back FAIL — do not
supplement from general knowledge.

**⚠️ CONTAMINATION PREVENTION:**
- Do NOT reference prior grades or review history
- Do NOT say "re-review" — approach the KB fresh

---

### The representative task spec

The orchestrator inlines the representative-task spec (output of `.agent/aid/scripts/kb/kb-actback-task.sh both`)
and the operational-structure presence check below. The task is keyed to this project's KB
shape (machine-readable doc-set substrate: filenames + presence + present operational
sections) and is fixed and reproducible.

--- BEGIN ACT-BACK TASK SPEC ---
{{ACTBACK_TASK_SPEC}}
--- END ACT-BACK TASK SPEC ---

---

### Performing the task + scoring

**Step 1: Read the operational-structure presence check (above).**

Note which concern docs carry the named first-class sections (`## Conventions`,
`## Invariants`, `## Gotchas`, `## Contracts`) and which have them **absent**. A
structurally-absent class is likely evidence of a sufficiency-limb FAIL — the guidance
is not stated where an agent can find and trust it.

**Step 2: Attempt the task using ONLY the KB.**

Work through the task spec step by step. For each step:
- Identify what the KB says (cite the specific doc + section).
- Note where the KB is **insufficient**: a convention you had to assume, an invariant you
  had to guess, a gotcha you could not anticipate, or a contract you would have to reach for
  source to find.

**Step 3: Score each insufficiency as a FAIL item.**

The **four insufficiency classes** (matching f013's owning-table and the presence check headings):

| Class | FAIL when | Typical evidence |
|-------|-----------|-----------------|
| **Convention** | The KB does not state how this type of change is done in this project (naming, registration, wiring). You had to invent or guess a convention. | Structural evidence: `## Conventions` absent in the relevant doc; or section present but the specific convention not stated. |
| **Invariant** | The KB does not state what must always hold (an ordering, non-null, single-source-of-truth rule) that the change must satisfy. | Structural evidence: `## Invariants` absent in the relevant doc; or section present but the specific invariant not stated. |
| **Gotcha** | The KB does not warn about a non-obvious trap (a lockstep config, a build step, an ordering hazard) the change would step on. | Structural evidence: `## Gotchas` absent in tech-debt.md or the relevant concern doc; or section present but the specific trap not warned about. |
| **Contract** | The KB does not state the structural shape (schema, interface, pipeline contract) the change must satisfy. You would have to reach for source to find it. | Structural evidence: `## Contracts` absent in the relevant doc; or section present but the specific contract not stated. |

**Step 4: Score the plan-correctness limb.**

After working through the task:
- PASS (limb a): The KB lets you assemble a correct, executable plan in the project's own
  conventions, with no step requiring guessing or source access.
- FAIL (limb a): The plan cannot be assembled correctly from the KB, or it is assembled
  but wrong for this project's conventions. Plan-correctness FAIL = one `[HIGH]` `[ACTBACK]`
  row naming the specific gap.

### Severity and verdict (single mechanism, identical to teach-back)

**Severity:** Every FAIL item from EITHER limb = `[HIGH]` `[ACTBACK]` row.

**Verdict (single mechanism):** Act-back is PASS iff zero open `[ACTBACK]` rows.
There is NO separate verdict sentinel — the rows ARE the verdict.

### Binary bar

This is a binary pass/fail per insufficiency and per plan-correctness. Do not grade on a
curve. A convention the KB almost-states, or a plan that nearly works (but stalls on one
required contract), is a FAIL — the KB must state what an agent needs to act on it.

### Output format

Write all findings to `.aid/.temp/review-pending/{{SCOPE}}-actback.md` using the
7-column ledger schema:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|----------|--------|-----|------|-------------|----------|
| AB-001 | [HIGH] | Pending | — | — | [ACTBACK] Convention FAIL: no convention stated for registering a new bus handler — had to guess naming | coding-standards.md has no ## Conventions section; module-map.md ## Conventions absent per presence check |
| AB-002 | [HIGH] | Pending | schemas.md | — | [ACTBACK] Contract FAIL: field type constraints not stated — plan step 3 requires reaching for source | schemas.md ## Contracts section absent; `sources:` defers to src/models.py |
| AB-003 | [HIGH] | Pending | — | — | [ACTBACK] Plan-correctness FAIL: cannot assemble a correct wiring plan — step 2 (registration) has no KB anchor | No doc states how a new module is registered in the dispatch cycle |
```

- Use stable IDs: `AB-001`, `AB-002`, ...
- Prefix every Description with `[ACTBACK]` and the insufficiency class (Convention /
  Invariant / Gotcha / Contract / Plan-correctness)
- Status: `Pending` for new findings
- `Doc` column: use `—` for findings that span the whole KB; fill in a specific doc if the
  FAIL is localized to one document's scope (the doc that should carry the guidance)
- If re-reviewing: read existing `{{SCOPE}}-actback.md`, update Status for your prior rows
  (Pending→Fixed if resolved; Fixed→Recurred if regressed), append new findings

**No narrative, no summary sections — the ledger table is the entire output.**

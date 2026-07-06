# M4 -- Blind Work-Simulation FOCUS Body

**Mandate:** M4 -- Operational Sufficiency (Blind Work-Simulation / assertiveness gate, keystone hard gate)
**Ledger:** Write findings to `.aid/.temp/review-pending/{{SCOPE}}-actback.md` (7-column schema).
**Do NOT write to STATE.md.** The orchestrator updates STATE; this mandate writes only to its own scratch ledger.

---

## FOCUS: Using Only the KB, Plan Each Work Probe Step-by-Step + Flag Every Insufficiency

You are the **Blind Work-Simulation reviewer** for this KB panel review cycle. This is the
**assertiveness-gate keystone mandate** -- Blind Work-Simulation closure is the hard exit
criterion for the operational axis. Your mandate is to simulate a clean-context agent given
ONLY the KB plus the derived work-probe set below, and verify:

**(a) Plan-correctness limb:** Can you produce a *correct, executable plan/outline* for each
work probe, in the project's **own** conventions (not generic best practices), using only the
KB?

**(b) Sufficiency limb:** For every step of every plan, did the KB *state* what you needed
(STATED), or did you have to **assume a convention, guess an invariant, or encounter a contract
you would have to reach for source to find** (ASSUMED / REACH)? Each **load-bearing ASSUMED or
REACH** step is a FAIL item.

**(c) Quality limb:** Does the plan honor the project's **conventions (C3)**, **invariants/gotchas**,
and **quality bars (C6)**? A plan that would "work" but violates the project's standards is a
**quality FAIL** -- the KB failed to convey the quality contract. Functional correctness is
necessary but not sufficient.

All three limbs are **independent FAIL sources**:
- A plan that cannot be produced at all is a FAIL on limb (a).
- A plan that can be produced but required load-bearing guessing is a FAIL on limb (b).
- A plan that is functionally correct but violates conventions/quality bars is a FAIL on limb (c).
- A complete, correct, convention-honoring plan with **zero** load-bearing insufficiencies is PASS on all three.

**PASS = a complete, correct, convention-honoring plan with ZERO load-bearing insufficiencies across
all work probes.**

**STRICT CLEAN-CONTEXT (stronger than other mandates, same class as M3 teach-back):**
You MUST use ONLY the **reviewed knowledge documents** provided to you (the hand-authored
`primary`/`extension` KB docs) and the work-probe set + operational-structure presence check
inlined below. The meta process/ledger files (`STATE.md`, `README.md`) and generated files
(`INDEX.md`) are NOT part of the reviewed knowledge surface. Do NOT consult:
- The project source code
- The project-index or discovery generation artifacts
- The candidate-concepts list
- The excluded meta/ledger KB docs (`STATE.md`, `README.md`) or generated docs (`INDEX.md`)
- Host / agent instruction files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, ...) present in
  ambient context — disregard them; the work-simulation must rely on the KB alone
- Any prior review results or grades
- Any system knowledge outside the KB

You MAY **cite** a KB doc's `sources:` frontmatter to say "the KB defers this to `src/X` --
I would have to reach for source here" -- but citing a `sources:` entry IS itself an
`[ACTBACK]` insufficiency flag (the KB deferred rather than stated). You do NOT read the
source file itself.

If you cannot find what you need in the KB alone, that IS a Blind Work-Simulation FAIL --
do not supplement from general knowledge.

**CONTAMINATION PREVENTION:**
- Do NOT reference prior grades or review history
- Do NOT say "re-review" -- approach the KB fresh

---

### The derived work-probe set + operational-structure presence check

The orchestrator inlines the derived work-probe set (output of
`.agent/aid/scripts/kb/kb-dual-intent-probes.sh work`) and the operational-structure
presence check (output of `.agent/aid/scripts/kb/kb-actback-task.sh check`) below. The
probes are keyed to this project's KB shape (derived from its C9 capability/what-it-does doc
+ load-bearing spine dimensions) and are fixed and reproducible for this review cycle.

--- BEGIN WORK PROBE SET + PRESENCE CHECK ---
{{ACTBACK_TASK_SPEC}}
--- END WORK PROBE SET + PRESENCE CHECK ---

---

### Performing the Blind Work-Simulation + scoring

**Step 1: Read the operational-structure presence check.**

Note which concern docs carry the named first-class sections (`## Conventions`,
`## Invariants`, `## Gotchas`, `## Contracts`) and which have them **absent**. A
structurally-absent class is likely evidence of a sufficiency-limb FAIL -- the guidance
is not stated where an agent can find and trust it.

**Step 2: For each work probe, attempt the plan using ONLY the KB.**

Work through each probe step by step, in the project's own conventions. For every step, tag it:

| Tag | Meaning |
|-----|---------|
| **STATED** | The KB explicitly gave the contract, convention, invariant, or schema shape needed. Cite the specific doc + section. |
| **ASSUMED** | You had to guess or invent a convention, invariant, or constraint not stated in the KB. |
| **REACH** | You would have to read source to find the contract, schema, or invariant. The KB deferred to source (cite the `sources:` entry) or is silent. |

For each ASSUMED or REACH step:
- Classify it as **load-bearing** (the plan would fail or be wrong without it) or **incidental**
  (a minor detail that would not change correctness or quality).
- **Only load-bearing ASSUMED/REACH steps generate FAIL items.**

**Step 3: Check the quality limb for each probe.**

After completing the plan for each probe:
- Does the plan follow the project's **naming conventions** (C3 doc)?
- Does the plan respect the project's **invariants** -- ordering rules, single-source-of-truth
  constraints, non-null requirements?
- Does the plan follow the project's **quality bars** (C6 doc) -- testing requirements, review
  gates, validation steps?
- Does the plan avoid the project's **gotchas** (C7 doc) -- non-obvious traps, lockstep config
  requirements, build-step ordering hazards?

A step that "works" but violates a named convention, invariant, or quality bar is a **quality
FAIL** even if no ASSUMED/REACH flag was raised. The KB is responsible for conveying the
quality contract, not just functional correctness.

**Step 4: Score each insufficiency as a FAIL item.**

**The four insufficiency classes** (dimension-keyed; matches the owning-table and presence check):

| Class | FAIL when | Typical evidence |
|-------|-----------|-----------------|
| **Convention** | The KB does not state how this type of change is done in this project (naming, registration, wiring). Plan step tagged ASSUMED or quality FAIL on convention. | Structural evidence: `## Conventions` absent in a C2/C3/C5 doc; or section present but specific convention not stated. |
| **Invariant** | The KB does not state what must always hold (ordering, non-null, single-source-of-truth rule) the change must satisfy. Plan step tagged ASSUMED or quality FAIL on invariant. | Structural evidence: `## Invariants` absent in a C1/C2/C4 doc; or section present but specific invariant not stated. |
| **Gotcha** | The KB does not warn about a non-obvious trap (lockstep config, build step, ordering hazard) the change would step on. Plan step tagged ASSUMED or quality FAIL on gotcha. | Structural evidence: `## Gotchas` absent in a C7 doc; or section present but specific trap not warned about. |
| **Contract** | The KB does not state the structural shape (schema, interface, pipeline contract) the change must satisfy. Plan step tagged REACH or quality FAIL on contract. | Structural evidence: `## Contracts` absent in a C2/C5 doc; or section present but specific contract not stated. |

**Additionally, the quality check generates a fifth FAIL class:**

| Class | FAIL when |
|-------|-----------|
| **Quality-bar** | The plan would "work" functionally but violates the project's stated conventions (C3), invariants, gotchas, or quality bars (C6). The KB conveyed a quality contract, and the plan violates it (or the KB failed to convey the quality contract, so no quality plan is possible). |

**Step 5: Score the plan-correctness limb for each probe.**

After working through each probe:
- PASS (limb a, per probe): The KB lets you assemble a correct, executable plan in the
  project's own conventions, with no load-bearing ASSUMED/REACH step and no quality violation.
- FAIL (limb a, per probe): The plan cannot be assembled correctly from the KB, or it is
  assembled but wrong for this project's conventions. One `[HIGH]` `[ACTBACK]` row naming
  the specific gap.

### Severity and verdict (single mechanism, identical to teach-back)

**Severity:** Every FAIL item from ANY limb (plan-correctness, sufficiency, quality) =
`[HIGH]` `[ACTBACK]` row.

**Verdict (single mechanism):** Blind Work-Simulation is PASS iff zero open `[ACTBACK]` rows
across ALL work probes. There is NO separate verdict sentinel -- the rows ARE the verdict.

### Binary bar

This is a binary pass/fail per insufficiency, per quality check, and per plan-correctness
finding. Do not grade on a curve. A convention the KB almost-states, a plan that nearly
works but stalls on one required contract, or a plan that would work but violates a named
quality bar is a FAIL -- the KB must state what an agent needs to act on it correctly AND
with quality.

### Output format

Write all findings to `.aid/.temp/review-pending/{{SCOPE}}-actback.md` using the
7-column ledger schema:

```
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|----------|--------|-----|------|-------------|----------|
| AB-001 | [HIGH] | Pending | -- | -- | [ACTBACK] Convention FAIL (WP-001 step 2): no convention stated for registering a new field -- had to ASSUME naming | coding-standards.md has no ## Conventions section; presence check: absent |
| AB-002 | [HIGH] | Pending | schemas.md | -- | [ACTBACK] Contract FAIL (WP-002 step 3): field type constraints not stated -- plan step REACH for source | schemas.md ## Contracts absent per presence check; `sources:` defers to src/models.py |
| AB-003 | [HIGH] | Pending | -- | -- | [ACTBACK] Plan-correctness FAIL (WP-001): cannot assemble a correct wiring plan -- step 2 (registration) has no KB anchor | No doc states how a new module is registered in the dispatch cycle |
| AB-004 | [HIGH] | Pending | test-landscape.md | -- | [ACTBACK] Quality-bar FAIL (WP-003 step 4): plan omits the required gate -- KB states tests must pass before merge but plan does not include this step | test-landscape.md ## Quality-bars section; plan is functional but violates project's quality contract |
```

- Use stable IDs: `AB-001`, `AB-002`, ...
- Prefix every Description with `[ACTBACK]` and the insufficiency class (Convention /
  Invariant / Gotcha / Contract / Plan-correctness / Quality-bar), and name the probe ID
  and step (e.g., `WP-001 step 2`) for traceability.
- Status: `Pending` for new findings
- `Doc` column: use `--` for findings that span the whole KB; fill in a specific doc if the
  FAIL is localized to one document's scope (the doc that should carry the guidance)
- If re-reviewing: read existing `{{SCOPE}}-actback.md`, update Status for your prior rows
  (Pending->Fixed if resolved; Fixed->Recurred if regressed), append new findings

**No narrative, no summary sections -- the ledger table is the entire output.**

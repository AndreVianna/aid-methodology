# Criteria Gap Interrupt

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-27 | Feature identified from REQUIREMENTS.md §5.C (FR-C1..C8, C10, C11) and §5.D (FR-D8, FR-D9), §9 (AC-4, AC-5, AC-10) | /aid-define |

## Source

- REQUIREMENTS.md §5 group C — FR-C1, FR-C2, FR-C3, FR-C4, FR-C5, FR-C6, FR-C7, FR-C8, FR-C10, FR-C11
- REQUIREMENTS.md §5 group D — FR-D8, FR-D9
- REQUIREMENTS.md §9 — AC-4, AC-5, AC-10
- REQUIREMENTS.md §2 — problem 3 (there is no way to say "I cannot review this")

## Description

Every row in today's ledger asserts something about the artifact. There is no way to record
"there is no rule to measure this against". So when a reviewer meets Java code and the
project has never written down a Java standard, it invents one — quietly, from whatever it
considers good practice.

This feature makes the gap expressible and then productive. Findings split into two kinds.
Type 1 is about the artifact and can be graded. Type 2 says the review's own preconditions
are missing, and it cannot be graded because there is no yardstick. No grade is computed
while any Type 2 remains open.

When gaps are found they are gathered into one batch rather than interrupting one at a time —
a greenfield project has no standards at all, and per-gap halting would stop dozens of times.
The reviewer proposes options, the calling skill holds the conversation, and the review halts
with the exact command to resolve it. Where the answer goes follows one question: is this
canon for the project, or just this once? Canon goes to the Knowledge Base. One-time goes to
the work's own documents. That single answer picks the target skill, so no judgment is needed.

A refusal is a valid answer, and it gets recorded so it is never asked again — along with two
follow-ups: what to do instead, and whether that decision is canon or one-time.

The feature also draws a boundary the current greenfield handling blurs. Missing *criteria*
halts everywhere, `aid-discover` included. Missing *evidence* does not — a greenfield project
cannot produce as-built evidence for something it has not built, and halting there would
demand the code before the design can be reviewed.

## User Stories

- As a **greenfield adopter**, I want the review to tell me which standard is missing and help me write it, instead of silently grading me against rules I never agreed to.
- As an **adopter project with documentation gaps**, I want review to improve my Knowledge Base as a side effect, so that each review leaves the project better defined.
- As an **AID maintainer**, I want no grade computed while a precondition is missing, so that a grade never means "measured against something I made up".
- As a **greenfield adopter**, I want to be asked once about all my missing standards, not interrupted for each one.
- As an **adopter project**, I want to be able to say "no, don't check that" and have it stick.
- As an **AID maintainer**, I want a gap that keeps recurring to stop the loop by itself, rather than relying on me to notice.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-4** — Given an artifact whose standard is undefined, when it is reviewed, then a Type 2 gap is produced and the review halts before grading; no invented finding appears.
- [ ] **AC-5** — Given a gap answered with "no", when the same review runs again, then the decision is found on record and is not re-asked.
- [ ] **AC-10** — Given the same gap raised twice, when the second occurrence is recorded, then the review halts with a possible-loop flag without user intervention.
- [ ] Given a ledger with an open Type 2 row, when grading is attempted, then no grade is produced.
- [ ] Given several gaps in one review, when they are surfaced, then they arrive as a single batch, not as separate interruptions.
- [ ] Given a gap, when the review halts, then it prints the exact command that resolves it.
- [ ] Given a "canon" answer, when routing is resolved, then the target is the Knowledge Base via `/aid-update-kb`; given a "one-time" answer, then the target is the work's own documents via `/aid-define`, `/aid-specify`, `/aid-plan`, or `/aid-detail`.
- [ ] Given a "no" answer, when it is recorded, then it captures both follow-ups: what to do instead, and one-time versus canon.
- [ ] Given a gap raised while resolving another gap, when recursion is checked, then a depth limit stops it.
- [ ] Given `aid-discover` reviewing with a missing criterion, when the gap is detected, then it halts and asks — there is no relax-and-continue exception.
- [ ] Given a greenfield project with no as-built code, when a design claim cannot be verified against disk, then the review does not halt; evidence substitution applies.
- [ ] Given the reviewer detects a gap, when resolution begins, then the reviewer does not write the fix.

## Notes for Specify

- **FR-D8 and FR-D9 were moved here from group D** (see STATE.md judgment call J3). FR-C7's recursion depth limit is a MUST whose counter lives in the ledger, and the ledger is deleted at skill DONE — so depth cannot survive the FR-C3 halt unless FR-D9's promotion to `STATE.md` carries it. Leaving D9 in feature 5 would close this feature with an unsatisfied MUST, or force a temporary counter that feature 5 then generalises. D8 travels with D9 because loop detection over gap IDs is meaningless without the gaps, and AC-10 would otherwise be verified a feature away from its durability mechanism.
- **FR-C9 is deliberately NOT here.** It names `aid-light-review`, which feature 6 builds. This feature implements gap detection inside the graded pass — and FR-A5 makes that permanent, so it is not throwaway work. Feature 6 then adds the up-front screening pass, reusing this feature's batching, halting and routing unchanged.
- **Requires feature 3 first.** A Type 2 gap needs a `G-NNN` row to live in, and batching needs somewhere to accumulate. Without the substrate, this feature would invent temporary storage that feature 3 replaces.
- The halt is a genuine architectural choice, not a limitation: delegating to a long, human-gated skill like `/aid-update-kb` and resuming in place would nest two approval gates, which nothing in the codebase does. Halt-and-route is the existing idiom (the work-initiation gate and the delivery gate's non-CODE path both use it).
- Verify five-profile render parity at feature close (STATE.md concern N3).

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. Adapted sections — the runtime here is agents
> reading documents plus two shell scripts. Eighteen conditional sections are dropped for want
> of a store, a request flow, a network surface, or a UI.

### 0. Two framing corrections, both load-bearing

**The halt is not a new mechanism — it is `PAUSE-FOR-USER-ACTION`.**
`canonical/aid/templates/state-machine-chaining.md` line 47 already lists *"Run another
`/aid-<other-skill>` first (cross-skill loopback)"* as a sanctioned use of advance type 2, and
lines 80–86 already define the pause's durable footprint (`writeback-state.sh --pipeline
--field Lifecycle --value "Paused-Awaiting-Input"` plus `Pause Reason`). Line 96's *"do not
invent a third pattern"* is satisfied **by citation, not by argument**. And the pattern is
already shipping: `aid-housekeep`'s KB-DELTA (`references/state-kb-delta.md` § Step 4, line
653) writes an `Impact: Required` Q&A entry into `.aid/knowledge/STATE.md` and then routes to
`/aid-discover`. **Register-write-then-route is existing code**, not a proposal.

**FR-C9 stays out of `## Source`.** The count of record is **12 FRs = C1–C8, C10, C11, D8,
D9**. This feature implements FR-C9's *substance* — the up-front batched scan — inside the
existing per-skill REVIEW states, because `aid-light-review` does not exist until feature-006.
Adding FR-C9 to Source would claim a skill that does not exist and change the count of record.
Feature-006 relocates the scan; per FR-A5 that is not rework, because deep review's own gap
detection is permanent.

### 1. The Type 1 / Type 2 model

**Type 2 needs no new carrier.** Feature-003 §1 already ships it: a `G-NNN` row with `--` in
Severity and `--` in Rule, Status `Open | Resolved`.

- **Type 1** = a row whose `#` matches `^([A-Z][A-Z0-9]{0,3}-)?[0-9]{1,4}$`. A finding.
  Bracketed severity. Grade-bearing.
- **Type 2** = a row whose `#` carries the `G-` prefix. Grade-**inert by construction**:
  `grade.sh` lines 207–212 exact-match `cols[3]` against the five bracketed literals and `next`
  on anything else, so a `--` never reaches the status filter at line 215. Feature-003 measured
  this — its §9 fixtures a/b/c/d all grade `D+` with byte-identical `--explain` breakdowns.

So FR-C1 costs no schema change. **The new mechanical work is entirely FR-C2**, and
grade-inertness is the wrong tool for it: an inert row cannot *stop* a grade, only fail to
affect it. The gate must therefore sit outside `grade.sh` — which NFR-1 requires anyway.

**Three discriminators inside `Description`, as a closed enum.** Every gap row's Description
begins with exactly one of:

| Token | Meaning | Blocks the grade? |
|---|---|---|
| `[GAP:CRITERIA]` | No rule in either authority ladder speaks to the concern | **Yes** |
| `[GAP:CRITERIA:NB]` | Same, but the depth limit was reached (§5) or feature-002 §4's family fallback covered it | No |
| `[GAP:EVIDENCE]` | No available evidence can confirm or deny the claim — feature-002 §5's *cannot measure* | No |

This reuses an existing convention rather than inventing one: `aid-discover`'s merge rule 4
(`state-review.md` lines 418–424) already requires every Description to carry a bracketed
marker prefix — its five are `[M1]`, `[M2]`, `[FIDELITY]`, `[ESSENCE-GAP]` and `[ACTBACK]`. It
also needs no ninth
column — REQUIREMENTS.md §4's column set was reopened exactly once, for FR-B10, and reopening
it again would be a second exception.

`[GAP:EVIDENCE]` is how feature-002 §5's *"cannot measure → ask the user"* becomes
implementable at all: a dispatched sub-agent cannot ask, so it records a non-blocking gap and
the batch surfaces it. That is FR-C11's axis in FR-C10's carrier.

### 2. FR-C2's teeth — the pre-grade gate at 18 sites

Every grade site gains a preceding gate:

```bash
bash canonical/aid/scripts/review/check-gaps.sh --ledger <path>   # 0 clean, 1 open criteria gap
bash canonical/aid/scripts/grade.sh --explain <path>              # only reachable on exit 0
```

The site set is reproducible, not asserted:

```bash
grep -rln 'bash canonical/aid/scripts/grade\.sh' canonical/ | wc -l   # measured: 18 files
grep -rn  'bash canonical/aid/scripts/grade\.sh' canonical/ | wc -l   # measured: 19 lines
grep -rn  'check-gaps\.sh' canonical/ | wc -l                        # measured: 0 today
```

Nineteen lines across eighteen files — `aid-define/references/state-cross-reference.md` carries
two (a prose form at line 16, the fenced invocation at line 32). Twelve are fenced or
line-start invocations. Of the remaining seven, **six are inline-backticked forms in `SKILL.md`
files and the seventh is that prose form at `state-cross-reference.md:16`**. One of the eighteen
files is `canonical/aid/templates/shortcut-engine.md` line 778 — **the Lite path grades too**,
and omitting it would leave every shortcut skill able to grade over an open gap.

**Wire all eighteen**, including `aid-summarize`'s VALIDATE and `aid-deploy`'s VERIFYING whose
ledgers are machine-written and cannot produce a `G-` row today. Their call is a cheap exit-0
invariant, and wiring them makes the oracle **total** — a partial wiring needs an exclusion
list, and exclusion lists rot.

### 3. The gap lifecycle

| # | Transition | Owner | Mechanism |
|---|---|---|---|
| 1 | **Detect** | the dispatched `aid-reviewer` | Per-row during its normal pass. No criterion in either ladder → a `G-` row instead of a finding. Feature-001's rule 3 ("no criterion, no finding") is the trigger |
| 2 | **Record** | the reviewer | `writeback-ledger.sh --append-gap --gap-key ...`. Idempotent on the key; a repeat increments `resume=N` |
| 3 | **Batch** | the calling skill's REVIEW state | Formed by **reading** every scratch ledger, never by merging rows into the canonical one |
| 4 | **Subtract** | the calling skill | `gap-register.sh --resolved-keys`. Keys already `Answered` or `Declined` drop out. AC-5's read side |
| 5 | **Propose** | the reviewer, in its **return message** | Proposals never enter the ledger — feature-003's "narrative goes in the return message" rule already forbids it |
| 6 | **Ask** | the calling skill, once for the whole batch | FR-C8. A sub-agent cannot hold the dialogue, so the skill owns it |
| 7 | **Promote** | the calling skill | `gap-register.sh --promote`, **before** anything is deleted or halted. Idempotent on Gap Key |
| 8a | **Loop back** (owning skill == running skill) | the calling skill | CHAIN to its own authoring state. In `aid-discover` that is the existing `Q-AND-A → FIX` path |
| 8b | **Halt and route** (owning skill ≠ running skill) | the calling skill | `PAUSE-FOR-USER-ACTION`: write `Lifecycle` + `Pause Reason`, print the resolution command(s), exit |
| 9 | **Resolve** | the routed skill | `/aid-update-kb` or a definition skill. The reviewer writes nothing (FR-C6) |
| 10 | **Re-invoke → resume** | the user, then the calling skill | Step 4 subtracts the resolved keys; the `U-NNN` coverage manifest resumes rather than restarts |

**Two things this ordering fixes.**

*The batch would otherwise never form.* Feature-003 §7 **excludes** `U-` and `G-` rows from
`aid-discover`'s panel merge — they stay in each mandate's scratch ledger, and step 2e
(`state-review.md` lines 502–529) `rm -f`s those files. Under four parallel mandates the gaps
would be deleted before anyone read them. So `check-gaps.sh` and `gap-register.sh` accept
**repeated `--ledger`** arguments and read *across* scratch ledgers without merging rows:
feature-003's no-cross-mandate-ID-reconciliation property survives, and the canonical ledger
stays purely findings so the essence and act-back derivations (steps 2c/2d) are untouched.

*The join key cannot be the row ID.* Two mandates raising the same gap produce `G-001` in two
namespaces. Dedupe happens on the **Gap Key**, which is also what makes cross-invocation
dedupe (AC-5) and recurrence counting (AC-10) possible at all.

### 4. The gap key and the durable register

**Location, resolved by scope, one accessor:**

| Running scope | Register | Companion |
|---|---|---|
| A work (all pipeline skills, Lite included) | `.aid/works/work-NNN-*/STATE.md` → new `## Criteria Gaps` | — |
| A delivery (`aid-execute` DELIVERY-GATE) | `delivery-NNN/STATE.md` → same section | — |
| The Knowledge Base (`aid-discover`, `aid-update-kb`) | `.aid/knowledge/STATE.md` → same section | an `Impact: Required` entry in `## Q&A (Pending)` |

Both files are git-tracked — verified: `.gitignore` covers `.aid/.temp/`, `.aid/.trash/`,
`.aid/.heartbeat/`, `.aid/.control/`, `.aid/generated/`, `.aid/knowledge/.cache/` and exactly
one work folder (`work-023-ticket-integration`). Neither `.aid/works/*/STATE.md` nor
`.aid/knowledge/STATE.md` is ignored. **That is what makes the record survive both the halt and
the ledger's deletion at DONE.**

**A dedicated section, not the existing Q&A section.** Reusing `## Cross-phase Q&A` was
considered and rejected: it is marked DERIVED with a contested single-writer rule, it holds
prose `### QN` blocks rather than a table, and it carries multiple long-lived `Status: Pending`
entries alongside `Deferred`, `Resolved` and `Partially resolved` ones. The live count is
whatever this returns, and it is deliberately not quoted as a number here:

```bash
awk '/^## Cross-phase Q&A/{f=1} f && /^## Calibration Log/{f=0} f && /\*\*Status:\*\* Pending/' \
    .aid/works/work-003-review-subsystem-redesign/STATE.md | wc -l
```

A gap that gates a grade cannot share a section with entries that are *designed* to sit Pending
for weeks. A table is also what `writeback-state.sh` already edits surgically
(`--append-issue`, `--gate-field`), so the writer follows a proven pattern.

For the KB scope the **companion `Impact: Required` Q&A entry** is written too, copying
`aid-housekeep`'s Step 4. That makes the existing `Q-AND-A` state pick the gap up with **zero
change to that state**: `state-q-and-a.md` lines 3–7 already drive every Pending entry to a
terminal answer, and lines 55–59 already make APPROVAL unreachable while any remains.

**Schema — eight columns, mirroring the ledger, with the ledger's `\|` escape:**

```
| Gap Key | Kind | Status | Depth | Recurrences | Scope | Criterion | Resolution |
```

| Cell | Contract |
|---|---|
| **Gap Key** | `^[a-z0-9][a-z0-9./-]{2,63}$`. Content-derived: `<artifact-class>/<missing-criterion-slug>`, e.g. `code-sh/coding-standard`. **MUST NOT contain a row ID, cycle number, date, or a movable path** — any of those breaks dedupe, which breaks AC-5 and AC-10 together |
| **Kind** | `criteria` \| `evidence`. Mirrors the Description token. Only `criteria` gates |
| **Status** | `Pending` \| `Answered` \| `Declined` \| `Superseded`. `Declined` is FR-C5's "no" |
| **Depth** | `0`–`2`. The gap-resolution chain length (§5) |
| **Recurrences** | Integer. Incremented **only** when a previously `Answered`/`Declined` key returns — never while still `Pending` |
| **Scope** | The artifact or doc-set whose review stalled |
| **Criterion** | One sentence: which criterion is missing |
| **Resolution** | Pending → the printed route command. Answered → `canon → <doc>` or `one-time → <doc>`. Declined → `declined; instead: <what-to-do-instead>; canon\|one-time` — **both** FR-C5 follow-ups in one cell |

**How AC-5 reads it.** `--resolved-keys` prints every key whose Status is `Answered`,
`Declined` or `Superseded`; step 4 subtracts that set. There is a **second, structural layer**:
a "no" answered as canon becomes a *declared rule* ("this project does not check X"), and a
declared rule means the next reviewer finds no gap at all. The mechanical subtraction covers
the window before the declaration lands; the declaration covers everything after.

**How FR-C7 reads it.** The `Depth` cell is the counter. It does not depend on a SHOULD,
because **FR-D9 was promoted to MUST and is owned by this feature** — three of this feature's
acceptance criteria rest on the promotion.

**One real hazard, named.** `/aid-update-kb`'s Pre-flight creates its worktree **off `master`**
(`SKILL.md` §2b — its text uses a double hyphen, not an em-dash:
`No live run found -- create a fresh worktree off `master``), not off the caller's branch. So a canon-route resolution lands on `master` and the caller's worktree does
not see the new criterion until it merges. Two consequences:

1. The gap brief and depth **must** ride in `/aid-update-kb`'s free-text argument, because the
   register write is invisible across that boundary. Not a preference: of the five routing
   targets, **only `/aid-update-kb` takes free text** — `/aid-define`, `/aid-specify`,
   `/aid-plan` and `/aid-detail` take a work or feature id plus flags. The four
   work-document routes pass their brief through the register (same worktree, so it works);
   the canon route passes it through the prompt.
2. A caller who re-invokes before merging re-raises the same gap. The
   increments-only-after-resolution rule is what stops that being misread as a loop, and the
   printed halt text carries an explicit merge line.

### 5. Restricted mode and the depth limit

**Restricted mode is a fourth injectable parameter on an existing seam.** `aid-update-kb`'s
REVIEW *is* `aid-discover`'s REVIEW — it invokes
`canonical/skills/aid-discover/references/state-review.md` with `{{SCOPE}} = update-kb` and
follows the panel "WITHOUT modification (AC-7)". So a gap-resolution review already has one
code path, and it already has a precedent for a mode block: `{{GREENFIELD_BLOCK}}`. Add
`{{GAP_DEPTH}}` alongside it, rendered as a `GAP-RESOLUTION MODE` block in the same shape.

**Four restrictions:**

1. **Scope lock.** A criteria gap may only be raised about an artifact in `{{ARTIFACTS}}`. An
   out-of-scope observation is an `OOS` finding or a `[GAP:EVIDENCE]` row — never a blocking
   gap. Without this, resolving one gap can discover the whole KB.
2. **Fallback before halt.** At depth ≥ 1, where feature-002 §4's family rules cover the
   concern they are *used*, and the missing class rule set is recorded `[GAP:CRITERIA:NB]`.
   Family rules are declared rules, so no invention occurs.
3. **Depth cap.** At depth = 2, `[GAP:CRITERIA]` is written as `[GAP:CRITERIA:NB]`, the run
   proceeds to grade, and the register records `Depth: 2` with `Status: Pending` so the human
   sees it when the chain unwinds. **The cap demotes; it never discards.**
4. **No self-route.** An `/aid-update-kb` run may not print a canon route to
   `/aid-update-kb`; it uses its own `CONFIRM → APPLY` loopback. Without this the recursion is
   structural rather than depth-bounded — and it would nest worktrees, since ISOLATE creates
   one per run.

**Depth limit: 2.** Depth 0 is the original review, 1 is resolving its gap, 2 is a gap raised
while resolving a gap — STATE.md Q5(b)'s named case, *a gap in the very standard being
authored*, legitimate exactly once. Each level costs a full human-gated skill run:
`/aid-update-kb` alone carries **two** human gates (CONFIRM before any edit, APPROVAL before
commit) plus its own FIX loop. Three stacked runs already exceed what any existing AID flow
asks in one sitting; a fourth is a bug, not a workflow. Needing depth 3 means the KB has a
structural hole belonging to a full `/aid-discover` — and demoting to non-blocking says exactly
that, in the register, where a human reads it.

### 6. Criteria versus evidence — the greenfield split

`document-expectations.md` `## Greenfield Mode` (lines 13–68) has three sub-blocks. Read against
FR-C10/C11, **all three are evidence-shaped except one clause.**

**Retained as evidence-substitution (FR-C11), behaviour unchanged:**

| Site | Today | Why it is evidence, not criteria |
|---|---|---|
| 26–27 | C3 depth standard: "concrete example from this project's code" → "from intended use" | The criterion (state the project's own rules) stands; only the artifact holding the example is absent |
| 28–29 | `architecture.md`: "ground every claim in a file or path" → "in a confirmed requirement" | The grounding *requirement* is untouched; the grounding *source* shifts |
| 30–31 | C4 depth standard: "where it lives in the code" → "in the intended design" | Same |
| 41–44 | C0 / `technology-stack.md`: "Version TBD" and a missing build command ACCEPTED | The criterion (name every language, framework, runtime **with its version**) is fully in force. The version is an unavailable *fact* |
| 45–49 | C1 / `architecture.md`: generic descriptions without file paths RELAXED; `project-structure.md` excluded | Paths do not exist yet. **One tightening:** the `project-structure.md` exclusion is recorded as a `U-NNN` row with Status `Skipped` and its reason, so the exclusion is *declared* rather than silent |
| 56–68 | Dimension floors retained | Already at full strength. No change |

**The one clause that splits — lines 50–52, C3 / `coding-standards.md`.** Today: *"A convention
named but no example from code" is ACCEPTED when the doc declares "standard for `<stack>`, no
project-specific deviations yet".* The acceptance is conditioned on a declaration, which is
right — but the declaration is not required to be *resolvable*, and an unresolvable "the
stack's standard" is precisely FR-B3's "established best practice" with a declaration wrapped
around it. So:

- **The declaration names a resolvable standard** — a URL, a document, or a linter/formatter
  config present in the repo → **a criterion exists.** The missing code example is an evidence
  gap; acceptance holds and the reviewer records the citation in Evidence.
- **The declaration names nothing resolvable** ("standard for Bash", or silence) → **no
  criterion.** A halting `[GAP:CRITERIA]` row, routed to whichever skill owns
  `coding-standards.md`.

This is the **only** behavioural change to greenfield mode, and the only place today's mode
admits an invented criterion.

It also picks up an inbound hand-off that would otherwise be orphaned: feature-001 §5 states
that a **missing modality** on an FR or AC "makes a missing modality a *precondition gap*
rather than a finding — Type 2 territory, and Type 2 is feature-004." Once this feature lands, a
modality-free rule in a work spec document under review is a `[GAP:CRITERIA]` gap routed to the
owning definition skill; `lint-modality.sh` remains the authoring-time gate.

**Considered and deliberately NOT converted to gaps**, stated so a reviewer sees each was
examined:

- **The discovery-triage greenfield panel skip** (`state-review.md` lines 140–144). A project
  classified greenfield at Step 0f has no extracted KB, so the panel is skipped. That is an
  **empty artifact set**, not a missing criterion — FR-C10 has nothing to bite on. The
  seed-review path (`greenfield: true`) is a distinct entry point that already traverses the
  full panel, and that is where the split above applies.
- **The graceful degradations** at `state-review.md` lines 33–36, 50–51 and 78–82 (absent
  `candidate-concepts.md` → empty oracle output; no C4/C9/D docs → the fixed probe only).
  Missing evidence *inputs*. Retained.
- **`read-setting.sh --default A`** for `minimum_grade`. A declared default, not an absence.
- **An unmapped spine dimension.** Proposed as a hole and then disproved:
  `domain-doc-matrix.md` line 336 makes the `auto-researched` provenance map every proposed doc
  to a spine dimension, user-confirmed, before it enters `discovery.doc_set`. The mapping is
  total by construction. **Claim dropped.**

**The general-purpose invention licence, outside greenfield.** `reviewer-dispatch.md` lines
133–134 say *"When no pre-defined rubric exists (one-off reviews like Phase A foundation), the
brief enumerates the checks inline"*; § One-off reviews (209–214) generalises it to every
hand-crafted brief; the worked example instantiates it at 247–248. An inline-enumerated check
is neither a KB rule nor a work spec rule, so FR-B2 forbids it. After feature-002's catalog
exists, no rubric means: family fallback → non-blocking class gap; no family fit → blocking
criteria gap. These three regions are unclaimed by features 001–003 and are this feature's
business, because the *reason* to delete the licence is "no criterion, no finding".

### 7. Affected-artifact inventory and region ownership

In `aid-reviewer/AGENT.md` the union of prior claims is **3, 17, 31, 36, 39–57, 59–67, 69–74,
75, 76–79, 81–95, 96–99, 100–103** — every **content** line from 39 to 103, plus 3, 17, 31, 36.
Lines **58, 68 and 80 are blank separators** that no feature claims, which is why the union is
expressed as ranges rather than as a single span. What remains unclaimed is 1–38 minus those,
and 104–108.

**New files (3):**

| File | Content |
|---|---|
| `canonical/aid/scripts/review/check-gaps.sh` | Read-only gate. Exit `0` clean / `1` open criteria gap / `2` usage |
| `canonical/aid/scripts/review/gap-register.sh` | `--promote`, `--resolved-keys`, `--depth`. Codes per `writeback-state.sh` |
| `tests/canonical/test-criteria-gaps.sh` | §9's suite. `run-all.sh` globs; `coverage-parity.sh` fails only on reduced assertions, so both are gate-clean |

**Two scripts, not one, and the reason is a KB rule.** `.aid/knowledge/coding-standards.md`
lines 226–229 declares the conventions — *"Linters use `0` clean, `1` violations, `2` usage"*
and *"A new failure mode SHOULD reuse an existing code with matching semantics rather than
inventing a new one."* A gate must follow the linter scheme; a STATE writer must follow
`writeback-state.sh`'s (where `1` is unreadable and `2` is lock contention). One script cannot
honour both without a code meaning two things, and the KB forbids inventing a third scheme. The
possible-loop signal therefore rides **stdout**, not a new exit code — one line per open gap,
`OPEN|LOOP <tab> <gap-key> <tab> <recurrences> <tab> <route>` — matching the declared
convention that stdout carries the result and stderr the diagnostics.

Both land in the `review/` directory **feature-003 creates**, so its emission caveat is
inherited: **emission of `review/` must be confirmed by rendering**, because a subdirectory that
has never been emitted has never exercised the directory-level mapping. (A first draft justified
this by calling the rendered manifests *stale*, since they carry `"src": "canonical/scripts/..."`
while the scripts live under `canonical/aid/scripts/`. That was retracted on 2026-07-28:
`render.py` normalizes the manifest `src` field deliberately, "for manifest src stability", so the
value is a stable logical identifier and is correct as generated.)

**Claimed regions:**

| File | Claimed | Change |
|---|---|---|
| `canonical/agents/aid-reviewer/AGENT.md` | **21** | "Add Q&A entries to the relevant STATE file when review findings reveal information gaps" → the gap contract: record a `G-` row via the helper; the calling skill promotes it |
| | **106–107** | The two Q&A-escalation bullets become the criteria-gap route. All three prior features list 105–108 as *not* claimed; **105** (the heading) and **108** ("cannot run tests") are left alone |
| | **insertion after 79** | A new `## Finding Types` section at the seam that features **002 and 003 jointly** open: feature-003 deletes 81–95 and 100–103, feature-002 deletes 96–99. Neither alone clears the range. Claims no existing line |
| `canonical/agents/aid-reviewer/README.md` | **80–81**, **insertion after 34** | Human-facing counterparts. 11, 13, 31, 33 are feature-002's; 63, 66 feature-001's; 52 is Q3(d) and stays |
| `canonical/aid/templates/reviewer-ledger-schema.md` | **141–142** | The `First REVIEW` block: "Orchestrator runs grade.sh" → gate-then-grade; the advance line gains the gap branch. Feature-003's claim here is an *insertion after 139* and it declines 149–157, so 141–142 is free |
| | **insertion after 17**, **insertion after 191** | A `contracts:` line for register-promotion-before-deletion; a new orchestrator `**Always:**` bullet for the gate. Inserting after 191 rather than editing 192 deliberately avoids feature-003's hand-off of 192–194 to feature-005 |
| `canonical/aid/templates/reviewer-dispatch.md` | **133–134**, **209–214**, **247–254** | The inline-check-enumeration licence, in all three places. 122–123 and 170 are prior features'; 43–44, 196, 269 are declined by feature-003. 247–254 is collateral on the same argument 001 and 002 used for theirs |
| `canonical/aid/templates/state-machine-chaining.md` | **insertion after 47** | One line under the cross-skill-loopback bullet naming the gap halt as an instance. **No new advance type**; line 96 is untouched and is the reason for the phrasing |
| `aid-discover/references/document-expectations.md` | **13–19**, **36–54** | The mode header re-framed as criteria-versus-evidence; the split at 50–52. 21–34 and 56–68 stay behaviourally identical, re-labelled only |
| `aid-discover/references/reviewer-brief.md` | **insertion after 20**, **71–94** | The `GAP-RESOLUTION MODE` block and its substitution spec. Line 22's `RUBRIC:` re-point is feature-002's |
| `aid-discover/references/state-review.md` | **7–11**, **insertion after 427**, **575–576** | `{{GAP_DEPTH}}` added to the injectable seam; the gate between 2a and 2b; the Advance line gains the gap branch. Feature-003's claim here is an insertion after 424; 427's `7-column` token is feature-002's |
| `canonical/aid/templates/work-state-template.md` | **insertion after 288** | The `## Criteria Gaps` section and its 8-column schema |
| `canonical/aid/templates/discovery-state-template.md` | **insertion after 80** | Same section, plus the companion-entry convention |
| `.aid/knowledge/quality-gates.md` | additive | The gap gate as a declared gate. 98–100 is feature-001's, 107 feature-002's, "after 122" feature-003's. Carries a Change Log row and a `README.md` revision-history entry |
| `.aid/knowledge/pipeline-contracts.md` | **293–298** | The "every phase that grades uses one deterministic rubric" contract gains "and no grade is computed while a criteria gap is open". Untouched by 001–003 |
| The **six** `reviewer-brief.md` templates | one static section each | `GAP POLICY`, parallel to the existing `OOS FINDINGS POLICY`. Six exist on disk; `aid-describe`'s is the missing seventh `reviewer-dispatch.md` promises, already a Q3 item |
| The **18** grade-site files | one line each | The gate. One (`aid-discover/references/state-review.md`) overlaps the list above |

**Distinct files touched: 37** = 3 new + 12 substantive + 6 briefs + 18 gate sites − **2**
overlaps. Both overlaps are `aid-discover` files that appear in two of the four groups:
`references/state-review.md` (substantive **and** a gate site) and
`references/reviewer-brief.md` (substantive **and** one of the six briefs). The authoritative
list is the union of the table above, not this arithmetic — derive it at implementation time
rather than trusting the count.

**Not claimed, though tempting.** `grade.sh` — no change of any kind, so NFR-1 holds trivially.
`AGENT.md` 8, 20, 33–34.

### 8. Migration, and what replaces the interim `OOS` row

Feature-003 §4 carries an exemption forced by STATE.md Q11 decision 3 — *"a finding row may
carry `--` in `Rule` if and only if its Status is `OOS`"* — with the retirement condition *"when
feature-004 replaces the interim `OOS` row with a `G-NNN` row."* Precisely what happens:

1. **An unmatched artifact class stops being a finding.** It becomes a `G-NNN` row:
   `Severity --`, `Status Open`, `Rule --`, Description
   `[GAP:CRITERIA] no rule set registered for class <X>` (or `[GAP:CRITERIA:NB]` where
   feature-002 §4's family fallback applies), Evidence = the route command plus `resume=N`.
2. **The exemption is deleted, not relaxed.** `--append-finding` rejects `--`, empty, or a
   non-conforming `Rule` with **exit 4 unconditionally**; the `Status == OOS` branch is removed
   from the helper's argument validation. Non-finding rows carry `--` in `Rule` by **row kind**,
   which was never an exemption.
3. **`Status: OOS` survives as a status.** It still means "out of the declared review scope".
   What changes is that an OOS row is still a *finding about an artifact* and must cite the rule
   it would have violated. A rule-less out-of-scope observation is not an OOS finding at all —
   it is a `[GAP:EVIDENCE]` or `[GAP:CRITERIA:NB]` row, non-blocking because it is out of scope.
4. **A hand-off feature-003 must absorb.** Its §9 oracle asserting
   `--append-finding --status OOS --rule --` exits **0** must be **inverted to exit 4** when
   this feature lands. Stated here because the STATE.md Q7 #8 orphan happened once already, by
   nobody writing the hand-off down.

**In-flight rule.** Feature-003 §6 settled it: a review finishes under the shape it started,
and the ledger is deleted at DONE, so there is no migration event. This feature adds one clause:
the register is written **before** deletion, so a halt mid-review loses the ledger but never the
gap. Nothing here changes a cell `grade.sh` reads.

### 9. Verification strategy

Ships as `tests/canonical/test-criteria-gaps.sh`. **Every baseline below was run against the
real tree**, and every count carries its command.

**AC-4 — a gap is produced and the review halts before grading.**

```bash
# (a) TOTALITY: every grade invocation is preceded, in the same file, by the gate.
#     Baseline: 18 files invoke grade.sh; 0 mention check-gaps.sh -> non-trivially false today.
grep -rln 'bash canonical/aid/scripts/grade\.sh' canonical/ | wc -l   # measured: 18
grep -rn  'check-gaps\.sh' canonical/                        | wc -l   # measured: 0

for f in $(grep -rln 'bash canonical/aid/scripts/grade\.sh' canonical/); do
  g=$(grep -n 'check-gaps\.sh'                       "$f" | head -1 | cut -d: -f1)
  d=$(grep -n 'bash canonical/aid/scripts/grade\.sh' "$f" | head -1 | cut -d: -f1)
  { [ -n "$g" ] && [ "$g" -lt "$d" ]; } || fail "$f: grade site not gated"
done

# (b) BEHAVIOUR: the gate fires on an open criteria gap and only on one.
check-gaps.sh --ledger fx-open-criteria.md ; [ $? -eq 1 ]   # [GAP:CRITERIA] Open
check-gaps.sh --ledger fx-nb.md            ; [ $? -eq 0 ]   # [GAP:CRITERIA:NB]
check-gaps.sh --ledger fx-evidence.md      ; [ $? -eq 0 ]   # [GAP:EVIDENCE] -- FR-C11
check-gaps.sh --ledger fx-resolved.md      ; [ $? -eq 0 ]   # G row, Status Resolved
check-gaps.sh --ledger fx-findings.md      ; [ $? -eq 0 ]   # findings only

# (c) NO INVENTED FINDING: an ungrounded finding is unwritable, at every status.
writeback-ledger.sh ... --append-finding --severity '[HIGH]' --rule -- ...             ; [ $? -eq 4 ]
writeback-ledger.sh ... --append-finding --severity '[LOW]' --status OOS --rule -- ... ; [ $? -eq 4 ]
```

(a) is the assertion that matters: total over a mechanically derived file set, so a grade site
added later fails it automatically — no exclusion list to maintain. (c) is the mechanical half
of "never produces an invented finding", and its second line is the inversion of feature-003's
own oracle, which is why §8's hand-off is explicit.

**AC-5 — a "no" is on record and is not re-asked.**

```bash
# (a) READ SIDE: a Declined key is reported, and therefore subtracted from the batch.
gap-register.sh --state fx-state.md --resolved-keys | grep -qx 'code-sh/coding-standard'

# (b) IDEMPOTENCY: promoting twice yields a byte-identical register.
cp fx-state.md a.md
gap-register.sh --state a.md --promote --ledger fx-open-criteria.md
cp a.md b.md
gap-register.sh --state b.md --promote --ledger fx-open-criteria.md
diff -q a.md b.md          # expect identical: no duplicate row, no renumber

# (c) DURABILITY: neither register file is gitignored.
git check-ignore -q .aid/works/work-NNN/STATE.md ; [ $? -ne 0 ]
git check-ignore -q .aid/knowledge/STATE.md      ; [ $? -ne 0 ]
```

(c) is the assertion a weaker suite would skip, and the one that proves the record survives the
halt. It is non-trivially true for both register paths and non-trivially **false** for the
ledger (`.aid/.temp/` is ignored) — so the same three lines also prove *why* the register cannot
be the ledger.

**AC-10 — the same gap twice halts with a loop flag, unaided.**

```bash
# (a) WITHIN one invocation: the helper's own recurrence counter.
writeback-ledger.sh --ledger L --append-gap --gap-key code-sh/coding-standard ...
writeback-ledger.sh --ledger L --append-gap --gap-key code-sh/coding-standard ...
[ "$(grep -c '^| G-' L)" -eq 1 ]        # no second row
grep -q 'resume=2' L

# (b) ACROSS invocations: the register's counter, and the loop token on stdout.
gap-register.sh --state S --promote --ledger L   # key was Declined -> Recurrences 1 -> 2
check-gaps.sh --ledger L --state S > out.tsv ; [ $? -eq 1 ]
[ "$(cut -f1 out.tsv | head -1)" = 'LOOP' ]

# (c) NO FALSE POSITIVE: a still-Pending gap re-raised is the SAME gap, not a recurrence.
gap-register.sh --state S-pending --promote --ledger L
[ "$(awk -F'|' '/code-sh/ {gsub(/ /,"",$6); print $6}' S-pending.md)" = '0' ]
```

(c) is the assertion most likely to be missing. Without it, the
`/aid-update-kb`-branches-off-`master` behaviour in §4 makes *every* canon-route resolution look
like a loop on first re-invocation, and AC-10 would fire on the happy path. It is the negative
control proving the counter counts recurrences rather than re-reads.

**What no script can prove, stated plainly.** *"The reviewer raises a gap instead of inventing a
rule"* is a runtime property of an agent, and no static check reaches it. These oracles prove
that an invented finding is unwritable, that an open gap makes the grade unreachable at all
eighteen sites, that a refusal is durable and machine-readable, and that recurrence is counted
rather than guessed. Whether a reviewer *notices* the gap is enforced by the agent body, the six
briefs, and mechanically by `--append-finding`'s refusal of a rule-less row.

### 10. Render and profile impact

Per STATE.md concern N3, verified **at this feature's close**: `/generate-profile`, then
`verify_deterministic.py`, then assert both scripts are emitted and executable under each of the
five tool roots plus this repo's own `.claude/` and `.cursor/` installs, and that each rendered
brief carries the `GAP POLICY` section with renderer-rewritten pointers. `canonical/aid/scripts/`
currently holds `config connectors execute grade.sh housekeep kb migrate release summarize
works` — no `review/` — so emission must be confirmed by rendering, per feature-003's emission
caveat (a never-emitted subdirectory has never exercised the mapping).

### 11. Out of scope

- The severity scale and `AGENT.md` 31/36/59–67 — **feature-001**.
- The rubric catalog, the `Rule` column, and `AGENT.md` 3/17/39–57/75/96–99 — **feature-002**.
- The `G-NNN` row kind itself, `--append-gap`, and the write helper — **feature-003**. This
  feature consumes them.
- Resume semantics, the resume-vs-new-cycle split, orchestrator-owned Status reconciliation,
  unit invalidation, and `reviewer-ledger-schema.md` 101/149–157/185/192–194 — **feature-005**.
- `aid-light-review` and the relocation of the up-front scan into it — **feature-006**.
- The settings gate, the frontmatter-lint wiring, the BLUEPRINT review, the per-section specify
  ledger, and the single-grading-backend consolidation — **feature-007**.
- Fixing `/aid-update-kb`'s branch base and the phantom `coding-standards.md S12` citation —
  **Q3 backlog**, both logged rather than fixed here. (A third item, "the stale emission
  manifests", was listed here and has been **retracted** — it was not a defect; see feature-003.)

### Delivery recommendation

Three deliveries. **D1** — the two scripts, the register schema in both state templates, and the
suite; independently verifiable, and ships the AC-5/AC-10 machinery alone. **D2** — the semantic
edits: `AGENT.md`, `README.md`, `reviewer-ledger-schema.md`, `reviewer-dispatch.md`,
`state-machine-chaining.md`, the six briefs, and the greenfield split. **D3** — the 18-site gate
wiring plus the render-parity gate; largest file count, smallest per-file change, and the only
delivery whose oracle is a tree-wide sweep. D1 gates both others.

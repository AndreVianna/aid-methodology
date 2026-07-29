# Criteria-Gap Protocol

**"There is no rule to judge this by" is an outcome, not an excuse to invent one.** This document
defines how that outcome is detected, recorded, asked about once, and resolved.

The halt is **not a new mechanism.** It is `PAUSE-FOR-USER-ACTION`, already sanctioned in
[`state-machine-chaining.md`](state-machine-chaining.md) for cross-skill loopback, with its durable
footprint already defined. `aid-housekeep`'s KB-DELTA already writes a register entry and routes to
another skill, so **register-write-then-route is existing behaviour**, not a proposal.

---

## Two kinds of finding

| Type | What it is | Carrier | Grade-bearing? |
|---|---|---|---|
| **Type 1** | A defect in the artifact | an ordinary finding row | **Yes** |
| **Type 2** | A missing *precondition* of the review | a `G-NNN` gap row | No |

A Type 2 is not a softened Type 1. The artifact may be perfect; what is missing is the rule that
would let anyone say so. Grading it would either invent a criterion or score it against nothing.

## The three discriminators

Every gap row's `Description` begins with **exactly one** of these, as a closed enum:

| Token | Meaning | Blocks the grade? |
|---|---|---|
| `[GAP:CRITERIA]` | No rule in either authority ladder speaks to the concern | **Yes** |
| `[GAP:CRITERIA:NB]` | Same, but the depth cap was reached, or a family rule set covered it | No |
| `[GAP:EVIDENCE]` | No available evidence can confirm or deny the claim | No |

This reuses an existing convention rather than inventing one: `aid-discover`'s merge rule already
requires every `Description` to carry a bracketed marker prefix. It needs **no ninth column** — the
column set was reopened exactly once, for `Rule`, and reopening it again would be a second exception.

`[GAP:EVIDENCE]` is how *"cannot measure → ask the user"* becomes implementable at all: a dispatched
sub-agent **cannot** ask, so it records a non-blocking gap and the batch surfaces it.

---

## The gate

Every grade site gains a preceding gate:

```bash
bash .codex/aid/scripts/review/check-gaps.sh --ledger <path>   # 0 clean, 1 open criteria gap
bash .codex/aid/scripts/grade.sh --explain <path>              # only reachable on exit 0
```

`--ledger` may be **repeated**, and that is load-bearing rather than convenient. Under parallel
mandates each reviewer writes its own scratch ledger, and `U-`/`G-` rows are deliberately **not**
merged into the panel ledger — so the batch can only form by reading *across* ledgers without
merging rows.

**The gate cannot live inside `grade.sh`.** NFR-1 forbids changing its behaviour, and grade-inertness
is the wrong tool anyway: an inert row cannot *stop* a grade, only fail to affect it.

---

## The lifecycle

| # | Transition | Owner | Mechanism |
|---|---|---|---|
| 1 | **Detect** | the dispatched reviewer | No criterion in either ladder → a `G-` row instead of a finding |
| 2 | **Record** | the reviewer | `writeback-ledger.sh --append-gap`. Idempotent on the key |
| 3 | **Batch** | the calling skill | By **reading** every scratch ledger — never by merging rows |
| 4 | **Subtract** | the calling skill | `gap-register.sh --resolved-keys`. Settled keys drop out |
| 5 | **Propose** | the reviewer, in its **return message** | Proposals never enter the ledger |
| 6 | **Ask** | the calling skill, **once for the whole batch** | A sub-agent cannot hold a dialogue |
| 7 | **Promote** | the calling skill | `gap-register.sh --promote`, **before** anything is deleted or halted |
| 8a | **Loop back** (owning skill == running skill) | the calling skill | CHAIN to its own authoring state |
| 8b | **Halt and route** (owning skill ≠ running skill) | the calling skill | `PAUSE-FOR-USER-ACTION`: write `Lifecycle` + `Pause Reason`, print the route, exit |
| 9 | **Resolve** | the routed skill | `/aid-update-kb` or a definition skill. **The reviewer writes nothing** |
| 10 | **Resume** | the calling skill | Step 4 subtracts resolved keys; coverage rows resume rather than restart |

**Promote before you halt.** The ledger lives under `.aid/.temp/` and is deleted at skill DONE. A gap
that was never promoted dies with it, and so does the user's answer.

**The join key is the Gap Key, never the row ID.** Two mandates raising the same gap produce `G-001`
in two namespaces. Dedupe on the key is what makes never-re-asking and recurrence counting possible.

---

## Routing

| Owning artifact | Route | Brief travels via |
|---|---|---|
| A KB document | `/aid-update-kb <free-text brief>` | **the prompt** |
| REQUIREMENTS | `/aid-define <work>` | the register |
| A feature SPEC | `/aid-specify <feature>` | the register |
| PLAN / BLUEPRINT | `/aid-plan <work>` | the register |
| Task DETAIL | `/aid-detail <work>` | the register |

**Why the KB route is different.** `/aid-update-kb` creates its worktree off `master`, not off the
caller's branch, so a canon-route resolution lands somewhere the caller cannot see until it merges.
The register write is therefore **invisible across that boundary**, and the brief must ride in the
free-text argument instead. That is not a preference: of the five targets, only `/aid-update-kb`
takes free text — the other four take a work or feature id plus flags.

Two consequences follow, and the printed halt text must carry both:

1. A caller who re-invokes **before merging** will re-raise the same gap.
2. That is why recurrences increment *only after resolution* — otherwise an unmerged branch looks
   identical to a genuine loop.

### Canon or one-time

Every answer is also a scope decision, and it must be asked for explicitly:

- **canon** — the rule becomes project policy, written into the KB. The next reviewer finds no gap at
  all, because a declared rule is not a gap.
- **one-time** — the decision applies to this artifact only, recorded in the work's documents.

A **"no"** is a legitimate answer and gets two follow-ups in one cell: *what to do instead*, and
*canon or one-time*. A "no" answered as canon becomes a declared rule ("this project does not check
X"), which is why the structural layer eventually replaces the mechanical subtraction.

---

## Restricted mode (resolving a gap)

A review running to resolve a gap operates under four restrictions. Without them, resolving one gap
can discover the entire Knowledge Base.

1. **Scope lock.** A criteria gap may only be raised about an artifact already in scope. An
   out-of-scope observation is an `OOS` finding or a `[GAP:EVIDENCE]` row — never a blocking gap.
2. **Fallback before halt.** At depth ≥ 1, where family rules cover the concern they are **used**,
   and the missing class rule set is recorded `[GAP:CRITERIA:NB]`. Family rules are declared rules,
   so no invention occurs.
3. **Depth cap.** At depth 2, a `[GAP:CRITERIA]` is written as `[GAP:CRITERIA:NB]`, the run proceeds
   to grade, and the register records `Depth: 2` with `Status: Pending`. **The cap demotes; it never
   discards.**
4. **No self-route.** An `/aid-update-kb` run may not print a canon route to `/aid-update-kb`; it
   uses its own loopback. Otherwise the recursion is structural rather than depth-bounded — and it
   would nest worktrees.

### Why the limit is 2

Depth 0 is the original review, 1 is resolving its gap, 2 is *a gap in the very standard being
authored* — legitimate exactly once. Each level costs a full human-gated skill run; `/aid-update-kb`
alone carries two human gates plus its own fix loop. Three stacked runs already exceed what any
existing flow asks in one sitting, so **a fourth is a bug, not a workflow.**

Needing depth 3 means the Knowledge Base has a structural hole belonging to a full `/aid-discover`.
Demoting to non-blocking says exactly that, in the register, where a human reads it.

---

## The register

Location resolves by scope, through one accessor:

| Running scope | Register | Companion |
|---|---|---|
| A work (Lite included) | `.aid/works/work-NNN-*/STATE.md` → `## Criteria Gaps` | — |
| A delivery | `delivery-NNN/STATE.md` → same section | — |
| The Knowledge Base | `.aid/knowledge/STATE.md` → same section | an `Impact: Required` entry in `## Q&A (Pending)` |

**Both files are git-tracked, and that is the point.** The ledger is deleted at DONE; the register is
what survives the halt *and* that deletion.

The KB scope also writes the companion Q&A entry, copying `aid-housekeep`'s existing step. That makes
the existing `Q-AND-A` state pick the gap up with **zero change to that state**: it already drives
every Pending entry to a terminal answer, and already makes approval unreachable while any remains.

```bash
gap-register.sh --state <STATE.md> --promote --gap-key code-sh/coding-standard \
    --kind criteria --scope 'b.sh' --criterion 'no shell coding standard declared' \
    --resolution '/aid-update-kb coding-standards'

gap-register.sh --state <STATE.md> --resolved-keys      # subtract these from the batch
gap-register.sh --state <STATE.md> --depth-of <key>     # the chain length so far
```

### The two rules that make the register trustworthy

**A recurrence never resets the answer.** When an `Answered` or `Declined` key returns, `Recurrences`
increments and the **status stands**. Resetting it to `Pending` would drop the key out of
`--resolved-keys`, and the next batch would re-ask a question the user already settled — the single
failure this register exists to prevent.

**Recurrences increment only after resolution.** A gap still sitting `Pending` is a slow human, not a
loop. Counting it would make every re-run look like a runaway.

---

## See also

- [`reviewer-ledger-schema.md`](reviewer-ledger-schema.md) — the `G-NNN` row kind
- [`review-rubrics/INDEX.md`](review-rubrics/INDEX.md) — the rule sets whose absence *is* the gap
- [`state-machine-chaining.md`](state-machine-chaining.md) — `PAUSE-FOR-USER-ACTION`

## Change Log

| Date | Change |
|---|---|
| 2026-07-29 | Created. Type 1/2 model, three discriminators, the gate, the lifecycle, routing, restricted mode, and the register. |

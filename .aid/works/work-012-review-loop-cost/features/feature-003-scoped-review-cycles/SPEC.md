# Scoped Review Cycles

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-15 | Feature identified from REQUIREMENTS.md §5 FR-1–FR-7 and FR-14, §9 AC-2–AC-4, AC-9, AC-10, AC-12 | /aid-define |
| 2026-08-15 | FR-14 folded in here rather than made a fourth feature — it edits the same sites; NFR-5 close-out folded in likewise (C-7) | /aid-define |
| 2026-08-15 | **AC-13 adopted** (for FR-5, the once-per-phase contradiction pass), promoted to a numbered criterion in REQUIREMENTS.md §9 after cross-reference cycle 1 found FR-5 demanded by nothing. `## Source` updated to list it — cycle 2 found it present in the criteria list but absent from Source | /aid-define |
| 2026-08-15 | Technical Specification authored: the verification/hunt split, the mechanical referrer expansion, Guard 2's cadence change, FR-14's slice, and the work's close-out | /aid-specify |
| 2026-08-15 | **Specify gate cycle 1 (C+) — Guard 2 had no implementer.** It was fully argued in prose and mapped to no file in the Layers table, so an executor working from that table would have built Guards 1 and 3 and silently omitted it; it now has a row naming its two invocation sites, and a stated firing point (after the last artifact's gate, before the phase hands off). Also: the `Doc: —` ledger row would have left a doc-wide finding unverifiable, so it now widens the verification set; and AC-9's byte measurement was missing from close-out | /aid-specify |
| 2026-08-15 | **Specify gate cycle 2 (C+) — Guard 2's invocation site could not do the job.** Cycle 1's fix named `aid-specify/state-done.md`, which fires **per feature** and HALTs: the pass would have run once per feature, the opposite of AC-13's once-per-phase, and closing that would have meant inventing "is this the last feature?" detection. The rule is now derived from a fact already true of the pipeline — three reviews (`aid-define` cross-reference, `aid-plan`, `aid-detail`) already receive every artifact of a phase at once, so the pass is a **cycle-1 activity of any multi-artifact review** and needs no new state anywhere. `aid-specify` correctly gets none, since it dispatches per artifact; its specs are cross-checked at `aid-plan`'s review. The cycle-1 claim that `aid-specify` and `aid-define` were "the only two skills gating more than one artifact per phase" was also false and is corrected in place | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-1 to FR-7 (the scoped cycle and its three guards)
- REQUIREMENTS.md §5 FR-14 (the requirements slice for the per-feature specify gate)
- REQUIREMENTS.md §6 NFR-4 (no guarantee traded for cost), NFR-5 (the single render)
- REQUIREMENTS.md §7 C-3 (7 columns and `grade.sh` untouched), C-4 (resolution stays scope-free)
- REQUIREMENTS.md §9 AC-2, AC-3, AC-4, AC-9, AC-10, AC-12, AC-13

## Description

A review re-reads the whole artifact on every cycle. The cause is one sentence at the end
of the cycle-2-and-later workflow in `reviewer-ledger-schema.md`: *"Append new rows as
`Pending` for newly-found issues."* Everything before it is already targeted and cheap —
verify each `Pending` row on disk, promote to `Fixed`, demote a regressed `Fixed` to
`Recurred`. That last clause is what forces the full re-read, because finding NEW issues
means re-scanning everything.

This feature splits that clause in two. **Ledger verification stays full; new-finding
discovery becomes scoped.** Cycle 1 still reads everything. Cycles 2 and later hunt for new
findings only in what the previous FIX changed.

The scoping is only safe because of three guards, and all three land with it rather than
after it:

1. **A fix in one section breaks another.** The scoped surface includes the sections that
   *reference* the changed ones, found by mechanical cross-reference lookup — not by asking
   the model to judge what might be affected.
2. **Cross-document contradictions.** That pass is kept, but runs once per PHASE instead of
   once per cycle per feature. It was never a per-cycle check.
3. **Something is missed anyway.** `Recurred` already exists for exactly this, and a final
   full pass runs before approval as the backstop. A scoped cycle never approves.

Feature-002 is what makes this sound rather than merely cheaper. A scoped cycle only works
for criteria that can be *evaluated* against a subset, and evaluation scope varies per
criterion — `G-01` fires on a local occurrence, `KB-02` needs the whole file, `G-07` needs
the whole corpus. A criterion with an oracle is re-run at any scope for negligible cost, so
its evaluation scope stops mattering. That is why feature-002 comes first.

**Folded in here, per C-7 rather than made into more features:** FR-14, the requirements
slice, because it edits the same files; and the NFR-5 close-out, because a render is the
last act of the last delivery, not a feature of its own.

## User Stories

- As the repo owner, I want a review cycle to cost what the change costs rather than what
  the document costs, so that a small fix does not pay for a full re-read.
- As a reviewer, I want the surface I must hunt to be stated and bounded, so that my
  coverage is provable rather than asserted.
- As a reviewer on a per-feature specify gate, I want the slice of requirements the feature
  traces to rather than the whole document, so that I am not re-reading 88 KB to check one
  feature.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-2** Given a defect seeded in a section that REFERENCES a changed section, when a
      scoped cycle runs, then the defect is found. FR-4's guard is tested, not trusted.
- [ ] **AC-3** Given a defect seeded OUTSIDE the scoped surface and consequently missed by
      a scoped cycle, when the final full pass runs, then the defect is caught. The
      backstop is demonstrated end to end.
- [ ] **AC-4** Given a `Fixed` row that regresses in a section outside the scoped surface,
      when the next cycle runs, then it is still demoted to `Recurred` — ledger
      verification is provably unscoped.
- [ ] **AC-9** Given a per-feature specify gate, when it is dispatched, then it carries only
      the requirements slice the feature traces to, and the saving is stated as a measured
      byte reduction on a real feature.
- [ ] **AC-10** Given the work at close, when the ledger and the grader are inspected, then
      the ledger is still 7 columns and `canonical/aid/scripts/grade.sh` is byte-identical
      to its state at the start of the work (C-3).
- [ ] **AC-12** Given the work at close, when CI runs, then the render-drift gate and the
      dogfood byte-identity gate are both green (NFR-5).
- [ ] **AC-13** Given a phase whose gate runs 2 or more cycles over more than one feature,
      when the cross-document contradiction pass is counted, then it executed exactly once
      for the phase — and a contradiction spanning two features is still caught by it. Both
      halves are required: a pass that runs once but stops catching what it exists for is a
      regression, not a saving.
- [ ] Given cycle 1 of any review, when it runs, then it reads the whole artifact —
      unchanged behaviour (FR-1).
- [ ] Given a scoped cycle, when it completes, then it has not approved the artifact; only
      a full pass can (FR-6).

---

## Technical Specification

### The change is smaller than it sounds, and that is the design

`reviewer-dispatch.md` already prescribes deriving the artifact list mechanically:

> **Deriving `{{ARTIFACTS}}` — always from disk, never from memory.** For PR-level reviews,
> derive from `git diff --name-only <base>..HEAD | filter_reviewable_artifacts`, then
> filtered by the OUT-OF-SCOPE list.

So the machinery for "compute the review surface from a diff" exists and is already
normative. **FR-3 changes which `<base>` is used, and splits one list into two.** It does not
introduce a new way of deciding what a reviewer reads.

This matters for NFR-1 and for risk: the feature adds **no executable surface at all**. Every
change is authored instruction in five files plus one KB table.

### Two sets, not one — the core of the design

Today a cycle has one artifact list. From cycle 2 it has two, because the ledger workflow
already does two different jobs and only one of them is expensive.

| Set | Contents | Scope | Why |
|---|---|---|---|
| **Verification set** | Every file named in an existing ledger row's `Doc` column, **plus the full cycle-1 artifact set whenever any row's `Doc` is `—`** | **FULL — never scoped** | Verifying a `Pending` row is a targeted disk check, already cheap. Scoping it would break `Recurred` detection, which is the backstop the whole design leans on (AC-4). |

**The `Doc: —` case, which would otherwise quietly break AC-4.** The ledger schema permits
`—` in `Doc` for a doc-wide issue with no specific file. Such a row names no file, so a
verification set built by collecting `Doc` values would contain nothing for it and the row
could never be re-verified — it would sit `Pending` forever, or worse, be treated as
verified because nothing contradicted it. Any `—` row therefore widens the verification set
to the full cycle-1 artifact set. This is the correct direction: a doc-wide finding is
doc-wide, and AC-4's claim that verification is *provably* unscoped has to hold for every
row shape the schema allows, not just the common one.
| **Hunt set** | What the previous FIX changed, plus the sections that reference it | **SCOPED** | This is the expensive half — "find NEW issues" is what forces a full re-scan today. |

The brief carries both, labelled, so the reviewer can tell what it must verify from what it
must hunt in. `ARTIFACTS UNDER REVIEW` gains this structure for cycles ≥ 2 and is unchanged
for cycle 1 and the final pass.

### Computing the hunt set

```
changed   := git diff --name-only <previous-cycle-commit>..HEAD
             | filter_reviewable_artifacts          # the existing filter, reused
referrers := files containing a literal reference to any changed path
             or to a changed section's heading text
hunt      := changed ∪ referrers
```

**`<previous-cycle-commit>` is already recorded.** feature-001's `review-cost.tsv` carries a
`commit` per cycle, so the base is a lookup rather than a new record. Where no previous-cycle
commit exists — the meter was not run, or this is a first scoped cycle — the base **falls
back to the artifact set of cycle 1**, i.e. the cycle is unscoped. Degrading to today's
behaviour is always the safe direction, and it is chosen deliberately over guessing a base.

**`referrers` is a grep, not a judgment (FR-4).** The guard L5 requires is that a fix in one
section can break another that references it. The lookup is mechanical over the three
reference forms this corpus actually uses — a backticked path, a markdown link, and an
in-page anchor to a heading. Concretely: for each changed path, grep the in-scope corpus for
that path string; for each changed heading, grep for its anchor form. No model judgment about
what "might be affected", because a judgment that varies between cycles is the
non-determinism this work exists to remove.

**Stated limitation.** A reference expressed in prose without naming the path ("the ledger
schema says…") is not found by grep. This is a real hole, and it is why FR-6's final full
pass is not optional: the mechanical expansion is the cheap catch, the full pass is the
complete one. Widening the grep to prose synonyms would reintroduce exactly the judgment the
guard exists to eliminate.

### Guard 2 — the contradiction pass moves to once per phase

The cross-document contradiction pass is kept in full (NFR-4 forbids trading a guarantee for
cost). What changes is **cadence**: once per phase, over all of that phase's artifacts,
instead of once per cycle inside each feature's gate.

| | Today | After |
|---|---|---|
| Runs | features × cycles | once per phase |
| Sees | one feature at a time | every artifact in the phase, together |

It gets **better**, not merely cheaper: a contradiction between two feature specs is
invisible to a per-feature gate that only ever reads one of them. This work's own Define
phase demonstrated the class — `feature-001`'s SPEC restated `REQUIREMENTS.md` §9 AC-1 and
disagreed with it, and the cross-feature sweep is what found it.

**Where it fires — and it needs no new state anywhere.** An earlier draft put the pass in a
"phase close" step and named `aid-specify`'s `state-done.md` as a site. That was wrong on its
own terms: `state-done.md` fires **per feature** and HALTs, with no awareness of the other
features, so the pass would have run three times in this work rather than once — the exact
opposite of AC-13.

The correct rule follows from a fact already true of the pipeline: **several reviews already
receive every artifact of a phase at once.** The pass is a **cycle-1 activity of any review
whose `ARTIFACTS` span more than one artifact.**

| Review | Already receives | Covers |
|---|---|---|
| `aid-define` CROSS-REFERENCE | `REQUIREMENTS.md` + every feature `SPEC.md` | Define's own output |
| `aid-plan` review | full `PLAN.md` + **every** `feature-*/SPEC.md` | **Specify's per-feature specs** |
| `aid-detail` review | every `task-NNN/DETAIL.md` across all deliveries + `PLAN.md` | Detail's task set |

`aid-specify` is the one skill that dispatches a reviewer **per artifact**, so no single
specify review can see a contradiction spanning two features — and it correctly gets **no**
Guard 2 invocation. Its specs are cross-checked at `aid-plan`'s review, the first review
after Specify that sees them all together.

**Cycle 1, and therefore once per phase by construction.** Cycle 1 is the full-read cycle
that happens anyway, and a multi-artifact review happens once per phase, so pinning the pass
to it satisfies AC-13 without any "is this the last feature?" detection — which is precisely
the mechanism the earlier draft would have had to invent.

**A correction to a claim made while fixing this.** An earlier revision asserted that
`aid-specify` and `aid-define` are "the only two skills that gate more than one artifact per
phase". That is false — `aid-plan` and `aid-detail` both do, as the table above shows. The
distinction that actually matters is not how many artifacts a phase has, but whether **one
review sees them all**.

**The window this leaves, stated rather than glossed.** A contradiction introduced *by the
contradiction pass's own fix* is not re-checked by that pass, because the pass is pinned to
cycle 1 and the fix lands after it. It is not unguarded — FR-6's final full pass before
approval is the backstop, exactly as for a missed scoped finding — but the pass itself is
single-shot by design, and re-running it every cycle until fixpoint would rebuild the
per-cycle loop this feature exists to remove.

### FR-14 — the requirements slice

A per-feature specify gate currently receives the whole `REQUIREMENTS.md`
(`state-initialize.md § Step 1: Load Full Context`, item 2, "full requirements for
cross-reference"; `state-review.md`, "Same as INITIALIZE Step 1").

**The slice is already declared, so nothing needs inventing.** Each feature SPEC's
`## Source` section names the `REQUIREMENTS.md` sections and criteria it traces to — this
work's own three features each do. The slice is those sections, extracted by heading. A
feature whose `## Source` names no requirements section is a defect that surfaces
immediately, which is a second reason to derive the slice from it rather than from a
hand-maintained map.

### Layers & Components

| Component | Path | Change |
|---|---|---|
| Ledger schema | `canonical/aid/templates/reviewer-ledger-schema.md` | Split the cycle-N≥2 clause: ledger verification full, new-finding discovery scoped. The single sentence L5 identifies. |
| Dispatch protocol | `canonical/aid/templates/reviewer-dispatch.md` | `ARTIFACTS UNDER REVIEW` carries the two labelled sets on cycles ≥ 2; `RUBRIC` resolves criteria against the scoped surface. **Also declares the contradiction pass as a phase-level activity** (Guard 2) — the normative home, since the cadence binds every skill that dispatches a reviewer. |
| **Guard 2's invocation sites** | `canonical/skills/aid-define/references/state-cross-reference.md`, `canonical/skills/aid-plan/references/review-deliverables.md`, `canonical/skills/aid-detail/references/review.md` | The three reviews that already receive **every artifact of a phase at once**. Each runs the contradiction pass on **cycle 1 only**. `aid-plan`'s is the one that covers Specify's per-feature specs. **`aid-specify` gets no invocation** — it dispatches per artifact, so no single review of its could see a cross-feature contradiction; that is why the coverage sits downstream. Without this row an executor reading only this table would build Guards 1 and 3 and silently omit Guard 2. |
| Every reviewer brief | `canonical/skills/*/references/reviewer-brief.md` — **enumerated from disk**, six at authoring time | Render the two sets; `aid-specify`'s additionally renders the requirements slice (FR-14). |
| Specify's context load | `canonical/skills/aid-specify/references/state-initialize.md`, `state-review.md` | The two FR-14 sites. `aid-specify` is touched **only** here — it takes no Guard 2 change. |
| Criteria table | `.aid/knowledge/authoring-conventions.md` | The scoped-cycle note. **Owner-authorized (C-5).** |

**No script, no oracle, no data.** The whole feature is authored instruction plus one KB
edit. Under NFR-1's definition it adds **zero mechanism lines** — which is worth stating,
because remedy 1 was the half of L5 that sounded riskier and is in fact the half that adds
nothing executable.

**The brief set is a glob, not a list, and the reason generalises.** An earlier version of
this table named six brief files explicitly. `work-006` is the counter-example that
prompted the change: it adds 36 skills in one work, without its author knowing this work
existed. It happens to add no seventh brief — but a hand-written enumeration would have
missed one silently if it had, and "it happened not to" is not a property a design should
rely on.

The count is also the wrong *kind* of thing to write down. `G-01` bans a stated count unless
it is load-bearing and measured from disk at authoring time; here the count is
load-bearing precisely because it defines an edit set, which is the case for deriving it
rather than the case for stating it. A work whose whole subject is "stop re-deriving by hand
what a command can answer" should not hard-code an enumeration a `ls` produces.

So the contract is `canonical/skills/*/references/reviewer-brief.md`, resolved at execution.
Six exist today; `task-009` reports how many it actually edited, so a brief added between
now and Execute is visibly covered rather than quietly skipped.

### Close-out (folded in per C-7)

This feature is last, so it carries the work's single render and the final measurement:

1. `python .claude/skills/generate-profile/scripts/run_generator.py` — the **full** generator,
   never a per-script renderer, or the render-drift gate fails on stale emission manifests
   (`tech-debt.md § Gotchas`). This is the one render for the whole work (NFR-5), covering
   feature-002's `canonical/` edits as well as this feature's five.
2. Resync the two tracked dogfood trees from the rendered profiles.
3. Take AC-1's "after" reading and report the net (AC-1, AC-11).
4. **Measure FR-14's saving (AC-9):** the byte size of the requirements slice a real
   feature's specify gate receives, against the byte size of the whole `REQUIREMENTS.md` it
   would have received. AC-9 asks for a *measured* byte reduction, and unlike AC-1 this one
   needs no before/after run — both figures exist at the same commit, so it is a single
   comparison taken here.
5. Confirm `grade.sh` is byte-identical to its state at the start of the work (AC-10).

### Sections not applicable

No data model, API, UI, events, DDD, CQRS, state machine, auth, cache, external integration,
scheduled work, mobile, search, AI, recovery, cloud or hardware concern. No migration: the
change is to instructions an agent reads at run time, so there is nothing on disk to convert.

### Known issues touched

None new. `tech-debt.md § Gotchas`'s render-drift trap is a pre-existing entry, observed by
close-out step 1 rather than discovered here.

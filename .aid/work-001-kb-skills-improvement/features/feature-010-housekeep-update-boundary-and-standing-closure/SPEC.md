# Housekeep ↔ Update-KB Boundary & Standing Closure

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-33, FR-34) | /aid-interview |

## Source

- REQUIREMENTS.md §5.I (FR-33, FR-34)
- REQUIREMENTS.md §1.8 (skill topology, freshness loop), §2.8 (P8)
- §4 S7, S8, §10 (Should)

## Description

This feature draws the clean boundary between the two KB-mutating skills and makes
concept-closure a standing invariant. It defines `aid-housekeep` (KB-DELTA) as
**source-driven and global** — a whole-KB reconcile against current source state
(triggered by merge-to-master / major change / periodic), using the FR-5 per-doc
staleness as the shared signal to scope the sweep. It defines `aid-update-kb` as
**prompt-driven and targeted** — a prompt specifies what to update, and the skill
analyzes how best to fold that into the KB via the review/calibration gate. The two
**MUST NOT overlap**; per-doc staleness (FR-5) is the shared signal that
distinguishes them.

It also makes **concept-closure a maintained invariant**, not a discovery-only
check: both `aid-update-kb` and `aid-housekeep` must **re-verify closure** after
they change the KB, so the KB cannot drift into having an undefined
project-specific term after a targeted edit or a reconcile sweep.

## User Stories

- As an **AID maintainer**, I want a clear housekeep-vs-update-kb boundary (global
  source-driven vs targeted prompt-driven) so that I always know which skill to run
  and the two never overlap.
- As a **doc owner**, I want per-doc staleness to scope the housekeep sweep so that
  reconciliation is targeted rather than an expensive whole-KB judgment sweep.
- As an **AI agent** consuming the KB, I want closure re-verified after any KB
  change so that the KB stays self-contained (no undefined native term) over time.

## Priority

Should

## Acceptance Criteria

- [ ] Given the two skills, when each runs, then `aid-housekeep` performs a
  whole-KB source-driven reconcile and `aid-update-kb` performs a prompt-driven
  targeted update, with no overlap and per-doc staleness (FR-5) as the shared
  signal. *(FR-33, AC10)*
- [ ] Given a KB change by `aid-update-kb` or `aid-housekeep`, when it completes,
  then it re-verifies concept-closure (closure is a standing invariant, not
  discovery-only). *(FR-34; supports AC3)*

> Cross-cutting note: depends on f007 (per-doc staleness, FR-5) as the shared
> signal, and on f004's closure check (FR-14) as the invariant re-verified here.

---

## Technical Specification

> Methodology/governance feature. It draws the **non-overlapping contract** between AID's
> two KB-mutating skills (FR-33) and makes **concept-closure a standing invariant** re-verified
> before committing each KB change (FR-34). f010 builds **nothing new from scratch**: it (a)
> rewrites `aid-housekeep`'s KB-DELTA stage to **prioritize its whole-KB sweep via f007's
> `kb-freshness-check.sh` per-doc suspect verdicts** (replacing the git-date hint as the drift
> signal and adding a fast no-drift exit) while **retaining the whole-KB content re-review of all
> docs** so the AC1 "subtly-wrong-all-along" guarantee is preserved, (b) adds a **closure
> re-verify step** to `aid-housekeep` **before** it commits a KB refresh (the housekeep half of
> FR-34, true f008 parity — f008 verifies before committing; the `aid-update-kb` half is already
> wired in **f008**'s DONE — referenced, not duplicated), and (c) records the **boundary
> contract** so the two skills never overlap.
> Every helper it calls — `kb-freshness-check.sh` (f007), `closure-check.sh` (f004) — already
> exists; **f010 adds no new script** (C2/NFR-3 satisfied by reuse). Each claim is grounded
> against the files cited inline; genuine unknowns are flagged **[SPIKE]**, not guessed.

### Overview

This feature touches **two canonical skill bodies plus the requirements/KB record** — it does
**not** ship a new script or skill:

1. **The boundary contract (FR-33).** `aid-housekeep` (KB-DELTA) = **source-driven + global**;
   `aid-update-kb` = **prompt-driven + targeted**. The two **MUST NOT overlap**; **f007's
   per-doc staleness is the shared signal** both read. Specified as a contract table + a
   no-overlap guarantee, recorded in the canonical KB doc that documents the skill topology so
   a maintainer always knows which skill to run.
2. **Housekeep KB-DELTA scoping change (FR-33).** Today `aid-housekeep/references/state-kb-delta.md`
   uses git as an "optional hint" and then **autonomously re-reads the whole KB** against the
   repo, with **no per-doc/source linkage** to prioritize or to cheaply exit (the §1.8 "no
   precision" hole). `aid-housekeep` is AID's **broad/global/periodic** KB skill — distinct from
   `aid-update-kb`'s targeted speed — so it **retains the whole-KB content re-review** (the
   coverage AC1's "subtly-wrong-all-along" guarantee requires). What f010 changes is **how that
   sweep is scoped and exited**: f010 adds a **deterministic `kb-freshness-check.sh` pre-pass**
   whose **`suspect`** verdicts become a **prioritization layer** (definite/priority re-review of
   the precisely-flagged drifted docs) **plus a fast no-drift exit** (when nothing is `suspect`
   *and* the content review finds nothing, the run exits mostly-mechanically). The per-doc
   staleness **does not replace** the content review and **does not skip any doc** — `current`
   docs are still content-reviewed for subtly-wrong-at-approval drift, just at lower priority and
   with the signal giving confidence ordering.
3. **Standing closure re-verify (FR-34).** `aid-housekeep` gains a **CLOSURE re-verify step**
   after a KB refresh: re-run f004's `closure-check.sh` over the refreshed KB; if it reports an
   ungrounded term, raise it as a finding / Q&A escalation reusing the existing
   `STATE.md ## Q&A (Pending)` mechanism. The `aid-update-kb` half is **f008** (its DONE already
   re-runs `closure-check.sh`); f010 only references it and supplies the shared who-runs-when
   contract.

**Confirmed design decisions this spec builds on (FR-33/FR-34 are well-specified; not
re-litigated):** the boundary is source-driven-global (housekeep) vs prompt-driven-targeted
(update-kb), with per-doc staleness (f007) as the shared signal; closure (f004) is a standing
invariant re-verified by **both** skills after they change the KB. f010 realizes these precisely.

**Boundaries (what this feature does NOT do).**

- **`aid-update-kb` itself = f008.** Its ANALYZE→APPLY→REVIEW→APPROVAL→DONE state machine, its
  prompt contract, its f005-panel reuse, and its **own** closure re-verify in DONE
  (`canonical/skills/aid-update-kb/references/state-done.md`, f008 SPEC lines 308–315) are
  **f008**. f010 references update-kb's closure step as the *update-kb half* of FR-34; it does
  not re-spec it.
- **`closure-check.sh` = f004.** The deterministic closure oracle
  (`canonical/aid/scripts/kb/closure-check.sh`, f004 SPEC lines 437–446) is **built and tested
  in f004**. f010 *calls* it from housekeep; it adds no flag, no new behavior to the script.
- **`kb-freshness-check.sh` = f007.** The per-doc staleness script
  (`canonical/aid/scripts/kb/kb-freshness-check.sh`, f007 SPEC lines 104–185) is **built and
  tested in f007**. f010 *consumes* its `--format tsv` verdicts; it adds no flag.
- **The f005 review/calibration gate = f005.** Housekeep's KB-DELTA refresh still drives
  `/aid-discover`'s targeted re-entry → REVIEW (the panel f005 builds). f010 does not change
  the gate; it only changes **how the fed-in scope is prioritized** (suspect-prioritized, with
  the whole-KB content review retained — not a narrower whole-KB-vs-targeted swap).
- **Cross-tree render + manifests = f009.** Editing `canonical/skills/aid-housekeep/` source
  here leaves render-drift RED on the f010 branch by construction; **f009** runs the generator
  and reconciles host trees. f010 edits `canonical/` only.

---

### Part 1 — The boundary contract (FR-33)

#### The non-overlapping contract table

| Dimension | `aid-housekeep` (KB-DELTA) | `aid-update-kb` |
|-----------|---------------------------|-----------------|
| **Driver** | **Source-driven** — the current state of the repo's source tree drives it | **Prompt-driven** — a free-form prompt naming *what to update* drives it (f008 prompt contract) |
| **Scope** | **Global** — reconciles the **whole KB** against current source state | **Targeted** — a specific (doc, change) set the prompt implies (f008 ANALYZE) |
| **Trigger** | merge-to-master / major source change / periodic maintenance sweep (§1.8 "periodic broad reconciliation") | a maintainer explicitly invoking `/aid-update-kb "<delta>"` (e.g. a finished work's deltas) |
| **Question it answers** | "Which docs has the repo drifted *away from*, and what needs reconciling?" | "How do I best fold *this named change* into the KB?" |
| **Shared signal (the divider)** | reads f007's per-doc **suspect** verdicts to **prioritize** the whole-KB sweep (and gate a fast no-drift exit) — does not narrow which docs are content-reviewed | reads f007's per-doc **suspect** verdicts to **confirm which prompt-named docs actually drifted** (f008 ANALYZE step 2) |
| **Gate** | f005 panel via `/aid-discover` targeted re-entry (existing) | f005 panel scoped to the changed docs (f008 REVIEW) |
| **Closure** | re-verifies `closure-check.sh` **before committing** the refresh (Part 3, **new in f010**) | re-verifies `closure-check.sh` **before committing** in DONE (f008, existing) |

#### The shared signal — per-doc staleness (f007)

Both skills read the **same deterministic signal** — `kb-freshness-check.sh`'s per-doc
`{current, suspect, unknown}` verdict (f007 SPEC line 159–165) — but **use it for opposite
purposes**, which is exactly what keeps them non-overlapping:

- **housekeep** uses the suspect set as the **input that defines its scope** (source → which
  docs drifted → reconcile those). It starts from *the repo* and asks *which docs*.
- **update-kb** uses the suspect set as a **confirmation filter** on a scope the prompt already
  named (prompt → candidate docs → confirm drift). It starts from *a named change* and asks
  *which of these docs actually moved* (f008 ANALYZE step 2: "prompt-implied docs ∩ suspect docs").

The signal is read-only and side-effect-free for both (f007: stdout only, no writes), so two
skills reading it concurrently is safe.

#### The no-overlap guarantee

The two are mutually exclusive **by driver**, and the contract makes the exclusion explicit:

1. **No prompt → not update-kb.** `aid-update-kb` requires a prompt and exits with a usage line
   if none is supplied (f008 prompt pre-flight). A source-driven periodic reconcile has no
   prompt, so it is **never** an update-kb job.
2. **Whole-KB reconcile → not update-kb.** A global "reconcile everything that drifted" sweep is
   `aid-housekeep`'s definition (§1.8: "periodic broad reconciliation"); §1.8 already states
   "`aid-housekeep`'s KB-DELTA is too broad for an end-of-work diff" — the targeted end-of-work
   diff is update-kb's lane.
3. **Targeted named delta → not housekeep.** A maintainer with a *specific* change to fold in
   runs `/aid-update-kb "<delta>"`; they do **not** run a global housekeep sweep for one doc.
4. **The divider is recorded, not just asserted.** The contract table above is written into the
   canonical KB doc that documents skill topology (Part 4) so the boundary is a durable,
   routable artifact — a maintainer (or the dashboard) can look up "which skill, when".

This is the FR-33 AC10 contract: *given the two skills, when each runs, housekeep performs a
whole-KB source-driven reconcile and update-kb a prompt-driven targeted update, with no overlap
and per-doc staleness as the shared signal.*

---

### Part 2 — Housekeep KB-DELTA scoping change (FR-33)

**What changes:** `canonical/skills/aid-housekeep/references/state-kb-delta.md` (the canonical
source of the rendered `.claude/skills/aid-housekeep/references/state-kb-delta.md` read above).
The **SKILL.md state machine, the run-state file, the branch/commit machinery, the
Step 3 confirm-and-adjust gate, the Step 4 `/aid-discover` targeted re-entry, and the Steps 5–6
read-back/commit are all retained unchanged.** The **whole-KB content re-review is also
retained** — housekeep is the broad/global/periodic skill, so it still content-reviews every
doc. What Steps 1–2 change is **scoping and exit**: a **deterministic suspect pre-pass becomes a
prioritization + fast-no-drift-exit layer** over (not a replacement for) the whole-KB review,
replacing the git-delta-hint as the cheap drift signal.

#### The current scoping (to be replaced)

Today (`state-kb-delta.md` Steps 1–2, lines 56–102): Step 1 reads `**Last KB Review:**` as a
date hint and optionally `git log`/`git diff` since that date; Step 2 **autonomously re-reads
the whole KB** against the repo ("a purely git-scoped pass would miss drift … AC1 requires
catching that too"). The whole-KB content re-review is **correct and is kept** — it is what
catches a doc that was subtly-wrong-at-approval (AC1). The defect is only that the git range is
the *only* scoping signal: there is **no per-doc/source linkage** to prioritize the review or to
exit cheaply when nothing drifted — exactly the "no precision" hole §1.8 names.

#### The new scoping (suspect-driven prioritization over a retained whole-KB review)

Keep Step 2's whole-KB content re-review; add a deterministic pre-pass that **prioritizes** it
and supplies a **fast no-drift exit** — a **two-tier scope**, where Tier 1 is priority work and
Tier 2 is the retained whole-KB review:

**Step 1 (rewritten) — deterministic suspect pre-pass.** Run f007's check over the KB and
capture the per-doc verdicts as the precise, source-keyed drift signal:

```bash
bash .claude/aid/scripts/kb/kb-freshness-check.sh \
    --root .aid/knowledge --format tsv > "$SUSPECT_TSV"
# columns (f007): doc \t verdict \t approved_at_commit \t n_current \t n_suspect \t n_unknown \t suspect_sources_csv
```

The **`suspect`** rows are the **commit-graph-exact** set of docs whose `sources:` changed
after their `approved_at_commit:` baseline (f007 fold rule) — i.e. the docs the *source tree*
drifted away from. This is the source-driven-global signal, computed mechanically (no LLM, no
clock dependence — f007 determinism), and it **replaces the git-date hint as the cheap drift
signal that prioritizes the review and gates the fast exit** (it does *not* bound which docs are
content-reviewed). `suspect_sources_csv` names *which* source drifted each doc, so the reconcile
knows where to look **first**.

**Step 2 (rewritten) — prioritized review with a retained whole-KB content pass (two tiers).**

- **Tier 1 (priority scope, deterministic):** the **suspect docs** from Step 1 are the
  definite/priority re-review set. For each, read the doc + its `suspect_sources_csv` entries and
  plan the correction (the same per-doc "what drifted / what to change" analysis the current
  Step 2 does, but now driven by a precise source-keyed signal and ordered by drift). This is the
  cheap, precise drift signal that closes the §1.8 "no precision" hole — it tells housekeep
  exactly which docs definitely drifted and where.
- **Tier 2 (retained whole-KB content re-review — preserves AC1):** Tier 1 cannot be the whole
  story, because f007's signal is *source-keyed*: a `current` doc (f007: `sources:` at-or-before
  baseline) can still have a *summary* that silently **never matched reality** — the precise AC1
  "subtly-wrong-all-along" case that `state-kb-delta.md:84-85` requires the whole-KB re-read to
  catch. So Step 2 **retains the autonomous content re-review of ALL docs, including `current`
  ones** — no doc is skipped. The verdict only sets **priority**: `suspect` docs reviewed first
  (definite drift), `unknown` docs next (no baseline yet — f011 unstamped, so treated as
  un-cleared), and `current` docs still content-reviewed (lower priority, the signal giving
  confidence that they are *likely* clean but not *proven* summary-correct). The optimization is
  **prioritization + a fast no-drift exit**, not skipping any doc's content review.

> **Why the content review of `current` docs is retained.** A `current` verdict (f007) proves
> only **source-ancestry at-or-before baseline** — it says the doc's declared `sources:` have not
> moved since approval. It does **not** prove the doc's *summary* was ever correct: a doc can be
> subtly-wrong-at-approval with stable `sources:`. Dropping the content review for `current` docs
> would therefore drop AC1's exact coverage. f010 keeps it. The cost is acceptable because
> housekeep is the **broad/global/periodic** skill (its whole reason-for-being vs `aid-update-kb`'s
> targeted speed); the deterministic pre-pass makes the common "nothing drifted" run exit fast
> (below), so the retained review is the *thorough periodic* path, not the everyday one.

**Step 3 onward unchanged.** The confirm-and-adjust gate (Step 3), the `Impact: Required` Q&A +
`/aid-discover` targeted re-entry (Step 4), and the read-back/commit (Steps 5–6) are retained
verbatim — they already feed the f005 gate and are human-gated (NFR-6). The only edit is that
the **proposed scope presented at Step 3 is the set of docs the review found to have drifted**
(across all tiers — `suspect` docs that confirmed drift, plus any `unknown`/`current` doc whose
content review found a summary that no longer matches reality), each annotated by the signal that
flagged it:

```
KB drift detected (signal: kb-freshness-check suspect verdicts, prioritizing a whole-KB content review).
Proposed KB refresh scope:
  architecture.md   — suspect: <suspect_sources_csv> drifted
  module-map.md     — suspect: <suspect_sources_csv> drifted
  test-landscape.md — content drift (current-verdict doc; summary no longer matches repo — AC1 catch)
[1] Confirm — refresh this scope
[2] Adjust  — add/remove docs: ___
[3] Cancel  — stall this stage
```

**No-drift exit (AC4) refined.** The no-drift exit fires when **zero suspect docs AND the
retained whole-KB content review found nothing** — both the deterministic signal and the content
re-review must be clean before the run exits. The deterministic suspect count makes the *common*
case (no `suspect` docs) a far more confident, mostly-mechanical fast verdict than today's
all-judgment exit, while the retained content review still guards the AC1 subtly-wrong case
before the run is allowed to exit clean.

**Offline note retained.** The current housekeep "git-is-a-hint, no-hard-offline-gate" rule
(state-kb-delta.md's own inherited constraint — **not** this work's C2, which is
ASCII-only/PS-5.1) applies even more cleanly: `kb-freshness-check.sh` is **pure local git
plumbing** (f007 determinism — no network), so the suspect pre-pass needs no `git fetch`. The
optional `git fetch origin master`
to bring the local graph current (state-kb-delta Step 1, lines 62–74) is kept as a convenience
before the pre-pass; offline simply means "scope against the local graph", never a pause.

---

### Part 3 — Standing closure re-verify (FR-34)

Concept-closure (f004's `closure-check.sh`) becomes a **maintained invariant**: it is
re-verified after **every** KB change, by **both** mutating skills, so the KB cannot drift into
an undefined native term after a targeted edit *or* a reconcile sweep.

#### update-kb half — already in f008 (referenced, not duplicated)

`aid-update-kb`'s DONE state already re-runs the deterministic closure check before committing
(f008 SPEC lines 308–315, `state-done.md`): "before committing, re-run the deterministic closure
check (f004's `closure-check.sh`) over the changed KB to confirm the update left no native term
undefined — a standing invariant, not a discovery-only check." f008 also notes the
*who-runs-when boundary contract is f010's*. **f010 does not change update-kb;** it records the
update-kb half in the contract table (Part 1) and supplies the shared break-handling below.

#### housekeep half — new CLOSURE re-verify step (this feature)

`aid-housekeep` adds a closure re-verify **before** its KB refresh commits — **true f008 parity**
(f008 SPEC line 311 re-runs the closure check **"before committing"**, so it never commits a
hole). The cleanest wiring (C8 thin-router; no new state) is to insert it into KB-DELTA's passed
path **between the staged KB edits and Step 6's commit**: re-run f004's `closure-check.sh` over
the *refreshed (but not-yet-committed)* KB; only if closure is intact does Step 6 commit. The
invariant is thus checked on **exactly the runs that changed the KB**, and a broken closure
**stalls without committing the hole**:

```bash
# state-kb-delta.md, after the KB edits are staged but BEFORE Step 6's branch-commit.sh --commit:
bash .claude/aid/scripts/kb/closure-check.sh <f004-inputs> > "$CLOSURE_OUT" 2>&1 || CLOSURE_RC=$?
# closure intact -> proceed to Step 6 commit; closure broken -> stall+escalate, do NOT commit.
```

`closure-check.sh` (f004) deterministically reports any candidate-concept or spine relates-to
term that is **used in a KB doc but undefined in the spine** (f004 SPEC lines 437–446) — the
ungrounded-term set. Its **inputs** are f004's: `.aid/generated/candidate-concepts.md` (the term
universe) + the spine (`domain-glossary.md`) + the KB docs (f004 SPEC line 438). **Empty output
= closure intact** (the steady state); a non-empty set means the refresh introduced or exposed an
undefined native term.

> **[SPIKE-C2] — `closure-check.sh`'s exact CLI.** f004 specifies the script's **inputs**
> (candidate-concepts.md + spine + KB docs) and that it mirrors `build-kb-index.sh`'s shape, but
> does **not** pin the exact flag names (the `--root/--output/--denylist` invocation at f004 SPEC
> line 160 is `harvest-coined-terms.sh`'s, not closure-check's). The exact invocation
> (`<f004-inputs>` above) is f004's to define and f010's to call as-defined — the task-author
> wires the literal flags once f004 lands, not guessed here. **Dependency, not a blocker:** f010's
> contract is "re-run f004's closure oracle after a KB change", which holds for any input shape.

- **Closure intact (empty)** → write `**Closure:** verified` to the run-state, **then** let
  Step 6 commit the refresh and CHAIN to SUMMARY-DELTA. The standing invariant held; the commit
  ships a closed KB.
- **Closure broken (non-empty)** → handle per the **shared break-handling** below **before any
  commit**: escalate + stall with the refresh **uncommitted**, so the KB hole is **never
  committed to the housekeep branch** (f008 parity — f008 likewise stalls before committing).

**Run-on-skip note.** On the **no-drift / skipped** path (housekeep made no KB change) the
closure step is **not** run — closure was a standing invariant *before* this run and nothing
changed it, so re-verifying would be wasted work. The re-verify is wired only on the **passed**
path that is about to commit a KB change, and it runs **before** that commit (matching f008,
which verifies before committing an edit).

#### Break-handling (shared by both skills; reuses existing mechanisms)

When `closure-check.sh` reports an ungrounded term over the refreshed (not-yet-committed) KB, the
skill **does not auto-fix, does not commit, and does not silently proceed** (NFR-6 human-gated).
It **escalates as a finding +
Q&A** using the **exact existing mechanism** KB-DELTA already uses for scope (state-kb-delta
Step 4) and f008 uses for ungroundable concepts (f008 ANALYZE step 4): append one entry to
`.aid/knowledge/STATE.md ## Q&A (Pending)` in the canonical Style A schema:

```markdown
### Q{N}
- **Category:** Closure / Standing Invariant Break
- **Impact:** Required
- **Status:** Pending
- **Context:** A KB change by /aid-housekeep (KB-DELTA refresh) left native term(s) undefined
  in the spine: <ungrounded-term @ doc:anchor, …> (closure-check.sh output). The KB is no
  longer self-contained — a fresh reader cannot resolve these terms from the spine.
- **Suggested:** Ground each term into domain-glossary.md (a spine entry) via targeted
  re-discovery, or escalate if it cannot be grounded from the artifacts (FR-32), then re-verify.
```

Then the stage takes the **existing `stalled` exit** (state-kb-delta "Exit — stalled", lines
225–248) with `**Stall Reason:** closure invariant broken — undefined native term in the staged
KB refresh (not committed)`, and PAUSEs (PAUSE-FOR-USER-ACTION) **with the refresh uncommitted**.
Re-running `/aid-housekeep` resumes at KB-DELTA; once the term is grounded (and `closure-check.sh`
is empty), the stage advances and **then** commits. This reuses the
**existing Q&A queue, the existing `Impact: Required`→`/aid-discover` re-entry, and the existing
stalled-exit/resume** — **no new escalation mechanism is invented** (the f008 precedent for
update-kb's ungroundable-concept path is identical, so the two skills handle a closure break the
same way — the FR-34 shared contract).

> **Closure-break re-entry path (resolved — `Impact: Required` targeted re-entry naming the
> glossary owner).** KB-DELTA Step 4 writes an `Impact: Required` Q&A to drive `/aid-discover`'s
> **targeted re-entry** (which re-runs the owning sub-agents to refresh a *named* doc). A closure
> break names an *undefined term* — a spine/`domain-glossary.md` gap — rather than a drifted
> source doc. **Decision:** the closure-break Q&A routes to `/aid-discover`'s **targeted re-entry
> naming `domain-glossary.md` (the spine) plus the doc that uses the term** as the docs to
> refresh. This is chosen over directly triggering f004's INVESTIGATE/closure loop
> (`state-closure.md`) because targeted re-entry is the *existing, already-wired* escalation path
> KB-DELTA Step 4 uses — reusing it keeps f010 mechanism-free (no new routing), and the
> owning sub-agent for `domain-glossary.md` is exactly the one that runs the f004 spine
> grounding, so naming the glossary as the re-entry target reaches the same grounding loop. The
> task-author wires the re-entry to name `domain-glossary.md` + the using-doc; no new path is
> introduced. (This is a routing decision, not a spike — both candidate paths re-run the glossary
> owner, so the choice is settled here rather than deferred.)

---

### Part 4 — Recording the contract (durable artifact)

The boundary table (Part 1) is recorded in **two places** so it is durable and routable:

1. **The canonical skill-topology KB doc.** The §1.8 topology (`aid-discover` bulk · `aid-update-kb`
   targeted · `aid-query-kb` read · `aid-summarize` render · `aid-housekeep` periodic broad
   reconcile) is documented in the project KB; f010 appends the **housekeep-vs-update-kb boundary
   contract table + the shared-signal + no-overlap rules** to that doc so a maintainer (and the
   dashboard's routing surface) can look up which skill to run. **[SPIKE-K1]** — confirm the
   exact KB doc that owns skill topology in the *adopter-facing* canonical KB (vs. this repo's
   own `.aid/knowledge/`); the task-author resolves the precise file during /aid-detail (likely
   the architecture/pipeline-contracts doc that already lists the skills). Flagged because the
   doc identity is a render-time fact, not guessable from the requirements alone.
2. **Each skill's own description.** A one-line cross-reference in `aid-housekeep`'s SKILL.md
   description ("source-driven global reconcile; for a targeted prompt-named delta use
   `/aid-update-kb`") and the reciprocal in `aid-update-kb`'s description (f008 owns that edit),
   so the boundary is discoverable at the point of use.

---

### Constraints satisfied

- **Deterministic substrate (NFR-3, C5) — no new script.** f010 **reuses** f007's
  `kb-freshness-check.sh` (suspect pre-pass) and f004's `closure-check.sh` (closure re-verify).
  Both are pure git-plumbing + coreutils, byte-reproducible, CI-tested in their own features.
  f010 adds **zero new scripts and no new flags** — it only changes which existing-script output
  feeds the (already human-gated) state machine. The deterministic suspect set adds a mechanical
  **prioritization + fast-no-drift-exit** layer in front of the (retained) whole-KB content
  review, **raising** the deterministic fraction of the common run (NFR-3 honest floor) without
  dropping the AC1 content coverage.
- **Thin-router (C8).** No new state and no new skill: the scoping change is inside KB-DELTA's
  existing `state-kb-delta.md`; the closure re-verify is a step inserted into KB-DELTA's passed
  path **before** Step 6's commit. The thin-router `SKILL.md` + `references/state-*.md` shape is
  preserved (the Dispatch table, run-state file, and chaining are untouched).
- **Human-gated (NFR-6, C4, O2).** No auto-apply is introduced. The suspect pre-pass only
  *scopes* (auto-detect/flag, FR-7); the Step 3 confirm-and-adjust gate, the f005 review, and
  the human APPROVAL are all retained. A closure break **stalls and escalates a Q&A** — it never
  auto-edits the spine.
- **ASCII-only (C2).** f010 ships **no script** (the two it calls are f004/f007's, already
  ASCII-guarded by `test-ascii-only.sh`). The edited canonical skill markdown
  (`state-kb-delta.md`, SKILL.md description, the KB topology doc) stays ASCII — no non-ASCII
  glyphs introduced (the banners reuse the existing skill's already-shipped characters).

---

### Spikes (genuine unknowns flagged, not guessed)

> The closure-break `/aid-discover` re-entry path is **resolved inline** (Part 3,
> break-handling): targeted re-entry naming `domain-glossary.md` + the using-doc, reusing the
> existing KB-DELTA Step 4 escalation path. It is a routing decision, not an open spike.

- **[SPIKE-C2]** — `closure-check.sh`'s **exact CLI flags**. f004 defines the script's inputs
  (candidate-concepts.md + spine + KB docs) but not the literal flag names; f010 calls the oracle
  as f004 defines it. Dependency on f004 landing, not a design blocker.
- **[SPIKE-K1]** — the exact **adopter-facing KB doc** that owns skill topology and should carry
  the recorded boundary table (Part 4 item 1). The task-author resolves the precise file during
  /aid-detail; likely the architecture / pipeline-contracts doc already enumerating the skills.

---

### Files touched (canonical source only; f009 renders)

| Change | File | What |
|--------|------|------|
| **EDIT** scoping | `canonical/skills/aid-housekeep/references/state-kb-delta.md` | Steps 1–2 rewritten: add `kb-freshness-check.sh` suspect pre-pass as a **prioritization + fast-no-drift-exit** layer (Tier 1) over a **retained whole-KB content re-review of all docs incl. `current`** (Tier 2, preserves AC1); the git-date-hint stops being the scoping boundary; Step 3 scope/banner names the signal; no-drift exit refined. **+ wire the CLOSURE re-verify step BEFORE the KB-DELTA commit** (Part 3). |
| **EDIT** description | `canonical/skills/aid-housekeep/SKILL.md` | One-line boundary cross-reference in `description:` ("for a targeted prompt-named delta use `/aid-update-kb`"); KB-DELTA banner/desc copy aligned to "source-driven reconcile". No state-machine change. |
| **EDIT** contract record | the canonical skill-topology KB doc (**[SPIKE-K1]**) | Append the boundary contract table + shared-signal + no-overlap rules. |
| **REFERENCE only** | `canonical/skills/aid-update-kb/references/state-done.md` (f008) | update-kb's closure re-verify — cited as the update-kb half of FR-34, **not edited** here. |
| **CONSUMED** | `canonical/aid/scripts/kb/kb-freshness-check.sh` (f007), `canonical/aid/scripts/kb/closure-check.sh` (f004) | Called by housekeep; **not modified** (no new flags). |

> **Render note (f009).** Editing `canonical/skills/aid-housekeep/` leaves the rendered
> `.claude/skills/aid-housekeep/` (and the 5 host trees) stale → render-drift RED on the f010
> branch **by construction**; **f009** runs the generator and reconciles the host trees. f010
> edits `canonical/` only.

### CI / verification

- **Existing closure & freshness suites cover the helpers.** f004's
  `tests/canonical/test-closure-check.sh` and f007's freshness suite already assert the two
  scripts; f010 adds **no new script test** (nothing new to test at the script level).
- **f010's acceptance is behavioral** (per the feature ACs): (AC10/FR-33) housekeep does a
  whole-KB reconcile **prioritized by** the suspect set (whole-KB content review retained) while
  update-kb stays prompt-targeted with no overlap — verified by the rewritten `state-kb-delta.md`
  calling `kb-freshness-check.sh` for prioritization (grep guard: KB-DELTA references
  `kb-freshness-check.sh` and no longer relies on a git-date range as the scoping boundary);
  (FR-34) both skills re-run `closure-check.sh` **before committing** a KB change — verified by a
  grep guard that both `aid-housekeep/references/state-kb-delta.md` (passed path, pre-commit) and
  `aid-update-kb/references/state-done.md` reference `closure-check.sh`. These guards are the
  task-author's to wire during /aid-detail (a small `tests/canonical/` assertion or a doc-grep in
  an existing skill-shape test), keeping f010 dependency-free.

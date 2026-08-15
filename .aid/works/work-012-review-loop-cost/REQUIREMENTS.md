# Requirements

- **Name:** Scoped Review Cycles and Criterion Oracles
- **Description:** Cut the cost and the non-determinism of AID's review loop by scoping each cycle-2-and-later hunt for new findings to what the previous fix changed, and by letting a mechanically decidable criterion declare an executable oracle that is re-run instead of re-read.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-14 | Initial interview started | /aid-describe |
| 2026-08-14 | Requirements captured from `tech-debt.md` § L5 (the merged proposal) plus the requester's brief; every §2 figure and every edit site re-derived against this branch's disk | /aid-describe |
| 2026-08-14 | Identity fields confirmed: Scoped Review Cycles and Criterion Oracles | /aid-describe |
| 2026-08-14 | `work-011` reclassified from dependency to in-flight sibling (requester correction): it is still being processed, so nothing here may depend on its artifacts. AC-1's measurement made instrument-neutral, and C-2 added | /aid-describe |
| 2026-08-14 | **Dependency set closed at one (owner decision).** `work-004` is the sole dependency; C-1 now says so and forbids another without an amendment. §4's out-of-scope bullet generalised from `work-011` to any in-flight work, and §8's conditional meter reuse withdrawn — FR-15 measures with its own local count | /aid-describe |
| 2026-08-14 | **`work-004` merged to `master`.** C-1 restated from "pending merge" to landed; the work's one dependency is now on the mainline, so nothing it needs is in flight | /aid-describe |
| 2026-08-14 | **Q-01 answered (owner).** NFR-1's exit criterion ratified as drafted: an oracle ships only where it replaces recurring human re-derivation, and the trade is measured. Two rejected alternatives recorded with their reasons | owner |
| 2026-08-14 | **Q-02 answered (owner).** An `oracle:` value is a repo-root-relative path and oracles live outside `canonical/` — one resolution rule for AID and adopters alike, and no oracle in the render chain. FR-8 and NFR-5 updated | owner |
| 2026-08-14 | **`work-009` merged; state format 3 → 4.** This work's `STATE.md` converted to `STATE.yml`; the two cross-references above re-pointed. No requirement changed — the merge touches none of the four L5 edit sites | /aid-describe |
| 2026-08-14 | **Q-03 answered (owner).** The measurement subject is named at Define rather than now, so the choice rests on the gate inventory Define produces. AC-1 and §10 step 1 record it as a Define deliverable owed before Specify | owner |
| 2026-08-15 | **`work-009` and the `aid-graph` removal merged.** All ten grounding claims re-verified; no requirement changed by either merge | /aid-describe |
| 2026-08-15 | **Q-04 answered (owner).** Oracle generation is lazy — the trigger is a second re-derivation of the same criterion, so the payback evidence precedes the script. FR-10 carries the rule; FR-13 records why `G-07` is not delayed by it. **All four questions now answered** | owner |
| 2026-08-15 | **Path confirmed full, with a hard size cap (owner decision).** `/aid-refactor` rejected — it is defined as behavior-preserving and this work changes behavior by design. The Lite path was rejected for a sharper reason: it yields one gate, and AC-1 needs more than one to produce a before-and-after. New **C-7** caps the work at 3 features and 2 deliveries, and forbids Define exceeding it silently | owner |
| 2026-08-15 | Interview complete — approved | /aid-describe |
| 2026-08-15 | **Decomposed into 3 features (owner-approved), at the C-7 ceiling.** All 15 FRs and all 12 ACs map, none twice. FR-14 and the NFR-5 close-out folded into feature-003 rather than becoming a fourth feature | /aid-define |
| 2026-08-15 | **Q-03 discharged.** AC-1's measurement subject named from the now-known gate inventory: this work's own per-task review cycles during Execute, split at FR-3's task. AC-1 updated, and the resulting sequencing constraint recorded for `/aid-plan` | /aid-define |
| 2026-08-15 | **C-5 authorized (owner), enumerated to three edits** — the `oracle:` field, the `Match` selector column, and the scoped-cycle note in `authoring-conventions.md`. §4's In Scope list also gained the KB file, which L5 names as an edit site and two feature SPECs require but this list had omitted | owner |
| 2026-08-15 | **Q-05 answered (owner):** add a `work-artifact` type to the registry with criteria, routed to `/aid-discover`. Not absorbed here — the C-5 authorization is enumerated, §4 keeps the cascade out of scope, and C-7 caps the feature count. Q&A backlog now fully answered | owner |
| 2026-08-15 | **Cross-reference cycle 1 fixes (grade C+).** Four requirements were demanded by no criterion — **AC-13** added for FR-5, **AC-14/AC-15/AC-16** for FR-9/FR-10/FR-11. **AC-1 re-specified** around cycles-to-close plus a within-task re-read ratio, so task-size heterogeneity cancels instead of confounding the result; a raw cross-task byte comparison is now explicitly refused. FR-14's citation corrected to a durable anchor | /aid-define |
| 2026-08-15 | **Cross-reference cycle 2 fixes (grade D+ — it went down).** The cycle-1 fix left `feature-001`'s SPEC restating the old AC-1, contradicting §9 — a requirement and a feature spec disagreeing about a shared fact, which is the exact failure class this work exists to address. Realigned, and both `feature-002` and `feature-003` had their `## Source` lists brought back in step with their criteria | /aid-define |
| 2026-08-15 | **Cross-reference PASSED at A+ (cycle 3).** 9 findings Fixed, 1 routed OOS to `/aid-discover` as Q-05, 0 counting toward the grade against a minimum of A. Define complete; ready for `/aid-specify` | /aid-define |

## 1. Objective

Review gates are the dominant cost line in an AID work, and a large part of that cost
buys nothing: the same artifact is re-read on every cycle, and the same criterion is
re-decided by a reviewer reading it on every cycle — including criteria a script could
decide once and answer identically forever.

Reduce that cost, measurably, without weakening adversarial review. Two remedies that
each fix the other's weakness, delivered as one work.

## 2. Problem Statement

One problem, two causes, recorded in full at `.aid/knowledge/tech-debt.md`
§ "[MEDIUM] L5 -- The review loop re-reads everything, and re-judges what it could run".

**The cost, measured.** Modelled against this project's observed averages for a full-path
work (3-4 features, 4-5 deliveries, 16-25 tasks, 5-7 review cycles per gate), review gates
account for roughly 61-65% of total work cost — about 4.7x to 6.7x the cost of authoring
the documents being reviewed. A requirements document of ~88 KB is re-read 15 to 28 times
inside the per-feature specify gates alone. Independently observed on a later work:
re-reading the same feature specs across gate cycles cost roughly 1.9M input tokens
against ~452k output tokens to author all thirteen specs once. Of 25 gate cycles recorded
on that work, four moved the grade zero.

**Cause (a) — the cycle hunt is unbounded.** `canonical/aid/templates/reviewer-ledger-schema.md`
§ "Status values" describes the cycle-2-and-later workflow. Everything in it is already
targeted and cheap — verify each `Pending` row on disk, promote to `Fixed`, demote a
regressed `Fixed` to `Recurred` — until its last sentence, *"Append new rows as `Pending`
for newly-found issues"*. Finding NEW issues means re-scanning the whole surface, so one
clause makes every cycle pay a full read. `.aid/settings.yml` records the consequence in
its floor-history comment: five consecutive Large-tier gate cycles each closed about
twelve findings and opened about twelve, the ledger growing 30 to 43 to 62 to 73 to 85
with no decline in the new-finding rate.

**Cause (b) — a decidable criterion is still decided by reading.** Every criterion in
`.aid/knowledge/authoring-conventions.md` § "Review Criteria — Criteria by Level" is
verified by a reviewer reading it, every cycle, forever. For a genuinely semantic
criterion that is unavoidable. For a mechanically decidable one it is both waste and a
reliability problem: `G-07` ("Every in-scope markdown file resolves to exactly one type in
the registry above") is re-derived by hand each cycle — read the registry, read the corpus
definition, enumerate files, apply each selector — which is expensive and inconsistent
between cycles.

**Why the two are one item.** A scoped cycle is only sound for criteria that can be
*evaluated* against a subset, and evaluation scope varies per criterion: `G-01` fires on a
local occurrence, `KB-02` needs the whole file, `G-07` needs the whole corpus. A criterion
carrying an oracle is re-run at any scope for negligible cost, so its evaluation scope
stops mattering. Remedy 2 therefore removes remedy 1's sharpest objection instead of
guarding around it.

## 3. Users & Stakeholders

| Who | Interest |
|-----|----------|
| Repo owner | cost per work; the review guarantees are not negotiable |
| Adopting teams | the same pipeline, cheaper, with no new runtime dependency |
| `aid-reviewer` (dispatched) | a bounded surface per cycle, and provable rather than asserted coverage |
| Executing and fixing agents | fewer findings re-litigated cycle after cycle |
| KB maintainer | one new optional frontmatter key, and no migration across the criteria already declared |

## 4. Scope

### In Scope

- Splitting the cycle-2-and-later clause in `reviewer-ledger-schema.md` into full ledger
  verification plus scoped new-finding discovery.
- The definition of the scoped surface, including its mechanical cross-reference expansion.
- Moving the cross-document contradiction pass to once per phase.
- A final full pass before approval, as the backstop.
- One new OPTIONAL `oracle:` key on a `review-criteria:` entry, with its reader and runner
  contract and its degradation behaviour.
- `G-07`'s oracle as the worked example.
- Carrying the changed-section set and the scoped surface through
  `canonical/aid/templates/reviewer-dispatch.md` (`ARTIFACTS UNDER REVIEW` and `RUBRIC`)
  and the six `canonical/skills/*/references/reviewer-brief.md` files
  (`aid-define`, `aid-detail`, `aid-discover`, `aid-execute`, `aid-plan`, `aid-specify`).
- Passing a per-feature specify gate only the requirements slice that feature traces to,
  instead of the whole `REQUIREMENTS.md`.
- **The criteria-table edits in `.aid/knowledge/authoring-conventions.md`** — the `oracle:`
  field, the `Match` selector column, and the scoped-cycle note. This is the fourth edit
  site L5 names, and it was missing from this list while being required by two feature
  SPECs; a later phase could have read the omission as "out of scope". Authorized under C-5.
- Measuring the reduction before and after, on a real artifact.

### Out of Scope

- The grading scale, the ledger's column count, and `canonical/aid/scripts/grade.sh` — all
  three are untouched.
- The criteria cascade itself. Resolution stays scope-free and needs no change.
- A migration across criteria already declared: `oracle:` is a pure addition, so an
  existing entry without it is untouched and correct.
- Anything from another in-flight work. `work-004` is the only dependency (C-1); every
  other live work, `work-011` included, is a read-only reference this work coordinates
  with and depends on in no part (C-2).
- Runtime token accounting that needs host cooperation. This work measures what it can
  measure deterministically on disk plus whatever the host already reports.
- Any change that buys cost by removing a review guarantee (see NFR-4).

## 5. Functional Requirements

**Remedy 1 — scope the cycle-2-and-later hunt**

- **FR-1** Cycle 1 reads the whole artifact. Unchanged.
- **FR-2** On cycle 2 and later the reviewer verifies EVERY existing ledger row in full.
  Verification is never scoped; only discovery is.
- **FR-3** On cycle 2 and later the hunt for NEW findings is bounded to the scoped
  surface: what the previous FIX changed.
- **FR-4** The scoped surface is expanded to include the sections that REFERENCE the
  changed ones, by mechanical cross-reference lookup — deterministic, reproducible, and
  not a model judgment call.
- **FR-5** The cross-document contradiction pass is kept, and runs once per PHASE rather
  than once per cycle per feature.
- **FR-6** A final full pass runs before approval. A scoped cycle never approves an
  artifact on its own.
- **FR-7** A finding missed by a scoped cycle has a home: the existing `Recurred` status
  and the FR-6 final pass are the backstop, and no new status or column is added for it.

**Remedy 2 — an optional `oracle:` on a criterion**

- **FR-8** A `review-criteria:` entry MAY carry one optional `oracle:` key naming an
  executable check. Its absence is never a defect and never a finding. The value is a path
  resolved from the repo root, and an oracle lives OUTSIDE `canonical/` — one resolution
  rule for AID's own criteria and an adopter's alike, because a criterion is
  project-specific and its oracle is the executable half of it (owner decision, STATE.yml
  Q-02).
- **FR-9** A criterion carrying an oracle is decided by RUNNING the oracle rather than by
  a reviewer re-reading the criterion.
- **FR-10** An oracle is generated once, in the project's own terms, and is then re-run
  unchanged on every cycle. **Generation is LAZY** (owner decision, STATE.yml Q-04): the
  trigger is a reviewer re-deriving the same criterion a second time, so the evidence that
  the oracle pays for itself exists before the script does. This is what enforces NFR-1
  rather than trusting it — an author is never asked to predict recurrence.
- **FR-11** An oracle's verdict maps into the existing ledger without changing its shape:
  the criterion `id` stays a prefix in the `Description` cell, and the oracle's invocation
  and output go in `Evidence`.
- **FR-12** An oracle that is missing, non-executable, or that crashes DEGRADES to the
  existing read-based judgment and reports the degradation. It never silently passes and
  never silently fails the criterion.
- **FR-13** `G-07` ships an oracle as the worked example. It does not wait on FR-10's lazy
  trigger: L5 already records `G-07` being re-derived by hand every cycle, so its
  recurrence evidence predates the rule rather than needing to be gathered under it.

**Related, at the same edit sites**

- **FR-14** A per-feature specify gate receives only the slice of `REQUIREMENTS.md` that
  the feature traces to, not the whole document. The current sites are
  `canonical/skills/aid-specify/references/state-initialize.md` — under the heading
  `### Step 1: Load Full Context`, the list item reading "**REQUIREMENTS.md** — full
  requirements for cross-reference" — and
  `canonical/skills/aid-specify/references/state-review.md`, the line "Same as INITIALIZE
  Step 1".

**Measurement**

- **FR-15** The reduction is measured, not asserted: a before figure is captured on a real
  artifact BEFORE any remedy lands, and the same measurement is repeated after.

## 6. Non-Functional Requirements

- **NFR-1 — the oracle must pay for itself, and the trade is measured.**
  `work-004` revised its NFR-2 so that the "added mechanism" side counts EXECUTABLE
  surface only, with authored instruction explicitly not counting. Every oracle is a
  script, so this work adds executable surface BY DESIGN and is the first work where that
  definition bites. The exit criterion is therefore not "add no mechanism" but:
  **an oracle is justified only where it REPLACES recurring human re-derivation, and the
  work measures that trade rather than asserting it.** Each oracle shipped records what
  re-derivation it replaces and what that re-derivation costs per cycle; the work reports
  the net. An oracle that replaces nothing recurring is not shipped.
  **Owner-ratified 2026-08-14** (STATE.yml Q-01). A hard numeric cap on oracle count was
  considered and rejected as a figure with nothing to ground it; justifying an oracle by
  determinism alone was rejected because it removes the only test that stops oracles
  accumulating on criteria nobody re-derives.
- **NFR-2** No new runtime dependency on the core path. Core AID installs assume neither
  node nor python, so an oracle on the core path is bash plus awk.
- **NFR-3** An oracle is deterministic: two runs over an unchanged tree produce the same
  verdict and the same output.
- **NFR-4** No change weakens grounding, instruction, or adversarial review. A change that
  reduces cost by removing a guarantee is out of scope, not a trade-off to weigh.
- **NFR-5** Every derived chain — the five `profiles/` trees and the two tracked dogfood
  trees — is refreshed exactly once, at the end. Mid-work staleness is expected and is not
  a defect. No oracle enters that chain: FR-8 places them outside `canonical/`, so an
  oracle is never multiplied across the seven rendered trees.
- **NFR-6** Edits stay additive and localized wherever a contended file is touched, so a
  later reconcile with an in-flight sibling work stays cheap.

## 7. Constraints

- **C-1** **`work-004` is this work's only dependency, and it has landed.** It merged to
  `master` on 2026-08-14, so its declared-criteria mechanism — the type registry, the
  criteria-by-level table, and the `review-criteria:` frontmatter field — is now on the
  mainline and is the substrate both remedies extend. This work is therefore unblocked:
  nothing it needs is in flight. Nothing else is depended on, and no other in-flight work
  may become a dependency without an explicit owner decision that amends this constraint.
- **C-2** Every other live work is a read-only reference. `work-011` in particular is in
  flight and unmerged, and nothing here depends on it — not its folded artifact shape, not
  its traceability ids, not its cost meter. One file overlaps,
  `.aid/knowledge/authoring-conventions.md`, in different sections (that work removes the
  Change Log section; this work touches the criteria tables), so the overlap is a merge
  reconcile, not a design coupling.
- **C-3** The ledger keeps its 7 columns and `grade.sh` keeps its positional parse. Both
  stay byte-identical.
- **C-4** Criteria resolution stays scope-free: a file's resolved list depends only on its
  path and frontmatter, never on its content. Remedy 1 needs no change to resolution.
- **C-5** `.aid/knowledge/` edits happen only with explicit owner authorization.
  **AUTHORIZED 2026-08-15, for this work, scoped to `.aid/knowledge/authoring-conventions.md`
  and to these three edits only:**
  1. the optional `oracle:` field on a declared criterion (FR-8);
  2. the machine-readable `Match` column on the type registry, alongside the retained prose
     `Selector` — eight rows gain a cell, `template-payload` and `template-own` do not
     (feature-002 SPEC);
  3. the scoped-cycle note on the criteria table (feature-003 SPEC).

  The authorization is deliberately enumerated rather than blanket. Any other
  `.aid/knowledge/` edit — including any change to what an existing selector *means*, as
  opposed to how it is written — is not covered and needs a fresh ask. §4 keeps the criteria
  cascade itself out of scope, and this authorization does not widen that.
- **C-6** Nothing merges without explicit owner authorization.
- **C-7** **Hard cap on the pipeline's own size: at most 3 features and at most 2
  deliveries** (owner decision, 2026-08-15). The full path is kept only because AC-1 needs
  more than one gate to produce a before-and-after figure — a single-gate Lite work cannot
  measure itself. It is NOT kept for ceremony, so the gate count is bounded at the point it
  is created rather than left to grow.
  - The natural decomposition fits inside the cap without straining: **measurement**
    (FR-15), **the oracle mechanism** (FR-8 to FR-13), and **scoped cycles** (FR-1 to
    FR-7). FR-14 folds into the scoping feature — it edits the same sites — and the NFR-5
    close-out folds into the last delivery rather than becoming a feature of its own.
  - The cap is a **ceiling, not a target**. Fewer is better if the work fits.
  - **Define may not exceed it silently.** If the decomposition cannot fit, or if the cap
    would leave too few gate cycles for AC-1 to show a reduction, Define stops and
    escalates to the owner. Quietly adding a fourth feature to make the work comfortable is
    the failure this constraint exists to prevent — this is a work about review cost, and
    its own gate count is the first place that claim is tested.

## 8. Assumptions & Dependencies

- A `review-criteria:` entry tolerates unknown keys
  (`canonical/aid/templates/kb-authoring/frontmatter-schema.md` § "Parsing rules (for
  tools)", the paragraph beginning "The same tolerance applies one level down"), so
  `oracle:` is a new key and a new reader, not a migration across every criterion already
  declared.
- Because resolution is scope-free, the criteria list for a section IS the list for its
  file — which is what makes a scoped surface resolvable at all.
- `Recurred` already exists in the Status enum, so a finding that a scoped cycle misses
  and a later cycle re-finds has a correct status without any enum change.
- Token figures are estimates unless the host reports them; byte counts measured from disk
  are authoritative in any gate.
- **FR-15 stands on its own instrument.** The before-and-after figures are taken with a
  local, deterministic byte-and-cycle count, so AC-1 is satisfiable with `work-004` alone.
  Adopting another work's meter instead would be an owner decision amending C-1, not a
  fallback this work plans around.

## 9. Acceptance Criteria

- **AC-1** **The reduction is observed, not claimed.** Measured before any remedy lands and
  again after, with both figures recorded together with the command that produced them. A
  criterion satisfied merely by the change existing is not accepted.

  **The measurement subject was named at Define** (Q-03, now discharged): this work's own
  **per-task review cycles during Execute**, split at the task that lands FR-3, with the
  delivery-002 gate as a secondary reading. The specify gates were rejected as the subject —
  all three run before any code lands, so they yield no "after". This puts a sequencing
  constraint on `/aid-plan`: FR-3's task lands early in delivery-002, or the "after" sample
  is too small to compare.

  **Two metrics, both chosen to survive the fact that no two tasks are the same size:**
  1. **Cycles to close** — how many review cycles a task takes to reach its grade. A count,
     unaffected by task size, and the mechanism this work acts on directly.
  2. **The within-task re-read ratio** — bytes read on cycles 2+ as a fraction of the bytes
     that same task's cycle 1 read. **Each task is its own control**, so task-size
     heterogeneity cancels rather than being argued away. Under today's rule the ratio sits
     near 1.0 because every cycle re-reads everything; under FR-3 it must fall.

  A raw cross-task byte comparison is **not** an accepted form of this evidence: a smaller
  later task reads fewer bytes whether or not the remedy works.
- **AC-2** A defect seeded in a section that REFERENCES a changed section is found by a
  scoped cycle. This is FR-4's guard, tested rather than trusted.
- **AC-3** A defect seeded OUTSIDE the scoped surface, and consequently missed by a scoped
  cycle, is caught by the FR-6 final full pass. The backstop is demonstrated end to end.
- **AC-4** Ledger verification is provably unscoped: a `Fixed` row that regresses in a
  section outside the scoped surface is still demoted to `Recurred` on the next cycle.
- **AC-5** A criterion with no `oracle:` key produces no finding and grades exactly as it
  does today. Absence is not a defect — asserted as a positive control, not as prose.
- **AC-6** `G-07`'s oracle exits 0 over a corpus where every in-scope markdown file
  resolves to exactly one registry type, and non-zero — naming the offending file — over a
  corpus containing an untyped or a double-typed file.
- **AC-7** `G-07`'s oracle run twice over an unchanged tree produces byte-identical output
  (NFR-3).
- **AC-8** A criterion whose oracle is missing or non-executable is reviewed by reading and
  the degradation is reported in the ledger (FR-12).
- **AC-9** The specify gate carries the traced requirements slice rather than the whole
  document, and the saving is stated as a measured byte reduction on a real feature.
- **AC-10** The ledger is still 7 columns, and `canonical/aid/scripts/grade.sh` is
  byte-identical to its state at the start of this work.
- **AC-11** Every oracle shipped names the recurring re-derivation it replaces and the
  measured per-cycle cost of that re-derivation, and the work reports the net trade
  (NFR-1). An oracle with no recorded replacement is not shipped.
- **AC-12** The render-drift gate and the dogfood byte-identity gate are green at close
  (NFR-5).
- **AC-13** **(FR-5)** The cross-document contradiction pass runs **once per phase**, not
  once per cycle per feature: across a phase whose gate runs N ≥ 2 cycles over more than
  one feature, the pass executes exactly once, and a contradiction spanning two features is
  still caught by it. Both halves are required — a pass that runs once but stops catching
  the thing it exists for is a regression, not a saving.
- **AC-14** **(FR-9)** A criterion carrying an oracle is decided by **running** it: the
  verdict recorded for that criterion traces to the oracle's exit status, not to a
  reviewer's re-reading.
- **AC-15** **(FR-10)** Oracle generation is lazy: given a criterion re-derived only once,
  no oracle exists for it; the second re-derivation is what triggers authoring. `G-07` is
  the recorded exception — its recurrence predates the rule (FR-13).
- **AC-16** **(FR-11)** An oracle verdict is recorded in the existing ledger with the
  criterion `id` as a `Description` prefix and the oracle's invocation and output in
  `Evidence` — 7 columns, no new column, and `grade.sh`'s positional parse untouched (C-3).

## 10. Priority

Sequenced inside C-7's cap of at most 3 features and at most 2 deliveries.

1. **FR-15 first.** The baseline must be captured before any remedy lands, or AC-1 is
   unprovable for the rest of the work. Define names the measurement subject (Q-03) as its
   own deliverable, so the baseline can be taken the moment Specify opens.
2. **Remedy 2 next (FR-8 to FR-13).** Sequencing it before or alongside remedy 1 removes
   remedy 1's correctness objection rather than guarding around it, and `G-07` — the worst
   case for scoping — becomes the worked example that proves the point.
3. **Remedy 1 (FR-1 to FR-7).** The scoping change, with all three guards landing with it
   and not after it.
4. **FR-14.** The requirements-slice win, at the same edit sites, once the scoped-surface
   vocabulary those sites need already exists.
5. **Close-out.** The measured after-figure, the NFR-1 trade report, and the single render.

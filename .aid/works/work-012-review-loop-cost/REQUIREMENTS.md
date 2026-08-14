# Requirements

- **Name:** Scoped Review Cycles and Criterion Oracles
- **Description:** Cut the cost and the non-determinism of AID's review loop by scoping each cycle-2-and-later hunt for new findings to what the previous fix changed, and by letting a mechanically decidable criterion declare an executable oracle that is re-run instead of re-read.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-14 | Initial interview started | /aid-describe |
| 2026-08-14 | Requirements captured from `tech-debt.md` § L5 (the merged proposal) plus the requester's brief; every §2 figure and every edit site re-derived against this branch's disk | /aid-describe |
| 2026-08-14 | Identity fields confirmed: Scoped Review Cycles and Criterion Oracles | /aid-describe |
| 2026-08-14 | `work-011` reclassified from dependency to in-flight sibling (requester correction): it is still being processed, so nothing here may depend on its artifacts. AC-1's measurement made instrument-neutral, C-2 added, and the `tests/cost-meter.py` reuse moved to §8 as a conditional | /aid-describe |

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
- Measuring the reduction before and after, on a real artifact.

### Out of Scope

- The grading scale, the ledger's column count, and `canonical/aid/scripts/grade.sh` — all
  three are untouched.
- The criteria cascade itself. Resolution stays scope-free and needs no change.
- A migration across criteria already declared: `oracle:` is a pure addition, so an
  existing entry without it is untouched and correct.
- `work-011`'s artifact folding and its `tests/cost-meter.py`. That work is still being
  processed and is not merged; this work coordinates with it and depends on none of it
  (see C-2, and §8 for the conditional reuse).
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
  executable check. Its absence is never a defect and never a finding.
- **FR-9** A criterion carrying an oracle is decided by RUNNING the oracle rather than by
  a reviewer re-reading the criterion.
- **FR-10** An oracle is generated once, in the project's own terms, and is then re-run
  unchanged on every cycle.
- **FR-11** An oracle's verdict maps into the existing ledger without changing its shape:
  the criterion `id` stays a prefix in the `Description` cell, and the oracle's invocation
  and output go in `Evidence`.
- **FR-12** An oracle that is missing, non-executable, or that crashes DEGRADES to the
  existing read-based judgment and reports the degradation. It never silently passes and
  never silently fails the criterion.
- **FR-13** `G-07` ships an oracle as the worked example.

**Related, at the same edit sites**

- **FR-14** A per-feature specify gate receives only the slice of `REQUIREMENTS.md` that
  the feature traces to, not the whole document. The current sites are
  `canonical/skills/aid-specify/references/state-initialize.md` (step 2, "full requirements
  for cross-reference") and `canonical/skills/aid-specify/references/state-review.md`
  ("Same as INITIALIZE Step 1").

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
- **NFR-2** No new runtime dependency on the core path. Core AID installs assume neither
  node nor python, so an oracle on the core path is bash plus awk.
- **NFR-3** An oracle is deterministic: two runs over an unchanged tree produce the same
  verdict and the same output.
- **NFR-4** No change weakens grounding, instruction, or adversarial review. A change that
  reduces cost by removing a guarantee is out of scope, not a trade-off to weigh.
- **NFR-5** Every derived chain — the five `profiles/` trees and the two tracked dogfood
  trees — is refreshed exactly once, at the end. Mid-work staleness is expected and is not
  a defect.
- **NFR-6** Edits stay additive and localized wherever a contended file is touched, so a
  later reconcile with an in-flight sibling work stays cheap.

## 7. Constraints

- **C-1** This work is based on `work-004`, which is pending merge. Its declared-criteria
  mechanism — the type registry, the criteria-by-level table, and the `review-criteria:`
  frontmatter field — is the substrate both remedies extend.
- **C-2** `work-011` is in flight and NOT merged. No artifact of this work may depend on
  it: not the folded `REQUIREMENTS.md § 11` shape, not `PLAN.md` absorbing `BLUEPRINT.md`,
  not `AC-N` traceability, and not `tests/cost-meter.py`. One file overlaps —
  `.aid/knowledge/authoring-conventions.md` — in different sections (that work removes the
  Change Log section; this work touches the criteria tables), so the overlap is a merge
  reconcile, not a design coupling.
- **C-3** The ledger keeps its 7 columns and `grade.sh` keeps its positional parse. Both
  stay byte-identical.
- **C-4** Criteria resolution stays scope-free: a file's resolved list depends only on its
  path and frontmatter, never on its content. Remedy 1 needs no change to resolution.
- **C-5** `.aid/knowledge/` edits happen only with explicit owner authorization.
- **C-6** Nothing merges without explicit owner authorization.

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
- **Conditional, not a dependency:** if `work-011` lands before this work's measurement
  step, reuse its `tests/cost-meter.py` rather than building a second meter. If it has not
  landed, FR-15's measurement is taken with a local, deterministic byte-and-cycle count.
  Either way AC-1 is satisfiable without `work-011`.

## 9. Acceptance Criteria

- **AC-1** **The reduction is observed, not claimed.** On one real artifact, the cost of a
  gate — read bytes, and tokens where the host reports them, and cycles — is measured
  before any remedy lands and again after. The after figure is lower, and both figures are
  recorded with the command that produced them. A criterion satisfied merely by the change
  existing is not accepted.
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

## 10. Priority

1. **FR-15 first.** The baseline must be captured before any remedy lands, or AC-1 is
   unprovable for the rest of the work.
2. **Remedy 2 next (FR-8 to FR-13).** Sequencing it before or alongside remedy 1 removes
   remedy 1's correctness objection rather than guarding around it, and `G-07` — the worst
   case for scoping — becomes the worked example that proves the point.
3. **Remedy 1 (FR-1 to FR-7).** The scoping change, with all three guards landing with it
   and not after it.
4. **FR-14.** The requirements-slice win, at the same edit sites, once the scoped-surface
   vocabulary those sites need already exists.
5. **Close-out.** The measured after-figure, the NFR-1 trade report, and the single render.

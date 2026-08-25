# Delivery BLUEPRINT -- delivery-002: An Honest Grade

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.yml.

> **Delivery:** delivery-002
> **Work:** work-013-review-stack-completion
> **Created:** 2026-08-17

---

## Objective

With one stack and its blind spots closed by delivery-001, the last question is whether the grade
means anything. Four gaps remain. A severity can be asserted without a reason, so a finding's band
cannot be argued with. A new review cycle is *told* not to read the previous cycle's ledger, and
being told is not the same as being unable — the intent was defeated the first time it was tested.
Nobody knows what fraction of real defects a review actually finds, so a review getting worse at
finding them would be invisible. And a fix that repairs one instance of a defect leaves its
siblings in place, to be rediscovered one at a time. This delivery closes all four: every finding
carries a one-line why naming the consequence, a new cycle is structurally unable to reach the
prior ledger, recall against a seeded-defect corpus is measured and reported, and a class sweep
becomes part of closing a fix. It is a distinct unit because its feature **edits**
`reviewer-ledger-schema.md`, the one file delivery-001's feature-001 requires **unchanged** — a
contradiction a shared gate would have to resolve, rather than an ordering a task list can. The
boundary lets each gate diff against its own recorded base.

## Scope

- **feature-003-severity-and-recall-measurement** — the why-line inside the existing seven columns,
  composing with a criterion's declared `severity:` as the default band and recording any
  divergence; structural clean-context isolation for a new cycle, proven by an attempted path and
  its failure; a seeded-defect corpus with a recall report per rule set and overall; a class sweep
  that closes a FIX, proven by a seeded second instance; and the observe-only boundary that keeps a
  mechanical check's output out of the ledger while an oracle's `VIOLATION` stays an ordinary
  criteria finding.

**Out of scope:** feature-001 and feature-002 (delivery-001 — this delivery branches from their
merged state and rebases onto both). Changing `grade.sh` counting logic or the seven-column shape:
the why-line lives inside existing columns, and NFR-1 is the sharpest constraint on this delivery.
Allocating a criterion id for a recall regression without an owner decision — Q9 governs that.
Re-litigating the criteria cascade, VERIFY/HUNT, the cost meter or the single review path, all
settled by delivery-001.

## Gate Criteria

- [ ] The why-line screen, run on this delivery's own real ledger, reports `rows=N why-line=N`
      with the `missing:` and `no-provenance:` lists both empty; any residue rows are read and
      reported **by row number**, because the grep decides form and not substance. Baseline before
      the change, measured on the last real ledger: `rows=2 why-line=0`. *(FR-C1; §9 AC-9, and the
      command Q8 asked for)*
- [ ] The three documented attempts to reach a prior cycle's ledger are recorded with their exit
      codes, and `tests/canonical/test-ledger-isolation.sh` passes: the literal-path canary at `0`,
      and the cycle-1 preflight **failing loudly** on a seeded leftover inside a `mktemp -d` copy —
      never against the live tree. *(FR-C2; §9 AC-4)*
- [ ] `bash tests/review-recall.sh report --ledger <path>` prints one row per criterion scope
      prefix plus `ALL`, each carrying `seeded` and `found` as raw counts rather than a stored
      ratio, and reports a `seeded=0` group as **missing** rather than as 100%. Its stdout is
      recorded. *(FR-C4; §9 AC-4)*
- [ ] A FIX commit carries `Sweep-class`, `Sweep-command` and `Sweep-residue`; re-running the
      recorded command reproduces the recorded residue; and the suite asserts all four sweep steps
      **including a residue of `1` after a single-instance fix**, so a sweep that finds nothing
      cannot pass as a sweep that ran. *(FR-C5; §9 AC-10)*
- [ ] **SHOULD** — one review demonstrates a coverage unit that is not a file: its cycle-2 brief
      names `<path> § <heading>` under HUNT, and its `review-cost.tsv` row is no longer twice the
      file size, closing the measured `84934 = 2 × 42467` double count. *(FR-C3; synthesized
      criterion — subject to Q9)*
- [ ] **SHOULD** — `bash scripts/checks/g07-selector-partition.sh` exits `0` with `76 UNDECIDED`
      and `0 VIOLATION`, and produces **zero** ledger rows from that run; `test-criterion-oracles.sh`
      still passes beside the new observe-only assertions. *(FR-C6; synthesized criterion — subject
      to Q9)*
- [ ] `tests/review-recall.sh` cites the measured re-derivation it removes. **If that figure falls
      below the stated floor the script does not merge**, and that outcome is recorded as a
      discharge rather than a skip. *(NFR-3; §9 AC-5)*
- [ ] `git diff <recorded-base> HEAD -- canonical/aid/scripts/grade.sh` is **empty**, and the
      schema's non-empty diff touches neither counting logic nor column shape — verified three
      ways: the header row still yields one match, the severity and status enums and the status
      table are unchanged, and the scoped-cycle suite still prices its fixtures `A+` / `B+` / `D+`.
      Both pinned literals still resolve, the suite selector now reaches the oracle suite for an
      `AGENT.md`-only change (`0` → `1`), `verify_deterministic.py` passes, and the render diff is
      generator-written paths only. *(NFR-1, NFR-2; §9 AC-11)*
- [ ] Every count in this delivery's artifacts carries the command that produced it, and re-running
      that command reproduces the number. *(NFR-4; §9 AC-12)*
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ — `aid-detail` fills this table.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** delivery-001. Hard, not merely ordering: this delivery edits
  `reviewer-ledger-schema.md`, which delivery-001's feature-001 requires unchanged, so it branches
  from delivery-001's merged state and rebases onto it. Its fourth severity-provenance token — "no
  declared criterion reaches this document" — is currently true of every row, and the gap that
  makes it so is closed by feature-002's FR-B5 inside delivery-001.
- **Blocks:** -- (none). Terminal.

## Notes

- **Q9 governs the last two gate criteria.** FR-C3 and FR-C6 reach no criterion in §9, so this
  feature synthesized one each at their source `SHOULD`. Confirming them or dropping the two
  requirements is the owner's call, and either outcome is recorded.
- **Q8 is answered in substance, not in wording.** The why-line criterion supplies the command
  AC-9 asked for and states its limit: a grep decides a why-line's *form*, never whether its clause
  names a real consequence, which is why the residue rows are read rather than counted.
- **This delivery is `Should` and contains `MUST` criteria.** That is correct, not a mistake:
  `Priority` is the track's scheduling weight; each criterion carries the modality of the
  requirement it discharges.
- **Corpus size is undecided by design.** If the corpus is too small for the recall script to clear
  NFR-3's floor, the script does not merge — a legitimate outcome the gate criterion above requires
  to be recorded rather than quietly dropped.

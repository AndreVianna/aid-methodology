# Requirements

- **Name:** Review Stack Completion
- **Description:** Finish what master’s review stack still lacks — one clean path on disk, the remaining coverage gaps, and judgment/measurement that make the grade mean something — without rebuilding a rival review system.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-16 | Draft from owner decisions (successor to canceled prior review redesign; T1→T2→T3; migrate catalog rows; default-delete scripts) | owner + agent scaffold |

> **Modality.** Every FR/NFR carries MUST / SHOULD / COULD.

---

## 1. Objective

Make AID’s review **effective and simpler** on the stack that already shipped:

- criteria cascade + optional oracles  
- 7-column ledger  
- VERIFY/HUNT scoped cycles + cost meter  
- single `/aid-review` + `aid-reviewer`

Do **not** invent a second loader, second ledger shape, or second review skill family.

---

## 2. Problem Statement

1. **Half the old redesign’s problems are already solved** on master (declared criteria, cheaper re-review, shared dispatch). Continuing that old plan would re-solve them with rivals.
2. **Judgment and measurement gaps remain:** severity still needs a clear “why” practice; clean context for new cycles is not structural; recall of seeded defects is unmeasured; several artifact classes still lack gates.
3. **Simplicity is at risk** if abandoned redesign artifacts (or habits) land beside the cascade.

---

## 3. Users & Stakeholders

| Who | Need |
|-----|------|
| Pipeline skills | One way to dispatch review; briefs stay small |
| `aid-reviewer` | One criteria loader; clear severity practice |
| Maintainers | Measure cost; delete unjustified scripts |
| Owner | Grade means distance from ideal — not feel + arithmetic facade |

---

## 4. Scope

### In scope (three tracks, in order)

| Track | Name | Outcome |
|-------|------|---------|
| **T1** | Align | One review path on disk matching master law; useful old catalog checks migrated into cascade; rival entry points and default-deleted scripts gone |
| **T2** | Gaps | Remaining coverage gates: settings, frontmatter wiring, kb.html content pass, BLUEPRINT/specify grading path, citation/quote wiring on `/aid-review` |
| **T3** | Measure & judge | Severity why-line (judgment), structural clean context, claim-level coverage if still needed, seeded recall + class sweep in FIX |

### Out of scope

- Rubric-catalog **loader** / 8-column `Rule` ledger / deep+light skill split as the design  
- Changing `grade.sh` positional parse or the 7-column ledger shape  
- Re-opening canceled prior work’s delivery SPECs as live tasks  
- Naming prior work ids inside `.aid/knowledge/`

---

## 5. Functional Requirements

### T1 — Align

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-A1 | MUST | Exactly one review skill path for pipeline use: `/aid-review` (plus existing screener agent if still warranted). No deep/light pair. |
| FR-A2 | MUST | Reviewer loads criteria only from the cascade (global → type → file). No catalog INDEX routing. |
| FR-A3 | MUST | Useful checks that existed only in the old catalog are **migrated** into `review-criteria:` (and `oracle:` where mechanical). Then the catalog tree is removed or left non-referenced. |
| FR-A4 | MUST | Default-delete review helper scripts from the abandoned redesign unless a cost-meter case keeps one. |
| FR-A5 | MUST | No install-tree or skill reference CHAINs to removed review skills. |

### T2 — Gaps

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-B1 | MUST | `.aid/settings.yml` has a kind-D mechanical gate. |
| FR-B2 | MUST | Frontmatter lint is wired as a runtime gate where declared. |
| FR-B3 | MUST | Generated `kb.html` gets an adversarial content pass (kind A), not only build-verify. |
| FR-B4 | MUST | `BLUEPRINT.md` and specify per-section review use the standard ledger + `grade.sh` path. |
| FR-B5 | MUST | Citation/quote accuracy checks run on the `/aid-review` path (work artifacts included). |
| FR-B6 | SHOULD | One grading backend for summary/letter grade (no parallel points model). |

### T3 — Measure & judge

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-C1 | MUST | Finding severity is agent judgment with a **one-line why** naming consequence; declared criterion `severity:` remains a default when the finding cites that criterion. |
| FR-C2 | MUST | New-cycle review context is **structurally** isolated from prior-cycle ledgers (not only instructed). |
| FR-C3 | SHOULD | Coverage units can be claim/worklist items where file-scoped HUNT is not enough. |
| FR-C4 | MUST | Seeded-defect corpus + recall report exist; recall regression is a review-subsystem defect. |
| FR-C5 | MUST | A FIX is not complete until its defect class is swept (distinguishing phrase / agreed pattern). |
| FR-C6 | SHOULD | Mechanical checks that only observe (no verdict) stay outside the ledger; only an open criteria gap may block a grade for “missing rule.” |

---

## 6. Non-Functional Requirements

| ID | Modality | Requirement |
|----|----------|-------------|
| NFR-1 | MUST | Do not change `grade.sh` counting logic or 7-column ledger schema. |
| NFR-2 | MUST | Five install profiles stay in sync via generate-profile (no hand-edits in `profiles/` / generated trees). |
| NFR-3 | MUST | Any kept or new script justifies itself with **measured** removed re-derivation (cost meter or equivalent command cited). |
| NFR-4 | MUST | Claims in work artifacts that are counts cite the producing command. |
| NFR-5 | MUST | VERIFY/HUNT + brief-to-disk + cost-meter `record` remain mandatory on pipeline review dispatch. |

---

## 7. Constraints

- Master review stack is law; this work **folds into** it.
- Evidence over assertion.
- Work folders are transient; KB never cites a work id.

---

## 8. Assumptions & Dependencies

- Cascade, VERIFY/HUNT, cost meter, and `/aid-review` remain on master.
- Canceled prior redesign is history only; cherry-picks allowed only when they serve T1–T3 and do not reintroduce rivals.
- Owner already locked: track order T1→T2→T3; migrate catalog rows; default-delete scripts.

---

## 9. Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Grep/dispatch audit: zero live references to removed rival review skills; cascade is the only criteria loader in `aid-reviewer`. |
| AC-2 | Cost meter still records on a real pipeline review dispatch after T1. |
| AC-3 | Each T2 gate has a failing fixture or measured before/after proving it fires. |
| AC-4 | T3: seeded corpus + recall report command; one documented clean-context proof that prior ledger is unreachable. |
| AC-5 | No new script merges without a cited measurement of what re-derivation it removes. |

---

## 10. Priority

1. **T1 Align** — simplicity; stops the wrong system from shipping  
2. **T2 Gaps** — closes known blind spots on the good stack  
3. **T3 Measure & judge** — makes the grade honest and improvable  

---

## Approval

Draft for owner approval. Reply **approve** to mark requirements approved and continue to `/aid-define`, or list edits.

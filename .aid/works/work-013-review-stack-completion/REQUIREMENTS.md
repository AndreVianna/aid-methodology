# Requirements

- **Name:** Review Stack Completion
- **Description:** Finish what master’s review stack still lacks — keep that stack clean, close remaining coverage gaps, and add judgment/measurement that make the grade mean something — without rebuilding a rival review system.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-16 | Draft from owner decisions (successor to canceled prior review redesign; T1→T2→T3; migrate catalog rows; default-delete scripts) | owner + agent scaffold |
| 2026-08-16 | Fix review findings: T1 retargeted to master tip (no rivals on this branch); drop screener; clarify FR-C1; retarget AC-1; tighten T2 evidence notes | requirements self-review |

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
2. **This branch starts from master.** Rival redesign artifacts (deep/light skills, rubric-catalog loader, 8-column Rule path) are **not** on master. The live risks are: (a) those rivals landing via an old open PR, (b) drift in `/aid-review` docs vs the 7-column law, (c) useful catalog *checks* never folded into the cascade.
3. **Judgment and measurement gaps remain:** severity needs an explicit why-line practice; clean context for new cycles is not structural; recall of seeded defects is unmeasured; several artifact classes still lack gates.
4. **Coverage gaps on master today:** no settings kind-D gate; frontmatter lint exists but is not proven wired; `kb.html` lacks an adversarial content pass; BLUEPRINT/specify grading path and work-artifact citation/quote checks are incomplete; `grade-summary.sh` still coexists with letter-grade `grade.sh`.

---

## 3. Users & Stakeholders

| Who | Need |
|-----|------|
| Pipeline skills | One way to dispatch review; briefs stay small |
| `aid-reviewer` | One criteria loader; clear severity practice |
| Maintainers | Measure cost; no unjustified scripts; no rival PR merges |
| Owner | Grade means distance from ideal — not feel + arithmetic facade |

---

## 4. Scope

### In scope (three tracks, in order)

| Track | Name | Outcome |
|-------|------|---------|
| **T1** | Align | Master stack stays the only review system: block/close rival PR landings; fix `/aid-review` drift to 7-column + cascade; migrate **useful checks** from the abandoned catalog (history/cherry-pick source) into `review-criteria:` / `oracle:`; do not add deep/light, catalog loader, or 8-col Rule ledger |
| **T2** | Gaps | Remaining coverage gates on **this** tree: settings kind-D, wire frontmatter lint, kb.html content pass, BLUEPRINT/specify ledger+`grade.sh`, citation/quote on `/aid-review`; collapse summary grading toward one backend |
| **T3** | Measure & judge | Severity why-line (without undoing cascade `severity:` defaults), structural clean context, claim-level coverage if still needed, seeded recall + class sweep in FIX |

### Out of scope

- Building or merging a rubric-catalog **loader**, 8-column `Rule` ledger, or deep+light skill split  
- Re-introducing an `aid-screener` agent (not on master; not required for this work)  
- Changing `grade.sh` positional parse or the 7-column ledger shape  
- Re-opening canceled prior work’s delivery SPECs as live tasks  
- Naming prior work ids inside `.aid/knowledge/`  
- “Delete rivals from this branch” as a no-op task — they are absent here; handle via PR hygiene + migration from history

---

## 5. Functional Requirements

### T1 — Align

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-A1 | MUST | Pipeline review uses **only** `/aid-review` + `aid-reviewer` on the cascade/VERIFY/HUNT stack. This work must not add a second review skill family. |
| FR-A2 | MUST | `aid-reviewer` and `/aid-review` docs match law: criteria from cascade only; **7-column** ledger (criterion id in Description). Remove any shipped prose that still describes an 8-column `Rule` ledger or catalog INDEX routing. |
| FR-A3 | MUST | Useful checks that existed **only** in the abandoned catalog (recoverable from git history / canceled branch) are **migrated** into `review-criteria:` (and `oracle:` where mechanical). Migration does **not** bring back the catalog loader or tree as a live path. |
| FR-A4 | MUST | Do **not** merge rival redesign artifacts onto master (deep/light skills, catalog-as-loader, 8-col Rule path, unjustified helper scripts). Close or strip any open PR that would land them. Default-delete: if a helper script is proposed from that history, it ships only with a cost-meter (or equivalent) case. |
| FR-A5 | MUST | After T1, a measured audit shows: no live CHAIN/dispatch to non-existent or rival review skills; cascade remains the only criteria loader in `aid-reviewer`. |

### T2 — Gaps

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-B1 | MUST | `.aid/settings.yml` has a kind-D mechanical gate (`lint-settings` or successor name). *Baseline: absent on master today.* |
| FR-B2 | MUST | `lint-frontmatter.sh` (already on master) is **wired** as a runtime gate where authoring-conventions/enforcement declare it — proven with a failing fixture or before/after measurement. |
| FR-B3 | MUST | Generated `kb.html` gets an adversarial content pass (kind A), not only build-verify. |
| FR-B4 | MUST | `BLUEPRINT.md` and specify per-section review use the standard 7-column ledger + `grade.sh` path. |
| FR-B5 | MUST | Citation/quote accuracy checks run via the `/aid-review` / cascade path and cover work artifacts, not only KB. |
| FR-B6 | SHOULD | One grading backend for letter grade: retire or demote parallel points/`grade-summary.sh` paths so `grade.sh` is the sole letter producer. *Baseline: `grade-summary.sh` still present on master.* |

### T3 — Measure & judge

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-C1 | MUST | Every finding carries a **one-line why** naming the consequence. **Severity resolution (do not undo cascade):** if the finding cites a declared criterion that has `severity:`, that value is the default band; the why-line is still required. If there is no cited criterion severity (or the agent must diverge), the agent judges the band and the why-line must say so. |
| FR-C2 | MUST | New-cycle review context is **structurally** isolated from prior-cycle ledgers (not only instructed). |
| FR-C3 | SHOULD | Coverage units can be claim/worklist items where file-scoped HUNT is not enough. |
| FR-C4 | MUST | Seeded-defect corpus + recall report exist; recall regression is a review-subsystem defect. |
| FR-C5 | MUST | A FIX is not complete until its defect class is swept (distinguishing phrase / agreed pattern). |
| FR-C6 | SHOULD | Mechanical checks that only observe (no verdict) stay outside the ledger; only an open criteria gap may block a grade for “missing rule.” Oracles that emit VIOLATION remain criteria checks, not a second ledger. |

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
- This worktree/branch is based on **master**; abandoned redesign code is a **history source**, not the working tree.

---

## 8. Assumptions & Dependencies

- Cascade, VERIFY/HUNT, cost meter, and `/aid-review` remain on master.
- Canceled prior redesign is history only; cherry-picks allowed only when they serve T1–T3 and do not reintroduce rivals.
- Owner already locked: track order T1→T2→T3; migrate useful catalog **rows into cascade**; default-delete abandoned scripts unless measured.
- Open rival PR(s) from the canceled redesign are closed or rewritten before merge.

---

## 9. Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC-1 | **PR hygiene + doc law:** rival redesign PR is closed or contains no rival loader/skills/8-col path; `aid-reviewer` loads cascade only; `/aid-review` (and related briefs) describe the **7-column** ledger — measured by named greps/commands in the delivery record. |
| AC-2 | Cost meter still records on a real pipeline review dispatch after T1. |
| AC-3 | Each T2 gate (B1–B5; B6 if done) has a failing fixture or measured before/after proving it fires. |
| AC-4 | T3: seeded corpus + recall report command; one documented clean-context proof that prior ledger is unreachable. |
| AC-5 | No new script merges without a cited measurement of what re-derivation it removes. |
| AC-6 | Migrated catalog checks: each kept check has a cascade/`oracle:` home; no live `review-rubrics/` loader on master after T1. |

---

## 10. Priority

1. **T1 Align** — keep master clean; fix drift; migrate useful checks without rivals  
2. **T2 Gaps** — close known blind spots on this tree  
3. **T3 Measure & judge** — make the grade honest and improvable  

---

## Approval

Revised draft for owner approval. Reply **approve** to mark requirements approved and continue to `/aid-define`, or list edits.

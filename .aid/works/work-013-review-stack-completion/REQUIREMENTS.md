# Requirements

- **Name:** Review Stack Completion
- **Description:** Finish what master’s review stack still lacks — keep that stack clean, close remaining coverage gaps, and add judgment/measurement that make the grade mean something — without rebuilding a rival review system.

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
4. **Coverage gaps on master today:** `.aid/settings.yml` has no mechanical gate; frontmatter lint exists but is not proven wired; `kb.html` is build-verified and its content is never read; BLUEPRINT/specify grading path and work-artifact citation/quote checks are incomplete; `grade-summary.sh` still coexists with letter-grade `grade.sh`.
5. **Some findings are manufactured by the process itself.** A hand-maintained `## Change Log` drifts from git as soon as one edit skips a row, and reviewers then spend cycles on the drift rather than on the artifact. Removing a whole finding class is worth more than reviewing it faster.

---

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| Pipeline skill | Any skill that runs a REVIEW state (`aid-discover`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`) | One way to dispatch review; briefs that stay small enough to stay honest |
| Reviewer agent | `aid-reviewer`, the agent that judges an artifact | One criteria loader, and a severity practice it can defend line by line |
| Maintainer | Whoever changes the methodology and keeps the five install profiles rendering | Cost measured rather than asserted; no unjustified script; no rival review system merged |
| Owner | The person the grade is reported to | A grade that means distance from the ideal, not a feel judgment wrapped in arithmetic |

---

## 4. Scope

### In Scope

Three tracks, executed in order:

| Track | Name | Outcome |
|-------|------|---------|
| **T1** | Align | Master stack stays the only review system: block/close rival PR landings; fix `/aid-review` drift to 7-column + cascade; migrate **useful checks** from the abandoned catalog (history/cherry-pick source) into `review-criteria:` / `oracle:`; do not add deep/light, catalog loader, or 8-col Rule ledger |
| **T2** | Gaps | Remaining coverage gates on **this** tree: a mechanical gate for settings, wire frontmatter lint, a content review for kb.html, BLUEPRINT/specify on the ledger + `grade.sh` path, citation/quote on `/aid-review`; collapse summary grading toward one backend |
| **T3** | Measure & judge | Severity why-line (without undoing cascade `severity:` defaults), structural clean context, claim-level coverage if still needed, seeded recall + class sweep in FIX |

### Out of Scope

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
| FR-A1 | MUST | Pipeline review uses **only** `/aid-review` + `aid-reviewer` on the cascade/VERIFY/HUNT stack. Exactly one review skill directory exists under `canonical/skills/` and exactly one reviewer agent under `canonical/agents/`; this work adds neither a second review skill nor a second reviewer agent. |
| FR-A2 | MUST | `aid-reviewer` and `/aid-review` docs match law: criteria from cascade only; **7-column** ledger (criterion id in Description). Remove any shipped prose that still describes an 8-column `Rule` ledger or catalog INDEX routing. |
| FR-A3 | MUST | Useful checks that existed **only** in the abandoned catalog (recoverable from git history / canceled branch) are **migrated** into `review-criteria:` (and `oracle:` where mechanical). Migration does **not** bring back the catalog loader or tree as a live path. |
| FR-A4 | MUST | Do **not** merge rival redesign artifacts onto master (deep/light skills, catalog-as-loader, 8-col Rule path, unjustified helper scripts). Close or strip any open PR that would land them. Default-delete: if a helper script is proposed from that history, it ships only with a cost-meter (or equivalent) case. |
| FR-A5 | MUST | T1 closes with a **recorded audit**: every skill reference, dispatch table and CHAIN target that names a review skill resolves to a review skill that exists on disk. The audit is a named command whose output is pasted into the delivery record, not a claim. |

### T2 — Gaps

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-B1 | MUST | `.aid/settings.yml` has a **mechanical gate** — a script that passes or fails on its own, with no agent judgment (`lint-settings` or successor name). *Baseline: absent on master today.* |
| FR-B2 | MUST | `lint-frontmatter.sh` (already on master) is **wired** as a runtime gate where authoring-conventions/enforcement declare it — proven with a failing fixture or before/after measurement. |
| FR-B3 | MUST | Generated `kb.html` gets an **agent content review**, not only build-verify. This is a deliberate, named exception to the cascade's treatment of generated artifacts (`KB-03`, "the generator is the oracle"): the generator proves the file was built, and nothing today reads what it says. |
| FR-B4 | MUST | `BLUEPRINT.md` and specify per-section review use the standard 7-column ledger + `grade.sh` path. |
| FR-B5 | MUST | Citation/quote accuracy checks run via the `/aid-review` / cascade path and cover work artifacts, not only KB. |
| FR-B6 | SHOULD | One grading backend for letter grade: retire or demote parallel points/`grade-summary.sh` paths so `grade.sh` is the sole letter producer. *Baseline: `grade-summary.sh` still present on master.* |
| FR-B7 | MUST | **No artifact carries an in-document history section.** No `## Change Log`, no `## Revision History`, no `changelog:` frontmatter — for every artifact the methodology produces, not only KB docs. Git is the per-document history. The rule is stated once (`artifact-schemas.md`), and no template, skill, or fixture authors one. *Rationale: a hand-maintained history table drifts from git the moment a row is missed, and that drift was a recurring source of review findings — removing it removes the finding class.* |

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

Each criterion names the requirement it discharges, so an uncovered MUST is visible.

| ID | Discharges | Criterion |
|----|-----------|-----------|
| AC-1 | FR-A2, FR-A4 | **PR hygiene + doc law:** the rival redesign PR is closed, or contains no rival loader, review skills or 8-column path; `aid-reviewer` resolves criteria from the cascade only; `/aid-review` and the per-skill briefs describe the **7-column** ledger. Evidence: the greps, and their output, recorded in the delivery record. |
| AC-2 | NFR-5 | Cost meter records on a real pipeline review dispatch after T1: a brief file on disk and a matching row in `review-cost.tsv`. |
| AC-3 | FR-B1, FR-B2, FR-B3, FR-B4, FR-B5 (and FR-B6 if done) | Each T2 gate has a fixture that **fails before and passes after**, or a before/after measurement, proving the gate actually fires. |
| AC-4 | FR-C2, FR-C4 | Seeded-defect corpus exists with a recall-report command and its output; plus one documented proof that a new-cycle reviewer **cannot reach** a prior cycle's ledger — the attempted path and its failure, not an instruction. |
| AC-5 | NFR-3 | No script merges without a cited measurement of the re-derivation it removes. |
| AC-6 | FR-A3 | Migrated catalog checks: each kept check has a cascade `review-criteria:` (or `oracle:`) home, cited by id; no live `review-rubrics/` loader remains. |
| AC-7 | FR-B7 | `grep -rn '## Change Log' canonical tests docs site/src .aid/knowledge` returns no artifact-authoring instruction, template section, or fixture — only the rule text that forbids one. |
| AC-8 | FR-A1, FR-A5 | `ls -d canonical/skills/*review*/` returns exactly one directory and `ls -d canonical/agents/*review*/` exactly one; and the FR-A5 audit command's output shows every review-skill reference resolving to a skill that exists. Both outputs are pasted into the delivery record. |
| AC-9 | FR-C1 | On a real review cycle, **every** ledger row's `Description` carries a one-line why naming the consequence; where a row's severity diverges from a cited criterion's declared `severity:`, the row's `Evidence` says so. Measured by reading that cycle's ledger, with the row count reported. |
| AC-10 | FR-C5 | A FIX cycle is not closed until its class sweep runs: the sweep command and its output are recorded with the fix, and a seeded second instance of the same defect class is found by that sweep rather than by the next review cycle. |
| AC-11 | NFR-1, NFR-2 | `grade.sh` and `reviewer-ledger-schema.md` are unchanged in counting logic and column shape (`git diff` on both is empty, or the diff touches neither); and `generate-profile` re-renders byte-identically with VERIFY deterministic PASS, with no hand-edit in `profiles/` or the dogfood trees. |
| AC-12 | NFR-4 | Every count stated in this work's artifacts carries the command that produced it, and re-running that command reproduces the number. |

---

## 10. Priority

1. **T1 Align** (Must) — keep the stack single; fix drift; migrate useful checks without reintroducing rivals. First because everything after it is measured on this stack.
2. **T2 Gaps** (Must) — close the known blind spots on the aligned stack.
3. **T3 Measure & judge** (Should) — make the grade honest and improvable. Last because its measurements are only meaningful once T1 and T2 have settled what is being measured.

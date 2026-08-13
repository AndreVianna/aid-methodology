# Requirements

- **Name:** Declared Review Criteria
- **Description:** Review criteria are declared as data — global and per-document-type lists in the Knowledge Base, per-file exceptions in a file's own frontmatter — every agent that writes a file resolves them first and complies, the reviewer verifies against the same list, and the guard scripts that stood in for them are removed.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Initial interview started | /aid-describe |
| 2026-08-12 | Sections 1, 2, 7 captured; 4, 5, 9 partial — seeded from the owner's opening description and `prior-art.md` | /aid-describe |
| 2026-08-12 | Sections 3, 10 captured; FR-5 (one uniform `contracts:` field) and FR-6 (three-level severity cascade) decided | /aid-describe |
| 2026-08-12 | Coverage figures re-derived against this branch, correcting the work-003 measurements | /aid-describe |
| 2026-08-12 | FR-7 (delete the 20 internal READMEs), deferred front-face bucket, C-7 (work-003 admission gates), NFR-1..5, AC-1..6 — all 10 sections Complete | /aid-describe |
| 2026-08-12 | COMPLETION quality check: corrected a stale `341` in FR-6 to the derived `315` | /aid-describe |
| 2026-08-12 | COMPLETION KB hydration assessed — no KB write warranted yet; reasons recorded below | /aid-describe |
| 2026-08-12 | Identity fields confirmed: Declared Review Criteria | /aid-describe |
| 2026-08-12 | Interview complete — approved | /aid-describe |
| 2026-08-12 | **Correction pass.** Feature decomposition found this document citing artifacts that exist only on `work-003`. Re-derived §2's enforcement gap and guard inventory, §4's stream-1 target table and stream-3 scope, FR-2/FR-3/FR-4, NFR-2, §8's collision set, AC-3/AC-4 — all against this branch's disk | /aid-define |
| 2026-08-12 | **Cross-reference fix pass.** `aid-reviewer` raised 34 findings over 87 re-derived claims; 27 fixed here. Corrected `site/src/content/docs` 137→93, FR-6's citation list, AC-1's triple-counted population (→290 with carve-outs named), NFR-2's undefined "added" side, NFR-4's missing site chain, NFR-1's unimplementable script, the examples' false "zero references", and every bare `file:LINE` citation. Added FR-8 for the front face, which was gated with no requirement behind it | /aid-define |
| 2026-08-12 | **Criteria model corrected by the owner.** `contracts:` holds the *criteria a reviewer validates the file against*, resolved through a three-level cascade — global and per-document-type lists in the KB, per-file exceptions in frontmatter — written once at the highest level where true, to stop duplication and keep per-file lists short. Criteria are positive **and** negative: a non-obvious exclusion belongs in `contracts:` with its reason, never as a severity. `severity:` named and shaped as a defect-kind → level map over validatable kinds only. FR-1, FR-5, FR-6, AC-1, §4 streams 1–2 and both feature SPECs rewritten; the earlier `canonical/` placement correction withdrawn — criteria are project-specific, so the KB is right | /aid-define |
| 2026-08-12 | **Criteria home fixed: `.aid/knowledge/authoring-conventions.md`**, both levels together as two new sections (owner decision). The concern spine puts it at C3 — conventions and standards — which is what criteria are; it is `kb-category: primary`, already tagged `enforcement`, and already carries level 1 unlabelled in `## Drift-Prone Content is Banned`, `## Citation Rule` and `## Resolved Items Leave No Trace`. Not `quality-gates.md` (C6), which keeps the grade scale, ledger and thresholds; criteria and their cost in C3, scoring in C6, cross-referenced never duplicated | /aid-define |
| 2026-08-12 | **Criteria are a writer's contract, not a reviewer's checklist** (owner correction). FR-2 rewritten: any agent that writes or edits a file resolves its criteria first and complies; the reviewer verifies against the same list and is the backstop, not the sole enforcer. New **FR-9** (resolve-before-writing) and **FR-10** (a work that introduces or retires a document type owes the KB its registry row) — both **global instructions in `agent-boilerplate.md`**, which every AGENT.md includes, rather than per-skill edits. AC-2 now proves both directions. Field shape settled: `review-criteria:` as an array of objects (`id`/`kind`/`criterion`/`severity`/`why`), same shape at all three levels, renamed from `contracts:`; severity is a field on each criterion rather than a separate block; overrides permitted with mandatory `why` and the effective value surfaced in the gate output, which closes FR-6's parked open cost | /aid-define |
| 2026-08-13 | **Rule column closed without a column** — every criterion carries a greppable `id` and a finding names it as a prefix inside the existing `Description` cell, so the ledger keeps 7 columns and `grade.sh` its positional parse. Two global exclusions added (`agent-context`, `rendered`); the `rendered` one keyed on **provenance via the emission manifest, not a path glob**, after a path-based draft would have exempted `render.py` and `release-aid` from review. `render.py` to carry `review-criteria` through, so the `agent` type behaves identically for canonical and repo-local members. Ledger: 33 Fixed, 1 Invalid, 0 Pending | /aid-define |
| 2026-08-13 | **Second cross-reference fix pass — 37 findings.** Every figure re-derived. AC-1's buckets now net the carve-outs out of the buckets, not only the total (159/123/8 = 290); the `Rule` column and the withdrawn `severity:` block removed from the places a prior pass missed; the rename surface enumerated at 52 files across five generator emitters, a migration parser, four `kb-authoring/` docs and the data carriers; the `rendered` exclusion given its **second limb** (`profiles/<tool>/` **with** a `canonical/` source) after the one-limb version was found to reach 0 of 1,376 files under `profiles/`; FR-9 re-targeted from install output to the **five hand-authored `profiles/<tool>/{CLAUDE,AGENTS}.md`**; the `skill` type split like `template` (**58** generator-refreshed of 76); severity overrides settled to the ledger's `Evidence` cell (owner decision) rather than a gate-output change; AC-4's merged 2,181 floor split back to a **379** guard floor; "CI invokes `kb-citation-lint.sh`" retracted as false; the import log given a path and scheduled. FR-8 moved into numeric order | /aid-define |
| 2026-08-13 | **Correction to the correction pass.** FR-2's stated reason for not adding a ledger column was a **false mechanism** — `grade.sh` indexes `cols[3]`/`cols[4]` from the left and guards only `if (n < 5)`, so an appended column shifts nothing. Replaced with the real reason (edit cost across four documents and every existing ledger, for a citation the `Description` prefix already provides). Two defects introduced *within this pass* were caught before commit: a bare `profiles/**` limb that would have exempted FR-9's own five edit targets, and a "7 of the 290" primary-doc count that is **13** | /aid-define |

### KB hydration assessment (COMPLETION step 2)

Performed, and the conclusion is **no KB write at this point**. Four reasons, each sufficient:

1. **The KB records the current state of the project's sources.** Every decision taken in this
   interview (FR-5, FR-6, FR-7, C-7) is a *planned* future state. Writing them now would make the KB
   describe something that is not yet true.
2. **The one current-state fact — the coverage gap — is what this work fixes.** A `tech-debt.md`
   entry would be added and then deleted inside the same work, since resolved debt is removed from
   that document. Pure churn.
3. **Six of the KB's own docs are stream-2 targets**, including `quality-gates.md`,
   `authoring-conventions.md` and `tech-debt.md`. Writing them now means writing them twice.
4. **Gap check found no empty doc.** All 22 KB docs carry substantive bodies (smallest substantive:
   `external-sources.md` at 36 lines; `README.md` and `INDEX.md` are meta docs by the KB's own
   model). There is no doc sitting empty where the owner plainly has an answer, so there is no
   question to ask.

This work's KB changes land through **stream 2** and the single end-of-work refresh (**C-2**, **NFR-4**).

## 1. Objective

**Make review criteria declared data rather than code**, and put them in front of every agent that
writes a file — not only the one that reviews it. Then delete the scripts that were standing in for
them.

Criteria resolve through three levels, each written once at the highest level where it is true:

- **Global** and **per-document-type** lists in the Knowledge Base — where most criteria live
- **Per-file exceptions** in a file's own frontmatter — only where a file genuinely differs

Each criterion says either *"validate this"* or *"never validate this, and here is why"*, and carries
its own severity — what a violation of that criterion costs. Together they replace a growing pile of
guard scripts — each of which encoded one fact-check in code, and could be wrong about it — with a
statement of what to check, applied by something that can read.

**Whoever writes a file resolves its criteria before writing; whoever reviews it verifies against the
same list.** One list, two moments. A reviewer catching what a writer was never told is the loop this
work exists to break.

**The point is to stop the review process from growing the surface it reviews every time it fixes
something.** A criterion added to a KB list changes nothing about how much there is to review. A
guard added to catch the same defect is a new artifact with its own defects — which is exactly how
the previous attempt failed.

## 2. Problem Statement

AID's review process is load-bearing for the whole methodology, and it failed to converge on its
own artifact.

**The measurement.** `work-003`'s `delivery-015` ran four review→fix cycles: 47 findings raised,
all 47 fixed, zero recurred — yet the grade went E → C- → D+ → D while the finding count went
15 → 14 → 9. 37% of the findings in cycles 16–18 named a previous cycle's fix as their cause, and
8 of cycle 18's 9 findings sat in files the previous cycle's repairs had touched. The delivery's
objective was met around cycle 16; every failure after that came from a change made in the cycle
that reported it.

**The mechanism.** Each fix added a guard. Each guard was a new artifact. Each new artifact sat
inside the reviewed surface and carried its own defects. Fixes enlarged the reviewed surface
faster than they closed findings in it.

**Why the existing remedy did not fire.** The check that would have caught most of the 47 **already
exists on this branch** — `canonical/aid/templates/kb-authoring/review-rubric.md` item 3:

> *"**Contracts hold against disk** — for each entry in `contracts:`, derive the asserted fact from
> disk and compare. Mismatch = HIGH finding."*

So does the field it reads, schema and all, in
`canonical/aid/templates/kb-authoring/frontmatter-schema.md`. **Nothing here needs inventing.**
Three things are wrong with what exists, and each is why it went unused:

1. **It is scoped to one tree, and not even all of it.** It lives under `kb-authoring/`, so it
   governs `.aid/knowledge/` docs and nothing else. Item 3 sits inside the rubric's
   `## Rubric: Full Primary (hand-authored)` section, and the routing table above it sends
   `kb-category: meta` docs to *Spot-Check Snapshot* or *Build-Verify Only* instead — so the three
   meta docs (`STATE.md`, `README.md`, `external-sources.md`) never reach it either. Actual reach:
   **19 of 315** in-scope files. (`extension` and `primary`+`generated` docs *do* reach it — the
   table routes them to "same as primary" and "Full Primary + Build-Verify".) A skill, an agent or a
   template is never reached by it at all.
2. **It has no criterion ID.** "Item 3 of the KB authoring rubric" is not something a finding can
   cite — an ordinal into a document that renumbers whenever the document changes. A finding derived
   from it therefore has no stateable origin. It was cited **once** in `work-003`'s 47 findings (see
   `prior-art.md § 3`).
3. **No surface tells an agent to read the artifact's frontmatter.** Verified on this branch:

   | Surface | Its only frontmatter mention |
   |---|---|
   | `aid-reviewer/AGENT.md` → the ledger-shape rule | *"**No frontmatter**, no headers, no narrative sections"* — a rule about the reviewer's **own ledger**. It never says to read the artifact's. |
   | `aid-execute/references/state-fix.md` → F2's impact-chain table | one row — *"KB doc `summary:` frontmatter → `.aid/knowledge/INDEX.md`"*. Not post-edit re-verification. |

   That second gap produced `work-003` cycle-17 finding #3 directly: `quality-gates.md`'s body was
   fixed and its own `contracts:` block was left contradicting it.

### The coverage this reaches

Measured on this work's own base (`master` @ `9260fc88`) across `canonical/skills/`,
`canonical/agents/`, `canonical/aid/templates/` and `.aid/knowledge/`:

| bucket | `.md` | has frontmatter | declares a criterion |
|---|---|---|---|
| `skills/*/SKILL.md` | 76 | 76 | **0** |
| `skills/*/references/*.md` | 110 | **0** | 0 |
| `skills/*/README.md` | 11 | **0** | 0 |
| `agents/*/AGENT.md` | 9 | 9 | **0** |
| `agents/*/README.md` | 9 | **0** | 0 |
| `canonical/aid/templates` | 78 | 29 | 1 |
| `.aid/knowledge` | 22 | 22 | 9 |
| **TOTAL** | **315** | **136** | **10** |

*(The `.aid/knowledge` bucket of 22 includes 5 files that receive no authored criterion — `STATE.md`
per C-4, `INDEX.md` and `relationships.md` per C-5, and the other two of the **three** `kb-category:
meta` docs, `README.md` and `external-sources.md` (`STATE.md` is the third, already carved out by
C-4). AC-1 nets them out; the survey above counts them because they are markdown files in the
tree.)*

- **179 files carry no frontmatter at all** — including every one of the 110
  `skills/*/references/*.md` (the procedure bodies agents actually execute) and 49 of the 78
  `canonical/aid/templates/*.md` — among them `grading-rubric.md`, `reviewer-dispatch.md` and
  `kb-authoring/review-rubric.md`, so **the documents defining how review works cannot declare what
  they must be true against**. (`reviewer-ledger-schema.md` is the exception and the one template
  counted as declaring in the table above: it has frontmatter and a populated `contracts:` block.)
- **126 files carry frontmatter that declares nothing** — all 76 `SKILL.md`
  (`name`/`description`/`allowed-tools`, plus `argument-hint` on 74 of the 76), all 9 `AGENT.md`
  (`name`/`description`/`tier`/`tools`, with one agent also carrying `permissionMode` and another
  `background`), 28 templates and 13 KB docs.
- **9 of 22 KB docs carry an explicitly empty `contracts: []`** — `architecture.md`,
  `decisions.md`, `domain-glossary.md`, `external-sources.md`, `integration-map.md`,
  `pipeline-contracts.md`, `project-structure.md`, `tech-debt.md`, `technology-stack.md`.

*(An earlier draft of this section cited 341 / 139 / 202 / 88. Those were measured in
`work-003`'s worktree, which carries files `master` does not, and were corrected here rather than
carried forward — a requirements document that states a figure no one can derive from this branch
is the defect this work exists to remove.)*

**What stands in its place.** Prose facts are checked by script instead. The archetype on this
branch is `tests/canonical/check-skill-counts.mjs` — **379 lines** whose entire job is to find
count claims written in prose and compare them against the corpus. That is a `contracts:` line
wearing a script costume: it encodes one fact-check in code and can be wrong about the fact, where
a declaration states the fact and delegates checking to something that can read.

**The full inventory of such guards has not been derived and is deliberately not asserted here.**
An earlier draft of this paragraph listed six files totalling 2,816 lines; four of them
(`test-one-grading-backend.sh`, `test-review-rubrics.sh`, `derived-values.mjs`,
`check-derived-values.mjs`) **do not exist on this branch** — they are `work-003`'s. Of the two that
do, `check-skill-counts.mjs` is 379 lines (not 426) and `kb-citation-lint.sh` is 70 (not 279), and
`kb-citation-lint.sh` checks citation **form**, not a prose fact, so no declaration replaces it.
(It is orchestrator-gated at GENERATE; CI runs only its unit test. An earlier draft said "CI invokes
it", which overstated the reason to keep it — the reason it stays is that it checks form, not that
CI runs it.) Deriving the real inventory is the first task of stream 3 (see AC-3), because
asserting a number this document has not verified is the defect it exists to remove — and this
paragraph had already made that error once.

## 3. Users & Stakeholders

**AID users.** Everyone adopting the methodology depends on the review process working; that is
what makes this load-bearing rather than internal housekeeping.

The declaration's direct reader is the review agent, which acts on the user's behalf — so a
declaration that is authored but unread fails the user even though every file looks correct.

## 4. Scope

### In Scope

Three streams. **The order is load-bearing.**

1. **Enforce the mechanism first** — must land first, or the declarations authored in stream 2 are
   read by nothing. The surfaces, **as they exist on this branch**:

   **The largest single piece is the criteria themselves, in `authoring-conventions.md`.** Most of
   the value lands here, not in the 290 files: a criterion written once at type level covers every
   file of that type and keeps their frontmatter empty.

   | Surface | Lines | What it must gain |
   |---|---|---|
   | **`.aid/knowledge/authoring-conventions.md`** | 329 | **two new sections** — level 1 (global criteria + exclusions) and level 2 (per-document-type criteria, exclusions and per-criterion severities). The document-type list must be enumerated so every in-scope file resolves to exactly one. `## Enforcement` folds in — under the new model most of its rows become "the reviewer, via these criteria". |

   **Level 1 is a re-authoring, not a restructure — corrected.** An earlier draft said the global
   criteria "largely exist already, unlabelled" in `## Drift-Prone Content is Banned`,
   `## Citation Rule (Durable Anchors)` and `## Resolved Items Leave No Trace`, and could therefore be
   restructured rather than written. The text of the first of those opens *"Four content classes are
   banned from **primary docs**"* — it is scoped to `kb-category: primary` KB documents, of which
   **13 are hand-authored** (16 counting the three `source: generated` ones), against **290** in-scope
   files. Lifting a rule written for primary KB docs to "every document in the
   project" is a **change of scope**, and each one has to be re-argued at the wider scope and given a
   severity that holds for a skill reference and a template too. The existing sections are the raw
   material and the precedent; they are not the level-1 list in a different shape.
   | `canonical/aid/templates/kb-authoring/review-rubric.md` | 304 | its contracts check (item 3) generalized beyond `.aid/knowledge/`, taught to resolve the three levels, and given a citable rule ID |
   | `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | — | `review-criteria:` defined for all four trees rather than KB docs alone, carrying **positive criteria and exclusions**, each with its own `severity`; and the field removed from the "stay fully exempt" legacy list |
   | `canonical/aid/templates/grading-rubric.md` | 83 | level 2 of FR-6's severity cascade |
   | **`canonical/aid/templates/agent-boilerplate.md`** | — | **the two global instructions (FR-9, FR-10)** — resolve a file's criteria before writing it, and update the KB when a document type is introduced or retired. Included by every `canonical/agents/*/AGENT.md`, so one edit reaches every dispatched sub-agent. |
   | **the 5 hand-authored `profiles/<tool>/{CLAUDE,AGENTS}.md`**, `AID:BEGIN`/`AID:END` region | — | the same two instructions, as pointers — the only surface the **session's own agent** reads (it reads no `AGENT.md`), and it writes files too. These are the sources; the repo-root file is install output from `_copy_root_agent_file` — see FR-9. |
   | `canonical/agents/aid-reviewer/AGENT.md` | — | the reviewer's own half: verify compliance against the resolved criteria, and cite the criterion `id` in the finding |
   | `canonical/aid/templates/reviewer-dispatch.md` | 311 | the declaration reaching the dispatched reviewer |
   | `canonical/aid/templates/reviewer-ledger-schema.md` | 221 | the criterion `id` established as a `Description`-cell prefix, with the ledger's 7-column shape unchanged |
   | 6 × `canonical/skills/*/references/reviewer-brief.md` | — | the per-skill briefs naming it |
   | `canonical/skills/aid-execute/references/state-fix.md` | 121 | F1–F6 gaining post-edit re-verification |

   *There is no `review-rubrics/` catalog and no `reviewer-brief-template.md` on this branch —
   both are `work-003` additions. An earlier draft named them as targets.*
2. **Populate and correct the per-file exceptions second** — walk the in-scope files, confirm each
   resolves to a declared type, and add a `review-criteria:` block **only where the file has criteria
   or exclusions its type does not already cover**. There is no separate `severity:` block: severity
   is a field on each criterion (FR-6). Correct the **8** in-scope KB docs at `contracts: []` (9 carry
   it; `external-sources.md` is carved out) and verify the **8** that already declare. Most files will
   need nothing, and that is the intended outcome, not an omission.
3. **Remove the superseded scripts last** — or the only checks currently catching drift are deleted
   before the replacement works. Stream 3 **derives its own removal set first** (see AC-3); this
   document asserts no inventory. The `grade.sh` byte-identity pin named in an earlier draft belongs
   to `work-003` and does not exist here — **but an assertion labelled `NF01` does exist on this
   branch**, in `test-graph-runtime.sh` → the `NF01 [SR09]` assertion, and is unrelated. A sweep reading the
   earlier sentence literally would have skipped it.

Trees confirmed in scope: `canonical/skills/` (both `SKILL.md` and `references/*.md`),
`canonical/agents/`, `canonical/aid/templates/`, `.aid/knowledge/`.

### Out of Scope

- **`site/src/content/docs` (93 `.md`; 105 files of any type)** — informational content. It needs a
  different kind of validation, decided separately. *(An earlier draft said 137 — another off-branch
  figure the first correction pass did not reach.)*
- **`tests/canonical/test-dogfood-byte-identity.sh`** — it sha256s the two tracked dogfood trees
  against the render manifest, answering *"was the generator re-run"*. That is a build question,
  not a review question, and no declared contract replaces it. This is the genuine mechanical
  residue and it stays.
- **Code files.** Markdown needs a declared content-verification criterion because it is not
  compiled or executed. Code has build, lint and test as its oracle.
- **The deferred front-face bucket — DEFERRED, not out of scope.** It sits under this heading for
  proximity only: these files are what a user reads, they describe the trees this work is changing,
  and adjusting them mid-work would document a state that is still moving. They are **in scope and
  gated** — `FR-8` requires them, and feature-003 carries the acceptance criterion. *(Owner decision,
  2026-08-12; the "Out of Scope" placement without an FR was a defect — the same work cannot be both
  unscoped and gated.)*

  | Files | Count | Lines |
  |---|---|---|
  | `docs/*.md` | 7 | — |
  | repo-root `README.md` | 1 | 257 |
  | `examples/**/README.md` | 4 | 1,237 |

  *(An earlier draft called `brownfield-full-path` and `greenfield` "zero inbound references". That
  was wrong: both are linked from `examples/README.md` as directory links — `](greenfield/)`. The audit
  behind that claim only looked for `](README.md)`, so directory-style links were invisible to it. They
  are referenced, they are user-facing, and they belong here rather than in FR-7's delete set. A second
  draft also cited "the KB's repository-structure doc" — **there is no such KB document**; the file is
  `docs/repository-structure.md`, which is part of the front face this work defers, not part of the
  KB.)*

- **READMEs that ship to adopters** — `profiles/{antigravity,claude-code,codex,copilot-cli,cursor}/README.md`
  and `packages/{npm,pypi}/README.md` (7 files). Rendered/published artifacts, not internal surface.

- **READMEs with real consumers** — `.aid/knowledge/README.md` (an earlier draft's "49 files / 56
  rows" figures are not reproducible on this branch and are withdrawn; note also that
  `kb-freshness-check.sh` and `kb-actback-task.sh` name it only to **skip** it as a meta doc, which
  is a weaker kind of consumer than the phrasing implied), `dashboard/README.md`, `tests/README.md`,
  `tests/ui/README.md`,
  `dashboard/server/tests/fixtures/README.md`.

- **Test-fixture READMEs** — `tests/canonical/fixtures/kb-essence/relative-bus/README.md` and
  `dashboard/server/tests/fixtures/pt1h-repo-a/.aid/knowledge/README.md`. Zero textual references,
  but they are fixture *data* scanned by tests. Never touched.

## 5. Functional Requirements

*(Complete. FR-1..FR-10; the field set is settled at FR-5 and severity at FR-6. An earlier draft
carried a "partial" note naming the section-4 scope boundary as an open gap — that boundary was
settled by owner decision, and FR-8 now carries the deferred front face.)*

- **FR-1** **Every in-scope authored markdown file is covered by a complete set of criteria** —
  resolved across the three levels of FR-5, not necessarily written in the file.

  A file carries a `review-criteria:` block **only where it has criteria or exclusions of its own.** A file
  fully covered by its global and type-level criteria correctly declares nothing, and that is a
  passing state, not a gap. Coverage is a property of the cascade; a per-file block is the exception.
- **FR-2** **Criteria are resolved by whoever WRITES a file, and verified by whoever reviews it.**
  Same list, two moments — not a reviewer's checklist. *(Owner correction, 2026-08-12.)*

  Before writing or editing any in-scope file, an agent resolves that file's criteria — global, then
  its type, then the file's own — and complies. The reviewer then verifies compliance against the
  same list.

  *Why this is the load-bearing half:* if the criteria reach only the reviewer, every agent writes
  blind and the reviewer catches the damage afterwards. That is the loop that failed — **37% of
  `work-003`'s findings were caused by a previous fix**. A fixer editing a file while reading that
  file's criteria would not have produced most of them: the criteria say *"no bare line-number
  citation"* and *"no restated count"* **before** the edit, not after. The reviewer stops being the
  only line of defence and becomes the backstop it should always have been.

  This also explains the home chosen in FR-5 better than the reasoning given there:
  `authoring-conventions.md` is the ***authoring*** conventions document. Writers read it, reviewers
  check it, and C3 covers both because they were always the same thing.

  *Corrected scope.* An earlier draft framed this as switching on an existing rule, and scoped it to
  the reviewer alone. The check exists but is **scoped to `.aid/knowledge/` and carries no ID**, so
  this requirement is to **generalize it, name it, and put it in front of every agent that writes**:
  lift `kb-authoring/review-rubric.md` item 3 out of KB-only scope, give its entries citable ids
  (FR-5), and carry the resolve-before-writing instruction in `agent-boilerplate.md` (FR-9).

  **How a finding cites its criterion — no ledger change.** A finding names the criterion `id` as a
  prefix inside its existing `Description` cell:

  ```
  | # | Severity | Status | Doc | Line | Description | Evidence |
  | 3 | [HIGH] | Pending | canonical/skills/aid-plan/SKILL.md | 42 | SK-01 — dispatch table names `aid-sequencer`, which does not resolve | ls canonical/agents/ |
  ```

  A scope-prefixed id (`G-`, `KB-`, `SK-`) resolves in `authoring-conventions.md`'s criteria table; a
  file-local `F-` id resolves inside the file already named in the `Doc` column. **The ledger keeps
  its 7 columns, `grade.sh` keeps its positional parse, and nothing new is built.**

  *An earlier draft required "a citable rule ID for the ledger's `Rule` column". There is no `Rule`
  column on this branch, and the column was an assumption imported from a branch that has one. **The
  requirement was always for a citable criterion, not for a column**, and the `id` field of FR-5
  satisfies it.*

  *Why not simply add the column — the accurate reason.* An earlier correction claimed an eighth
  column "would shift Severity and Status and mis-grade silently". That is **false**, and stating a
  false mechanism as the justification for a design is the class of defect this work exists to
  remove. `canonical/aid/scripts/grade.sh` indexes from the **left** — its header documents
  `cols[3]` as Severity and `cols[4]` as Status, and its only width guard is `if (n < 5) next` — so a
  column appended after `Evidence` shifts neither. The real reason is cost with no benefit: the
  7-column shape is fixed by `reviewer-ledger-schema.md`, `authoring-conventions.md`,
  `quality-gates.md` and the root context files' `## Review output format (global)` section, and
  `grade.sh` documents the shape twice more, so a new column means editing all of them plus every
  ledger already written. The `Description` prefix costs none of that — and `grade.sh` states
  outright that *"Severity tags in cols[5..8] (Doc, Line, Description, Evidence) are ignored"*, so
  the cell is already inert to grading and an `id` placed there cannot perturb it.*

  *A benefit that falls out:* a finding citing **no** id, or an id resolving nowhere, is itself a
  defect — which is the first defence this project has had against a reviewer inventing criteria.
- **FR-3** The FIX contract requires re-verifying a file's own declaration after editing that file,
  closing the `quality-gates.md` failure mode. Target: `aid-execute/references/state-fix.md`, the
  only one of the four `state-fix.md` files carrying F1–F6.

  *Known gap, not silently absorbed:* `aid-discover` (125 lines), `aid-graph` (56) and
  `aid-summarize` (38) each have a `state-fix.md` with **no F-rules at all**. Their FIX states also
  edit files and would not re-verify. Flagged rather than scoped in — extending F1–F6 to three more
  skills is a different change from the one this work is doing.
- **FR-4** The declaration is the single home for a file's criteria; review surfaces **route to it
  rather than duplicating its content**.

  *Corrected scope.* An earlier draft said "the rubric catalog routes to the declaration". There is
  no rubric catalog on this branch, so there is nothing to re-route — the requirement is the
  narrower and stronger one that whatever surfaces FR-2 touches must point at the declaration
  instead of restating what it says.
- **FR-5** **Criteria resolve through a three-level cascade, and each criterion is written once at
  the highest level where it is true.** *(Owner decision, 2026-08-12.)*

  The field is **`review-criteria:`** and it holds **the list of criteria a reviewer validates this
  file against** — not a restatement of what the file says, and not a per-fact assertion list.

  **Renamed from `contracts:`** *(owner decision, 2026-08-12)*. The old name reads as "assertions
  about the world", which is how it was misread for three turns of this interview; `review-criteria`
  says what it is.

  **The migration is enumerable, but it is not small — an earlier draft called it "bounded" and named
  three surfaces.** Derived on this branch with
  `grep -rln "contracts:" --include=*.md --include=*.sh --include=*.ps1 --include=*.mjs --include=*.yml canonical .aid/knowledge tests`:
  **52 files** carry or mention the field. They fall into four kinds, and each kind needs a different
  treatment, which is why the count matters:

  | kind | surfaces | treatment |
  |---|---|---|
  | **Generators that emit the field** | `build-kb-index.sh`, `build-relationships.sh`, `build-metrics.sh`, `build-connectors-index.sh` **and** its PowerShell twin `build-connectors-index.ps1` | emit the new key; the twins must stay byte-parallel |
  | **A parser of the field** | `migrate/migrate-kb-frontmatter.sh` | its `/^contracts:/` match must accept both names, or already-migrated docs stop parsing |
  | **Documents defining or teaching it** | four `kb-authoring/` docs — `frontmatter-schema.md`, `review-rubric.md`, `principles.md`, `tier-model.md` | the definition moves; the other three cite it |
  | **Files carrying it as data** | the `knowledge-base/` doc templates, `feature-inventory.md`, `state-machine-chaining.md`, `reviewer-ledger-schema.md`, `relationship-schema.yml`'s comment, and the 22 KB docs on disk | mechanical key rename |

  The PowerShell twin and the migration parser are the two an earlier draft would have missed
  entirely, and both would have failed **after** the rename looked complete.

  **One shape at all three levels.** Every criterion — global, per-type, or per-file — is an object
  with the same fields, so resolution is a concatenation rather than a normalisation of two formats:

  | Field | Required | Meaning |
  |---|---|---|
  | `id` | yes | greppable, scope-prefixed (`G-`, `KB-`, `SK-`…; file-local entries use `F-`) |
  | `kind` | yes | `validate` or `exclude` |
  | `criterion` | yes | what to check, or what must never be checked |
  | `severity` | **only when `kind: validate`** | what a violation costs — declaring it on an `exclude` is a schema error, not a style slip |
  | `why` | yes | the reason. On an exclusion it is the whole point; without it an exclusion reads as an escape hatch |

  ```yaml
  review-criteria:
    - id: F-01
      kind: validate
      criterion: The 7-column table is the entire file; no headers, narrative or summary sections
      severity: HIGH
      why: grade.sh parses by column position, so an extra section mis-grades silently
    - id: F-03
      kind: exclude
      criterion: Example ledger rows in this document are not graded as real findings
      why: they are illustrations; grading them would fault the doc for demonstrating its own schema
  ```

  **A file-local `id` needs no global uniqueness** — the ledger's existing `Doc` column disambiguates
  it. This is also how a finding cites its criterion without any new ledger column and without
  touching `grade.sh`'s positional parse.

  **The field must stop being exempt from grading, and the exemption must be named to be retired.**
  `kb-authoring/frontmatter-schema.md` currently states that legacy fields — `intent:`, `contracts:`,
  `changelog:` — *"stay fully exempt"* from content grading. Under this model the field **drives**
  grading, so a wrong entry cannot be free. The rename carries that change: `review-criteria:` is
  graded content, and a criterion that does not hold is a finding against the file that declares it.

  Two things make this more than a wording change, and an earlier draft asserted the outcome without
  either:

  - **The exemption is one sentence covering three fields**, so retiring it for `contracts:` means
    splitting that list rather than deleting the sentence — `intent:` and `changelog:` are not in
    this work's scope and must keep their treatment.
  - **The branch already holds two mechanisms with opposite treatments of the same field.** The
    review rubric's item 3 grades `contracts:` against disk; the frontmatter lint exempts it from
    content grading entirely. That contradiction is *why* the field could be populated, wrong, and
    uncontested — and reconciling the two is part of stream 1, not a side effect of the rename.

  **Not every file can carry a file-level block, and the registry must say so.** **Two** such cases,
  both verified on this branch — an earlier draft said "three cases" above a two-row table:

  | Case | Why | Consequence |
  |---|---|---|
  | **Generator-refreshed `SKILL.md`** | rebuilt from `shortcut-catalog.yml`; anything hand-written is erased on the next run | type-level criteria only — which is sufficient, since generated files are uniform by construction |
  | **Templates carrying a payload block** | their frontmatter is the *emitted* artifact's, placeholders and all (`work-state-template.md` opens with `pipeline:`, `started: "{YYYY-MM-DD}"`) — a `review-criteria:` there would be stamped onto every generated STATE.md | type-level criteria only |

  In both, the type level does the work, which is what the cascade is for. A type that cannot carry
  file-level criteria is a **property of that type**, recorded in the registry, not a gap.

  **Both cases split their type in two, and the registry must reflect both splits symmetrically.** An
  earlier draft split `template` and left `skill` as a single type — even though the generated case is
  *larger* for skills. Derived on this branch by intersecting the catalog's row names with the skill
  directories:

  | type | generator-refreshed | hand-authored | total |
  |---|---|---|---|
  | `skill` (`canonical/skills/*/SKILL.md`) | **58** (one per `shortcut-catalog.yml` row) | **18** | 76 |
  | `template` (`canonical/aid/templates/**`) | payload-carrying: frontmatter belongs to the emitted artifact | own frontmatter (e.g. `reviewer-ledger-schema.md`) | 78 |

  So the registry carries four rows where a draft carried three: `skill-generated` /
  `skill-authored`, and `template-payload` / `template-own`. Leaving `skill` unsplit would let a
  reviewer flag 58 files for a missing file-level block that they cannot keep.

  **`canonical/agents/*/AGENT.md` is NOT such a case, contrary to an earlier draft.** It can carry a
  file-level block like any other authored file, and **`render.py` is changed to carry
  `review-criteria` through** *(owner decision, 2026-08-13)*.

  `render.py` today rebuilds the shipped agent frontmatter as a fresh dict of
  `name`/`description`/`tools`/`model` (+ optional `permissionMode`, `background`) and drops every
  other key. Strictly, the criteria do not need to ship: rendered trees are never content-reviewed,
  so the only review of an agent definition is of its canonical source, which has the field.

  It changes anyway, for a reason that is not about shipping:

  - **A type must behave identically for every member.** The registry names one `agent` type with
    one criteria list. A repo-local agent authored directly in `.claude/agents/` keeps its
    file-level block; a canonical one silently loses it at render. The type's rules would be true
    for some members and false for others, with nothing on the file saying which — the latent
    inconsistency the cascade exists to eliminate.
  - **A silently discarded field is a trap.** Written, rendered, gone, no complaint, no artifact to
    review.
  - **The cost is near zero at this moment.** One key in `new_fm`, riding the single end-of-work
    re-render NFR-4 already mandates, rather than forcing its own re-baseline later.

  *Counted honestly against NFR-2:* this is a generator edit, and it is the first one this work
  makes. It adds a line rather than an artifact, so it stays within **C-1** — but it is recorded
  here rather than waved through.

  **Two global exclusions follow, and both cover large parts of the repo:**

  | Type | Exclusion | Why |
  |---|---|---|
  | `agent-context` | root `CLAUDE.md` / `AGENTS.md` are never reviewed | shared host files — AID owns only the `AID:BEGIN`/`AID:END` region and the rest is the user's content; they point at truth rather than holding it, which is also why KB docs may not cite them. They carry no frontmatter, so there is nowhere to declare this on the file itself. |
  | `rendered` | a file **listed as a rendered `dst` in an emission manifest** is not content-reviewed | byte-identical output of `canonical/`; `architecture.md` states that *"a rendered or vendored copy is a defect; edit `canonical/` and re-render"*, and the byte-compare gate **is** their review. This is **C-5 generalised beyond the KB**: build-verify, never content-grade. |

  **The `rendered` exclusion is keyed on PROVENANCE, not on path.** An earlier draft wrote it as
  `profiles/**`, `.claude/**`, `.cursor/**` — which is wrong, and would have exempted real authored
  files from all review. `.claude/` is not purely rendered: it also holds
  `skills/generate-profile/**` (the renderer toolchain itself, including `render.py`),
  `skills/release-aid/**` (maintainer-only ops, never shipped) and `output-styles/**`. A path glob
  would have silently excluded the very code this work is about to edit.

  `tests/canonical/test-dogfood-byte-identity.sh` already encodes the right distinction, as a
  documented allowlist of non-generator files. The criterion follows it: **a file is excluded because
  it IS a render, not because of where it sits.** Anything under a dogfood tree that no manifest
  claims is authored, and is reviewable.

  **The test has TWO limbs, because the render chain has two stages — and a draft written as a fix
  only had the first.** Checking "appears as a `dst` in an emission manifest" reaches the dogfood trees
  and **nothing else**. Verified: every `dst` in `profiles/claude-code/emission-manifest.jsonl` begins
  with `.claude`, and no manifest carries a `profiles/` `dst` at all. So a one-limb provenance test
  leaves the **1,376 markdown files under `profiles/`** fully reviewable — the second-largest body of
  rendered output in the repo, and 4× the entire in-scope corpus.

  | limb | what it excludes | evidence |
  |---|---|---|
  | 1 — appears as a `dst` in an emission manifest | the two tracked dogfood trees (`.claude/`, `.cursor/`) | `grep -oh '"dst": *"[^/]*' profiles/claude-code/emission-manifest.jsonl` yields only `.claude` |
  | 2 — sits under `profiles/<tool>/` **and has a corresponding `canonical/` source** | the five per-profile render trees | `run_generator.py`'s output; the render-drift gate byte-compares it, which **is** its review |

  **Limb 2's second clause is load-bearing, not belt-and-braces.** A bare `profiles/<tool>/**` glob —
  which is what a first draft of this correction said — would exempt the **five hand-authored
  `profiles/<tool>/{CLAUDE,AGENTS}.md` files**, which have no `canonical/` source at all (verified:
  `canonical/CLAUDE.md` and `canonical/AGENTS.md` do not exist, and no manifest carries a `CLAUDE.md`
  `dst`). Those five are the *real* edit targets of FR-9, so exempting them would exclude from review
  the very files this work adds its central instruction to. **This is the same path-glob mistake as the
  original, caught one layer in.**

  **Limb 2 re-exempts nothing that limb 1 was written to protect.** Verified: none of
  `skills/generate-profile/`, `skills/release-aid/` or `output-styles/` exists under
  `profiles/claude-code/` — the repo-local carve-outs live only in the dogfood tree, so naming
  `profiles/<tool>/` cannot reach them. The two limbs are disjoint by construction.

  | Level | Holds | Lives in |
  |---|---|---|
  | 1 — **Global** | criteria every document in the project is validated against | **`.aid/knowledge/authoring-conventions.md`**, as a new section |
  | 2 — **Document type** | criteria for that class of document (KB doc, skill, skill reference, agent, template) | **the same document**, as a second new section |
  | 3 — **This document** | only what is unique to this file | the file's own `review-criteria:` |

  **Levels 1 and 2 are expressed as two tables** in that document *(owner decision, 2026-08-12)*:

  **A type registry** — answering "what types exist, and which one is this file?". Selectors must be
  **mutually exclusive and exhaustive** over the in-scope corpus, which is the property AC-1 checks:

  ```markdown
  | Type | Selector | Notes |
  |------|----------|-------|
  | `kb-doc` | `.aid/knowledge/*.md` | except the meta and generated docs below |
  | `skill` | `canonical/skills/*/SKILL.md` | |
  | `skill-reference` | `canonical/skills/*/references/*.md` | the procedure bodies |
  | `state` | any `STATE.md`, any depth | never reviewed — see `G-04` |
  ```

  **A criteria table** — **one row per criterion, not per type**, carrying the same fields as the
  frontmatter object. `*` in `Applies to` means global, so levels 1 and 2 share one list and
  duplication is visible on sight: two rows saying the same thing for two types belong at `*`.

  ```markdown
  | ID | Applies to | Kind | Criterion | Severity | Why |
  |----|-----------|------|-----------|----------|-----|
  | G-01 | `*` | validate | No cosmetic counts unless the count is load-bearing | MINOR | drifts every commit; the reader can run `wc -l` |
  | G-04 | `state` | exclude | Never reviewed, at any level, in any folder | — | bookkeeping; a completed run's rows are correct as history, so any content check fires forever |
  | SK-01 | `skill` | validate | Every agent named in a Dispatch table resolves to `canonical/agents/<name>/` | HIGH | a skill dispatching a non-existent agent fails at run time |
  ```

  A table rather than a section per type because it stays compact as types are added, and because
  "does every in-scope file resolve to exactly one type?" is then answerable by reading one column.
  **No cell may contain a pipe** — a criterion needing one is rephrased. *(This constrains the
  markdown tables only; the YAML frontmatter has no such limit, which matters because real criterion
  text does contain pipes.)*

  **Both levels live in `authoring-conventions.md`, and stay together.** *(Owner decision,
  2026-08-12.)* The concern spine places it at **C3 — "What conventions and standards does it
  follow?"** — and the criteria *are* the conventions: a reviewer validating a document is checking
  it against the standards it was authored under. The doc is `kb-category: primary`, already tagged
  `enforcement`, and **already carries level 1** in unlabelled form: `## Drift-Prone Content is
  Banned` (four criteria, with their exclusions attached), `## Citation Rule (Durable Anchors)`,
  `## Resolved Items Leave No Trace`. `## KB Document Layout` is a level-2 section for a single type.

  **Not `quality-gates.md`.** It is `kb-category: extension`, tagged **C6 — "Quality & how it is
  checked"**, and holds the *machinery*: the grade scale, the ledger, how a grade is computed,
  minimum-grade thresholds. That boundary must hold — criteria and what a violation costs in C3,
  scoring in C6, cross-referenced and never duplicated. Duplication across these two is what
  produced three independent severity definitions on this branch.

  A reviewer resolves all three and validates against the **union**. Most specific wins on conflict.

  **The three levels exist to stop duplication, not to add structure.** Their purpose is that a
  criterion is stated exactly once, so it cannot be copied into many files and drift apart, and so
  no single file's frontmatter inflates. The operating rules follow directly:

  - A file's `review-criteria:` **never restates** a global or type-level criterion.
  - The same criterion appearing in two files means it belongs at the **type** level.
  - The same criterion appearing in two types means it belongs at **global**.
  - Consequently most files carry **few entries or none** — a short list is the expected state, not
    a sign of an incomplete declaration.

  Ignoring this reproduces the exact defect this work removes: N copies of one rule, disagreeing
  with each other. Only the location changes — from scripts into frontmatter.

  **Criteria are positive AND negative.** A criterion says either *"validate this"* or *"do not
  validate this"*. An exclusion is recorded **where a reviewer would otherwise reasonably check and
  would be wrong to** — not for everything merely inapplicable — and it carries its **reason**,
  because an exclusion without one reads as an escape hatch and is how a bar gets quietly lowered.

  Exclusions cascade identically: `STATE.md` is never reviewed at any level (global); a
  `source: generated` document's *content* is not graded, only its generator (type); and anything
  uniquely not-to-be-checked here (file).

  *Why this half matters most:* in `work-003`, a guard swept a KB `STATE.md`, found five historical
  lines, and was answered with **five allowances plus a schema amendment written to defend them** —
  an allowlist accreting invisibly inside a script. A declared exclusion is that same knowledge,
  stated once where it can be read and argued with.

  **One uniform field for every in-scope tree.** A `SKILL.md`, an `AGENT.md`, a template and a KB
  doc all declare the same way — no per-artifact-kind schema, no `references:`/`dispatches:`
  variants. The field and a check that derives it already exist in
  `kb-authoring/frontmatter-schema.md` and `kb-authoring/review-rubric.md` item 3, scoped to KB
  docs; this widens both rather than adding a second mechanism (**C-1**).
- **FR-6** **Severity resolves through the same three-level cascade, over validatable defect kinds
  only.** *(Owner decision, 2026-08-12.)*

  **Severity is a field on each criterion, not a block of its own.** A criterion *is* a defect kind,
  so a `severity` on every `review-criteria` entry already **is** the defect-kind → level map — with
  no second block that can drift out of step with the first. An earlier draft proposed a separate
  `severity:` map; it is withdrawn as a redundant surface (**C-1**).

  A criterion with `kind: exclude` carries **no** severity. Declaring one is a schema error: an
  excluded defect kind is not scored, and there is no such thing as an exclusion expressed as a
  severity of zero.

  | Level | Holds | Lives in |
  |---|---|---|
  | 1 — **Global** | what each severity *means* | `canonical/aid/templates/grading-rubric.md § Issue Severities` — the universal scale, shipped |
  | 2 — **Document type** | what each defect kind costs in that class of document | **`.aid/knowledge/authoring-conventions.md`**, beside that type's criteria |
  | 3 — **This document** | overrides only where this file genuinely differs | the file's own `review-criteria:` |

  **Overrides are permitted** *(owner decision, 2026-08-12)*, under two conditions that are not
  optional.

  **An override introduces no new field and no new shape — it reuses the higher-level `id`.** FR-5
  fixes one object shape at all three levels, and an override is not an exception to it: a file-level
  entry carrying an `id` that already exists higher up **is** the override, because FR-5 already
  resolves conflicts by "most specific wins". The five fields are unchanged:

  ```yaml
  review-criteria:
    - id: G-01                 # the global id, restated at file level = override
      kind: validate
      criterion: No cosmetic counts unless the count is load-bearing
      severity: HIGH           # global says MINOR
      why: this doc's counts are load-bearing; a stale one misroutes an agent
  ```

  *An earlier draft wrote this as `- override: G-01` with only `severity` and `why`* — a fourth object
  shape, missing `id`, `kind` and `criterion`, in the same requirement that mandates one shape
  everywhere. Reusing the `id` costs nothing and keeps resolution a plain concatenation.

  1. **`why` is mandatory on every override**, enforced by the schema rather than by convention.
     Without it an override is indistinguishable from a bar being lowered.
  2. **The effective value is surfaced in the finding itself** — the reviewer writes the resolved
     severity and the overriding file's `why` into the finding's **`Evidence` cell**.
     *(Owner decision, 2026-08-13.)* An override is precisely where a bar can be quietly lowered, so
     it must be visible at the moment it is applied.

     **This costs no machinery, which is why it is this and not a gate-output change.** `grade.sh`
     documents that *"Severity tags in cols[5..8] (Doc, Line, Description, Evidence) are ignored"*, so
     the cell is already inert to grading and carries free-form evidence by design. Nothing is built,
     `grade.sh` is untouched, and the override travels with the finding it affects rather than sitting
     in a summary someone has to remember to write.

  *This resolves what an earlier draft carried as an unresolved "open cost", and it corrects a second
  draft that required the value "in the gate output" — which read as a `grade.sh` change and put this
  requirement in direct conflict with feature-001's no-new-mechanism criterion. It is now a
  requirement satisfiable without touching either.*

  Level 2 sits with the criteria it prices, not in `quality-gates.md`: what a violation costs is a
  property of the criterion (C3), while turning severities into a letter grade is machinery (C6).
  `authoring-conventions.md`'s existing `## Enforcement` table is the *before* picture of this — it
  already lists each convention, its enforcer, and "what breaks on violation", in prose rather than
  as a declared level.

  Same anti-duplication rule as FR-5: declared once, at the highest level where it is true. Level 3
  is an **override, not a requirement** — which is what keeps most in-scope files from carrying any
  severity at all.

  **Severity covers only what IS validated.** If something must *never* be validated, that is an
  entry with `kind: exclude` in `review-criteria:` (FR-5), not a severity. There is no such thing as
  an exclusion expressed as a severity of zero, and an excluded criterion carries no `severity` field
  at all.

  *Why per-kind rather than per-file:* severity currently comes from the rule that fired, so it is
  uniform everywhere that rule applies — a stale count and a false claim in a routing document score
  identically. Declaring it per kind, per document, makes that difference expressible where it
  actually differs.

  **Placement — corrected.** An earlier draft of this requirement asserted that levels 1 and 2 must
  live in `canonical/aid/templates/` rather than the KB, reasoning that the KB does not ship. That
  was too strong and is withdrawn. Criteria and per-type severity are **project-specific** — an
  adopter's document types are not AID's — so **each project's own KB is the right home**, exactly
  as FR-5 states. What ships is the *template* for those KB documents plus the universal severity
  scale below. AID's KB carries AID's lists; an adopter's carries theirs.

  **The universal scale already exists** at `canonical/aid/templates/grading-rubric.md § Issue Severities` — the
  five-row Minor/Low/Medium/High/Critical table.

  Who cites it, derived on this branch with `grep -rln "grading-rubric" canonical/` — **14 files**,
  not the 5 an earlier draft named:

  | citers | files |
  |---|---|
  | per-skill `reviewer-brief.md` | **5 of the 6** — `define`, `detail`, `execute`, `plan`, `specify`; **not** `discover` |
  | other review surfaces | `reviewer-dispatch.md`, `kb-authoring/review-rubric.md`, `aid-define/references/cross-reference.md`, `aid-execute/references/state-review.md`, `aid-execute/references/state-delivery-gate.md`, `aid-specify/references/state-continue.md`, `shortcut-engine.md`, `aid-summarize/SKILL.md` |
  | plus | `EMISSION-MANIFEST.md` (a render entry, not a citation of the rubric's content) |

  **The two that matter here still do not cite it:** `aid-reviewer/AGENT.md` and
  `reviewer-ledger-schema.md` — the surfaces a reviewer actually reads — plus `grade.sh`, which names
  no path, only "the universal AID rubric" in a comment. That is the finding, and it survives the
  corrected count: the scale is widely cited *and* independently redefined in the two places closest to
  the reviewer.

  *The earlier list was not merely short — it omitted `reviewer-dispatch.md`, which is itself a
  stream-1 target, so the document under-counted its own blast radius.*

  **There are already three severity homes, not one.** `grading-rubric.md § Issue Severities`,
  `reviewer-ledger-schema.md § Severity values`, and `aid-reviewer/AGENT.md § Severity
  Classification` each define all five severities independently, in different words, and neither of
  the latter two cites the first. Extending `grading-rubric.md` alone would leave the two surfaces a
  reviewer actually reads unchanged. **Reconciling the three is in scope for feature-001** — this is
  a correction to an earlier draft that assumed a single home and warned only against creating a
  second.

  *(An earlier draft carried the per-file-bar risk as an unresolved "open cost". It is resolved
  above: overrides are permitted, `why` is mandatory, and the effective value is surfaced in the
  gate output.)*
- **FR-7** **Delete the 20 internal `README.md` files** under `canonical/skills/` (11) and
  `canonical/agents/` (9) — 1,802 lines. *(Owner decision, 2026-08-12: they are issue-prone surface
  that adds no value.)*

  Evidence for the decision:

  | Fact | Value |
  |---|---|
  | Lines removed | 1,802 |
  | Skills that even have one | **11 of 76** — not a convention, 11 exceptions |
  | How many reach an adopter | **zero.** No README under any `profiles/*/skills/` or `profiles/*/agents/`, none in either tracked dogfood tree. Rendered agents are flat files (`aid-reviewer.md`), not folders. |
  | With zero inbound references | **18 of 20** — re-derived; see the method below |
  | Precedent | *(withdrawn — an earlier draft cited `aid-graph/README.md` as "already declined as a documentation surface". No on-disk record of that decision exists on this branch, so the row asserted something unverifiable inside a table of verified facts.)* |

  **The "18 of 20" is re-derived, and its method is stated because the previous method was wrong.**
  The `examples/` audit earlier in this document searched only for `](README.md)` and so missed
  directory-style links. This one used two searches: `grep -rno "aid-[a-z-]*/README\.md" canonical tests
  site lib` for path references, and a search for relative `](README.md)` / `](./README.md)` links
  across `canonical/`. Exactly **two** of the 20 are reached:

  | README | referenced from |
  |---|---|
  | `aid-clerk/README.md` | `aid-execute/references/state-execute.md` → “Mechanical sub-tasks”, and the generated sidecar `site/src/data/skill-flows/aid-execute.flow.json` |
  | `aid-monitor/README.md` | `tests/canonical/test-deploy-monitor-repurpose.sh` (three assertions — see below) |

  The relative-link search found only `canonical/aid/templates/kb-authoring/README.md`, cited 6 times
  as an index by three sibling docs — **that file is not in this delete set**, which covers
  `canonical/skills/` and `canonical/agents/` only. The remaining 18 are reached by nothing.

  Deletion is a **fix**, not only a cleanup: the single instruction-content pointer at one of them
  is already broken. `aid-execute/references/state-execute.md` → the “Mechanical sub-tasks” paragraph tells an
  executor *"See `agents/aid-clerk/README.md` for the caller contract"*, and that path exists in no
  installed tree — the line is replicated to all five profiles and both dogfood trees, so seven
  copies of the pointer resolve to nothing.

  **Two files need preparation before deletion, or deletion causes a regression:**

  1. **`canonical/agents/aid-clerk/README.md`** — move the caller contract into
     `aid-clerk/AGENT.md`, which does ship; then correct `state-execute.md` → “Mechanical sub-tasks” and **regenerate**
     `site/src/data/skill-flows/aid-execute.flow.json`, which is a generated sidecar and must not be
     hand-edited. Deleting first would turn a broken pointer into a lost contract.
  2. **`canonical/skills/aid-monitor/README.md`** — `test-deploy-monitor-repurpose.sh` asserts against
     it **three** times, not once, so removing one assertion leaves two failures behind. Derived with
     `grep -n MONITOR_README tests/canonical/test-deploy-monitor-repurpose.sh`:

     | assertion | what it checks |
     |---|---|
     | `DMR00c` | the README exists |
     | `DMR03c` | its routing table maps `BUG` → `/aid-fix` |
     | `DMR03d` | its routing table maps `Change Request` → `/aid-triage` |

     All three go with the file — **and the two routing rows are content, not existence**, so before
     deletion the sweep must confirm that mapping is stated somewhere that ships. *An earlier draft
     named only `DMR00c`, which would have left the suite red and read as a surprise regression rather
     than a known consequence.*

  *Why this belongs in a work about declared criteria:* every deleted file is one fewer surface that
  can drift, and it is the inverse of adding a mechanism — **C-1** applied in the direction that
  shrinks the reviewed surface instead of growing it.
- **FR-8** **The front face is brought into line with the changed trees, at the very end** —
  `docs/*.md` (7), the repo-root `README.md` (257 lines) and `examples/**/README.md` (4 files, 1,237
  lines). Deferred by owner decision because these describe trees that are still moving until stream
  3 closes; scheduled alongside the single render of NFR-4 for the same reason. Added because the
  deferred bucket was previously gated by feature-003 with no requirement behind it.
- **FR-9** **Resolving criteria before writing is a global instruction to every agent, in
  `canonical/aid/templates/agent-boilerplate.md`.** *(Owner decision, 2026-08-12.)*

  That template is included by **every** `canonical/agents/*/AGENT.md`, which makes it the one
  surface that reaches all **dispatched sub-agents** at once. The instruction is **not** scoped to
  `aid-reviewer`, and **not** distributed across individual skills: an agent that writes files —
  developer, architect, tech-writer, clerk, operator — is bound by it wherever it is dispatched from.

  **A second surface is required, or the session's own agent is not bound.** `agent-boilerplate.md`
  reaches **dispatched sub-agents** only. The agent running the session itself — the one the user talks
  to, which dispatches the others — never reads an `AGENT.md`; it reads the repo-root `CLAUDE.md` /
  `AGENTS.md`. Since it writes files constantly (most of this work's own artifacts were written that
  way), the instruction must also sit in the `AID:BEGIN`/`AID:END` region of those files.

  *Naming, corrected:* an earlier draft called this "the main/orchestrator agent". **`aid-orchestrator`
  is a real dispatched agent on this branch** with its own `AGENT.md`, so it is already bound by
  `agent-boilerplate.md` like every other sub-agent. Using "orchestrator" for the session agent
  conflates the two and would mis-target the edit.

  **The edit target is the five hand-authored profile sources, NOT the repo-root files.** Verified on
  this branch:

  | fact | evidence |
  |---|---|
  | The five sources are hand-authored, one per profile | `profiles/{claude-code/CLAUDE.md, antigravity/AGENTS.md, codex/AGENTS.md, copilot-cli/AGENTS.md, cursor/AGENTS.md}` |
  | They are **not** render output | no `canonical/CLAUDE.md` or `canonical/AGENTS.md` exists, and no emission manifest carries a `CLAUDE.md` `dst` |
  | The repo-root file is **install output** | `lib/aid-install-core.sh` → `_copy_root_agent_file`, which writes the marked region from the profile source |

  So editing the repo-root `CLAUDE.md` would edit an install artifact and be overwritten on the next
  install; the change has to land in all five profile sources. *An earlier draft named the repo-root
  files as the target and gave their byte sizes, which described the output rather than the source and
  named none of the five files that actually have to change.*

  Those files being **excluded from review** (see FR-5) does not make them a poor home for it: they
  hold pointers, not truth. `CLAUDE.md` already carries exactly this shape of instruction in
  `## Tracking discipline (IMPERATIVE)` and `## Review output format (global)`, each pointing at a
  definition held elsewhere. The criteria themselves stay in `authoring-conventions.md`; the context
  file only says "resolve them before you write".

  Per-skill instructions were considered and rejected: they would put the same rule in many places,
  which is the duplication FR-5's cascade exists to prevent, applied to instructions instead of
  criteria.

- **FR-10** **A work that introduces a new document type owes the KB the registry row and its
  criteria — and this too is a global instruction, not a phase's private duty.**
  *(Owner correction, 2026-08-12.)*

  It is foundational rather than procedural: **if a new document type is introduced, the KB is
  updated**, whichever agent introduces it and whichever phase it is in. It therefore lives in
  `agent-boilerplate.md` alongside FR-9, not in `/aid-define` and `/aid-specify` as an earlier draft
  proposed.

  **Symmetric:** a work that removes the last file of a type removes its registry row. Otherwise the
  registry accumulates rows for types that no longer exist — the same drift, in the other direction.

  **Backstop, so this does not rest on an agent noticing.** `authoring-conventions.md` carries a
  criterion on itself: *every in-scope file resolves to exactly one registry row.* If the introducing
  work misses the addition, the next review of that document catches it. Proactive obligation plus
  review backstop — and neither is a mechanism (**C-1**).

## 6. Non-Functional Requirements

### NFR-1 — A planted defect can never reach the work branch

**C-6** requires proving each new criterion against a planted defect. That creates a real hazard: a
plant that is forgotten becomes a genuine defect. The hazard is removed **structurally**, in three
independent layers — not by a reminder, and not by a new guard.

1. **The plant is never applied to the tracked tree.** It goes into a **disposable git worktree at
   the same commit**, and the work branch's files are never edited — so there is nothing to restore
   and nothing to forget.

   **Correction: the named script cannot do this.**
   `canonical/aid/scripts/works/worktree-lifecycle.sh` has exactly two verbs, `create)` and
   `locate)` — **no destroy** — and `create` is keyed to a `work-NNN` branch and is idempotent, so
   it returns the *existing* work-004 worktree rather than a throwaway. An earlier draft named it as
   the mechanism. The disposable tree therefore comes from plain `git worktree add` on a detached
   HEAD plus `git worktree remove`, which needs nothing built. *(The earlier draft also cited the
   `.claude/` path — a render. The source of truth is `canonical/`.)*

   *Why a whole worktree rather than a single scratch file:* a `review-criteria:` entry is derived
   from the file's **position in the tree** (*"`canonical/skills/` holds 76 directories"*), so a
   lone copy in a temp directory cannot be derived against. The tree has to be real; only its
   location is disposable.

   This follows a convention the repo already uses. `tests/canonical/test-dogfood-byte-identity.sh`
   runs its negative controls against a `mktemp -d` scratch copy under a
   `trap 'rm -rf …' EXIT`, and states that nothing under the tracked trees is ever written. NFR-1
   is that convention scaled from a file to a tree — **no new mechanism**.

2. **The plant is never committed.** It exists only as an uncommitted edit inside the disposable
   worktree. Leaking one would require two independent failures at once: the wrong tree *and* a
   commit.

3. **The plant class is self-announcing.** The planted defect is, by construction, *a file body
   contradicting its own `review-criteria:` entry* — exactly what this work builds the reviewer to report
   as a violation. A forgotten plant of this class is flagged by the very next review. Unlike a
   planted bug in code, which is silent, this one trips the detector being installed: **the proof's
   subject matter is its own alarm.**

### NFR-2 — The work must end with less enforcement surface than it started

`work-003` failed because every fix grew the reviewed surface. This work is only successful if the
opposite is measurable: **lines of prose-fact guard removed must exceed lines of new mechanism
added.** Stated as a number, not a sentiment.

**Both sides of the subtraction must be defined, or the criterion is unfalsifiable.** An earlier
draft gave only a floor and never said what counts as "added".

| side | definition | confirmed floor |
|---|---|---|
| **removed — guard lines** | script logic whose job is checking a fact stated in prose | **379** (`check-skill-counts.mjs`) |
| **removed — documentation lines** | prose deleted outright: the 20 internal READMEs | **1,802** |
| **added — mechanism lines** | new scripts, checks, validators, or process rules an agent must follow | derived at close |

**The two removal figures are never summed into one number.** Merging them lets deleted prose pay for
added machinery, which is the exact loophole this NFR exists to close — so `379 + 1,802 = 2,181` is a
figure this document deliberately does not state as a floor. **The comparison that decides AC-4 is
guard lines removed vs. mechanism lines added: 379 against a number stream 3 derives.** The 1,802 is
reported alongside it and carries no weight in the test.

*An earlier draft defined the two kinds as separate in one sentence and then stated their merged
total as "the confirmed floor" in the next — and AC-4 inherited the merged figure.*

**An authored `review-criteria:` block is not mechanism.** It is the file stating a fact about itself,
which is the whole point, so no authored declaration counts against the added side. **How many files
gain one is an output, not an estimate** — under FR-1's cascade most of the 290 correctly gain nothing,
so an earlier draft's "roughly 290 files gain such a block" contradicted FR-1 and AC-1 and is
withdrawn.

The rest of the removal set is derived by stream 3, not asserted here — see §2.

This is **C-1** promoted to a measured exit condition, because "do not over-engineer" was already
stated in `work-003` and did not hold.

### NFR-3 — Stream-1 edits stay additive and localized

A new section, a new instruction paragraph, a new rule row — never a restructure of a file
`work-003` has also restructured. See §8: this keeps a later reconcile cheap and satisfies **C-1**
at the same time.

### NFR-4 — Every derived chain is refreshed exactly once, at the end

**Two chains, not one.** An earlier draft named only the first:

1. `canonical/` → `profiles/` → the two tracked dogfood trees, per **C-2**.
2. The **site chain** — `site/src/content/docs` and `site/src/data/skill-flows/*.flow.json`. This
   work edits `docs/*.md` (feature-003) and `canonical/skills/aid-execute/references/state-execute.md`
   (feature-002), both of which feed it. `aid-execute.flow.json` is generated and must be
   regenerated, never hand-corrected.

Mid-work staleness in either is correct and is not a defect. Both refresh once, in feature-003.

### NFR-5 — Every declaration must be derivable by an agent with repo access alone

No `review-criteria:` entry may assert something requiring a network call, a paid service, a private
credential, or knowledge of a work folder (which is transient by rule). A declaration that cannot be
checked from the repo is worse than none — it reads as verified and never is.

## 7. Constraints

Inherited from `work-003`. Violating any of these reproduces its failure — see `prior-art.md § 6`.

- **C-1** A fix that adds a mechanism adds reviewed surface. Prefer stating the fact where it lives
  over encoding a check for it elsewhere. **This work must not become the next pile of guards.**
- **C-2** Derived artifacts (`profiles/`, both tracked dogfood trees) refresh **once, at the end**.
  Mid-change staleness is correct, not a defect.
- **C-3** Do not narrate a refactor inside the artifact it produced — it is false as soon as the
  next change lands, and git records the history anyway.

  **Scope, sharpened after review found this document violating it.** C-3 bans *refactor narration* —
  "this file was split from three others", "the catalog now lives in four documents" — which is
  describing a **move** that stops being true the moment anything else moves.

  It does **not** ban a **correction record**: a note that a specific figure or claim was wrong and
  states the derived replacement. Those carry a durable fact plus a warning, and this document has
  the evidence that the warning is load-bearing — the `341` figure was re-introduced *after* a pass
  dedicated to removing it, and the `Rule` column survived that same pass. The correction notes in
  §2, §4, FR-6, FR-7 and AC-1 are kept deliberately on that basis.

  *Judgement call, flagged rather than resolved silently:* a reviewer could reasonably read the
  original C-3 as covering both. If the owner disagrees, the notes move wholesale to the Change Log
  and git, and nothing else in the document changes.
- **C-4** `STATE.md` is never reviewed, at any level, in any folder.
- **C-5** `source: generated` means build-verify only. `INDEX.md` and `relationships.md` are
  **generated** and are treated as build-verify rather than content-graded.

  *Corrected wording.* An earlier draft called them "a special kb-category, meta to the KB". Both are
  `kb-category: primary` with `source: generated` — verified in their own frontmatter — and the review
  rubric's routing table sends that combination to **"Full Primary + Build-Verify"**, which content-
  reviews as well. So the carve-out in AC-1 rests on `source: generated`, not on a kb-category they do
  not have, and it is a **decision of this work** rather than an inherited rubric rule.
- **C-6** A new assertion is not trusted until it has been shown to fail against a planted defect.

## 8. Assumptions & Dependencies

### `work-003` is a source to draw from on demand, never a branch to merge

`work-003` sits **131 commits ahead of `master`** and unpushed. Against review-related files under
`canonical/`, it **modifies 26** that exist here and **adds 17** that do not — the whole
`review-rubrics/` catalog and `reviewer-brief-template.md` among them.

> **These three figures are measurements of another branch and cannot be re-derived here**, which is
> what C-7 gate 3 forbids. They are admitted as **the first entries in the import log** — serving `§8`
> itself, derived by `git diff --name-status master...work-003`, carrying no mechanism, and logged per
> gate 6. They are recorded as *known collision surface*, not relied on for any design decision: every
> stream-1 target was independently derived from this branch in §4.

**The import log does not exist yet, and this document must not speak as though it does.** Its path is
`.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md`, and **creating it with
these three figures as its first entries is the first task of stream 1** — verified absent on this
branch (`find . -name imports-from-work-003.md` returns nothing). An earlier draft referenced it in the
present tense in §8, C-7 gate 6 and AC-6 while naming no path, so a reader could not tell whether it
was missing or merely unlocated — and AC-6 gated the work on auditing a file nothing had been asked to
create.

The 26 modified files are the real collision set, and they include every stream-1 target:
`aid-reviewer/AGENT.md`, `grading-rubric.md`, `kb-authoring/review-rubric.md`,
`reviewer-dispatch.md`, `reviewer-ledger-schema.md`, the six per-skill `reviewer-brief.md` files,
and `aid-summarize/references/state-fix.md`.

**Decision (owner, 2026-08-12): work-004 does not merge, rebase onto, or cherry-pick `work-003`.**
`work-003` failed to converge on its own gate; importing it wholesale would import the
over-engineering and the defects along with anything useful. work-004 is off `master` and stays
there.

`work-003` is treated as **evidence and a source of individual facts**, admitted one at a time.

### C-7 — Admission criteria for anything drawn from `work-003`

All six must hold. Any one failing means it does not come across.

1. **Facts, not files.** What crosses is a *statement*, re-authored into work-004's own tree. Never
   a commit, never a cherry-pick, never a file copy.
2. **Named need.** The import cites the work-004 requirement (`FR-n` / `AC-n`) it serves. Nothing
   arrives because it looked useful.
3. **Independently re-derived.** The fact is verified against **work-004's disk**, not accepted on
   `work-003`'s prose. If it cannot be re-derived here, it does not come — `work-003`'s own numbers
   were measured on a tree with more files in it, which is how this document's first draft acquired
   figures nobody could check (see §2).
4. **No mechanism rides along.** Scripts, guards, tests and new artifact types never cross. Only
   criteria and statements. **C-1** applies with full force at the boundary: `work-003`'s defects
   were overwhelmingly *in the guards it added*.
5. **Smallest form that carries the fact.** If stating it takes more than a few lines, it is a
   redesign rather than an import, and it goes through work-004's own design instead.
6. **Logged.** One line in
   `.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md` — created by stream 1's
   first task, since it does not yet exist: what came across, which requirement it serves, and where it
   was re-derived from. Contamination that is invisible cannot be undone.

### Collision is a separate problem from contamination — and C-7 does not solve it

C-7 keeps `work-003`'s content out. It does **not** stop the two branches editing the same 26 files.
Worse in one specific way: `work-003` **adds** a `review-rubrics/` catalog that would be a second
home for exactly the criteria this work is putting in `kb-authoring/review-rubric.md`. Whichever
branch merges second inherits two catalogs describing one thing.

**Mitigation, and a design constraint on stream 1:** keep stream-1 edits **additive and localized** —
a new section, a new instruction paragraph, a new rule row — never a restructure of a file
`work-003` has also restructured. Re-applying an additive edit onto a reorganized file is cheap;
re-applying a competing reorganization is the failure that cost PR #12 63 commits.

### Other dependencies

- **No dependency on `work-003` landing.** Every stream can be completed against `master`. This
  work is not blocked by, and does not block, `work-003`.
- **The render chain** (`canonical/` → `profiles/` → the two tracked dogfood trees) is refreshed
  **once at the end**, per **C-2**.
- **Assumed:** the reviewer agent, given an explicit instruction to read a file's `contracts:`
  block, will act on it. If that assumption fails, the whole approach fails, which is why **AC-2**
  demands it be evidenced in a real review rather than asserted.

## 9. Acceptance Criteria

- **AC-1** **Every in-scope authored markdown file is covered by the three-level cascade.**

  Coverage is achieved by the **global and per-type criteria lists in the KB**, plus a per-file
  `review-criteria:` block **only where the file has something of its own**. A file that declares nothing
  and is fully covered by its type passes. An earlier draft demanded a declaration in every file;
  that would have forced the duplication the cascade exists to prevent (FR-5).

  Checkable as three things:
  1. Every in-scope file **resolves to exactly one document type**, and no file is left untyped.
  2. Every type's criteria list exists and is non-empty in the KB.
  3. Where a file *does* carry `review-criteria:`, no entry restates a global or type-level criterion,
     and every entry — positive or exclusion — is derivable from the repo.

  **The population below is the survey, not a quota.** An earlier draft wrote "179 + 126 + 9",
  which triple-counts: the 9 `contracts: []` KB docs sit *inside* the 126, and the 179 still included
  the 20 READMEs FR-7 deletes first.

  | step | count |
  |---|---|
  | surveyed in scope | 315 |
  | − 20 internal READMEs, deleted first by FR-7 | 295 |
  | − 5 KB files carved out: `STATE.md` (C-4, also `kb-category: meta`), `INDEX.md` + `relationships.md` (C-5, build-verify), and the other two `kb-category: meta` docs `README.md` + `external-sources.md` | **290** |

  Of those 290: **159** have no frontmatter block at all, **123** have a block that declares nothing,
  and **8** already declare — and those 8 must be **verified, not assumed**, since a stale existing
  declaration is the worst case of all.

  **The carve-outs come out of the buckets, not only off the total.** An earlier draft subtracted the
  5 KB files from 315 but left them inside the bucket figures, so the three buckets summed to 295
  against a stated total of 290. Where each carve-out sits, derived from its own frontmatter:

  | carve-out | why carved out | bucket it leaves |
  |---|---|---|
  | `STATE.md` | C-4 | no `contracts:` key → the *declares nothing* bucket |
  | `README.md` | `kb-category: meta` | no `contracts:` key → the *declares nothing* bucket |
  | `external-sources.md` | `kb-category: meta` | `contracts: []` → the *declares nothing* bucket |
  | `INDEX.md` | C-5, build-verify | populated `contracts:` → the *already declares* bucket |
  | `relationships.md` | C-5, build-verify | populated `contracts:` → the *already declares* bucket |

  So 3 leave the middle bucket (126 → **123**) and 2 leave the last (10 → **8**), and
  159 + 123 + 8 = **290**. The 159 is untouched: no carve-out lacks frontmatter.

  Two figures elsewhere in this document follow from the same correction and are **deliberately left
  as they are**, because they describe the survey rather than the population: §2's table still reports
  126 and 10, and §2 still reports 9 KB docs at `contracts: []`. Of those 9, `external-sources.md` is
  carved out, leaving **8** in the population — which is the number stream 2 corrects.

  **How many of the 290 end up carrying a block is an output, not a target.** Under the cascade most
  will not, because their type's criteria already cover them, and a file gains frontmatter only where
  it has a genuine exception. This also removes the earlier premise problem: a generated `SKILL.md`
  or a template whose frontmatter slot is occupied needs no per-file block at all, provided its
  **type** is declared in the KB.
- **AC-2** **The reviewer demonstrably reads the declaration in a real review.** Evidenced, not
  asserted: an instruction that exists and goes unread is the exact failure being fixed, and
  `kb-authoring/review-rubric.md` item 3 proves an unread check can sit in the rubric for a whole
  delivery — cited once in 47 findings.

  **Both directions must be proven, not just the reviewer's.** Since FR-2 makes criteria a writer's
  contract first, testing only the reviewer would leave the more valuable half unproven:

  1. **Writer** — an agent dispatched to write or edit a file of a given type resolves that type's
     criteria and complies, without being told to in the task prompt.
  2. **Reviewer** — given a planted contradiction between a file's body and its resolved criteria,
     applied in a disposable worktree under NFR-1, a real review returns the finding citing that
     criterion's `id`.

  This is **C-6** applied to this work's own output, it reuses an existing convention, and it adds no
  maintained test.

  *Not the method:* counting how often contract-derived rules get cited across later reviews. That
  is a stronger long-run signal but needs several reviews to accumulate, so it cannot gate the work.
  Recorded as a follow-up measurement against the `1-in-47` baseline, not as an acceptance gate.
- **AC-3** The superseded prose-fact scripts are gone, and their removal loses no check the
  declarations do not cover. Each removed check is named, with the declaration that replaces it.

  **Stream 3 derives the removal set from this branch before removing anything** — the inventory is
  an output of the work, not an input. `kb-citation-lint.sh` is a named non-candidate **because it
  checks citation *form* rather than a prose fact** — the single sufficient reason. *An earlier draft
  added "and CI invokes it", which is false: `grep -rn "citation-lint" .github/workflows` returns
  nothing. It is orchestrator-gated at GENERATE (`authoring-conventions.md § Enforcement`), and CI runs
  only its unit test.*

  **`check-skill-counts.mjs` cannot be retired wholesale, and the replacement must be scoped before
  the removal.** Its corpus, read from `INCLUDE_FILES` / `INCLUDE_TREES` / `REPO_LOCAL_SKILLS`, is the
  root `README.md`, `docs/`, `.aid/knowledge/`, `canonical/`, `site/src/content/docs/`, and
  `.claude/skills/{generate-profile,release-aid}` — and its extension filter is
  `.md|.mdx|.sh|.mjs|.js|.ts|.yml|.yaml`. Two consequences a declaration cannot absorb:

  1. **It guards non-markdown files.** A markdown-frontmatter criterion has nowhere to live in a `.sh`
     or `.mjs`, so the cascade **structurally** cannot cover that part of its corpus.
  2. **Three of its trees have no declared type.** `site/src/content/docs/` is out of scope; `docs/`
     and the root `README.md` are the deferred front-face bucket; and the two repo-local skill trees
     are absent from `canonical/`, so no registry row reaches them.

  Therefore AC-3 requires, **before** any removal: for each check being retired, either the criterion
  and registry row that covers it, or an explicit statement that the coverage is being dropped and
  why. **A removal whose replacement has no home is a coverage loss, and this criterion fails on it.**
- **AC-4** **Net enforcement surface is down**, per NFR-2 — **removed guard lines exceed added
  mechanism lines**, stated as a number.

  **Guard-line floor: 379** (`check-skill-counts.mjs`), and that is the figure the criterion is tested
  against. The **1,802** documentation lines from the 20 READMEs are reported **separately** and do
  **not** count toward it. An earlier draft stated a merged floor of 2,181, which NFR-2's own
  definition forbids: merged, deleted prose pays for added machinery and the criterion stops measuring
  what it exists to measure.
- **AC-5** The 20 internal READMEs are deleted, with the `aid-clerk` caller contract relocated to
  `AGENT.md` and the `aid-monitor` test assertion removed alongside its file (FR-7).
- **AC-6** Nothing from `work-003` crossed into this work except through the six C-7 gates, each
  logged in `.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md` — which stream 1
  creates, since it does not exist on this branch today.

## 10. Priority

**Now.** The review process is the load-bearing part of the methodology, and it is currently
ineffective in a measured way — `work-003` could not close its own gate. Nothing else should
proceed through review while review itself is broken.

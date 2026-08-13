# Requirements

- **Name:** Declared Review Criteria
- **Description:** Review criteria are declared as data — global and per-document-type lists in the Knowledge Base, per-file exceptions in a file's own frontmatter — the review process is made to resolve and apply them, and the guard scripts that stood in for them are removed.

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

**Make review criteria declared data rather than code**, and make the review process resolve and
apply them. Then delete the scripts that were standing in for them.

Criteria resolve through three levels, each written once at the highest level where it is true:

- **Global** and **per-document-type** lists in the Knowledge Base — where most criteria live
- **Per-file exceptions** in a file's own frontmatter — only where a file genuinely differs

A criterion says either *"validate this"* or *"never validate this, and here is why"*, and
`severity:` says what each validatable defect kind costs. Together they replace a growing pile of
guard scripts — each of which encoded one fact-check in code, and could be wrong about it — with a
statement of what to check, applied by something that can read.

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

1. **It is scoped to one tree.** It lives under `kb-authoring/`, so it governs `.aid/knowledge/`
   docs and nothing else — **22 of 315** in-scope files. A skill, an agent or a template is never
   reached by it.
2. **It has no rule ID.** A reviewer cannot cite "item 3 of the KB authoring rubric" in a ledger's
   `Rule` column, so a finding derived from it has nowhere to come from. It was cited **once** in
   `work-003`'s 47 findings (see `prior-art.md § 3`).
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
per C-4, `INDEX.md` and `relationships.md` per C-5, and the two `kb-category: meta` docs `README.md`
and `external-sources.md`. AC-1 nets them out; the survey above counts them because they are markdown
files in the tree.)*

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

   **The largest single piece is new: the KB's criteria documents.** Levels 1 and 2 of FR-5/FR-6 do
   not exist anywhere yet — the global criteria list, the per-document-type criteria lists, and the
   per-type severity maps all have to be authored into `.aid/knowledge/`. Most of the value lands
   here, not in the 290 files: a criterion written once at type level covers every file of that type
   and keeps their frontmatter empty.

   | Surface | Lines | What it must gain |
   |---|---|---|
   | **`.aid/knowledge/` — new criteria documents** | — | **level 1** (global criteria + exclusions) and **level 2** (per-document-type criteria, exclusions, and severity maps). The document-type list itself must be enumerated, and every in-scope file must resolve to exactly one type. |
   | `canonical/aid/templates/kb-authoring/review-rubric.md` | 304 | its contracts check (item 3) generalized beyond `.aid/knowledge/`, taught to resolve the three levels, and given a citable rule ID |
   | `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | — | `contracts` defined for all four trees rather than KB docs alone, carrying **positive criteria and exclusions**; plus `severity:` as a defect-kind → level map |
   | `canonical/aid/templates/grading-rubric.md` | 83 | level 2 of FR-6's severity cascade |
   | `canonical/agents/aid-reviewer/AGENT.md` | — | the instruction to read the artifact's own frontmatter |
   | `canonical/aid/templates/reviewer-dispatch.md` | 311 | the declaration reaching the dispatched reviewer |
   | `canonical/aid/templates/reviewer-ledger-schema.md` | 221 | the new rule ID citable in the `Rule` column |
   | 6 × `canonical/skills/*/references/reviewer-brief.md` | — | the per-skill briefs naming it |
   | `canonical/skills/aid-execute/references/state-fix.md` | 121 | F1–F6 gaining post-edit re-verification |

   *There is no `review-rubrics/` catalog and no `reviewer-brief-template.md` on this branch —
   both are `work-003` additions. An earlier draft named them as targets.*
2. **Populate and correct the per-file exceptions second** — walk the in-scope files, confirm each
   resolves to a declared type, and add a `contracts:`/`severity:` block **only where the file has
   criteria or exclusions its type does not already cover**. Correct the 9 KB docs at
   `contracts: []` and verify the 10 that already declare. Most files will need nothing, and that is
   the intended outcome, not an omission.
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
  was wrong: both are linked from `examples/README.md` as directory links — `](greenfield/)` — and
  named in the KB's repository-structure doc. The audit behind that claim only looked for
  `](README.md)`, so directory-style links were invisible to it. They are referenced, they are
  user-facing, and they belong here rather than in FR-7's delete set.)*

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

*(partial — field set settled at FR-5, severity settled at FR-6; the remaining gap is the scope
boundary in section 4.)*

- **FR-1** **Every in-scope authored markdown file is covered by a complete set of criteria** —
  resolved across the three levels of FR-5, not necessarily written in the file.

  A file carries a `contracts:` block **only where it has criteria or exclusions of its own.** A file
  fully covered by its global and type-level criteria correctly declares nothing, and that is a
  passing state, not a gap. Coverage is a property of the cascade; a per-file block is the exception.
- **FR-2** The reviewer reads that declaration as a normal part of every review — not as an
  instruction that exists and goes unread.

  *Corrected scope.* An earlier draft framed this as switching on an existing rule. The check
  exists but is **scoped to `.aid/knowledge/` and carries no ID**, so this requirement is to
  **generalize and name it**: lift `kb-authoring/review-rubric.md` item 3 out of KB-only scope,
  give it a citable rule ID for the ledger's `Rule` column, and instruct `aid-reviewer/AGENT.md`
  and the six per-skill briefs to read the artifact's frontmatter.
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

  `contracts:` holds **the list of criteria a reviewer validates this file against** — not a
  restatement of what the file says, and not a per-fact assertion list.

  | Level | Holds | Lives in |
  |---|---|---|
  | 1 — **Global** | criteria every document in the project is validated against | the project's KB |
  | 2 — **Document type** | criteria for that class of document (KB doc, skill, skill reference, agent, template) | the project's KB |
  | 3 — **This document** | only what is unique to this file | the file's own `contracts:` |

  A reviewer resolves all three and validates against the **union**. Most specific wins on conflict.

  **The three levels exist to stop duplication, not to add structure.** Their purpose is that a
  criterion is stated exactly once, so it cannot be copied into many files and drift apart, and so
  no single file's frontmatter inflates. The operating rules follow directly:

  - A file's `contracts:` **never restates** a global or type-level criterion.
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

  The field is **`severity:`**, and it is a **map from defect kind to level**, not one value for the
  file — with the reason recorded inline so it can be argued with:

  ```yaml
  severity:
    contract-violation: HIGH    # this doc is load-bearing; a false claim misroutes an agent
    stale-count: LOW
  ```

  | Level | Holds | Lives in |
  |---|---|---|
  | 1 — **Global** | what each severity *means* | the universal scale, shipped |
  | 2 — **Document type** | what each defect kind costs in that class of document | the project's KB, beside the type's criteria |
  | 3 — **This document** | overrides only where this file genuinely differs | the file's own `severity:` |

  Same anti-duplication rule as FR-5: declared once, at the highest level where it is true. Level 3
  is an **override, not a requirement** — which is what keeps every in-scope file from needing a
  severity block.

  **`severity:` covers only what IS validated.** If something must *never* be validated, that is an
  **exclusion in `contracts:`** (FR-5), not a severity. There is no such thing as an exclusion
  expressed as a severity of zero, and an excluded defect kind never appears in this map at all.

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
  five-row Minor/Low/Medium/High/Critical table. Who actually cites it, derived on this branch:
  **5 of the 6** per-skill `reviewer-brief.md` files (`define`, `detail`, `execute`, `plan`,
  `specify` — not `discover`). `grade.sh` cites no path, only "the universal AID rubric" in a
  comment; `aid-reviewer/AGENT.md` and `reviewer-ledger-schema.md` do not cite it at all.

  **There are already three severity homes, not one.** `grading-rubric.md § Issue Severities`,
  `reviewer-ledger-schema.md § Severity values`, and `aid-reviewer/AGENT.md § Severity
  Classification` each define all five severities independently, in different words, and neither of
  the latter two cites the first. Extending `grading-rubric.md` alone would leave the two surfaces a
  reviewer actually reads unchanged. **Reconciling the three is in scope for feature-001** — this is
  a correction to an earlier draft that assumed a single home and warned only against creating a
  second.

  *Open cost, carried forward:* a level-3 override is a per-file bar, so it is a place a gate can
  be quietly lowered. It needs the same treatment as `minimum_grade` — surfaced in the gate output
  — for the same reason: an audit trail without a history mechanism.
- **FR-7** **Delete the 20 internal `README.md` files** under `canonical/skills/` (11) and
  `canonical/agents/` (9) — 1,802 lines. *(Owner decision, 2026-08-12: they are issue-prone surface
  that adds no value.)*

  Evidence for the decision:

  | Fact | Value |
  |---|---|
  | Lines removed | 1,802 |
  | Skills that even have one | **11 of 76** — not a convention, 11 exceptions |
  | How many reach an adopter | **zero.** No README under any `profiles/*/skills/` or `profiles/*/agents/`, none in either tracked dogfood tree. Rendered agents are flat files (`aid-reviewer.md`), not folders. |
  | With zero inbound references | **18 of 20** |
  | Precedent | *(withdrawn — an earlier draft cited `aid-graph/README.md` as "already declined as a documentation surface". No on-disk record of that decision exists on this branch, so the row asserted something unverifiable inside a table of verified facts.)* |

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
  2. **`canonical/skills/aid-monitor/README.md`** — `test-deploy-monitor-repurpose.sh` → the `DMR00c` assertion
     asserts `DMR00c aid-monitor/README.md exists`. The assertion is removed with the file.

  *Why this belongs in a work about declared criteria:* every deleted file is one fewer surface that
  can drift, and it is the inverse of adding a mechanism — **C-1** applied in the direction that
  shrinks the reviewed surface instead of growing it.
- **FR-8** **The front face is brought into line with the changed trees, at the very end** —
  `docs/*.md` (7), the repo-root `README.md` (257 lines) and `examples/**/README.md` (4 files, 1,237
  lines). Deferred by owner decision because these describe trees that are still moving until stream
  3 closes; scheduled alongside the single render of NFR-4 for the same reason. Added because the
  deferred bucket was previously gated by feature-003 with no requirement behind it.

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

   *Why a whole worktree rather than a single scratch file:* a `contracts:` assertion is derived
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
   contradicting its own `contracts:` line* — exactly what this work builds the reviewer to report
   as a violation. A forgotten plant of this class is flagged by the very next review. Unlike a
   planted bug in code, which is silent, this one trips the detector being installed: **the proof's
   subject matter is its own alarm.**

### NFR-2 — The work must end with less enforcement surface than it started

`work-003` failed because every fix grew the reviewed surface. This work is only successful if the
opposite is measurable: **lines of prose-fact guard removed must exceed lines of new mechanism
added.** Stated as a number, not a sentiment.

**Both sides of the subtraction must be defined, or the criterion is unfalsifiable.** An earlier
draft gave only a floor and never said what counts as "added".

| side | definition |
|---|---|
| **removed** | two kinds, counted and reported **separately**: *guard lines* (script logic whose job is checking a fact stated in prose) and *documentation lines* (the 20 READMEs). Confirmed floor: **379** guard + **1,802** documentation = 2,181. Reporting them merged would let deleted prose pay for added machinery. |
| **added** | lines of **mechanism** — new scripts, checks, validators, or process rules an agent must follow. **A `contracts:` block authored into a file is not mechanism**; it is the file stating a fact about itself, which is the whole point. Roughly 290 files gain such a block and none of it counts against this budget. |

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

No `contracts:` entry may assert something requiring a network call, a paid service, a private
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
- **C-5** `source: generated` means build-verify only. `INDEX.md` and `relationships.md` are a
  special kb-category, meta to the KB, and do not follow the other docs' rules.
- **C-6** A new assertion is not trusted until it has been shown to fail against a planted defect.

## 8. Assumptions & Dependencies

### `work-003` is a source to draw from on demand, never a branch to merge

`work-003` sits **131 commits ahead of `master`** and unpushed. Against review-related files under
`canonical/`, it **modifies 26** that exist here and **adds 17** that do not — the whole
`review-rubrics/` catalog and `reviewer-brief-template.md` among them.

> **These three figures are measurements of another branch and cannot be re-derived here**, which is
> what C-7 gate 3 forbids. They are admitted as **the first entries in
> `imports-from-work-003.md`** — serving `§8` itself, derived by `git diff --name-status
> master...work-003`, carrying no mechanism, and logged per gate 6. They are recorded as *known
> collision surface*, not relied on for any design decision: every stream-1 target was independently
> derived from this branch in §4.

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
6. **Logged.** One line in `imports-from-work-003.md`: what came across, which requirement it
   serves, and where it was re-derived from. Contamination that is invisible cannot be undone.

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
  `contracts:` block **only where the file has something of its own**. A file that declares nothing
  and is fully covered by its type passes. An earlier draft demanded a declaration in every file;
  that would have forced the duplication the cascade exists to prevent (FR-5).

  Checkable as three things:
  1. Every in-scope file **resolves to exactly one document type**, and no file is left untyped.
  2. Every type's criteria list exists and is non-empty in the KB.
  3. Where a file *does* carry `contracts:`, no entry restates a global or type-level criterion, and
     every entry — positive or exclusion — is derivable from the repo.

  **The population below is the survey, not a quota.** An earlier draft wrote "179 + 126 + 9",
  which triple-counts: the 9 `contracts: []` KB docs sit *inside* the 126, and the 179 still included
  the 20 READMEs FR-7 deletes first.

  | step | count |
  |---|---|
  | surveyed in scope | 315 |
  | − 20 internal READMEs, deleted first by FR-7 | 295 |
  | − 5 KB files carved out: `STATE.md` (C-4), `INDEX.md` + `relationships.md` (C-5, build-verify), `README.md` + `external-sources.md` (`kb-category: meta`) | **290** |

  Of those 290: **159** have no frontmatter block at all, **126** have a block that declares nothing
  (the 9 at `contracts: []` among them), and **10** already declare — 9 KB docs plus
  `reviewer-ledger-schema.md` — and must be **verified, not assumed**, since a stale existing
  declaration is the worst case of all.

  **How many of the 290 end up carrying a block is an output, not a target.** Under the cascade most
  will not, because their type's criteria already cover them, and a file gains frontmatter only where
  it has a genuine exception. This also removes the earlier premise problem: a generated `SKILL.md`
  or a template whose frontmatter slot is occupied needs no per-file block at all, provided its
  **type** is declared in the KB.
- **AC-2** **The reviewer demonstrably reads the declaration in a real review.** Evidenced, not
  asserted: an instruction that exists and goes unread is the exact failure being fixed, and
  `kb-authoring/review-rubric.md` item 3 proves an unread check can sit in the rubric for a whole
  delivery — cited once in 47 findings.

  **Method — planted-defect proof, once per stream, under NFR-1.** In a disposable worktree, put a
  claim in a file's body that contradicts its own `contracts:` line, run a real review, and confirm
  the finding comes back citing that contract. This is **C-6** applied to this work's own output, it
  reuses an existing convention, and it adds no maintained test.

  *Not the method:* counting how often contract-derived rules get cited across later reviews. That
  is a stronger long-run signal but needs several reviews to accumulate, so it cannot gate the work.
  Recorded as a follow-up measurement against the `1-in-47` baseline, not as an acceptance gate.
- **AC-3** The superseded prose-fact scripts are gone, and their removal loses no check the
  declarations do not cover. Each removed check is named, with the declaration that replaces it.

  **Stream 3 derives the removal set from this branch before removing anything** — the inventory is
  an output of the work, not an input. `kb-citation-lint.sh` is a named non-candidate: it checks
  citation form rather than a prose fact, and CI invokes it.
- **AC-4** **Net enforcement surface is down**, per NFR-2 — removed guard lines exceed added
  mechanism lines, stated as a number. Confirmed floor: **2,181** (1,802 READMEs + 379
  `check-skill-counts.mjs`).
- **AC-5** The 20 internal READMEs are deleted, with the `aid-clerk` caller contract relocated to
  `AGENT.md` and the `aid-monitor` test assertion removed alongside its file (FR-7).
- **AC-6** Nothing from `work-003` crossed into this work except through the six C-7 gates, each
  logged in `imports-from-work-003.md`.

## 10. Priority

**Now.** The review process is the load-bearing part of the methodology, and it is currently
ineffective in a measured way — `work-003` could not close its own gate. Nothing else should
proceed through review while review itself is broken.

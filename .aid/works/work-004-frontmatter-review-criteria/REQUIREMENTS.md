# Requirements

- **Name:** Declared Review Criteria
- **Description:** Every authored markdown file declares in its own frontmatter what it must be validated against, the review process is made to read that declaration, and the guard scripts that stood in for it are removed.

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

Make every authored markdown file in AID declare, in its own frontmatter, what it must be
validated against — and make the review process actually read that declaration. Then delete the
scripts that were standing in for it.

The declaration replaces a growing pile of per-fact guard scripts with a per-file statement of
truth, checked by an agent that can read. The point is to stop the review process from growing
the surface it reviews every time it fixes something.

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

**Why the existing remedy did not fire.** The rule that would have caught most of the 47 already
exists — `KB-22`: *"for each entry in `contracts:`, derive the asserted fact from disk and
compare; mismatch = HIGH."* It was cited **once** in 47 findings, because the mechanism it depends
on is almost entirely unpopulated and instructed nowhere:

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

- **179 files carry no frontmatter at all** — including every one of the 110
  `skills/*/references/*.md` (the procedure bodies agents actually execute) and 49 of the 78
  `canonical/aid/templates/*.md` (among them every `review-rubrics/` file,
  `reviewer-ledger-schema.md` and `grading-rubric.md` — the rubric catalog cannot declare what it
  must be true against).
- **126 files carry frontmatter that declares nothing** — all 76 `SKILL.md`
  (`name`/`description`/`allowed-tools`/`argument-hint`), all 9 `AGENT.md`
  (`name`/`description`/`tier`/`tools`), 28 templates and 13 KB docs.
- **9 of 22 KB docs carry an explicitly empty `contracts: []`** — `architecture.md`,
  `decisions.md`, `domain-glossary.md`, `external-sources.md`, `integration-map.md`,
  `pipeline-contracts.md`, `project-structure.md`, `tech-debt.md`, `technology-stack.md`.

*(An earlier draft of this section cited 341 / 139 / 202 / 88. Those were measured in
`work-003`'s worktree, which carries files `master` does not, and were corrected here rather than
carried forward — a requirements document that states a figure no one can derive from this branch
is the defect this work exists to remove.)*

No surface instructs an agent to read it. `aid-reviewer/AGENT.md` mentions frontmatter once —
forbidding it in its own ledger. `state-fix.md` F1–F6 mentions it once, inside F2's impact chain,
not as post-edit re-verification. Rendered reviewer briefs mentioned it 0–1 times per cycle. That
last gap produced cycle 17 finding #3 directly: `quality-gates.md`'s body was fixed and its own
`contracts:` block was left contradicting it.

**What stands in its place.** 2,816 lines of script check prose facts instead —
`test-one-grading-backend.sh` (1304), `check-skill-counts.mjs` (426), `test-review-rubrics.sh`
(337), `kb-citation-lint.sh` (279), `derived-values.mjs` (275), `check-derived-values.mjs` (195).
Roughly 1,900 of those lines are contract checks wearing script costumes: each encodes one
fact-check in code and can be wrong about the fact, where a `contracts:` line states the fact and
delegates the checking to something that can read.

## 3. Users & Stakeholders

**AID users.** Everyone adopting the methodology depends on the review process working; that is
what makes this load-bearing rather than internal housekeeping.

The declaration's direct reader is the review agent, which acts on the user's behalf — so a
declaration that is authored but unread fails the user even though every file looks correct.

## 4. Scope

### In Scope

Three streams. **The order is load-bearing.**

1. **Enforce the mechanism first** — `aid-reviewer/AGENT.md`, the reviewer brief template, the
   FIX contract (`aid-execute/references/state-fix.md` F1–F6), and the rubric catalog
   (`canonical/aid/templates/review-rubrics/`). Must land first, or the declarations authored in
   stream 2 are read by nothing.
2. **Populate and correct the declarations second** — the 179 files with no block, the 126 with an
   empty one, the 9 KB docs at `contracts: []`. Add what is missing; correct what is wrong.
3. **Remove the superseded scripts last** — or the only checks currently catching drift are
   deleted before the replacement works. `NF01` in `test-one-grading-backend.sh` goes outright: it
   pins `grade.sh` to commit `7a9df485` and asserts byte-identity, which is a `git diff` frozen
   into a committed test.

Trees confirmed in scope: `canonical/skills/` (both `SKILL.md` and `references/*.md`),
`canonical/agents/`, `canonical/aid/templates/`, `.aid/knowledge/`.

### Out of Scope

- **`site/src/content/docs` (137 files)** — informational content. It needs a different kind of
  validation, decided separately.
- **`tests/canonical/test-dogfood-byte-identity.sh`** — it sha256s the two tracked dogfood trees
  against the render manifest, answering *"was the generator re-run"*. That is a build question,
  not a review question, and no declared contract replaces it. This is the genuine mechanical
  residue and it stays.
- **Code files.** Markdown needs a declared content-verification criterion because it is not
  compiled or executed. Code has build, lint and test as its oracle.
- **The deferred front-face bucket — adjusted at the very end of this work, not dismissed.** These
  are what a user reads, so they describe the trees this work is changing; adjusting them mid-work
  would document a state that is still moving. *(Owner decision, 2026-08-12.)*

  | Files | Count | Lines |
  |---|---|---|
  | `docs/*.md` | 7 | — |
  | repo-root `README.md` | 1 | 257 |
  | `examples/**/README.md` | 4 | 1,237 |

  The `examples/` walkthroughs are near-orphaned — `brownfield-full-path` (448 lines) and
  `greenfield` (370 lines) have **zero** inbound references — but they are user-facing walkthroughs,
  so they belong here rather than in FR-7's delete set.

- **READMEs that ship to adopters** — `profiles/{antigravity,claude-code,codex,copilot-cli,cursor}/README.md`
  and `packages/{npm,pypi}/README.md` (7 files). Rendered/published artifacts, not internal surface.

- **READMEs with real consumers** — `.aid/knowledge/README.md` (referenced from 49 files, including
  `kb-freshness-check.sh`, `build-md-export.sh`, `kb-actback-task.sh`, and 56 rows of
  `relationships.md`), `dashboard/README.md`, `tests/README.md`, `tests/ui/README.md`,
  `dashboard/server/tests/fixtures/README.md`.

- **Test-fixture READMEs** — `tests/canonical/fixtures/kb-essence/relative-bus/README.md` and
  `dashboard/server/tests/fixtures/pt1h-repo-a/.aid/knowledge/README.md`. Zero textual references,
  but they are fixture *data* scanned by tests. Never touched.

## 5. Functional Requirements

*(partial — field set settled at FR-5, severity settled at FR-6; the remaining gap is the scope
boundary in section 4.)*

- **FR-1** Every in-scope authored markdown file carries a frontmatter declaration of what it must
  be validated against.
- **FR-2** The reviewer reads that declaration as a normal part of every review — not as an
  instruction that exists and goes unread.
- **FR-3** The FIX contract requires re-verifying a file's own declaration after editing that file,
  closing the `quality-gates.md` failure mode.
- **FR-4** The rubric catalog routes to the declaration rather than duplicating its content.
- **FR-5** **One uniform field set for every in-scope tree.** A single `contracts:` field holding
  free-text assertions; the reviewer derives each from disk and compares. A `SKILL.md`, an
  `AGENT.md`, a template and a KB doc all declare the same way — no per-artifact-kind schema, no
  `references:`/`dispatches:` variants.

  *Rationale (owner decision, 2026-08-12).* The field already exists and `KB-22` already reads it,
  so one shape means one instruction in the reviewer instead of four. Four field sets would be four
  schemas to define, lint and keep consistent — exactly the mechanism growth **C-1** exists to
  stop.

  *Known cost, accepted:* a uniform free-text field cannot express a per-tree required minimum, so
  nothing structurally prevents a file from declaring too little. This is the failure the 9
  `contracts: []` KB docs already demonstrate; addressing it is a review-criteria concern under
  stream 1, not a schema concern.
- **FR-6** **Severity resolves through a three-level cascade**, most specific winning
  (owner decision, 2026-08-12):

  | Level | What it declares | Where it lives |
  |---|---|---|
  | 1 | Global severity guidelines — what each severity *means*, for any artifact | central, shared |
  | 2 | File-class severity guidelines — what a violation costs in a class of file (KB doc, skill reference, template, agent) | central, shared; may be sections of the same document as level 1 |
  | 3 | File-specific severity | that file's own frontmatter, beside its `contracts:` |

  A file declaring nothing at level 3 inherits its class; a class declaring nothing inherits the
  global level. Level 3 is an override, not a requirement — which is what keeps all 315 in-scope
  files from each needing a severity block.

  *Rationale.* This is the same Universal → Family → Class shape the rubric catalog already uses
  for criteria, applied to severity. It makes the difference between a stale count and a false
  claim in a routing document expressible, without forcing a per-file declaration everywhere.

  **Placement correction (raised during the interview).** Levels 1 and 2 must live in
  **`canonical/aid/templates/`**, not `.aid/knowledge/`. The KB is AID's own project knowledge and
  does not ship; `canonical/` renders to `profiles/` and installs into every adopter's `.claude/`.
  Severity guidelines that adopters never receive would leave their reviews with no severity
  definitions at all.

  **Level 1 already exists** at `canonical/aid/templates/grading-rubric.md § Issue Severities` —
  the five-row Minor/Low/Medium/High/Critical table, cited by `grade.sh`, `aid-reviewer/AGENT.md`,
  `reviewer-ledger-schema.md` and seven per-skill reviewer briefs. This work **extends** that
  document with level 2 rather than creating a second severity home; a second one would be exactly
  the "two sources of truth for the value that decides the grade" defect `work-003` spent cycles
  removing.

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
  | Precedent | `canonical/skills/aid-graph/README.md` was already declined as a documentation surface |

  Deletion is a **fix**, not only a cleanup: the single instruction-content pointer at one of them
  is already broken. `canonical/skills/aid-execute/references/state-execute.md:166` tells an
  executor *"See `agents/aid-clerk/README.md` for the caller contract"*, and that path exists in no
  installed tree — the line is replicated to all five profiles and both dogfood trees, so seven
  copies of the pointer resolve to nothing.

  **Two files need preparation before deletion, or deletion causes a regression:**

  1. **`canonical/agents/aid-clerk/README.md`** — move the caller contract into
     `aid-clerk/AGENT.md`, which does ship; then correct `state-execute.md:166` and
     `site/src/data/skill-flows/aid-execute.flow.json`. Deleting first would turn a broken pointer
     into a lost contract.
  2. **`canonical/skills/aid-monitor/README.md`** — `tests/canonical/test-deploy-monitor-repurpose.sh:66`
     asserts `DMR00c aid-monitor/README.md exists`. The assertion is removed with the file.

  *Why this belongs in a work about declared criteria:* every deleted file is one fewer surface that
  can drift, and it is the inverse of adding a mechanism — **C-1** applied in the direction that
  shrinks the reviewed surface instead of growing it.

## 6. Non-Functional Requirements

### NFR-1 — A planted defect can never reach the work branch

**C-6** requires proving each new criterion against a planted defect. That creates a real hazard: a
plant that is forgotten becomes a genuine defect. The hazard is removed **structurally**, in three
independent layers — not by a reminder, and not by a new guard.

1. **The plant is never applied to the tracked tree.** It goes into a **disposable git worktree at
   the same commit**, created with the existing
   `.claude/aid/scripts/works/worktree-lifecycle.sh` and destroyed afterwards. The work branch's
   files are never edited, so there is nothing to restore and nothing to forget.

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
opposite is measurable: **lines of prose-fact guard removed must exceed lines of new
mechanism added.** Stated as a number, not a sentiment — the starting figure is 2,816 lines across
six files, plus 1,802 lines in the 20 READMEs of FR-7.

This is **C-1** promoted to a measured exit condition, because "do not over-engineer" was already
stated in `work-003` and did not hold.

### NFR-3 — Stream-1 edits stay additive and localized

A new section, a new instruction paragraph, a new rule row — never a restructure of a file
`work-003` has also restructured. See §8: this keeps a later reconcile cheap and satisfies **C-1**
at the same time.

### NFR-4 — The render chain is refreshed exactly once, at the end

`canonical/` → `profiles/` → the two tracked dogfood trees, per **C-2**. Mid-work staleness in the
derived trees is correct and is not a defect.

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
- **C-4** `STATE.md` is never reviewed, at any level, in any folder.
- **C-5** `source: generated` means build-verify only. `INDEX.md` and `relationships.md` are a
  special kb-category, meta to the KB, and do not follow the other docs' rules.
- **C-6** A new assertion is not trusted until it has been shown to fail against a planted defect.

## 8. Assumptions & Dependencies

### `work-003` is a source to draw from on demand, never a branch to merge

`work-003` sits **131 commits ahead of `master`**, unpushed, and has rewritten **all 22 files
stream 1 must edit**:

```
canonical/agents/aid-reviewer/AGENT.md          canonical/aid/templates/reviewer-brief-template.md
canonical/agents/aid-reviewer/README.md         canonical/aid/templates/reviewer-ledger-schema.md
canonical/aid/templates/grading-rubric.md       canonical/skills/aid-summarize/references/state-fix.md
canonical/aid/templates/review-rubrics/         canonical/skills/{define,detail,discover,execute,
  (10 files: INDEX, aid, definition, executable,   plan,specify}/references/reviewer-brief.md
   interface, kb, narrative, presentation,
   process, summary)
```

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

C-7 keeps `work-003`'s content out. It does **not** stop the two branches editing the same 22 files.
`review-rubrics/INDEX.md` alone was split into four files on `work-003`, so whichever branch merges
second must re-apply its edits onto a restructured catalog.

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

- **AC-1** Every in-scope authored markdown file declares what it must be validated against — the
  179 files with no frontmatter, the 126 declaring nothing, and the 9 KB docs at `contracts: []`.
- **AC-2** **The reviewer demonstrably reads the declaration in a real review.** Evidenced, not
  asserted: an instruction that exists and goes unread is the exact failure being fixed, and
  `KB-22` proves an unread rule can sit in the catalog for a whole delivery.

  **Method — planted-defect proof, once per stream, under NFR-1.** In a disposable worktree, put a
  claim in a file's body that contradicts its own `contracts:` line, run a real review, and confirm
  the finding comes back citing that contract. This is **C-6** applied to this work's own output, it
  reuses an existing convention, and it adds no maintained test.

  *Not the method:* counting how often contract-derived rules get cited across later reviews. That
  is a stronger long-run signal but needs several reviews to accumulate, so it cannot gate the work.
  Recorded as a follow-up measurement against the `1-in-47` baseline, not as an acceptance gate.
- **AC-3** The superseded prose-fact scripts are gone, and their removal loses no check the
  declarations do not cover. Each removed check is named, with the declaration that replaces it.
- **AC-4** **Net enforcement surface is down**, per NFR-2 — removed guard lines exceed added
  mechanism lines, stated as a number.
- **AC-5** The 20 internal READMEs are deleted, with the `aid-clerk` caller contract relocated to
  `AGENT.md` and the `aid-monitor` test assertion removed alongside its file (FR-7).
- **AC-6** Nothing from `work-003` crossed into this work except through the six C-7 gates, each
  logged in `imports-from-work-003.md`.

## 10. Priority

**Now.** The review process is the load-bearing part of the methodology, and it is currently
ineffective in a measured way — `work-003` could not close its own gate. Nothing else should
proceed through review while review itself is broken.

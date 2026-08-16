# Single Review Path Alignment

## Source

- REQUIREMENTS.md §4 Scope — T1 Align
- REQUIREMENTS.md §5 Functional Requirements — FR-A1, FR-A2, FR-A3, FR-A4, FR-A5
- REQUIREMENTS.md §6 Non-Functional Requirements — NFR-1 … NFR-5
- REQUIREMENTS.md §7 Constraints, §8 Assumptions & Dependencies
- REQUIREMENTS.md §9 Acceptance Criteria — AC-1, AC-2, AC-5, AC-6, AC-8, AC-11, AC-12
- REQUIREMENTS.md §10 Priority — item 1

## Description

AID already has a working review stack: criteria that cascade from global to type to
file, a 7-column findings ledger, scoped VERIFY/HUNT cycles with a cost meter, and a
single `/aid-review` skill paired with a single `aid-reviewer` agent. A canceled
redesign built a rival to each of those pieces. Those rivals are not in this branch,
but they remain reachable — through an open pull request, and through prose in the
shipped docs that still describes the rival shape.

This feature makes the existing stack the only review system, and proves it rather than
asserting it. Three things happen. Any pull request that would land a rival loader, a
second review skill, or an 8-column ledger is closed or stripped. Every place the
shipped documentation still describes the rival shape is corrected to the law that
actually runs. And the genuinely useful checks that only ever existed inside the
abandoned catalog are lifted out of git history and given a home in the cascade as
declared criteria — the checks come across, the catalog machinery does not.

It closes with an audit, not a claim: a named command whose output shows that every
reference to a review skill, in every dispatch table and every chain target, resolves to
a skill that exists on disk. That output is recorded with the delivery.

This feature goes first because everything the next two measure is measured on this
stack.

## User Stories

- As a pipeline skill, I want exactly one way to dispatch a review, so that a REVIEW state does not have to choose between two review systems that disagree.
- As the reviewer agent, I want criteria to come from the cascade and nowhere else, so that I never have to reconcile a catalog index against a file's own declaration.
- As a maintainer, I want a rival review system to be unable to land through an old pull request, so that the stack I keep rendering into five install profiles stays single.
- As a maintainer, I want the useful checks from the abandoned catalog kept as cascade criteria, so that the work that went into them is not lost with the machinery that carried them.
- As the owner, I want the closing audit to be a command and its output, so that "the stack is single" is something I can re-run rather than something I am told.

## Priority

Must

## Acceptance Criteria

> Each criterion carries the modality of the requirement it discharges. A criterion that
> reads MUST here is MUST because its source requirement is, not by default.

- [ ] **MUST** — Given the aligned stack, when `ls -d canonical/skills/*review*/` and `ls -d canonical/agents/*review*/` are run, then each returns exactly one directory, and the FR-A5 audit command's output shows every review-skill reference, dispatch-table entry and CHAIN target resolving to a skill that exists on disk; both outputs are recorded with the delivery. *(discharges FR-A1, FR-A5; §9 AC-8)*
- [ ] **MUST** — Given the rival redesign pull request, when it is closed or stripped, then it contains no rival loader, no second review skill and no 8-column `Rule` path; and `aid-reviewer` resolves criteria from the cascade only while `/aid-review` and every per-skill brief describe the 7-column ledger, evidenced by the greps and their output. *(discharges FR-A2, FR-A4; §9 AC-1)*
- [ ] **MUST** — Given a check that existed only in the abandoned catalog and is worth keeping, when it is migrated, then it has a cascade `review-criteria:` (or `oracle:`) home cited by id, and no live `review-rubrics/` loader remains. *(discharges FR-A3; §9 AC-6)*
- [ ] **MUST** — Given a real pipeline review dispatch after this feature closes, when the reviewer is dispatched, then a brief file exists on disk and a matching row exists in `review-cost.tsv`. *(discharges NFR-5 parts 2-3; §9 AC-2)*
- [ ] **MUST** — Given a review that reaches cycle 2 or later, when its brief is read, then that brief carries the two labelled `VERIFY` and `HUNT` lists, and the cycle-1 brief carries the single unlabelled list — shown by the cited grep over the brief files on disk. *(discharges NFR-5 part 1, "VERIFY/HUNT remains mandatory", which §9 AC-2 does not reach)*
- [ ] **MUST** — Given a script proposed by this feature, when it is merged, then it cites a measurement of the re-derivation it removes. *(discharges NFR-3; §9 AC-5)*
- [ ] **MUST** — Given this feature's changes, when `grade.sh` and `reviewer-ledger-schema.md` are diffed against the work's base commit, then neither counting logic nor column shape has changed; and `generate-profile` re-renders byte-identically with VERIFY deterministic PASS, with no hand-edit in `profiles/` or the dogfood trees. *(discharges NFR-1, NFR-2; §9 AC-11)*
- [ ] **MUST** — Given any count stated in this feature's artifacts, when the cited command is re-run, then it reproduces the number. *(discharges NFR-4; §9 AC-12)*

---

## Technical Specification

> **How to read the counts.** NFR-4 requires every stated count to carry the command that
> produced it. Every figure below is followed by its command, run from the worktree root at
> `HEAD` = `2dd1eb0e6`. The abandoned catalog is read from `work-003` at `8b9e62021`.
> **Section shape.** The three core sections of `canonical/aid/templates/specs/spec-template.md`
> are kept and marked `N/A` where they genuinely do not apply, so the schema in
> `.aid/knowledge/artifact-schemas.md § Feature SPEC.md` still resolves; the sections that
> carry the work follow them.

### Data Model

**N/A.** This repository persists no data — it ships markdown skills, agents and templates
rendered into five install trees, plus bash scripts and bash test suites
(`.aid/knowledge/project-structure.md` "Unusual Structure Notes") — and this feature adds no
schema, table or record.

### Feature Flow

**N/A.** No state machine, dispatch sequence or runtime path changes. The dispatch flow this
feature aligns *to* is defined, unchanged, in `canonical/aid/templates/reviewer-dispatch.md`
§ Brief generation ("Render the brief TO A FILE, then dispatch and record from that same file")
— this feature corrects prose in files that flow already reads, and adds one command run once,
at delivery close.

### Layers & Components

**N/A as layering** — there is no application layering here, no DI and no service/repo split.
The equivalent structural statement is § Artifacts & Surfaces below, which names every file
that changes and every tree that must never be hand-edited.

---

### Artifacts & Surfaces

**Authored, in scope to change:**

| Path | Why it changes | Registry type |
|---|---|---|
| `canonical/aid/templates/reviewer-dispatch.md` | FR-A2 — carries the two "rubric catalog" phrases and two `(future)` rubric names that resolve to nothing | `template-payload` (undecided by the `G-07` oracle) |
| `.aid/knowledge/authoring-conventions.md` § Review Criteria — Criteria by Level | FR-A3 — the only home a migrated check can land in | `kb-doc` |
| `scripts/checks/review-path-audit.sh` (new) | FR-A5 — the named audit command | outside the registry corpus |
| `tests/canonical/test-review-path-audit.sh` (new) | AC-3-shaped proof that the audit fires; discovered by glob, so `tests/run-all.sh` needs no edit (`tests/run-all.sh` "Discovers suites by glob") | outside the registry corpus |

**Generated — never hand-edited (NFR-2).** `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/`,
the dogfood trees `.claude/` and `.cursor/`, `packages/**/_vendor/`, and `.aid/knowledge/INDEX.md`.
Editing a rendered copy does nothing and CI `render-drift` fails
(`.aid/knowledge/architecture.md` § Gotchas, "Editing a rendered/vendored copy does nothing").

**One surface is generated in a way that constrains this feature.** `canonical/skills/aid-review/SKILL.md`
is a **hand-authored** skill that is nonetheless a `shortcut-catalog.yml` row, so the type
registry's `skill-generated` selector (`path canonical/skills/*/SKILL.md AND name-in
canonical/aid/templates/shortcut-catalog.yml`) classifies it as generated, and `SK-02` then
forbids it a file-level `review-criteria:` block. The catalog row itself says the opposite —
`canonical/aid/templates/shortcut-catalog.yml` at `- name: aid-review` carries `repurpose: true`
and the comment "HAND-AUTHORED collapse skill … so build-shortcut-skills.py never
generates/overwrites it".

- 34 of the 94 catalogued skills carry the generator's marker; **60 do not** and are therefore
  misclassified as `skill-generated`.
  `grep -rl 'GENERATED by .claude/skills/generate-profile/scripts/build-shortcut-skills.py' canonical/skills/*/SKILL.md | wc -l`
  → `34`; `grep -cE '^  - name: aid-' canonical/aid/templates/shortcut-catalog.yml` → `94`.
- **The defect is latent, not live:** none of those 60 carries a file-level block today, so
  `SK-02` is violated nowhere.
  `while read -r s; do f="canonical/skills/$s/SKILL.md"; [ -f "$f" ] || continue; grep -q 'GENERATED by .claude/skills/generate-profile/scripts/build-shortcut-skills.py' "$f" && continue; grep -q '^review-criteria:' "$f" && echo "$f"; done < <(grep -oE '^  - name: aid-[a-z0-9-]+' canonical/aid/templates/shortcut-catalog.yml | sed 's/^  - name: //') | wc -l`
  → `0`.
- **Consequence for this feature:** the FR-A2 fix must be reachable **without** a file-level
  block on `aid-review/SKILL.md`. It is — the drift is in `reviewer-dispatch.md`, not in
  `aid-review/SKILL.md` (§ Doc-Law Alignment). If a task later needs a file-level criterion
  there, correcting the registry becomes a **blocking prerequisite**, and correcting it means
  moving the `Selector` and `Match` cells together (`authoring-conventions.md`: "`Selector` and
  `Match` are one unit") and re-running the `G-07` oracle to diff the classification. That
  correction is **not** in this feature's scope — see § Routed Findings.

---

### Doc-Law Alignment (FR-A2)

The rival shape survives in shipped prose in exactly one place, and the rival shape is
**absent** everywhere else. Measured:

> **Command convention.** Commands are written **pipe-free wherever possible** (`grep -e` in place
> of `|` alternation) so they can be copied out of a markdown table and run verbatim. Where a
> command genuinely needs a shell pipeline, it is shown in a fenced block instead of a cell — a
> markdown-escaped `\|` inside a cell is not the pipe a shell reads, and pasting one would report
> a different number than the one being cited.

| What FR-A2 names | Command | Result |
|---|---|---|
| 8-column / `Rule`-column ledger prose | `grep -rniE -e 8-column -e 8-col -e eight-column -e 'eighth column' canonical tests scripts docs site/src .aid/knowledge` | 1 hit, and it is the **negation** — `reviewer-ledger-schema.md` § Citing the criterion, "No eighth column: the shape stays 7 columns" |
| a `Rule` column in the review stack | `grep -rnF -e '{PIPE} Rule {PIPE}' canonical tests scripts .aid/knowledge` (substituting a literal pipe for each `{PIPE}`) | 13 lines, **none in a ledger context** — unrelated tables in `backlog` mapping, `design-lifecycle`, `test-landscape`, `principles`, `architecture`. Filter shown below |
| catalog routing prose | `grep -rn 'rubric catalog' canonical tests scripts docs .aid/knowledge` | **2 hits, both in `canonical/aid/templates/reviewer-dispatch.md`** — the brief skeleton line `RUBRIC: <named rubric from a rubric catalog>` and § RUBRIC's "A **named rubric** drawn from a rubric catalog." |
| a live `review-rubrics/` loader | `grep -rn 'review-rubrics' canonical tests scripts docs .aid/knowledge` | **0** |

The ledger-context filter for row 2, which is the half that matters:

```bash
grep -rnF -e '| Rule |' canonical tests scripts .aid/knowledge | wc -l              # 13
grep -rnF -e '| Rule |' canonical tests scripts .aid/knowledge \
  | grep -icE -e ledger -e severity -e status -e finding                            # 0
```

**So FR-A2 is a two-line correction plus two dead pointers, not a rewrite.** There is no rubric
catalog on this branch: `find canonical -name '*rubric*'` returns three unrelated files
(`grading-rubric.md`, `kb-authoring/review-rubric.md`, `knowledge-summary/grading-rubric.md`).
The two `(future)` names in § RUBRIC — `code-review-rubric.md#standard` and
`spec-review-rubric.md#standard` — resolve to nothing on disk
(`ls canonical/aid/templates/code-review-rubric.md canonical/aid/templates/spec-review-rubric.md`
→ both "No such file").

**The change:** § RUBRIC and the skeleton line say the rubric is drawn from the *named rubric
documents that exist*, and the criteria come from the cascade. The composition rule is already
correct in that same section — "A named rubric does not replace the artifact's declared criteria
— the two compose … so the brief never needs a `Rule` column" — so this edit removes the
catalog framing above it and leaves the law it already states.

**What is already law and must not be re-authored.** These pass today and the feature's job is
to keep them passing, not to change them:

| Claim | Command | Result |
|---|---|---|
| `aid-reviewer` resolves criteria from the cascade only | `grep -n 'Resolve the artifact.s review criteria first' canonical/agents/aid-reviewer/AGENT.md` | present; the section resolves registry type → union of global/type/file, most specific wins |
| every per-skill brief states the 7-column shape | `grep -ciE -e 7-column -e '7 columns' -e 'seven columns' canonical/skills/*/references/reviewer-brief.md` | `2` in each of the 6 briefs |
| `/aid-review` states it | `grep -ciE -e 7-column -e '7 columns' -e 'seven columns' canonical/skills/aid-review/SKILL.md` | `1` |
| every brief cites the schema | `grep -c reviewer-ledger-schema canonical/skills/*/references/reviewer-brief.md` | `1` in each of the 6 |

> **The exact-string trap, recorded so a later cycle does not re-fall into it.** `grep -c '7-column'`
> alone returns `0` for all six briefs — they say "(7 columns, no new column)" and "Seven columns,
> unchanged". Any AC-1 evidence grep MUST carry all three spellings, as above. A verifier that
> greps the hyphenated form only will report a drift that does not exist.

---

### Migration of Catalog Checks (FR-A3)

#### Recovery

The abandoned catalog is read from git, never checked out:
`git show 8b9e62021:canonical/aid/templates/review-rubrics/INDEX.md` (and the nine sibling class
files). The tree is 10 files
(`git ls-tree -r --name-only work-003 -- canonical/aid/templates/review-rubrics | wc -l` → `10`)
holding **85 rule rows**
(`for f in aid definition executable interface kb narrative presentation process summary; do git show "work-003:canonical/aid/templates/review-rubrics/$f.md"; done | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'`
→ `85`), distributed `KB 16, EXE 13, PRE 11, NAR 11, SUMMARY 9, DEF 9, AID 6, PRO 5, INT 5`
(same pipeline, `| grep -oE '^\| `[A-Z]+-[0-9][0-9]`' | tr -d '|` ' | sed 's/-[0-9][0-9]$//' | sort | uniq -c | sort -rn`).

**Pin the sha, not the branch.** `work-003` is a live ref; cite `8b9e62021`. Closing the rival PR
does not delete the ref, but the migration must land its recovered rows into the criteria table
**before** the PR is closed, so a later ref deletion cannot orphan the source.

#### The screening test — four conditions, all required

FR-A3 says "existed **only** in the abandoned catalog". Read literally that filter is nearly
empty, and it is the wrong filter: the catalog's own admission rule was "**No Criterion, no
row**", so every row cites a document that already exists here. All 85 do
(`awk -F'|' '/^\| `[A-Z]+-[0-9][0-9]` \|/ {c=$4; gsub(/^ +| +$/,"",c); print c}' | grep -cvE '\.(md|sh|py|yml|jsonl|txt)'`
→ `0` rows citing no file). The operative question is therefore **not** "was the text only
there" but "**does the check have a citable home in the cascade today**". A row migrates only
if all four hold:

1. **Uncovered** — no current criterion `id` and no mechanical gate already decides it.
2. **Declared** — the convention it checks is stated in *this* tree. **5 of the 85** cite only the
   catalog's own universal taxonomy and so fail this: their declaring document leaves with the
   catalog, which would make the migration a new convention rather than a migration.
   Command: pipe the nine class files through
   `awk -F'|' '/^\| \`[A-Z]+-[0-9][0-9]\` \|/ {c=$4; if (c ~ /INDEX\.md\` universal taxonomy/) n++} END{print n+0}'`
   → `5`.
3. **Attachable** — true of `*` or of exactly **one existing** registry type. A row needing a
   **new** type is out of scope here; that is the shape `Q3` describes and it belongs to
   feature-002.
4. **Priceable** — carries a severity from `canonical/aid/templates/grading-rubric.md`
   § Issue Severities and a one-line `why`.

#### The id-namespace rule — never reuse a catalog id

The catalog's ids **collide with the current cascade's, meaning different things**. Old `KB-01`
is "frontmatter is the document's first block"; current `KB-01` is "required frontmatter is
present and single-line". Old `KB-03` is "no history apparatus"; current `KB-03` is the
`kb-generated` content exclusion. So a migrated row is issued **a new id in the existing
scope-prefix namespace, at the next free number within that scope**, and the allocation is
recorded in the delivery record. The current namespace is 18 rows —
`G-01…G-08, KB-01…KB-04, SK-01, SK-02, SR-01, AG-01, TO-01, TP-01`
(`awk '/^\| ID \| Applies to/,/^$/' .aid/knowledge/authoring-conventions.md | grep -cE '^\| [A-Z]+-[0-9]{2} \|'`
→ `18`). **No id is allocated in this SPEC**; allocation is task work under this rule.

#### Worked example — the `KB` class, screened row by row

The 16 `KB-*` rows resolve cleanly, and the split is representative:

| Old rows | Screen outcome | Evidence |
|---|---|---|
| old `KB-01`, `KB-02`, `KB-03`, `KB-09` | **covered** by current `KB-02` | that one criterion reads "Exactly one concern per doc, and the layout holds: frontmatter, title, index, content sections, and no history section" |
| old `KB-04` | **covered** by current `KB-01` | "Required frontmatter is present and single-line: `objective`, `summary`, `sources`" |
| old `KB-05`, `KB-06`, `KB-07`, `KB-08` | **uncovered candidates** — `audience:`/`owner:`/`tags:` present; `tags:` carries the concern id; no diagram blocks; junior-clear prose | the criteria-table sweep below returns **0**, so no criterion covers any of them |
| old `KB-20`…`KB-26` (7 rows) | **covered, by the rubric not by an id** — each cites `kb-authoring/review-rubric.md` as its own authority | the second command below returns **7** |

```bash
# no declared criterion mentions diagrams, tags, junior-clarity or plain prose  -> 0
awk '/^. ID . Applies to/,/^$/' .aid/knowledge/authoring-conventions.md \
  | grep -icE -e diagram -e tags -e junior -e plain

# all seven KB-20..26 rows cite review-rubric.md as their own authority        -> 7
git show work-003:canonical/aid/templates/review-rubrics/kb.md \
  | grep -cE '^. `KB-2[0-6]`.*review-rubric\.md'
```

All four uncovered candidates are conventions **already stated** in
`.aid/knowledge/authoring-conventions.md` (§ Frontmatter Rules for the fields and the concern
id; § Dual-Audience Standard for the no-diagram and junior-clear rules). That is exactly the
failure `G-08`'s own `why` names — *"the rule to delete them existed with no id, so a reviewer
that found one could not cite it … a rule nobody can cite is not enforced"*. Closing that
citability gap is what FR-A3 is worth.

#### A second uncovered case, found while reading the stack

`canonical/agents/aid-reviewer/AGENT.md` § Standing KB-Convention Checks opens "Per KB doc
`content-isolation.md`". That doc does not exist
(`ls .aid/knowledge/content-isolation.md` → "No such file"; the content is
`authoring-conventions.md` § Content Isolation), and it is the file's only reference to it
(`grep -rn 'content-isolation\.md' canonical .aid/knowledge --include=*.md` → 1 hit).
**No declared criterion reaches it:** `SR-01` ("Every instruction-content pointer resolves to a
path that exists in an installed tree") applies to `skill-reference, template-own`, and this
file's type is `agent`; `AG-01` covers only a referenced **agent** resolving. The abandoned
catalog covered it universally as taxonomy class 5, *Stale reference*. It therefore satisfies all
four screening conditions and is the strongest single migration candidate. Correcting the cite
itself is in FR-A2's reach ("`aid-reviewer` … docs match law"); giving the *class* a citable id
is FR-A3's.

#### Cascade entry vs `oracle:` — and a prerequisite

FR-A3 allows `oracle:` "where mechanical". **The criteria table cannot express one today.** Its
header is six columns with no oracle cell
(`grep -n '^| ID | Applies to' .aid/knowledge/authoring-conventions.md` → `| ID | Applies to |
Kind | Criterion | Severity | Why |`), even though the section's own prose promises "the same
fields as the frontmatter object (`id`, `kind`, `criterion`, `severity`, `why`, and the optional
`oracle`)". The consequence is visible: `scripts/checks/g07-selector-partition.sh` exists, is
tested, and exits `0` with 76 `UNDECIDED` lines and no `VIOLATION`
(`bash scripts/checks/g07-selector-partition.sh | grep -c UNDECIDED` → `76`, stable across three
runs) — yet it is named as `G-07`'s oracle **nowhere in the table**.
`grep -rn 'g07-selector-partition' canonical tests .aid/knowledge` returns 4 hits (the schema's
worked example, two test-suite lines, and a `tech-debt.md` proposal), and
`awk '/^| ID | Applies to/,/^$/' .aid/knowledge/authoring-conventions.md | grep -c 'g07-selector-partition'`
returns **0**.

**Decision.** Any migrated check lands as a **table row** (a `review-criteria:` cascade entry).
Adding an `Oracle` column is a prerequisite for the `oracle:` half and is deferred: it is a
change to the criteria table's shape, and while `NFR-1` does not forbid it (that constraint
binds `grade.sh` counting logic and the **ledger** column shape, neither of which is this
table), it is a table-shape change the `G-07` oracle parses adjacent to. If no screened row is
mechanically decidable, the `oracle:` half of FR-A3 is discharged as *not applicable*, stated
rather than silently skipped.

---

### PR Hygiene (FR-A4)

**The rival is PR #185**, `work-003` → `master`, "work-003: rebuild the review subsystem —
severity becomes judgment, scripts become tooling", state OPEN
(`gh pr list --state open --json number,title,headRefName,baseRefName`).

**What it would land.** 1066 files
(`git diff --name-only master...work-003 | wc -l`, measured against `master` = `origin/master` =
`aef150fe8`; the retracted stale ref `9528462e0` reported `1168`), of which
**13 are canonical rival paths**
(`git diff --name-only --diff-filter=A master...work-003 | grep -E '^canonical/' | grep -cE 'review-rubrics|aid-deep-review|aid-light-review|aid-screener'` → `13`):

- `canonical/aid/templates/review-rubrics/` — 10 files (the catalog-as-loader)
- `canonical/skills/aid-deep-review/SKILL.md`, `canonical/skills/aid-light-review/SKILL.md` —
  taking `canonical/skills/*review*/` from 1 to 3, which `FR-A1` forbids outright
- `canonical/agents/aid-screener/AGENT.md` — the agent §4 Out of Scope names by name

**"Closed" is the recommendation; "stripped" is not viable.** Three measured reasons:

1. The branch is **internally contradictory at its own tip**. Its ledger schema is 7-column and
   says "No eighth column" (`git show work-003:canonical/aid/templates/reviewer-ledger-schema.md | grep -c '| Rule |'`
   → `0`), while its catalog still instructs "This value goes in the ledger's `Rule` column"
   (`git show work-003:canonical/aid/templates/review-rubrics/INDEX.md | grep -c 'Rule` column'`
   → `3`). Stripping means resolving a 1066-file diff whose central contract disagrees with
   itself.
2. Its remaining content is a **superseded design**, and its useful part is being taken by
   § Migration of Catalog Checks — from history, without the machinery.
3. Closing does **not** delete the head ref, so `git show 8b9e62021:…` stays available for the
   migration.

**Concretely, "closed or stripped" means all three of:** (a) `gh pr view 185 --json state` reports
`CLOSED`; (b) the `work-003` ref still resolves, so the migration source survives —
`git rev-parse work-003` → `8b9e62021`; (c) the audit's L1/L2 layers pass on this tree, so a
later merge of the same content is caught rather than assumed away. This is an **owner/operator
action**, not an agent one — no task in this feature performs a PR write.

---

### The Closing Audit (FR-A5)

**Command:** `bash scripts/checks/review-path-audit.sh`. Repo-root-relative, outside `canonical/`
(the placement the oracle contract already uses for `scripts/checks/`), bash + awk only,
`LC_ALL=C`, deterministic — no network, no clock — and carrying the header block
`.aid/knowledge/coding-standards.md` § File Header Convention requires.

**Four layers, each answering a different way the stack could stop being single:**

| Layer | Asserts | Exit contribution |
|---|---|---|
| **L1 Singleton** | `canonical/skills/*review*/` is exactly 1 dir and `canonical/agents/*review*/` exactly 1 — AC-8's two `ls` commands, run inside the audit rather than beside it | fails on ≠ 1 |
| **L2 Lexicon** | no skill or agent directory name matches the review-family lexicon — `review`, `reviewer`, `screener`, `critique`, `audit`, `inspect`, `verif`, `grade`, `rubric` — outside the sanctioned pair `aid-review` / `aid-reviewer` | fails on any extra |
| **L3 Slash refs** | every `/aid-<name>` reference in `canonical/**/*.md` that is review-family resolves to a directory under `canonical/skills/` | fails on a review-family dangling ref; a non-review dangling ref is a `NOTE`, not a failure |
| **L4 Agent refs** | `aid-reviewer` resolves under `canonical/agents/`, and every agent named in the corpus resolves | fails if the reviewer agent is absent |

**Expected output on this tree.** The script does not exist yet — it is the `(new)` row in
§ Artifacts & Surfaces, and this feature's task is to write it. The block below is therefore the
**specified** output, not a transcript: each line was produced by running that layer's component
greps directly at `HEAD`, and the finished script must reproduce it exactly on an unchanged tree.

```
L1 SINGLETON   review-skill-dirs=1 (expect 1)  reviewer-agent-dirs=1 (expect 1)
L2 LEXICON     review-family names outside {aid-review, aid-reviewer}=0 (expect 0)
L3 SLASH-REFS  distinct=91  review-family=1  dangling(review-family)=0 (expect 0)  dangling(other)=1
L4 AGENT-REFS  named-and-resolving=9  reviewer-agent-present=yes
NOTE /aid-graph names no skill under canonical/skills/ (not review-family)
RESULT PASS
```

**Why it cannot pass vacuously.** Four independent guards, and the first two are the ones that
matter — a grep that matches nothing is the classic silent pass:

1. **`distinct=0` is a VIOLATION, not a pass.** If the extraction yields no references, the audit
   fails and says so.
2. **`review-family=0` is a VIOLATION.** If it extracts references but none is review-family, the
   audit is measuring the wrong corpus and fails.
3. **Every layer prints its expectation next to its measurement**, so a reader sees `expect 1`
   beside `=1` rather than a bare `PASS`.
4. **The failure path is demonstrated, read-only, against `work-003` — no tree mutation:**

```
$ git ls-tree -d --name-only work-003 -- canonical/skills/ | grep -c review   →  3
$ git ls-tree -d --name-only work-003 -- canonical/agents/ | grep -c review   →  1
L1 review-skill-dirs=3 (expect 1) reviewer-agent-dirs=1 (expect 1)  ->  FAIL
L2 unsanctioned review-family names:
   VIOLATION unsanctioned aid-screener
```

> **This answers `Q7` with evidence.** `Q7` (Pending, the owner's to settle) says AC-8's
> `*review*` glob is evadable by naming. The run above **demonstrates** it: on `work-003` the
> agents half of the glob returns `1` and passes, while `aid-screener` — the agent §4 Out of Scope
> names — is sitting right there. L2 is what catches it. This SPEC therefore designs the audit so
> that it *is* the real guard, which is `Q7`'s own suggestion; it does **not** re-word AC-8, which
> remains the owner's call.

**NFR-3 / AC-5 — the measured re-derivation this script removes.** The audit is four greps whose
correct form is not obvious, and the naive form is wrong most of the time. Both forms, run at
`HEAD`:

```bash
# NAIVE -- reports 7 dangling: aid-architect aid-clerk aid-command aid-create-
#                              aid-design- aid-graph aid-reviewer
grep -rhoE '/aid-[a-z0-9-]+' canonical --include=*.md \
  | sed 's|^/||' | sort -u \
  | while read -r s; do [ -d "canonical/skills/$s" ] || echo "$s"; done

# GUARDED (the script's form) -- reports 1 dangling: aid-graph
grep -rhoE '(^|[^A-Za-z0-9/._{-])/aid-[a-z0-9]+(-[a-z0-9]+)*' canonical --include=*.md \
  | grep -oE '/aid-[a-z0-9-]+' | sed 's|^/||' | sort -u \
  | while read -r s; do [ -d "canonical/skills/$s" ] || echo "$s"; done
```

**6 of 7 are false positives**, in two distinct classes: a path prefix (`canonical/agents/aid-architect/`
read as `/aid-architect`) and a template placeholder (`{/aid-command}` in
`canonical/aid/templates/knowledge-summary/section-templates/bespoke-components.md`). Re-deriving
the two guards at every closing audit is what the script removes, and the figure is reproducible
by running both commands. This is the "or equivalent command cited" form NFR-3 allows — the cost
meter measures a dispatch brief's declared read surface, which is not what a check script costs.

**Not an `oracle:`.** The oracle contract is a **per-file** `VIOLATION`/`UNDECIDED` verdict
(`canonical/aid/templates/kb-authoring/frontmatter-schema.md § oracle:`); this audit's subject is
the corpus, so it is a standalone check. Promoting it would need a criterion `id` the owner
allocates **and** the `Oracle` column that does not exist yet (§ Migration of Catalog Checks).

**The recorded output.** The run's stdout plus its exit code are pasted into the delivery record
alongside AC-8's two bare `ls` commands. It is run **after** the FR-A2 and FR-A3 edits and
**after** PR #185 is closed, so it audits the finished state.

---

### Render & Parity (NFR-2 / AC-11)

Three of the four changed paths are outside `canonical/`, so only
`reviewer-dispatch.md` and `authoring-conventions.md` drive a render. `authoring-conventions.md`
is a dogfood KB doc, not a canonical source, so the render set is one file.

1. Edit `canonical/` only. Never `profiles/`, `.claude/`, `.cursor/`.
2. Run the **full** generator, not a per-script renderer —
   `python .claude/skills/generate-profile/scripts/run_generator.py` — because a partial render
   leaves stale emission manifests and CI `render-drift` fails
   (`.aid/knowledge/architecture.md` § Gotchas, "After any `canonical/` edit, run the FULL
   `run_generator.py`").
3. **VERIFY (deterministic) must report PASS** —
   `python .claude/skills/generate-profile/scripts/verify_deterministic.py --canonical-root .`
   — the byte-identical re-render gate; a non-zero exit aborts before REPORT
   (`.claude/skills/generate-profile/SKILL.md` § Mode: VERIFY).
4. Resync the dogfood trees `.claude/` and `.cursor/` by regeneration, then confirm no hand-edit
   survived: `git diff --name-only` over `profiles/ .claude/ .cursor/` must contain only paths
   the generator wrote.
5. `.aid/knowledge/INDEX.md` is regenerated by
   `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
   if any frontmatter field this feature touches feeds a routing column — never hand-edited.

**The base-ref problem (NFR-1, and `Q1`).** `Q1` (Pending) is right that a bare `git diff` is
vacuous, and this branch shows it: `git diff --stat -- canonical/aid/scripts/grade.sh
canonical/aid/templates/reviewer-ledger-schema.md` → `0` lines, after 66 commits. The base must be
named.

Measured against `master` at `aef150fe8`:

- `git diff --stat master...HEAD -- canonical/aid/scripts/grade.sh canonical/aid/templates/reviewer-ledger-schema.md`
  → empty. Neither file has been touched on this branch.
- `git log --oneline master...HEAD -- canonical/aid/templates/reviewer-ledger-schema.md` → empty:
  the § Two sets from cycle 2 section is **already on master**, inherited rather than added here.

So `master` is a usable base today, and this SPEC still specifies **the work's base commit**
instead, for a reason that outlives today's measurement: `master` moves. A criterion whose base ref
is a moving branch silently re-scopes itself every time someone else merges, which is how an
inherited change becomes indistinguishable from this feature's own. The base is therefore **the
branch tip recorded at the start of this feature's first task** (`git rev-parse HEAD`, written into
the delivery record before any edit) — `2dd1eb0e6` if execution starts at this SPEC's approval. The
check is
`git diff <base> HEAD -- canonical/aid/scripts/grade.sh canonical/aid/templates/reviewer-ledger-schema.md`,
and the reading is `Q1`'s second disjunct only: **the diff touches neither counting logic nor
column shape**. An empty diff is sufficient but not required.

> **A measurement trap, recorded because it already caught this SPEC's first draft.** The local
> `master` *ref* in a worktree is whatever it was last fetched to, not what the remote holds. This
> draft was first measured against a `master` six commits stale (`9528462e0`), which reported the
> cost meter and the g07 oracle as absent from master and the ledger schema as `+60` lines — all
> three false. Any command in this SPEC that names `master` means `origin/master`, and is run after
> `git fetch origin master`. Verified: `git rev-parse master origin/master` returns the same sha.

---

### Verification — criterion by criterion

Every row is a command. Where nothing mechanical decides a criterion, the row says so.

| This SPEC's criterion | How it is checked |
|---|---|
| **1** — one review skill, one reviewer agent, audit resolves | `ls -d canonical/skills/*review*/` → 1 dir; `ls -d canonical/agents/*review*/` → 1 dir; `bash scripts/checks/review-path-audit.sh; echo "exit=$?"` → `RESULT PASS`, `exit=0`. All three outputs pasted into the delivery record. |
| **2** — PR closed/stripped; cascade-only criteria; 7-column everywhere | `gh pr view 185 --json state` → `CLOSED`; `git rev-parse work-003` still resolves; `grep -rn 'rubric catalog' canonical tests scripts docs .aid/knowledge` → `0`; `grep -ciE -e 7-column -e '7 columns' -e 'seven columns' canonical/skills/*/references/reviewer-brief.md canonical/skills/aid-review/SKILL.md` → `2` for each of the 6 briefs and `1` for the skill; `grep -c "Resolve the artifact.s review criteria first" canonical/agents/aid-reviewer/AGENT.md` → `1`. |
| **3** — migrated check has a cascade home cited by id; no live loader | for each migrated row, `grep -n '<new-id>' .aid/knowledge/authoring-conventions.md` → the row, with `Applies to`, `Kind`, `Severity`, `Why` populated; `grep -rn 'review-rubrics' canonical tests scripts docs .aid/knowledge` → `0`. If the screen admits **zero** rows, that outcome is recorded with the per-row screening table — a discharge, not a skip. |
| **4** — real dispatch produces a brief on disk and a `review-cost.tsv` row | after the next pipeline review, the brief file and its `task`/`cycle` row both exist — the two commands in the block below. Precedent on disk: **3** data rows for **3** briefs. |
| **5** — cycle-2+ brief carries labelled VERIFY/HUNT; cycle-1 does not | `grep -cE -e '^ +VERIFY *\(' -e '^ +HUNT *\(' .aid/works/work-013-review-stack-completion/briefs/*.md` → `2` for the `cycle-2` brief, `0` for both `cycle-1` briefs. The trailing `(` is what distinguishes the labelled list header from prose that merely mentions HUNT — verified: the cycle-2 brief contains one such prose line and it is correctly not counted. |
| **6** — a proposed script cites a measurement | the naive and guarded blocks in § The Closing Audit, re-run, reproduce **7** and **1** dangling refs. |
| **7** — `grade.sh` / ledger schema unchanged; render byte-identical | `git diff <recorded-base> HEAD -- canonical/aid/scripts/grade.sh canonical/aid/templates/reviewer-ledger-schema.md`, read as "touches neither counting logic nor column shape"; `verify_deterministic.py` → `VERIFY (deterministic): PASS`; `git diff --name-only` over `profiles/ .claude/ .cursor/` contains only generator-written paths. |
| **8** — every count re-derives | every count in this SPEC and in the delivery record carries its command inline; re-running each reproduces the figure. |

Criterion 4's two commands, and the precedent they currently return:

```bash
W=.aid/works/work-013-review-stack-completion
ls "$W"/briefs/*.md | wc -l                  # 3 -- one brief file per recorded cycle
awk -F'\t' 'NR>2' "$W"/review-cost.tsv | wc -l   # 3 -- one data row per brief
```

**No declared criterion reaches this SPEC.** The type registry bounds its corpus to "the markdown
under `canonical/skills/`, `canonical/agents/`, `canonical/aid/templates/` and `.aid/knowledge/`",
so a `.aid/works/**/SPEC.md` resolves to no registry type and inherits no type-level criteria;
`G-07` is not violated, because the file is not in-scope. That gap is `FR-B5`'s subject ("cover
work artifacts, not only KB") and belongs to feature-002. Until it closes, this SPEC is reviewed
against its own acceptance criteria and `.aid/knowledge/artifact-schemas.md` § Feature SPEC.md,
not against a resolved criteria list — stated here so a reviewer does not cite an id that does
not reach it.

---

### Routed Findings — real, measured, and deliberately not fixed here

Each was found while reading the stack for this feature and is out of its scope. None is silently
resolved.

| Finding | Evidence | Route |
|---|---|---|
| A stale local `master` ref makes every provenance claim in this SPEC wrong, silently | Measured after `git fetch origin master`: `git cat-file -e master:tests/review-cost-meter.sh` → exit `0`, same for `scripts/checks/g07-selector-partition.sh`; `git show master:.aid/knowledge/authoring-conventions.md \| grep -cE '^\| [A-Z]+-[0-9]{2} \|'` → `18`; `git rev-parse master origin/master` → one sha, `aef150fe8`. REQUIREMENTS §8 is therefore **correct**: the cascade, the ledger, VERIFY/HUNT, the cost meter, the oracle and `/aid-review` are all on master | **No conflict — this row records a retracted one.** This SPEC's first draft measured against `master` at `9528462e0`, six commits stale, and reported the cost meter and oracle as branch-only. They are not. The durable lesson is in § The base-ref problem: any command here naming `master` means `origin/master` and is run after a fetch. |
| `reviewer-dispatch.md` maintains an in-document changelog and instructs the next author to extend it | `grep -nE -e 'changelog entry' -e 'Bootstrap exemption' canonical/aid/templates/reviewer-dispatch.md` → 2 hits: § When this protocol changes step 1 "Update the changelog entry below", and the § Bootstrap exemption heading, which carries two dated lines | **feature-002 / FR-B7 + AC-7.** This feature edits the same file for FR-A2 — a sequencing note, not a merge conflict. Not touched here, so `Q2` is not pre-answered. |
| That changelog has already drifted: it names **7** brief templates for "6", including `aid-describe`, which has none | `ls canonical/skills/aid-describe/references/reviewer-brief.md` → "No such file"; § Brief generation's own prose is correct at 6 | Same route. It is a concrete instance of FR-B7's rationale, worth citing there. |
| 60 catalogued skills are hand-authored but classified `skill-generated`, so `SK-02` forbids each a file-level block | counts and commands in § Artifacts & Surfaces | **Registry defect, latent (0 live violations).** Becomes a **blocking prerequisite** for any task needing a file-level criterion on one of those 60 — including `aid-review/SKILL.md`. |
| No declared criterion covers a dangling *instruction pointer* in an `agent`-type file | `SR-01` applies to `skill-reference, template-own`; `AG-01` covers only a referenced agent | The strongest FR-A3 migration candidate (§ Migration of Catalog Checks). The instance — `content-isolation.md` in `aid-reviewer/AGENT.md` — is fixed under FR-A2. |
| `/aid-graph` names a skill that does not exist | `grep -rn 'aid-graph' canonical --include=*.md` → 1 hit, `canonical/aid/templates/design-lifecycle.md` § Region ownership | Not review-family, so the audit reports it as a `NOTE` and does not fail on it. Route to `tech-debt.md`; do not fix here. |
| `kb-authoring/review-rubric.md` § Rubric: Full Primary check 1 still requires "`intent:` non-empty" | `G-08` declares `intent:` superseded by `objective:` + `summary:` | Adjacent to FR-A2 but not named by it. Route to feature-002 with the FR-B7/`Q4` sweep. |

### Open — not decided by this SPEC

- **`Q7` is Pending and stays Pending.** This SPEC makes the FR-A5 audit the real guard (its
  suggestion) and supplies the demonstration `Q7` lacked, but does not re-word §9 AC-8. If the
  owner instead widens AC-8's glob, only the audit's L2 lexicon needs to move.
- **`Q1` is Pending.** This SPEC uses *the work's base commit*, which is what its own criterion 7
  already says and which the `master...HEAD` measurement shows is the only defensible base. §9
  AC-11's wording is still the owner's to fix.
- **How many of the 85 rows survive the screen** is not decided here. The corpus size (85), the
  four conditions, the id-namespace rule and one fully worked class (16 rows → 5 covered, 4
  candidates, 7 rubric-owned) are fixed; per-row judgment for the other 69 rows is task work, and
  a screen admitting zero rows is a legitimate outcome that must be recorded rather than padded.

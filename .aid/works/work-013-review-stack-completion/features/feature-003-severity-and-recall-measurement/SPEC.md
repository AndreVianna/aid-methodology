# Severity and Recall Measurement

## Source

- REQUIREMENTS.md §4 Scope — T3 Measure & judge
- REQUIREMENTS.md §5 Functional Requirements — FR-C1 … FR-C6
- REQUIREMENTS.md §6 Non-Functional Requirements — NFR-1 … NFR-4
- REQUIREMENTS.md §7 Constraints
- REQUIREMENTS.md §9 Acceptance Criteria — AC-4, AC-5, AC-9, AC-10, AC-11, AC-12
- REQUIREMENTS.md §10 Priority — item 3

## Description

With one stack and its blind spots closed, the last question is whether the grade means
anything. Four judgment-and-measurement gaps remain.

A severity today can be asserted without a reason. This feature requires every finding
to carry a one-line why that names the consequence — without undoing the cascade's
declared severities: when a finding cites a criterion that already prices itself, that
price is the default band and the why-line is still written. When the reviewer judges the
band itself, or diverges from the declared one, the row says so.

A new review cycle is told not to look at the previous cycle's ledger. Being told is not
the same as being unable. This feature makes the isolation structural, and proves it by
documenting an attempted path and its failure.

Nobody knows what fraction of real defects a review actually finds. This feature builds a
corpus of deliberately seeded defects and a command that reports recall against it, so
that recall becoming worse is a defect in the review subsystem rather than an invisible
decline.

And a fix that repairs one instance of a defect leaves its siblings in place. This
feature makes a class sweep part of closing a fix: the sweep command and its output are
recorded with the fix, and a seeded second instance of the same class is found by that
sweep rather than by the next review cycle.

This feature is last because its measurements only mean something once the first two have
settled what is being measured.

## User Stories

- As the owner, I want every finding to say what breaks, so that a grade reads as distance from the ideal rather than a feeling wrapped in arithmetic.
- As the reviewer agent, I want a severity practice I can defend line by line, so that a divergence from a declared severity is visible and justified instead of silent.
- As a pipeline skill, I want a new review cycle to be structurally unable to reach the previous cycle's ledger, so that a clean context is a property of the dispatch rather than an instruction I might not follow.
- As a maintainer, I want recall measured against seeded defects, so that a review getting worse at finding things shows up as a regression.
- As a maintainer, I want a fix to sweep its own defect class before it closes, so that the same bug is not rediscovered one instance at a time.
- As the reviewer agent, I want mechanical checks that only observe to stay out of the ledger, so that observations do not silently become grade-affecting findings.

## Priority

Should

## Acceptance Criteria

> `## Priority` above is this feature's scheduling weight from §10. Each criterion below
> carries its own modality, inherited from the requirement it discharges — a Should
> feature can and does contain MUST criteria.
>
> The last two criteria are synthesized: FR-C3 and FR-C6 reach no criterion in §9, so
> each inherits its source requirement's SHOULD.

- [ ] **MUST** — Given a real review cycle, when its ledger is measured by the cited command, then every row's `Description` carries a one-line why naming the consequence, and any row whose severity diverges from a cited criterion's declared `severity:` says so in `Evidence`; the row count is reported. *(discharges FR-C1; §9 AC-9)*
- [ ] **MUST** — Given a new review cycle, when a reviewer attempts to reach the prior cycle's ledger, then the attempt fails structurally, and the attempted path and its failure are documented rather than an instruction not to look. *(discharges FR-C2; §9 AC-4)*
- [ ] **MUST** — Given the seeded-defect corpus, when the recall-report command is run, then it produces a recall figure per rule set and overall, and its output is recorded. *(discharges FR-C4; §9 AC-4)*
- [ ] **MUST** — Given a FIX cycle, when it is closed, then its class sweep has run with the command and output recorded, and a seeded second instance of the same defect class was found by that sweep rather than by the next review cycle. *(discharges FR-C5; §9 AC-10)*
- [ ] **SHOULD** — Given a review where file-scoped HUNT is shown to be insufficient, when coverage is recorded, then a coverage unit may be a claim or worklist item rather than a file, demonstrated on at least one such review. *(discharges FR-C3; synthesized — no §9 criterion)*
- [ ] **SHOULD** — Given a mechanical check that only observes, when it runs, then it emits no ledger row; only an open criteria gap may block a grade for a missing rule; and an oracle emitting `VIOLATION` appears as an ordinary criteria finding in the same 7-column ledger, never as a second ledger. *(discharges FR-C6; synthesized — no §9 criterion)*
- [ ] **MUST** — Given a script proposed by this feature — the recall tooling in particular — when it is merged, then it cites a measurement of the re-derivation it removes. *(discharges NFR-3; §9 AC-5)*
- [ ] **MUST** — Given this feature's changes, when `grade.sh` and `reviewer-ledger-schema.md` are diffed against the work's base commit, then neither counting logic nor column shape has changed; and `generate-profile` re-renders byte-identically with VERIFY deterministic PASS, with no hand-edit in `profiles/` or the dogfood trees. *(discharges NFR-1, NFR-2; §9 AC-11)*
- [ ] **MUST** — Given any count stated in this feature's artifacts, when the cited command is re-run, then it reproduces the number. *(discharges NFR-4; §9 AC-12)*

---

## Technical Specification

> **How to read the counts.** NFR-4 requires every stated count to carry the command that
> produced it. Every figure below is followed by its command, run from the worktree root at
> `HEAD` = `2d0fb40dd`. Any command naming `master` means `origin/master`, run after
> `git fetch origin master`; verified before anything below was measured —
> `git rev-parse master origin/master` returns one sha, `aef150fe8`. The command convention is
> feature-001's and is inherited rather than restated: pipe-free in a table cell wherever
> possible, and a fenced block wherever a real shell pipeline is needed, because a
> markdown-escaped `\|` inside a cell is not the pipe a shell reads.
> **Section shape.** The three core sections of `canonical/aid/templates/specs/spec-template.md`
> are kept so the schema in `.aid/knowledge/artifact-schemas.md § Feature SPEC.md` still
> resolves. Two of them carry real content here — this feature does persist data (a fixture
> catalogue and a measurement pair) and does change a dispatch sequence — and the third is
> `N/A` with its reasoning. The sections that carry the rest of the work follow them.

### Data Model

**Active, and small.** The repository persists no application data
(`.aid/knowledge/project-structure.md` "Unusual Structure Notes"), but FR-C4 introduces two
tab-separated files, and their shape is a contract because a script parses them. Both follow the
`.tsv` + `.meta` **run-id pair** already used twice on this tree — `tests/coverage-baseline.tsv`
with `tests/coverage-baseline.meta`, and `review-cost.tsv` with `review-cost.meta`, whose
`verify_pair` refuses to append when the two run ids disagree
(`tests/review-cost-meter.sh` → `verify_pair`). The pair pattern is adopted, not invented, and
for the reason that file states: an appending measurement is exposed for the whole life of a
work, so a mismatch must be caught at the append that would widen it.

**1. The corpus catalogue — `tests/canonical/fixtures/review-recall/catalog.tsv`.** One row per
seeded defect. The columns are the fields a recall computation and a class sweep both need, and
nothing else:

| Column | Meaning | Why it is a column and not prose |
|---|---|---|
| `defect_id` | stable id for this seeded defect, e.g. `RD-001` | the join key between catalogue and a cycle's ledger; a prose name cannot be joined on |
| `class` | the defect class, one phrase | FR-C5's sweep is over a class; the seeded second instance shares this value |
| `criterion` | the criterion `id` the defect violates, or `--` | FR-C4 asks for recall **per rule set**; the rule set is this id's scope prefix |
| `declared_severity` | the band that criterion prices itself at, or `--` | lets the report show whether a found defect was also priced correctly (FR-C1's default band) |
| `fixture` | repo-relative path of the fixture file carrying the defect | the corpus must be readable without an agent |
| `signature` | the grep-recoverable distinguishing phrase | it is both the recall matcher and FR-C5's sweep pattern — one string, two consumers |
| `expected_doc` | the path a correct finding would put in the ledger's `Doc` column | matching on `signature` alone would count a row that names the wrong file |

`defect_id` is the primary key; `class` + `signature` is what a sweep runs on; `criterion`'s
scope prefix is the grouping key. **No cell contains a pipe or a tab.** `--` is the absent
marker, matching the enum convention `.aid/knowledge/artifact-schemas.md § Conventions` already
uses across state files.

**2. The recall record — `tests/review-recall.tsv` + `tests/review-recall.meta`.** Append-only,
one row per measured cycle: `run`, `scope`, `cycle`, `commit`, `rule_set`, `seeded`, `found`.
`rule_set` = `ALL` for the overall figure and one row per scope prefix otherwise, so "per rule
set and overall" is data rather than a derived reading. `seeded` and `found` are stored instead
of a ratio: a stored percentage cannot be re-checked, and a row with `seeded` = 0 must report
**missing**, never 100% — the same distinction `review-cost-meter.sh report` already draws
("A task with no rows is reported as missing, never as zero").

**No new state-file key, and no schema change to an existing artifact.** In particular the class
sweep is **not** written into `quick_check.findings[]`: that sequence's field set is closed at
`severity` / `description` / `source` / `disposition`
(`.aid/knowledge/artifact-schemas.md § Task STATE.yml`, "Quick Check Findings" row), so adding a
sweep field there would be an artifact-schema change this feature does not need — see
§ The Class Sweep for where the record actually lives.

### Feature Flow

**Active for one sequence only: the reviewer dispatch.** FR-C2 changes the ordered steps of a
dispatch, and that sequence is defined once, in `canonical/aid/templates/reviewer-dispatch.md`
§ Brief generation ("Render the brief TO A FILE, then dispatch and record from that same file —
one step").

Today, three steps:

1. render the brief into `.aid/works/{work}/briefs/<scope>-cycle-<N>.md`
2. `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief "$brief"`
3. dispatch the reviewer with the contents of that file

After this feature, four — one preflight added ahead of the render, and the ledger path resolved
as a parameter rather than named as a constant:

1. **PREFLIGHT (new).** Resolve `{{LEDGER}}` for this scope. On **cycle 1**, assert no file
   exists at that path; if one does it is a leftover from an earlier invocation and the dispatch
   **fails loudly** rather than handing a stale finding list to a fresh reviewer. On **cycle N≥2**
   assert it *does* exist, because the carry-forward the schema mandates has nothing to read
   otherwise.
2. render the brief, with `{{LEDGER}}` substituted — the brief names exactly one ledger path
3. `record` (unchanged)
4. dispatch (unchanged)

**Why the preflight goes in that block and nowhere else.** The same file already explains why:
an earlier version mandated `record` separately from rendering, and the mandate "was satisfiable
by doing nothing … an entire delivery's measurements were silently never taken". Deletion at DONE
has exactly that shape today — it is mandated (`reviewer-ledger-schema.md` Lifecycle step 5, and
per-skill, e.g. `canonical/skills/aid-specify/references/state-done.md`'s
`rm -f .aid/.temp/review-pending/specify-<feature>.md`) and nothing fails when it is skipped.
Binding the check to the artifact the dispatch already produces is the fix that file prescribes
for its own class of failure.

**Nothing else in the flow moves.** VERIFY/HUNT, the two labelled lists from cycle 2, the
five-section brief, the OOS policy, `grade.sh`, the Status lifecycle and the REVIEW→FIX loop are
untouched. NFR-5's three components survive intact: the preflight is an addition ahead of the
`record` call, not a substitution for it.

### Layers & Components

**N/A as layering** — there is no application layering here, no DI, no service/repo split. The
equivalent structural statement is § Artifacts & Surfaces below, which names every file that
changes and every tree that must never be hand-edited.

---

### Artifacts & Surfaces

**Authored, in scope to change:**

| Path | Why it changes | Registry type |
|---|---|---|
| `canonical/aid/templates/reviewer-ledger-schema.md` | FR-C1 — the `Description` and `Evidence` contracts live here, and today the `Description` row forbids what FR-C1 requires | `template-own` |
| `canonical/agents/aid-reviewer/AGENT.md` | FR-C1 — § Severity Classification is where the two agent-owned severity rules live; the why-line and the divergence record join them | `agent` |
| `canonical/aid/templates/reviewer-dispatch.md` | FR-C2 (the preflight + `{{LEDGER}}`), FR-C3 (a coverage unit that is not a file) | `template-payload` (undecided by the `G-07` oracle) |
| `canonical/skills/*/references/reviewer-brief.md` (6 files) | FR-C2 — each brief names its ledger path; the parameter has to reach them | `skill-reference` |
| `canonical/skills/aid-discover/references/state-fix.md` | FR-C2 — the one FIX state that hard-codes a constant ledger path with no token | `skill-reference` |
| `canonical/skills/aid-execute/references/state-fix.md` | FR-C5 — the FIX contract (F1-F7) is where a class sweep becomes part of closing | `skill-reference` |
| `canonical/aid/templates/kb-authoring/frontmatter-schema.md` § `oracle:` | FR-C6 — the oracle contract's home; the observe-only boundary belongs beside it | `template-own` |
| `.aid/knowledge/authoring-conventions.md` | FR-C1/FR-C6 — § Reviewer Ledger Convention states the ledger's shape for authors; the criteria table prices what a violation costs | `kb-doc` |
| `tests/canonical/fixtures/review-recall/**` (new) | FR-C4 — the corpus | outside the registry corpus |
| `tests/review-recall.sh` (new) | FR-C4 — the recall report | outside the registry corpus |
| `tests/canonical/test-severity-why-line.sh` (new) | FR-C1 — the why-line contract, and the counting command's own correctness | outside the registry corpus |
| `tests/canonical/test-ledger-isolation.sh` (new) | FR-C2 — the canary, modelled on `test-output-root-isolation.sh` | outside the registry corpus |
| `tests/canonical/test-scoped-review-cycles.sh` | FR-C3/FR-C5 — it already `COVERS:` both changed templates and already carries the seeded-defect harness; also gains the missing `# COVERS:` line for `grade.sh`, which its `SC15` runs but does not declare (§ The Why-Line) | outside the registry corpus |
| `tests/canonical/test-criterion-oracles.sh` | FR-C6 — it already `COVERS:` the oracle contract and the registry; also gains the missing `# COVERS:` line for `aid-reviewer/AGENT.md`, the file its `OR18` already asserts against (§ The Why-Line) | outside the registry corpus |

New suites are discovered by glob, so `tests/run-all.sh` needs no edit
(`.aid/knowledge/test-landscape.md` `F-01`, "discovers suites by the glob
`tests/canonical/test-*.sh`").

**Generated — never hand-edited (NFR-2).** `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/`,
the dogfood trees `.claude/` and `.cursor/`, `packages/**/_vendor/`, and `.aid/knowledge/INDEX.md`.
Editing a rendered copy does nothing and CI `render-drift` fails
(`.aid/knowledge/architecture.md` § Gotchas, "Editing a rendered/vendored copy does nothing").

**Sequencing, not conflict.** `reviewer-dispatch.md` is edited by all three features — feature-001
for FR-A2's catalog framing, feature-002 for FR-B7's in-document changelog, and this one for
FR-C2/FR-C3. §10 orders the tracks T1 → T2 → T3, so this feature edits the file last and rebases
onto both. `reviewer-ledger-schema.md` is different and worth stating plainly: **feature-001
measured it as untouched on this branch and must keep it that way; this feature is the one that
edits it**, under the boundary in § The Why-Line. That is not a contradiction between the two
SPECs — feature-001's claim is scoped to feature-001's own changes — but a reviewer comparing
them will see the same file called untouched in one and edited in the other, so the reason is
recorded here rather than left to be inferred.

---

### The Why-Line Inside a Fixed Schema (FR-C1)

#### What is already law, measured — so the delta is small and precise

Two of FR-C1's three parts are already on master. Measured:

| FR-C1 part | Already law? | Command and result |
|---|---|---|
| a cited criterion's `severity:` is the default band | **Yes** | `grep -c "take that criterion.s own" canonical/agents/aid-reviewer/AGENT.md` → `1` (§ Severity Classification, "take that criterion's own `severity:` … rather than judging one — the criterion has already priced itself against the scale") |
| a severity that came from an override is recorded in `Evidence` | **Yes** | `grep -c "Overrides are recorded in" canonical/aid/templates/reviewer-ledger-schema.md` → `1`, with a worked row in § Citing the criterion |
| every finding carries a one-line why naming the consequence | **No** | measured below: `0` of `2` rows on the most recent real ledger |

So FR-C1 does **not** need a severity mechanism built. It needs the why-line, and it needs the
divergence case — the one the existing override rule does not cover, because an override is a
*declaration* in a file's frontmatter while a divergence is the reviewer's *judgment*.

#### The one place existing law contradicts FR-C1

`reviewer-ledger-schema.md` § Columns, the `Description` row, reads: *"The criterion `id`
violated, then ONE sentence stating what's wrong … Avoid hedging or explanation; explanation goes
in Evidence."* Taken literally, a why-line inside `Description` is the thing that row forbids.

**Stated plainly, as the constraint requires: the why-line can live inside the existing columns,
and no column has to be added — but it is not free.** One sentence of that row's contract has to
change. The reconciliation is a real distinction, not a wording dodge:

| Cell | Carries | Does not carry |
|---|---|---|
| `Description` | what is wrong, and **what breaks because of it** | the proof, the disk truth, the command |
| `Evidence` | the proof, the command, the status justification, the **severity provenance** | the consequence |

A consequence is a fact about impact; an explanation is the reviewer's argument that the claim is
true. The row's ban on "explanation" is aimed at the second — a `Description` that argues its own
case is what made ledgers unreadable — and keeping the consequence in `Description` is what makes
a grade legible without opening `Evidence` for every row. The edit therefore **narrows** that
clause rather than deleting it.

#### The form

```
Description:  <criterion-id> — <what is wrong>; so <consequence>
Evidence:     <disk truth or command>; <severity-provenance token>
```

`; so ` is the connective, and it is the project's own idiom rather than a new notation: `6` of
the `18` declared criteria and `8` file-level `why:` values already state their consequence that
way (`awk '/^\| ID \| Applies to/,/^$/' .aid/knowledge/authoring-conventions.md | grep -E '^\| [A-Z]+-[0-9]{2} \|' | grep -c ' so '`
→ `6`; `grep -rh -A3 '^ *why:' canonical/agents canonical/aid/templates .aid/knowledge --include=*.md | grep -c ' so '`
→ `8`). One sentence with a semicolon is still one sentence, so the "ONE sentence" half of the
`Description` contract stands unchanged.

**The severity-provenance token is one of four, and exactly one is required.** This is the half
that keeps the cascade intact while making a divergence visible:

| Case | Token in `Evidence` |
|---|---|
| band taken from a cited criterion's declared `severity:` | `declared <BAND> via <id> (global / type / file)` |
| band came from a file-level override of that `id` | the existing form, unchanged — `resolved <BAND> via file-level override of <id> (<BAND> global); why: "…"` |
| reviewer diverges from the declared band | `judged <BAND> against declared <BAND> via <id>; why: …` |
| no criterion reaches the file, so no band is declared | `judged <BAND>; no declared criterion reaches <Doc> because <reason>` |

The fourth case is **not** an edge case here. On the most recent real ledger it is every row:
`2` of `2` say so in as many words, because a `.aid/works/**/SPEC.md` resolves to no registry type
(the gap feature-002 closes under FR-B5).

```bash
L=.aid/.temp/review-pending/specify-feature-001.md
awk '{ line=$0; gsub(/\\\|/,"\x1e",line); n=split(line,c,"|");
       if (n>=8 && c[3] ~ /\[/) { tot++; if (c[7] ~ /No criterion id/) noid++ } }
     END { printf "rows=%d no-id=%d\n", tot, noid }' "$L"     # rows=2 no-id=2
```

**What must not change, and is the whole of NFR-1 here.** `grade.sh` reads `cols[3]` and
`cols[4]` and ignores `cols[5..8]` (`canonical/aid/scripts/grade.sh`, "Severity tags in cols[5..8]
… are ignored"), so nothing above can reach the grade. The prohibited set, each item checkable:
the column count and header row; the `Severity` and `Status` enums; which statuses count; the
`modifier_for_count` thresholds; § grade.sh integration. `grade.sh` itself is **not edited at all** —
its diff against the base must stay empty, which is stricter than the criterion requires and is
the correct bar for a file this feature has no reason to touch.

**Two suites already pin NFR-1 to a literal string, in the two files this feature edits — so the
edit is line-scoped, not file-scoped.** This is the strongest form of NFR-1 available here,
because it fails in CI rather than in a reviewer's judgment:

| Canary | Pinned literal | Where it lives | Where this feature edits |
|---|---|---|---|
| `test-scoped-review-cycles.sh` `SC15` — `grep -q "shape stays 7 columns" "$SCHEMA"` | `shape stays 7 columns` | `reviewer-ledger-schema.md` **line 95**, § Citing the criterion | **lines 87-88**, the `Description` and `Evidence` rows of § Columns |
| `test-criterion-oracles.sh` `OR18` — `assert_file_contains … "7-column"` | `7-column` | `aid-reviewer/AGENT.md` **lines 3 and 95** (frontmatter `description:`, and § the oracle contract's close) | § Severity Classification |

```bash
grep -n 'shape stays 7 columns' canonical/aid/templates/reviewer-ledger-schema.md   # 95
grep -cn '7-column' canonical/agents/aid-reviewer/AGENT.md                          # 2  (lines 3, 95)
```

In both files the canary sits in a **different section from the edited region**, so the edit does
not have to route around a string — it simply must not reach for the nearby "no eighth column"
sentence to carry the new contract. Stated because the temptation is real: § Citing the criterion
is the natural place to explain a `Description` change, and it is the one paragraph in the file
that a suite reads by exact string. The why-line contract goes in the § Columns rows instead, and
`SC15`'s literal is left byte-identical. This also makes criterion 8 cheap to check: the two
greps above are the machine half of "column shape unchanged".

**But only one of the two canaries is selected automatically, and this feature has to fix that.**
`SC15`'s suite declares the file it guards; `OR18`'s does not:

```bash
grep -n '^# COVERS:' tests/canonical/test-scoped-review-cycles.sh   # reviewer-ledger-schema.md, reviewer-dispatch.md
grep -n '^# COVERS:' tests/canonical/test-criterion-oracles.sh      # g07-selector-partition.sh, frontmatter-schema.md, authoring-conventions.md

# the gap, and its control -- the selector's own explicit mode
bash tests/canonical/select-suites.sh canonical/agents/aid-reviewer/AGENT.md \
  | grep -c 'test-criterion-oracles'                                # 0  <-- OR18 not selected
bash tests/canonical/select-suites.sh canonical/aid/templates/reviewer-ledger-schema.md \
  | grep -c 'test-scoped-review-cycles'                             # 1  <-- SC15 selected
```

`test-criterion-oracles.sh` asserts `OR18` against `canonical/agents/aid-reviewer/AGENT.md` but
does **not** name that file in its `COVERS:` header — so a selective run for an `AGENT.md`-only
change skips the very assertion that guards the column shape there. Measured above: `0` against a
control of `1`. The selector's fail-safe does not save it, because that fail-safe covers only
suites with **no** `COVERS:` header at all — which is a declared criterion, `F-04` of
`.aid/knowledge/test-landscape.md`: *"A suite with no COVERS header is treated by
select-suites.sh as covering everything and is always selected"*, whose own `why` is that
"forgetting the header costs run time, never coverage". The inverse is the hazard here: a header
that is present but **incomplete** costs coverage silently, and `F-04` does not price that case.
A suite with a header gets exactly what it declared. Since this feature edits
`AGENT.md`, it **adds the missing `# COVERS: canonical/agents/aid-reviewer/AGENT.md` line** to
that suite. One line, and it closes a hole in the selection this feature would otherwise fall
through: the three files the suite already declares (`frontmatter-schema.md`,
`authoring-conventions.md`, `g07-selector-partition.sh`) are all edited here too, so the suite
happens to be selected anyway — which is exactly the kind of accident that hides the gap until a
change touches `AGENT.md` alone.

**And the class is swept, because FR-C5 is this feature's own rule.** An incomplete `COVERS:`
header is a *class*, not one line, so the same check runs against all four headered suites — the
declared paths against the paths each suite actually reaches:

```bash
for f in tests/canonical/test-{criterion-oracles,scoped-review-cycles,review-cost-meter,validator-behavior}.sh; do
  echo "== $f"; grep '^# COVERS:' "$f"
  grep -ohE '\$\{?REPO_ROOT\}?/[A-Za-z0-9._/-]+' "$f" | sed 's|.*REPO_ROOT}\{0,1\}/||' | sort -u
done
```

Read the output with one filter: a path the suite *creates and deletes* is scaffolding, not a
subject, and correctly stays out of `COVERS:` — `canonical/agents/__g07probe__` is written at
line 82 and removed at line 90, so it is excluded on purpose, not by oversight. What remains:

| Suite | Asserts against, but does not declare | Selector check | Disposition |
|---|---|---|---|
| `test-criterion-oracles.sh` | `canonical/agents/aid-reviewer/AGENT.md` — `OR18`, via `assert_file_contains` | `0` | **fixed here** — this feature edits `AGENT.md` |
| `test-scoped-review-cycles.sh` | `canonical/aid/scripts/grade.sh` — `SC15` runs the grader (line 180); **and** `canonical/skills/**` — `SC09-11` count the contradiction-pass sites there (lines 153, 156) | `0` for `grade.sh` | **`grade.sh` fixed here** (see below); `canonical/skills/` **routed** — declaring a whole tree selects the suite for every skill change, which is a cost trade this feature should not make unilaterally |
| `test-review-cost-meter.sh` | nothing undeclared | — | clean |
| `test-validator-behavior.sh` | `canonical/aid/scripts/summarize/grade-summary.sh`, and `.aid/knowledge/kb.html` (`PV11` runs over the shipped artifact) | `0` for `grade-summary.sh` | **routed**, not fixed — the summarize subsystem is outside T3 |

The selector checks are the explicit-mode invocation shown earlier, once per path:

```bash
bash tests/canonical/select-suites.sh canonical/aid/scripts/grade.sh \
  | grep -c 'test-scoped-review-cycles'                             # 0
bash tests/canonical/select-suites.sh canonical/aid/scripts/summarize/grade-summary.sh \
  | grep -c 'test-validator-behavior'                               # 0
```

**The `grade.sh` row is the one that matters to this feature, and it is why the sweep was worth
running.** `SC15` is the instrument criterion 8 leans on to prove "counting logic unchanged"
behaviourally — and a change to `grade.sh` alone does **not** select the suite that guards it.
NFR-1's protection of `grade.sh` was therefore only as good as a full-suite run. This feature adds
`# COVERS: canonical/aid/scripts/grade.sh` to that suite as well: it does not edit `grade.sh`, but
it does depend on `SC15` being reached, and a criterion whose instrument can be skipped is not a
criterion. Two one-line header additions, no assertion logic touched.

#### Measuring it (this is where Q8 lands)

`Q8` is Pending, and it is right: §9 AC-9 says "measured by **reading** that cycle's ledger" while
NFR-4 demands a command. This SPEC supplies the command `Q8` asks for, and it also states the
limit that keeps the reading from being redundant — a grep can decide the **form**, never whether
a clause names a real consequence.

```bash
# The why-line screen. Prints the row total, the count carrying the connective,
# and the row numbers of the residue -- which is what gets read.
awk '{ line=$0; gsub(/\\\|/,"\x1e",line); n=split(line,c,"|")
       if (n>=8 && c[3] ~ /\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]/) {
           tot++; if (c[7] ~ /; so /) ok++; else { gsub(/ /,"",c[2]); miss = miss " " c[2] }
           if (c[8] !~ /declared |judged |override /) { gsub(/ /,"",c[2]); noprov = noprov " " c[2] }
       } }
     END { printf "rows=%d why-line=%d missing:%s no-provenance:%s\n", tot, ok+0, miss, noprov }' \
    .aid/.temp/review-pending/<scope>.md
```

Run against the most recent real ledger, today, verbatim:
`rows=2 why-line=0 missing: 1 2 no-provenance: 1 2` — the practice does not exist yet, in either
half, which is exactly why FR-C1 exists.

**Two traps this command exists to avoid, both measured:**

1. **An escaped pipe shifts the columns.** That ledger's row 1 contains `\|` in both
   `Description` and `Evidence`; splitting on a bare `|` gives that row **11** fields where the
   others give **9**, so `c[7]` is a fragment of the wrong cell. Masking `\|` first is the fix,
   and it is the technique `scripts/checks/g07-selector-partition.sh` already uses for the same
   reason ("Mask the escaped pipes before splitting … so a cell's own content can never shift the
   columns"). Measured: `awk -F'|' '$0 ~ /^\|/ && $0 !~ /^\|[[:space:]]*[-:]+/ {print NR": fields="NF}' $L`
   → `1: fields=9`, `3: fields=11`, `4: fields=9`.
2. **The screen is one-sided.** `; so ` can be present in a clause that names no consequence, so
   a pass proves form, not substance. The count is therefore reported **with the residue row
   numbers**, and the semantic half stays a read of those rows. That is the honest form of AC-9,
   and it is why this SPEC does not propose re-wording AC-9 to "measured by a grep" — see § Open.

**Where the guard lives.** `tests/canonical/test-severity-why-line.sh` asserts the contract on
fixtures rather than on live ledgers (which are gitignored and absent in CI): a compliant row
passes, a row with no `; so ` fails, a row with no provenance token fails, and — the assertion
that matters most — a row whose `Description` carries an unmasked `\|` is still read correctly.
It also re-asserts the grade for the same fixture rows, so a Description change that somehow
reached the grade would be caught in the same file. `test-scoped-review-cycles.sh` `SC15` already
holds the grade contract independently (empty=A+, one LOW=B+, HIGH+Fixed-LOW=D+, verified today by
running it), and its own fixture Descriptions (`G-01 — x`) are deliberately not why-line-compliant —
they exercise the grader, not the authoring contract, so they stay as they are.

---

### Structural Clean Context (FR-C2)

#### What "structural" already means in this project

FR-C2 must not invent a meaning for the word. This project has one, with a precedent and a machine
proof: `quality-gates.md § The Conformance Check` — *"A shadow extraction dispatches aid-discover
subagents with a throwaway `output_root` … which is structurally isolated from the real
`.aid/knowledge/` tree — the real KB is unreachable by construction"* — proven by
`tests/canonical/test-output-root-isolation.sh`, whose header states the standard exactly:
*"the prose specification must express the redirect for the write boundary to hold at runtime.
Structural assertions on the prose ARE the machine proof for agent-prose write guarantees."*

So structural, here, means three things — a **parameterised path** instead of a constant, **nothing
at the old path to open**, and **no recovery route** — each machine-checkable. It does not mean a
sandbox: the reviewer holds `Bash` and could read any file it can name. The design closes the
naming, not the syscall, and says so.

#### The gap today, measured

| Claim | Command | Result |
|---|---|---|
| the isolation is instructed, in many places | `grep -rl 'clean context' canonical --include=*.md` | `48` files |
| every instruction site names only the **absence** case, never unexpected presence | `grep -c 'If the file does not exist, there is nothing to fix' canonical/skills/aid-discover/references/state-fix.md` → `1`; and `canonical/skills/aid-specify/references/state-review.md` § Dispatch the Reviewer, its "Ledger lifecycle" bullet, says to read the ledger *if it exists* and stops there | so a cycle-1 reviewer handed a leftover reads it as its own history, which is `F-06`'s hazard exactly |
| the hazard is a declared criterion of the schema, with no check behind it | `grep -c 'read as a live finding list by the next run' canonical/aid/templates/reviewer-ledger-schema.md` | `1` (`F-06`, severity LOW) |
| and no suite asserts the deletion that `F-06` depends on | `grep -rl 'review-pending' tests/canonical/test-*.sh` | `2` suites (`test-housekeep-classify.sh`, `test-shortcut-engine-contract.sh`), neither about the ledger's lifecycle |
| ledger paths are constants, not parameters | fenced block below | `42` occurrences of a fully-literal path, across `14` skill files that instruct a read or write of one |

> **A trap recorded because it caught this SPEC's first draft, and it is the second time this
> work has hit the same class.** The obvious way to state row 2 is a grep for the permissive
> phrase — and `grep -rn 'if it exists'` over those state files returns **nothing**, because the
> phrase wraps across a line break (`grep -n 'if it$' canonical/skills/aid-specify/references/state-review.md`
> shows the line ending in "if it"). A count of `0` there would have read as "no permissive
> instruction exists", the opposite of the truth. feature-001 recorded the same exact-string trap
> against `7-column`; the durable rule is that **a negative claim about prose is not proven by one
> grep** — quote the site, or count something positive.

```bash
grep -rhoE 'review-pending/[A-Za-z0-9._-]+\.md' canonical --include=*.md \
  | grep -vE '<|\{|NNN' | wc -l                                          # 42
grep -rlnE 'review-pending/(discovery|update-kb|plan|detail|deploy|summarize)\.md' \
  canonical/skills --include=*.md | wc -l                                # 14
```

**The gap is not hypothetical, and the project has already diagnosed it in writing.**
`canonical/skills/aid-update-kb/references/state-review.md` § 4(d) says of the discover FIX state:
*"`state-fix.md` has no ledger-path parameter of any kind (its Step 0 unconditionally hardcodes
`Read .aid/.temp/review-pending/discovery.md`, with no `{{SCOPE}}`/`{{LEDGER}}` token anywhere in
the file); invoking it here would either silently no-op … or apply fixes against an unrelated
aid-discover ledger (if one does)."* Verified: `grep -n 'review-pending' canonical/skills/aid-discover/references/state-fix.md`
returns one line, the hard-coded read. The workaround chosen there was to duplicate the whole FIX
loop rather than parameterise the path — which is evidence for FR-C2, and it means fixing the path
lets that duplication be retired later (not here; out of scope).

**And it is live right now, in this pipeline.** At the moment this SPEC is authored,
`.aid/.temp/review-pending/` holds exactly one file and it belongs to a *different* feature:
`ls .aid/.temp/review-pending/` → `specify-feature-001.md`. The brief for this feature names only
its own ledger, and nothing but instruction stands between a reviewer dispatched for feature-003
and the finding history of feature-001. That is the demonstration, not an analogy.

#### The mechanism — three legs, two already law

| Leg | Mechanism | Status |
|---|---|---|
| **L1 — parameterised path** | `{{LEDGER}}` is resolved by the dispatcher and substituted into the brief; the 6 brief templates and the FIX states take it as a token instead of naming a constant. Canary: **zero** fully-literal `review-pending/<name>.md` paths survive in a REVIEW/FIX instruction surface (schema examples and the path table are documentation, not instruction, and stay) | **new** |
| **L2 — nothing at the old path** | deletion at DONE, plus the cycle-1 preflight that fails when a ledger for this scope already exists (§ Feature Flow). The attempted path then returns ENOENT: unreachable because absent, not because forbidden | deletion is law (`reviewer-ledger-schema.md` Lifecycle step 5; per-skill `rm -f`); the **preflight is new** and is what makes the deletion non-optional |
| **L3 — no recovery route** | `.aid/.temp/` is gitignored, so a deleted ledger cannot be recovered with `git show`, and CI blocks a tracked one: `.github/workflows/test.yml`, job `kb-hygiene`, step *".aid/.temp/ is gitignored and untracked"* runs `git check-ignore` and `git ls-files .aid/.temp/` | **already law, already CI-gated.** `git ls-files .aid/.temp` → no output |

**L3's one honest caveat, recorded because the exception is on this branch's own history.** The
gate exists because the leak happened: `git log --oneline --all -- .aid/.temp` returns `2` commits,
the second of them `d14284bc3` *"work-009: untrack .aid/.temp file caught by recovery (fixes
KB-hygiene CI gate)"*. A force-add defeats gitignore; the CI step is what catches it. So L3 is
structural **because of the gate**, not because of the ignore file, and the SPEC cites the gate.

#### Rejected: a per-invocation ledger directory

The obvious alternative is `.aid/.temp/review-pending/<run-id>/<scope>.md`, so sibling scopes are
not even in the same directory. **Rejected**, for two reasons that outrank the benefit: it
contradicts `F-05` of the schema ("The ledger lives at `.aid/.temp/review-pending/<scope>.md`"),
so it is a change to the schema's location contract on top of the `Description` change FR-C1
already needs; and it buys nothing L2 does not, because a `Bash`-armed agent can list the parent
either way. The isolation that holds is *absence*, not depth.

#### The proof obligation AC-4 states

AC-4 wants "the attempted path and its failure, not an instruction". Three attempts, each with the
failure it must produce, recorded with the delivery:

```bash
# 1. a prior invocation's ledger, at the path the old constant named
cat .aid/.temp/review-pending/discovery.md          ; echo "exit=$?"   # No such file; exit=1
# 2. the same, via git, from inside the work tree
git show HEAD:.aid/.temp/review-pending/discovery.md; echo "exit=$?"   # path does not exist in HEAD; exit=128
# 3. the preflight itself, with a leftover in place (in a throwaway copy, never the live tree)
#    -- the dispatch must FAIL, and name the leftover
```

Attempt 3 is the one that cannot be faked, and it is the assertion
`tests/canonical/test-ledger-isolation.sh` carries, built on `test-output-root-isolation.sh`'s
K-series canary shape: `K`-equivalents assert the literal-path count is zero in the instruction
surface (so a regression that reintroduces one fires immediately), and the preflight is exercised
against a seeded leftover in a `mktemp -d` copy per `S5` ("Mutate a **copy** … never the source
tree").

---

### The Seeded-Defect Corpus and Recall Report (FR-C4)

#### The corpus is an extension of one that already exists

`tests/canonical/test-scoped-review-cycles.sh` is titled *"the three guards, by seeded defect"* and
builds a miniature corpus in a `mktemp -d` git repo, seeding a defect in a referring file and a
second outside the scoped surface. Its header also states the boundary FR-C4 inherits and must not
pretend away:

> *"the reviewer is an LLM, so these assertions exercise the DERIVATIONS the protocol mandates …
> not an agent's obedience to them. That is the honest boundary."*

`tech-debt.md` `L4` names the same technique from the other direction — the tracked remedy for
"no measure of test-suite effectiveness" is *"mutation testing + invariant-anchoring +
behavioral-surface + escaped-defect ledger"* — and `test-landscape.md` states why it is the right
oracle: *"mutation is the only oracle that catches suites which are green against a broken subject."*
A seeded-defect corpus for the review subsystem **is** mutation testing pointed at the reviewer.
`L4` explicitly scopes prompt-driven skills out of its own program, which is precisely why this
belongs to FR-C4 rather than to `L4`.

#### Where it lives and how a defect is catalogued

`tests/canonical/fixtures/review-recall/` — the location `tests/canonical/fixtures/<name>/` that
`.aid/knowledge/test-landscape.md § Test Data Strategy` already documents for curated inputs, with
ten sibling directories on disk today (`ls tests/canonical/fixtures | wc -l` → `10`). Each defect is
**one catalogue row plus one fixture file** whose content carries the seeded defect, and the row's
`signature` is a phrase that appears in the fixture and nowhere else in the repository —
checkable, and worth checking, because a signature that also matches real content makes both the
recall figure and the class sweep wrong. The suite asserts that for every row:
`grep -rl "$signature" --exclude-dir=fixtures .` must be empty.

**The corpus never lives in the reviewed tree.** Seeding a defect into `canonical/` to see whether
a review finds it would violate `F-06` of `test-landscape.md` ("A suite never mutates the source
tree") and would mean shipping a known defect. Fixtures are reviewed *as fixtures*: a cycle under
measurement is dispatched with the fixture set as its `ARTIFACTS`, which is an ordinary dispatch
against an unusual artifact list, not a new review path.

#### What recall is computed over

For a measured cycle: **recall = found / seeded**, where a seeded defect counts as `found` when the
cycle's ledger has a row whose `Status` ∈ {`Pending`, `Recurred`}, whose `Doc` equals
`expected_doc`, and whose `Description` or `Evidence` contains the `signature`. Grouped by the
`criterion` column's scope prefix for the per-rule-set figures, plus one `ALL` row.

**Status-awareness is the whole of the matching design, and the trap is measured.** A naive
phrase match counts a row that a *previous* cycle found and this cycle merely confirmed. On the
live ledger, matching the phrase `1168`:

```bash
L=.aid/.temp/review-pending/specify-feature-001.md
grep -c '1168' "$L"                                                    # 1  -- naive: "found"
awk '{ line=$0; gsub(/\\\|/,"\x1e",line); n=split(line,c,"|")
       if (n>=8 && c[3] ~ /\[/) { st=c[4]; gsub(/ /,"",st)
           if ((st=="Pending" || st=="Recurred") && (c[7] ~ /1168/ || c[8] ~ /1168/)) k++ } }
     END { print k+0 }' "$L"                                           # 0  -- status-aware
```

Both rows are `Fixed`, so a naive recall over this ledger reports a find for a cycle that found
nothing new. `1` versus `0` on a two-row ledger; the error grows with the ledger.

#### What makes a recall regression a defect — and the one thing this SPEC cannot decide

FR-C4 says a recall regression *is* a review-subsystem defect. Making that gradeable runs into a
rule this stack enforces hard: `aid-reviewer` — *"A finding that cites no `id`, or an `id` that
resolves nowhere, is itself a defect — it means you invented a criterion."* A recall drop has no
criterion to cite today. Two admissible routes, and the choice is not this SPEC's:

1. **Allocate a criterion id** in `.aid/knowledge/authoring-conventions.md`, in an existing
   scope-prefix namespace at the next free number, recorded with the delivery — the id-namespace
   rule feature-001 fixed. Then a drop is an ordinary finding with a declared band, and FR-C4's
   "is a defect" is literally true. **No id is allocated in this SPEC** — allocation is task work,
   and inventing one here is exactly what the rule forbids.
2. **Route it as tech-debt** — the report prints the drop, and it lands in `tech-debt.md` /
   `backlog.md` rather than a ledger. Cheaper, and consistent with FR-C6's observe-only boundary,
   but then "regression is a defect" is a process statement rather than a gate.

Route 1 is the recommendation, because FR-C4's wording asks for a defect and Route 2 delivers an
observation. Recorded in § Open as the owner's call.

#### NFR-3 — the measured re-derivation the script removes

The script is `tests/review-recall.sh`, a sibling of `tests/review-cost-meter.sh`: same directory,
same `record` / `report` subcommand style, same `--data` override so tests never touch live data,
bash + awk only, exit codes `0` success / `1` refusal / `2` usage, and the header block
`.aid/knowledge/coding-standards.md § File Header Convention` requires.

**What it removes, stated as a quantity with its command.** Without it, recall is re-derived by
hand every cycle: for a catalogue of `K` rows against a ledger of `R` rows, `K × R` pair checks,
over a read surface of `wc -c catalog.tsv` + `wc -c <ledger>` bytes per cycle — the same "declared
read surface" quantity `review-cost-meter.sh` defines, which is why that tool is cited and not
re-implemented. Today the measurable half is the ledger side: `wc -c .aid/.temp/review-pending/specify-feature-001.md`
→ `2149` bytes for `R = 2`.

**And it removes a re-derivation that is not merely tedious but wrong by default:** the naive match
above reports `1` where the correct answer is `0`. That is the AC-5 form — "or equivalent command
cited" — and it is the same shape feature-001 used for its audit script, because the cost meter
measures a dispatch brief, not what a check script costs.

**The floor, stated so the script can fail to justify itself.** The full figure is taken at the
task, on the corpus as built, with the command above. If `K` is small enough that the manual
computation is cheaper than the script's upkeep, **the script does not merge and the corpus is
measured by hand** — a legitimate outcome that must be recorded rather than padded around.
`Prose Over Scripts` (`.aid/knowledge/authoring-conventions.md`) and FR-A4's default-delete
disposition both point the same way.

---

### The Class Sweep (FR-C5)

#### F1 already says it; nothing records it

`canonical/skills/aid-execute/references/state-fix.md` `F1` is titled *"A finding is a CLASS, not
the line it was reported on"* and instructs: *"grep the defect's signature across the repository
before declaring it fixed."* Verified present:
`grep -c 'grep the defect.s signature across the repository' canonical/skills/aid-execute/references/state-fix.md`
→ `1`. So the sweep is law. What is missing is everything that makes it checkable — the command,
its output, and a demonstration that the sweep actually reaches a second instance.

#### Where the record lives

**In the fix commit message, as a trailer.** Three reasons, in order:

1. Git is this project's declared history mechanism — the same argument FR-B7 makes when it deletes
   in-document changelogs. A sweep record is history the moment the fix lands.
2. It survives the work folder. `CLAUDE.md` § Tracking discipline: work folders "may be pruned once
   the work ships", and no permanent artifact may depend on one. A sweep record inside
   `.aid/works/**` is deleted with the work; a commit trailer is not.
3. It needs no schema change. The alternative homes are closed or wrong: `quick_check.findings[]`
   has a fixed field set (§ Data Model), and the fixer is forbidden from writing the ledger at all
   (`reviewer-ledger-schema.md § Authoring rules for the fixer`).

The trailer is three fields, and the schema's existing instruction to *"cite the row `#` in commit
messages"* is what it extends:

```
fix row #2: <one line>

Sweep-class: <the class, in the words the Evidence used>
Sweep-command: grep -rn '<signature>' <paths>
Sweep-residue: 0   (was N before the fix)
```

**Recorded is not the same as trusted.** The point of storing the command rather than a claim is
that a reviewer verifying `Fixed` re-runs it: `git log -1 --format=%B` gives the command,
re-running it must still return the recorded residue. A sweep whose command no longer reproduces
its residue is a `Recurred` row, not a bookkeeping nit.

#### The seeded second instance AC-10 demands

AC-10 requires that a second instance of the same class be *"found by that sweep rather than by the
next review cycle"*. That is an assertion about the sweep's reach, and it is testable without a
live cycle: the corpus carries **two** fixtures sharing one `class` and one `signature`, only one
of which any ledger row names. The assertion, in `tests/canonical/test-scoped-review-cycles.sh`
(which already declares `COVERS:` both changed templates and already owns the seeded-defect
harness — a second suite would split one subject across two files):

1. a ledger row names instance A only;
2. running the row's `Sweep-command` over a `mktemp -d` copy of the corpus returns **both** A and B;
3. after a fix applied to A alone, the sweep's residue is **1**, not `0` — so a fix that closes the
   Description alone cannot record a clean sweep;
4. after both, residue `0`.

Step 3 is the one that gives the test teeth. A suite that only checks the clean case would pass on
a sweep that finds nothing at all — the vacuous-pass failure `S3` of `test-landscape.md` exists to
prevent, and the same failure feature-001's audit guards against with its `distinct=0` rule.

---

### Observe-Only Boundary (FR-C6)

FR-C6 has three clauses. Two are already law; the delta is one clause plus one absence.

| Clause | State today | Command |
|---|---|---|
| a `VIOLATION` is an ordinary criteria finding in the same 7-column ledger, never a second ledger | **law** — `aid-reviewer` maps exit `1` to "one finding per `VIOLATION <path>` line — criterion `id` as the `Description` prefix", then "No column is added; the ledger keeps its 7-column shape" | `grep -c 'No column is added' canonical/agents/aid-reviewer/AGENT.md` → `1`; `test-criterion-oracles.sh` `OR18` already asserts it |
| a non-verdict is not a finding | **law for `UNDECIDED`, absent for observe-only output** — the contract prices `UNDECIDED` ("Normal, not a failure") and degradation ("never let a degraded oracle read as a pass, and never file it as a violation"), but says nothing about a check that emits **no verdict at all** | `grep -c 'Normal, not a failure' canonical/agents/aid-reviewer/AGENT.md` → `1` |
| only an open criteria gap may block a grade for a missing rule | **absent** | `grep -rl 'missing rule' canonical .aid/knowledge --include=*.md` returns no file |

**The delta, therefore, is a short addition to `frontmatter-schema.md § oracle:` — the contract's
single home — saying three things:** a check that emits no per-file verdict is **not** an oracle and
produces no ledger row (`tests/review-recall.sh` and `tests/review-cost-meter.sh` are both of this
kind); the absence of a rule is not itself a finding, because a finding must cite a criterion `id`
that resolves, so the only gradeable form of "there is no rule for this" is an **open criteria
gap** — a missing row in the criteria table, raised against that table, citing the criterion that
governs it; and an oracle's `VIOLATION` is consumed as an ordinary finding, which is restated
nowhere because `aid-reviewer` already owns it.

**Measured, so the boundary is not theoretical.** The one oracle on this tree observes far more
than it decides: `bash scripts/checks/g07-selector-partition.sh; echo "exit=$?"` → `exit=0` with
`76` `UNDECIDED` lines and `0` `VIOLATION` lines
(`grep -c '^UNDECIDED'`, `grep -c '^VIOLATION'` over its output). Under the boundary this is
correct and silent: zero ledger rows from 76 observations. Without the boundary written down, a
reviewer can reasonably read 76 undecided files as 76 gaps.

**No second ledger, and no second grade path.** FR-C4's recall report is the obvious candidate for
becoming one, and this is where it is refused: it prints a measurement, writes its own `.tsv`, and
emits no ledger row. If a recall drop is to become gradeable it happens through a criterion `id`
(§ The Seeded-Defect Corpus, Route 1), inside the one 7-column ledger, and never as a parallel
artifact `grade.sh` would have to learn to read.

---

### Claim-Level Coverage (FR-C3)

FR-C3 is a SHOULD, conditional on file-scoped HUNT being "not enough". The condition is
**measurable**, and it was met on this work's own most recent review.

#### The insufficiency test

**A file-scoped hunt has nothing to scope when the artifact set is one file: the HUNT set equals
the VERIFY set.** Measured on the two review cycles this work has recorded:

```bash
bash tests/review-cost-meter.sh report
# excerpt -- the two rows with a ratio, columns side=/rows= elided;
# a third task (work-013-requirements) has one cycle and so reports ratio=n/a
# work-013-cross-ref                                cycles=2  ratio=1.022
# specify-feature-001-single-review-path-alignment   cycles=2  ratio=2.021
```

The multi-artifact review scoped almost perfectly (`1.022`). The single-file review reports
`2.021`, and the reason is worth stating precisely rather than presenting as reader cost: the
cycle-2 brief names the **same path in both lists**, and the meter's extractor emits it twice, so
the surface is counted twice — `2 × 42467 = 84934`, exactly the recorded figure.

```bash
B=.aid/works/work-013-review-stack-completion/briefs/specify-feature-001-single-review-path-alignment-cycle-2.md
S=.aid/works/work-013-review-stack-completion/features/feature-001-single-review-path-alignment/SPEC.md
wc -c "$S"                                    # 42467
awk -F'\t' '$1 ~ /specify-feature-001/ {print $2, $4}' \
    .aid/works/work-013-review-stack-completion/review-cost.tsv   # 1 42034 / 2 84934
```

So the honest reading is a **double count, not a doubling of work** — and that double count is the
symptom FR-C3 names. Two facts follow, both from the brief on disk:

1. The brief author **already** had to express the hunt as a sub-file region, because the
   file-scoped unit could not: its HUNT entry reads *"§ PR Hygiene … and § The Closing Audit … the
   only two regions the cycle-1 FIX touched."* Claim-level coverage is already happening, in prose.
2. That prose is **invisible to measurement**. The meter's `brief_artifacts` extractor keeps only
   lines that are a single bare token, so the region qualifier is dropped and the entry degrades to
   the whole file. Verified by running that awk over the brief: it emits the same path twice and
   nothing else.

#### The unit, and the two changes it needs

A coverage unit becomes `<path>` **or** `<path> § <heading>` — a path plus a grep-recoverable
heading anchor, which is the citation form `.aid/knowledge/authoring-conventions.md § Citation Rule
(Durable Anchors)` already mandates for every citation in this project. No new notation is
introduced: a unit is cited the way everything else is cited, so a reader and a script resolve it
the same way. A worklist unit — a ledger row, a criterion `id` — is the degenerate case where the
subject is not a file region at all; it is written as the row `#` or the `id`, and the VERIFY set
already works this way (it is built from `Doc` values, not from a scan).

1. `reviewer-dispatch.md § ARTIFACTS UNDER REVIEW` states the unit form, and states the trigger:
   when the VERIFY and HUNT lists would name the same path, HUNT names regions.
2. `tests/review-cost-meter.sh` counts a path **once per cycle** even when it appears in both
   lists, and attributes a `§`-qualified entry to its file. Note plainly: this is a change to a
   measurement tool, so under NFR-4 every previously recorded figure keeps its meaning only if the
   change is recorded — the fix is forward-only, the existing rows stay as measured, and the
   `.meta` run id is what distinguishes them.

**The demonstration the criterion asks for** is this very SPEC's own review: a cycle-2 brief for
feature-003 whose HUNT names regions rather than the whole SPEC, with the recorded surface no
longer double-counting. That is one dispatch, on a review that is going to happen anyway.

---

### Render & Parity (NFR-2 / AC-11)

Seven of the changed paths are under `canonical/`, so the render is not optional here (unlike
feature-001, where three of four changed files sat outside it).

1. Edit `canonical/` only. Never `profiles/`, `.claude/`, `.cursor/`.
2. Run the **full** generator — `python .claude/skills/generate-profile/scripts/run_generator.py` —
   not a per-script renderer, because a partial render leaves stale emission manifests and CI
   `render-drift` fails (`.aid/knowledge/architecture.md` § Gotchas).
3. **VERIFY (deterministic) must report PASS** —
   `python .claude/skills/generate-profile/scripts/verify_deterministic.py --canonical-root .` —
   a non-zero exit aborts before REPORT (`.claude/skills/generate-profile/SKILL.md` § Mode: VERIFY).
4. Resync the dogfood trees by regeneration, then confirm no hand-edit survived: `git diff --name-only`
   over `profiles/ .claude/ .cursor/` must contain only paths the generator wrote.
5. `.aid/knowledge/INDEX.md` is regenerated with
   `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
   if any frontmatter field this feature touches feeds a routing column — never hand-edited.

**The base ref (NFR-1, and `Q1`).** `Q1` is right that a bare `git diff` is vacuous. The base is
**the branch tip recorded at the start of this feature's first task** (`git rev-parse HEAD`, written
into the delivery record before any edit) — `2d0fb40dd` if execution starts at this SPEC's approval —
for the reason feature-001 gives and this SPEC does not restate: `master` moves, so a criterion
based on it silently re-scopes itself. Measured today, against both candidates:

```bash
git diff --stat 2d0fb40dd HEAD -- canonical/aid/scripts/grade.sh \
    canonical/aid/templates/reviewer-ledger-schema.md | wc -l          # 0
git diff --stat origin/master HEAD -- canonical/aid/scripts/grade.sh \
    canonical/aid/templates/reviewer-ledger-schema.md | wc -l          # 0
```

**The reading of criterion 8 for this feature specifically.** `grade.sh` is not edited, so its diff
stays empty and that is checked as an empty diff. `reviewer-ledger-schema.md` **is** edited, so its
diff will not be empty and only `Q1`'s second disjunct means anything: *the diff touches neither
counting logic nor column shape.* That is verified three ways rather than by reading the diff —
the header row is unchanged (`grep -c '^| # | Severity | Status | Doc | Line | Description | Evidence |'`
→ `1`), the enums and status table are unchanged, and `test-scoped-review-cycles.sh` `SC15` still
prices the same fixtures at `A+` / `B+` / `D+`. A behavioural assertion is the right instrument
here for a reason that suite records against itself: an earlier version proved `C-3` by diffing
`grade.sh` against `origin/master` and *"passed locally and FAILED IN CI: a shallow clone has no
such ref"*.

---

### Verification — criterion by criterion

Every row is a command, or says plainly that nothing mechanical decides it.

| This SPEC's criterion | How it is checked |
|---|---|
| **1** — every `Description` carries a why-line; a diverging severity says so in `Evidence`; the row count is reported | the why-line screen in § The Why-Line, run on the cycle's real ledger: `rows=N why-line=N missing:` empty, `no-provenance:` empty. Residue rows, if any, are read and reported with their numbers. Today's baseline on the last real ledger: `rows=2 why-line=0`. |
| **2** — a new cycle cannot reach the prior cycle's ledger; the attempted path and its failure are documented | the three attempts in § Structural Clean Context, with their exit codes, recorded with the delivery; plus `bash tests/canonical/test-ledger-isolation.sh` → the literal-path canary at `0` and the preflight failing on a seeded leftover. |
| **3** — the recall report produces a figure per rule set and overall, and its output is recorded | `bash tests/review-recall.sh report --ledger <path>` → one row per criterion scope prefix plus `ALL`, each printing `seeded` and `found`, with a `seeded=0` group reported as **missing**. stdout pasted into the delivery record. |
| **4** — a FIX closes with its sweep command and output recorded, and a seeded second instance was found by the sweep | `git log -1 --format=%B <fix-commit>` carries `Sweep-class` / `Sweep-command` / `Sweep-residue`; re-running the recorded command reproduces the recorded residue; `bash tests/canonical/test-scoped-review-cycles.sh` asserts the four sweep steps, including residue `1` after a single-instance fix. |
| **5** — a coverage unit may be a region or worklist item, demonstrated on one review | the cycle-2 brief for this feature names `<path> § <heading>` entries under HUNT (`grep -c ' § ' <brief>` ≥ 1), and its `review-cost.tsv` row no longer equals `2 ×` the file size. The insufficiency it answers is the measured `2.021` / `84934` figure above. |
| **6** — an observe-only check emits no ledger row; a missing rule blocks only as an open criteria gap; a `VIOLATION` is an ordinary finding in the one ledger | `bash scripts/checks/g07-selector-partition.sh` → `exit=0`, `76` `UNDECIDED`, `0` `VIOLATION`, and zero ledger rows from that run; `bash tests/canonical/test-criterion-oracles.sh` → `OR18` (7 columns, no new column) still passes alongside the new observe-only assertions. |
| **7** — a proposed script cites a measurement of the re-derivation it removes | for `tests/review-recall.sh`: the naive-versus-status-aware block in § The Seeded-Defect Corpus reproduces `1` and `0`, and the `K × R` + `wc -c` figure is taken on the built corpus with the command given there. If the figure falls below the stated floor the script does not merge — recorded as a discharge, not a skip. |
| **8** — `grade.sh` and the ledger schema unchanged in counting logic and column shape; render byte-identical | `git diff <recorded-base> HEAD -- canonical/aid/scripts/grade.sh` → **empty**; for the schema, the three checks in § Render & Parity (header row, enums, `SC15` behaviour); the two pinned-literal greps in § The Why-Line still return `95` and `2`, and `OR18`'s suite now declares `AGENT.md` so the selector reaches it (`0` → `1`); `verify_deterministic.py` → `PASS`; `git diff --name-only` over `profiles/ .claude/ .cursor/` contains only generator-written paths. |
| **9** — every count re-derives | every count in this SPEC and in the delivery record carries its command inline; re-running each reproduces the figure. |

**No declared criterion reaches this SPEC.** The type registry bounds its corpus to the markdown
under `canonical/skills/`, `canonical/agents/`, `canonical/aid/templates/` and `.aid/knowledge/`, so
a `.aid/works/**/SPEC.md` resolves to no registry type, inherits no type-level criteria, and does
not violate `G-07` (it is not in scope). That gap is FR-B5's subject and belongs to feature-002.
Until it closes, this SPEC is reviewed against its own acceptance criteria and
`.aid/knowledge/artifact-schemas.md § Feature SPEC.md` — stated so a reviewer does not cite an id
that cannot reach it, and measured: on the last real ledger, `2` of `2` rows had to say the same
thing in their `Description`.

---

### Routed Findings — real, measured, and deliberately not fixed here

| Finding | Evidence | Route |
|---|---|---|
| `tests/review-cost-meter.sh` over-reports a cycle whose VERIFY and HUNT lists name the same path — it counts the file twice | `2 × 42467 = 84934`, exactly the recorded cycle-2 surface; the extractor emits the path twice (commands in § Claim-Level Coverage) | **This feature, under FR-C3** — it is the measurable symptom of the file-scoped unit. Recorded here too because it also means the one recorded `2.021` ratio must not be read as reader cost. |
| `test-landscape.md § Running only the suites a change can affect` (line 618) says "No suite currently carries a `COVERS` header, so all 135 suites are selected fail-safe on any change" — both halves are false | `grep -rl '^# COVERS:' tests/canonical/test-*.sh` returns four files — `test-criterion-oracles.sh`, `test-review-cost-meter.sh`, `test-scoped-review-cycles.sh`, `test-validator-behavior.sh` — and the suite count is `139`, not 135 (both counts in the fenced block below the table) | **KB drift, not this feature's.** Route to feature-002's FR-B7/`Q2` sweep or to `tech-debt.md`. Worth one note for whoever fixes it: `135` is now accidentally right for the wrong reason — the selector reports "selected 135 of 139 suite(s); 4 not affected", so 135 is the count of *headerless* suites selected fail-safe, not the total. A fix that only bumps 135 to 139 would make the sentence more wrong, not less. It matters to this feature because the two suites it extends are among the four that *do* carry a header — which is what makes their headers load-bearing, and what makes the incomplete-header class above a real hazard rather than a tidiness point. |
| `aid-discover/references/state-fix.md` hard-codes one ledger path and `aid-update-kb` duplicated an entire FIX loop rather than parameterise it | the § 4(d) quotation and `grep -n 'review-pending' canonical/skills/aid-discover/references/state-fix.md` → 1 line | **Half in scope.** FR-C2 parameterises the path here; **retiring the duplicated loop is not in scope** and is a follow-up once `{{LEDGER}}` exists. |
| A `.aid/.temp/` ledger was once committed and had to be untracked | `git log --oneline --all -- .aid/.temp` → `2` commits, incl. `d14284bc3` "untrack .aid/.temp file caught by recovery (fixes KB-hygiene CI gate)" | **No action — cited as evidence.** It is why L3's structural claim rests on the CI step rather than on `.gitignore`. |
| The criteria table cannot express an `oracle:` — its header is six columns with no oracle cell, though the section's prose promises the key | feature-001 measured this and routed it; unchanged here (`grep -cn '^. ID . Applies to' .aid/knowledge/authoring-conventions.md` → `1`, the six-column header at line 192; the pattern uses `.` for the pipes so the command survives inside this cell) | **feature-001's routed finding, restated only because FR-C6 reasons about oracles.** This feature adds **no** `oracle:` and needs no `Oracle` column: its three new scripts are observe-only by design (§ Observe-Only Boundary). |
| The incomplete-`COVERS:`-header class has residue this feature does not fix: `test-validator-behavior.sh` omits `summarize/grade-summary.sh` and `.aid/knowledge/kb.html`; `test-scoped-review-cycles.sh` omits `canonical/skills/**` | the sweep table and its two selector checks in § The Why-Line, both returning `0` | **Routed with the residue named, which is the point.** Two of the five instances are fixed here (`AGENT.md`, `grade.sh`) because this feature's own criterion 8 depends on those two suites being reached. The rest goes to `tech-debt.md`: summarize is outside T3, and declaring `canonical/skills/**` is a run-cost trade for the repo to make, not this feature. Recorded as a **non-zero sweep residue** rather than a clean sweep — exactly the honesty § The Class Sweep requires of a `FIX`, applied to this SPEC's own finding. |
| A leftover ledger for another feature is on disk right now | `ls .aid/.temp/review-pending/` → `specify-feature-001.md` | **Evidence for FR-C2, not a finding against anyone.** It may be a live mid-invocation ledger or a survived DONE; either way the *reachability* is what FR-C2 addresses, and no claim is made here about which it is. |

The two counts behind row 2, which need a real shell pipeline and so are not written in a cell:

```bash
grep -rl '^# COVERS:' tests/canonical/test-*.sh | wc -l    # 4  (the KB says "no suite")
ls tests/canonical/test-*.sh | wc -l                       # 139 (the KB says 135)
```

### Open — not decided by this SPEC

- **`Q8` is Pending and stays Pending.** This SPEC supplies the grep `Q8` asks for and states its
  limit — a command decides the why-line's **form**, and the residue is read for substance. Both
  readings of §9 AC-9 are satisfied by criterion 1 as written ("measured by the cited command …
  the row count is reported"), so nothing here forces the owner's hand. If the owner re-words AC-9
  to "measured by a grep", the sentence about the semantic half must go with it, or the criterion
  starts asserting something the grep cannot decide.
- **`Q9` is Pending and stays Pending.** The two synthesized criteria (FR-C3, FR-C6) are the last
  two in § Acceptance Criteria, and this SPEC makes both verifiable rather than leaving them as
  prose: criterion 5 has a measured insufficiency trigger and a brief-level check, criterion 6 has
  three clauses each with a command. **Confirming them is the owner's call, and so is `Q9`'s other
  branch — dropping FR-C3 or FR-C6 outright.** If FR-C3 is dropped, the measured double-count
  finding still needs a home (routed above). If FR-C6 is dropped, the recall report has no written
  boundary keeping it out of the ledger, and § The Seeded-Defect Corpus Route 2 becomes the only
  route for a recall drop.
- **`Q1` is Pending.** This feature is the one that makes AC-11's wording matter: it edits
  `reviewer-ledger-schema.md`, so the "`git diff` is empty" disjunct is simply false here and only
  the second disjunct can be applied. § Render & Parity states how it is checked.
- **Whether a recall regression gets a criterion `id`** is the owner's, per § The Seeded-Defect
  Corpus. No id is allocated in this SPEC.
- **The corpus size** is not decided here. The catalogue's columns, the matching rule, the
  signature-uniqueness check and the two-instance requirement are fixed; how many defects are
  seeded, and whether the resulting `K` clears NFR-3's floor, is task work — and a corpus too small
  to justify the script is a legitimate outcome to record.

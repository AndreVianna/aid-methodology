# Coverage Gate Completion

## Source

- REQUIREMENTS.md §4 Scope — T2 Gaps
- REQUIREMENTS.md §5 Functional Requirements — FR-B1 … FR-B7
- REQUIREMENTS.md §6 Non-Functional Requirements — NFR-1 … NFR-4
- REQUIREMENTS.md §7 Constraints
- REQUIREMENTS.md §9 Acceptance Criteria — AC-3, AC-5, AC-7, AC-11, AC-12
- REQUIREMENTS.md §10 Priority — item 2

## Description

Once the review stack is single, the question becomes what it still does not look at.
Six things are unwatched today, and each is a place where a defect can ship without
anything firing.

The project's own settings file has no check that runs on its own — it is read by every
skill and validated by none. A frontmatter linter exists but nothing proves it is
actually wired into a runtime gate, so it may be passing because it never runs. The
generated Knowledge Base tour, `kb.html`, is checked only for having been built; nothing
reads what it says. Delivery blueprints and specify reviews are not on the standard
ledger and grading path. Citation and quote accuracy is checked for Knowledge Base docs
but not for the artifacts a work produces. And a second grading backend still coexists
with the one that produces the letter grade.

The seventh item removes a finding class rather than watching it. A hand-maintained
history table inside a document drifts from git the moment one edit skips a row, and
reviewers then spend cycles on the drift instead of on the artifact. This feature keeps
the rule enforced and makes sure no template, skill, or fixture authors such a section.

Every gate here has to prove it fires. A gate that passes because it never runs is worse
than no gate, so each ships with a fixture that fails before the change and passes
after, or a before-and-after measurement.

## User Stories

- As a maintainer, I want `.aid/settings.yml` checked by a script that passes or fails on its own, so that a malformed settings file is caught before a skill reads it.
- As a maintainer, I want proof that the frontmatter linter actually runs in a gate, so that a clean result means "checked" rather than "not looked at".
- As the owner, I want someone to read what `kb.html` actually says, so that a Knowledge Base tour that builds successfully but reads wrongly does not ship.
- As a pipeline skill, I want blueprint and specify reviews on the same 7-column ledger and `grade.sh` path as every other review, so that one grading contract covers every phase.
- As the reviewer agent, I want citation and quote accuracy checked on work artifacts too, not only Knowledge Base docs, so that a misquoted requirement is a finding wherever it appears.
- As the owner, I want one backend producing the letter grade, so that two paths cannot report two different grades for the same work.
- As a maintainer, I want no artifact to carry its own history section, so that reviewers stop spending cycles on drift that git already records correctly.

## Priority

Must

## Acceptance Criteria

> Each criterion carries the modality of the requirement it discharges. FR-B6 is SHOULD
> in §5 and its criterion stays SHOULD here.

- [ ] **MUST** — Given each of the five gates this feature adds or wires (the mechanical settings gate, the wired frontmatter lint, the `kb.html` content review, **`BLUEPRINT.md`** on the 7-column + `grade.sh` path, and citation/quote checks covering work artifacts), when the gate is exercised, then a fixture fails before the change and passes after, or a before/after measurement shows the gate firing. *(discharges FR-B1, FR-B2, FR-B3, FR-B4, FR-B5; §9 AC-3)*

  > **Q6 answered 2026-08-17: FR-B4 is narrowed to `BLUEPRINT.md`.** Nothing named
  > `per-section` is a review mechanism, and the specify per-FEATURE review is already on
  > the `grade.sh` path (`canonical/skills/aid-specify/references/state-review.md`), so
  > that half needs no work. The criterion above carries the narrowed wording.
- [ ] **SHOULD** — Given the summary grading path, when the single-backend change is made, then `grade.sh` is the sole letter producer and the change carries the same fixture or before/after proof as the gates above. *(discharges FR-B6; §9 AC-3 conditional tail)*
- [ ] **MUST** — Given the repository, when the history-section sweep is run over the authored trees, then no artifact-authoring instruction, template section, or fixture authors a `## Change Log`, a `## Revision History`, or a `changelog:` field — only the rule text that forbids one. *(discharges FR-B7; §9 AC-7)*
- [ ] **MUST** — Given a script proposed by this feature — the settings gate in particular — when it is merged, then it cites a measurement of the re-derivation it removes. *(discharges NFR-3; §9 AC-5)*
- [ ] **MUST** — Given this feature's changes, when `grade.sh` and `reviewer-ledger-schema.md` are diffed against the work's base commit, then neither counting logic nor column shape has changed; and `generate-profile` re-renders byte-identically with VERIFY deterministic PASS, with no hand-edit in `profiles/` or the dogfood trees. *(discharges NFR-1, NFR-2; §9 AC-11)*
- [ ] **MUST** — Given any count stated in this feature's artifacts, when the cited command is re-run, then it reproduces the number. *(discharges NFR-4; §9 AC-12)*

---

## Technical Specification

> **How to read the counts.** NFR-4 requires every stated count to carry the command that
> produced it. Every figure below is followed by its command, run from the worktree root at
> `HEAD` = `2d0fb40dd`. Commands are written **pipe-free wherever possible** so they can be
> copied out of a table and run verbatim; where a shell pipeline is genuinely needed it is
> shown in a fenced block instead of a cell, per feature-001's § Doc-Law Alignment convention.
> Any command naming `master` means `origin/master` and is run after `git fetch origin master`;
> verified `git rev-parse master origin/master` → one sha, `aef150fe8`.
>
> **Section shape.** The three core sections of
> `canonical/aid/templates/specs/spec-template.md` are kept and marked `N/A` where they
> genuinely do not apply, so the schema in
> `.aid/knowledge/artifact-schemas.md § Feature SPEC.md` still resolves; the sections that
> carry the work follow them.
>
> **Relation to feature-001.** That SPEC owns the *singleness* of the review stack. This one
> owns its *coverage*. Where the two touch — `reviewer-dispatch.md`'s own in-document
> changelog, the work-artifact registry gap it routed here — this SPEC picks the finding up at
> the reference feature-001 recorded and does not re-derive it.

### Data Model

**N/A.** This repository persists no data — it ships markdown skills, agents and templates
rendered into five install trees, plus bash scripts and bash test suites
(`.aid/knowledge/project-structure.md` "Unusual Structure Notes") — and this feature adds no
schema, table or record. The nearest thing to a schema it touches is `.aid/settings.yml`, a
config file; it is specified in § FR-B1 rather than here, because what changes is a validator,
not a persisted shape.

### Feature Flow

**N/A as a runtime path.** No state machine or dispatch sequence is redesigned. Two existing
states gain one script invocation each (`aid-discover` GENERATE Step 5a for FR-B2, § FR-B5 for
the citation lint's scope), and those are specified in place at the gate that changes. The
dispatch flow itself — brief to a file, then dispatch and record from that file — is unchanged
in `canonical/aid/templates/reviewer-dispatch.md § Brief generation`.

### Layers & Components

**N/A as layering** — no application layering, no DI, no service/repo split. The equivalent
structural statement is § Artifacts & Surfaces below, which names every file that changes and
every tree that must never be hand-edited.

---

### Artifacts & Surfaces

**Authored, in scope to change:**

| Path | Why it changes | Registry type |
|---|---|---|
| `canonical/aid/templates/settings.yml` | FR-B1 — has no `format_version` key at all, so a fresh install starts un-versioned | `template-payload` |
| `.aid/knowledge/artifact-schemas.md` § settings.yml | FR-B1 — documents 6 keys that do not resolve, and a grade domain `grade.sh` cannot emit | `kb-doc` |
| `canonical/skills/aid-discover/references/state-generate.md` § Step 5a | FR-B2 — the file that already names `lint-frontmatter.sh` as the gate it should model | `skill-reference` |
| `canonical/aid/scripts/kb/kb-citation-lint.sh` | FR-B5 — `-maxdepth 1` makes any nested root a false green | outside the registry corpus |
| `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | FR-B7 — its generated-doc example teaches `changelog:` with no legacy marker | `template-payload` |
| `canonical/aid/templates/feedback-artifacts/IMPEDIMENT.md` | FR-B7 — carries a live `## Revision History` section | `template-payload` |
| `canonical/aid/scripts/kb/build-metrics.sh` | FR-B7 — emits `changelog:` into the frontmatter it generates | outside the registry corpus |
| `docs/aid-methodology.md` | FR-B7 — carries `## Revision History`; the site copy is its generated mirror | outside the registry corpus |
| `examples/brownfield-{full,lite}-path/*` | FR-B7 — 5 hits; example artifacts teach the shape they show | outside the registry corpus |
| `canonical/skills/aid-summarize/references/state-manual-checklist.md`, `.../state-generate.md` | FR-B6 — each asserts a `grade.sh` capability `grade.sh` does not have | `skill-reference` |
| `canonical/aid/scripts/summarize/grade-summary.sh` | FR-B6 — emits three letter grades on an alphabet disjoint from `grade.sh`'s | outside the registry corpus |
| `tests/canonical/test-kb-template-authoring-standard.sh` | FR-B7 — `AS03`/`AS03b` are the right check over the wrong corpus | outside the registry corpus |
| `tests/canonical/test-frontmatter-lint.sh` | FR-B2 — `FL19` cannot distinguish "clean" from "checked nothing" | outside the registry corpus |
| `scripts/checks/settings-schema-check.sh` (new) | FR-B1 — the mechanical settings gate | outside the registry corpus |
| `tests/canonical/test-settings-schema-check.sh` (new) | AC-3 proof for FR-B1; discovered by glob, so `tests/run-all.sh` needs no edit (`tests/run-all.sh` "Discovers suites by glob") | outside the registry corpus |

**Generated — never hand-edited (NFR-2), and the set is larger than the four trees usually
named.** NFR-2 is normally cited as `profiles/`, `.claude/`, `.cursor/`, `site/src/data/`.
Measured, `site/src/content/` holds **two further generated regions**, and FR-B7's sweep lands
in both:

| Generated region | Producer | Size |
|---|---|---|
| `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/`, dogfood `.claude/` + `.cursor/` | `run_generator.py` | 5 profiles + 2 dogfood trees |
| `site/src/data/skill-flows/*.flow.json` | `site/scripts/gen-skills.mjs` | 111 files rewritten on a run (`ls site/src/data/skill-flows/*.flow.json \| wc -l` → `111`) |
| `site/src/content/docs/skills/*.md` + `index.md` | `site/scripts/gen-skills.mjs` | 111 pages + 1 index |
| `site/src/content/docs/{concepts,reference}/*.md` (4 synced docs) | `site/scripts/sync-docs.mjs` | 4, each carrying `sourceDoc:` frontmatter naming its source under `docs/` |
| `.aid/knowledge/INDEX.md` | `build-kb-index.sh` | 1 |

`grep -cE "^\s+src: '" site/scripts/sync-docs.mjs` → `4` (the quote in the pattern matters:
`grep -cE '^\s+src:'` returns `5`, the fifth being the template literal `src: \`docs/${e.src}\``
at `:315` inside the copy loop, not a synced doc); the generator's own run reports
`parsed 111 skills` / `wrote 111 pages`; `head -4 site/src/content/docs/concepts/methodology.md`
shows `sourceDoc: 'docs/aid-methodology.md'`. **Consequence for FR-B7:** the single
`## Revision History` under `site/src/content` is a *mirror*, fixed by editing
`docs/aid-methodology.md` and re-running the sync — never by editing the mirror.

**`.aid/knowledge/kb.html` is generated and is not in the registry corpus at all.** The corpus
is bounded to *markdown*: "the in-scope corpus — the markdown under `canonical/skills/`,
`canonical/agents/`, `canonical/aid/templates/` and `.aid/knowledge/`"
(`.aid/knowledge/authoring-conventions.md:107-108`). `kb.html` is HTML, so `G-07` does not
reach it and no type-level criteria resolve for it. This is `Q3`'s subject and is specified,
not resolved, in § FR-B3.

---

### Gate-by-gate specification

#### FR-B1 — a mechanical gate on `.aid/settings.yml`

**What is actually wrong.** Not that the file is malformed — it parses — but that the
*schema of record* and the file have drifted apart in both directions, and nothing notices.
`read-setting.sh` resolves a documented 2-level path onto the file's flat storage
(`review.minimum_grade` → `minimum_grade`), so the drift is absorbed at read time and stays
invisible. Probing all 12 keys `artifact-schemas.md § settings.yml` documents:

```bash
R=canonical/aid/scripts/config/read-setting.sh
for k in project.name project.description project.type tools.installed review.minimum_grade \
         execution.max_parallel_tasks traceability.heartbeat_interval kb_baseline.branch \
         kb_baseline.tip_date discovery.doc_set discovery.closure.max_rounds triage.large_min_dirs; do
  printf '%-32s %s\n' "$k" "$(bash "$R" --path "$k" --default ABSENT 2>&1 | head -c 40)"
done
```

**6 of 12 resolve; 6 report `ABSENT`** — `tools.installed`, `execution.max_parallel_tasks`,
`kb_baseline.branch`, `kb_baseline.tip_date`, `discovery.closure.max_rounds`,
`triage.large_min_dirs`. In the other direction, three keys the file *does* store are
documented nowhere: `source_control` (`git`), `knowledge.source` (`master`),
`knowledge.term_exclusions` (81 items) — same probe form, all three resolve.

Three findings sharpen this into a gate with real content:

1. **`format_version` is stale and untemplated.** `.aid/settings.yml:1` says `3`;
   `bin/aid:121` declares `readonly AID_SUPPORTED_FORMAT=4`; and
   `grep -c format_version canonical/aid/templates/settings.yml` → `0`, so a fresh install
   produces a file with no version at all. `bin/aid` warns rather than blocking, so this is
   latent, not breaking.
2. **The documented grade domain names a grade the grader cannot emit.**
   `artifact-schemas.md:338` says `review.minimum_grade` is "Valid: `A+..F`". `grade.sh` never
   emits `F` — `grep -c 'GRADE="F"' canonical/aid/scripts/grade.sh` → `0`; its letters are
   `A+ A A-` then `B/C/D/E` with a `modifier_for_count` suffix (`grade.sh:130-142`, `96-102`).
   A floor of `F` is therefore unreachable and would silently disable the gate.
3. **`kb_baseline.*` is documented, read by two skills, and absent — but safely.**
   `grep -rln kb_baseline canonical --include=*.md` → `aid-housekeep/references/state-summary-delta.md`
   and `aid-discover/references/state-done.md`; both carry an explicit absent-block fallback
   (`state-summary-delta.md:245-250`, the append-block idiom). **The gate must therefore not
   require it.** This is the distinction the gate is built on: it validates *required* keys and
   *value domains*, and is silent about optional-with-fallback keys.

**The gate.** `scripts/checks/settings-schema-check.sh` — repo-root-relative, outside
`canonical/` (the placement the oracle contract already uses for `scripts/checks/`), bash +
awk only, `LC_ALL=C`, deterministic, carrying the header block
`.aid/knowledge/coding-standards.md § File Header Convention` requires, and taking `--path` so
it can be run against a fixture. Four assertions — `S1`…`S4` are **this script's own assertion
labels**, in the style of `AS03`/`FL19` in the existing suites, and are deliberately **not**
criterion ids; this SPEC allocates no criterion id anywhere:

| # | Asserts | On failure |
|---|---|---|
| S1 | the file parses as the flat/2-level shape `read-setting.sh` actually supports, and every top-level key is either documented or listed as a known extension | exit 1, naming the key |
| S2 | `format_version` is present and equals `bin/aid`'s `AID_SUPPORTED_FORMAT` | exit 1 — `bin/aid` is the authority, so the check reads the value from it rather than hard-coding `4` |
| S3 | `minimum_grade` resolves and is a letter `grade.sh` can actually emit | exit 1 — closes finding 2 by construction |
| S4 | no key that `read-setting.sh` cannot reach (a 3-level path) is required by any skill | exit 1 — `discovery.closure.*` is the known instance, already documented as unreachable |

**Why it cannot pass vacuously** — the failure mode this whole feature exists to prevent. The
check counts the keys it validated and **exits 1 if that count is zero**, so a moved or renamed
settings file fails loudly instead of finding nothing and reporting green. It prints each
assertion's measurement beside its expectation, as feature-001's audit does.

**NFR-3 / AC-5 — the measured re-derivation this script removes.** Nothing validates settings
today, so the re-derivation it removes is not another script's — it is the **defensive default
restated at every call site**. Measured:

```bash
grep -rl 'read-setting.sh' canonical --include=*.md | wc -l                          # 39 files
grep -rho 'read-setting\.sh' canonical --include=*.md | wc -l                        # 68 invocations
grep -rnE 'read-setting\.sh.*--key minimum_grade' canonical --include=*.md | wc -l   # 29
grep -rnE 'read-setting\.sh.*--key minimum_grade' canonical --include=*.md \
  | grep -c -- '--default'                                                            # 28
```

**28 of 29 `minimum_grade` reads restate a fallback the file is never checked to satisfy — and
they do not agree.** The 28 split **26 × `--default A` and 2 × `--default A+`**:

```bash
grep -rhoE 'read-setting\.sh.*--key minimum_grade --default [A-Z][+-]?' canonical --include=*.md \
  | grep -oE '\-\-default [A-Z][+-]?$' | sort | uniq -c        # 26 "--default A", 2 "--default A+"
```

Both `A+` sites are `canonical/aid/templates/shortcut-engine.md` (lines 320, 723), against
`minimum_grade: A` in the file itself. A gate that guarantees the key exists and is valid is
what lets a call site stop carrying its own floor. Whether the Lite path's `A+` is intentional
is **not decided here** — see § Routed Findings.

#### FR-B2 — wire the frontmatter linter into a runtime gate

**The premise needs correcting before it can be specified, and the correction is the finding.**
The linter is *not* unwired. It runs in CI:
`.github/workflows/test.yml:150` — `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`.
What it lacks is a **runtime** invocation: no canonical skill or agent runs it. The only mention
inside a runtime state is parenthetical — `state-generate.md:863`, "(cf. `lint-frontmatter.sh`
for frontmatter)".

**And the KB claims otherwise.** `.aid/knowledge/authoring-conventions.md:497` lists the
frontmatter lint's enforcement as "Yes (lint)" directly beside the citation lint's "Yes (lint,
orchestrator-gated at GENERATE)" (`:498`), and `:478` instructs "run `lint-frontmatter.sh` +
`kb-citation-lint.sh` before done" as though the two were symmetric.

**They are the exact opposite of symmetric — each is covered precisely where the other is not:**

| | runtime gate | CI | currently |
|---|---|---|---|
| `kb-citation-lint.sh` | **yes** — `state-generate.md:850`, `agent-prompts.md:94` | **no** — `grep -rn kb-citation-lint .github/` → `0` | **failing: 8 violations** |
| `lint-frontmatter.sh` | **no** — 0 invocations; one parenthetical at `:863` | **yes** — `test.yml:150` | passing, 18 checked / 5 skipped / 0 findings |

The citation lint's 8 live violations are all in `.aid/knowledge/tech-debt.md` (lines 101, 103)
— `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge; echo $?` → `1`.
Nothing catches them because that lint is the half that is not in CI.

**The change is small and the repo already specifies it.** `state-generate.md:862-863` says
Step 5a "is the model for moving any MECHANICAL authoring rule from 'self-reported in GENERATE
/ caught in REVIEW' to 'mechanically gated in GENERATE' (cf. `lint-frontmatter.sh` for
frontmatter)." FR-B2 is that sentence, executed: add the frontmatter lint beside the citation
lint in Step 5a, with the same exit-0/exit-1 contract, the same owner re-dispatch on
violations, and the same 2-round cap before escalation. Symmetrically, the citation lint gains
the CI step it lacks. Both halves are one edit each and neither invents a mechanism.

**`FL19` must stop being satisfiable two ways.** `tests/canonical/test-frontmatter-lint.sh:337-343`
is titled "AID's own KB docs all soft-skip (day-one)" and asserts only `exit 0`, no
`[FM-MISSING]`, no `[FM-INVALID]`. Those three hold whether the lint checks 18 docs and finds
nothing **or** skips all 23 and looks at nothing — and the title asserts the second while the
live run reports the first (`Checked: 18 docs | Skipped: 5 docs | Findings: 0`). The fix is one
added assertion on the **checked count**, which is already printed. Its own CI step name carries
the same stale claim ("f001 soft-skip -- stays green until f011 migrates docs").

> A `tech-debt.md` row overlaps here and is **stale**. `W5-3` states "6 of the 21 KB documents
> have frontmatter that is not valid YAML", root-caused to `changelog:` entries. Re-measured
> with `yaml.safe_load` over `.aid/knowledge/*.md`: **23 docs, 0 unparseable** — the
> `changelog:` fields are gone from the KB (the FR-B7 sweep confirms `.aid/knowledge` at 0).
> The row's *gate* half stands (FL19 is vacuous); its *corpus* half is fixed. Retiring it is
> routed, not done here.

#### FR-B3 — read what `kb.html` actually says

**There is a live content defect, and it proves the gap.** `kb.html` names the work state file
**15 times as `STATE.md` and 0 times as `STATE.yml`**:

```bash
grep -c 'STATE\.md'  .aid/knowledge/kb.html    # 15
grep -c 'STATE\.yml' .aid/knowledge/kb.html    # 0
```

Some `STATE.md` uses are legitimate (`.aid/knowledge/STATE.md` still exists), but not these —
the glossary entry reads "The authored run-state of a Work, tracked in its `STATE.md`", and
another names `deliveries/delivery-NNN/STATE.md`. Both are `STATE.yml` now
(`grep -c 'STATE\.yml' .aid/knowledge/artifact-schemas.md` → `58`). The tour builds clean and
reads wrongly, which is exactly the user story.

**Nothing reads it, by construction and by history.**

- **The structural checks pass on structure.** `tests/canonical/test-kb-export.sh` KB01–KB08
  cover "element presence, button labels, print CSS, validators"; `test-payload-size.sh` covers
  payload size and the no-Mermaid-engine assertion. None asserts a claim about the project.
- **The one job that might have is gone.** `.github/workflows/test.yml:13-32` records that the
  `visual-fidelity` job "had been passing while validating NOTHING" — it looked for
  `.aid/dashboard/kb.html`, a path eliminated on 2026-07-11, so "its graceful-degradation
  branch then took over -- print SKIP, exit 0 -- so for four weeks it installed Chromium on
  every run, found no input, and reported green." Removed on the owner's decision.
  **This is this feature's own thesis, already recorded in the repo**, and it is the reason
  AC-3 demands a fixture rather than a passing run.

**Two contracts block a naive implementation, and this is `Q3`.**

1. **No type resolves.** `kb.html` is not markdown, so it is outside the registry corpus
   (`authoring-conventions.md:107-108`) and `G-07` — "Every in-scope markdown file resolves to
   exactly one type" — is not violated by it, because it is not in scope.
2. **The nearest type would *exclude* it.** `KB-03` applies to `kb-generated` with
   `kind: exclude`: "Content is not graded; only that the generator ran (build-verify)", whose
   `why` is "the generator is the oracle (C-5)". So typing `kb.html` as generated would forbid
   the very review FR-B3 asks for.

FR-B3 calls itself "a deliberate, named exception to `KB-03`". Measured, it is not an
exception — `KB-03` does not currently reach `kb.html`, so there is nothing to except. It is an
**addition**: a registry type whose selector admits a non-markdown generated artifact, plus
criteria for it, plus a corresponding widening of `G-07`'s "in-scope markdown" wording so the
partition still holds. **What this SPEC fixes regardless of `Q3`'s answer:** the review is
scoped to *claims about the project that can be checked against the KB* — names, paths, counts,
grades — and explicitly not to layout, styling or wording, so it cannot drift into re-reviewing
the generator. **No criterion id is allocated here**; allocation is the owner's, as feature-001
established for migrated checks.

**A generalizable helper already exists.** `canonical/aid/scripts/summarize/spot-check-facts.sh`
extracts claims from the HTML and cross-checks them against the KB, and states it does not
affect grading. It is the mechanical half of this gate; what it lacks is a criteria home and a
ledger route, which is what `Q3` gates.

#### FR-B4 — BLUEPRINT and specify review on the 7-column + `grade.sh` path

Two halves with opposite statuses. Measured, **there is no blueprint ledger scope anywhere in
the pipeline**: `grep -rn 'review-pending/blueprint' canonical tests scripts` → `0`. Every scope
that does exist is something else —
`grep -rhoE 'review-pending/[a-z<>{}-]+\.md' canonical --include='*.md' | sed 's|review-pending/||' | sort -u`
lists `deploy.md`, `detail.md`, `discovery.md`, `plan.md`, `specify-<feature>.md`, `summarize.md`,
`shortcut-{work}-defn.md`, `shortcut-{work}-tasks.md`, `<work>-review.md`, `<work>-test.md`,
`<work>-verify.md`, the `update-kb-*` set, and the placeholder forms (`<scope>.md`,
`<skill-name>.md`, `adhoc-<slug>.md`). None is a blueprint scope.

> The search is scoped to `canonical tests scripts` deliberately. Adding `.aid` returns `2` —
> **both hits are this SPEC quoting the command**. A verification grep whose corpus includes the
> document making the claim measures itself; every command in this SPEC is scoped to exclude
> `.aid/works/`, and this note records why so a later cycle does not "broaden" it back.

**The blueprint half is a real, structural gap — and it is an ordering problem, not a missing
grep.** On the full path `BLUEPRINT.md` files are created *in the branch that runs after the
grade clears*: `canonical/skills/aid-plan/references/review-deliverables.md:62` —
"Grade >= minimum | Ensure all delivery folders exist (`deliveries/delivery-NNN/BLUEPRINT.md` +
`STATE.yml` …; create any missing ones …)". The artifact does not exist at review time, so no
brief could include it. On the Lite path it is already reviewed: `shortcut-engine.md:742-743`
lists `BLUEPRINT.md` under "ARTIFACTS UNDER REVIEW" for GATE Pass 1, on ledger
`shortcut-{work}-defn.md`, graded by `grade.sh`. **So the Lite path already satisfies FR-B4 and
the full path structurally cannot.**

**And the documented owner of the fix does not do it.** `artifact-schemas.md:285` says the
BLUEPRINT is "written once by `aid-plan` (creates the stub) and refined by `aid-specify` on the
full path (at `deliveries/delivery-NNN/BLUEPRINT.md`)". But
`grep -rn BLUEPRINT canonical/skills/aid-specify/` → **0 hits**. The skill documented as
refining the blueprint never mentions it. That makes two candidate homes — move `aid-plan`'s
creation ahead of its review, or give `aid-specify` the blueprint scope its schema already
claims — and the second is cheaper because `aid-specify` is already on the ledger + `grade.sh`
path. **This SPEC does not choose**, because the choice is inside `Q6`'s scope; it fixes the
documentation conflict either way.

**The specify half is already satisfied, and "per-section" is less absent than it looks.**
`aid-specify/references/state-review.md:38,50-53` runs the standard loop on
`.aid/.temp/review-pending/specify-<feature>.md` and then
`bash canonical/aid/scripts/grade.sh --explain` on it — per **feature**. Nothing named
`per-section` is a review mechanism: `grep -rniE 'per-section|per section' canonical --include=*.md`
→ `5`. Four are `aid-summarize` HTML sections and theme palettes; the fifth is
`aid-specify/references/state-continue.md:15`, the heading "## The Loop — Per Section", which is
the specify loop's own working unit and still not a grading unit. **But the specify review is
already section-scoped in its brief**: `:23` says "For each section in SPEC.md, run step 4 of
the loop", and `:34` sets `{{ARTIFACTS}}` = "`SPEC.md` path + the section list under review (or
'full SPEC')". So "per-section" names something that half-exists — as *brief scope*, not as a
grading unit. That distinction is the substance of `Q6` and § Open states both readings.

#### FR-B5 — citation and quote accuracy over work artifacts

**Pointing the existing lint at a work root produces a false green, and this is measurable.**
`kb-citation-lint.sh:37` collects docs with `find "$ROOT" -maxdepth 1 -type f -name '*.md'`.
Run against this work:

```bash
W=.aid/works/work-013-review-stack-completion
bash canonical/aid/scripts/kb/kb-citation-lint.sh --root "$W"   # "clean", exit 0
find "$W" -maxdepth 1 -type f -name '*.md' | wc -l              # 2  <- what it looked at
find "$W" -mindepth 2 -type f -name '*.md' | wc -l              #     <- what it skipped
```

The skipped count grows as the work runs — it was `8` at `6090fe9e0` and rises with every brief
this work renders — so the criterion is the **ratio, not the constant**: the lint opens the
depth-1 files only, which is `2`, and skips everything below, which is every feature `SPEC.md`
including this one. Pin the number to a commit when quoting it, or state it as "2 opened, all
nested skipped"; a bare constant here is stale by the next cycle, which is exactly the drift
`FR-B7` exists to remove. So FR-B5 is not merely "point it at works"; pointing it there without
fixing the depth would *manufacture* the silent pass AC-3 exists to forbid. The change is a
`--recursive` (or depth) option, defaulting to today's behaviour so the KB invocation is
unaffected, plus the work-artifact invocation that uses it.

**No criterion reaches work artifacts, and feature-001 already routed that here.** Its
§ Verification records: a `.aid/works/**/SPEC.md` "resolves to no registry type and inherits no
type-level criteria; `G-07` is not violated, because the file is not in-scope", and names
`FR-B5` as the owner. So FR-B5 has two parts: the mechanical lint (above) and **registry
entries for work artifacts** so a citation/quote criterion has somewhere to attach. The second
part is the same shape as `Q3` — adding types, not excepting one — and no id is allocated here.

**On the apparent `file:line` conflict.** `canonical/skills/aid-review/SKILL.md` requires
findings to cite a KB doc or `file:line`, while `kb-citation-lint.sh` exits 1 on a bare
`file.ext:LINE`. These do not collide: the ledger's `Line` column is the sanctioned place for a
line reference (`canonical/aid/templates/reviewer-ledger-schema.md`), and the lint forbids bare
line citations *in KB prose*. The FR-B5 extension must preserve that split — a work artifact's
prose gets the durable-anchor rule; a ledger row's `Line` cell does not. Stated so a later
cycle does not "fix" a conflict that is not one.

**Quote accuracy** generalizes `spot-check-facts.sh` (§ FR-B3) from HTML to markdown: a quoted
span attributed to a source must appear in that source. It shares FR-B3's blocker — a criteria
home — and so shares its resolution.

#### FR-B6 — one grading backend (SHOULD)

**The collision `Q5` describes is real but much narrower than it looks, because the migration
is already half done.** `aid-summarize/references/state-validate.md` runs `grade-summary.sh` for
"the AUTO_POOL (machine-verifiable) checks only" (`:6`), then writes a **7-column ledger** at
`.aid/.temp/review-pending/summarize.md` "per `reviewer-ledger-schema.md`" (`:24`) and runs
`bash canonical/aid/scripts/grade.sh --explain` on it (`:55`). **`grade.sh` is already the
letter producer on this path.**

What remains is that `grade-summary.sh` *also* still produces letters, on an alphabet that
cannot agree with `grade.sh`'s:

| | model | alphabet | emits `E` | emits `F` |
|---|---|---|---|---|
| `grade.sh` | severity of the worst surviving finding, `+`/`-` by count (`:130-142`, `:96-102`) | `A+ A A-`, `B/C/D/E` × `+ · -` | yes | **no** — `grep -c 'GRADE="F"'` → `0` |
| `grade-summary.sh` | percentage of two point pools, `letter_grade()` over `AUTO_MAX` / `MANUAL_MAX=30` (`:395-406`, `:476`, `:490`) | `A+ A A- B± C± D F` | **no** — `grep -c '"E'` → `0` | yes |

The two are **disjoint exactly where they matter**: a letter one can emit, the other cannot.
`grade-summary.sh` computes `MACHINE_GRADE`, `HUMAN_GRADE` and `OVERALL_GRADE` (`:471-508`) and
prints them (`:559`, `:594`).

**How FR-B6 avoids the NFR-1 collision — it does not need `grade.sh` to change at all.**
`grade-summary.sh` is demoted from *grader* to *check orchestrator*: it keeps running the
machine checks and starts emitting **findings with severities** into the existing 7-column
ledger, and stops computing or printing any letter. `grade.sh` then produces the single letter
from that ledger, which is what `state-validate.md` already does. No counting-logic change, no
column change, no points mode.

**Each machine check already has a declared severity, and this SPEC allocates none.** The mapping
exists at `canonical/skills/aid-summarize/references/state-validate.md` § Translate Script Output
to Schema Rows, which the orchestrator already applies today when it writes failed checks into
`.aid/.temp/review-pending/summarize.md`. FR-B6 changes **who emits the row** — the script instead
of the orchestrator — and changes nothing about the band. Reproduced here for the fixture to assert
against, with each check's real name from `CHECK_NAMES` in `grade-summary.sh:227-243`:

| Check | Name in `grade-summary.sh` | Declared severity |
|---|---|---|
| `COV` | Resolved-doc-set coverage | `[CRITICAL]` — automatic F on the machine grade |
| `L1` | Anchor links | `[HIGH]`, one row per broken link |
| `L2` | Relative md links | `[HIGH]`, one row per broken path |
| `H1` | HTML validity | `[HIGH]`, one row per reported error |
| `S2` | Offline render | `[HIGH]`, one row per CDN reference |
| `NM` | No-Mermaid-engine (D-012) | `[HIGH]`, one row |
| `A1` | Semantic landmarks | `[MEDIUM]`, one row per check |
| `A2` | ARIA on lightbox | `[MEDIUM]`, one row per check |
| `A3` | Focus trap | `[MEDIUM]`, one row |
| `A4` | Reduced motion | `[MEDIUM]`, one row per check |
| `A5` | Visible focus | `[MEDIUM]`, one row per check |
| `C1` | Light theme contrast | `[MEDIUM]`, one row per failing colour pair |
| `C2` | Dark theme contrast | `[MEDIUM]`, one row per failing colour pair |
| `D1` | Mermaid parse (if present) | **not in the mapping** — see below |
| `D2` | Mermaid render (if present) | **not in the mapping** — see below |

`AUTO_POOL` is `COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2 NM` (`grade-summary.sh:201`), 15 checks;
the mapping in `state-validate.md` covers 13 of them plus `T1`/`T2`/`T3`, which are visual checks
that live outside `AUTO_POOL`. **`D1` and `D2` have no declared severity**, and that is not an
oversight to paper over here: both are "trivially passed — Mermaid engine retired"
(`grade-summary.sh:31`, `:248`), so no failing row can be produced today. A task that makes them
capable of failing must declare their band first, in `state-validate.md` where the others live —
not in a second table beside it.

> **A defect this SPEC made and is recording rather than deleting.** The first draft of this
> section invented its own severity table without checking that `state-validate.md` already
> declared one, and got four bands wrong: `H1` as "heading order" at `[LOW]` when it is HTML
> validity at `[HIGH]`, `S2` as "size budget" at `[LOW]` when it is the CDN-free assertion at
> `[HIGH]`, `COV` at `[HIGH]` when it is `[CRITICAL]`, and `C1`/`C2` at `[LOW]` when WCAG contrast
> is `[MEDIUM]`. The lesson generalises past this table: **when a mapping already exists, cite it;
> a second copy is drift with extra steps** — which is the same argument `FR-B7` makes about
> history sections. `Q5`'s two options were "convert the summarize path (not in §4)"
or "teach `grade.sh` a points mode (NFR-1 forbids it)" — the measurement shows a **third**: the
conversion is largely already in place, so what is left is deleting a duplicate letter path.

**One genuine residue stays with the owner**, and it is why this remains `Q5` and stays SHOULD:
the **V1 human visual gate** can force `F` (`grade-summary.sh:487-488`, "mandatory gate"),
and `F` is a letter `grade.sh` cannot express. Expressing it on the ledger means a `CRITICAL`
row (which `grade.sh` renders as `E±`, not `F`), or treating V1 as a **precondition** that
blocks before grading rather than a grade. Both are defensible; both change what a recorded
summary grade means historically. That choice is the owner's.

**Two statements on disk are false today and are corrected regardless of `Q5`:**

| Statement | Measured |
|---|---|
| `state-manual-checklist.md:31` — "Re-run `grade.sh` — it reads `manual-checklist.json`" | `grep -c manual-checklist canonical/aid/scripts/grade.sh` → `0`; `grade-summary.sh` → `6` |
| `state-generate.md:354` — "**Machine Grade Source:** `grade.sh` AUTO_POOL (68 pts)" | `grep -c AUTO_POOL canonical/aid/scripts/grade.sh` → `0`; `grep -c AUTO_POOL canonical/aid/scripts/summarize/grade-summary.sh` → `3` (lines 18, 206, 401) |

#### FR-B7 — no artifact authors its own history section

Specified in full in § The FR-B7 sweep below, because the command and its exclusions are the
substance.

---

### The FR-B7 sweep

**AC-7's literal command does not test what FR-B7 says.** As written it is
`grep -rn '## Change Log' canonical tests docs site/src .aid/knowledge`, which returns **97**
(`canonical 16, tests 3, docs 1, site/src 74, .aid/knowledge 3` — each reproduced by the same
grep on that one tree). Three defects, which together are `Q2`:

1. **It matches one of three forbidden forms.** FR-B7 forbids `## Change Log`, `## Revision
   History` *and* `changelog:`. The command greps only the first.
2. **It is a substring match, so it counts the rule itself.** Anchored to a heading,
   `grep -rnE '^#{1,6} +Change Log' canonical tests docs site/src .aid/knowledge` returns
   **0**. Not one real `## Change Log` heading exists in AC-7's own five trees; all 97 hits are
   prose stating the rule, or JSON-embedded text.
3. **74 of the 97 are inside a generated tree NFR-2 forbids editing** — 73 in
   `site/src/data/skill-flows/` and 1 in the generated `site/src/content` mirror
   (`grep -rn '## Change Log' site/src/data | wc -l` → `73`;
   `... site/src/content | wc -l` → `1`). AC-7 and NFR-2 contradict each other on those files.

**The corrected sweep** — all three forms, heading-anchored, over the authored trees only:

```bash
grep -rnE -e '^#{1,6} +Change Log' -e '^#{1,6} +Revision History' -e '^changelog:' \
  canonical tests scripts docs examples site/src/content dashboard lib .aid/knowledge \
  --include=*.md --include=*.sh --include=*.py --include=*.yml --include=*.mjs
```

→ **29 hits.** The matrix (each cell reproduced by the same command scoped to that one tree):

| Form | canonical | tests | docs | examples | site/src/content | dashboard | **total** |
|---|---|---|---|---|---|---|---|
| `## Change Log` | 0 | 0 | 0 | 0 | 0 | 8 | **8** |
| `## Revision History` | 1 | 1 | 1 | 1 | 1 | 0 | **5** |
| `changelog:` | 4 | 5 | 0 | 4 | 0 | 3 | **16** |
| **total** | **5** | **6** | **1** | **5** | **1** | **11** | **29** |

`.aid/knowledge`, `scripts` and `lib` return 0 — the KB is already clean, which is why the
`tech-debt.md § W5-3` corpus claim is stale (§ FR-B2).

**Classification, because AC-7 forbids "authoring instruction, template section, or fixture"
and permits "the rule text that forbids one".** Not all 29 are violations:

| Class | Count | Disposition |
|---|---|---|
| **Live emission** — `build-metrics.sh:117` writes `changelog:` into generated frontmatter | 1 | **Fix.** Directly contradicts `G-08`, "`changelog:` is not a valid field at all" |
| **Template section** — `feedback-artifacts/IMPEDIMENT.md:112` `## Revision History` | 1 | **Fix** |
| **Template example teaching the field** — `kb-authoring/frontmatter-schema.md:83` (the "For generated docs" block, carrying **no** legacy marker) | 1 | **Fix.** Its sibling at `:66` sits under an explicit `# --- legacy, superseded … ---` comment and is **permitted** rule/history text |
| **Legacy-marked example** — `frontmatter-schema.md:66`, `principles.md:175` (`intent: (superseded)` block) | 2 | **Keep**, subject to `Q4`. `G-08` explicitly bounds itself away from KB-doc templates |
| **Migration-test fixtures** — `test-migrate-kb-frontmatter.sh` ×5 | 5 | **Keep.** A migration test must contain the field it migrates away; removing them removes the test |
| **Authored docs + examples** — `docs/aid-methodology.md:1153`, `examples/` ×5 | 6 | **Fix.** Examples teach the shape they show |
| **Generated mirror** — `site/src/content/docs/concepts/methodology.md:1157` | 1 | **Regenerate**, never edit — fixed by `docs/aid-methodology.md` + `sync-docs.mjs` |
| **Dashboard parser fixtures** — `pt023-external-sources/*`, `pt1-aid/**/REQUIREMENTS.md`, `test_feature009.py:228` | 11 | **Owner decision (`Q2`).** These assert the *parser tolerates* a legacy artifact; deleting the input deletes the coverage |
| **Incidental test fixture** — `test-complexity-score.sh:74` | 1 | **Fix** — the fixture does not depend on the section |

**The generated `site/src` mirror is regenerated, not edited — demonstrated, not asserted.**
Running `node scripts/gen-skills.mjs` from `site/` (tree clean before, reverted after) takes
`## Change Log` in `site/src/data/skill-flows/` from **73 to 2**, and both survivors are
*rule-text excerpts* quoting the criterion that forbids the section
(`aid-discover.flow.json:77`, `aid-update-kb.flow.json:102`). The 73 were stale generated
content from an era when skills carried the section; the canonical sources now carry only the
rule. So NFR-2 and AC-7 are reconciled by **running the generator**, and `Q2`'s suggestion is
confirmed by measurement rather than argument.

**The mechanical gate is a corpus widening, not a new script — which is why its AC-3 proof is
exact.** `tests/canonical/test-kb-template-authoring-standard.sh` already implements precisely
the right check: `AS03` asserts `grep -c '^## \(Change Log\|Revision History\)'` is `0` and
`AS03b` asserts `grep -c '^changelog:'` is `0`, per template. It just runs over the wrong
corpus — `find canonical/aid/templates/knowledge-base -maxdepth 1 -name '*.md'` (`:42-50`):

| Corpus | Files | Violations found |
|---|---|---|
| today's `AS03` corpus (`templates/knowledge-base`, depth 1) | 14 | **0** |
| all `canonical/aid/templates/**/*.md` | 76 | **3** |

The three are `feedback-artifacts/IMPEDIMENT.md`, `kb-authoring/principles.md`,
`kb-authoring/frontmatter-schema.md`. Widening `AS03`/`AS03b` to the full template tree makes
the gate fire on 3 findings it structurally could not see — a **0 → 3** before/after, with no
new script and no new assertion logic.

---

### The fires-or-not proof (AC-3)

AC-3 requires, per gate, a fixture that fails before and passes after, **or** a before/after
measurement. Which of the two each gate gets, and why:

| Gate | Form | The proof |
|---|---|---|
| **FR-B1** settings | **Fixture** | `tests/canonical/test-settings-schema-check.sh` runs the check against fixture settings files: one missing `format_version` (S2), one with `minimum_grade: F` (S3 — a value `grade.sh` cannot emit), one with an undocumented top-level key (S1), one valid. Plus the **zero-keys** case, asserting exit 1 rather than a vacuous pass. Before: no check exists, so all four inputs "pass". |
| **FR-B2** frontmatter lint | **Measurement, two-sided** | *Runtime:* `grep -c 'lint-frontmatter' canonical/skills/aid-discover/references/state-generate.md` → 1 before (the parenthetical at `:863`) and ≥2 after, with the added hit inside the Step 5a command block. *CI:* `grep -rn kb-citation-lint .github/ \| wc -l` → `0` before, ≥1 after. *Vacuity:* `FL19` gains a checked-count assertion; the fixture that proves it is a root where every doc skips — exit 0 and 0 findings today, failing after. |
| **FR-B3** `kb.html` content | **Fixture, and one live finding already in hand** | The live defect is the before-measurement: `grep -c 'STATE\.md' .aid/knowledge/kb.html` → `15`, `STATE\.yml` → `0`. A review that does not report it is not reading. Fixture: a `kb.html` whose stated project facts contradict the KB must produce a finding; one that agrees must not. **Blocked on `Q3`** for where the criterion attaches — the *proof shape* is fixed here, its id is not. |
| **FR-B4** blueprint | **Measurement** | `grep -rn 'review-pending/blueprint' canonical tests scripts \| wc -l` → `0` before, ≥1 after (the corpus excludes `.aid/works/` — see § FR-B4). After: a real full-path dispatch also leaves a brief on disk plus a `review-cost.tsv` row — feature-001's criterion-4 commands, reused unchanged. |
| **FR-B5** citations on work artifacts | **Measurement, and it must be the *depth* that is measured** | Before: lint over `.aid/works/work-013-*` reports clean having opened **2** of **10** `.md` files. After: it opens 10. The assertion is on the **opened count**, not on the verdict — a clean verdict is exactly what the false green already produces. |
| **FR-B6** single backend | **Measurement** | `grep -oE '"[A-F][+-]?"' canonical/aid/scripts/summarize/grade-summary.sh \| sort -u \| wc -l` → **11** distinct letter values before (`A+ A A- B+ B B- C+ C C- D F`), 0 after. Note the `-o … sort -u` form: the plain `grep -cE` counts *matching lines* and returns **27**, which is a different quantity and not the one this criterion is about. `grep -c 'Machine Grade:' grade-summary.sh` → 1 before, 0 after; and `state-validate.md` still runs `grade.sh --explain` on the 7-column ledger, unchanged. `git diff <base> HEAD -- canonical/aid/scripts/grade.sh` stays empty (NFR-1). |
| **FR-B7** history sections | **Measurement, both corpora** | Gate: `AS03`/`AS03b` over 14 files → **0**, over 76 → **3**. Sweep: the 29-hit command re-run after the fixes returns only the classified **Keep** rows, and `site/src/data` drops 73 → 2 by regeneration. |

**The common guard.** Every gate above prints what it examined next to what it expected, and
every one treats *examined nothing* as a failure rather than a pass. That rule is not stylistic
here: `.github/workflows/test.yml:13-32` records a gate in this repo that reported green for
four weeks while examining no input, and `FL19` and the `-maxdepth 1` lint are two more live
instances. AC-3 exists because of them.

---

### Render & Parity (NFR-2 / AC-11)

Files this feature changes under `canonical/` drive a render; the rest do not. Sequence:

1. Edit `canonical/` only. Never `profiles/`, `.claude/`, `.cursor/`, `site/src/data/`, or the
   generated regions of `site/src/content/` named in § Artifacts & Surfaces.
2. Run the **full** generator — `python .claude/skills/generate-profile/scripts/run_generator.py`
   — because a partial render leaves stale emission manifests and CI `render-drift` fails
   (`.aid/knowledge/architecture.md § Gotchas`).
3. **VERIFY (deterministic) must report PASS** —
   `python .claude/skills/generate-profile/scripts/verify_deterministic.py --canonical-root .`
   — a non-zero exit aborts before REPORT.
4. Regenerate the site trees rather than editing them: `node site/scripts/gen-skills.mjs` and
   `node site/scripts/sync-docs.mjs`. The FR-B7 fix to `docs/aid-methodology.md` lands its
   mirror through step 4, not by hand.
5. Confirm no hand-edit survived: `git diff --name-only` over
   `profiles/ .claude/ .cursor/ site/src/data/ site/src/content/docs/skills/` contains only
   generator-written paths.

**NFR-1 baseline.** Measured now, `git diff --stat origin/master...HEAD -- canonical/aid/scripts/grade.sh canonical/aid/templates/reviewer-ledger-schema.md`
is **empty** — neither file has been touched on this branch. This SPEC still uses **the work's
base commit** rather than `master`, for feature-001's reason: `master` moves, so a criterion
based on it silently re-scopes itself whenever someone else merges. The base is the branch tip
recorded in the delivery record before any edit, and the reading is "the diff touches neither
counting logic nor column shape" — an empty diff is sufficient but not required. This is `Q1`,
which feature-001 owns; nothing here re-decides it.

**FR-B6 is the one part of this feature that could violate NFR-1**, and § FR-B6 states the
avoidance concretely: `grade-summary.sh` stops emitting letters and starts emitting ledger
findings; `grade.sh` is not modified at all.

---

### Verification — criterion by criterion

Every row is a command. Where nothing mechanical decides a criterion, the row says so.

| This SPEC's criterion | How it is checked |
|---|---|
| **1** — five gates each fire (fixture, or before/after) | the seven rows of § The fires-or-not proof, each re-run and its before/after figures reproduced, with outputs recorded in the delivery record. **Re-worded first if `Q6` redefines "per-section"** — the criterion carries that note already. |
| **2** — `grade.sh` sole letter producer (SHOULD) | `grep -cE '"[A-F][+-]?"' canonical/aid/scripts/summarize/grade-summary.sh` → `0`; `grep -c 'grade\.sh --explain' canonical/skills/aid-summarize/references/state-validate.md` → `1`; `git diff <base> HEAD -- canonical/aid/scripts/grade.sh` touches no counting logic. **If `Q5` resolves against conversion, this criterion is discharged as *not done, by owner decision* and recorded — not silently dropped.** |
| **3** — no artifact authors a history section | the 29-hit sweep in § The FR-B7 sweep, re-run, returns only the classified **Keep** rows; `AS03`/`AS03b` over the widened 76-file corpus exit 0; `grep -rn '## Change Log' site/src/data \| wc -l` → `2` after regeneration. `Q2` governs the 11 dashboard-fixture rows; until it answers, they are listed, not deleted. |
| **4** — proposed script cites a measured re-derivation | § FR-B1's commands re-run and reproduce `39`, `68`, `29`, `28`, and the `26 A` / `2 A+` split. |
| **5** — `grade.sh` / ledger schema unchanged; render byte-identical | `git diff <recorded-base> HEAD -- canonical/aid/scripts/grade.sh canonical/aid/templates/reviewer-ledger-schema.md`, read as "touches neither counting logic nor column shape"; `verify_deterministic.py` → `VERIFY (deterministic): PASS`; the step-5 `git diff --name-only` over all five generated regions contains only generator-written paths. |
| **6** — every count re-derives | every count in this SPEC carries its command inline; re-running each reproduces the figure. |

**No declared criterion reaches this SPEC.** As feature-001 recorded, a `.aid/works/**/SPEC.md`
resolves to no registry type and inherits no type-level criteria, so `G-07` is not violated —
the file is not in scope. **That gap is this feature's own FR-B5**, which makes this SPEC an
instance of the defect it specifies the fix for. Until FR-B5 closes, it is reviewed against its
own acceptance criteria and `.aid/knowledge/artifact-schemas.md § Feature SPEC.md`, not against
a resolved criteria list — stated so a reviewer does not cite an id that does not reach it.

---

### Routed Findings — real, measured, and deliberately not fixed here

| Finding | Evidence | Route |
|---|---|---|
| `kb-citation-lint.sh` is **failing right now** and nothing runs it in CI | `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge; echo $?` → `1`, 8 violations, all `.aid/knowledge/tech-debt.md:101,103`; `grep -rn kb-citation-lint .github/ \| wc -l` → `0` | **In scope, FR-B2** — the CI half of the symmetry. The 8 violations are content fixes in `tech-debt.md`, done with it. |
| `tech-debt.md § W5-3` claims 6 of 21 KB docs have unparseable frontmatter | `yaml.safe_load` over `.aid/knowledge/*.md` → **23 docs, 0 unparseable**; the FR-B7 sweep returns 0 for `.aid/knowledge` | **Stale — retire the corpus half, keep the gate half.** `FL19`'s vacuity is real and is fixed under FR-B2. Retiring the row is `aid-housekeep` work, not this feature's. |
| `artifact-schemas.md` documents 6 settings keys that do not resolve, and omits 3 that are stored | the 12-key probe and the 3-key probe in § FR-B1 | **In scope, FR-B1** — the doc is the schema of record the gate validates against, so it is corrected with the gate. |
| The Lite path's grade floor default disagrees with every other call site | the `uniq -c` split in § FR-B1 → `26 --default A`, `2 --default A+`, both `A+` in `shortcut-engine.md` (320, 723), against `minimum_grade: A` in the file | **Owner question, not a bug to fix silently.** A stricter Lite floor may be intended. Route to `tech-debt.md`; the FR-B1 gate makes the *file* authoritative either way. |
| `aid-specify` never mentions `BLUEPRINT.md`, though `artifact-schemas.md:285` says it refines it | `grep -rn BLUEPRINT canonical/skills/aid-specify/` → `0` | **In scope, FR-B4** — it is one of the two candidate homes for the blueprint review, and the doc conflict is corrected whichever `Q6` picks. |
| `shortcut-engine.md:760` and `aid-specify/references/state-review.md:35` still name `STATE.md` for work state | `grep -c 'STATE\.yml' .aid/knowledge/artifact-schemas.md` → `58`; `kb.html` carries 15 more | **Same class as FR-B3's live defect.** The `kb.html` instances are in scope (they are what the content review must catch); the two canonical prose instances are adjacent drift — route to `tech-debt.md`. |
| `reviewer-dispatch.md` maintains an in-document changelog and tells the next author to extend it | feature-001 § Routed Findings measured it: 2 hits, § When this protocol changes step 1 and § Bootstrap exemption | **Inherited into FR-B7's scope.** Note the anchored sweep returns **0** for it — the section is a dated `## Bootstrap exemption` heading, not a `## Change Log`, so the sweep command alone does not catch it. Fixing it is FR-B7's; **widening the sweep to catch dated-history-by-another-name is not**, and is `Q4`'s territory. |
| `kb-authoring/review-rubric.md` check 1 still requires "`intent:` non-empty", which `G-08` supersedes | feature-001 routed this here with the `Q4` sweep | **Deferred to `Q4`.** It is a superseded-field finding, not a history-section one; FR-B7's three forms do not reach it. |
| 60 catalogued skills are hand-authored but classified `skill-generated`, so `SK-02` forbids each a file-level block | feature-001 § Artifacts & Surfaces; 0 live violations | **Blocking prerequisite** if any FR-B2/FR-B6 edit needs a file-level criterion on one of those skills. None of this SPEC's edits does. |

### Open — not decided by this SPEC

All five questions that land on this feature are **Pending and stay Pending**. For each: what
this SPEC does regardless, and what the answer would change.

- **`Q2` — AC-7's command.** *Regardless:* the corrected 3-form, generated-tree-excluding sweep
  in § The FR-B7 sweep is specified and measured (29 hits, classified), and the generated mirror
  is shown to clear by regeneration (73 → 2), which confirms `Q2`'s suggestion by measurement.
  *The answer changes:* whether the **11 dashboard parser fixtures** are violations or protected
  coverage. If they are in scope, 11 fixtures are rewritten and their parser assertions
  re-based; if not, they are recorded as a named exclusion in the sweep command itself. This
  SPEC lists them and deletes nothing.
- **`Q3` — FR-B3 as "exception to `KB-03`".** *Regardless:* the review's *scope* is fixed
  (project claims checkable against the KB; not layout or wording), the live `STATE.md` × 15
  defect is the before-measurement, and `spot-check-facts.sh` is named as the mechanical half.
  *The answer changes:* whether `kb.html` gets a **registry type** — which also requires
  `G-07`'s "in-scope markdown" wording to widen so the partition still holds — or whether FR-B3
  is restated as a standalone check outside the cascade. **No criterion id is allocated here
  either way.**
- **`Q4` — "stated once".** *Regardless:* the rule's **normative home is identified** —
  `.aid/knowledge/artifact-schemas.md:629-632`, "No in-document history, anywhere … This binds
  every artifact the methodology produces, not only KB docs" — with `:252` and `:272` as
  narrower restatements and `G-08` as the citable criterion for the `changelog:` half. FR-B7's
  *gate* needs none of this resolved. *The answer changes:* whether the ~8 further sites
  (`grep -rlniE 'no history section|history apparatus|never author a .## Change Log|changelog. is not a valid field' canonical tests docs .aid/knowledge` → 8 files) become
  cross-references to `:629-632` or are deleted. Deletion touches the cascade, the docs site and
  three test assertions, and §4 In Scope does not mention it.
- **`Q5` — FR-B6 vs NFR-1.** *Regardless:* the collision is shown to be **narrower than
  stated** — `grade.sh` is already the letter producer at `state-validate.md:55`, so no points
  mode and no `grade.sh` change is needed; the remaining work is removing
  `grade-summary.sh`'s duplicate letter path, plus two false statements corrected either way.
  *The answer changes:* how the **V1 human visual gate's `F`** is expressed, since `grade.sh`
  cannot emit `F` — as a `CRITICAL` ledger row (rendering `E±`) or as a precondition that
  blocks before grading. Both change what a historical summary grade means. FR-B6 is SHOULD, so
  a decision to drop it is a legitimate outcome; it is then **recorded as declined, not
  silently skipped**.
- **`Q6` — FR-B4's "specify per-section review".** *Regardless:* the blueprint half is fully
  specified and measured (no ledger scope exists; the Lite path already reviews it; the full
  path creates the artifact after grading, so it structurally cannot), and the criterion above
  carries FR-B4's wording unchanged. *The answer changes:* whether "per-section" is **narrowed
  away** — in which case the specify half is already discharged, since
  `state-review.md:38,50-53` is on the ledger + `grade.sh` path — or **defined**. If defined,
  the measurement that matters is that specify review is *already* section-scoped in its brief
  (`:23`, `:34` — `{{ARTIFACTS}}` is "the section list under review"), so the open question is
  whether FR-B4 wants a **grade per section** rather than a brief scoped per section. This SPEC
  states both readings and picks neither.

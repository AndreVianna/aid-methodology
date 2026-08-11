# Plain-Language Knowledge Base Rewrite

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-11 | SPEC authored from REQUIREMENTS.md | /aid-refactor |

## Source

- REQUIREMENTS.md §2 Problem Statement — the symptom/evidence table that scopes what "jargon" means here.
- REQUIREMENTS.md §4 Scope — the 17 in-scope docs, their word-count baselines, and the out-of-scope carve-outs.
- REQUIREMENTS.md §5 Functional Requirements — FR-1 through FR-10.
- REQUIREMENTS.md §6 Non-Functional Requirements — frontmatter bounds, growth budget, no-new-dependency, determinism, grade bar.
- REQUIREMENTS.md §7 Constraints — canonical-only editing, no work references in the KB, generated-files rule, shipped-script rules.
- REQUIREMENTS.md §8 Assumptions & Dependencies — including the one decision explicitly deferred to this SPEC (how enforcement lands).
- REQUIREMENTS.md §9 Acceptance Criteria — AC-1 through AC-12.
- REQUIREMENTS.md §10 Priority — the dependency-driven ordering of the Must set.

## Description

The Knowledge Base under `.aid/knowledge/` breaks a rule it publishes about itself. Its own
`authoring-conventions.md` and the canonical rule it mirrors both demand plain words, short
sentences, and a glossary entry for every project-specific term. Nothing checks that, so the
docs have drifted into invented metaphors nobody defined, frontmatter sentences long enough to
wreck the routing table every agent loads first, and shouted codes used as if the reader
already knows them.

This work does two things and nothing else.

First, it **rewrites the wording** of the 17 hand-authored KB docs so a junior professional can
read them. The knowledge itself does not move: every fact, contract, enum, table row, path,
command, and citation that was there before is there afterwards, saying the same thing. This is
a prose refactor, so "no observable change" means "no change to what the KB asserts".

Second, it **turns the rule into a check**. Today the plain-language expectation is advice, and
advice does not survive the next author. After this work, a KB doc that uses an invented term
with no glossary entry, or whose frontmatter blows past the readability bounds, fails a script;
and a doc whose prose is merely dense fails a named reviewer check with a stated severity. The
rule stops depending on whoever happens to be reviewing.

## User Stories

- As the **repo maintainer**, I want to read any KB doc without decoding invented vocabulary, so
  that the KB is usable instead of merely present.
- As a **junior human reader or new contributor**, I want every project-specific term defined the
  first time I meet it, so that I can follow a doc without prior AID vocabulary.
- As an **AI agent consuming the KB**, I want short, concrete `objective:` and `summary:` frontmatter
  and unambiguous terms, so that `INDEX.md` routes me to the right doc instead of a wall of text.
- As the **`aid-reviewer`**, I want a plain-language and glossary-coverage condition with a stated
  severity in the rubric I apply, so that I record a finding by rule rather than by recall.
- As the **Architect** who owns `authoring-conventions.md`, I want the KB's restatement of the rule
  to name the same mechanism the canonical rule names, so that the two never contradict.
- As a **future author of a KB doc**, I want the check to run before I merge, so that I learn about a
  new undefined term at authoring time rather than one review cycle later.

## Priority

**Must** — all of REQUIREMENTS.md §5 FR-1 through FR-10. Nothing is deferred to Should or Could.

Ordering is dependency-driven, not importance-ranked (REQUIREMENTS.md §10):

1. **FR-7, FR-8** — settle and build the tightened rule first, so every later rewrite is written
   against the standard it will be graded by, and so the negative fixture proves the gate works
   before the corpus depends on it.
2. **FR-6, FR-3** — rewrite and complete `domain-glossary.md`, settling the term set the other
   16 docs' wording depends on.
3. **FR-1, FR-4, FR-5** — the per-doc prose and frontmatter rewrite.
4. **FR-9, FR-10** — mirror the rule into `authoring-conventions.md`, then render `canonical/`
   to `profiles/` and resync the dogfood trees.

## Acceptance Criteria

Each criterion below traces back to a REQUIREMENTS.md §5 functional requirement and forward to a
concrete verification a task can run. The trace table follows the list.

- [ ] **AC-1 — Knowledge unchanged.** Given a rewritten KB doc and its pre-rewrite version at the
      work's base commit, when the two are compared by the per-doc invariant diff plus claim
      ledger defined in `### Feature Flow` (flow D), then every fact, contract, enum value, table
      row, path, command, and citation present before is present after with unchanged meaning and
      scope, and nothing new is asserted.
- [ ] **AC-2 — No undefined coined term.** Given the rewritten `.aid/knowledge/*.md`, when
      `kb-language-lint.sh --check glossary` runs, then it exits 0 with zero `[GLOSSARY-GAP]`
      findings — every coined term in the computed universe either resolves to a
      `domain-glossary.md` definition (a `## Concept Spine` `### ` heading, an `**Aliases:**`
      entry, or a Lexicon/Abbreviations table term) or appears in the dismissal file with a
      recorded reason, and every term named in REQUIREMENTS.md §2 either resolves or no longer
      appears in the KB.
- [ ] **AC-3 — No opaque bare code.** Given any shouted token (`CONFIRMED`, `SYNTHESIS`,
      `ELICIT E1/E2`, `S1-S5`, `T1-T6`, `P1`/`P9`/`P10`, `C0`-`C9`, `APPROVAL-HALT`, or any other),
      when a reader meets its first occurrence in a doc, then it is expanded there or resolves to a
      named legend or glossary entry; the reviewer records any residue as `[AUTHORING-CODE]`.
- [ ] **AC-4 — Frontmatter within bounds.** Given each in-scope doc's frontmatter, when
      `kb-language-lint.sh --check frontmatter` runs, then it exits 0: `objective:` is one physical
      line of at most 25 words and `summary:` is at most 2 sentences of at most 30 words each with
      at most 1 em-dash aside. `architecture.md`'s `objective:` and `test-landscape.md`'s `summary:`
      specifically pass.
- [ ] **AC-5 — INDEX regenerated, not edited.** Given the rewritten frontmatter, when
      `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
      runs, then it succeeds, `INDEX.md` reflects the new frontmatter, and a second run produces no
      further diff.
- [ ] **AC-6 — Growth budget respected.** Given each rewritten doc, when `wc -w` is compared to its
      REQUIREMENTS.md §4 baseline, then it exceeds the baseline by no more than 15%.
- [ ] **AC-7 — The rule is enforceable, proven by a negative fixture.** Given the fixture KB at
      `tests/canonical/fixtures/kb-language-lint/undefined/`, which contains a doc introducing a
      coined term with no `domain-glossary.md` entry and no dismissal row, when
      `kb-language-lint.sh --root <fixture>` runs, then it exits 1 and prints a `[GLOSSARY-GAP]`
      line naming that term. And given the sibling fixture
      `tests/canonical/fixtures/kb-language-lint/defined/`, identical except that the term carries a
      `### ` glossary entry, then the same command exits 0. A fixture pair that both pass, or both
      fail, is itself a test failure.
- [ ] **AC-8 — Canonical and KB agree.** Given the tightened rule, when
      `canonical/aid/templates/kb-authoring/principles.md` (P10 Language), `review-rubric.md`
      (Full Primary checklist + lint-tag severity table) and `.aid/knowledge/authoring-conventions.md`
      (§ Dual-Audience Standard, § Enforcement) are read side by side, then they state the same rule,
      name the same script and the same reviewer tags, and assign the same severities, with no
      contradiction.
- [ ] **AC-9 — Render is clean.** Given the `canonical/` changes, when
      `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/`
      runs, then it exits 0, and `bash tests/canonical/test-dogfood-byte-identity.sh` passes — the
      render is current, `profiles/` carries no hand edit, and the `.claude/` and `.cursor/` dogfood
      trees match their emission manifests.
- [ ] **AC-10 — Existing lints pass.** Given the rewritten docs, when `lint-frontmatter.sh` and
      `kb-citation-lint.sh` run over `.aid/knowledge/`, then both exit 0 with no `[FM-MISSING]`,
      `[FM-INVALID]`, or positional-citation finding.
- [ ] **AC-11 — No work references in the KB.** Given `.aid/knowledge/**`, when it is grepped for
      `work-[0-9]{3}`, then there are no hits, in prose, tables, headings, or frontmatter.
- [ ] **AC-12 — Grade gate cleared.** Given the rewritten KB, when `aid-reviewer` grades it against
      the tightened rubric, then no plain-language, glossary-coverage, or shouted-code finding
      remains above MINOR and the resulting grade is at least `A`, the resolved `minimum_grade`.
- [ ] **AC-13 — Enforcement adds no toolchain dependency.** Given `kb-language-lint.sh`, when it runs
      on a machine with only the tools `technology-stack.md` already declares (bash, coreutils, awk,
      git; ripgrep optional), then it completes successfully — it invokes no interpreter, package, or
      binary that the repo does not already require, and `AID_HARVEST_NO_RG=1` produces identical
      findings.
- [ ] **AC-14 — Every silenced term is auditable.** Given `.aid/knowledge/.glossary-dismissed.txt`,
      when it is read, then every non-blank, non-comment line carries exactly one bare term whose
      reason is stated on the `#` comment line immediately above it — the form
      `closure-check.sh --dismissed` actually parses, per `### Data Model` — and no term appears there
      that also carries a `domain-glossary.md` definition. A term is silenced by an explicit recorded
      decision, never by a heuristic the check happens not to catch.
- [ ] **AC-15 — The check is wired where it can block.** Given the tightened rule, when the
      `kb-hygiene` CI job runs and when `/aid-discover` REVIEW dispatches its mechanical oracles,
      then `kb-language-lint.sh` runs in both, so a violation fails a merge and surfaces as a ledger
      finding rather than passing silently.
- [ ] **AC-16 — The gate is test-covered.** Given `tests/canonical/test-kb-language-lint.sh`, when
      `bash tests/run-all.sh` runs, then the suite is discovered by the `tests/canonical/test-*.sh`
      glob and passes; it carries `# COVERS:` headers for `kb-language-lint.sh` and its fixtures, and
      its coverage rows are registered in `tests/coverage-baseline.tsv`.
- [ ] **AC-17 — Existing oracles keep their behavior.** Given the additive change to
      `closure-check.sh`, when `bash tests/canonical/test-closure-check.sh` and the essence/teachback
      suites run, then they pass unchanged — the new input defaults to absent and the default
      invocation is byte-identical to today's.

### Traceability

| SPEC AC | REQUIREMENTS §5 FR | Verified by |
|---|---|---|
| AC-1 | FR-2 | Per-doc invariant diff + claim ledger (`### Feature Flow` flow D); reviewer spot-check |
| AC-2 | FR-3 (refined — see the note below), FR-8 | `kb-language-lint.sh --check glossary` exit code + finding list |
| AC-3 | FR-4 | Reviewer check `[AUTHORING-CODE]` in the tightened rubric |
| AC-4 | FR-5 | `kb-language-lint.sh --check frontmatter` exit code |
| AC-5 | FR-5 | `build-kb-index.sh` re-run + `git diff --exit-code` |
| AC-6 | FR-1 | `wc -w` per doc vs the REQUIREMENTS.md §4 baseline |
| AC-7 | FR-7, FR-8 | `tests/canonical/test-kb-language-lint.sh` fixture pair |
| AC-8 | FR-9 | Side-by-side read of canonical rule set vs `authoring-conventions.md` |
| AC-9 | FR-10 | `run_generator.py` + `git diff --exit-code -- profiles/` + dogfood byte-identity suite |
| AC-10 | FR-1, FR-5 | `lint-frontmatter.sh`, `kb-citation-lint.sh` |
| AC-11 | FR-1 (constraint §7) | `grep -rE 'work-[0-9]{3}' .aid/knowledge/` |
| AC-12 | FR-1, FR-3, FR-4 | `aid-reviewer` + `grade.sh` against the tightened rubric |
| AC-13 | FR-7 (NFR no-new-dependency) | Run with `AID_HARVEST_NO_RG=1`; inspect the script's invocation set |
| AC-14 | FR-8 | Read `.glossary-dismissed.txt`; cross-check against the glossary |
| AC-15 | FR-7 | `kb-hygiene` job definition; `state-review.md` oracle list |
| AC-16 | FR-7 | `tests/run-all.sh`; `tests/coverage-parity.sh` |
| AC-17 | FR-7 | `tests/canonical/test-closure-check.sh` and the essence/teachback suites |
| — (structural; no AC) | FR-6 | Enforced by the task dependency graph, not by a runtime check: PLAN.md `## Execution Graph` makes `domain-glossary.md`'s rewrite (task-006) a dependency of every other corpus-rewrite task (task-007 through task-013), so the glossary is settled first by construction. Stated as a design constraint in `#### Sequencing constraints` item 2 |

**Deliberate refinement — SPEC AC-2 against FR-3.** REQUIREMENTS.md §5 FR-3 and §9 AC-2 phrase the
obligation as "a `### ` definition" in `domain-glossary.md`; SPEC AC-2 accepts any
`domain-glossary.md` definition — a `## Concept Spine` `### ` heading, an `**Aliases:**` value, or a
first-column term in a Lexicon / Abbreviations / Domain-Meanings table. This is recorded here as a
deliberate, narrow **refinement**, not a relaxation: the obligation "the term is defined in the
glossary" is unchanged, and only the accepted syntactic form widens. The reason is argued in
`### Feature Flow` ("Why `closure-check.sh` needs one additive input"): the glossary already defines
terms in those tables, so requiring them to be re-listed as `### ` would misrepresent the doc's own
structure and the Concept Spine's meaning. The `### ` form remains the default route for a newly
retained coined term. No other SPEC acceptance criterion diverges from the requirement it traces to.

---

## Technical Specification

> Authored by the shortcut engine's SPEC state (flattened Lite path), not by a separate
> `/aid-specify` pass. Per `shortcut-scaffolding/change-refactor.md § aid-refactor -- SPEC section
> activation`, a bare `refactor` activates **no conditional section**: the mandatory three below
> are the whole specification. `### Data Model` and `### Feature Flow` carry the family's
> "unchanged -- behavior-preserving refactor" default, extended only where the rule-tightening half
> genuinely introduces a detection path (stated explicitly in `### Feature Flow`).
> `### Layers & Components` carries the substance.

### Data Model

**Unchanged — behavior-preserving refactor.** This work touches no database, no persisted entity,
no migration, and no settings schema. `.aid/settings.yml` is read, never written. The KB frontmatter
schema in `canonical/aid/templates/kb-authoring/frontmatter-schema.md` gains **no new field**: the
readability rule tightens the permitted *content* of the existing `objective:` and `summary:`
scalars, not their shape, so `lint-frontmatter.sh`'s presence-and-shape contract is untouched.

The only new on-disk data shapes are four plain-text artifacts and one finding format:

| Shape | Path | Format | Producer | Consumer |
|---|---|---|---|---|
| Dismissal list | `.aid/knowledge/.glossary-dismissed.txt` | One bare term per line, with its reason on the `#` comment line immediately above it — never inline on the term's own line; blank lines ignored. ASCII, LF. | Human decision, recorded during the rewrite | `kb-language-lint.sh` -> `closure-check.sh --dismissed` |
| Project-local denylist (existing mechanism, may gain entries) | `.aid/knowledge/.coined-term-denylist.local.txt` | One lowercase word per line | Human | `harvest-coined-terms.sh` (already supported) |
| Merged candidate universe (transient) | `.aid/.temp/kb-language/candidates.md` | The `## Ranked Candidates` markdown table shape `harvest-coined-terms.sh` already emits | `kb-language-lint.sh` | `closure-check.sh --concepts` |
| Glossary table-defined terms (transient) | `.aid/.temp/kb-language/defined-extra.txt` | One term per line, parsed from `domain-glossary.md`'s Lexicon / Abbreviations / Domain-Meanings tables; blank lines ignored. ASCII, LF | `kb-language-lint.sh` | `closure-check.sh --defined-extra` |
| Lint finding line | stdout/stderr of `kb-language-lint.sh` | `  [TAG] <doc>: <description>` — matching `lint-frontmatter.sh`'s existing emission shape | `kb-language-lint.sh` | Orchestrator, CI, reviewer |

Three dismissal-file rules are load-bearing and belong here rather than in prose. First, the reason
is a **preceding comment line, not an inline one**, because that is the only form the consumer
parses: `closure-check.sh --dismissed` drops lines that *start* with `#` but does not strip an
inline `#`, so `Thin Doorway  # not a concept` would be excluded as the literal string
`thin doorway  # not a concept` and the term itself would stay in the universe — a silent dismissal
failure. Keeping the reason on its own `#` line makes the file auditable and needs no change to the
shipped parser. Second, the file lives under `.aid/knowledge/` (so it travels with the KB it
governs, like the existing `.coined-term-denylist.local.txt` and `.review-checklist.md` overrides).
Third, it is a **durable** record. It deliberately does **not** reuse
`.aid/generated/spine-todo.md`, whose `DISMISSED` column
the `/aid-discover` closure loop already consumes: that file is regenerated from
`candidate-concepts.md` on every discovery run, so a decision recorded there does not survive, and a
standing gate needs a decision that does.

New closed value sets introduced by the rule-tightening (added to the `review-rubric.md`
"Lint output -> severity mapping" table, which is the single registry of these tags):

| Tag | Severity | Decided by | Meaning |
|---|---|---|---|
| `[GLOSSARY-GAP]` | HIGH | Script | A coined term used in a KB doc has no `domain-glossary.md` definition and no dismissal row |
| `[LANG-FRONTMATTER]` | HIGH | Script | `objective:`/`summary:` exceed the readability bounds |
| `[AUTHORING-CLARITY]` | MEDIUM | Reviewer | Jargon-dense prose a junior could not follow where plain words carry the same meaning |
| `[AUTHORING-CODE]` | MEDIUM | Reviewer | A shouted bare code used on first occurrence with no expansion and no resolvable legend |

`[AUTHORING-CLARITY]` already exists as an emitted tag in
`canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md` (Authoring Standard checklist,
item 15) but has **no row in the rubric's severity table** — part of the defect this work closes.
The two script tags are HIGH, consistent with the rubric's standing statement that current lint
findings are HIGH; the two judgment tags are MEDIUM, matching the severity the anatomy prompt
already assigns.

### Feature Flow

**Unchanged for the refactored target.** The prose rewrite changes no runtime path: no product
code, no CLI behavior, no generator logic, no state machine transition. The KB is data an agent
reads, and after the rewrite it asserts exactly what it asserted before (AC-1). That is this
refactor's behavior-preservation guarantee.

The rule-tightening half is where a flow genuinely appears, because there is no detection path
today. Four flows are specified: three detection paths (A, B, C) and the verification path (D)
that proves the rewrite preserved the knowledge.

#### Flow A — a glossary-coverage violation, end to end

The premise is that this project **already computes** a coined-term set deterministically; the gap
is that it does so only inside `/aid-discover`'s GENERATE closure loop, so nothing checks
`.aid/knowledge/` afterwards. Flow A reuses that computation instead of inventing a second one.

1. An author edits a KB doc and introduces the phrase `Thin Doorway` with no glossary entry.
2. `kb-language-lint.sh --root . --check glossary` runs — from the `kb-hygiene` CI job, from the
   `/aid-discover` REVIEW mechanical-oracle step, or by hand.
3. The lint builds the **candidate universe** in two harvests, both using the shipped
   `harvest-coined-terms.sh` with a `--top` large enough that the emitted list is never truncated:
   - `--root .` over the project sources. Its prune set excludes `.aid`, so this harvest supplies
     terms coined in `canonical/`, `lib/`, `dashboard/`, `tests/`, config, code comments, and the
     subjects and bodies of the last 500 git-log commits.
   - `--root .aid/knowledge` over the KB itself. The prune set matches directory *names* under the
     scan root, and `.aid` is not a directory under `.aid/knowledge`, so nothing is pruned. This
     second harvest is what catches a term coined **only** in KB prose — the dominant case in
     REQUIREMENTS.md §2 — which the first harvest structurally cannot see.
4. The lint concatenates the two `## Ranked Candidates` tables into
   `.aid/.temp/kb-language/candidates.md`, deduplicating by term. It also parses
   `domain-glossary.md`'s `## Lexicon — *`, `## Abbreviations & Acronyms`, and
   `## Terms with Specific Domain Meanings` tables into
   `.aid/.temp/kb-language/defined-extra.txt`, one table-defined term per line, for the
   `--defined-extra` input the next step passes.
5. `closure-check.sh --concepts .aid/.temp/kb-language/candidates.md
   --spine .aid/knowledge/domain-glossary.md --kb-dir .aid/knowledge
   --dismissed .aid/knowledge/.glossary-dismissed.txt
   --defined-extra .aid/.temp/kb-language/defined-extra.txt --output-a <tmp>`
   runs. It subtracts the shipped denylist, the project-local denylist, and the dismissal list;
   normalizes by slash-split and regular-plural singularization; resolves each remaining term
   against the glossary's defined-identifier set — the `## Concept Spine` parse unioned with the
   `--defined-extra` terms, so a term the glossary defines only in a table is not reported as a gap;
   and emits output (a) — one `term | used-in-doc | anchor` row per undefined term actually present
   in a KB doc body. Omitting `--defined-extra` would reintroduce exactly the false positive this
   flow exists to close: every Lexicon- or Abbreviations-defined term reported as a `[GLOSSARY-GAP]`.
6. `Thin Doorway` survives the denylist (the word `doorway` is not a common word on the list),
   is absent from the defined set, and is present in the doc body, so it appears as a row.
7. The lint converts each output-(a) row into
   `  [GLOSSARY-GAP] <doc>: coined term "Thin Doorway" has no domain-glossary.md definition`
   and exits 1.
8. In CI, the `kb-hygiene` job fails and the merge is blocked. Under `/aid-discover` REVIEW, the
   orchestrator hands the findings to the reviewer, which records them as HIGH ledger rows, so
   `grade.sh` drops the grade below the `A` floor and the phase cannot advance.
9. The author closes the finding one of three ways: add a `### Thin Doorway` entry to
   `domain-glossary.md § Concept Spine`; add `Thin Doorway` as an `**Aliases:**` value on the
   existing spine concept it is a synonym for; or replace the phrase with plain words. Recording it
   in `.glossary-dismissed.txt` is the fourth route and is reserved for a token that is not a
   concept at all — it costs an explicit, reviewable entry (a reason comment line plus its term).

**What counts as a "coined term" — the computability rule.** The check does not carry its own
definition of "coined". A term is a coined term for this gate exactly when it is a member of the
computed set below. Every clause is already implemented and test-covered in this repo:

| Element | Rule | Implemented by |
|---|---|---|
| Candidate extraction | From the docs channel: E2 (CamelCase, kept both joined and split), E4 (runs of 2-4 capitalized words), E5 (quoted strings up to 4 words). Additionally from the code channel: E1 (identifiers, length >= 4), E3 (snake/kebab compounds, length >= 5), E2, E5; from the config channel: E3 and joined-only E2; from the comments and git-log channels: E4 and E2 | `harvest-coined-terms.sh` extraction classes |
| Scan scope | Project sources (root harvest) **union** `.aid/knowledge/` (KB harvest) | The two-harvest step above |
| Common-word rejection | A candidate survives only if at least one component word is off the ~300-word shipped denylist; an all-common phrase survives only via the whole-phrase escape at cross-source spread >= 2 | `coined-term-denylist.txt` + the rank/filter pass |
| Project-local rejection | Additional common words a project declares | `.aid/knowledge/.coined-term-denylist.local.txt` (already supported) |
| Explicit dismissal | A term the maintainer has judged not a concept, with a recorded reason | `.aid/knowledge/.glossary-dismissed.txt` -> `closure-check.sh --dismissed` |
| "Defined" | A `### <Term>` heading under `## Concept Spine` (parenthetical stripped), an `**Aliases:**` value under such a heading, or a first-column term in a `## Lexicon — *` / `## Abbreviations & Acronyms` / `## Terms with Specific Domain Meanings` table | `closure-check.sh` spine parse, plus the additive `--defined-extra` input below |
| Normalization | Slash-split (`canonical / profile` -> two terms) and regular-plural singularization (`-s`/`-es`/`-ies`), applied symmetrically to defined identifiers and used terms | `closure-check.sh` `norm_terms` |
| "Used" | Case-insensitive literal substring match in a `.aid/knowledge/*.md` body | `closure-check.sh` batched presence scan |

The one gap this leaves is named rather than hidden, and it is the reason the enforcement split is
(c) and not (a): the docs-channel extraction classes are CamelCase, capitalized multi-word phrases,
and quoted strings, so **a single-word all-lowercase coinage that appears nowhere but KB prose is
not extracted** and cannot be caught mechanically. That residue is exactly what the
`[AUTHORING-CLARITY]` reviewer check owns (Flow C). Any such term the rewrite chooses to keep is
capitalized, quoted, or hyphenated on first use — all three forms are extractable — which converts
most of the residue into the mechanical class by an authoring convention rather than by a smarter
regex.

**Why `closure-check.sh` needs one additive input.** Its current spine parse recognizes only
`### ` headings and `**Aliases:**` under `## Concept Spine`. `domain-glossary.md` also defines terms
in eight `## Lexicon — *` tables, an `## Abbreviations & Acronyms` table, and a
`## Terms with Specific Domain Meanings` table. Without those, a term already defined in the
glossary would be reported as undefined, and the only ways to silence it would be to promote it into
the 32-entry Concept Spine (misrepresenting the doc's structure and the spine's meaning) or to
dismiss it (asserting it is not a concept, which is false). So `closure-check.sh` gains one optional
flag, `--defined-extra <file>`, whose contents are unioned into the defined-identifier set before
normalization. `kb-language-lint.sh` generates that file by parsing the glossary's table sections.
The flag defaults to absent, in which case the script's behavior is byte-identical to today's — this
is what keeps `test-closure-check.sh` and the essence/teachback fixtures green (AC-17).

REQUIREMENTS.md AC-2 phrases the obligation as "a `### ` definition". This SPEC reads that as
"a definition in `domain-glossary.md`", because that is what FR-3 and §4 require and because the
`### ` form names where a **new concept** goes. A term the glossary already defines in a Lexicon
table is already defined; requiring it to be re-listed as `### ` would contradict the doc's own
structure. The default route for a newly retained coined term remains a spine `### ` entry or an
alias on one.

#### Flow B — a frontmatter readability violation

1. An author writes an `objective:` that chains four abstractions across 38 words.
2. `kb-language-lint.sh --check frontmatter` reads each in-scope doc's frontmatter with the same
   single-pass awk contract `lint-frontmatter.sh` uses (`kb-category:` in {primary, extension} and
   `source:` not `generated`; meta and generated docs skipped).
3. It counts: `objective:` must be one physical line of at most 25 whitespace-delimited words;
   `summary:` must be at most 2 sentences (split on `.`, `?`, `!` followed by whitespace or
   end-of-line) of at most 30 words each, with at most 1 em-dash.
4. The 38-word `objective:` emits
   `  [LANG-FRONTMATTER] architecture.md: 'objective:' is 38 words (max 25)` and the script exits 1.
5. Same downstream as Flow A: `kb-hygiene` fails the merge; the reviewer records a HIGH row.
6. Because `INDEX.md` is composed mechanically from these two fields, fixing the source doc and
   re-running `build-kb-index.sh` is the only way the routing table improves. `INDEX.md` is never
   edited (REQUIREMENTS.md §7).

#### Flow C — a judgment-level plain-language violation

1. A doc's prose is grammatical, uses only defined terms, and still stacks abstractions so densely
   that a junior cannot follow it; or it opens with `SYNTHESIS` as a bare token.
2. No script can decide this, so the reviewer does. `review-rubric.md § Rubric: Full Primary` gains
   two checks: reading level (`[AUTHORING-CLARITY]`, MEDIUM) and shouted-code resolvability
   (`[AUTHORING-CODE]`, MEDIUM). Both are added to the "Lint output -> severity mapping" table so
   every reviewer that applies the rubric — not only the `/aid-discover` M2 Anatomy panel dispatch —
   carries them.
3. `reviewer-prompt-anatomy.md`'s Authoring Standard checklist is updated to point at the rubric as
   the source of truth for these two checks and to add the shouted-code check, so the panel prompt
   and the rubric say one thing.
4. The reviewer writes a 7-column ledger row at `.aid/.temp/review-pending/<scope>.md` with the
   bracketed severity; `grade.sh` counts it; the phase cannot advance below the resolved floor.

#### Flow D — verifying that the rewrite preserved the knowledge (AC-1)

Run per doc, by the task that rewrites that doc, before it hands off. No new tooling: git, grep, and
awk only, run inline in the work's worktree. This produces no shipped script, because it verifies a
one-time migration rather than a durable capability.

1. **Capture the baseline.** `git show <work-base-commit>:.aid/knowledge/<doc>.md > <tmp>/before.md`.
2. **Extract invariants from both versions** into sorted sets:
   (i) every fenced code block's body; (ii) every inline-code span, which is where paths, commands,
   enum values, field names, exit codes, and script names live; (iii) every link target;
   (iv) every `sources:` entry; (v) every table row's cell list.
3. **Assert set equality on (i)-(iv).** These are the mechanical carriers of the doc's contracts, and
   a prose rewrite has no reason to change any of them. Any difference is a defect until the task
   justifies it in the handoff note — the sole legitimate case is an inline-code span that was itself
   jargon rather than a real identifier.
4. **Assert cell survival on (v).** A table row's prose cells may be re-worded, but every cell
   containing an inline-code span or an enum token must survive with the same value, and the row
   count per table must not drop.
5. **Claim ledger for the residue.** Enumerate the before-version's factual claims as a numbered
   list; locate each in the after version; mark it `present`, `absent`, or `scope-changed`. Any
   `absent` or `scope-changed` entry is an AC-1 violation unless it is a pure wording change. The
   ledger is attached to the task's handoff so the reviewer verifies rather than rediscovers.
6. **Bound the growth.** `wc -w` on both versions; the after count must be at most 115% of the
   REQUIREMENTS.md §4 baseline (AC-6).

Pre-existing factual defects and internal contradictions are carried forward untouched
(REQUIREMENTS.md §8) — including the `## Change Log` conflict between `authoring-conventions.md`
§ KB Document Layout and `principles.md` P10 Layout. Fixing a fact during a wording refactor would
itself break AC-1.

### Layers & Components

The refactor touches five layers. Every file that changes is named; nothing else changes.

#### Layer 1 — the KB corpus (`.aid/knowledge/`, hand-authored)

| File | Change | Notes |
|---|---|---|
| `domain-glossary.md` | Prose + frontmatter rewrite; new `### ` spine entries and `**Aliases:**` values for retained coined terms | **Rewritten first** (FR-6): every other doc's wording depends on the settled term set |
| `architecture.md`, `artifact-schemas.md`, `capability-inventory.md`, `coding-standards.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `pipeline-contracts.md`, `project-structure.md`, `tech-debt.md`, `technology-stack.md`, `test-landscape.md` | Prose + frontmatter rewrite | 12 primary docs; `tech-debt.md` (9674 words) and `test-landscape.md` (5125) carry the most work |
| `decisions.md`, `quality-gates.md`, `release-tracking.md` | Prose + frontmatter rewrite | 3 extension docs; same rubric treatment as primary |
| `authoring-conventions.md` | Prose + frontmatter rewrite **plus** the mirrored rule (FR-9) | § Dual-Audience Standard states the tightened plain-language and glossary-coverage rule; § Enforcement gains rows for `kb-language-lint.sh` (Automatic: Yes) and the two reviewer tags (Automatic: No), naming the same severities the canonical rubric assigns |
| `.glossary-dismissed.txt` | **New** | Durable dismissal list; dot-prefixed so `find ... ! -name '.*'` in the existing KB scripts skips it as a doc |
| `.coined-term-denylist.local.txt` | May gain entries | Existing mechanism |
| `INDEX.md` | **Regenerated, never authored** | `build-kb-index.sh` after all frontmatter is final |
| `relationships.md`, `kb.html` | **Untouched** | Generated; out of scope (REQUIREMENTS.md §4) |
| `README.md`, `STATE.md`, `external-sources.md` | **Untouched** | Meta, review-exempt |

Binding constraint restated here because it binds every row above: `.aid/knowledge/**` must contain
no work id and no work-folder path — not `work-008`, not `.aid/works/work-008-*/`, not "added in
work-008" — in prose, tables, headings, or frontmatter. The reviewer treats any `work-[0-9]{3}` hit
as HIGH with no exception. The SPEC, PLAN, and task files may name the work freely; the KB may not.

#### Layer 2 — the enforcement script (`canonical/aid/scripts/kb/`)

| File | Change | Notes |
|---|---|---|
| `kb-language-lint.sh` | **New** | Bash. Flags: `--root <repo>`, `--kb-dir <path>`, `--check glossary\|frontmatter\|all` (default `all`), `--verbose`, `-h/--help`. Exit codes 0 clean, 1 findings, 2 usage — the linter convention `kb-citation-lint.sh` and `lint-frontmatter.sh` already share. Header block with Purpose/Usage/Exit codes per `coding-standards.md`. Orchestrates the two harvests, the merged candidate table, the `--defined-extra` extraction, and the `closure-check.sh` call; owns the frontmatter word/sentence counting itself |
| `closure-check.sh` | **Additive only** | One new optional flag `--defined-extra <file>`, unioned into the defined-identifier set before normalization. Absent by default; default invocation stays byte-identical (AC-17) |
| `harvest-coined-terms.sh`, `coined-term-denylist.txt`, `lint-frontmatter.sh`, `kb-citation-lint.sh`, `build-kb-index.sh` | **Unchanged** | Reused as-is. `lint-frontmatter.sh` keeps owning presence-and-shape; the new lint owns readability, so the two never overlap |

**No PowerShell twin is required.** The twin rule in `coding-standards.md § Conventions` binds when
touching a language twin, and `canonical/aid/scripts/kb/` is a bash-only family — 13 scripts plus one data file, zero
`.ps1`. Adding a twin here would create a parity-drift liability the family has deliberately avoided.
ASCII-only still binds (the shipped-script rule and `tests/canonical/test-ascii-only.sh`), as does the
`set -euo pipefail` strict-mode convention, relaxed to `set -uo pipefail` only if the script must
tolerate a non-zero `grep`, as `kb-citation-lint.sh` does.

#### Layer 3 — the canonical rule set and reviewer wiring (`canonical/`)

| File | Change |
|---|---|
| `canonical/aid/templates/kb-authoring/principles.md` | P10 § Language: the plain-language and define-on-first-use expectations become stated, checked conditions naming `kb-language-lint.sh` and the two reviewer tags. P4 ("Enforce via review, not by mechanical lint") gains the narrow carve-out this work creates, so P4 and the new script do not contradict |
| `canonical/aid/templates/kb-authoring/review-rubric.md` | § Rubric: Full Primary gains two checks — reading level `[AUTHORING-CLARITY]` MEDIUM and shouted-code resolvability `[AUTHORING-CODE]` MEDIUM. § Lint output -> severity mapping gains four rows: `[GLOSSARY-GAP]` HIGH, `[LANG-FRONTMATTER]` HIGH, `[AUTHORING-CLARITY]` MEDIUM, `[AUTHORING-CODE]` MEDIUM. The two MEDIUM rows must carry an explicit severity prefix, per the table's own standing rule that a non-HIGH lint tag never ships bare |
| `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | The readability bounds for `objective:`/`summary:` are recorded next to the existing shape rules. No new field |
| `canonical/aid/templates/kb-authoring/concern-model.md` | **Unchanged** — read for consistency only; the concern spine is not in scope |
| `canonical/skills/aid-discover/references/state-review.md` | `kb-language-lint.sh` is added to the deterministic oracles the orchestrator runs before dispatching the panel, alongside `closure-check.sh` and `kb-dual-intent-probes.sh` |
| `canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md` | The Authoring Standard checklist's item 15 points at the rubric as source of truth; a shouted-code check is added; the severity-anchor list gains the two tags |
| `canonical/skills/aid-discover/references/document-expectations.md` | The plain-language and glossary-coverage expectation is stated where per-doc expectations live |
| `canonical/skills/**` prose | **Unchanged** — REQUIREMENTS.md §4 puts a style sweep of shipped skill prose out of scope; only the authoring rule changes |

#### Layer 4 — render and dogfood resync (obligation, not authorship)

Nothing under `profiles/` is hand-edited. Every `canonical/` change in Layers 2 and 3 reaches the
five profile trees through one command, and this repo additionally consumes its own output:

| Step | Command / artifact | Why |
|---|---|---|
| Render | `python .claude/skills/generate-profile/scripts/run_generator.py` | Emits `canonical/aid/scripts/` and `canonical/aid/templates/` into `.claude/`, `.codex/`, `.cursor/`, `.agent/`, and `.github/aid/` under `profiles/`, refreshing each profile's `emission-manifest.jsonl` |
| Dogfood resync | The repo-root `.claude/` and `.cursor/` trees | This repo installs its own toolkit. `tests/canonical/test-dogfood-byte-identity.sh` checks three directions — manifest-to-dogfood hash match, manifest completeness, and a repo-orphan sweep — and fails on any drift |
| Verify | `git diff --exit-code -- profiles/` then `bash tests/canonical/test-dogfood-byte-identity.sh` | AC-9. A non-empty diff means the render was not re-run or `profiles/` was hand-edited |

The render must be deterministic: a second `run_generator.py` run produces no diff
(REQUIREMENTS.md §6).

#### Layer 5 — tests and CI

| File | Change |
|---|---|
| `tests/canonical/test-kb-language-lint.sh` | **New** suite. Discovered by the `tests/canonical/test-*.sh` glob, so `run-all.sh` needs no edit. Carries `# COVERS:` headers for `canonical/aid/scripts/kb/kb-language-lint.sh` and its fixture dir. Follows S1 (one subject invocation per distinct fixture, asserted many times), S2 (single-pass read into arrays, no per-assertion command substitution), and S5 (mutate only a `mktemp -d` copy) |
| `tests/canonical/fixtures/kb-language-lint/undefined/` | **New** negative fixture: a minimal KB whose doc introduces a coined term with no glossary entry and no dismissal row. The lint must exit 1 with `[GLOSSARY-GAP]` |
| `tests/canonical/fixtures/kb-language-lint/defined/` | **New** positive fixture: byte-identical except the term carries a `### ` glossary entry. The lint must exit 0 |
| Frontmatter fixtures under the same dir | Over-length `objective:` and multi-sentence `summary:` cases, plus their in-bounds twins |
| `tests/coverage-baseline.tsv` | Register the new suite's coverage rows so `tests/coverage-parity.sh` stays green |
| `tests/canonical/test-closure-check.sh` | **Unchanged and must stay green** — proves the `--defined-extra` addition is behavior-preserving on the default path (AC-17) |
| `.github/workflows/test.yml` (`kb-hygiene` job) | One new step running `kb-language-lint.sh --root .` after the frontmatter-lint step and before the INDEX-freshness step. Repo-local; not rendered |

The fixture pair is the load-bearing artifact of the whole enforcement half: AC-7 is satisfied only
when the negative fixture actually fails and its twin actually passes. A check that cannot fail is
not a check.

#### The enforcement decision, and why

REQUIREMENTS.md §8 defers the choice of mechanism to this SPEC. The decision is **(c) — both,
split by what is mechanically decidable and what needs judgment.**

The evidence for the split, from this repo's own conventions:

1. **`authoring-conventions.md` § Enforcement already draws exactly this line.** Its table separates
   automatic script gates (frontmatter lint, citation lint, grade, render drift, ASCII/PS 5.1) from
   `aid-reviewer` semantic checks (doc layout, one-concern, dual-audience, no-diagrams). The
   plain-language rule spans both classes, so it belongs in both columns rather than being forced
   into one.
2. **Glossary coverage is already computed mechanically and is already HIGH.** `[CLOSURE-GAP]` exists
   in the rubric today with exactly this meaning, produced by `closure-check.sh` output (a). Choosing
   (b) alone would demote a check the project already knows how to decide by script into reviewer
   recall — a regression. What is missing is not the computation; it is a standing gate over
   `.aid/knowledge/` outside the `/aid-discover` GENERATE loop, which `kb-hygiene` currently does not
   provide: its KB steps are the frontmatter lint, an AID-repo-local strict frontmatter assertion,
   and the INDEX freshness check — nothing that reads KB prose.
3. **The frontmatter bounds in REQUIREMENTS.md §6 are already stated as counts** — 25 words,
   2 sentences, 30 words, 1 em-dash. A number a script can count must not be a judgment call;
   `test-landscape.md`'s S-conventions and `coding-standards.md`'s linter family both treat countable
   invariants as script territory.
4. **Reading level cannot be scripted honestly, and this repo already says so.** `principles.md` P4
   argues against brittle mechanical lints for semantic rules, and
   `reviewer-prompt-anatomy.md` already carries `[AUTHORING-CLARITY]` as a runtime judgment. A
   readability-score lint would be a new metric with no anchor in the project's conventions, would
   flag correct dense technical writing, and would need a scoring dependency the NFR forbids.
   Choosing (a) alone would therefore either miss the jargon-density defect entirely or produce a
   noisy gate the team would learn to bypass.
5. **(c) satisfies the NFR "no new toolchain dependency" exactly.** Every mechanical clause reuses a
   shipped bash script; the judgment clauses are prose in files that already exist.

The split, stated once:

| Obligation | Mechanism | Tag | Rationale |
|---|---|---|---|
| A coined term used with no glossary definition | Script | `[GLOSSARY-GAP]` HIGH | Already computable; the term universe, denylist, and defined set are all deterministic |
| `objective:`/`summary:` over the readability bounds | Script | `[LANG-FRONTMATTER]` HIGH | Pure counting against numbers REQUIREMENTS.md §6 already fixes |
| Jargon-dense prose a junior cannot follow | Reviewer | `[AUTHORING-CLARITY]` MEDIUM | No honest mechanical oracle; already a named judgment surface in the anatomy prompt |
| A shouted bare code with no expansion or legend | Reviewer | `[AUTHORING-CODE]` MEDIUM | The token set is open-ended and "resolves to a legend" needs reading; a regex would flag every legitimate acronym |

#### Sequencing constraints (input to PLAN, not a plan)

Three orderings are forced by the design and must survive into the task graph:

1. The enforcement mechanism (Layers 2, 3, 5) lands **before** the corpus rewrite, so every doc is
   written against the standard it will be graded by, and so the fixture pair proves the gate works
   before 17 docs depend on it.
2. `domain-glossary.md` is rewritten and completed **before** the other 16 docs (FR-6), because the
   settled term set decides, for every other doc, whether a term is kept and defined or replaced.
3. `build-kb-index.sh` runs **last** among KB steps, after every doc's frontmatter is final; and the
   generator render plus dogfood resync run last overall, after the final `canonical/` edit. Both are
   the standing "generated files refresh last" rule (`principles.md` P3).

# Delivery BLUEPRINT -- delivery-001: Plain-Language Knowledge Base Rewrite

> **Delivery:** delivery-001
> **Work:** work-008-kb-plain-language
> **Created:** 2026-08-11

---

## Objective

The Knowledge Base under `.aid/knowledge/` breaks a rule it publishes about itself: its own
`authoring-conventions.md`, and the canonical rule it mirrors, demand plain words, short sentences,
and a glossary entry for every project-specific term, but nothing checks that. This delivery closes
both halves of that gap in one unit, because neither half is worth shipping alone. It **rewrites the
wording** of the 17 hand-authored primary and extension KB docs so a junior professional can read
them, changing no fact, contract, enum, table row, path, command, or citation -- a prose refactor
whose behavior-preservation guarantee is that the KB asserts afterwards exactly what it asserted
before. And it **turns the rule into a check**: a doc that uses an invented term with no glossary
definition, or whose frontmatter blows past the readability bounds, fails a shipped script; prose
that is merely dense fails a named reviewer check with a stated severity. Rewriting without the
check leaves the drift free to return with the next author; adding the check without the rewrite
would fail the corpus it governs on day one.

## Scope

In scope for delivery-001 (REQUIREMENTS.md §4 In Scope; SPEC.md `### Layers & Components`):

- **The KB corpus rewrite** -- prose and `objective:`/`summary:` frontmatter on all 17 in-scope docs:
  `domain-glossary.md`, `architecture.md`, `artifact-schemas.md`, `authoring-conventions.md`,
  `capability-inventory.md`, `coding-standards.md`, `infrastructure.md`, `integration-map.md`,
  `module-map.md`, `pipeline-contracts.md`, `project-structure.md`, `tech-debt.md`,
  `technology-stack.md`, `test-landscape.md`, `decisions.md`, `quality-gates.md`,
  `release-tracking.md`.
- **Glossary completion** -- every coined term the rewritten KB retains gains a `domain-glossary.md`
  definition (a `## Concept Spine` `### ` entry or an `**Aliases:**` value on one); terms not worth
  defining are replaced with plain words; terms that are not concepts at all are recorded, with a
  reason, in the new `.aid/knowledge/.glossary-dismissed.txt`.
- **Shouted-code resolution** -- every bare code (`CONFIRMED`, `SYNTHESIS`, `ELICIT E1/E2`, `S1-S5`,
  `T1-T6`, `P1`/`P9`/`P10`, `C0`-`C9`, `APPROVAL-HALT`, and the rest of the class) is expanded on
  first use or resolves to a named legend or glossary entry.
- **The enforcement script** -- new `canonical/aid/scripts/kb/kb-language-lint.sh` (bash, ASCII-only,
  exit 0/1/2), plus one additive optional `--defined-extra <file>` flag on `closure-check.sh`.
- **The canonical rule set and reviewer wiring** -- `kb-authoring/principles.md` (P10 Language, and
  the P4 carve-out), `kb-authoring/review-rubric.md` (two Full Primary checks; four lint-tag severity
  rows), `kb-authoring/frontmatter-schema.md` (readability bounds recorded, no new field), and
  `canonical/skills/aid-discover/references/` -- `state-review.md`, `reviewer-prompt-anatomy.md`,
  `document-expectations.md`.
- **The KB mirror** -- `.aid/knowledge/authoring-conventions.md` § Dual-Audience Standard and
  § Enforcement restate the tightened rule and name the same script, tags, and severities.
- **Tests and CI** -- new `tests/canonical/test-kb-language-lint.sh` with its
  `undefined/`/`defined/` fixture pair and frontmatter fixtures, new rows in
  `tests/coverage-baseline.tsv`, and one new `kb-language-lint.sh` step in the `kb-hygiene` job of
  `.github/workflows/test.yml`.
- **Regeneration** -- `INDEX.md` rebuilt with `build-kb-index.sh` after all frontmatter is final;
  `profiles/` re-rendered with the generator and the `.claude/`/`.cursor/` dogfood trees resynced,
  after the final `canonical/` edit.

**Out of scope:** a style sweep of the shipped prose under `canonical/skills/**` (only the authoring
*rule* changes there); the generated KB artifacts `relationships.md` and `kb.html`; the body of
`INDEX.md` (fixed only by fixing source frontmatter, never edited); any change to the knowledge the
KB records -- no new facts, no removed facts, no re-scoped claims, and pre-existing factual defects
and internal contradictions are carried forward untouched (including the `## Change Log` conflict
between `authoring-conventions.md` § KB Document Layout and `principles.md` P10 Layout); hand-edits
to the five `profiles/` renders; the meta docs `README.md`, `STATE.md`, and `external-sources.md`;
any new field on the KB frontmatter schema; and a PowerShell twin of the new lint (the
`canonical/aid/scripts/kb/` family is bash-only).

## Gate Criteria

Each criterion below is the delivery-gate form of the matching SPEC.md `## Acceptance Criteria`
entry. Paths are repo-relative and every command runs from the work's worktree root.

- [ ] **AC-1 -- Knowledge unchanged.** For each rewritten doc, the per-doc invariant diff against
      `git show <work-base-commit>:.aid/knowledge/<doc>.md` shows equal sorted sets for fenced
      code-block bodies, inline-code spans, link targets, and `sources:` entries; every table row's
      inline-code and enum cells survive with the same value and no table loses rows; and the task's
      claim ledger marks every before-version claim `present`, with any `absent` or `scope-changed`
      entry justified as a pure wording change in the handoff note.
- [ ] **AC-2 -- No undefined coined term.**
      `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` exits 0 with zero
      `[GLOSSARY-GAP]` lines; and for each term named in REQUIREMENTS.md §2, a case-insensitive grep
      over `.aid/knowledge/*.md` either returns no hit or the term resolves to a `domain-glossary.md`
      definition (a `## Concept Spine` `### ` heading, an `**Aliases:**` value, or a Lexicon /
      Abbreviations / Domain-Meanings table term).
- [ ] **AC-3 -- No opaque bare code.** For every shouted token class in REQUIREMENTS.md §5 FR-4, its
      first occurrence in each of the 17 docs is expanded inline or resolves to a named legend or
      glossary entry, and the reviewer's `[AUTHORING-CODE]` check over those docs records no finding
      above MINOR.
- [ ] **AC-4 -- Frontmatter within bounds.**
      `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` exits 0 over
      `.aid/knowledge/`, emitting no `[LANG-FRONTMATTER]` line -- specifically none for
      `architecture.md`'s `objective:` (one line, <= 25 words) or `test-landscape.md`'s `summary:`
      (<= 2 sentences, <= 30 words each, <= 1 em-dash).
- [ ] **AC-5 -- INDEX regenerated, not edited.**
      `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
      succeeds, the resulting `INDEX.md` carries the rewritten `objective:`/`summary:` text, and a
      second run followed by `git diff --exit-code -- .aid/knowledge/INDEX.md` exits 0.
- [ ] **AC-6 -- Growth budget respected.** For each of the 17 docs, `wc -w` on the rewritten file is
      at most 115% of that doc's REQUIREMENTS.md §4 baseline word count.
- [ ] **AC-7 -- The rule is enforceable, proven by a negative fixture.**
      `kb-language-lint.sh --root tests/canonical/fixtures/kb-language-lint/undefined/` exits 1 and
      prints a `[GLOSSARY-GAP]` line naming the fixture's undefined coined term; the sibling
      `.../defined/` fixture, identical except that the term carries a `### ` glossary entry, exits
      0. Both fixtures passing, or both failing, fails this criterion.
- [ ] **AC-8 -- Canonical and KB agree.** Each of the four tags (`[GLOSSARY-GAP]`,
      `[LANG-FRONTMATTER]`, `[AUTHORING-CLARITY]`, `[AUTHORING-CODE]`) appears with the same severity
      in `canonical/aid/templates/kb-authoring/review-rubric.md` § Lint output -> severity mapping and
      in `.aid/knowledge/authoring-conventions.md` § Enforcement; `principles.md` P10 § Language and
      `authoring-conventions.md` § Dual-Audience Standard state the same rule and name
      `kb-language-lint.sh` as its mechanism; a side-by-side read of the three records no
      contradiction.
- [ ] **AC-9 -- Render is clean.**
      `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/`
      exits 0, a second generator run leaves the tree unchanged, and
      `bash tests/canonical/test-dogfood-byte-identity.sh` passes.
- [ ] **AC-10 -- Existing lints pass.** `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0, with no
      `[FM-MISSING]`, `[FM-INVALID]`, or positional-citation (`file:LINE`) finding.
- [ ] **AC-11 -- No work references in the KB.** `grep -rE 'work-[0-9]{3}' .aid/knowledge/` returns
      no match (exit 1) -- in prose, tables, headings, or frontmatter.
- [ ] **AC-12 -- Grade gate cleared.** `aid-reviewer` grading the rewritten KB against the tightened
      rubric leaves no `[GLOSSARY-GAP]`, `[LANG-FRONTMATTER]`, `[AUTHORING-CLARITY]`, or
      `[AUTHORING-CODE]` ledger row above MINOR, and `grade.sh` over that ledger returns at least the
      resolved `minimum_grade` of `A`.
- [ ] **AC-13 -- Enforcement adds no toolchain dependency.** Reading `kb-language-lint.sh`'s
      invocation set shows it calls nothing outside the tools `technology-stack.md` already declares
      (bash, coreutils, awk, git; ripgrep optional), and
      `AID_HARVEST_NO_RG=1 bash canonical/aid/scripts/kb/kb-language-lint.sh --root .` produces
      findings identical to the default run.
- [ ] **AC-14 -- Every silenced term is auditable.** Every non-blank, non-comment line of
      `.aid/knowledge/.glossary-dismissed.txt` carries exactly one bare term, each such term is
      immediately preceded by a `#` comment line stating its reason (the only form
      `closure-check.sh --dismissed` parses -- it drops `#`-leading lines and does not strip an
      inline `#`), and no term listed there also carries a `domain-glossary.md` definition.
- [ ] **AC-15 -- The check is wired where it can block.** The `kb-hygiene` job in
      `.github/workflows/test.yml` contains a step running `kb-language-lint.sh --root .`, and
      `canonical/skills/aid-discover/references/state-review.md` lists `kb-language-lint.sh` among the
      deterministic oracles the orchestrator runs before dispatching the reviewer panel.
- [ ] **AC-16 -- The gate is test-covered.** `bash tests/run-all.sh` discovers
      `tests/canonical/test-kb-language-lint.sh` through the `tests/canonical/test-*.sh` glob and the
      suite passes; the suite carries `# COVERS:` headers for
      `canonical/aid/scripts/kb/kb-language-lint.sh` and its fixture directory; and
      `bash tests/coverage-parity.sh` exits 0 with the new rows present in
      `tests/coverage-baseline.tsv`.
- [ ] **AC-17 -- Existing oracles keep their behavior.**
      `bash tests/canonical/test-closure-check.sh` and the essence/teachback suites pass unchanged,
      and `closure-check.sh` invoked without `--defined-extra` produces output byte-identical to the
      pre-change script on the same inputs.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

> **What the last criterion names.** The two criteria above are the standing pair every delivery
> carries verbatim (`shortcut-engine.md` § State: PLAN Step 2b;
> `canonical/aid/templates/delivery-blueprint-template.md`), so their wording is fixed. "section-6"
> is **`REQUIREMENTS.md` §6 Non-Functional Requirements** -- the numbered requirements section the
> phrase has pointed at since it entered the templates
> (`canonical/skills/aid-describe/references/interview-strategies.md` § Quality gates inference
> derives a work's quality gates from "Section 6 (Non-Functional Requirements)"), not a section of
> this BLUEPRINT, which has none. For this delivery it resolves to five gates, each already testable
> above: the frontmatter readability bounds (AC-4), the 15% growth budget (AC-6), no new toolchain
> dependency (AC-13), a deterministic generator render (AC-9), and the resolved `minimum_grade` of
> `A` (AC-12). It adds nothing beyond those five and is satisfied exactly when they pass. The
> identical closing criterion on every `tasks/task-NNN/DETAIL.md` resolves the same way.

## Tasks

Fifteen tasks; each has a full `DETAIL.md` at `tasks/task-NNN/DETAIL.md`. The wave structure and the
dependency table live in `PLAN.md § Execution Graph`.

| Task | Type | Title |
|------|------|-------|
| task-001 | RESEARCH | Enumerate the coined-term and shouted-code universe and decide a disposition for every term |
| task-002 | IMPLEMENT | Build kb-language-lint.sh and add the additive --defined-extra flag to closure-check.sh |
| task-003 | TEST | Cover the new lint with test-kb-language-lint.sh and its undefined/defined fixture pair |
| task-004 | DOCUMENT | Tighten the canonical KB-authoring rule set and the reviewer rubric |
| task-005 | CONFIGURE | Wire kb-language-lint.sh into the kb-hygiene CI job and the discover REVIEW oracles |
| task-006 | REFACTOR | Rewrite domain-glossary.md and land the settled term set |
| task-007 | REFACTOR | Rewrite the system-shape docs -- architecture, module-map, project-structure, integration-map |
| task-008 | REFACTOR | Rewrite the contract and capability docs -- artifact-schemas, pipeline-contracts, capability-inventory |
| task-009 | REFACTOR | Rewrite the platform and standards docs -- technology-stack, infrastructure, coding-standards |
| task-010 | REFACTOR | Rewrite the verification docs -- test-landscape, quality-gates |
| task-011 | REFACTOR | Rewrite tech-debt.md |
| task-012 | REFACTOR | Rewrite the decision and release ledger docs -- decisions, release-tracking |
| task-013 | DOCUMENT | Rewrite authoring-conventions.md and mirror the tightened rule into the KB |
| task-014 | CONFIGURE | Regenerate INDEX.md, re-render profiles/, and resync the dogfood trees |
| task-015 | TEST | Run the delivery-wide verification sweep and clear the grade gate |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-refactor (refactor, artifact '').

Three orderings are forced by the design (SPEC.md `#### Sequencing constraints`) and must survive
into the task graph the DETAIL state writes:

1. The enforcement mechanism (the lint, the canonical rule set, the fixture pair) lands **before**
   the corpus rewrite, so every doc is written against the standard it will be graded by and the gate
   is proven to work before 17 docs depend on it.
2. `domain-glossary.md` is rewritten and completed **before** the other 16 docs, because the settled
   term set decides, for every other doc, whether a term is kept and defined or replaced.
3. `build-kb-index.sh` runs last among the KB steps, after every doc's frontmatter is final; the
   generator render and dogfood resync run last overall, after the final `canonical/` edit.

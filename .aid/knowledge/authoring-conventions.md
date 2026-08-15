---
kb-category: primary
source: hand-authored
objective: The conventions AID mandates for authoring its own artifacts -- KB docs, reviewer ledgers, skill prose, and content-isolated host files -- with the rules, examples, and where each is enforced.
summary: Read this before writing any AID methodology artifact (a KB doc, a reviewer ledger, a SKILL.md, a root agent-context file) to follow the project's authoring rules; for source-code style see coding-standards.md.
sources:
  - .claude/aid/templates/kb-authoring/principles.md
  - .claude/aid/templates/kb-authoring/frontmatter-schema.md
  - .claude/aid/templates/kb-authoring/concern-model.md
  - .claude/aid/templates/reviewer-ledger-schema.md
  - .claude/aid/scripts/kb/lint-frontmatter.sh
  - .claude/aid/scripts/kb/kb-citation-lint.sh
  - .claude/aid/scripts/grade.sh
  - CLAUDE.md
  - canonical/EMISSION-MANIFEST.md
tags: [C3, authoring, kb-authoring, reviewer-ledger, frontmatter, content-isolation, dual-audience, enforcement]
see_also: [coding-standards.md, artifact-schemas.md]
owner: architect
audience: [developer, architect, tech-writer, reviewer]
review-criteria:
  - id: F-01
    kind: validate
    criterion: "Every KB doc layout stated here holds: frontmatter, title, index, content sections, and no history section"
    severity: MEDIUM
    why: "This doc IS the layout contract, so a layout claim that is false here is false everywhere it is enforced -- and it was: it asserted a Change Log last section that the rule forbids and this file does not have"
  - id: F-02
    kind: validate
    criterion: "The reviewer ledger is described as a 7-column table with closed Severity and Status enums, consistent with reviewer-ledger-schema.md"
    severity: HIGH
    why: "A second, divergent description of the ledger teaches a reviewer to write rows grade.sh cannot parse"
  - id: F-03
    kind: validate
    criterion: "The required frontmatter fields named here are objective, summary and sources, matching what lint-frontmatter.sh grades"
    severity: MEDIUM
    why: "The lint is the oracle; a field list that disagrees with it either blocks a valid doc or lets an invalid one through"
---

# Authoring Conventions

AID is a methodology, so its primary "product" is **authored artifacts**: Knowledge
Base documents, reviewer ledgers, skill state-machine prose, requirement/spec/task
files, and the content it writes into a user's host files. This document records the
rules that govern how those artifacts are written, named, structured, and checked.

These rules exist because **review effort scales with what is in an artifact, not
with what is useful in it** (kb-authoring `principles.md`). Every claim a reviewer
must verify is a tax; the conventions remove drift-prone clutter and keep the
load-bearing core.

> Boundary: this doc covers **artifact/process authoring**. Source-code style
> (shell strict mode, exit codes, PowerShell 5.1 rules) lives in
> [coding-standards.md](coding-standards.md). The exact field schema of each
> artifact lives in [artifact-schemas.md](artifact-schemas.md). This doc is the
> *how to write it well* layer; that doc is the *required shape* layer.

## Contents

- [KB Document Layout](#kb-document-layout)
- [Review Criteria — Type Registry](#review-criteria--type-registry)
- [Review Criteria — Criteria by Level](#review-criteria--criteria-by-level)
- [Frontmatter Rules](#frontmatter-rules)
- [Dual-Audience Standard](#dual-audience-standard)
- [Drift-Prone Content is Banned](#drift-prone-content-is-banned)
- [Citation Rule (Durable Anchors)](#citation-rule-durable-anchors)
- [Signature Exception](#signature-exception)
- [Resolved Items Leave No Trace](#resolved-items-leave-no-trace)
- [Reviewer Ledger Convention](#reviewer-ledger-convention)
- [Plan-First (Review then Fix)](#plan-first-review-then-fix)
- [Concern Model (Doc-Set Derivation)](#concern-model-doc-set-derivation)
- [Prose Over Scripts](#prose-over-scripts)
- [Content Isolation](#content-isolation)
- [Generated and Temporary Files](#generated-and-temporary-files)
- [Conventions](#conventions)
- [Enforcement](#enforcement)

---

## KB Document Layout

Every KB document MUST follow this top-to-bottom order (kb-authoring P10):

| Position | Section | Rule |
|----------|---------|------|
| 1 | Frontmatter | YAML block between `---` markers; first content in the file (no BOM, no blank line before). |
| 2 | Title | a single `# Doc Title`. |
| 3 | Index / contents | required when the doc has more than 3 sections. |
| 4 | Content sections | the concern's substance. |

**There is no history section.** A KB doc carries no `## Change Log` / `## Revision History`
and no `changelog:` frontmatter field: git records per-doc history with author, date and diff,
at higher fidelity and without drift. Delete the section and the field where either still
appears; never author a new one. Every doc in this KB, including this one, ends with its last
content section.

---

## Review Criteria — Type Registry

A reviewer validates an authored artifact against the **criteria declared for it**, resolved through
three levels: **global** criteria (this document, `Applies to: *`), **per-document-type** criteria (this
document, keyed by type), and **per-file** exceptions (the file's own `review-criteria:` frontmatter).
The reviewer validates against the **union**; the most specific declaration wins on conflict. A criterion
is written **once, at the highest level where it is true** — a rule true for two files belongs at the
type level, one true for two types belongs at global — so most files declare few criteria or none.

This registry answers "what document types exist, and which one is a given file?". It covers the
in-scope corpus — the markdown under `canonical/skills/`, `canonical/agents/`,
`canonical/aid/templates/` and `.aid/knowledge/` — so every in-scope markdown file resolves to exactly
one type (criterion `G-07`).

**Resolution is first match in table order.** Rows are ordered most-specific-first and a file takes the
first row whose selector it satisfies; the two catch-all rows (`kb-doc`, `template-own`) close their
trees. Ordering is what makes the selectors mutually exclusive in practice rather than by careful
wording: `.aid/knowledge/STATE.md` satisfies `state`, `kb-generated` and `kb-meta` at once, and resolves
to `state` because that row comes first.

### The `Match` column

`Selector` is the prose a human reads. `Match` is the same selector in a form a check can
parse, so a tool never keeps its own second copy of the registry and cannot drift from it.

| Clause | Form | Meaning |
|--------|------|---------|
| Path | `path <glob>` | the file's repo-relative path matches the glob |
| Frontmatter | `fm <key> == <value>` | the file's frontmatter has that key with that scalar value |
| Membership | `name-in <file>` | the file's **parent directory name** appears as a `name:` value in `<file>` |

Clauses join with `AND`. There is deliberately no regex, no negation and no disjunction: a
row needing more than this is a row a check must leave undecided, which is the honest
outcome. `skill-authored`'s prose says "**not** a `shortcut-catalog.yml` row" and needs no
negation, because `skill-generated` precedes it and resolution is first-match-wins —
ordering does the work, exactly as stated above.

One reserved token, which is not a clause and is never evaluated:

| Token | Meaning |
|-------|---------|
| `<inexpressible>` | This row's selector cannot be fully expressed. A check reads the row's other clauses to get its **path bound**, then stops for any file inside that bound and reports it undecided. Such a row is never a match and never a non-match — it is a boundary. |

`template-payload` carries it because its recognizers test frontmatter *shape* (placeholder
tokens, an unquoted choice-list in a value position), which no `key == value` clause can
express. Its path bound is mandatory rather than cosmetic: without it, a check would stop
for *any* file that exhausted the expressible rows, including a genuine orphan elsewhere in
the corpus — reporting as merely undecided the very defect `G-07` exists to catch.
`template-own` is the catch-all over that same path space, so it is unreachable behind
`template-payload` and is inexpressible as a consequence of its neighbour rather than of
anything about itself. **Eight rows are fully expressible; those two are not.**

> **`Selector` and `Match` are one unit.** Changing either without the other is a defect.
> They state the same rule in two notations, so an edit to the prose that forgets the
> `Match` cell leaves a check silently classifying by the old rule. Re-running a check that
> prints its full classification, and diffing the output across the edit, shows exactly
> which files changed type — an intended edit produces an expected diff; a forgotten cell
> produces none where one was expected.

| Type | Selector | Match | Notes |
|------|----------|-------|-------|
| `state` | any `STATE.md`, at any depth in any folder | `path **/STATE.md` | never reviewed (see `G-04`); first row, so a `STATE.md` inside another tree never resolves to that tree's type |
| `kb-generated` | a `.md` under `.aid/knowledge/` with `source: generated` (e.g. `INDEX.md`) | `path .aid/knowledge/*.md AND fm source == generated` | build-verify only; content not graded (C-5). Ahead of `kb-meta`, so a generated meta doc is build-verified rather than field-checked |
| `kb-meta` | a `.md` under `.aid/knowledge/` with `kb-category: meta` (e.g. `external-sources.md`) | `path .aid/knowledge/*.md AND fm kb-category == meta` | spot-check of top-level fields only |
| `kb-doc` | any other `.md` under `.aid/knowledge/` | `path .aid/knowledge/*.md` | the hand-authored knowledge docs — `kb-category: primary` or `extension` with `source: hand-authored`; the catch-all that closes the KB tree |
| `skill-generated` | a `canonical/skills/<name>/SKILL.md` whose `<name>` is a row in `shortcut-catalog.yml` | `path canonical/skills/*/SKILL.md AND name-in canonical/aid/templates/shortcut-catalog.yml` | rebuilt by the generator; no file-level block (see `SK-02`) |
| `skill-authored` | a `canonical/skills/<name>/SKILL.md` whose `<name>` is not a `shortcut-catalog.yml` row | `path canonical/skills/*/SKILL.md` | hand-authored; may carry a file-level block |
| `skill-reference` | a `.md` under `canonical/skills/*/references/` | `path canonical/skills/*/references/*.md` | the procedure bodies an agent executes |
| `agent` | a `canonical/agents/*/AGENT.md` | `path canonical/agents/*/AGENT.md` | may carry a file-level block; `render.py` carries it through |
| `template-payload` | a file under `canonical/aid/templates/` whose frontmatter belongs to the artifact the template EMITS rather than to the template. Three recognizers, any one sufficient: placeholder tokens (`{project}`, `{grade or Pending}`); an **unquoted** choice-list in a value position (`delivery_state: Pending-Spec | `path canonical/aid/templates/** AND <inexpressible>` | Specified | ...`) — a pipe inside a quoted string is prose, not a choice list; or an opening key drawn from the emitted artifact's own schema — `pipeline:`, `delivery_state:`, `state:`. **`kb-category:` is deliberately NOT a recognizer**: a template may carry it about itself (`reviewer-ledger-schema.md` does), and the `knowledge-base/` doc templates are already caught by their placeholders | no file-level block (see `TP-01`). Includes the `knowledge-base/` doc templates: their frontmatter is the emitted KB doc's, so a `review-criteria:` there is the EMITTED doc's declaration, not the template's |
| `template-own` | any other file under `canonical/aid/templates/` — its frontmatter describes itself, or it has none | `path canonical/aid/templates/**` | the catch-all that closes the template tree (e.g. `reviewer-ledger-schema.md`); may carry a file-level block. Ordered after `template-payload`, so a payload template never falls here |

---

## Review Criteria — Criteria by Level

One row per criterion, carrying the same fields as the frontmatter object (`id`, `kind`, `criterion`,
`severity`, `why`, and the optional `oracle`). **Applies to** takes one of three values: `*` means global (level 1); one **or more
comma-separated registry type names** mean level 2 — a criterion true of two types stays ONE row naming
both, because two rows saying the same thing is the duplication this table exists to make visible; and a
**file class named by the criterion itself** scopes a global
exclusion to a set of files that is not a document type. Only two rows use the third form —
`agent-context` (`G-05`) and `rendered` (`G-06`) — and each is deliberately not a registry type: the
files they cover are not in-scope authored artifacts at all, so giving them a type would put them
inside `G-07`'s "every in-scope file resolves to exactly one type" and make the registry claim
something false. Each such row's `criterion` cell states its own membership test. A `kind:
exclude` row records what a reviewer must **not** validate (where it would otherwise reasonably check)
and carries **no** severity — an exclusion is not a defect kind, and there is no severity of zero. **No
cell may contain a pipe** — a criterion needing one is rephrased (this constrains the markdown table
only; the YAML frontmatter has no such limit).

A finding cites a criterion by its `id` as a prefix inside the ledger's existing `Description` cell — a
scope-prefixed id (`G-`, `KB-`, `SK-`, …) resolves here; a file-local `F-` id resolves in the file named
in the ledger's `Doc` column. A finding citing no id, or an id resolving nowhere, is itself a defect.

| ID | Applies to | Kind | Criterion | Severity | Why |
|----|-----------|------|-----------|----------|-----|
| G-01 | `*` | validate | No cosmetic count unless it is load-bearing and measured from disk at authoring time | MINOR | counts drift every commit; the reader can run `wc -l` |
| G-02 | `*` | validate | Every citation is a durable anchor (path plus a grep-recoverable symbol or heading), never a bare `file.ext:LINE` | LOW | line numbers move on the next edit above them |
| G-03 | `*` | validate | A resolved or closed tracked item leaves no trace — its row, detail, and closure prose are removed | MEDIUM | a resolved item still visible reads as open; git is the audit trail |
| G-04 | `state` | exclude | Never reviewed, at any level, in any folder | — | bookkeeping; a completed run's rows are correct as history, so any content check fires forever |
| G-05 | `agent-context` | exclude | The root `CLAUDE.md` / `AGENTS.md` are never content-reviewed | — | shared host files; AID owns only the `AID:BEGIN`/`AID:END` region and points at truth rather than holding it; they carry no frontmatter to declare this on |
| G-06 | `rendered` | exclude | A file that IS a render is not content-reviewed — it appears as a `dst` in an emission manifest, OR it sits under `profiles/<tool>/` and has a corresponding `canonical/` source | — | byte-identical output of `canonical/`; the byte-compare gate is its review. Keyed on provenance not path, so authored repo-local content under a dogfood tree stays reviewable |
| G-07 | `*` | validate | Every in-scope markdown file resolves to exactly one type in the registry above | HIGH | FR-10 backstop; an untyped file has no resolved criteria and drifts unchecked |
| G-08 | `*` | validate | No superseded frontmatter field survives in a file's OWN frontmatter -- `intent:` is replaced by `objective:` plus `summary:`, and `changelog:` is not a valid field at all. A KB-doc TEMPLATE is out of reach whatever type it resolves to: its frontmatter belongs to the artifact it emits, and `tests/canonical/test-kb-template-authoring-standard.sh` requires the emitted shape to keep `intent:` while the coexistence window is open -- that test is the contract, so it bounds this criterion rather than the reverse | LOW | the rule to delete them existed with no id, so a reviewer that found one could not cite it and had to report outside the ledger; a rule nobody can cite is not enforced |
| KB-01 | `kb-doc` | validate | Required frontmatter is present and single-line: `objective`, `summary`, `sources` | HIGH | lint-graded; a missing or malformed field misroutes the doc |
| KB-02 | `kb-doc` | validate | Exactly one concern per doc, and the layout holds: frontmatter, title, index, content sections, and no history section | MEDIUM | mixing concerns is a boundary smell; layout is a fixed contract, and a history section drifts from git |
| KB-03 | `kb-generated` | exclude | Content is not graded; only that the generator ran (build-verify) | — | the generator is the oracle (C-5) |
| KB-04 | `kb-meta` | validate | Only the top-level fields are checked -- that they are present and current; the body is not content-graded | LOW | a meta doc orients a reader to the KB rather than asserting project facts, so there is little in its body that can be wrong about the project |
| SK-01 | `skill-authored` | validate | Every agent named in a Dispatch table resolves to `canonical/agents/<name>/` | HIGH | a skill dispatching a non-existent agent fails at run time |
| SK-02 | `skill-generated` | exclude | Carries no file-level `review-criteria:` block; type-level criteria only | — | rebuilt from `shortcut-catalog.yml`; anything hand-written is erased on the next run |
| SR-01 | `skill-reference`, `template-own` | validate | Every instruction-content pointer resolves to a path that exists in an installed tree | HIGH | both types are procedure bodies an agent follows at run time, so a broken pointer is followed rather than noticed |
| AG-01 | `agent` | validate | The `name:` matches the folder, and any agent it references resolves under `canonical/agents/` | MEDIUM | a name/folder mismatch mis-dispatches |
| TO-01 | `template-own` | exclude | A template inlined into another file by an `{{include:<name>}}` token carries no file-level `review-criteria:` block — currently `agent-boilerplate.md`, inlined by every `canonical/agents/*/AGENT.md` | — | the include copies the file verbatim, so frontmatter here is injected as a stray delimiter block into the middle of every including file |
| TP-01 | `template-payload` | exclude | Carries no file-level `review-criteria:` block; its frontmatter is the emitted artifact's | — | a block here would be stamped onto every generated artifact |

**An optional `oracle:` decides a criterion by running it.** A `validate` criterion may name an
executable check — a repo-root-relative path, living outside `canonical/` — so a mechanically
decidable criterion is settled by *running* rather than by a reviewer re-deriving it every cycle.
Absence of the key is never a defect, and most criteria will never carry one. The full contract —
the per-file `VIOLATION`/`UNDECIDED` output, the exit codes, the 60-second bound, and what
degradation means — is declared once in
`kb-authoring/frontmatter-schema.md § oracle: — deciding a criterion by running it`, and is not
restated here.

**Severity** on a `validate` criterion is what a violation of that criterion costs, resolved through the
same three levels (a file may override a higher level's severity by restating the criterion's `id` with
a mandatory `why`; the reviewer records the effective value in the finding's `Evidence` cell).

**Where severity lives, and where it does not.** This table is the only home for **per-type severity** —
what a defect kind costs in a given class of document — because that is a convention, and conventions
live here. It is deliberately not duplicated into `quality-gates.md`. What that document and
`canonical/aid/templates/grading-rubric.md` own instead is the **grading machinery**: the five-level
scale itself (`grading-rubric.md § Issue Severities`), the severity-to-letter mapping and quantity
modifiers (`§ Grade Calculation`), and the thresholds a phase must clear. This table **prices** each
criterion against that scale and redefines nothing; the two cross-reference and never restate each
other.

---

## Frontmatter Rules

Source of truth: `kb-authoring/frontmatter-schema.md`. Every KB doc begins with a
YAML frontmatter block. The fields divide into required, optional, and
generator-written.

| Field | Class | Rule |
|-------|-------|------|
| `kb-category:` | required | `primary` \| `meta` \| `extension` -- picks the review rubric. |
| `source:` | required | `hand-authored` \| `forward-authored` (greenfield KB seed, design-authoritative) \| `generated` (then `generator:` is required). |
| `objective:` | required (hand-authored) | one-line noun-phrase purpose; single physical line. |
| `summary:` | required (hand-authored) | one-sentence scope; single physical line. |
| `sources:` | required (hand-authored) | YAML list of paths/globs/URLs; `sources: []` for a pure-synthesis doc (absence is a lint error). |
| `tags:` | optional | concrete keywords; **MUST include the concern/dimension id** (e.g. `C2`) by convention -- that is how a doc anchors to the spine. |
| `see_also:`, `owner:`, `audience:` | optional | negative-routing pointers, accountable role, target readers (all free strings, not enums). |
| `approved_at_commit:` | generator-written | git SHA freshness baseline; **never hand-authored.** |
| `review-criteria:` | optional | the criteria a reviewer validates this doc against -- declare only what is true of THIS doc; see [Review Criteria -- Criteria by Level](#review-criteria--criteria-by-level). |
| `contracts:` | pre-rename name of `review-criteria:` | the same field under its old name, still on disk in docs whose data has not been migrated yet. Read it as `review-criteria:`; rename it on the next touch. Its entries were plain strings, so a rename is not enough -- each becomes an object, and a string entry has no `id`, which means no finding can cite it. |
| `intent:`, `changelog:` | legacy | `intent:` is superseded by objective+summary; `changelog:` is **not a valid field** -- delete it where it survives. |

- **Rule:** a new hand-authored primary/extension doc MUST carry `objective:`,
  `summary:`, and `sources:` -- these are lint-graded (`lint-frontmatter.sh`),
  missing -> `[FM-MISSING]` (HIGH), malformed -> `[FM-INVALID]` (HIGH).
- **Red flag:** a multi-line `objective: |` block scalar (must be a single line);
  a doc that omits the concern id from `tags:`.

---

## Dual-Audience Standard

Every KB doc is authored for **two readers at once**: a junior human and an AI
agent consuming the KB (kb-authoring P10). The same small, focused doc serves both.

- **One concern per doc.** Each doc answers exactly one concern question (see
  [Concern Model](#concern-model-doc-set-derivation)); mixing concerns is a
  boundary smell. Minimal overlap across docs.
- **Junior-clear language.** Plain words, active voice, short sentences, one idea
  per sentence. Define project-specific terms in `domain-glossary.md` on first use.
- **Tables and bullet lists are the primary structure** for reference material.
- **No diagrams** (Mermaid/SVG/ASCII art) in KB `.md` docs -- they degrade in plain
  text, cannot be grepped, and add maintenance cost. Use `A -> B` arrows,
  relationship tables, and numbered flow lists instead. Code blocks are not diagrams
  and are allowed. (Exception: the `kb.html` visual summary from `aid-summarize` is
  deliberately visual -- the no-diagram rule does not apply there.)
- **Operational guidance is first-class greppable structure**, not prose: where a
  doc carries conventions / invariants / contracts / gotchas, it carries them as the
  named `## Conventions` / `## Invariants` / `## Contracts` / `## Gotchas` sections.
- **Red flag:** a Mermaid block in a KB `.md`; a long catch-all doc covering several
  concerns; jargon a junior could not follow.

---

## Drift-Prone Content is Banned

Four content classes are banned from primary docs because they drift every commit
without adding knowledge (kb-authoring P1):

1. **Cosmetic counts** -- line/byte/method counts ("this file has N functions").
   The reader can run `wc -l`. Replace with a structural assertion only where the
   count is load-bearing.
2. **Dates without semantic anchor** -- "as of 2026-05-22"; git carries this.
   Allowed only in `STATE.md` history, or as a load-bearing inflection marker.
3. **Other low-value clutter** -- judgment call; default to removal, ask the user
   when unclear.
4. **Positional citations** -- see [Citation Rule](#citation-rule-durable-anchors).

A "proper metric" (when load-bearing) must be relevant, measured-from-disk at
authoring time, and never retroactively edited in a historical statement.

---

## Citation Rule (Durable Anchors)

Cite a **durable anchor** -- a file path plus a grep-recoverable symbol, heading, or
unique string -- never a bare `file.ext:LINE` (line numbers drift on the next edit
above them; P1(d)).

| Form | Verdict |
|------|---------|
| `read-setting.sh` -> `lookup_list` | correct (greppable symbol) |
| `principles.md` "P1(d) Positional citations" | correct (greppable heading) |
| `read-setting.sh` + a bare line number (the `.sh` followed by a colon and digits) | **wrong** (the line moves on the next edit above it) |

This is mechanically gated by `kb-citation-lint.sh`, which distinguishes a bare
line number from a durable anchor (a colon followed by letters, or `.digit` for an
IP/version, is allowed). Run it before declaring a doc done.

---

## Signature Exception

The "summary + pointer" altitude rule (synthesise *why/how*; leave volatile detail
in `sources:`) has one hard carve-out -- **P1(d)-SIG**. A load-bearing operational
contract an agent must satisfy to ACT -- data-schema field types, exit/error codes,
host-tool capability flags, interface argument shapes, mode/option invariants --
MUST be stated **inline** or behind a precise grep-recoverable anchor, never
deferred to a bare `sources:` file pointer. A `sources:`-deferred contract forces an
agent to REACH, which the assertiveness gate flags as an insufficiency. The altitude
rule de-bloats *narrative* volatility only; it does not apply to work-critical
contracts.

---

## Resolved Items Leave No Trace

A KB doc records **current state only** (kb-authoring P9). When a tracked item is
resolved -- a `tech-debt.md` entry fixed, a Q&A answered, an open question closed --
its record is removed **entirely** (the row, the detail, any "closed items"
roll-call). Do not keep a closure record "for
history" -- git history is the only retained audit trail. A resolved item still
visible anywhere (including in the generated `kb.html`) is a defect.

---

## Reviewer Ledger Convention

Every review output -- dispatched sub-agent, script validator, or ad-hoc -- is
written as a single markdown table at `.aid/.temp/review-pending/<scope>.md`
(reviewer-ledger-schema.md). The table is the **entire file**: no frontmatter, no
headers, no narrative, no summary section.

7-column shape:

```markdown
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [HIGH] | Pending | foo.md | 42 | claim Y is wrong | doc says Y, disk shows Z |
```

- **Severity** (closed, bracketed): `[CRITICAL]` `[HIGH]` `[MEDIUM]` `[LOW]` `[MINOR]`.
- **Status** (closed, no brackets): `Pending` `Fixed` `Recurred` `Accepted` `OOS` `Invalid`.
- The grade is computed by `grade.sh` over rows where Status is `Pending` or
  `Recurred`: worst severity dominates; count sets the modifier.
- **Never** add a `## Summary` section with severity tag-strings (they get
  over-counted). Rows are append-only history; only `Status` changes across cycles.

---

## Scoped Review Cycles

**Cycle 1 reads everything. From cycle 2 a review verifies the existing ledger in full but
hunts for new findings only in what the previous fix changed.** The two halves are separate
because only one of them was ever expensive: re-checking a `Pending` row is a targeted disk
lookup, while "find NEW issues" is what forced a whole-artifact re-scan on every cycle.

Three properties keep it safe, and none is optional:

- The scoped surface includes the sections that **reference** the changed ones, found by
  mechanical cross-reference lookup rather than by a judgment about what might be affected.
- The cross-document contradiction pass is kept, and runs **once per phase** — on cycle 1 of
  any review that sees more than one artifact — instead of once per cycle per artifact.
- **A scoped cycle never approves.** One full pass runs before approval, and `Recurred`
  already exists in the Status enum for anything a scoped cycle missed.

The mechanism is defined once in `kb-authoring/../reviewer-ledger-schema.md § Two sets from
cycle 2` and carried by `reviewer-dispatch.md § ARTIFACTS UNDER REVIEW`. It is not restated
here — a second definition is the drift this convention section exists to prevent.

---

## Plan-First (Review then Fix)

Review and fix are **separate phases**, never blended (kb-authoring P3). The ledger
is the action queue: REVIEW upserts findings as `Pending`; FIX processes the ledger
top-to-bottom and addresses each (the fixer does NOT mark rows `Fixed` -- the next
reviewer confirms). This is restart-safe (a crash leaves the ledger intact) and
prevents cascade-fixing before all findings are seen.

---

## Concern Model (Doc-Set Derivation)

The KB doc set is derived from a fixed **dimension spine** -- 11 universal concerns
(C0-C9 + D), not from project types (concern-model.md). C0-C9 are the 15-doc default
seed; **D (Decisions)** is a conditional doc. The doc set is **proposed -> confirmed**
with the user and persisted in `discovery.doc_set` (`.aid/settings.yml`); only the
doc realization varies per project, the dimension list is fixed (a T2 cardinality
contract). A doc that is really a **per-work** governance artifact (a sprint backlog, a
work plan, a task register) is out of KB scope -- route it to the pipeline
(`REQUIREMENTS.md`/`SPEC.md`/`PLAN.md`, the per-work `STATE.md`), not the doc set. A
**project-level** governance artifact (a roadmap, a backlog, a release ledger) is
admissible instead, as a conditional document: the pipeline artifacts a per-work item
would route to are per-work and transient -- pruned when the work ships -- leaving no
durable home for a project-level concern.

---

## Prose Over Scripts

AID does trivial state/argument work in **SKILL.md prose**, not in bash scripts. A
skill's state machine is authored as Markdown instructions the agent follows; a
script is added only when real logic warrants it (parsing, grading, generation).
Corollary: when a test mis-specifies infrastructure that does not exist, relax the
test rather than inventing the infrastructure. (USER DIRECTIVE; precedent across the
canonical suites.)

---

## Content Isolation

The cornerstone rule: **all AID-delivered content is isolated/namespaced from user
content.**

- **`aid-` prefix.** Skills and agents are named `aid-<name>`; orphan pruning on
  uninstall is by this prefix. Scripts/templates are namespaced under the toolkit
  subtree and tracked by the install manifest.
- **Root agent files use an AID:BEGIN/END boundary.** `CLAUDE.md` / `AGENTS.md`
  carry an AID-managed region between `<!-- AID:BEGIN -->` and `<!-- AID:END -->`
  (see `CLAUDE.md`). The installer updates only the content **in place** inside that
  region; content outside it (the user's own instructions) is never touched, and
  there is no `.aid-new` side file. Two layers produce this: the **mechanism** is the
  install-core region-replacement (`lib/aid-install-core.sh` `_copy_root_agent_file` + its
  PowerShell twin `lib/AidInstallCore.psm1` `Copy-RootAgentFile`), which copies the AID region
  from the source root-agent file into the host file in place; the **content** is the
  `AID:BEGIN/END` body of the rendered root-agent source `profiles/<tool>/{CLAUDE.md,AGENTS.md}`
  (the file the installer reads). So to change HOW the region is written, edit the install-core
  libs; to change WHAT AID writes into it, edit that root-agent body -- never the user's host file.
- **Red flag:** an AID file without the `aid-` prefix; writing outside the
  AID:BEGIN/END region in a host file; an uninstall that deletes by directory rather
  than by manifest.

---

## Generated and Temporary Files

- **Generated content** (`.aid/generated/*`) carries an `<!-- AUTO-GENERATED ... DO
  NOT EDIT -->` comment and `source: generated` + `generator:` frontmatter; it is
  refreshed LAST in a FIX cycle from disk truth (kb-authoring P5). Registered in
  `generated-files.txt`.
- **Temporary state** (`.aid/.temp/*`) is the gitignored ledger/scratch space;
  skills MUST NOT review files there; it is deleted at skill DONE.

---

## Conventions

> The project's own way of each recurring authoring change. Imperative rules.

- **Authoring a new KB doc:** start from the seed template or a custom layout;
  fill `objective:`/`summary:`/`sources:` + a concern id in `tags:`; one concern
  only; tables over prose; no diagrams; durable citations; no history section;
  run `lint-frontmatter.sh` + `kb-citation-lint.sh` before done.
- **Writing a review:** emit the 7-column ledger as the whole file at
  `.aid/.temp/review-pending/<scope>.md`; closed Severity/Status enums; no narrative.
- **Resolving a tracked item:** delete its record entirely; do not keep a closure note.
- **Authoring skill logic:** prefer SKILL.md prose; add a script only for real logic.
- **Writing into a host file:** stay inside the `AID:BEGIN/END` region; namespace
  every delivered file under the `aid-` convention.
- **Adding a doc to the set:** propose -> confirm with the user; never silently add
  a doc outside the confirmed `discovery.doc_set`.

---

## Enforcement

> Which conventions are enforced automatically vs by review, and what breaks when a
> rule is violated.

| Convention | Enforced by | Automatic? | What breaks on violation |
|------------|-------------|------------|--------------------------|
| Required frontmatter (`objective`/`summary`/`sources`) + shape | `lint-frontmatter.sh` | Yes (lint) | `[FM-MISSING]`/`[FM-INVALID]` HIGH finding -> grade drop. |
| Durable citations (no bare `file:LINE`) | `kb-citation-lint.sh` | Yes (lint, orchestrator-gated at GENERATE) | Lint exit 1; cycle blocked until fixed. |
| Reviewer-ledger schema + grade | `grade.sh` | Yes (parses the table) | Mis-shaped ledger mis-grades; a `## Summary` line over-counts. |
| Doc layout, one-concern, dual-audience, no-diagrams, P1/P9 | `aid-reviewer` sub-agent (semantic) | No (review judgment) | Findings logged to the ledger; grade gate fails below `minimum_grade`. |
| INDEX regeneration | `build-kb-index.sh` (run from `canonical/.../kb/`) | Partly (CI KB-hygiene checks the script path) | Stale INDEX; KB-hygiene CI fails on the embedded path. |
| Render drift (canonical -> profiles) | full `run_generator.py` + emission manifests | Yes (render-drift CI) | CI render-drift failure on stale emission. |
| ASCII-only + WinPS 5.1 (shipped PS) | `ps51-compat-check.ps1`, ASCII CI guard | Yes (CI) | Windows mis-parse / 5.1 break; CI red. |
| Content isolation (`aid-` prefix, AID:BEGIN/END) | install/uninstall logic + review | Partly | User content clobbered or orphan files left behind. |

**Read alongside:** the `minimum_grade` floor (`.aid/settings.yml`, default `A`)
is the bar a review must clear before a phase advances; the reviewer applies the
rubric in `kb-authoring/review-rubric.md`.

---


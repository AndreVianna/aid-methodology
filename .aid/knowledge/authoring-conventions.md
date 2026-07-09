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
contracts:
  - "Every KB doc layout: frontmatter -> title -> index -> content -> Change Log last"
  - "Reviewer ledger is a 7-column table; Severity + Status are closed enums"
  - "Required frontmatter fields: objective, summary, sources (lint-graded)"
changelog:
  - 2026-07-09: housekeep KB-DELTA connectors subsystem refresh -- added the `forward-authored` value to the frontmatter `source:` rule (closed 3-value enum).
  - 2026-06-25: Initial authoring (aid-discover brownfield deep-dive / Analyst)
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
- [Change Log](#change-log)

---

## KB Document Layout

Every KB document MUST follow this top-to-bottom order (kb-authoring P10):

| Position | Section | Rule |
|----------|---------|------|
| 1 | Frontmatter | YAML block between `---` markers; first content in the file (no BOM, no blank line before). |
| 2 | Title | a single `# Doc Title`. |
| 3 | Index / contents | required when the doc has more than 3 sections. |
| 4 | Content sections | the concern's substance. |
| 5 | `## Change Log` | **always the last section.** |

Example: every doc in this KB (including this one) opens with frontmatter and ends
with `## Change Log`.

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
| `intent:`, `contracts:`, `changelog:` | legacy/optional | `intent:` is superseded by objective+summary; `changelog:` newest-first. |

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
   Allowed only in `STATE.md` history, the frontmatter `changelog:`, or as a
   load-bearing inflection marker.
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
roll-call, any closure prose in `changelog:`). Do not keep a closure record "for
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
contract). A doc that is really a governance artifact (a plan, a backlog, a register)
is out of KB scope -- route it to the pipeline (`REQUIREMENTS.md`/`SPEC.md`/`PLAN.md`),
not the doc set.

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
  only; tables over prose; no diagrams; durable citations; `## Change Log` last;
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

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.1 | 2026-07-09 | housekeep KB-DELTA | Connectors subsystem refresh: the frontmatter `source:` rule (Frontmatter Rules) now lists the closed 3-value enum `hand-authored \| forward-authored \| generated`, matching artifact-schemas.md's inline contract. Verified the 15-doc default seed figure already stated under Concern Model is correct (no change needed there). |
| 1.0 | 2026-06-25 | aid-discover | Initial authoring-conventions doc (Analyst) |

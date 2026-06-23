# Essence-Capture Research

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-12, FR-13, FR-14, FR-15, FR-16, FR-31, FR-32) | /aid-interview |

## Source

- REQUIREMENTS.md §5.D (FR-12, FR-13, FR-14, FR-15, FR-16), §5.I (FR-31, FR-32)
- REQUIREMENTS.md §1.2 (the essence gap, the 'Relative bus' miss), §1.4 (research side), §1.5 (the method), §2.1/§2.3 (P1, P3)
- §4 S4

## Description

This feature is the heart of the overhaul: it makes discovery **capture a
project's essence** — its ubiquitous language and native concepts — instead of
cataloging generic structure. It adds a **mechanical coined-term / salient-concept
harvest** that scans all source types and emits a candidate-concept list
(project-coined × recurring × cross-source) — the deterministic anchor that turns
"did we miss a concept?" into a checklist (the 'Relative bus' concept lights up
here). From that list it builds a **concept spine** — the grounded native concepts,
constructed *before* the per-concern docs and shared with every researcher so
cross-cutting concepts are nobody-falls-between-lanes.

It introduces the **comprehension / closure loop**: stop cataloging and explain
how the system works in the project's own language, iterating until the
explanation closes (no undefined project-specific term remains). A
**can't-explain-it tripwire** makes any ungrounded project-specific term a
mandatory investigation rather than ignorable noise, and research must read **all
source types** — code, docs/ADRs, reports, data bundles, commit/issue history —
because the *why-here* (the essence) lives in prose, not just code. The concept
spine is **persisted as a first-class KB doc** (the upgraded ubiquitous-language /
glossary) that other docs reference and the INDEX routes to. When a concept
**cannot be grounded from the artifacts**, discovery **escalates it as a human
Q&A** rather than silently dropping it.

## User Stories

- As an **AI agent** consuming the KB, I want discovery to capture the project's
  native concepts so that I get the delta from what I already know, not the generic
  skeleton.
- As a **senior architect**, I want a persisted concept spine that other docs
  reference so that the project's conceptual model is a durable backbone, not lost
  scratch.
- As an **AID adopter**, I want discovery to read the *why* sources and ground every
  coined term so that the KB explains *my* domain ('Relative bus'-type concepts) and
  passes teach-back.
- As an **AID maintainer**, I want ungroundable concepts escalated as explicit human
  Q&A so that silent misses become caught questions.

## Priority

Must

## Acceptance Criteria

- [ ] Given any project, when the mechanical harvest runs, then it scans all source
  types and emits a candidate-concept list (project-coined × recurring ×
  cross-source). *(FR-12; supports AC2)*
- [ ] Given the candidate list, when discovery proceeds, then a grounded concept
  spine is built before the per-concern docs and shared with every researcher.
  *(FR-13)*
- [ ] Given a fresh agent and only the KB, when asked, then it can explain how the
  project works in its own language and answer "what is X?" for the native concepts
  (teach-back closure / closure loop). *(FR-14, AC1 keystone, AC3)*
- [ ] Given any ungrounded project-specific term, when discovery encounters it, then
  it is treated as a mandatory investigation, never ignorable noise. *(FR-15,
  tripwire)*
- [ ] Given a project, when research runs, then it reads all source types — code,
  docs/ADRs, reports, data, commit/issue history. *(FR-16)*
- [ ] Given a fixture with a planted 'Relative bus'-style concept, when discovery
  runs, then it captures and defines it. *(FR-12; AC2 — validated in f012)*
- [ ] Given a project, when discovery completes, then the concept spine exists as a
  first-class KB doc that other docs reference and the INDEX routes to. *(FR-31, AC14)*
- [ ] Given a concept that cannot be grounded from the artifacts, when discovery
  detects it, then it escalates a human Q&A entry (surfaced, not silently dropped).
  *(FR-32, AC15)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — the harvest,
> the closure self-containment check, and salience ranking are mechanical/scripted
> (cheap, deterministic, CI-able); the closure loop must be bounded; LLM judgment
> (synthesis, "did it understand") is minimized and evidence-anchored. AC3 (closure
> self-containment) is verified jointly with f012.

---

## Technical Specification

> Methodology/tooling feature — the **generation-time essence-capture engine**. It adds (1) a
> shipped, deterministic **coined-term harvest** bash script + denylist + canonical test
> suite, (2) the **concept spine** as an upgrade of `domain-glossary.md` (the FR-31 persisted
> artifact), (3) a **bounded comprehension/closure loop** orchestrated inside `aid-discover`'s
> GENERATE/synthesis flow, (4) the **can't-explain tripwire** that forces investigation of
> any ungrounded project-specific term, and (5) **FR-32 human escalation** reusing the existing
> scout-questions → `STATE.md ## Q&A (Pending)` backlog. "Components" here are a new KB script,
> a denylist data file, `aid-discover` reference snippets, the upgraded glossary template, a
> `.aid/settings.yml` key, and a canonical test suite — not application code. Every claim is
> grounded against the files cited inline; genuine unknowns are flagged **[SPIKE]**, not guessed.
>
> **Boundaries (NOT absorbed here).** The **multi-mandate review PANEL** (Correctness /
> Anatomy / Concept-closure / Teach-back / Calibration) and the **teach-back-closure EXIT
> gate** are **f005** — f004 owns the *generation-time* research+closure that PRODUCES the
> essence; f005 GRADES it. The **3 paths** (greenfield / brownfield-small / brownfield-large)
> and the recon **triage** that select closure depth + panel size are **f006**; f004 reads
> the path as a parameter but does not implement triage. The **frontmatter field schema**
> (`sources:`/`objective:`/`summary:`/`tags:`) is **f001**'s; f004 *consumes* `sources:`, it
> does not redefine it. The **concern model** (the glossary-as-C4-concern-doc, the
> expectations-as-open-questions transform) is **f003**'s; f004 *upgrades the content* of the
> C4 doc into the spine. **Migration** of AID's own glossary to spine shape is **f011**.

### Overview

This feature converts discovery from structural cataloging into conceptual-model
reconstruction (REQUIREMENTS §1.2 root cause), by inserting three new pieces into the
existing GENERATE flow (`state-generate.md`) and one config key:

1. **A mechanical coined-term harvest** — a shipped, deterministic bash script
   (`canonical/aid/scripts/kb/harvest-coined-terms.sh`) + a shipped denylist
   (`canonical/aid/scripts/kb/coined-term-denylist.txt`). It runs as a **new Step 0e**
   in GENERATE — after the project index (Step 0c) and doc-set confirm (Step 0d), **before**
   the researcher fan-out (Steps 2-5). It emits a ranked **candidate-concept list**
   (`.aid/generated/candidate-concepts.md`) — the deterministic anchor that makes "did we
   miss a concept?" a checklist (REQUIREMENTS §1.4; the 'Relative bus' lights up here).

2. **The concept spine** — an **upgrade of `domain-glossary.md`** (NOT a separate doc; the
   C4-Vocabulary concern doc f003 already designates as the spine). The harvest *seeds* it
   (top candidates pre-listed as "to ground"); the closure loop *populates* it with each
   native concept's definition-as-used-here, how-it-relates-to-others, and `sources:`. It is
   the FR-31 persisted, first-class KB artifact other docs reference and the INDEX routes to.

3. **The comprehension / closure loop** — orchestrated by `aid-architect` in a new synthesis
   sub-state, run after the deep dives. It is the explain-in-native-terms → find-ungrounded-
   terms → investigate → repeat cycle, **bounded** by a configurable cap
   (`discovery.closure` in `.aid/settings.yml`; default K=2 consecutive-clean passes OR a
   token budget per NFR-2), and **batched-parallel** (detect-all-gaps → fill-all-parallel →
   re-check) to keep the critical path short (NFR-2).

4. **The can't-explain tripwire (FR-15)** + **human escalation (FR-32)** — woven through the
   loop: a project-specific term not confidently definable from general knowledge is a
   *mandatory* investigation (never noise); a term that cannot be grounded from any artifact
   after investigation becomes a `## Q&A (Pending)` entry in `.aid/knowledge/STATE.md` via the
   **existing scout-questions mechanism** (Step 6b) — no new queue invented.

The deterministic substrate (the harvest script + the closure self-containment check) is
mechanical/CI-able; the LLM judgment (grounding a term, "did it close") is bounded and
evidence-anchored against the harvest output (FR-23, NFR-1/2/3).

### Coined-Term Harvest

#### The script

- **File:** `canonical/aid/scripts/kb/harvest-coined-terms.sh` (rendered to the 5 host trees
  + the repo `.claude/` working copy, like its siblings `build-project-index.sh` /
  `build-kb-index.sh`). It is a **shipped KB script** that vendors into the install bundles,
  so it is ASCII-only bash (C2; PS-5.1 N/A — see Constraints). No LLM, no embedding model
  (C1/NFR-8); pure coreutils (`find`, `grep`, `awk`, `sort`, `tr`, `comm`) — the same
  toolset `build-project-index.sh` already uses.
- **Invocation** (mirrors `build-project-index.sh`'s flag shape):
  ```bash
  bash .claude/aid/scripts/kb/harvest-coined-terms.sh \
    --root . \
    --output .aid/generated/candidate-concepts.md \
    --denylist .claude/aid/scripts/kb/coined-term-denylist.txt \
    --top 60
  ```
  Copies `build-project-index.sh`'s `SKIP_DIRS` prune set (`.git`, `node_modules`, `target`,
  `dist`, `.aid`, ...) and its absolute-OUTPUT-before-cd resolution (lines 172-185) — copied,
  not sourced (bash functions/arrays do not cross scripts), so the two behave identically on
  path edge cases and are kept in lockstep by the shared test fixture.

#### Extraction rules (all source types — FR-16)

The harvest scans **every text file** under `--root` (not only "source" languages — the
*why-here* lives in prose, so docs/ADRs/reports/commits count). For each file it extracts
candidate **terms** by four deterministic token classes, each tagged with the **source
channel** it was found in (the channel set drives cross-source spread, below):

| # | Token class | Extraction rule (grep/awk, deterministic) | Channels it primarily lands in |
|---|-------------|--------------------------------------------|--------------------------------|
| E1 | **Identifiers** | `[A-Za-z_][A-Za-z0-9_]*` tokens from code files (lang detected by a `detect_lang`/`is_source` classifier copied from `build-project-index.sh` — bash functions are not importable across scripts, so the classifier is re-implemented identically, not sourced; the two must be kept in lockstep, asserted by a shared fixture in the test suite). | `code` |
| E2 | **CamelCase / PascalCase** | tokens matching `[A-Z][a-z]+([A-Z][a-z0-9]+)+` (>=2 humps) — split-or-keep both forms (`RelativeBus` AND `Relative Bus`). | `code`, `docs` |
| E3 | **snake / kebab compounds** | tokens matching `[a-z0-9]+([_-][a-z0-9]+)+` (>=1 separator). | `code`, `config` |
| E4 | **Capitalized multi-word phrases** | from prose (docs/comments/commits): runs of 2-4 `[A-Z][a-z]+` words (`Relative Bus`, `Relative ME`). | `docs`, `comments`, `history` |
| E5 | **Quoted strings** | single/double/backtick-quoted short strings (<=4 words) in code + docs — these are often coined labels. | `code`, `docs` |

**Channels** (the FR-16 "all source types" made mechanical — each file is classified once,
by path + extension, into exactly one channel):

| Channel | Membership rule |
|---------|-----------------|
| `code` | `is_source` languages (from `build-project-index.sh`). |
| `docs` | `.md`/`.rst`/`.txt`/`.adoc` files, plus anything under `docs/`, `adr*/`, `doc/`. |
| `config` | `.yml`/`.yaml`/`.toml`/`.json`/`.ini` + notable manifests. |
| `comments` | comment lines extracted from `code` files (leading `#`, `//`, `/* */`, `--`, `;`). |
| `history` | `git log --format=%s%n%b -n <cap>` subjects/bodies + (when present) `.aid/`-external issue/report bundles passed via `--history-file`. **[SPIKE-H1]** — git-log harvesting is gated on `git rev-parse` succeeding; on a non-git source tree the `history` channel is simply empty (degrade-gracefully, never an error). The issue/report bundle path is a `--history-file` arg the orchestrator fills from `external-sources.md` if such a bundle was declared. |

Comments and history are the channels that carry *why-here* prose (REQUIREMENTS §1.4 "read
the why sources"); they are first-class harvest inputs, not an afterthought.

#### Denylist filter (= "non-standard")

- **File:** `canonical/aid/scripts/kb/coined-term-denylist.txt` — a shipped, ASCII,
  newline-delimited, sorted, lowercased word list. "Non-standard" (project-coined) is defined
  operationally as **a term whose component words are NOT all in the denylist**. The denylist
  has two seeded sections (both shipped, both extensible by a project via a local override —
  see below):
  - **Common English** — a few thousand high-frequency English words (articles, prepositions,
    common nouns/verbs). Seeded from a compact public-domain frequency list, trimmed to ASCII.
  - **Common-tech vocabulary** — generalist programming terms an agent already knows from
    training and that are therefore *negative value* to store (REQUIREMENTS §1.2): `service`,
    `controller`, `repository`, `handler`, `factory`, `client`, `server`, `request`,
    `response`, `config`, `index`, `buffer`, `cache`, `queue`, `thread`, `async`, `module`,
    `component`, `interface`, `schema`, `model`, `view`, `router`, `middleware`, `token`,
    `session`, `layer`, `pipeline`, `stream`, ... (the "layered architecture / repository
    pattern / REST API" vocabulary §1.2 calls out as the shallow-but-true trap).

  **Filter rule (per candidate):** split the candidate into component words (CamelCase split
  on humps; snake/kebab split on separators; phrase split on spaces), lowercase each; the
  candidate **survives** (is project-coined) **iff at least one component word is NOT in the
  denylist**. So `UserService` (both words in denylist) is dropped; `RelativeBus` (`relative`
  in denylist, `bus` in denylist — see note) ... — handled by the **whole-term allowlist
  escape**: a multi-word phrase whose *combination* is salient even though each word is
  common is retained when the **phrase as a unit** is not in the denylist AND it clears the
  salience floor (below). `Relative Bus` is exactly this case: both words are common English,
  but the *phrase* is project-coined and recurs cross-source, so the phrase-level survival +
  salience ranking surfaces it. **This is the precise mechanism that closes the 'Relative
  bus' miss (AC2):** the harvest never asks "is this word non-standard"; it asks "is this
  *term* (word or phrase) non-standard, recurring, and cross-source" — and a common-word
  phrase that recurs across code+docs+comments clears that bar.
  **[SPIKE-H2]** — tune the denylist size + the phrase-survival rule against the f012
  'Relative bus' fixture: the fixture is the executable acceptance test for the filter's
  recall (it MUST surface the planted phrase) and precision (it must not bury it under
  thousands of common-word phrases). The phrase salience floor (min cross-source spread >=2
  for a phrase whose every word is common) is the precision lever and is f012-calibrated.

- **Project override.** A project MAY ship `.aid/knowledge/.coined-term-denylist.local.txt`
  (gitignored-or-committed, project choice); the script `comm`-unions it with the shipped
  denylist before filtering. This lets a team suppress its own house-vocabulary false
  positives without editing the shipped list (mirrors f001's `.review-checklist.md` override
  precedent). Absent → shipped denylist only.

#### Ranking formula (frequency x cross-source spread)

Each surviving candidate carries: `freq` (total occurrences across all files) and `spread`
(the count of **distinct channels** — of the 5: code/docs/config/comments/history — it
appears in, 1..5). The **salience score** is:

```
salience = freq * (1 + 2 * (spread - 1))
```

so a term in **one** channel scores `freq`; the same frequency spread across **three**
channels scores `freq * 5`. This deterministically ranks "appears in code AND comments AND
docs" above "appears 50x in one generated file" — exactly the user-approved
"frequency x cross-source spread" rule (a code+comment+doc term ranks high; a single-file
identifier dump does not). Ties break by `spread` desc, then candidate string asc (stable,
CI-reproducible). The script emits the **top `--top` (default 60)** plus **every candidate
with spread >= 3** (cross-source concepts are never truncated away by the top-N cut — the
'Relative bus' guard).

#### Output format (the candidate-concept list)

Markdown (human-scannable + agent-parsable, same rationale as `project-index.md`), written
to `.aid/generated/candidate-concepts.md`:

```markdown
# Candidate Concepts

> Generated by `canonical/aid/scripts/kb/harvest-coined-terms.sh`. Deterministic; no LLM.
> The mechanical anchor for essence capture (FR-12). Each row is a project-coined term that
> is recurring and/or cross-source — a concept the KB MUST explain or explicitly dismiss.

## Summary
| Metric | Value |
|--------|-------|
| Candidates (post-denylist) | 213 |
| Cross-source (spread >= 2) | 47 |
| Top emitted | 60 |
| Generated | 2026-06-22 |

## Ranked Candidates
| # | Term | Class | Freq | Spread | Channels | Salience | Example source |
|---|------|-------|------|--------|----------|----------|----------------|
| 1 | `Relative Bus` | phrase | 38 | 4 | code,docs,comments,history | 266 | `src/bus/relative.ts`; `docs/adr/0007.md` |
| 2 | `Relative ME`  | phrase | 21 | 3 | code,docs,comments | 105 | `src/bus/relative.ts` |
| ... |
```

The **`Example source` column** gives each candidate a grep-recoverable anchor (path +
distinct string, no line numbers per the glossary's existing durable-anchor convention),
so the researchers (and f005's evidence-anchored grading) start grounded. This file is the
**fixed evidence list** REQUIREMENTS §1.6/NFR-3 names — the spine, the closure loop, and
f005's Concept-closure mandate all grade against it.

#### Where it runs in GENERATE

A new **Step 0e** is added to `state-generate.md`, between Step 0d (doc-set confirm) and
Step 1 (pre-scan):

```
Step 0c  build-project-index.sh          (existing, deterministic)
Step 0d  Propose & Confirm Doc-Set       (existing, human-gated PAUSE)
Step 0e  harvest-coined-terms.sh   <NEW>  (deterministic, no LLM, no dispatch)
Step 1   Pre-scan (scout)                (existing)
Steps2-5 Parallel deep dives             (existing — now armed with candidate-concepts.md)
```

Step 0e prints `[0e] Harvesting coined terms...` then `[0e] Candidate concepts ready
(K candidates, M cross-source)`. On failure (empty repo, no git) it logs a warning and
continues with an empty list (degrade-gracefully, exactly like Step 0c). Because it is a
pure script with no dispatch, it adds negligible cost and zero LLM tokens (NFR-1).

**The candidate list is wired into the fan-out** by adding `.aid/generated/candidate-concepts.md`
to the **REFERENCE DOCUMENTS** block every deep-dive agent already receives (`state-generate.md`
lines 213-219). Use the `.aid/generated/` tree for the new line — it is where Step 0e writes
the file (mirroring Step 0c, which writes `.aid/generated/project-index.md`).
**Note (pre-existing drift, do not copy):** that REFERENCE block currently lists
`.aid/knowledge/project-index.md` (line 216), which is inconsistent with where Step 0c
actually writes the index (`.aid/generated/project-index.md`). Add the new
`candidate-concepts.md` line under `.aid/generated/`, NOT under the block's wrong
`.aid/knowledge/` path; fixing the latent `project-index.md` mismatch in that block is in
scope for whoever edits this block (it should read `.aid/generated/project-index.md`).
The Integrator prompt (`agent-prompts.md` §Integrator — the
`domain-glossary.md` owner) gains the spine-grounding mandate (below); all four deep-dive
prompts gain the line: *"Every term you reach for while explaining your area MUST be either
general knowledge or defined in the concept spine; if you hit a candidate-concept term you
cannot ground, that is a mandatory investigation (the can't-explain tripwire) — ground it
and feed the definition back to the spine."*

#### Canonical test suite

- **File:** `tests/canonical/test-harvest-coined-terms.sh` (auto-discovered by
  `tests/run-all.sh`'s glob; runs in the `canonical-tests` job, `test.yml`). Pattern mirrors
  `test-doc-set-mapping.sh` (numbered `T01..` mechanical assertions, `set -u`, sourced
  `assert.sh`). Asserts, against small in-suite fixture trees under
  `tests/canonical/fixtures/`:
  - **T01-T03 denylist filter** — a common-tech term (`UserService`) is dropped; a coined
    identifier (`RelativeBus`) survives; a common-word *phrase* (`Relative Bus`) recurring
    cross-source survives (the phrase-survival rule).
  - **T04-T06 ranking** — a cross-source term outranks a same-frequency single-channel term;
    spread>=3 candidates are never truncated by `--top`; tie-break is deterministic
    (re-run is byte-identical — the NFR-3 determinism assertion).
  - **T07-T08 channels** — a term appearing only in commits (history channel) is captured; a
    non-git fixture yields an empty history channel without error.
  - **T09 'Relative bus' planted-fixture** — a fixture with a planted coined phrase across
    code+docs+comments surfaces it in the top rows (the AC2 mechanical half; the full AC2
    capture-and-define is f012's end-to-end fixture).
  - **T10 output shape** — the emitted markdown has the documented columns and parses.
- **ASCII guard** — `harvest-coined-terms.sh` + `coined-term-denylist.txt` are added to
  `test-ascii-only.sh`'s `SHIPPED_SCRIPTS` allow-list (C2). **[SPIKE-H3]** — confirm the
  denylist seed wordlist is fully ASCII after trimming (drop any accented loanwords); the
  guard will red CI otherwise.

### Concept Spine (domain-glossary upgrade)

**Decision (user-approved): the spine IS the upgraded `domain-glossary.md`, not a new doc.**
This aligns with f003's concern model (C4-Vocabulary's default doc is `domain-glossary.md`,
designated "the concept spine doc, persisted by f004") and satisfies FR-31 (persisted
first-class artifact other docs reference + INDEX routes to) without adding a doc to the seed.

#### Upgraded structure

The template `canonical/aid/templates/knowledge-base/domain-glossary.md` is upgraded from a
flat term/definition/source glossary into the **concept spine**: each native concept is a
structured entry, not just a table row. The spine has two parts:

1. **Concept entries** — for each grounded native concept (one entry per concept):
   - **Term** — the native/coined name (as used here).
   - **Definition-as-used-here** — what it means *in this project*, NOT in general (the
     §1.2 delta: a generic definition is negative value; only the project-specific meaning
     is stored).
   - **Relates-to** — how it connects to other spine concepts (the cross-cutting linkage no
     single researcher lane owns — REQUIREMENTS §2.3 P3; this is what makes the spine a
     *backbone*, not just-another-doc).
   - **`sources:`** — the files/anchors that ground it (per concept, inline — the same
     durable path+symbol anchor the current glossary already uses; consumed by f005's
     evidence-anchored grading and f007's freshness). This is the per-concept realization of
     f001's doc-level `sources:` field.
2. **Term/definition tables** (retained) — the existing scoped tables (Core Methodology,
   Pipeline Phases, ...) stay for terms that are vocabulary-but-not-load-bearing-concepts; the
   concept entries are the *spine* (load-bearing native concepts), the tables are the
   *lexicon*. The upgrade is additive to the current glossary shape — no term is lost.

The doc-level frontmatter gains f001's fields (`objective`, `summary`, `sources`, `tags`);
its `sources:` is the union of the concept-level sources. (f001 owns the schema; f004 only
populates the upgraded template content — and f011 migrates AID's own glossary into this
shape.)

#### How harvest seeds it + closure populates it

- **Seed (mechanical).** After Step 0e, the orchestrator pre-lists the top cross-source
  candidates as a **"to ground" checklist** at the head of the spine work-area (a transient
  `.aid/generated/spine-todo.md` derived 1:1 from `candidate-concepts.md`). Each candidate is
  a row the closure loop must either (a) ground into a concept entry, or (b) explicitly
  dismiss as not-a-concept (a generated-identifier dump, a vendored token) with a one-line
  reason. **No candidate is silently dropped** — every harvested cross-source term is
  accounted for (this is what converts "did we miss a concept?" into a checklist).
- **Populate (judgment).** The Integrator deep-dive (glossary owner) + the closure loop
  ground each candidate into a concept entry with definition-as-used-here, relates-to, and
  `sources:`. New native terms discovered *during* grounding (understanding is recursive —
  §1.4) are appended to the spine and re-fed to the todo checklist, which is what the closure
  loop iterates on (below).

### Comprehension / Closure Loop

**Orchestration.** The loop runs in a new synthesis sub-state of GENERATE, owned by
**`aid-architect`** (per REQUIREMENTS §1.5 step 4: "SYNTHESIS + CLOSURE LOOP
(`aid-architect`)"), after the deep dives (Steps 2-5) complete and before REVIEW. It is added
to `state-generate.md` as **Step 5b (SYNTHESIS + CLOSURE)** and detailed in a new reference
`references/state-closure.md` (thin-router pattern, C8). The cycle:

```
1. EXPLAIN   aid-architect writes a "how it works" narrative in the project's native terms,
             drawing only on the spine + the deep-dive docs.
2. DETECT    a mechanical self-containment check (closure-check.sh, below) scans the
             narrative + all KB docs for any candidate-concept term (from
             candidate-concepts.md) or any spine "relates-to" term that is USED but NOT
             DEFINED in the spine -> the ungrounded-term set.
3. INVESTIGATE  every ungrounded term is a mandatory investigation (the tripwire, FR-15):
             dispatched as a BATCH of parallel grounding sub-agents (one per term, or
             chunked), each grounding its term into a spine entry or escalating it (FR-32).
4. REPEAT    re-run DETECT. Loop until CLOSED (DETECT finds zero ungrounded terms for
             K-consecutive passes) OR the cap trips (below).
```

This is the §1.4 "stop cataloging; explain in the project's own language; loop until it
closes" heart, made concrete. **Batched-parallel (NFR-2):** DETECT-all-gaps →
FILL-all-parallel → re-check turns N sequential term-investigations into ~2-3 rounds (the
§1.6 wall-clock lever). The grounding sub-agents are `aid-researcher` dispatches (deep-dive
tier), fanned out like the existing Steps 2-5 fan-out, reusing the same parallel-dispatch +
graceful-sequential-degradation machinery (A3).

#### The mechanical DETECT check (deterministic substrate)

- **File:** `canonical/aid/scripts/kb/closure-check.sh` (shipped KB script; ASCII; no LLM —
  the **closure self-containment check** REQUIREMENTS §1.6 names as scripted). Inputs:
  `.aid/generated/candidate-concepts.md` (the term universe) + the spine
  (`domain-glossary.md`) + the KB docs. It deterministically reports the set of
  **candidate-concept terms and spine relates-to terms that appear in a KB doc but have no
  defining concept entry in the spine**. Output: a list of ungrounded terms with the doc +
  anchor where each is used (so each becomes a targeted investigation). This is the
  termination oracle — the loop's DETECT step is a script, not a judgment call (NFR-3:
  "closure-termination MUST be deterministic and CI-able"). Tested by
  `tests/canonical/test-closure-check.sh` (planted ungrounded term is reported; a fully
  closed fixture reports empty). The LLM judgment is confined to step 1 (EXPLAIN) and step 3
  (ground the term) — both anchored to the harvest evidence list (NFR-3 honest floor).

#### The bounded cap + config

The loop is **bounded** (FR-14 + NFR-2: "MUST be bounded — K-consecutive-clean or token
budget"). This feature **adds a new top-level `discovery:` block** to the `settings.yml`
template — the template currently has **no** `discovery:` key (its keys are
project/tools/review/execution/traceability/kb_baseline). `discovery.doc_set` is **not** a
template default: it is written at runtime by `state-generate.md` Step 0d (only when the
confirmed doc-set differs from the seed), so it is a conditional runtime-written sibling of
`closure:` under the same `discovery:` parent — not a pre-existing template key f004 nests
into. f004 introduces the parent block with the `closure:` child:

```yaml
discovery:
  # doc_set: <runtime-written sibling — NOT a template default; written by Step 0d when the
  #          confirmed doc-set differs from the seed. f004 does not add it; shown here only
  #          to document that closure: shares the discovery: parent with it.>
  closure:
    max_clean_passes: 2        # CLOSED after this many consecutive zero-ungrounded DETECT passes (default 2)
    max_rounds: 4              # hard ceiling on EXPLAIN->DETECT->INVESTIGATE rounds (wall-clock guard)
    token_budget: 0            # optional alternative cap: 0 = use pass/round caps; >0 = stop when cumulative loop tokens exceed budget
```

Read via the existing `read-setting.sh --path discovery.closure.max_clean_passes --default 2`
accessor (no new config machinery — D5). Defaults live in the `settings.yml` template (added
by this feature). **Path scaling (f006):** the three paths set these caps —
brownfield-large uses the full batched loop (default caps); brownfield-small uses
`max_rounds: 1` (single understand-pass, §1.5 matrix); greenfield closure is "intent coherent
+ vocab set" (f006 wires the path→cap mapping; f004 provides the knobs + the default
brownfield-large behavior). **When the cap trips before CLOSED**, the remaining ungrounded
terms are NOT dropped — each is escalated as a human Q&A (FR-32, below), so a budget exhaust
degrades to "surface the gaps," never "ship shallow silently" (REQUIREMENTS §1.4 honest limit).

### Can't-Explain Tripwire (FR-15)

The tripwire is the **rule that makes every ungrounded project-specific term a mandatory
investigation, never ignorable noise** (the root failure was treating 'Relative bus' as
noise). It is enforced at two layers, both grounded:

1. **Mechanical (DETECT).** `closure-check.sh` makes "ungrounded term" a *computed set*, not
   a judgment — a candidate-concept term used-but-undefined is mechanically flagged, so it
   *cannot* be glossed as noise; the loop must act on every member of the set.
2. **Prompt (every researcher + the architect).** The deep-dive and grounding prompts carry
   the explicit instruction: *"Any project-specific term you reach for while explaining the
   system that you cannot confidently define from general knowledge is a MANDATORY
   investigation — ground it from the artifacts or escalate it; never skip it as noise."*
   (REQUIREMENTS §1.4 verbatim intent.) This is the judgment-side tripwire for terms the
   mechanical harvest did not fingerprint (a concept named only in one obscure comment); the
   mechanical layer catches the fingerprinted ones, the prompt catches the rest.

### Read All Source Types (FR-16)

Both the harvest and the researchers consume all source types:
- **Harvest:** the 5 channels (code / docs / config / comments / history) are the FR-16 set
  made mechanical — comments and commit/issue history are first-class harvest inputs, not just
  code (the *why-here* prose lives there, §1.4).
- **Researchers:** the deep-dive prompts already direct agents to read code + docs +
  `external-sources.md` (`agent-prompts.md`); f004 **adds** the directive to read
  `candidate-concepts.md` (which surfaces history/comment-sourced terms) and to follow each
  candidate's `Example source` anchor into the *why* source (ADR/report/commit) when grounding
  it. The data-bundle / issue-history path enters via `external-sources.md` (the scout already
  inventories external docs, Step 0b/Step 1) + the `--history-file` harvest arg.

### Human Escalation (FR-32)

**Reuses the existing scout-questions → `STATE.md ## Q&A (Pending)` backlog (Step 6b) — no
new queue.** When a candidate-concept term cannot be grounded from any artifact after
investigation (the §1.4 "ungroundable model gap" — a concept held in heads, never named in a
fingerprinted artifact), the closure loop **does not drop it**; it writes a Q&A entry, using
the exact mechanism Step 6b already consumes:

- During the loop, an ungroundable term is appended to `.aid/knowledge/.scout-questions.tmp`
  (the same temp file the scout writes, `agent-prompts.md` §Scout line 57), in the existing
  structured Q&A format (`### Q{N}` + Category/Impact/Status/Context/Suggested/Question, per
  `state-generate.md` Step 6b). Category: `Concept`; Impact: `High` (a load-bearing concept
  the KB cannot explain); Context: where the term recurs (its `candidate-concepts.md` anchor)
  + why it could not be grounded; Suggested: the best partial inference or "—".
- **Step 6b is unchanged** — it already reads `.scout-questions.tmp`, consolidates into
  `## Q&A (Pending)` with sequential IDs, and deletes the temp file. The closure loop simply
  feeds the same pipe. This converts a silent miss into a caught human question (FR-32, AC15),
  reusing the existing backlog exactly as the user directed.
- This is the §1.4 honest-limit escape hatch: capture every *fingerprinted* concept (harvest +
  closure), and *escalate* the un-fingerprinted ones rather than ship shallow.

### Determinism & Cost (FR-23 / NFR-1-3)

- **Mechanical-first (NFR-1, the cost lever).** The harvest is a **script, not an LLM**
  (zero dispatch tokens for the anchor); the DETECT/termination oracle is a **script**
  (`closure-check.sh`); the salience ranking is **arithmetic** in `awk`. The only LLM surface
  is EXPLAIN (synthesis) + ground-a-term (investigation) — both **anchored** to the harvest
  evidence list (the §1.6 honest floor). Total discovery cost stays within the same order of
  magnitude as today's discover (NFR-1): the new LLM work is bounded by the cap, and the
  expensive part (the anchor + the closure oracle) is free deterministic script time.
- **Bounded wall-clock (NFR-2).** The loop is capped (`max_clean_passes` / `max_rounds` /
  optional `token_budget`) and **batched-parallel** (detect-all → fill-all-parallel →
  re-check ≈ 2-3 rounds, not N sequential iterations). The harvest is a single ~30s script
  pass (like `build-project-index.sh`).
- **Determinism / repeatability (NFR-3).** The harvest output is byte-reproducible (stable
  sort, fixed tie-break, fixed denylist) — CI asserts re-run byte-identity. The closure
  termination is a deterministic script. The teach-back/evidence anchor (the
  `candidate-concepts.md` term set) is the **fixed question set** §1.6/NFR-3 names. The
  irreducible judgment (EXPLAIN / "did it understand") is minimized + evidence-anchored, not
  pretended away.

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| **NEW harvest script** | `canonical/aid/scripts/kb/harvest-coined-terms.sh` | The deterministic coined-term harvest (extraction E1-E5, channels, denylist filter, salience ranking, markdown output). ASCII bash; reuses `build-project-index.sh`'s prune set + OUTPUT resolution. |
| **NEW denylist** | `canonical/aid/scripts/kb/coined-term-denylist.txt` | Shipped, sorted, lowercased, ASCII wordlist (common English + common-tech). Project override via `.aid/knowledge/.coined-term-denylist.local.txt`. |
| **NEW closure oracle** | `canonical/aid/scripts/kb/closure-check.sh` | Deterministic self-containment check (ungrounded candidate/relates-to terms used-but-undefined in the spine). ASCII bash; no LLM. The loop's DETECT/termination step. |
| GENERATE flow | `canonical/skills/aid-discover/references/state-generate.md` | Add **Step 0e** (run harvest before fan-out); add `candidate-concepts.md` to the REFERENCE DOCUMENTS block; add **Step 5b (SYNTHESIS + CLOSURE)** chaining to the new closure reference; route ungroundable terms into `.scout-questions.tmp` (Step 6b unchanged). |
| **NEW closure reference** | `canonical/skills/aid-discover/references/state-closure.md` | The EXPLAIN→DETECT→INVESTIGATE→REPEAT loop body, the cap read from `discovery.closure`, the batched-parallel dispatch, the FR-32 escalation. Thin-router pattern (C8). |
| Agent prompts | `canonical/skills/aid-discover/references/agent-prompts.md` | Add the spine-grounding + tripwire mandate to the Integrator (glossary owner) + all four deep-dive prompts; add a **Grounding** prompt section for the closure-loop sub-agents. |
| Spine template | `canonical/aid/templates/knowledge-base/domain-glossary.md` | Upgrade to the concept-spine structure (concept entries: definition-as-used-here / relates-to / per-concept `sources:`; retain lexicon tables). Content upgrade; f001 owns the frontmatter schema, f011 migrates AID's own glossary. |
| Settings template | `canonical/aid/templates/settings.yml` | Add the **new top-level `discovery:` block** (the template has no `discovery:` key today) with its `closure:` child (`max_clean_passes`/`max_rounds`/`token_budget`) + defaults + comments. `doc_set` is NOT added — it stays a conditional runtime-written sibling (Step 0d). |
| CI — canonical suites | `tests/canonical/test-harvest-coined-terms.sh` (NEW), `tests/canonical/test-closure-check.sh` (NEW) + fixtures under `tests/canonical/fixtures/` | Mechanical assertions for the harvest (filter/rank/channels/'Relative bus' planted/output shape + byte-reproducibility) and the closure oracle (ungrounded reported / closed empty). Auto-discovered by `tests/run-all.sh`. |
| CI — ascii-only | `tests/canonical/test-ascii-only.sh` | Add `canonical/aid/scripts/kb/harvest-coined-terms.sh`, `closure-check.sh`, and `coined-term-denylist.txt` to `SHIPPED_SCRIPTS`. **[SPIKE-H3]** — confirm the denylist seed is fully ASCII. |
| render-drift | `test.yml` job `render-drift` | No edit; stays green by editing canonical only + re-running `run_generator.py` (C3). The three new files under `canonical/aid/scripts/kb/` + the template/reference edits render to all 5 trees. |

### Constraints

- **C2 / Q2 — ASCII-only.** `harvest-coined-terms.sh`, `closure-check.sh`, and
  `coined-term-denylist.txt` vendor into the install bundles → ASCII-only (bash; PS-5.1 N/A).
  Added to the `test-ascii-only.sh` allow-list. The denylist seed wordlist must be trimmed to
  ASCII (drop accented loanwords). **[SPIKE-H3].**
- **C1 / NFR-8 — no new runtime.** Pure coreutils (`find`/`grep`/`awk`/`sort`/`tr`/`comm`/
  `git`) — the toolset `build-project-index.sh` already uses. No embedding model, binary, MCP,
  or `python3`/`pwsh` escalation. The denylist is shipped data, not a runtime dependency.
- **C3 / NFR-4 — render-drift green.** All authored files are canonical (`scripts/kb/*`,
  `templates/knowledge-base/domain-glossary.md`, `templates/settings.yml`,
  `skills/aid-discover/references/*`). Edit canonical only; re-run
  `python .claude/skills/generate-profile/scripts/run_generator.py`; commit regenerated
  `profiles/` (render-drift-full-generator precedent). **[SPIKE-H4]** — verify the renderer
  auto-discovers a net-new `scripts/kb/*.txt` data file (it enumerates the tree; expected yes)
  and emits it to all 5 trees; if an emission manifest pins the `scripts/kb/` file list,
  update canonical + regen, never hand-place.
- **C5 / NFR-3 — deterministic, CI-testable.** Both new scripts are mechanical, stable-sorted,
  fixed-tie-break, byte-reproducible, and asserted in the new canonical suites.
- **C4 — human-gated.** The harvest + closure are detection/synthesis; the resulting KB
  content still passes the existing REVIEW gate (f005) + human approval before it is final.
  Ungroundable concepts escalate to the human via Q&A (FR-32), never auto-resolved.
- **C6 — content-isolation.** New scripts are namespaced under `aid/scripts/kb/`; generated
  outputs live under `.aid/generated/` (transient) and the spine under `.aid/knowledge/`
  (the existing isolated KB tree).

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-H1]** History-channel sourcing — git-log harvesting on non-git trees + the
  `--history-file` issue/report bundle contract (degrade to empty history channel; confirm the
  orchestrator fills `--history-file` from `external-sources.md` when a bundle is declared).
- **[SPIKE-H2]** Denylist size + phrase-survival/salience-floor tuning — calibrate recall
  (must surface the planted 'Relative bus' phrase) vs precision (must not bury it under
  common-word phrase noise) against the f012 fixture. The phrase salience floor (spread>=2 for
  all-common-word phrases) is the precision lever, f012-calibrated.
- **[SPIKE-H3]** Denylist ASCII — confirm the trimmed seed wordlist is 100% ASCII before
  adding it to the ASCII guard (accented loanwords must be dropped or CI reds).
- **[SPIKE-H4]** Net-new `scripts/kb/*.txt` render — verify `run_generator.py` emits a
  net-new non-`.sh` data file to all 5 trees (it enumerates the tree); if any emission
  manifest pins the `scripts/kb/` list, regen, never hand-place.
- **[SPIKE-H5 — sequencing]** f004 consumes f001's `sources:`/frontmatter schema and f003's
  concern-model designation of `domain-glossary.md` as the C4 spine doc; f005 grades the spine
  + runs teach-back; f006 wires path→closure-cap; f011 migrates AID's own glossary into spine
  shape. Confirm with PLAN.md that f001+f003 land before f004's spine content, and that f004's
  `discovery.closure` knobs land before f006 wires the path mapping (provide-before-consume).
- **[SPIKE-H6 — boundary]** Closure cap "token_budget" measurement — counting cumulative loop
  tokens deterministically across hosts is host-dependent; v1 defaults to the pass/round caps
  (`token_budget: 0`) and treats `token_budget>0` as a best-effort secondary cap, since exact
  token accounting is not uniformly available (A3 capability-probe precedent). The
  deterministic guarantee rests on `max_clean_passes`/`max_rounds`, not the token budget.

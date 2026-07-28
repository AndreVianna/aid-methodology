# KB Gap Ledger And Routing

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.9 (FR-20, FR-25–FR-27), §2 item 1, §7 (C-6), §9 (AC-14, AC-15) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Finding 1 [CRITICAL] fixed — the coverage predicate is now a single shared module; `kb_gaps` demoted to a verified generate-time record; `kb:`-unbacked confirmed lens-only. Finding 2 [HIGH] fixed — D3 F4 restated as an invariant owned by feature-004, not a filter applied here | /aid-specify |
| 2026-07-28 | Owner corrections applied: (1) the shared predicate module is repointed to `canonical/aid/scripts/graph/coverage-predicate.mjs` per feature-007, and the `package.json` ESM-marker requirement is **deleted**; (2) the zero-row-node residue is **closed** — gap detection now runs over feature-004's enumerated node set, so an `int:` node with no table row becomes a `kb_gaps` entry and a ledger row, and `kb_gaps` entries gain `name` | /aid-specify |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the render and manifest lockstep is now **feature-012**'s and the ship-time Knowledge Base update is **feature-013**'s, in the Layers preamble, L3 and Migration steps 3–4. No decision in this SPEC changes | /aid-specify |

## Source

- REQUIREMENTS.md §5.9 (FR-25, FR-26, FR-27) and its Rationale paragraph
- REQUIREMENTS.md §5.7 FR-20 (a source concept with no Knowledge Base representation is
  reported as a defect; feature-004 detects the condition, this feature reports it)
- REQUIREMENTS.md §2 Problem Statement item 1 (drift and coverage detection — the purpose this
  feature serves)
- REQUIREMENTS.md §4 Out of Scope (fixing gaps; automatic ticket creation — both explicitly
  excluded here)
- REQUIREMENTS.md §7 Constraints — **C-6** (project-wide seven-column reviewer ledger schema
  written to the shared review-pending location; no bespoke findings format)
- REQUIREMENTS.md §9 (AC-14, AC-15)

**Dependency position.** Blocked by feature-004 (the enumerated node set the gap condition is
computed against) and feature-005 (the Knowledge Base coverage that says which of those nodes
are accounted for). Not blocked by either RESEARCH feature.

**Shared acceptance criterion — AC-15.** The Coverage lens and this ledger must agree. The
agreement *is* the criterion, so this feature owns it, but feature-007 and feature-008 must
satisfy it from the view side. AC-15 appears in this SPEC and in feature-007's as a mutual
obligation; neither feature may consider it met alone.

## Description

When a significant part of the project source turns out to have no representation in the
Knowledge Base, that is a defect in the Knowledge Base — not a curiosity, and not merely a node
with no edges. This feature is how such findings leave the tool and reach someone who can act
on them.

Findings are written as a reviewer ledger in the same seven-column shape the project uses
everywhere else, in the same place reviewers already look. One row per gap, and each row
carries the offending source artifact as its evidence, so a reviewer can go straight to the
thing that is undocumented rather than reconstructing what the finding meant.

Crucially, finding gaps never stops the run. `/aid-graph` reports; it does not gate. A run that
uncovers fifty gaps completes exactly as successfully as one that uncovers none. This is
deliberate and load-bearing: gating on Knowledge Base completeness would fail the tool for
reasons entirely outside its own control, and worse, it would create a standing incentive to
loosen the significance rule until the gaps stopped appearing — destroying the very signal the
artifact exists to produce. Reporting-only also keeps trust flowing one way: the tool observes
the Knowledge Base and cannot alter what it observes.

Fixing the gaps is somebody else's job. Findings route onward to the skills that already own
targeted Knowledge Base updates and re-discovery. This feature does not repair anything, and it
does not open tickets.

## User Stories

- As a **KB reviewer**, I want each gap delivered as a ledger row in the format I already
  review, with the offending source artifact named as evidence, so that I can verify and act on
  it without learning a new findings format.
- As a **maintainer/architect**, I want the run to succeed even when it finds many gaps, so that
  I get the report instead of a failure and can decide what to do about it.
- As the **AID methodology owner**, I want the tool to have no incentive to under-report, so
  that the gap signal stays trustworthy over time.
- As a **maintainer/architect**, I want findings pointed at the skills that already own
  Knowledge Base repair, so that a gap becomes tracked work rather than a note I forget.

## Priority

Must

## Acceptance Criteria

- [ ] AC-14: Given a run that detects one or more Knowledge Base gaps, when the run finishes,
      then each gap appears as a ledger row carrying the offending source artifact as its
      evidence, **and** the run still completes successfully.
- [ ] AC-15 *(shared with feature-007 — mutual obligation; neither feature may consider this met
      alone)*: Given a generated ledger and a generated graph view, when the Coverage lens is
      applied, then the lens surfaces exactly the gaps present in the ledger — the two agree,
      with no gap in one that is absent from the other.
- [ ] Given any number of detected gaps, when the run completes, then its exit status is success
      — the run never fails because gaps exist.
- [ ] Given a generated gap ledger, when its structure is checked, then it uses the project-wide
      seven-column reviewer-ledger shape at the shared review-pending location, with no bespoke
      findings format.
- [ ] Given a completed run that detected gaps, when the output is read, then it names the
      skills that own Knowledge Base repair as the route onward, and the run itself has neither
      modified the Knowledge Base nor opened a ticket.

---

## Technical Specification

> Grounded in `.aid/knowledge/quality-gates.md` (The Reviewer Ledger, How the Grade Is Computed),
> `.claude/aid/templates/reviewer-ledger-schema.md`, `.claude/aid/scripts/grade.sh`,
> `.aid/knowledge/authoring-conventions.md` (Reviewer Ledger Convention, Prose Over Scripts),
> `.aid/knowledge/coding-standards.md` (File Header Convention, Exit Codes),
> `.aid/knowledge/module-map.md` (Conventions — "Where a new helper script goes"), and
> `canonical/aid/scripts/kb/build-kb-index.sh` / `lint-frontmatter.sh` (verified tolerance of
> generator-written frontmatter keys).

### Data Model

#### D1 — Inputs (all read-only)

| Input | Producer | Shape consumed here |
|---|---|---|
| The enumerated `int:` node set (`nodes.tsv`) | feature-004 | **The candidate set** the predicate is evaluated over — every enumerated node is a candidate, whether or not it appears in the table (D2). Its `qualifier` and `evidence` fields then supply each emitted row's severity (D4) and `Evidence` cell (D5). |
| The final relationship table | feature-003 (schema) + feature-005 (rows) | The eight columns of REQUIREMENTS.md §5.2, after **both** extraction passes have completed (FR-30, FR-31). Supplies the **edge set** the predicate tests each candidate against. |
| The relation vocabulary, with each pair's category | feature-001 | Fixes the membership of `COVERAGE_BEARING` — condition 3 of the predicate (D2). It is consumed as the reviewable statement of that subset, not as a runtime input; the executable copy lives in the shared module. |

This feature reads those three inputs and writes nothing back into any of them. It adds no new
scan and no second traversal — the gap set is a query over data that already exists, which is why
it can be computed after extraction rather than during it.

#### D2 — The coverage predicate: one implementation, in a shared `.mjs` module

**There is exactly one implementation of the predicate, and this feature does not hold it.** It is
`detectKbGaps({nodeIds, edges})`, exported from
`canonical/aid/scripts/graph/coverage-predicate.mjs` — the purpose-built module feature-007
specifies and owns. This feature owns the predicate's *semantics*, which feature-007 adopts verbatim;
feature-007 owns the *file*. Both consumers call that one function: this feature's generator
`import`s it under Node, and the view runs the same bytes inlined in the browser. Agreement between
the ledger and the Coverage lens is therefore structural — one implementation, two runtimes — rather
than two readings of the same prose. D6 records how the two runtimes reach the same bytes and how
the result is verified.

**The predicate.** An enumerated `int:` node is **covered** when at least one edge of the final table
satisfies all three conditions:

1. the node is one of the edge's endpoints, **or** an ancestor path of the node is that endpoint — a
   `kb:` doc that documents a directory covers the artifacts inside it (D3, false-gap class F2).
   Path matching needs no new field: an `int:` id *is* its repo-relative path with the prefix
   stripped (D5, `Doc` column);
2. the edge's other endpoint carries the `kb:` prefix (REQUIREMENTS.md §5.3);
3. the relation naming that direction is a member of `COVERAGE_BEARING` — the coverage-bearing
   subset of the closed vocabulary, the pairs that mean "this KB concept describes / is derived from
   this artifact" rather than merely co-locating two nodes.

A candidate that is **not** covered is a **gap**. Condition 3 is what stops a bare mention from
clearing a gap; condition 1 is what stops D3's F2 from firing at scale, since KB documents cite bare
directories in their `sources:` frontmatter.

**The candidate set is feature-004's enumerated inventory, not the table's node column.** This is the
load-bearing choice, and it is deliberate: FR-19 and FR-20 are about *source artifacts with no
Knowledge Base representation*, and an artifact with no relationships at all is the extreme case of
that, not an exception to it. feature-004 qualifies by structural significance — an entry point or a
named unit need have no edge — so a zero-row node is reachable in practice. Computing over table
rows alone would make the ledger silently blind to precisely the worst finding it exists to produce.
`detectKbGaps`'s `nodeIds` argument exists for this: Node passes the full `nodes.tsv` inventory, the
browser passes what the table contains, and the difference between the two is the `orphans` class
feature-007's verification names and materialises (D6).

**Ownership of `COVERAGE_BEARING`.** feature-001 owns the vocabulary and its categories. This
feature owns only the *selection*: the subset is declared here as a named list, enumerated by pair
name, and stored beside the vocabulary artifact so a reviewer can read the two together. The
executable copy lives in `coverage-predicate.mjs`, because that module may not `import` anything
(D6); feature-007's **GV04** asserts the two copies are equal, which is the same doc↔code lockstep
the project already uses for render drift. If feature-001's research produces a category that
already means exactly this, the subset is that category and nothing further is declared.

#### D3 — False-gap classes and how each is excluded

A false gap is worse than a missed one: it teaches a reviewer to distrust the ledger, and it is the
first pressure toward loosening FR-21. Five classes are excluded **structurally**, not by tuning.

| # | False-gap class | Structural exclusion |
|---|---|---|
| F1 | A covering edge exists but was not yet typed when the predicate ran | The predicate runs **once, after** the pass-2 agent step (FR-31) completes, over the final table only. There is no early evaluation to be wrong. |
| F2 | The KB documents the artifact at a coarser grain — a doc covers a directory or a script area, not the file | D2's **condition 1**, ancestor-path matching. A `kb:` ↔ `int:canonical/aid/scripts/summarize` edge covers every enumerated node beneath that path. This class is not hypothetical: KB frontmatter `sources:` lists bare directories, so `.aid/knowledge/module-map.md`'s own `sources:` cites `bin/`, `lib/`, `canonical/`, `profiles/`, `packages/`, `dashboard/`, `site/`, and `tests/`. Without ancestor matching, dogfooding `/aid-graph` on AID would report nearly every file under those trees as a gap while `module-map.md` demonstrably documents them. |
| F3 | The covering edge is only `inferred`, so a strict reading would discard it and report a gap | Coverage is counted from rows of **any** `Provenance` value — none of D2's three conditions reads the `Provenance` column. The asymmetry with F4's invariant is deliberate: be liberal about what counts as coverage, strict about what counts as a qualified node. |
| F4 | The gap rests on a node that only qualified by agent opinion | **Excluded upstream, by an invariant this feature relies on rather than a filter it applies.** feature-004 owns it: its node record carries `evidence_provenance` ∈ {`declared`, `derived`} and its D3 states the hard rule — "`evidence_provenance` is never `inferred`, and a candidate that only a reading would qualify is **not emitted as a node**", written instead to `candidates.tsv` with a `drop_reason`. Such a node therefore never enters the node set, never reaches the table, and cannot become a ledger row. |
| F5 | The artifact is a rendered copy, vendored code, or ignore-listed | Never enumerated at all (FR-22, AC-16) — it cannot reach this feature. |

**Why F4 is stated as an invariant and not implemented as a check.** A filter here would need
per-node qualification provenance available at predicate-evaluation time, and the shared predicate
of D2 is computed from `GraphModel` alone, whose node record carries no such field. Adding one
would put a second, weaker copy of feature-004's rule in the view layer — the exact duplication
Finding 1 removed. Since feature-004 guarantees the set is already clean, the correct engineering
answer is to depend on the guarantee and name its owner. If feature-004's guarantee were ever
weakened, this row is where the consequence lands, and `GL03` (L4) is the assertion that would go
red.

#### D4 — Severity assignment (derivable, not judged)

Severity is a function of the FR-21 clause the node qualified under — the same evidence the row
already carries — so two runs over the same node set produce the same severity. It is a triage
signal for the human, never a gate (D7).

| Severity | Assigned when the node qualified as… | Why this rank |
|---|---|---|
| `[HIGH]` | an **entry point or public surface** — a skill, a CLI command, a template, or a script another script invokes (FR-21 clause 1) | An undocumented public surface is the class the KB exists to describe; matches the schema's `[HIGH]` band, "Wrong claim, dead reference, broken citation, or missing post-merge content" |
| `[MEDIUM]` | **depended upon** by at least one other enumerated artifact, and not a public surface (FR-21 clause 2) | Internal contract drift — the schema's `[MEDIUM]` band |
| `[LOW]` | only a **named unit by the project's own conventions** — a test suite, a manifest, a settings schema (FR-21 clause 3) | Real but low-consequence documentation debt |

Two enum values are **never** assigned, and the reason is recorded so a later change cannot widen
the range by accident:

- `[CRITICAL]` — reserved by the schema for "will mislead downstream phases or break tooling". A
  documentation gap breaks nothing at run time, and a never-graded ledger that shouted `[CRITICAL]`
  would read as a blocker it is not.
- `[MINOR]` — a gap is never cosmetic. Emitting `[MINOR]` would let a reviewer sort the whole
  ledger to the bottom of their queue.

**Tie-break.** A node satisfying more than one FR-21 clause takes the **highest** applicable
severity, mirroring the project rubric's "worst severity dominates" rule
(`.aid/knowledge/quality-gates.md` The Grade Scale).

#### D5 — The ledger row

Exactly the project-wide seven columns of `.claude/aid/templates/reviewer-ledger-schema.md`, with
no additional column and no narrative anywhere in the file (C-6).

| Column | Value for a gap row |
|---|---|
| `#` | Next sequential row number within the file; never renumbered across cycles |
| `Severity` | The bracketed value from D4 — one of `[HIGH]`, `[MEDIUM]`, `[LOW]` |
| `Status` | `Pending` on first emission. On a later run, a node still uncovered stays `Pending`; a node now covered becomes `Fixed`; a node that was `Fixed` and is uncovered again becomes `Recurred`. `Accepted` / `OOS` / `Invalid` are set only by the orchestrator with the user authorization the schema requires — `/aid-graph` never writes them. |
| `Doc` | The offending artifact's **repo-relative path** — the `int:` id with its `int:` prefix stripped, so the cell is directly openable (the schema requires a repo-relative path here, e.g. `canonical/aid/scripts/graph/detect-kb-gaps.mjs`) |
| `Line` | `—` always. FR-23 fixes granularity at the whole artifact, so there is no line to name, and inventing one would contradict AC-16. |
| `Description` | One sentence, fixed form: `no Knowledge Base document covers <int-id> (qualified as <clause>)` |
| `Evidence` | The FR-24 qualification evidence verbatim from feature-004, plus the recheck command. Form: `<rule> — <disk fact>; recheck: grep -c 'int:<path>' .aid/knowledge/relationships.md = 0` |

**A zero-row node emits an ordinary row — no special case anywhere in this table.** Its `Doc` is its
path like any other, its `Description` reads the same, and its recheck command is not merely valid
but the sharpest form of the evidence: `grep -c 'int:<path>' relationships.md` returns `0` because
the id appears in no row at all. The one difference is informational, and it belongs in
`Description`, which gains a trailing clause when the node has no relationships:
`no Knowledge Base document covers <int-id> (qualified as <clause>; no relationships in the table)`.
That is the FR-20 sentence a reviewer most needs to read, and burying it would be the "silently
dropped" failure FR-20 names.

`Evidence` carries the **offending `int:` node** as AC-14 requires, and carries it as something a
reviewer can run rather than a claim they must trust. Any `|` inside `Description` or `Evidence` is
escaped `\|` per the schema's pipe rule.

#### D6 — The AC-15 carrier: one implementation, two runtimes

AC-15 requires the Coverage lens and this ledger to agree. Agreement is made **structural** by
having one function compute the set on both sides, and then *verified* rather than assumed.

**The shared module.** `canonical/aid/scripts/graph/coverage-predicate.mjs` (feature-007) is the
single implementation. Three properties of that choice matter to this feature and are stated so a
later change cannot quietly undo them:

- **`.mjs`, not `.js`.** The extension alone makes the file unambiguously an ES module to Node, so
  no `package.json` marker is needed anywhere. A marker would otherwise have to sit in a *template*
  directory that renders into all five profile trees, putting a stray `package.json` into every
  adopter's install where their own tooling could misread it. **This SPEC's earlier `package.json`
  ESM-marker requirement is withdrawn entirely** — there is no marker file in this work.
- **Purpose-built, not the view model.** `graph-model.js` also carries the markdown parser,
  `project()`, the store and the presets; importing it from Node would pull the whole view layer
  into the pipeline. The predicate module imports nothing, touches no DOM global, and exchanges
  plain data only (feature-007's four boundary rules, asserted by its **GV01**).
- **It renders as text, so it must contain no paths.** `.mjs` is in `render.py`'s `_TEXT_EXTENSIONS`,
  so every rendered copy passes through `substitute_filenames` and `rewrite_install_paths` — unlike
  a `.yml`, which is copied verbatim. The module must therefore contain **no `canonical/…` path and
  no filename placeholder**, or the canonical and rendered copies diverge and feature-007's **GV02**
  byte-identity test between the inlined region of `graph.html` and the module file breaks. Nothing
  in the predicate needs a path — its only path-shaped data is the `int:` ids passed in as plain
  strings — so the constraint costs nothing, but it is a real authoring rule for whoever writes the
  file.

| Runtime | How it reaches the module |
|---|---|
| **Node, at generate time** | `detect-kb-gaps.mjs` (L2) does `import { detectKbGaps } from '../graph/coverage-predicate.mjs'` — a sibling in the same script area, so the specifier is a plain relative path with no resolution machinery behind it. |
| **Browser, at load time** | The generate step inlines the same file byte-identically as the first segment of one `<script type="module">` (feature-007's § "How each runtime reaches it"). No second copy is authored and no transpile step intervenes. |

**`kb_gaps` frontmatter: a recorded result, not a second source of truth.** `relationships.md`
carries a generator-written key listing what `detectKbGaps` returned at generate time:

```yaml
kb_gaps:
  - id: "int:canonical/aid/scripts/graph/detect-kb-gaps.mjs"
    name: "canonical/aid/scripts/graph/detect-kb-gaps.mjs"
    severity: "HIGH"
    clause: "entry-point"
  - id: "int:tests/canonical/test-graph-gap-ledger.sh"
    name: "tests/canonical/test-graph-gap-ledger.sh"
    severity: "LOW"
    clause: "named-unit"
```

`name` is the display name from field 2 of feature-004's `nodes.tsv`. It is carried rather than
derived because a consumer must be able to *present* an entry whose node appears in no table row and
therefore has no `GraphModel` node to read a label from. For an `int:` id the two happen to coincide
today — feature-003 D5 fixes the display name as the repo-relative path — but making the view
re-derive it would put a naming rule in the consumer for the one case where the consumer has the
least information. This widens feature-007's `recordedGaps` type from `{id, severity, clause}` to
`{id, name, severity, clause}`; the addition is purely additive and no existing consumer breaks.

- The **ledger** emits exactly one row per `kb_gaps` entry, in list order. `kb_gaps` is written from
  the same call whose result the rows are built from, so the two cannot diverge within a run.
- The **Coverage lens** does **not** read `kb_gaps` as its input. It calls `detectKbGaps` over the
  nodes it can see and **verifies** the result against the record, publishing
  `coverageGaps.intUndocumented` as the **union** of the two (feature-007's verification table). A
  disagreement it cannot explain fails loudly into the page's visible error region rather than
  rendering a picture that quietly contradicts the ledger.
- **`kb:`-unbacked is lens-only.** `kbUnbacked` is a separate export, computed in the view only,
  surfaced by the Coverage lens, and written to no frontmatter key and no ledger row. AC-15's
  equality binds the `int:` class alone, matching FR-20 and FR-26, which give the ledger rows for
  undocumented source and nothing else.
- FR-3 and AC-10 hold, and the zero-row case is where that is worth saying explicitly: `kb_gaps`
  lives in `relationships.md`'s own frontmatter, so the view still reads **exactly one artifact**.
  A zero-row node reaches the page from the same file the table is in — not from a second file, not
  from a second extraction, and not from a fetch.

**How AC-15's equality now holds — the argument has changed.** It used to rest on both surfaces
computing over the table's node column, which made them agree by being equally blind to a zero-row
node. It now rests on both surfaces resolving to the same **node set**: the generator evaluates the
predicate over feature-004's full inventory and records the answer; the view evaluates the same
predicate over the nodes it can see and unions in the record, which restores exactly the entries its
own candidate set could not contain. `orphans = G \ T` is the expected, named difference between the
two candidate sets — not a mismatch — and after the union both surfaces list the same gaps. The
equality is now true of the artifact a reader actually sees, rather than true of a set both artifacts
had jointly excluded.

Verified safe to add: `canonical/aid/scripts/kb/lint-frontmatter.sh` validates only the named
fields (`objective`, `summary`, `sources`, `tags`, `see_also`, `audience`, `owner`,
`approved_at_commit`) and emits nothing for an unrecognised key;
`canonical/aid/scripts/kb/build-kb-index.sh` composes its row from named fields only. `kb_gaps` is
therefore a generator-written field in the same class as `generator:` and `approved_at_commit:` and
does not disturb C-7 / AC-18.

**The agreement test** asserts three sets are equal: the `kb_gaps` list in the frontmatter, the
`Doc` column of the ledger, and an in-test call to `detectKbGaps` over the fixture's node inventory
and table. The third is not an independent reimplementation — that is the point — it is the check
that the *carrier* has not drifted from what the one predicate returns, which is the only failure
mode a single implementation still permits.

#### D7 — Two ledger scopes, so the gate cannot see the gaps

FR-25's "reports, never gates" and FR-28's "own artifacts only" are enforced by **file separation**,
because `.claude/aid/scripts/grade.sh` grades exactly one file passed as its argument and has no
row-filtering flag. Splitting by file makes conflation impossible rather than merely discouraged.

| Ledger | Path | Contents | Graded by `grade.sh`? | Lifecycle |
|---|---|---|---|---|
| Own-artifact findings | `.aid/.temp/review-pending/graph.md` | feature-010's FR-28 rubric failures only — id resolvability, inverse-pair consistency, provenance population, view validity | **Yes** — this file is the run's gate | Standard schema lifecycle: persists across REVIEW→FIX cycles, **deleted at DONE** |
| KB gap findings | `.aid/.temp/review-pending/graph-kb-gaps.md` | One row per `kb_gaps` entry | **Never.** No state passes this path to `grade.sh` | **Retained at DONE** — see the carve-out below |

Both paths obey C-6: the mandated directory, the mandated seven-column shape, no bespoke format.

**Retention carve-out (a deliberate departure from the schema's lifecycle).**
`reviewer-ledger-schema.md` ("Lifecycle (per skill invocation)") has the orchestrator delete the
ledger at skill DONE. That is correct for a review-cycle scratch file and wrong for a hand-off
artifact: deleting `graph-kb-gaps.md` at DONE would destroy the findings FR-26 exists to deliver and
FR-27 exists to route. The carve-out is therefore written **into the shared schema** (see L3), not
left as local behaviour, so a future orchestrator reading the schema does not delete it. Its
lifecycle is: written at GAP-REPORT, retained past DONE, and replaced wholesale by the next
`/aid-graph` run (which reads the previous file first to compute the `Fixed` / `Recurred`
transitions of D5). It is removed by whoever consumes it.

### Feature Flow

Runs as one state of the `/aid-graph` state machine (feature-010 owns the machine; this feature owns
the state's body — see L1). Every step below reads real paths.

1. **Enter GAP-REPORT.** Precondition asserted by feature-010's dispatch: EMIT has completed, so
   `.aid/knowledge/relationships.md` exists and contains the final post-pass-2 table.
2. **Load the previous gap ledger** if `.aid/.temp/review-pending/graph-kb-gaps.md` exists, so
   existing row numbers, severities and descriptions are preserved and only `Status` moves (the
   schema's append-only rule). Absent file → this is cycle 1 and every row starts `Pending`.
3. **Call the shared predicate.** Read the final table into an edge list and feature-004's
   `nodes.tsv` into the candidate inventory, then call
   `detectKbGaps({ nodeIds, edges })` (D2) with `nodeIds` = **every** enumerated `int:` id,
   including those appearing in no row. Decorate each returned id with its display name, FR-21
   clause and FR-24 evidence from the same inventory. Result: the ordered gap set. `kbUnbacked` is
   not called here — it is lens-only. No predicate logic is written in this feature.
4. **Write `kb_gaps` into `.aid/knowledge/relationships.md` frontmatter** (D6). This is the only
   write this feature performs inside `.aid/knowledge/`, and `relationships.md` is on
   `/aid-graph`'s own write-allowlist (feature-010's FR-10 fence), so the AC-13 fence is not
   tripped.
5. **Write the ledger.** Emit `.aid/.temp/review-pending/graph-kb-gaps.md` as a single seven-column
   table and nothing else. Status transitions per D5 against the step-2 file.
6. **Print the routing block** (see below). Never invoke a repair skill, never open a ticket.
7. **Exit 0, always** — see the FR-25 enforcement below.
8. **Advance: CHAIN** to feature-010's next state (`.claude/aid/templates/state-machine-chaining.md`
   §CHAIN — this is a mechanical state with no user interaction, so it must not pause).

#### How FR-25 is enforced structurally

Four independent mechanisms, none of which is a convention a later edit could quietly drop:

| # | Mechanism | Why a violation is impossible rather than unlikely |
|---|---|---|
| S1 | **File separation** (D7) | The gate reads `graph.md`. The gap rows are in a different file. `grade.sh` cannot see them because it is never given that path. |
| S2 | **The detector's exit contract is unconditional 0** | `detect-kb-gaps.mjs` exits `0` whether it emits zero rows or five hundred, following the precedent of `canonical/aid/scripts/summarize/stale-check.sh`, whose header states "Exit 0 always (the 'decision' is informational, not a failure)". Gap count is reported on stdout, never in the exit status. Reserved: `2` for a usage/argument error only, per `.aid/knowledge/coding-standards.md` Exit Codes. |
| S3 | **The state's Advance line has no failure branch** | `state-gap-report.md` declares a single `**Advance:** CHAIN` with no conditional. There is no route from this state to FIX, to a blocked lifecycle, or to a non-zero skill exit. Adding one would require editing the Advance line, which is a visible, reviewable change. |
| S4 | **A test asserts the property, over a fixture built to fail** | `tests/canonical/test-graph-gap-ledger.sh` (L4) constructs a fixture whose KB deliberately covers nothing, runs the detector, and asserts a non-empty ledger **and** exit 0. The many-gaps case is the tested case, not the untested one. |

S1 also settles the FR-28-versus-this-feature question the work brief raises: the skill's gate and
this ledger cannot be conflated because they are not the same file, and neither state reads the
other's path.

#### Routing hand-off (FR-27)

DONE prints a routing block. It names commands the user runs; the skill runs none of them, opens no
ticket, and writes nothing into `.aid/knowledge/STATE.md` (which would violate AC-13).

```
KB gaps: 7 (3 HIGH, 2 MEDIUM, 2 LOW) — 2 with no relationships at all
Ledger:  .aid/.temp/review-pending/graph-kb-gaps.md   (retained; not graded; the run succeeded)

Route onward — /aid-graph does not fix gaps:
  Targeted, one gap or a named few:
    /aid-update-kb "document canonical/aid/scripts/graph/detect-kb-gaps.mjs in module-map.md"
  Broad sweep, many gaps or a whole subsystem:
    /aid-housekeep          # KB-DELTA re-discovers drifted docs against the repo
```

The two targets are chosen from their own declared boundary, not invented here:
`canonical/skills/aid-update-kb/SKILL.md` describes itself as "the prompt-driven-targeted half of
the KB freshness loop" whose `argument-hint` is `<what changed / what to update in the KB>`, and
routes the "source-driven-global sweep" to `aid-housekeep`'s KB-DELTA job. A single named gap is
prompt-driven-targeted; a subsystem's worth is source-driven-global. The `[HIGH]` rows are listed
first in the block so the suggested `/aid-update-kb` instruction is drawn from the most consequential
gap.

**The "no relationships at all" count changed meaning, and the change is the point.** It used to
report a class the detector had *declined* to examine. It now reports a **slice of the rows already
in the ledger** — every one of those nodes has its own row, its own severity and its own evidence,
and the count is there only because "this artifact has no relationships whatsoever" is a stronger
statement than "this artifact is undocumented" and a reader should not have to infer it by reading
`Description` cells. If the slice is empty the clause is omitted rather than printed as `0`, so the
summary line stays quiet when there is nothing to say.

### Layers & Components

Canonical-first: the skill, script, and template files below (L1–L3) are authored under `canonical/`
and rendered to the five profile trees plus the dogfood `.claude/` by the full generator
(`.aid/knowledge/module-map.md` Invariants — "Single source of truth"). The test suite (L4) lives
under `tests/canonical/`, which is repository test infrastructure and is not rendered. **feature-012**
owns the render and the manifest/count lockstep and **feature-013** owns the documentation surfaces;
this feature owns the content of the files it introduces.

#### L1 — Skill state body (the feature-010 seam)

| File | Owner | This feature's obligation |
|---|---|---|
| `canonical/skills/aid-graph/SKILL.md` | **feature-010** | Contributes exactly one row to the Dispatch table: `\| GAP-REPORT \| references/state-gap-report.md \| inline \| → RENDER \|` (the successor feature-010's state machine declares), and the corresponding node in the "you are here" map. No other edit to this file. |
| `canonical/skills/aid-graph/references/state-gap-report.md` | **feature-006** | Owned outright. Names the shared predicate the state calls (D2 — it restates no predicate logic), and carries the D4 severity rule, the D5 row form, the routing block, and the single unconditional `**Advance:**` line of S3. |

Stated this explicitly so `/aid-detail` produces one task that edits `SKILL.md` (feature-010's) and
a separate task that creates `state-gap-report.md`, rather than two tasks editing the same file.

#### L2 — Helper script

`canonical/aid/scripts/graph/detect-kb-gaps.mjs` — a new script in a new `graph/` script area,
placed per `.aid/knowledge/module-map.md` Conventions ("Where a new helper script goes: place it
under the phase area it serves").

**It is Node, not bash, and the reason is D6.** The predicate has exactly one implementation, and
that implementation is an ES module the browser also loads. Bash cannot `import` an ES module, so a
bash generator would have to restate the predicate in awk/grep — reintroducing the second
implementation Finding 1 removed, and the fork C-4 forbids. feature-007 allows either a bash CLI
shelling out to a thin `.mjs` or an outright `.mjs`; **this feature takes the outright `.mjs`**,
because the wrapper would exist only to preserve a `.sh` extension and would add a process boundary
with nothing on the near side of it. The `.mjs` extension follows the precedent already set in the
sibling script area, where `canonical/aid/scripts/summarize/validate-visuals.mjs` and
`contrast-check.mjs` are Node entry points called from bash-driven skill states.

It sits beside `coverage-predicate.mjs` in the same `graph/` area, so the import is a plain relative
sibling specifier. Two consequences of `.mjs` being in `render.py`'s `_TEXT_EXTENSIONS` apply to this
file as they do to the module: it is text-processed at render, so it must carry **no `canonical/…`
path and no filename placeholder** — every path it touches arrives through the flags below.

Justified against `.aid/knowledge/authoring-conventions.md` "Prose Over Scripts", which says a
script is added only when real logic warrants it: the Status transitions require diffing against a
previous ledger file, severity and evidence must be joined from a second inventory, and S4 needs a
callable unit to test. That is real logic, not state or argument shuffling.

Conforming to `.aid/knowledge/coding-standards.md` § JavaScript / Node Conventions and its Exit
Codes rule:

- ES module syntax, Node ≥ 20 (C-5, the floor `graph-preflight.sh` P5 asserts);
- a header comment block stating Purpose / Usage / Exit codes, matching the shape
  `validate-visuals.mjs` uses;
- exit codes `0` always-success, `2` usage error only. No other code is defined, because no other
  outcome exists — this is what keeps S2's unconditional exit 0 honest;
- stdout carries the result (the gap counts, the no-relationship slice, and the ledger path); stderr
  carries diagnostics, messages prefixed `detect-kb-gaps.mjs: `;
- any configuration read through `canonical/aid/scripts/config/read-setting.sh`, never by parsing
  `.aid/settings.yml` directly.

Interface:

```
node detect-kb-gaps.mjs --table PATH --nodes PATH --output PATH [--previous PATH]
```

Four paths, all explicit with no baked-in default, so the fixture of S4 supplies its own and
satisfies A-6 (fixtures are self-built and depend on no work folder's contents). There is **no
`--vocabulary` flag**: `COVERAGE_BEARING` is a compile-time constant inside
`coverage-predicate.mjs`, kept in lockstep with the reviewable subset by feature-007's GV04, so
passing the vocabulary in at run time would create a second way for the two to disagree.

**No marker file, and no other new file.** The earlier `canonical/aid/templates/knowledge-graph/package.json`
requirement is withdrawn with the module repoint (D6) — `.mjs` needs none.

#### L3 — Shared-contract amendments

Two project-wide contracts gain content. Both live in `canonical/aid/templates/`, so both require a
full generator run afterwards (feature-012's obligation, `.aid/knowledge/tech-debt.md` Gotchas —
"Render-drift needs the FULL generator").

| File | Amendment |
|---|---|
| `canonical/aid/templates/reviewer-ledger-schema.md` | Two rows in the "File: location" scope table — `/aid-graph` own-artifact validators → `graph.md`, and `/aid-graph` KB-gap findings → `graph-kb-gaps.md`. Plus a named retention exception in "Lifecycle (per skill invocation)" covering `graph-kb-gaps.md` (D7). |
| `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | The `kb_gaps:` generator-written field, in the same class as `generator:` and `approved_at_commit:`, with its shape and its sole producer named. |

Neither amendment changes any existing rule, so no existing ledger or KB doc is invalidated.

#### L4 — Tests

`tests/canonical/test-graph-gap-ledger.sh`, discovered automatically by the glob
`tests/canonical/test-*.sh` — `.aid/knowledge/test-landscape.md` states adding a suite needs no edit
to `tests/run-all.sh`. It builds its own fixture tree under `mktemp -d` in the style of
`tests/canonical/test-guardrails-d012.sh` (which writes its own compliant `kb.html` inline), so A-6
holds and nothing depends on `.aid/works/work-005-knowledge-graph/`.

| ID | Assertion |
|---|---|
| GL01 | A node with a `COVERAGE_BEARING` edge to a `kb:` id produces **no** row, at any `Provenance` value including `inferred` (D2, F3) |
| GL02 | A node covered only through an ancestor path produces **no** row (F2) |
| GL03 | **The F4 invariant holds at the seam:** every id in feature-004's fixture inventory carries `evidence_provenance` of `declared` or `derived`, and no `int:` id present in `candidates.tsv` appears in the ledger. This asserts the invariant this feature depends on rather than a filter it applies — it goes red if feature-004's guarantee is ever weakened (D3 F4) |
| GL04 | An uncovered entry-point node yields `[HIGH]`; depended-upon yields `[MEDIUM]`; named-unit-only yields `[LOW]`; a node satisfying two clauses takes the higher (D4) |
| GL05 | The emitted file is exactly one seven-column table — no frontmatter, no heading, no summary section (C-6, and the schema's anti-`## Summary` rule) |
| GL06 | Every `Line` cell is `—` and every `Doc` cell is a repo-relative path that exists in the fixture (D5, AC-16) |
| GL07 | **FR-25:** a fixture with many gaps yields a non-empty ledger and exit status 0 (S4, AC-14) |
| GL08 | `grade.sh` over `graph.md` returns `A+` while `graph-kb-gaps.md` holds `[HIGH]` rows — proving the gap rows are invisible to the gate (S1) |
| GL09 | **AC-15:** the `kb_gaps` id list, the ledger `Doc` column, and an in-test call to `detectKbGaps` over the fixture's **full node inventory** plus its table are the same set; and `kbUnbacked` ids from that same fixture appear in **neither** `kb_gaps` nor the ledger (D6, the lens-only scope) |
| GL12 | The shared module loads under Node with no marker file — `import { detectKbGaps, kbUnbacked, COVERAGE_BEARING } from '../graph/coverage-predicate.mjs'` succeeds from the detector's own directory, and `canonical/aid/scripts/graph/` contains **no** `package.json` (D6) |
| GL13 | **The zero-row case, closed:** a fixture whose inventory contains an enumerated `int:` node appearing in **no** table row yields a ledger row for it with the correct severity from its clause, a `kb_gaps` entry carrying both `id` and `name`, and a `Description` ending `; no relationships in the table` (D2, D5). Removing the node from `nodes.tsv` — leaving the table untouched — makes the row disappear, proving the candidate set is the inventory and not the table |
| GL10 | Re-running against a previous ledger moves a now-covered row to `Fixed` and a re-broken row to `Recurred`, and renumbers nothing (D5) |
| GL11 | `grade.sh` over a ledger whose rows are all `Fixed` returns `A+`, confirming the Status enum is being written in the form `grade.sh` counts |

GL08 and GL11 are the two assertions that would fail if a future change filtered by row instead of
by file, or wrote a Status value outside the schema's enum.

### Migration Plan

Nothing existing changes shape; two shared contracts gain content and one KB doc gains a row.

| Step | Change | Verification |
|---|---|---|
| 1 | Add `detect-kb-gaps.mjs` to the `graph/` script area, beside feature-007's `coverage-predicate.mjs` (L2). No marker file and no other new file. | `bash tests/canonical/test-graph-gap-ledger.sh` |
| 2 | Amend `reviewer-ledger-schema.md` and `frontmatter-schema.md` (L3) | `bash tests/canonical/test-grade.sh` still passes — the amendments add scopes and a field, and change no parsing rule |
| 3 | Add a `graph/` row to `.aid/knowledge/module-map.md` "Script Modules by Area" at ship time | The doc's own review gate |
| 4 | Run the FULL profile generator, then confirm no render drift | `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/` |

Step 3 is **feature-013's** ship-time Knowledge Base update and step 4 is **feature-012's** render
mechanism (both were feature-011's before its three-way split); they are listed here because steps 1
and 2 are not complete without them.

**Deliberately left open.** The membership of `COVERAGE_BEARING` (D2 condition 3) cannot be
enumerated until feature-001's relation-vocabulary research lands (D-1). This SPEC fixes the
*contract* — a named, enumerated subset stored beside the vocabulary, selected by this feature,
consumed only by condition 3 of the shared predicate — so that `/aid-detail` can schedule the work.
The member list is filled in by the task that authors `coverage-predicate.mjs` (feature-007's file),
after D-1 closes; this feature supplies the selection, feature-007's GV04 binds the two copies.

**Coordination obligations on feature-007, stated so they are scheduled and not discovered.** Both
land inside `coverage-predicate.mjs`, which feature-007 owns, so `/aid-detail` must produce **one**
task for that file, dependent on both features, rather than two tasks editing the same lines.

| # | Obligation | Status |
|---|---|---|
| 1 | The predicate's three conditions and the `COVERAGE_BEARING` selection are this feature's semantics, authored into feature-007's module | Already reflected in feature-007's SPEC, which adopts them verbatim |
| 2 | `recordedGaps` widens from `{id, severity, clause}` to `{id, name, severity, clause}`, and orphan materialisation reads `name` for the isolated node's label rather than deriving it from the id (D6) | **New with this revision** — additive, and the only contract this feature's zero-row closure moves |

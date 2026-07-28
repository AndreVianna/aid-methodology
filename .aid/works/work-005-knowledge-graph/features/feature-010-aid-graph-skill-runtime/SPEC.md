# /aid-graph Skill Runtime And Quality Gate

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.5 (FR-7–FR-11), §5.9 (FR-28), §7 (C-5), §9 (AC-11–AC-13) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Final-gate finding fixed — render.py's `skills` branch description completed to include the verbatim `scripts/` copy (line 594, is_dir-guarded); noted as unexercised today | /aid-specify |
| 2026-07-28 | `generator` frontmatter value reconciled with feature-003 — `build-relationships.sh` (script name, per the `build-kb-index.sh` precedent), not `aid-graph` | /aid-specify |
| 2026-07-28 | Finding 3 [HIGH] fixed — D4's weighted-points/percentage rubric removed and the gate re-specified purely in `grade.sh`'s worst-severity-dominates terms. Finding 5 [MEDIUM] fixed — `V-T` now covers T1–T4 with T4 assigned its own severity. Validator invocation corrected to match feature-011's revised D3 (validators unmodified by default; NM fully enforced) | /aid-specify |
| 2026-07-28 | Reference fix only, following the owner's feature-006 corrections: the `graph/` script-area inventory now names feature-007's `coverage-predicate.mjs` alongside feature-006's `detect-kb-gaps.mjs`. No decision in this SPEC changes | /aid-specify |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the ownership seam now names **feature-012** (render, manifests, count surfaces, `## References`, `README.md`) and **feature-013** (documentation, registration suite, ship gate) where it previously said feature-011, which retains only the validator reuse and its two contingent suites. The Dependency-position paragraph is repointed the same way. No decision in this SPEC changes | /aid-specify |
| 2026-07-28 | The `/aid-summarize` Node-floor mismatch P5 worked around is **fixed on this branch** (preflight and `state-preflight.md` now assert ≥ 20). P5's rationale and the Migration Plan row are restated accordingly; the approval-grep workaround is unaffected | /aid-specify |

## Source

- REQUIREMENTS.md §5.5 (FR-7 skill name and placement, FR-8 approved-Knowledge-Base preflight,
  FR-9 artifact output paths, FR-10 read-only with respect to Knowledge Base content, FR-11
  idempotence with a wider staleness input set and a reset flag)
- REQUIREMENTS.md §5.9 (FR-28 — the skill's own quality gate covers its own artifacts only, never
  the Knowledge Base's completeness) and its Rationale paragraph
- REQUIREMENTS.md §5.9 Decision paragraph (separate skill, shared scripts — the grading model
  differs from the Knowledge Base summary's, which is part of why this is its own skill)
- REQUIREMENTS.md §7 Constraints — **C-5** (runtime version floor at preflight; feature-011 owns
  the graceful degradation of browser-backed validation)
- REQUIREMENTS.md §8 (A-2 the Knowledge Base is complete and approved before this runs; A-4 the
  graph filename is assumed from the skill name)
- REQUIREMENTS.md §9 (AC-11, AC-12, AC-13)

**Dependency position.** This feature spans the whole work. It invokes feature-004 and
feature-005, writes the artifacts feature-003 and feature-007 define, and runs the quality gate
over all of them. It depends on feature-012 for the canonical script area its own scripts live in
and for the render that ships them, and on feature-011 for the reused summarize validators it
calls. It should be specified early and closed last.

**Gate ownership.** FR-28's checks are implemented in the features that produce each artifact —
feature-003 for the data checks, feature-007 and feature-009 for the view checks — but this feature
owns the **rubric and the gate orchestration**, so that the gate has a single owner rather than
being distributed with no one accountable for its scope.

## Description

This feature is the skill itself: the thing a user invokes, and the rules governing when it will
and will not run.

`/aid-graph` is a standalone, on-demand skill occupying the same slot in the lifecycle as the
existing Knowledge Base summary skill — a sibling of it, not a phase of it, and never triggered
automatically by discovery. A user asks for it when they want it.

Before doing anything, it checks that the Knowledge Base is finished and approved. It does not run
mid-discovery, because a graph built from a half-written Knowledge Base would report gaps that are
simply work in progress, and the report would be worthless. If the Knowledge Base is not approved,
the skill refuses with a message that says what to do about it.

Both artifacts land alongside the existing Knowledge Base summary, in the Knowledge Base folder.

The skill reads widely and writes narrowly. It reads the Knowledge Base, the project source, and
the external-sources file; it writes only its own two artifacts and its own findings ledger. It
never edits the Knowledge Base. That one-way relationship is what makes the tool trustworthy as an
observer: it cannot alter the thing it is reporting on.

Running it twice on an unchanged project does nothing the second time. Because it draws on more
than the Knowledge Base — the source and the external-sources file matter too — its notion of
"unchanged" is correspondingly wider than the summary skill's. A reset flag forces regeneration
when a user wants it regardless.

Finally, the skill grades its own output and only its own output. It checks that identifiers
resolve, that relation pairs are consistent, that provenance is populated, and that the view is
valid — and it never grades the Knowledge Base's completeness. Grading completeness would fail the
skill for reasons outside its control and would reward under-reporting, which is exactly what the
gap signal cannot afford.

## User Stories

- As a **maintainer/architect**, I want to invoke the graph when I want it rather than have it fire
  during discovery, so that it does not interrupt work or produce reports from an unfinished
  Knowledge Base.
- As a **maintainer/architect**, I want a clear, actionable refusal when the Knowledge Base is not
  yet approved, so that I know what to do instead of guessing why nothing happened.
- As the **AID methodology owner**, I want a guarantee that no run modifies the Knowledge Base, so
  that the tool can be trusted as an observer of it.
- As a **maintainer/architect**, I want re-running on an unchanged project to do nothing, and a
  reset flag when I want to force a rebuild, so that the skill is cheap to invoke habitually.
- As the **AID methodology owner**, I want the skill graded on its own artifacts only, so that its
  pass or fail says something about the tool rather than about the Knowledge Base.

## Priority

Must

## Acceptance Criteria

- [ ] AC-11: Given a project whose Knowledge Base is absent or not approved, when `/aid-graph` is
      invoked, then preflight refuses to run and reports an actionable message naming what the user
      must do.
- [ ] AC-12: Given an unchanged Knowledge Base, project source, and external-sources file, when
      `/aid-graph` is re-run, then the run is a no-op; and when it is run with the reset flag, then
      it regenerates regardless.
- [ ] AC-13: Given any run of `/aid-graph`, when the Knowledge Base files are compared before and
      after, then none has been modified.
- [ ] Given a successful run, when the output locations are checked, then both artifacts are
      present in the Knowledge Base folder alongside the existing summary.
- [ ] Given the skill's placement in the lifecycle, when discovery runs, then `/aid-graph` is not
      triggered automatically — it is on-demand only.
- [ ] Given a change to the project source or the external-sources file with the Knowledge Base
      itself unchanged, when `/aid-graph` is re-run, then the staleness check treats the project as
      changed and regenerates — proving the input set is wider than the summary skill's.
- [ ] Given a completed run, when the quality gate is applied, then it scores identifier
      resolvability, inverse-pair consistency, provenance population, and view validity, and scores
      nothing about the Knowledge Base's completeness.
- [ ] Given a run on a project with an unmet runtime version floor, when preflight executes, then
      it reports the requirement rather than failing obscurely later.

---

## Technical Specification

> Modelled on `/aid-summarize`, read in full: `canonical/skills/aid-summarize/SKILL.md` and its ten
> `references/state-*.md` files, plus `canonical/aid/scripts/summarize/` (`summarize-preflight.sh`,
> `stale-check.sh`, `grade-summary.sh`, `validate-html-output.sh`, `validate-visuals.mjs`,
> `manual-checklist.sh`, `writeback-state.sh`, `assemble.sh`, `package.json`). Governed by
> `.claude/aid/templates/state-machine-chaining.md`, `.aid/knowledge/quality-gates.md`
> (Minimum-Grade Thresholds), `.aid/knowledge/coding-standards.md` (Exit Codes, Configuration
> Access, Security Conventions), and `.aid/knowledge/authoring-conventions.md` (Prose Over Scripts).

### Data Model

#### D1 — Arguments

Following the existing convention (a `## Arguments` table in `SKILL.md` plus an `argument-hint:`
frontmatter string, as in `canonical/skills/aid-summarize/SKILL.md` and
`canonical/skills/aid-housekeep/SKILL.md`):

| Argument | Effect |
|---|---|
| *(none)* | Full run: `PREFLIGHT → STALE-CHECK → …`, no-op when nothing changed (AC-12) |
| `--reset` | Forces regeneration regardless of the staleness verdict. Implemented by discarding the recomputed-digest comparison, **not** by deleting the artifacts — the previous `graph-kb-gaps.md` must survive so the `Fixed` / `Recurred` transitions of feature-006 still work. |
| `--grade X` | Overrides the minimum acceptable grade. Format `[A-F][+-]?`, validated against that pattern exactly as `canonical/aid/scripts/summarize/writeback-state.sh` validates its `GRADE` argument. When passed, persisted to `.aid/settings.yml` `graph.minimum_grade` via `/aid-config`, mirroring `/aid-summarize`'s `--grade` row. |

Without `--grade`, the floor is resolved by the project's single resolver — never by parsing
`.aid/settings.yml` directly (`.aid/knowledge/coding-standards.md` Configuration Access):

```bash
bash canonical/aid/scripts/config/read-setting.sh --skill graph --key minimum_grade --default A
```

In this repository that resolves to `A+`, because `.aid/settings.yml` carries a top-level
`minimum_grade: A+` and `read-setting.sh`'s skill mode falls through per-skill override → flat
top-level key → legacy `review.<key>` → `--default`.

**`--table-only` is deliberately not added.** During the §10 delivery sequence the view simply does
not exist yet, so RENDER is absent rather than skipped by a flag; adding one now would be scope
invented ahead of a demonstrated need.

#### D2 — The staleness record: content-addressed, carried inside the artifacts

`/aid-summarize` compares two **dates** read from `.aid/knowledge/STATE.md` (`stale-check.sh` reads
`## Review History` against `## Summarization History`). `/aid-graph` cannot use that mechanism:
AC-13 forbids modifying any KB file, so there is nowhere in `.aid/knowledge/STATE.md` for it to
stamp a last-run date. It also should not — a date comparison cannot see a source-tree change, and
FR-11 requires exactly that.

So staleness is **content-addressed**, and the record lives inside the two artifacts the skill
already owns. No new state file is introduced.

| Field | Home | Value |
|---|---|---|
| `graph_inputs_digest` | `relationships.md` frontmatter (generator-written) | The composite digest below |
| `graph_generated_at` | `relationships.md` frontmatter | UTC timestamp, informational |
| `generator` | `relationships.md` frontmatter | `build-relationships.sh` — the **script name**, not the skill name. Reconciled with feature-003 (which owns the frontmatter contract) 2026-07-28: `.aid/knowledge/INDEX.md` carries `generator: build-kb-index.sh`, so the established precedent is the generating script. Required alongside `source: generated` per `.aid/knowledge/authoring-conventions.md` Frontmatter Rules and `canonical/aid/templates/kb-authoring/frontmatter-schema.md` |
| The same digest | `graph.html`, as `<!-- aid-graph inputs-digest: <hex> -->` | So the view's currency is checkable without parsing the table |

The composite digest is a SHA-256 over three sorted component lists, joined in fixed order. Order is
fixed and the lists are sorted so the digest is byte-stable across runs and platforms — the same
determinism argument `canonical/EMISSION-MANIFEST.md` makes for sorting its records by `dst`.

| Component | Covers | Composed from |
|---|---|---|
| `KB` | The Knowledge Base (FR-11 input 1) | `path + sha256` for every `.aid/knowledge/*.md` at depth 1, **excluding the paths on the write-allowlist of D3**, sorted by path |
| `SRC` | The project source (FR-11 input 2) | `path + sha256` for every artifact in feature-004's enumerated node set, sorted by path |
| `EXT` | The external-sources file (FR-11 input 3) | `sha256` of `.aid/knowledge/external-sources.md` |

**Why this is cheap, and why it forces one ordering decision.** `SRC` hashes the enumerated node set,
not the repository. FR-22 already excludes the five rendered `profiles/` trees, the dogfood
`.claude/` tree, `packages/*/_vendor/`, and anything ignore-listed — which is where nearly all of
this repository's file mass sits (`.aid/knowledge/tech-debt.md` Duplication records the toolkit
appearing in five profiles plus `.claude/`). What remains is the canonical tree plus `bin/`, `lib/`,
`dashboard/`, `tests/`, and `site/` at whole-artifact granularity (FR-23), which A-5 puts in the
hundreds. The digest is a hash pass over feature-004's already-produced node list, not a second
traversal.

The consequence is that **ENUMERATE must run before STALE-CHECK**, not after it: you cannot know the
source is unchanged without looking at the source, and a newly added artifact is invisible to any
stored path list. The state machine is ordered accordingly. Enumeration is the cheap, deterministic,
write-free half of the pipeline; what a `CURRENT` verdict actually saves is the expensive half — the
two-pass extraction with its bounded agent step (FR-31) and the render — so the no-op is a genuine
no-op in every sense that matters: no write, no agent invocation, no artifact churn.

**Two composition decisions are recorded explicitly, so a later change is a visible decision rather
than a drift:**

- **`INDEX.md` is *included* in `KB`, and the consequence is accepted.** The first run writes
  `relationships.md`; when the KB's owner later regenerates `INDEX.md` (per
  `canonical/aid/templates/generated-files.txt`, whose build command for
  `.aid/knowledge/INDEX.md` is `build-kb-index.sh`), the index gains a `relationships.md` row and
  `KB` changes, so the next `/aid-graph` run regenerates once. That is correct — `INDEX.md` is the
  routing table agents actually read, so a change to it is a real KB change. Excluding it to avoid
  one extra run would blind the check to genuine index changes. The extra run is bounded to one and
  is documented in the skill's failure-modes table.
- **The skill's own scripts and the relation vocabulary are not separate components.** The
  vocabulary artifact (feature-001) and the `graph/` script area both live inside the canonical tree
  and are enumerated by feature-004 wherever they qualify under FR-21, so they are already inside
  `SRC`. Adding a fourth `TOOL` component would double-count them and would exceed FR-11's declared
  input set. A change the digest genuinely cannot see is handled by `--reset`.

#### D3 — The write allowlist (the FR-10 / AC-13 enforcement data)

Exactly five path patterns are writable. Everything else — most importantly every other file under
`.aid/knowledge/` — is read-only for the entire run.

| # | Path | Owner feature |
|---|---|---|
| W1 | `.aid/knowledge/relationships.md` | feature-003 (schema), feature-006 (`kb_gaps`), this feature (digest fields) |
| W2 | `.aid/knowledge/graph.html` | feature-007/008/009 |
| W3 | `.aid/knowledge/graph-assets/**` — companion assets, only if FR-18's packaging produces any | feature-007 |
| W4 | `.aid/.temp/review-pending/graph.md` and `.aid/.temp/review-pending/graph-kb-gaps.md` | this feature / feature-006 |
| W5 | `.aid/.temp/graph/**` — scratch (assembly sources, the visual-gate answer file) | this feature |

W3's directory name matters: `canonical/aid/scripts/kb/build-kb-index.sh` selects index rows with
`find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*'`, so a **subdirectory** is invisible to
it regardless of name, and `graph.html` is invisible because it is not `*.md`. FR-9's requirement
that companion assets not be mistaken for KB documents is therefore satisfied by one concrete rule:
**no companion asset may be a `*.md` file sitting directly in `.aid/knowledge/`.**

#### D4 — The FR-28 rubric (own artifacts only)

**The grading algorithm is `canonical/aid/scripts/grade.sh`, unmodified, and this rubric is
expressed purely in its terms.** `grade.sh` is not a weighted-points model: it parses the Severity
and Status columns of a seven-column ledger, counts only rows whose Status is `Pending` or
`Recurred`, and applies *worst severity dominates, count determines the modifier* — zero rows `A+`;
otherwise `E`/`D`/`C`/`B` banded by the worst severity present, with `+` for exactly one row of that
severity, no modifier for two to five, and `-` for more than five. There is no maximum, no
percentage, and no weight anywhere in it.

The rubric is therefore a **check → severity** mapping plus a rule for how many rows a failure
emits. Nothing else is needed, and specifying anything else would describe an algorithm the skill
does not run.

`grade-summary.sh`'s `AUTO_POOL` shape is deliberately **not** copied. Beyond the points mismatch,
its pool is centred on `COV` — `kb.html`'s coverage of `discovery.doc_set` — which has no analogue
here and whose import would be exactly the KB-completeness grading FR-28 forbids.

| ID | Check | Asserts | Severity on failure | One row per | Implemented by |
|---|---|---|---|---|---|
| `R1` | Id resolvability | Every `Source Id` / `Target Id` resolves: `kb:` to an existing KB doc and heading, `int:` to an existing repo-relative path, `ext:` to an entry in the external-sources file (AC-1) | `[HIGH]` | unresolvable id | feature-003 |
| `R2` | Inverse-pair consistency | Every row's `S2T Relation` / `T2S Relation` is a valid inverse pair from the closed vocabulary and the two directions do not disagree (AC-2) | `[HIGH]` | offending table row | feature-003 |
| `R3` | No duplicate relationship | No relationship appears twice, once forward and once inverse (AC-3) | `[MEDIUM]` | duplicate pair | feature-003 |
| `R4` | Provenance population | Every row carries `declared`, `derived`, or `inferred` (AC-4) | `[HIGH]` | offending table row | feature-003 |
| `R5` | Frontmatter validity | `relationships.md` passes `canonical/aid/scripts/kb/lint-frontmatter.sh` (C-7, AC-18) | `[HIGH]` | `[FM-MISSING]` / `[FM-INVALID]` finding, matching `lint-frontmatter.sh`'s own HIGH classification | feature-003 |
| `V-H1` | HTML validity | `validate-html-output.sh` H1 | `[HIGH]` | reported error | feature-007 |
| `V-A` | Accessibility baseline | `validate-html-output.sh` A1–A5 (NFR-1, AC-9) | `[MEDIUM]` | failing sub-check | feature-007/009 |
| `V-L` | Link resolution | `validate-html-output.sh` L1 (anchor `href="#X"` resolves to `id="X"`) and L2 (relative `./X.md` exists in `--kb-dir`) | `[HIGH]` | broken anchor or link | feature-007 |
| `V-C` | Contrast, both themes | `contrast-check.mjs` (AC-9) | `[MEDIUM]` | failing colour pair | feature-007 |
| `V-S2` | Offline render | `validate-html-output.sh` S2 — no `<script src="http…">` and no `<link href="http…">` | `[HIGH]` | offending external reference | feature-011 |
| `V-NM` | No-Mermaid-engine | `validate-html-output.sh` NM — **all three sub-checks, in force** (NM.1 inline bundle > 100 KB containing `mermaid` in a non-`text/markdown` script; NM.2 `mermaid.initialize(`; NM.3 CDN `<script src>` whose URL contains `mermaid`) | `[HIGH]` | failing sub-check | feature-011 |
| `V-T` | Visual fidelity | `validate-visuals.mjs` **T1–T4**: T1 rendered font-size ≥ 10 px and not zero-height-clipped; T2 sibling-child overlap ≤ 20% of the smaller area; T3 non-trivial bounding rect; T4 no horizontal overflow of its own container at the 732 px and 390 px viewports | T1, T3, T4 → `[HIGH]`; **T2 → `[MEDIUM]`** | failing check, per visual | feature-008 |

**Why T2 alone is `[MEDIUM]`.** T1, T3 and T4 each mean content is *not available* — text too small
to read, a collapsed visual, or a region clipped off the side at a supported width. T2 means content
is present but crowded. The split also keeps the severity honest against feature-011's finding that
T2 is the one check that collides with an SVG graph surface *by design*: where the collision is
handled by a scoped exclusion, the residual T2 signal covers authored visuals only, and over-ranking
it would let a legend's minor overlap outrank a clipped table.

**What the resulting grade means, and what the severities actually buy.** Every failed check becomes
`Pending` rows in `.aid/.temp/review-pending/graph.md`; passed checks add no row, per
`state-validate.md`'s "no row = no finding" rule. `grade.sh` then yields `A+` if and only if the file
holds no `Pending` or `Recurred` row. Because the resolved floor in this repository is `A+` (D1),
**any** finding at any severity drops the Machine Grade below the floor and routes to FIX. So the
severity column does not decide pass or fail here; it decides *band and repair order* — it tells the
FIX state which rows to take first, and it is what makes the grade meaningful for a project that
configures a lower floor (a single `[MEDIUM]`-only run grades `C+`, a single `[HIGH]`-only run
grades `D+`).

**No check emits `[CRITICAL]` or `[MINOR]`.** `[CRITICAL]` is reserved by
`canonical/aid/templates/reviewer-ledger-schema.md` for findings that will mislead downstream phases
or break tooling; every failure above is a defect in an artifact this same run is about to repair in
FIX, and none of them escapes the run. `[MINOR]` is excluded from the other side: a validator that
fired found a real defect, so nothing here is cosmetic. Fixing the range at three values keeps the
mapping auditable — a reviewer can check every row of the table against the enum.

**What is *not* in the rubric, and why the omission is structural.** There is no check whose subject
is the Knowledge Base. The gap count lives in a different ledger file that no grading state ever
passes to `grade.sh` (feature-006 §D7), so the gate is not merely instructed to ignore gaps — it
cannot reach them. The two features' outputs cannot be conflated because they are not the same file.

**Gate ownership.** Per this SPEC's Gate ownership note, each check's *implementation* belongs to
the feature that produces the artifact; this feature owns the table above, its severity assignments,
and the orchestration that runs it, so the rubric has a single accountable owner.

**When only the table exists** (the §10 delivery-2 state, before any view ships), the `V-*` checks
are not run and therefore emit no rows. Under `grade.sh` that needs no special mechanism at all —
absent rows are absent rows — which is a further reason the severity model is the right one for this
artifact: the rubric shrinks without any maximum needing to be recomputed.

#### D5 — The two-grade question: where a human gate is and is not appropriate

`/aid-summarize` runs a two-grade gate (Machine + Human, `min` of the two, `V1` mandatory). Whether
that is right here differs **per artifact**, and REQUIREMENTS.md §5.9's Decision paragraph already
says why: `relationships.md` "grades as *data*", while `kb.html` "grades on visual fidelity behind a
mandatory human visual gate".

| Artifact | Human grade? | Reasoning |
|---|---|---|
| `relationships.md` | **No** | Every property that matters is decidable: an id either resolves or does not, a pair either inverts or does not, a provenance value is either in the enum or not. There is no judgment left to elicit, so a human pool here would be ceremony that invites rubber-stamping. `/aid-summarize`'s `K1` (doc-set completeness) and `K2` (fact grounding) have **no analogue** — `K1`'s subject is KB completeness, which FR-28 forbids grading, and `K2`'s subject is prose faithfulness, which a machine-checkable relation table does not have. |
| `graph.html` | **Yes — one mandatory check** | Whether a force-directed layout at this project's node counts is *legible* is not machine-decidable. `validate-visuals.mjs` checks that visuals render (readable font size, bounded overlap, non-zero dimensions, no horizontal clipping at 732/390 px — T1–T4); it cannot judge whether the picture is comprehensible. Two independent rules already bind this: `.aid/knowledge/tech-debt.md` Gotchas — "Web-output reviews require Playwright: reviewing `kb.html` or the site by reading HTML/CSS is not a valid review", and `.aid/knowledge/test-landscape.md` Known Test Gaps — "Source inspection is not a valid review of rendered pages". |

So the gate is **one machine pool plus a single human check**, not `/aid-summarize`'s three:

- **`G1` — human visual gate (mandatory, 100% of the human pool).** A `G1` fail forces the Human
  Grade to `F`, exactly as `grade-summary.sh` forces `HUMAN_GRADE="F"` when `MANUAL_V1` is 0. `G1`
  asks one question: opened in a real browser, is the graph legible and usable — nodes and labels
  readable at default zoom, the four lenses each visibly changing the view, keyboard zoom and pan
  working (NFR-6), reduced-motion yielding a settled graph (NFR-4)?
- Overall Grade = `min(Machine, Human)`, the same composition `grade-summary.sh` uses.
- When `graph.html` is not in scope for the run, the human pool is **N/A** and
  Overall Grade = Machine Grade. This is the honest form of "no human gate on the table".

`spot-check-facts.sh` is deliberately **not** reused. It greps HTML claims against source KB prose to
help a human answer `K2`; with no `K2` there is nothing for it to support.

### State Machines

Eleven states. `/aid-summarize` has ten; the shape is the same and the differences are all traceable
to a requirement.

```
aid-graph  ▸ state machine
  [ PREFLIGHT ] → [ ENUMERATE ] → [ STALE-CHECK ] → [ EXTRACT ] → [ EMIT ]
    → [ GAP-REPORT ] → [ RENDER ] → [ VALIDATE ] → [ VISUAL-GATE ] → [ DONE ]
                                        ↑                 │
                                        └──── [ FIX ] ←───┘
```

| State | Reference doc | Body owned by | Advance |
|---|---|---|---|
| PREFLIGHT | `references/state-preflight.md` | this feature | CHAIN → ENUMERATE; aborts the run on failure |
| ENUMERATE | `references/state-enumerate.md` | feature-004 | CHAIN → STALE-CHECK |
| STALE-CHECK | `references/state-stale-check.md` | this feature | CHAIN → EXTRACT when `STALE` / `FIRST_RUN`; CHAIN → DONE (idempotent variant) when `CURRENT` |
| EXTRACT | `references/state-extract.md` | feature-005 | CHAIN → EMIT |
| EMIT | `references/state-emit.md` | feature-003 | CHAIN → GAP-REPORT |
| GAP-REPORT | `references/state-gap-report.md` | feature-006 | CHAIN → RENDER (single unconditional branch — feature-006 §S3) |
| RENDER | `references/state-render.md` | feature-007 | CHAIN → VALIDATE |
| VALIDATE | `references/state-validate.md` | this feature | CHAIN → VISUAL-GATE when Machine Grade ≥ minimum; CHAIN → FIX otherwise |
| VISUAL-GATE | `references/state-visual-gate.md` | this feature | CHAIN → DONE when `G1` passes and Overall Grade ≥ minimum; CHAIN → FIX otherwise |
| FIX | `references/state-fix.md` | this feature | CHAIN → VALIDATE |
| DONE | `references/state-done.md` | this feature | HALT |

Every transition is CHAIN or HALT — none is `PAUSE-FOR-USER-ACTION` or `-DECISION`. This is required
by `.claude/aid/templates/state-machine-chaining.md`, whose anti-patterns section states that a pause
is legitimate only when the user must do work outside the chat, and that a question belongs in an
inline `AskUserQuestion`. `G1` is such a question, so VISUAL-GATE chains.

**Four differences from `/aid-summarize`, each traceable to a requirement:**

1. **No PROFILE state.** `/aid-summarize` needs one to resolve `discovery.doc_set` into an ordered
   section manifest. The graph's section set is the relationship table; there is nothing to profile.
2. **No APPROVAL and no WRITEBACK state.** Both of `/aid-summarize`'s exist to record an approval
   scalar and a history row in `.aid/knowledge/STATE.md` (`state-approval.md` writes
   `summary_approved`; `state-writeback.md` appends to `## Summarization History`). AC-13 forbids
   `/aid-graph` from writing any KB file, so neither state can exist here. The consequence is
   deliberate and beneficial: because currency is content-addressed rather than
   approval-addressed (D2), STALE-CHECK has **no `CURRENT_UNAPPROVED` branch** — the third verdict
   `stale-check.sh` emits has no counterpart. A re-run on an unchanged project is a true no-op
   (AC-12) rather than a re-request for sign-off.
3. **VISUAL-GATE replaces MANUAL-CHECKLIST**, carrying one check instead of three (D5).
4. **STALE-CHECK runs third, not second.** `/aid-summarize` can decide staleness from two dates
   before doing any work. FR-11's wider input set makes that impossible: the `SRC` component of the
   digest is defined over the enumerated node set, and a newly added artifact cannot be seen without
   enumerating (D2). ENUMERATE therefore runs first — it is write-free and deterministic — and
   STALE-CHECK's `CURRENT` verdict short-circuits the expensive remainder: the two-pass extraction
   with its bounded agent step and the render.

#### PREFLIGHT

Runs `canonical/aid/scripts/graph/graph-preflight.sh` before any state, following
`summarize-preflight.sh`'s shape (an `err()` helper printing a cause line plus an actionable `→`
line, then `exit 1`).

| # | Check | Failure message names |
|---|---|---|
| P1 | `.aid/knowledge/STATE.md` exists | run `/aid-config` then `/aid-discover` |
| P2 | **The KB is approved (FR-8).** Read the frontmatter scalar `kb_status` from the leading YAML block; `Approved` passes. Fall back, only when that key is absent, to the blockquoted metadata line `> **User Approved:** yes` **scoped to the region above the first `##` heading**. | run `/aid-discover` to APPROVAL and approve the KB (AC-11) |
| P3 | At least one populated KB document exists — a `.aid/knowledge/*.md` other than `STATE.md` / `README.md` / `INDEX.md` with more than 30 non-blank lines and no `^❌ Pending` marker | run `/aid-discover` to populate the KB |
| P4 | Not in Plan Mode (`CLAUDE_PLAN_MODE` is not `1`); the run writes files | exit Plan Mode and re-run |
| P5 | **Node.js ≥ 20 (C-5).** | install or upgrade Node.js and re-run |
| P6 | `.aid/knowledge/external-sources.md` exists — it is a declared FR-11 staleness input and an AC-1 resolution target | run `/aid-discover` (its ELICIT state authors this file) |

**P2 differs from `summarize-preflight.sh` on purpose, and the difference is a correctness fix.**
`summarize-preflight.sh` matches `^(> *)?\*\*User Approved:\*\* yes` against the whole file. In this
repository `.aid/knowledge/STATE.md` contains that literal **twice** — once in the blockquoted
metadata block (the KB's approval) and once inside `## Knowledge Summary Status` (the *summary's*
approval, written by `/aid-summarize` itself). An unscoped grep therefore passes when the KB is
unapproved but a stale summary approval is recorded. `graph-preflight.sh` reads the machine scalar
`kb_status` first and scopes its legacy fallback, so it cannot make that mistake. The
`/aid-summarize` defect is reported upstream, not fixed here — fixing it changes another skill's
behaviour and is outside this work's scope.

**P5's floor is 20, and it is now the *same* floor `/aid-summarize` asserts.** The rationale is
unchanged — `canonical/aid/scripts/summarize/package.json` declares `engines.node: ">=20"` for the
very validators this skill reuses, and C-5 states the same floor — but the asymmetry an earlier
revision described is gone. The `/aid-summarize` preflight/`package.json` mismatch has been **fixed
on this branch**: `summarize-preflight.sh` Check 5 now guards `-lt 20` and `state-preflight.md`
item 5 matches (feature-011 D7). P5 therefore adopts a floor its sibling already enforces rather
than raising one above it.

#### STALE-CHECK

Runs after ENUMERATE, because the `SRC` digest component is defined over the enumerated node set
(D2). Invokes `canonical/aid/scripts/graph/graph-stale-check.sh`, which prints one verdict as its
last stdout line and — following `stale-check.sh`'s header contract, "Exit 0 always (the 'decision'
is informational, not a failure)" — always exits 0.

| Verdict | Condition | Route |
|---|---|---|
| `FIRST_RUN` | `relationships.md` absent, or present with no `graph_inputs_digest` | EXTRACT |
| `STALE` | Recomputed digest ≠ the stored digest, **or** `graph.html` is expected for this build and its embedded digest differs from `relationships.md`'s | EXTRACT |
| `CURRENT` | Both artifacts present and both digests equal the recomputed digest | DONE (idempotent) |

`--reset` bypasses the comparison and forces `STALE`. The state prints *why* it is regenerating —
which of `KB` / `SRC` / `EXT` changed — so a user is told the reason rather than shown a bare verdict,
matching `state-stale-check.md`'s "tell the user *why* it's stale" instruction. This is also the
mechanism behind the acceptance criterion that a source-only change (KB unchanged) must still
regenerate: `SRC` changes while `KB` does not, and the composite digest changes.

#### VALIDATE

1. Run `canonical/aid/scripts/graph/grade-graph.sh .aid/knowledge/relationships.md
   [.aid/knowledge/graph.html]`, which orchestrates the D4 rubric by invoking the **existing**
   leaf validators — `validate-html-output.sh`, `contrast-check.mjs`, `validate-visuals.mjs` — plus
   the `R*` data checks. It duplicates no assembler or validator logic (AC-17); feature-011 owns the
   reuse wiring.

   **The validators are invoked unmodified unless feature-011's two contingencies fire.**
   Re-verified against the scripts (feature-011 D3): `graph.html` as specified passes
   `validate-html-output.sh` in full, including all three `NM` sub-checks, because every one of them
   is keyed on the literal token `mermaid` and a non-Mermaid interaction bundle contains none. The
   two contingencies are `--profile graph` for S2 (only if FR-18 selects CDN delivery) and the
   `validate-visuals.mjs` scoped exclusion for T2 (only if feature-002 selects an SVG live surface).
   Neither is assumed here; whichever fires, feature-011 owns it and D4's rows are unchanged.
2. Translate each failed check into a `Pending` row in `.aid/.temp/review-pending/graph.md`, using
   the seven-column schema and the D4 severity assignments. Passed checks add no row — "no row = no
   finding", per `state-validate.md`'s own rule. Row shape and phrasing follow the mapping table
   already in `canonical/skills/aid-summarize/references/state-validate.md` ("Translate Script Output
   to Schema Rows"), so the two skills report comparable failures the same way.
3. Compute the Machine Grade: `bash canonical/aid/scripts/grade.sh --explain
   .aid/.temp/review-pending/graph.md`. No other grade computation exists in this skill — D4 assigns
   severities and `grade.sh` turns them into the letter.

**When Playwright is absent**, `validate-visuals.mjs` prints its `SKIP` and exits 0, so `V-T` emits
no rows and cannot lower the Machine Grade. That is the documented degradation (feature-011 D7), and
its consequence here is that `G1` becomes the sole carrier of visual assurance for that run —
recorded in the closing summary so the grade is not read as stronger evidence than it is.

#### VISUAL-GATE

Skipped as `N/A` when `graph.html` is not in scope. Otherwise:

1. Surface the artifact to the user with its opening instructions and, when the FR-18 packaging
   requires it, the runtime prerequisites AC-6 obliges the artifact to document.
2. Ask `G1` inline via `AskUserQuestion`; require that the user has actually opened it in a browser.
3. Record the answer in `.aid/.temp/graph/visual-gate.json` (transient, allowlist W5). Nothing is
   persisted to `.aid/knowledge/` — AC-13.
4. Recompute the Overall Grade as `min(Machine, Human)`. `G1` fail ⇒ Human `F` ⇒ Overall `F` ⇒ FIX.

Because the answer is transient, `G1` is re-asked on every regeneration. That is correct: a
regenerated view is a different picture, and a stored approval would be an assertion about bytes that
no longer exist.

#### FIX

Splits by failure kind, as `canonical/skills/aid-summarize/references/state-fix.md` does:

- **Machine-pool rows** — objective, one correct repair each. Read the `Pending` / `Recurred` rows of
  `graph.md`, apply the repair, do **not** touch the `Status` column (the next VALIDATE re-verifies;
  the fixer never marks a row `Fixed`).
- **`G1` failure** — subjective. Use the **expose → propose → ask** loop: restate the legibility
  complaint precisely, propose one concrete change (a density default, a label-collision rule, a
  lens preset), and wait for confirmation before editing. Never guess-fix a judgment.

#### DONE

Two variants, as `/aid-summarize`'s composite DONE has:

- **Normal completion** — print the artifact paths and grades, print feature-006's routing block, and
  delete **only** `.aid/.temp/review-pending/graph.md`. `graph-kb-gaps.md` is retained (feature-006
  §D7) and `.aid/.temp/graph/` scratch is removed.
- **Idempotent completion** — print `relationships.md and graph.html are current for this project.
  Nothing to do. Re-run with --reset to force regeneration.` No file is written.

### Feature Flow

The FR-10 / AC-13 guarantee is the load-bearing part of the flow, so it is described as a fence
around the whole run rather than as a promise inside each state.

1. **PREFLIGHT** passes (P1–P6).
2. **Raise the KB write fence.** `canonical/aid/scripts/graph/kb-write-fence.sh --snapshot` walks
   `.aid/knowledge/` and writes `path + sha256` for every file **not** matching the D3 allowlist to
   `.aid/.temp/graph/kb-fence.txt`. This is the same walk that produces the `KB` digest component, so
   the snapshot costs nothing extra.
3. **ENUMERATE** (feature-004) → the significant `int:` node set plus each node's FR-24 qualification
   evidence. Write-free. Call boundary: this feature invokes it and consumes its output; the
   significance rule, the FR-22 exclusions, and the evidence format are feature-004's and are not
   restated here.
4. **STALE-CHECK** computes the D2 digest over that node set plus the KB and external-sources file,
   and decides. `CURRENT` → step 9, then DONE's idempotent variant.
5. **EXTRACT** (feature-005) → the two-pass row set, `declared`/`derived` from the deterministic scan
   and `inferred` from the bounded agent pass. Call boundary: this feature sequences the two passes
   as one state and consumes the row set; the pass mechanics are feature-005's.
6. **EMIT** (feature-003) → writes `.aid/knowledge/relationships.md` (W1): frontmatter, the
   eight-column table, and the `graph_inputs_digest` / `graph_generated_at` fields of D2. Call
   boundary: this feature supplies the digest values; the schema, the frontmatter contract, and the
   `R1`–`R5` checks are feature-003's.
7. **GAP-REPORT** (feature-006) → `kb_gaps` into W1 and the gap ledger into W4. Exits 0 regardless of
   gap count.
8. **RENDER** (feature-007, with feature-008/009) → writes `graph.html` (W2) and any companion assets
   (W3), embedding the same digest.
9. **Lower the fence.** `kb-write-fence.sh --verify` re-walks the same non-allowlisted set and diffs
   against the snapshot. Any added, removed, or changed path is an **FR-10 violation**: the run
   fails with exit 1, naming every offending path, and the closing summary says the artifacts must
   not be trusted. This runs on **every** exit path, including the idempotent one and the failure
   ones, so no route bypasses it.
10. **VALIDATE → VISUAL-GATE → DONE** as the state machine describes.

#### How the read-only guarantee is enforced rather than promised

| # | Mechanism | What it makes impossible |
|---|---|---|
| E1 | **A declared write allowlist** (D3) in `SKILL.md`, checked at review | An undeclared write target reaching implementation unnoticed. Precedent: `.aid/knowledge/coding-standards.md` Security Conventions — "Discovery is read-only on the repo, with one declared exemption … a category guard in the skill pre-flight". |
| E2 | **The pre/post digest fence** (steps 2 and 9) | A write outside the allowlist *succeeding silently*. The fence hashes the complement of the allowlist, so it catches the case an allowlist alone cannot: an accidental `build-kb-index.sh` invocation regenerating `INDEX.md`, or a sub-agent editing a KB doc it was only asked to read. |
| E3 | **`allowed-tools` in `SKILL.md` frontmatter** | Nothing by itself — the tool list cannot express a path scope — but omitting any tool the skill does not need keeps the surface minimal. Listed for completeness, not relied upon. |
| E4 | **A test that tries to violate it** | The guarantee going untested. `tests/canonical/test-graph-read-only.sh` builds a fixture KB, snapshots it, runs the fence's verify against a deliberately mutated KB doc, and asserts a non-zero exit naming that path. The violation path is the tested path. |

E2 is what turns AC-13 from an assertion into a check: AC-13's wording — compare the KB files before
and after — *is* the fence, run by the skill on itself every time rather than only by a reviewer
after the fact.

**Why `INDEX.md` regeneration is not the skill's job.** AC-18 requires that regenerating the KB index
leaves the index and `relationships.md` consistent. It is satisfied by `relationships.md` carrying
valid frontmatter (Q3, C-7) — not by `/aid-graph` running the generator. `INDEX.md` is a registered
generated file whose build command belongs to its owner
(`canonical/aid/templates/generated-files.txt`, consumed by `/aid-discover`'s FIX state). If
`/aid-graph` ran it, step 9's fence would fail by design, which is exactly the signal that the write
belongs elsewhere.

### Layers & Components

The skill and script files are authored under `canonical/` and rendered to all five profile trees plus
the dogfood `.claude/` by the full generator; the test suites live under `tests/canonical/` and are
repository test infrastructure, not rendered. **feature-012** owns the render and the manifest and
count lockstep, **feature-013** owns the documentation surfaces and the ship gate, and
**feature-011** owns the reuse wiring; this feature owns the runtime content.

#### The ownership seam: 010 against 011, 012 and 013

Four features touch this skill. The split is by **file**, and where a file is shared, by **named
section**, so `/aid-detail` cannot produce two tasks editing the same lines.

| File or section | feature-010 (runtime) | Other owner |
|---|---|---|
| `canonical/skills/aid-graph/SKILL.md` — frontmatter (`name`, `description`, `allowed-tools`, `argument-hint`) | **Owns** | — |
| `SKILL.md` — `## Pre-flight Checks`, `## Arguments`, `## State Detection`, `## Dispatch`, `## Quality Gate`, `## Failure modes and recovery` | **Owns** | — |
| `SKILL.md` — `## References` (the list of shared scripts and templates the skill calls) | — | **feature-012** |
| `canonical/skills/aid-graph/README.md` (canonical-only; `render.py`'s `skills` branch emits `SKILL.md`, `references/*.md`, and a verbatim `scripts/` when present — but nothing else, so a `README.md` never ships) | — | **feature-012** |
| `references/state-preflight.md`, `state-stale-check.md`, `state-validate.md`, `state-visual-gate.md`, `state-fix.md`, `state-done.md` | **Owns** | — |
| `references/state-enumerate.md`, `state-extract.md`, `state-emit.md`, `state-gap-report.md`, `state-render.md` | Owns each file's `**Advance:**` line and its Dispatch-table row only | features 003–007 own the bodies |
| `canonical/aid/scripts/graph/graph-preflight.sh`, `graph-stale-check.sh`, `kb-write-fence.sh`, `grade-graph.sh` | **Owns** | — |
| `canonical/aid/scripts/summarize/*` (the reused validators) | Calls them, unmodified by default | **feature-011** owns every edit to them, and owns whether its D3 contingencies (the S2 `--profile` and the T2 exclusion) are triggered at all |
| The canonical→profiles render, the emission manifests, the count surfaces | — | **feature-012** |
| The documentation surfaces and the ship-time Knowledge Base updates | — | **feature-013** |
| `tests/canonical/test-graph-preflight.sh`, `test-graph-stale-check.sh`, `test-graph-read-only.sh` | **Owns** | — |
| `tests/canonical/test-validate-html-profiles.sh`, `test-validate-visuals-profiles.sh` (both contingent) | — | **feature-011** |
| `tests/canonical/test-graph-skill-registration.sh`, the aggregate HOME-pinned gate | — | **feature-013** |
| The doc-count reconcile and the render-drift check | — | **feature-012** |

One-sentence form: **010 owns what the skill does; 011 owns how it borrows; 012 owns how it ships;
013 owns how it is found and how the whole thing is proved finished.**

#### New scripts (this feature)

Four scripts, all in the new `canonical/aid/scripts/graph/` area that this work introduces (two more
land in the same area: feature-006's Node generator `detect-kb-gaps.mjs` and feature-007's shared
`coverage-predicate.mjs`, which it imports). Placed per
`.aid/knowledge/module-map.md` Conventions ("Where a new helper script goes"), and all conforming to
`.aid/knowledge/coding-standards.md`: `#!/usr/bin/env bash`, a Purpose / Usage / Exit-codes header
block, `set -euo pipefail` (or the documented `set -uo pipefail` variant for the read-only
analysers), stdout for results and stderr for diagnostics with a `<script>: ` message prefix, and
configuration read only through `read-setting.sh`.

| Script | Purpose | Exit codes |
|---|---|---|
| `graph-preflight.sh` | P1–P6 | `0` pass, `1` a prerequisite failed, `2` usage |
| `graph-stale-check.sh` | The D2 digest, the verdict, and the changed-component report | `0` for **every** verdict — the decision is informational, never a failure, as `stale-check.sh`'s header states; `2` usage |
| `kb-write-fence.sh` | `--snapshot` / `--verify` (E2) | `0` clean, `1` violation, `2` usage |
| `grade-graph.sh` | Orchestrates the D4 rubric over the reused leaf validators; prints Machine / Human / Overall | `0` Machine ≥ `A-`, `1` below, `2` usage — the same contract `grade-summary.sh` documents |

`grade-graph.sh` is a **new orchestrator, not a fork.** `grade-summary.sh` is specific to `kb.html`:
it hardcodes `KB_DIR=".aid/knowledge"`, reads
`.aid/.temp/summarize/manual-checklist.json`, and centres its 68-point pool on `COV` — resolved
doc-set coverage of the summary. Reusing it for the graph would import KB-completeness grading,
which FR-28 forbids. Reuse therefore happens at the **leaf validator** layer, where every check
actually lives, and `grade-graph.sh` contains no copied check logic. That is the reading of AC-17
this SPEC commits to — "no duplicated assembler or validator logic" — stated plainly so a reviewer
can test it by diffing the two orchestrators for shared check bodies and finding none.

#### Tests

Discovered by the `tests/canonical/test-*.sh` glob with no runner edit
(`.aid/knowledge/test-landscape.md` contracts). Each builds its own fixture under `mktemp -d`,
satisfying A-6.

| Suite | Covers |
|---|---|
| `test-graph-preflight.sh` | AC-11 (each of P1–P6 refuses with an actionable message); explicitly, a fixture whose KB is unapproved but whose `## Knowledge Summary Status` records `**User Approved:** yes` must still be **refused** — the P2 scoping fix |
| `test-graph-stale-check.sh` | AC-12 (`CURRENT` on an unchanged fixture; `STALE` after `--reset`); and the wider-input-set criterion: mutate only a `SRC` file, leave the KB untouched, assert `STALE` |
| `test-graph-read-only.sh` | AC-13 via E4 — the fence detects a mutated KB doc and exits non-zero naming it |

Machine-testing the state machine itself is out of scope by project design:
`.aid/knowledge/test-landscape.md` records prompt-driven skill state machines as "not machine-tested
(by design) — dogfooding + human/AI review only". The three suites above test the **scripts** the
states call, which is the testable surface.

### Migration Plan

Nothing existing changes shape. One pre-existing inconsistency is worked around here rather than
fixed, because fixing it changes `/aid-summarize`'s behaviour and is outside this work's scope; a
second has been fixed on this branch and no longer needs a workaround.

| Item | Disk truth | This feature's position |
|---|---|---|
| Node floor | **Fixed on this branch.** `summarize-preflight.sh` Check 5 now guards `-lt 20` with the message `Node.js >= 20 is required`, and `canonical/skills/aid-summarize/references/state-preflight.md` item 5 matches; `canonical/aid/scripts/summarize/package.json` has always declared `engines.node: ">=20"` | `graph-preflight.sh` P5 asserts **≥ 20**, which is now simply the project's summarize-validator floor rather than a raised one. No workaround remains. |
| Approval grep | `summarize-preflight.sh`'s `**User Approved:** yes` match is unscoped and this repo's `.aid/knowledge/STATE.md` contains that literal twice | `graph-preflight.sh` P2 reads the `kb_status` frontmatter scalar first and scopes its legacy fallback. `/aid-summarize` is left as-is; reported upstream (feature-011 `U4`). |

**Deliberately left open.**

- Whether RENDER produces a single file or a file plus companion assets depends on FR-18 / STATE.md
  Q2. The state machine, allowlist entry W3, and the `V-*` rubric rows are written to accommodate
  either without change.
- `graph.minimum_grade` is not added to `.aid/settings.yml` as part of this feature. The file carries
  a top-level `minimum_grade: A+` and no per-skill block at all — not even for `/aid-summarize`,
  despite `.aid/knowledge/quality-gates.md` describing one (recorded by feature-011 as a KB-drift
  finding). The resolver chain already yields `A+` here, so a per-skill key would add a second place
  for the floor to drift. The `--grade` argument writes it on demand when a project genuinely wants a
  different floor for this skill.

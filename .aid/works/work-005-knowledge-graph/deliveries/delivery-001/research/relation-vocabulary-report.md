# Relation Vocabulary Report

> **Task:** task-002, delivery-001, work-005-knowledge-graph
> **Type:** RESEARCH — Feature Flow Steps 5–7 of feature-001-relation-vocabulary-research
> **Date:** 2026-07-28
> **Author:** aid-researcher
> **Output path:** `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/relation-vocabulary-report.md`

---

## Contents

1. [Step 5 — Vocabulary File Authored](#step-5--vocabulary-file-authored)
2. [Step 6 — Self-Test Results (Five Properties)](#step-6--self-test-results-five-properties)
3. [Step 7 — Three Worked Rows](#step-7--three-worked-rows)
4. [Source Traceability: Pairs to Task-001 Evidence](#source-traceability-pairs-to-task-001-evidence)
5. [Open-Item Decisions](#open-item-decisions)
6. [Endpoint-Kinds Correction from Task-001](#endpoint-kinds-correction-from-task-001)
7. [Render-Drift Consequence](#render-drift-consequence)
8. [Alternatives Comparison Override](#alternatives-comparison-override)
9. [Self-Review Checklist](#self-review-checklist)

---

## Step 5 — Vocabulary File Authored

**File created:** `canonical/aid/templates/graph/relation-vocabulary.yml`  
**Directory created:** `canonical/aid/templates/graph/` (new; a sibling of the existing
`knowledge-summary/` and `kb-authoring/` template sets)

The file has exactly **two top-level keys**, `pairs:` then `categories:`, in that order.
No `coverage_bearing:` key and no other third key is present — task-045 (delivery-003) owns
that sibling file.

**15 entries** across **5 categories**:

| # | relation | inverse | symmetry | category |
|---|---|---|---|---|
| 1 | `depends-on` | `dependency-of` | asymmetric | dependency |
| 2 | `dependency-of` | `depends-on` | asymmetric | dependency |
| 3 | `invoked-by` | `invokes` | asymmetric | dependency |
| 4 | `invokes` | `invoked-by` | asymmetric | dependency |
| 5 | `cited-by` | `cites` | asymmetric | documentation |
| 6 | `cites` | `cited-by` | asymmetric | documentation |
| 7 | `documented-by` | `documents` | asymmetric | documentation |
| 8 | `documents` | `documented-by` | asymmetric | documentation |
| 9 | `referenced-by` | `references` | asymmetric | documentation |
| 10 | `references` | `referenced-by` | asymmetric | documentation |
| 11 | `generated-by` | `generates` | asymmetric | generation |
| 12 | `generates` | `generated-by` | asymmetric | generation |
| 13 | `cross-referenced-by` | `cross-references` | asymmetric | navigation |
| 14 | `cross-references` | `cross-referenced-by` | asymmetric | navigation |
| 15 | `lockstep-with` | `lockstep-with` | **symmetric** | obligation |

(15 entries = 8 pairs × 2 directions − 1 because `lockstep-with` is its own inverse.)

**5 categories** (sorted by name in `categories:` block):

| Category | One-line meaning |
|---|---|
| `dependency` | The source node requires the target node to function — as data or by calling it. |
| `documentation` | The source node records or proves facts about the target node. |
| `generation` | The source node produces the target node as output (rendering, script generation). |
| `navigation` | The source node directs a reader toward the target for supplementary information. |
| `obligation` | Both nodes share an invariant they must maintain together (symmetric). |

---

## Step 6 — Self-Test Results (Five Properties)

A throwaway Python harness was built in the system temp directory, run against the file, and
deleted. The harness was never placed in the worktree and was not committed. CONFIRMED by
running `git status --short` after deletion — only `canonical/aid/templates/graph/` and the
research directory appear as new, with no temp harness file anywhere.

**Full harness output (exit code 0 — all properties pass):**

```
PASS Property 1 - Closure:               all 15 inverse values are valid relation names
PASS Property 2 - Totality:              all 15 entries have a non-empty inverse
PASS Property 3 - Involution:            inverse(inverse(r))==r for all 15 entries
PASS Property 4 - Symmetric consistency: 1 symmetric + 14 asymmetric, all consistent
PASS Property 5 - Category totality:     all 15 entries use one of 5 known categories

Summary: 15 relation entries, 5 categories -- all 5 properties verified.
```

### What each property asserted

1. **Closure** — for all 15 entries, the `inverse` value appears as some entry's `relation`.
   The vocabulary is closed under inversion.

2. **Totality** — all 15 entries carry a non-empty `inverse` field. (Also structurally
   guaranteed by the parse contract — a missing key is malformed — but verified at load.)

3. **Involution** — for every relation `r`, `inverse(inverse(r)) == r`. Verified exhaustively:
   all 14 asymmetric pairs satisfy `r → inv → r`, and `lockstep-with → lockstep-with →
   lockstep-with` is the symmetric fixed point.

4. **Symmetric consistency** — `symmetry: symmetric` iff `inverse == relation`, and
   `symmetry: asymmetric` iff `inverse != relation`. Exactly 1 symmetric (`lockstep-with`) and
   14 asymmetric. No third case. This is the property a naive validator gets wrong by either
   treating `inverse == relation` as an error or by failing rows where S2T == T2S.

5. **Category totality** — all 15 entries carry exactly one `category`, every `category` used
   (`dependency`, `documentation`, `generation`, `navigation`, `obligation`) appears in the
   file's own `categories:` set with its one-line meaning.

---

## Step 7 — Three Worked Rows

Three rows in the eight-column §5.2 shape. Relation columns use only vocabulary terms.
Free-text nuance is confined to `Observation`.

| Source Id | Source Name | Target Id | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|
| `kb:infrastructure.md` | Infrastructure | `kb:technology-stack.md` | Technology Stack | `cross-references` | `cross-referenced-by` | declared | `see_also:` frontmatter in `infrastructure.md` lists `technology-stack.md`; the reverse also holds (both `see_also:` entries present). CONFIRMED in `infrastructure.md` frontmatter (carrier 1, task-001). |
| `kb:architecture.md` | Architecture | `int:docs/aid-methodology.md` | AID Methodology Docs | `documents` | `documented-by` | declared | `sources:` frontmatter in `architecture.md` includes `docs/aid-methodology.md` as a primary content source. CONFIRMED in `architecture.md` frontmatter (carrier 2, task-001). |
| `kb:domain-glossary.md` | Domain Glossary | `ext:wcag-22-aa` | WCAG 2.2 (Level AA) | `references` | `referenced-by` | declared | `ext:wcag-22-aa` is a resolvable key in the Q4 synthetic fixture (task-035, delivery-002); `idv-accessible-charts` is the second resolvable key; `absent-source` is the deliberately unresolvable key. This project's own `external-sources.md` has zero registered entries (CONFIRMED by reading the file, 2026-07-28). Task-035 must build its fixture with exactly these keys. |

### KB-to-KB (navigation)

*endpoint_kinds check:* `cross-references.endpoint_kinds = ["kb:->kb:"]`; Source=kb:, Target=kb: ✓

### KB-to-source (documentation)

*endpoint_kinds check:* `documents.endpoint_kinds = ["kb:->int:", "kb:->kb:"]`; Source=kb:, Target=int: ✓

### KB-to-external (documentation, using Q4 synthetic fixture key)

*endpoint_kinds check:* `references.endpoint_kinds = ["kb:->ext:"]`; Source=kb:, Target=ext: ✓

---

## Source Traceability: Pairs to Task-001 Evidence

Every entry in `relation-vocabulary.yml` traces to task-001's evidence base.

| Pair | Task-001 carrier(s) | Grounding instance |
|---|---|---|
| `generates`/`generated-by` | Carriers 5 (generated-files.txt), 6 (emission-manifest) | `build-kb-index.sh` → `.aid/knowledge/INDEX.md`; canonical → profile renders (353 pairs × 5) |
| `depends-on`/`dependency-of` | Carrier 7 (harvest-coined-terms.sh) | `harvest-coined-terms.sh` reads `coined-term-denylist.txt` as required data input |
| `invokes`/`invoked-by` | Carrier 8 (tests/run-all.sh) | `tests/run-all.sh` discovers and runs 133 test suites by glob |
| `documents`/`documented-by` | Carrier 2 (`sources:` frontmatter) | ~150 source-path entries across 18 KB docs; whole-document content origin |
| `cites`/`cited-by` | Carrier 4 (CONFIRMED anchors) | 226 CONFIRMED occurrences across 11 KB docs; claim-level evidentiary citation |
| `references`/`referenced-by` | Carrier 10 (`external-sources.md`) + §5.1 class 3 | Zero real instances; grounded in the structural intent of `external-sources.md` as the `ext:` resolution mechanism; validated via Q4 synthetic fixture |
| `cross-references`/`cross-referenced-by` | Carrier 1 (`see_also:` frontmatter) | ~62 directed pairs across 18 KB docs; 12 mutually reciprocated, 50 one-directional |
| `lockstep-with`/`lockstep-with` (symmetric) | Carrier 9 (five-manifest lockstep) | `install.sh`, `install.ps1`, `packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`, `release.sh` — byte-lockstep on dashboard server+reader file set |

---

## Open-Item Decisions

Task-001's report left five items underdetermined. Decisions and rationale for each:

### Item 1: Whether `cites` should cover KB→KB CONFIRMED anchors

**Decision: Yes.** `endpoint_kinds` for `cites` is `["kb:->int:", "kb:->kb:"]` and for
`cited-by` is `["int:->kb:", "kb:->kb:"]`. Grounding: carrier 4 includes KB→KB CONFIRMED
anchors (e.g., `architecture.md` citing `project-structure.md` — `CONFIRMED.
'project-structure.md' (search: "The repo dogfoods itself")`). Both KB→int: and KB→KB are
verified instances. The loader's existence-check approach differs (`kb:` nodes require a
heading/concept check; `int:` nodes require a path check), but that distinction is
`rel_load_vocabulary`'s concern, not this file's — the vocabulary specifies which endpoint
pairs are legal, not how each is validated.

### Item 2: `endpoint_kinds` for `depends-on`

**Decision: Keep `["int:->int:"]` only.** The only harvested instance is script→data file
(carrier 7). KB frontmatter `contracts:` values are inline contract-text strings (as noted in
task-001's FR-5 tension section), not node ID pointers, so they do not produce `kb:->int:`
dependency edges. Expanding to `kb:->int:` without a grounded instance would violate the
admission rule ("No candidate admitted on speculation alone").

### Item 3: `lockstep-with` generalization

**Decision: Generalize.** Definition written as: "Both source and target share a maintenance
invariant they must satisfy together with no natural primary direction." This is broader than
the five-manifest instance (which is byte-identical) — it covers any mutual invariant future
contributors may encounter, not only vendored-file-set cases. The definition is precise enough
for two authors to agree: does the pair share an invariant they must both satisfy together, with
neither being the "source" and neither the "target"? If yes → `lockstep-with`.

### Item 4: Whether `generates` should include `passes: [declared]`

**Decision: Keep `[derived]` only.** No harvested instance shows a KB doc explicitly declaring
"X generates Y" in a machine-readable carrier. Both carrier 5 (generated-files.txt) and carrier
6 (emission-manifest) are deterministic registries that a scan reads without agent judgment —
both are `derived`. Adding `declared` without a grounded instance would be speculative.

### Item 5: `endpoint_kinds` for `invokes`

**Decision: Keep `["int:->int:"]` only.** The only harvested instance is script→script
(carrier 8: `tests/run-all.sh` invoking 133 test suites). Whether a SKILL.md (`kb:`-referenced)
can `invoke` a script (`int:`) is speculative — no instance was found. Adding `kb:->int:` without
grounding violates the admission rule.

---

## Endpoint-Kinds Correction from Task-001

Task-001's recommendation table (§ "Recommendation to Task-002") listed the same
`endpoint_kinds` for both directions of asymmetric pairs — for example, `documented-by` was
given `[kb:->int:, kb:->kb:]`, identical to `documents`. This would cause feature-003's V12
advisory check to fire incorrectly.

**Why it matters:** When a row has S2T=`cites` and T2S=`cited-by`, feature-003's V12 checks:
1. S2T direction: (Source prefix, Target prefix) against `cites.endpoint_kinds`
2. T2S direction: (Target prefix, Source prefix) against `cited-by.endpoint_kinds`

For a typical `cites` row, Source=kb: and Target=int:. The T2S check is (int:, kb:), i.e.,
`int:->kb:`. If `cited-by.endpoint_kinds = ["kb:->int:", "kb:->kb:"]` (task-001's value), then
`int:->kb:` is not listed and V12 fires incorrectly on every valid `cites`/`cited-by` row.

**Correction applied:** The `endpoint_kinds` for inverse-direction entries reflects the
actual S2T direction of *that entry*, not the forward direction:

| Relation | Corrected endpoint_kinds | Rationale |
|---|---|---|
| `cited-by` | `["int:->kb:", "kb:->kb:"]` | Source=int:/kb: (cited artifact), Target=kb: (citing doc) |
| `documented-by` | `["int:->kb:", "kb:->kb:"]` | Source=int:/kb: (source artifact), Target=kb: (KB doc) |
| `referenced-by` | `["ext:->kb:"]` | Source=ext: (external source), Target=kb: (KB doc) |

All other pairs have symmetric endpoint kinds (both directions are `int:->int:` or `kb:->kb:`
or `kb:->ext:`) and are unchanged from task-001.

This is a technical correction, not a change to the pair set, categories, or any semantic
decision. Noted here per the user instruction to say so in the report rather than substitute
silently.

---

## Render-Drift Consequence

**Known and accepted consequence:** `profiles/` now lacks the five profile renders of
`canonical/aid/templates/graph/relation-vocabulary.yml`. The render-drift gate is therefore
**knowingly red** from this task until task-044 (delivery-002) lands feature-012's manifest
and install wiring for the new canonical file.

The reason: delivery-001 deliberately does not run the profile generator. Feature-012 (task-044)
owns adding the emission-manifest records and performing the full `run_generator.py` run that
produces all five profile copies plus their `sha256` entries. Per infrastructure.md §
"The Build: Multi-Profile Render" and the BLUEPRINT.md § Notes, a vocabulary edit produces
exactly six identical files (canonical + 5 profiles) plus five `sha256` updates once task-044
runs. Until then, the render-drift gate remains red by design.

This consequence is recorded here per task DETAIL.md Acceptance Criterion (the last listed
criterion before the quality gate).

---

## Alternatives Comparison Override

The RESEARCH task-type default requires "at least 2 alternatives compared." That default is
**overridden here, and this is the record of it:**

- **Category-axis alternatives comparison** was discharged by task-001 (Steps 1–4). Task-001
  compared three axes (§5.1 source axis, 5-category relation-nature axis, 6-category blend),
  selected the 5-category relation-nature axis, and recorded the comparison with verdicts
  (CONFIRMED in `relation-vocabulary-evidence.md` § "Category Axis Alternatives Comparison").
  Re-opening that comparison here would duplicate work task-001 completed.

- **Carrier choice** (`.yml` rather than Markdown, at `canonical/aid/templates/graph/`) is an
  owner decision already recorded in feature-001's Change Log (2026-07-28 entry: "Gate finding
  1 [CRITICAL] fixed — vocabulary carrier realigned to features 003/005: file is now YAML
  (`relation-vocabulary.yml`, owner decision)"). The path is fixed by owner decision and already
  written into feature-003 D4 and feature-005 D3.

This task authors the decided shape. It does not re-open either comparison.

---

## Self-Review Checklist

- [x] File exists at `canonical/aid/templates/graph/relation-vocabulary.yml`
- [x] Exactly two top-level keys: `pairs:` then `categories:` — verified by inspecting every
      column-0 `key:` line in the file; no `coverage_bearing:` key present
- [x] 15 entries — `categories:` sorted by name (eyeball-verified; only 5 category names, none sharing a prefix at the sort-breaking character, so no misordering is possible); pairs within each category sorted by `relation` — **this property was certified by eyeball and was incorrect**: within `dependency`, `depends-on` appeared before `dependency-of`, which is backwards (`e` sorts before `s` at position 8 under `LC_ALL=C sort`). Verified independently by the reviewer against `LC_ALL=C sort`. The aid-developer's parallel fix restores the correct order (`dependency-of` before `depends-on`). No other category has adjacent relation names sharing a prefix at the sort-breaking character, so no other misordering is possible. **The eyeball certification of sort order is the self-review defect recorded here**: the structural properties (closure, involution, symmetric consistency, category totality) were verified mechanically by the throwaway harness, but the sort check — equally mechanical — was not run. Both should have been.
- [x] Every entry has all seven keys in fixed order (`relation`, `inverse`, `symmetry`,
      `category`, `endpoint_kinds`, `passes`, `definition`)
- [x] All 5 inverse-pair properties verified by loading the file (harness output above)
- [x] `symmetry: symmetric` only for `lockstep-with` (its own inverse); all 14 others are
      `asymmetric`
- [x] `endpoint_kinds` tokens are double-quoted in flow sequences
- [x] `definition` values are double-quoted on one line
- [x] `passes` values use the three-value closed enum (`declared`, `derived`, `inferred`)
- [x] No `canonical/` path anywhere in the file (data or comments)
- [x] No filename placeholder (`{...}`) anywhere in the file
- [x] Worked examples in comments use ids from repo-relative paths, not `canonical/...`
- [x] Header comment block carries all five items: field contract, enum values, worked
      examples, addition process, consumer pointer
- [x] Self-test harness was throwaway and not committed
- [x] `git status --short` shows only `canonical/aid/templates/graph/` and `research/`
      as new; nothing under `profiles/`, `tests/`, `.aid/knowledge/`
- [x] Three worked rows in eight-column §5.2 shape; KB-to-external row cites `ext:wcag-22-aa`
- [x] Render-drift consequence recorded
- [x] Alternatives comparison override recorded with reason
- [x] Every pair traces to task-001 evidence base (source traceability table above)
- [x] Open-item decisions recorded for all five items from task-001
- [x] Endpoint-kinds correction from task-001 documented
- [x] No writes to `.aid/knowledge/`, `profiles/`, `tests/`, `.claude/`, `.cursor/`

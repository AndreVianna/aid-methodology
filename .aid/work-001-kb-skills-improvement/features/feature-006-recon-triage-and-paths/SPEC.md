# Recon Triage & The Three Paths

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-20, FR-21, FR-22) | /aid-interview |

## Source

- REQUIREMENTS.md §5.E (FR-20, FR-21, FR-22)
- REQUIREMENTS.md §1.5 (the method, the three paths, triage = lifecycle), §2.7 (P7)
- §4 S5, §10 (brownfield Must; greenfield Could)

## Description

This feature makes discovery **adapt to project shape** through one method with
three recon-selected paths: **greenfield**, **brownfield-small**, and
**brownfield-large**. A **recon pre-pass** measures source-availability and
complexity and **proposes** a path (human-confirmed) — the path is *measured, not
declared* from a static `project.type`. Each path configures the same method
differently per the agreed matrix: concept acquisition (extract vs elicit),
generation shape (forward-authored / single pass / parallel fan-out), closure
depth, panel size, source-of-truth, and exit — while **teach-back closure remains
the invariant exit** across all paths.

The path is **re-triaged every run**, so the three paths are *stages a project
passes through*: a greenfield's thin intent-KB becomes the spec the code is built
against, and as code lands the **greenfield→brownfield transition** is handled —
`aid-update-kb` verifies intent vs as-built and fills anatomy, and crossing the
complexity threshold triggers a brownfield-large consolidation. Per §10, the
brownfield-small and brownfield-large paths are **Must**; the **greenfield branch**
(elicit mode + the greenfield→brownfield transition) is **Could** (highest-risk /
most speculative).

## User Stories

- As an **AID adopter (brownfield)**, I want recon to measure my repo and propose
  the right path so that effort is scaled to my project — small repos stay cheap,
  large repos get the full machinery.
- As an **AID adopter (greenfield)**, I want a forward-authoring path so that I can
  discover a project that has nothing to extract yet (intent + vocabulary + design).
- As an **AID maintainer**, I want the path re-triaged every run and the
  greenfield→brownfield transition handled so that the KB persists and is
  progressively verified/enriched across the project lifecycle.

## Priority

Must (brownfield-small + brownfield-large paths) · Could (greenfield branch + transition)

## Acceptance Criteria

- [ ] Given a project, when the recon pre-pass runs, then it measures
  source-availability/complexity and proposes a path (greenfield / brownfield-small
  / brownfield-large), human-confirmed — measured, not declared. *(FR-20, AC7)*
- [ ] Given a proposed path, when discovery runs, then it configures the method per
  the agreed matrix and reaches teach-back closure (the invariant exit across all
  paths). *(FR-21, AC7)*
- [ ] Given a re-run, when triage executes, then the path is re-triaged and the
  greenfield→brownfield transition is handled (`aid-update-kb` verifies intent vs
  as-built and fills anatomy). *(FR-22)*
- [ ] Given greenfield / brownfield-small / brownfield-large fixtures, when triage
  runs, then it proposes the correct path on each and each path reaches teach-back
  closure. *(AC7 — fixtures from f012; greenfield branch is Could)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — triage depth
> by salience, cost scaling with project size (greenfield/brownfield-small cheap),
> deterministic threshold measurement. Path fixtures are provided by f012.

---

## Technical Specification

> Methodology/tooling feature — the **adaptive wrapper** that makes the f004 essence-capture
> engine + the f005 review panel **scale to project shape**. f006 adds (1) a shipped,
> deterministic **recon pre-pass** bash script that computes source-availability/complexity
> metrics (extending `build-project-index.sh`'s metrics + reading f004's candidate-concept
> count) and a **threshold classifier** (configurable in `.aid/settings.yml`) that **proposes**
> greenfield / brownfield-small / brownfield-large; (2) a **propose -> human-confirm** triage
> step in GENERATE that mirrors `aid-interview`'s lite/full TRIAGE; (3) a **3-path config
> matrix** that sets f004's closure knobs + f005's panel size per path; (4) the **panel-scaling
> wiring** f005 explicitly deferred here; (5) the **greenfield (elicit) branch** (the Could
> slice); and (6) **re-triage every run** with the greenfield->brownfield transition referenced
> (built by f010/f011, not here). "Components" are a new KB recon script, a `.aid/settings.yml`
> `triage:` block, `aid-discover` reference snippets (a new triage step + a path-config table),
> and a canonical test suite — not application code. Every claim is grounded against the files
> cited inline; genuine unknowns are flagged **[SPIKE]**, not guessed.
>
> **Boundaries (NOT re-spec'd here).** The **essence-capture engine** — the coined-term harvest,
> the concept spine, the closure loop, and the `discovery.closure` knobs — is **f004**; f006
> *consumes* `candidate-concepts.md` (for the metric) and *sets* the `discovery.closure` knobs
> per path, but does not redefine the harvest or the loop. The **5-mandate review panel +
> teach-back exit** is **f005**; f006 *collapses* the panel size per path (the seam f005
> deferred), but does not redefine the mandates (they are invariant across paths). The
> **frontmatter / `sources:` schema** is **f001**'s; the **concern model** is **f003**'s; the
> **greenfield elicitation** reuses `aid-interview` / `aid-specify` (NOT re-spec'd — f006 only
> detects greenfield and routes to the elicit shape). The **migration** of AID's own KB and the
> **greenfield->brownfield as-built verification** (`aid-update-kb` intent-vs-as-built) are
> **f010/f011** — f006 *references* the transition and re-triages each run, but the verifier is
> built there.

### Overview

f006 makes the one discovery method **adapt to project shape** (REQUIREMENTS §1.5, §2.7 P7,
FR-20/21/22). It inserts a **recon pre-pass + triage** at the front of GENERATE and a
**path->config mapping** that parameterizes the f004 engine and f005 panel the rest of GENERATE
already runs. The design is a thin adaptive wrapper, not a new engine: the heavy machinery is
f004 (produce) + f005 (grade); f006 only **measures the project, proposes a path (human-
confirmed), and sets the knobs**. Five pieces:

1. **A deterministic recon script** (`canonical/aid/scripts/kb/recon-classify.sh`) — extends
   `build-project-index.sh`'s metrics with the f004 candidate-concept count and emits a
   **proposed path** + the metrics that drove it, against **configurable thresholds in
   `.aid/settings.yml`**. No LLM, no dispatch (NFR-1/NFR-3). It runs as a **new Step 0f** in
   GENERATE, after f004's Step 0e (harvest) — so the candidate-concept count is available — and
   before the deep-dive fan-out.
2. **A propose -> human-confirm triage gate** — a PAUSE-FOR-USER-DECISION that shows the metrics
   + the proposed path + the threshold rationale and asks the human to confirm or override
   (greenfield / brownfield-small / brownfield-large). This **mirrors `aid-interview`'s
   lite/full TRIAGE** (propose from a measured signal -> single confirm turn -> write the
   decision to STATE.md). The path is **measured, not declared** — f006 never reads
   `project.type` as authoritative (FR-20).
3. **The 3-path config matrix** — a reference table (`references/path-config.md`) that maps each
   confirmed path to: f004's `discovery.closure` knobs (`max_rounds` / `max_clean_passes`),
   f004's fan-out on/off (deep-dive parallelism), f005's panel size (which mandates dispatch,
   parallel vs one checklist reviewer), the source-of-truth, the generation shape, and the exit.
   **Teach-back closure is the invariant exit on ALL three paths** (FR-21).
4. **Panel-scaling wiring** — the concrete realization of f005's deferred seam: for
   brownfield-large the full 5-parallel-dispatch panel runs; for brownfield-small / greenfield
   the panel **collapses to ONE `aid-reviewer` running the multi-mandate checklist** (all five
   mandates still apply — the *size* scales, the mandates do not). f006 sets the `review.panel`
   parameter that `state-review.md` (f005) reads to decide its dispatch count.
5. **The greenfield (elicit) branch + re-triage** — recon detects ~no-source -> greenfield; the
   path's source-of-truth is the human + requirements/design (elicit, not extract), reusing
   `aid-interview`/`aid-specify` (not re-spec'd). The path is **re-triaged every run**, so as
   code lands a project crosses greenfield -> brownfield-small -> brownfield-large; the
   greenfield->brownfield **transition verifier** (`aid-update-kb` intent-vs-as-built) is
   referenced as f010/f011 territory.

The deterministic substrate (the recon script's metrics + the threshold classifier) is
mechanical/CI-able; the only human judgment is the **confirm gate** (a one-turn decision,
anchored to the displayed metrics), exactly the §1.6 honest-floor shape.

### Recon Pre-Pass

#### The script

- **File:** `canonical/aid/scripts/kb/recon-classify.sh` (rendered to the 5 host trees + the
  repo `.claude/` working copy, like its siblings `build-project-index.sh` /
  `harvest-coined-terms.sh`). A **shipped KB script** that vendors into the install bundles, so
  ASCII-only bash (C2; PS-5.1 N/A — bash). No LLM, no embedding model (C1/NFR-8); pure coreutils
  (`awk`, `grep`, `sort`, `wc`) reading two **already-generated markdown files** + the settings.
- **It does NOT re-scan the tree.** All file-level metrics are read from `project-index.md`
  (Step 0c) and the candidate-concept count from `candidate-concepts.md` (Step 0e) — both are
  deterministic markdown tables already on disk by the time recon runs. recon-classify is a
  cheap **aggregator + classifier** over those two files, not a second find/wc sweep (NFR-1: no
  duplicated mechanical work; it reuses `build-project-index.sh`'s output rather than its code).
- **Invocation** (mirrors the sibling flag shape):
  ```bash
  bash .claude/aid/scripts/kb/recon-classify.sh \
    --index .aid/generated/project-index.md \
    --candidates .aid/generated/candidate-concepts.md \
    --settings .aid/settings.yml \
    --output .aid/generated/recon.md
  ```
  On a missing/empty `--candidates` (f004 not yet landed, or empty harvest) the concept-count
  metric degrades to 0 (degrade-gracefully, never an error) — recon still classifies on the
  file metrics alone. On a missing `--index` it logs a warning and proposes `brownfield-small`
  as the conservative default (the user-confirm gate is the safety net, mirroring Step 0d's
  "when uncertain, prefer the conservative proposal").

#### The metrics (the measured signal)

recon-classify reads these four metrics — the source-availability/complexity signal the
user-approved design names. All are parsed deterministically from the two markdown tables:

| # | Metric | Source (already on disk) | Parse rule |
|---|--------|--------------------------|------------|
| RM1 | **source-file count** | `project-index.md` Language Breakdown | sum of `Files` over rows whose Language is a `build-project-index.sh` `is_source` language (Java/Python/TS/Go/... — config/docs/data rows excluded). This is the "is there source to extract from?" signal — the greenfield discriminator. |
| RM2 | **source LOC** | `project-index.md` Language Breakdown | sum of `Lines` over the same `is_source` rows. The complexity magnitude (a 200-line CLI vs a 200k-line monolith). |
| RM3 | **directory / subsystem count** | `project-index.md` Full File Inventory | count of distinct top-2-level directory prefixes over `is_source` files (the breadth/fan-out signal — how many concern-lanes the deep dives must cover). |
| RM4 | **candidate-concept count** | `candidate-concepts.md` Summary | the `Cross-source (spread >= 2)` value (f004's count of project-coined, cross-source terms). This is the *conceptual* complexity signal — a small repo with many cross-source coined concepts is "small but conceptually dense" and may merit the large path. 0 when f004 absent. |

RM1 is the **greenfield discriminator** (near-zero source = nothing to extract = greenfield);
RM2/RM3/RM4 together are the **brownfield-small vs brownfield-large discriminator** (size x
breadth x concept-density). Using the **already-emitted** index + candidates keeps recon free
deterministic script time (NFR-1) and makes its output byte-reproducible (NFR-3).

> **`is_source` lockstep (same hazard f004 handles).** `is_source` is a **non-importable local
> function** inside `build-project-index.sh`; deriving RM1/RM2/RM3 requires `recon-classify.sh` to
> **re-implement that 23-language source classifier**. This is exactly the lockstep hazard f004
> already manages for its harvest (re-implemented identically across scripts, kept in lockstep,
> asserted by a shared fixture). `recon-classify.sh`'s language set MUST stay **in lockstep with
> `build-project-index.sh`'s `is_source`** — a shared fixture assertion in f006's new canonical
> suite (below) enforces it, mirroring f004's shared-fixture approach.

#### The classifier (deterministic rule)

recon-classify applies a **transparent, ordered rule** against the configurable thresholds:

```
if   RM1 (source-file count) <= greenfield_max_source_files
        AND RM2 (source LOC)  <= greenfield_max_source_loc
     -> propose GREENFIELD                 # little/no source to extract
elif RM2 (source LOC)         >= large_min_source_loc
        OR  RM3 (dir count)   >= large_min_dirs
        OR  RM4 (concept count) >= large_min_concepts
     -> propose BROWNFIELD-LARGE           # any one "large" dimension trips the full machinery
else -> propose BROWNFIELD-SMALL           # has source, but under every large threshold
```

The rule is **ordered and OR-on-large** by design: greenfield is gated on BOTH source metrics
being tiny (a repo with 3 source files but 50k LOC is not greenfield); brownfield-large trips if
**any** one dimension (LOC, breadth, or concept-density) is large (a small-LOC but
concept-dense repo — RM4 — still gets the full panel, which is the §1.5 "small but
conceptually dense" case the matrix's concept-density column anticipates). Everything between is
brownfield-small. The rule is pure arithmetic in `awk` — no judgment, fully CI-assertable
(NFR-3). recon emits the **proposed path PLUS the metric values and which threshold(s) tripped**,
so the confirm gate (below) shows the human *why* this path was proposed (visibility — NFR-6).

#### Configurable thresholds (`.aid/settings.yml` keys + defaults)

f006 **adds a new top-level `triage:` block** to the `settings.yml` template (the template has
no `triage:` key today — its keys are project/tools/review/execution/traceability/kb_baseline;
f004 adds `discovery:`). Sensible defaults, **NOT hard-coded magic** — every number is a
calibratable setting:

```yaml
# ---------------------------------------------------------------------------
# triage: recon-pre-pass thresholds for the 3-path discovery classifier (f006)
# ---------------------------------------------------------------------------
# Read by recon-classify.sh to PROPOSE a path (greenfield / brownfield-small /
# brownfield-large); the human CONFIRMS (the path is measured, not declared —
# project.type is never read as authoritative). Defaults are sensible starting
# points, calibratable per project; f012 fixtures tune them. All four metrics
# are read from the already-generated project-index.md + candidate-concepts.md.
triage:
  greenfield_max_source_files: 5     # RM1 <= this AND RM2 <= loc => greenfield (little/no source to extract)
  greenfield_max_source_loc:   500   # RM2 ceiling for greenfield
  large_min_source_loc:        20000 # RM2 >= this => brownfield-large (size)
  large_min_dirs:              25    # RM3 >= this => brownfield-large (breadth / fan-out)
  large_min_concepts:          40    # RM4 >= this => brownfield-large (concept density)
  # (absent block => these defaults; a project may override any single key)
```

Read via the existing `read-setting.sh --path triage.greenfield_max_source_files --default 5`
accessor (no new config machinery — D5). Defaults live in the `settings.yml` template (added by
this feature). **[SPIKE-T1]** — these five numbers are first-pass sensible defaults; the f012
greenfield / brownfield-small / brownfield-large fixtures (AC7) are the executable calibration:
each fixture MUST classify to its intended path. The thresholds are the precision lever and are
f012-tuned; f006 sets the *shape* (which metric, which comparison), f012 tunes the *floor*.
**[SPIKE-T2]** — `read-setting.sh` natively resolves only flat dotted-path lookups; `triage.*`
is one level deep (`triage.greenfield_max_source_files`), which is the same depth as the
existing `execution.max_parallel_tasks` (confirmed working — `state-generate.md` Step 0c reads
`discovery.doc_set` the same way), so `triage.*` reads work without `yq`. The f004
`discovery.closure.max_clean_passes` knob f006 *sets per path* is **two** levels deep; confirm
whether that two-level read needs `yq` or whether f006 should set the closure cap by passing it
as a **runtime flag to f004's closure step** rather than via a nested settings read (see Path
Config Matrix wiring + [SPIKE-T2]).

#### Where it runs in GENERATE

A new **Step 0f** is added to `state-generate.md`, after f004's Step 0e (harvest) and before
Step 1 (pre-scan) — so RM4 (candidate-concept count) is available, and so the path is decided
**before** any expensive dispatch (the fan-out + panel are what the path scales):

```
Step 0c  build-project-index.sh        (existing, deterministic — produces RM1/RM2/RM3 source)
Step 0d  Propose & Confirm Doc-Set      (existing, human-gated PAUSE)
Step 0e  harvest-coined-terms.sh  (f004) (deterministic — produces RM4 source)
Step 0f  recon-classify + triage  <NEW>  (deterministic classify, THEN human-confirm PAUSE)
Step 1   Pre-scan (scout)               (existing)
Steps2-5 Parallel deep dives            (existing — fan-out scaled by the confirmed path)
Step 5b  SYNTHESIS + CLOSURE      (f004) (closure cap scaled by the confirmed path)
REVIEW   panel                    (f005) (panel size scaled by the confirmed path)
```

Step 0f prints `[0f] Recon: measuring project shape...` then `[0f] Proposed path: <path>
(source-files=N, LOC=M, dirs=D, concepts=C)`. Because it is a pure script reading two existing
files, it adds negligible cost and zero LLM tokens (NFR-1).

### Triage Gate (propose -> human-confirm, mirroring aid-interview)

The confirm gate is a **PAUSE-FOR-USER-DECISION** that mirrors `aid-interview`'s lite/full
TRIAGE (`state-triage.md`): a measured proposal -> a single confirmation turn -> the decision
written to STATE.md. It is added to `state-generate.md` as the second half of Step 0f.

#### Idempotent re-entry

Mirroring Step 0d's idempotency and `state-triage.md`'s "if `Path:` is already populated, skip":
before classifying, check whether `.aid/{work-or-knowledge}/STATE.md ## Discovery Triage`
already carries a `**Path:**` from a prior run.

- **Prior path exists:** this is a re-run — **re-triage** (recompute the metrics; the path is
  re-measured every run, FR-22). Show the prior path + the freshly-measured proposal as a diff
  ("was brownfield-small; now measures brownfield-large — N new dirs since last run") and ask the
  human to confirm the transition or keep the prior path. This is the re-triage lifecycle made
  visible (greenfield -> brownfield as code lands).
- **No prior path:** first run — classify and propose.

#### Present the proposal (single confirm turn)

Display the measured metrics + the proposed path + the threshold rationale, then ask:

```
Recon measured this project:
  source files : 142        (greenfield <= 5)
  source LOC   : 38,400     (large >= 20,000)   <-- tripped LARGE
  directories  : 31         (large >= 25)       <-- tripped LARGE
  coined concepts: 47       (large >= 40)       <-- tripped LARGE

Proposed discovery path: brownfield-large
  (full machinery: researcher fan-out + full 5-mandate review panel + batched closure loop)

[1] Confirm  brownfield-large  (as proposed)
[2] Override brownfield-small  (collapsed: single understand-pass, one checklist reviewer)
[3] Override greenfield        (forward-authored / elicit; for a project with no source yet)
```

**This is a genuine PAUSE-FOR-USER-DECISION** (C4 human-gated; the path is measured but
**confirmed**, never auto-decided — FR-20). Stop here after presenting. The human's choice (not
the static `project.type`) is authoritative; an override is recorded as such (mirroring
`state-triage.md`'s `Override: yes`). Escalation/uncertainty defaults to the proposed path on a
bare confirm, exactly like Step 0d's conservative default.

#### On confirm (resume path) — write the decision

Write the confirmed path to `STATE.md ## Discovery Triage` (the trackable record; mirrors
`state-triage.md` Step 6 writing `## Triage`):

```markdown
## Discovery Triage

- **Path:** brownfield-large
- **Measured:** source-files=142, source-LOC=38400, dirs=31, concepts=47
- **Proposed:** brownfield-large (tripped: large_min_source_loc, large_min_dirs, large_min_concepts)
- **Decision rationale:** measured -> proposed brownfield-large -> confirmed
- **Re-triaged:** 2026-06-22 (run N)
```

(`**Override:**` is added when the human picked a path other than the proposed one, mirroring
`state-triage.md`.) The path value drives the Path Config Matrix (below). Then **CHAIN -> Step
1** with the confirmed path parameterizing the rest of GENERATE.

### The 3-Path Config Matrix

The confirmed path sets the knobs of the f004 engine + f005 panel per the §1.5 matrix. This is
authored as a reference table `canonical/skills/aid-discover/references/path-config.md` that the
GENERATE / closure / review states read. **The mandates and the teach-back exit are invariant
across all three paths; only the SIZE scales** (FR-21, FR-17).

| Dimension | Greenfield (Could) | Brownfield-Small (Must) | Brownfield-Large (Must) |
|---|---|---|---|
| **Source of truth** | human intent + requirements/design (elicit) | code + docs (extract) | code + docs + history/reports/data (extract) |
| **Concept acquisition** | **elicit** — spine co-authored from requirements (ties to interview/specify); harvest seeds candidate vocabulary but does not extract from absent source | **extract**, single pass — harvest -> spine, grounded once | **extract** — full mechanical harvest -> spine, concept-aware |
| **f004 deep-dive fan-out** | none (forward-authored, thin) | **off** — ONE understand-pass (no 4-way parallel fan-out) | **on** — full 4-way parallel deep-dive fan-out by concern |
| **f004 closure knobs** (`discovery.closure`) | `max_rounds: 1` — closure = "intent coherent + specified + vocab set" (teach-back **vs intent**) | `max_rounds: 1`, `max_clean_passes: 1` — short closure, single pass | default `max_rounds: 4`, `max_clean_passes: 2` — full batched-parallel loop, capped |
| **f005 panel size** (`review.panel`) | `mini` — ONE reviewer, intent-graded multi-mandate checklist | `collapsed` — ONE reviewer running the full multi-mandate checklist | `full` — 5 parallel mandate dispatches |
| **Review MANDATES** | all 5 (Correctness/Anatomy/Concept-closure/Teach-back/Calibration) — invariant | all 5 — invariant | all 5 — invariant |
| **Exit** | **teach-back closure** (vs intent) | **teach-back closure** | **teach-back closure** |
| **Starting KB** | thin (intent + vocab + design) | full anatomy (small) | full anatomy (large) |
| **Cost / wall-clock** | low tokens, human-paced | low | high (justified by complexity) |

**The single invariant: teach-back closure is the exit on all three paths** (REQUIREMENTS §1.5,
FR-21). What scales is the *machinery that gets there* — fan-out, closure depth, panel size —
NOT the acceptance bar.

#### How f006 sets f004's knobs

f004 exposes `discovery.closure.max_rounds` / `max_clean_passes` (its SPEC §"The bounded cap +
config") and the deep-dive fan-out as the parameters f006 scales. f004's SPEC *delegates the
path->cap mapping* to f006 (f006 reads the cap via `read-setting.sh --path
discovery.closure.max_clean_passes` and selects the per-path value). The **Step-5b cap-override
runtime argument** — the seam by which f006 supplies the per-path cap to f004's closure step
*without* a two-level nested settings read — is **not yet specified in f004's SPEC**; it is a
**PLAN-confirmed provide-before-consume seam (already flagged as [SPIKE-T2])** that f004 must
accept. **f006 chooses the runtime-arg mechanism** (so the deterministic settings read stays
flat — C1/NFR-8), and f004's interface for it is **confirmed in PLAN, not assumed present** in
f004's SPEC today. f006 sets the knobs per the matrix:

- **brownfield-large:** use f004's **default** closure caps (`max_rounds: 4`,
  `max_clean_passes: 2`) and run the full Steps 2-5 fan-out — f004's default behavior, no
  override needed.
- **brownfield-small:** `max_rounds: 1` (single understand-pass, no batched loop) and **skip the
  4-way fan-out** — GENERATE dispatches ONE `aid-researcher` understand-pass over the (small)
  source instead of the 4 concern-lane parallel dispatches. (The doc-set is still the confirmed
  small set; one researcher covers it in a single pass — the §1.5 "one understand-pass, no
  fan-out" row.)
- **greenfield:** `max_rounds: 1` with the closure criterion redefined to "intent coherent +
  specified + vocab set" (teach-back **vs intent**, not vs as-built source — there is no source).

**Wiring mechanism (per [SPIKE-T2]).** Because f004's closure cap lives at the two-level path
`discovery.closure.max_clean_passes` (which `read-setting.sh` resolves natively only one level
deep without `yq`), f006 sets the per-path cap by **the orchestrator passing the path-derived
cap as an explicit argument to f004's Step 5b closure step** (the `path-config.md` table is the
source the orchestrator reads), NOT by mutating nested settings at runtime. The
`discovery.closure` settings keys remain f004's **defaults** (the brownfield-large baseline); the
per-path override is a runtime parameter the matrix supplies. This keeps the deterministic
settings read flat and avoids a `yq` dependency (C1/NFR-8). The cap-override runtime argument is
a provide-before-consume seam f004 must accept; it is **not present in f004's SPEC today** and is
**confirmed in PLAN.md, not assumed** — **[SPIKE-T2]** tracks landing f004's Step 5b argument
interface ahead of f006's consumption.

### Panel-Scaling Wiring (the f005 seam)

f005 authored REVIEW to dispatch the **full 5-mandate parallel panel as the default** and
explicitly left the collapse-by-path to f006 (f005 SPEC §"Panel Orchestration": *"The full panel
(all 5) is the default f006 collapses ... f005 does not implement the collapse; it notes the
seam: the per-mandate dispatch list is the unit f006 scales (full 5 -> 1)"*; [SPIKE-C3]). f006
builds that collapse here.

- **The seam f005 exposed.** `state-review.md` Step 1 iterates a per-mandate dispatch list
  {Correctness, Anatomy/Coverage, Concept-closure, Teach-back, Calibration}, firing one
  `aid-reviewer` per mandate in parallel, then merges the per-mandate scratch ledgers into the
  single `discovery.md` and grades. f006 scales **how many dispatches** that list produces, via a
  `review.panel` parameter the path supplies (`full` | `collapsed` | `mini`).
- **brownfield-large (`panel: full`):** the unchanged f005 default — 5 parallel `aid-reviewer`
  dispatches, one per mandate, merged to `discovery.md`. No collapse.
- **brownfield-small / greenfield (`panel: collapsed` / `mini`):** the panel collapses to **ONE
  `aid-reviewer` running the multi-mandate checklist** — a single dispatch whose prompt
  concatenates **all five** mandate FOCUS bodies (the `reviewer-prompt-{correctness,anatomy,
  concept-closure,teachback,calibration}.md` f005 already split) into one checklist. The single
  reviewer writes ONE scratch ledger applying all five mandates; the merge step (f005 Step 2)
  short-circuits (one ledger -> `discovery.md`). **All five mandates still run** (the §1.5 "Review"
  row: *"collapsed: 1 reviewer, multi-mandate checklist"*) — the *panel size* drops from 5
  dispatches to 1, the *mandate coverage* is unchanged (FR-17: mandates invariant, size scales).
- **Teach-back stays a clean-context dispatch even when collapsed.** f005's teach-back mandate
  (M4) requires a **stricter** clean context (ONLY the KB, not the source). When the panel
  collapses, the **teach-back mandate is still dispatched as its own clean-context reviewer** (it
  cannot share a context that has seen the source), so `panel: collapsed` is concretely **2
  dispatches**: one combined-checklist reviewer (M1/M2/M3/M5) + one clean-context teach-back
  reviewer (M4). `panel: mini` (greenfield) is the same 2-dispatch shape, with M4 graded **vs
  intent** rather than vs as-built. This preserves the teach-back keystone exit on every path
  (FR-18) while still collapsing the bulk of the panel. **[SPIKE-T3]** — confirm with f005's
  `state-review.md` whether the combined-checklist single dispatch can host M1/M2/M3/M5 in one
  reviewer context without the contamination f005's per-mandate split was designed to prevent
  (the split exists so neither Correctness nor Anatomy is "satisfied by generic content while the
  other passes" — P2). The collapse is justified for SMALL/greenfield projects where the cost of
  5 dispatches is unjustified (NFR-1) and the contamination risk is lower (less source to
  conflate); for brownfield-large the full split stays. The `review.panel` parameter is the unit
  f006 sets; the dispatch-count realization lives in f005's `state-review.md`, which f006 amends
  to branch on `review.panel`.

`review.panel` is supplied the same runtime-parameter way as the closure cap (from
`path-config.md`, passed by the orchestrator to f005's REVIEW state) — not a persisted settings
key (it is a per-run, per-path value derived from the confirmed triage, re-derived each run).

### Greenfield Path (the Could slice)

Greenfield is the **forward-authoring / elicit** path (REQUIREMENTS §1.5; §10 Could — highest
risk / most speculative). It is the slice for a project that **has nothing to extract yet**.

- **Detection.** recon's RM1/RM2 near-zero (source-file count <= `greenfield_max_source_files`
  AND source LOC <= `greenfield_max_source_loc`) -> propose greenfield. The harvest (f004 Step
  0e) over a near-empty source yields a near-empty candidate list — which is itself the
  greenfield signal (nothing coined to extract).
- **Source of truth = human + requirements/design** (A4): the concept spine is **elicited**, not
  extracted. The spine's native concepts come from the project's **intent** — the requirements,
  the design notes, the human's vocabulary — co-authored with the human. This **reuses
  `aid-interview` / `aid-specify`** (the existing elicitation skills) — f006 does **NOT** re-spec
  elicitation; it only **routes** greenfield discovery to draw the spine from intent artifacts
  (requirements/design docs) + a human elicitation turn, rather than from a source sweep. The
  f004 harvest + spine machinery still runs (the spine is still the persisted first-class doc,
  FR-31); its *input* is intent rather than source.
- **Generation shape:** forward-authored, thin (intent + vocab + design) — no deep-dive fan-out
  (there is no source to fan out over). One pass authors the thin intent-KB.
- **Closure / exit:** teach-back **vs intent** — "intent coherent + specified + vocab set" — not
  teach-back vs as-built (there is no as-built yet). The teach-back mandate (M4) grades whether a
  fresh reviewer, given only the thin KB, can explain the *intended* system + define each
  *intended* concept. Teach-back closure remains the invariant exit (FR-18) — its referent shifts
  from as-built to intent.
- **Why it is the speculative slice (§10 Could).** Greenfield's primary risk (§1.5 matrix) is
  **intent <-> as-built drift**: the thin intent-KB becomes the spec the code is built against,
  and the KB must later be **verified against what was actually built** — which is the
  greenfield->brownfield transition (next section), built by f010/f011. f006 ships the greenfield
  *authoring* shape; the *verification* of that intent against later as-built is downstream.

### Re-Triage + Greenfield -> Brownfield Transition

**The path is re-triaged every run** (FR-22), so the three paths are **stages a project passes
through**, not a one-time label:

- **Re-triage (built here).** Step 0f recomputes the metrics on every `/aid-discover` run and
  re-proposes (the idempotent-re-entry branch above shows the prior path -> new measurement as a
  diff and re-confirms). A greenfield project whose code has since landed now measures
  brownfield-small; a brownfield-small that has grown past `large_min_*` now measures
  brownfield-large. The transition is **measured + human-confirmed** each run — the lifecycle is
  visible, never silently re-labeled. The path is **never** read from a static `project.type`
  (FR-20) — re-measurement is the mechanism that makes the path a lifecycle stage.
- **The greenfield -> brownfield transition VERIFIER (referenced, NOT built here).** When a
  greenfield's code lands, the thin intent-KB must be **verified against the as-built** and the
  anatomy filled in. REQUIREMENTS §1.5 / FR-22 assign this to **`aid-update-kb` (intent vs
  as-built)** — which is **f010/f011** territory (the `aid-update-kb` skill + the migration /
  as-built verification). f006's responsibility ends at: (a) re-triaging so the project is
  re-classified to brownfield once code lands, and (b) routing that re-triaged run to the
  brownfield extract shape (which now has source to extract). The **intent-vs-as-built diff +
  anatomy-fill** is performed by `aid-update-kb` (f010/f011), not by f006. Crossing
  `large_min_*` on a later run triggers a brownfield-large consolidation — again just a re-triage
  + re-route, with the consolidation work done by the (already-built) brownfield-large path.

This keeps f006 a thin re-routing wrapper: it **measures and routes** each run; the heavy
transition *work* (verify intent vs as-built, fill anatomy) is the downstream skill's job.

### Determinism & Cost (FR-23 / NFR-1-3)

- **Mechanical-first (NFR-1).** recon-classify is a **script reading two already-generated
  files** + a settings read — zero dispatch tokens, no second tree scan. The classifier is
  `awk` arithmetic against the thresholds. The only human surface is the one-turn confirm gate
  (a decision, not a generation). The path *scales down* the expensive work (fan-out, panel) for
  small/greenfield projects, which is the core NFR-1 lever (cost scales with project shape).
- **Bounded wall-clock (NFR-2).** recon adds one sub-second script pass before any dispatch; it
  does not lengthen the critical path. By collapsing the panel (5 -> 2 dispatches) and skipping
  the 4-way fan-out for small/greenfield, f006 *shortens* the critical path for those paths.
- **Determinism / repeatability (NFR-3).** Given the same `project-index.md` +
  `candidate-concepts.md` + thresholds, recon-classify emits a **byte-identical** proposed path
  (stable arithmetic, fixed threshold reads) — CI asserts re-run byte-identity, the same NFR-3
  guarantee f004's harvest carries. The classifier is a deterministic, CI-able termination of the
  "which path" question (the §1.6 "control flow / gates ... MUST be deterministic" mandate); the
  irreducible judgment (the human confirm) is a single anchored decision, not free reasoning.

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| **NEW recon script** | `canonical/aid/scripts/kb/recon-classify.sh` | Deterministic recon: read RM1/RM2/RM3 from `project-index.md` + RM4 from `candidate-concepts.md`, apply the threshold classifier from `triage.*`, emit the proposed path + metrics + tripped-thresholds to `.aid/generated/recon.md`. ASCII bash; no LLM; reads two already-generated files (no second tree scan). |
| GENERATE flow | `canonical/skills/aid-discover/references/state-generate.md` | Add **Step 0f** (run recon-classify after Step 0e; THEN the propose->human-confirm triage PAUSE; write `## Discovery Triage` to STATE.md; idempotent re-entry = re-triage). Add the path parameter to the Steps 2-5 fan-out (skip fan-out / one understand-pass for small/greenfield) and to the Step 5b closure-cap argument. |
| **NEW path-config reference** | `canonical/skills/aid-discover/references/path-config.md` | The 3-path config matrix: path -> {closure caps, fan-out on/off, `review.panel` size, source-of-truth, generation shape, exit}. The single source the GENERATE / closure / review states read for the per-path knobs. Teach-back-closure invariant noted on all three rows. |
| REVIEW flow | `canonical/skills/aid-discover/references/state-review.md` | Amend f005's Step 1 to **branch on `review.panel`**: `full` -> 5 parallel dispatches (f005 default, unchanged); `collapsed`/`mini` -> ONE combined-checklist reviewer (M1/M2/M3/M5) + ONE clean-context teach-back reviewer (M4). The merge/grade (Step 2) and teach-back hard gate are unchanged. (f006 edits the dispatch-count branch f005 left as a seam; it does not touch the mandates or the grade.) |
| Settings template | `canonical/aid/templates/settings.yml` | Add the **new top-level `triage:` block** (5 threshold keys + sensible defaults + comments). Absent block => defaults; a project may override any single key. |
| CI — canonical suite | `tests/canonical/test-recon-classify.sh` (NEW) + fixtures under `tests/canonical/fixtures/` | Mechanical assertions: a near-empty index classifies greenfield; a large-LOC index classifies brownfield-large; a small-source index classifies brownfield-small; each large-dimension (LOC / dirs / concepts) independently trips large; threshold overrides change the verdict; re-run byte-identical (NFR-3). **Plus an `is_source` lockstep fixture assertion** — a shared fixture asserting `recon-classify.sh`'s source-language set is identical to `build-project-index.sh`'s `is_source` (mirroring f004's shared-fixture lockstep), so the re-implemented classifier cannot drift. Auto-discovered by `tests/run-all.sh`. |
| CI — ascii-only | `tests/canonical/test-ascii-only.sh` | Add `canonical/aid/scripts/kb/recon-classify.sh` to `SHIPPED_SCRIPTS` (C2). |
| render-drift | `test.yml` job `render-drift` | No edit; stays green by editing canonical only + re-running `run_generator.py` (the new script + the 2 reference edits + the template edit render to all 5 trees). **[SPIKE-T4]** — same net-new-`scripts/kb/*.sh` render check as f004 [SPIKE-H4] / f005 [SPIKE-C2]; if an emission manifest pins the `scripts/kb/` list, regen, never hand-place. |

### Constraints

- **C2 / Q2 — ASCII-only.** `recon-classify.sh` vendors into the install bundles -> ASCII-only
  bash (PS-5.1 N/A). Added to `test-ascii-only.sh`'s allow-list. (The `path-config.md` /
  `state-*.md` edits are markdown — kept ASCII for sibling consistency.)
- **C1 / NFR-8 — no new runtime.** recon-classify is pure coreutils (`awk`/`grep`/`sort`/`wc`) +
  the existing `read-setting.sh` — the toolset its siblings already use. No embedding model,
  binary, MCP, or `python3`/`pwsh` escalation. The closure-cap + panel-size are runtime
  parameters (avoiding a two-level nested settings read that could pull in `yq` — [SPIKE-T2]).
- **C3 / NFR-4 — render-drift green.** All authored files are canonical (`scripts/kb/recon-classify.sh`,
  `templates/settings.yml`, `skills/aid-discover/references/{state-generate,state-review,path-config}.md`).
  Edit canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py`;
  commit regenerated `profiles/` (render-drift-full-generator precedent). **[SPIKE-T4]**.
- **C4 — human-gated.** The path is **measured but confirmed** — recon proposes, the human
  decides (FR-20). The path is never auto-applied from `project.type`; an override is recorded.
  Re-triage re-confirms each run.
- **C5 / NFR-3 — deterministic, CI-testable.** recon-classify is mechanical, stable, and
  byte-reproducible; the classifier rule is asserted in the new canonical suite against the f012
  path fixtures.
- **C6 — content-isolation.** The new script is namespaced under `aid/scripts/kb/`; its output
  lives under `.aid/generated/` (transient); the triage decision is recorded in the existing
  `STATE.md` (the isolated tracking tree).
- **C8 — skill conventions.** The triage gate follows the PAUSE-FOR-USER-DECISION /
  one-step-per-turn pattern (`state-machine-chaining.md`), mirroring Step 0d and
  `aid-interview`'s TRIAGE — thin-router state, visible discipline.

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-T1]** Threshold calibration — the five `triage.*` defaults
  (`greenfield_max_source_files`, `greenfield_max_source_loc`, `large_min_source_loc`,
  `large_min_dirs`, `large_min_concepts`) are first-pass sensible defaults; the f012 greenfield /
  brownfield-small / brownfield-large fixtures (AC7) are the executable calibration — each
  fixture MUST classify to its intended path. f006 sets the classifier *shape* (which metric,
  which comparison); f012 tunes the *floor*.
- **[SPIKE-T2]** Nested-settings read depth — `read-setting.sh` resolves flat dotted-paths
  natively; `triage.*` (one level) is fine, but f004's `discovery.closure.max_clean_passes` (two
  levels) may need `yq`. This spec therefore sets the per-path closure cap as a **runtime
  argument** the orchestrator passes to f004's Step 5b (from `path-config.md`), keeping the
  deterministic read flat (C1/NFR-8). Confirm the f004 Step 5b argument interface in PLAN.md
  (provide-before-consume: f004's closure step must accept a cap override arg).
- **[SPIKE-T3]** Panel-collapse contamination — confirm with f005's `state-review.md` whether a
  single combined-checklist reviewer can host M1/M2/M3/M5 in one context without re-introducing
  the P2 "blend selects for shallow-but-true" contamination the per-mandate split was designed to
  prevent. The collapse is scoped to SMALL/greenfield (low source -> low conflation risk, NFR-1
  cost-justified); brownfield-large keeps the full 5-way split. Teach-back (M4) stays a separate
  clean-context dispatch in all cases (so `collapsed`/`mini` = 2 dispatches, not 1).
- **[SPIKE-T4]** Net-new `scripts/kb/*.sh` render — same as f004 [SPIKE-H4] / f005 [SPIKE-C2]:
  verify `run_generator.py` emits `recon-classify.sh` to all 5 trees (it enumerates the tree;
  expected yes); if an emission manifest pins the `scripts/kb/` list, regen, never hand-place.
- **[SPIKE-T5 — sequencing]** f006 consumes f004 (`candidate-concepts.md` for RM4; the
  `discovery.closure` knobs it scales) and f005 (the `review.panel` dispatch-count seam). Confirm
  with PLAN.md that **f004 + f005 land before f006** (consume-after-define); if f006 is sequenced
  earlier, recon degrades gracefully (RM4=0 with no candidates file; the panel/closure knobs have
  nothing to scale yet) but the path-scaling value is not realized until f004/f005 land. The
  greenfield->brownfield transition VERIFIER (`aid-update-kb` intent-vs-as-built) is **f010/f011**
  — f006 references it; do not build it here.
- **[SPIKE-T6 — boundary, where STATE lives]** The `## Discovery Triage` record — `aid-discover`
  runs against `.aid/knowledge/STATE.md` (the KB state file), whereas `aid-interview`'s TRIAGE
  writes the work's `STATE.md`. Confirm with PLAN.md which STATE file owns the discovery-path
  record (likely `.aid/knowledge/STATE.md`, since the path is a property of the *KB generation*,
  not a work); the idempotent re-entry / re-triage read must target the same file the write
  targets.

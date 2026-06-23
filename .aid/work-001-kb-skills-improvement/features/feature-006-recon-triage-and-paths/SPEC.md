# Recon Triage & The Three Paths

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-20, FR-21, FR-22) | /aid-interview |
| 2026-06-23 | whole-work review 2026-06-23 — Dec.A: Description + AC aligned — greenfield reuses `aid-interview`/`aid-specify`; greenfield→brownfield transition handled by re-triage + the standard brownfield engine; intent-vs-as-built verifier mechanism dropped (Could framing preserved) | whole-work review |
| 2026-06-23 | f004 cross-refs aligned — the Step-5b cap-override interface (`--max-clean-passes`/`--max-rounds`/`--token-budget`) is now specified+owned in f004's SPEC; removed the impossible "f006 reads the cap via read-setting.sh" 2-level read; [SPIKE-T2] marked RESOLVED (provide-before-consume seam closed); f006 supplies per-path caps through f004's runtime-arg interface | alignment pass |
| 2026-06-23 | greenfield de-scope — greenfield is now **detect + signpost** only, NO generation engine. recon-classify KEEPS greenfield DETECTION (RM1/RM2 → greenfield verdict); on a confirmed greenfield path aid-discover prints a **signpost message and HALTS** (no fan-out, no closure, no panel, no elicit-via-interview/specify route). Greenfield is no longer a generation path: removed from the Steps 2-5 fan-out config, the Step-5b closure cap, and the `review.panel` `collapsed` value (now brownfield-small only). Re-triage (greenfield→brownfield as code lands) is kept; the forward-authored KB-seed is a FUTURE interview-side work, OUT of scope here | greenfield de-scope |

## Source

- REQUIREMENTS.md §5.E (FR-20, FR-21, FR-22)
- REQUIREMENTS.md §1.5 (the method, the three paths, triage = lifecycle), §2.7 (P7)
- §4 S5, §10 (brownfield Must; greenfield Could)

## Description

This feature makes discovery **adapt to project shape** through one method with
recon-selected paths. A **recon pre-pass** measures source-availability and
complexity and **proposes** a path (human-confirmed) — the path is *measured, not
declared* from a static `project.type`. Recon **detects** three project shapes —
**greenfield**, **brownfield-small**, and **brownfield-large** — but only the two
**brownfield** shapes are *generation paths*. Each brownfield path configures the
same method differently per the agreed matrix: concept acquisition (extract,
single pass vs concept-aware), generation shape (single understand-pass vs
parallel fan-out), closure depth, panel size, source-of-truth, and exit — while
**teach-back closure remains the invariant exit** across both brownfield paths.

**Greenfield is detect-and-signpost, not a generation path.** When recon detects
~no source (RM1/RM2 near-zero) and the human confirms greenfield, aid-discover
prints a **signpost** ("Nothing to discover yet — run `/aid-interview` to define
the project; the KB fills in as you build, via re-triage once code lands") and
**HALTS** — no deep-dive fan-out, no closure loop, no review panel. There is **no
greenfield generation engine** and no elicit-via-`aid-interview`/`aid-specify`
route built here; forward-authoring a KB-seed from intent is a **future,
interview-side work**, out of scope.

The path is **re-triaged every run**, so the shapes are *stages a project passes
through*: once a greenfield's code lands, the next run **re-triages** and re-routes
to a brownfield path, where the standard engine captures the now-extractable
anatomy, and crossing the complexity threshold triggers a brownfield-large
consolidation. Per §10, the brownfield-small and brownfield-large paths are
**Must**; greenfield **detection + signpost** is the in-scope greenfield slice
(detect, signpost, halt) — the greenfield generation path is explicitly **not
built** here.

## User Stories

- As an **AID adopter (brownfield)**, I want recon to measure my repo and propose
  the right path so that effort is scaled to my project — small repos stay cheap,
  large repos get the full machinery.
- As an **AID adopter (greenfield)**, I want recon to recognize my project has
  nothing to discover yet and **signpost me to `/aid-interview`** so that I'm not
  pushed through an extraction machine over absent source.
- As an **AID maintainer**, I want the path re-triaged every run so that once a
  greenfield project's code lands it is re-routed to the brownfield engine and the
  KB is built across the project lifecycle.

## Priority

Must (brownfield-small + brownfield-large paths + greenfield detect+signpost) · Greenfield generation path: OUT OF SCOPE (future interview-side work)

## Acceptance Criteria

- [ ] Given a project, when the recon pre-pass runs, then it measures
  source-availability/complexity and proposes a path (greenfield / brownfield-small
  / brownfield-large), human-confirmed — measured, not declared. *(FR-20, AC7)*
- [ ] Given a confirmed **brownfield** path, when discovery runs, then it configures
  the method per the agreed matrix and reaches teach-back closure (the invariant exit
  across both brownfield paths). *(FR-21, AC7)*
- [ ] Given a confirmed **greenfield** verdict, when discovery runs, then aid-discover
  prints the signpost ("Nothing to discover yet — run `/aid-interview` …") and
  **HALTS** — no fan-out, no closure, no panel (greenfield is detect+signpost, not a
  generation path). *(FR-20, AC7)*
- [ ] Given a re-run, when triage executes, then the path is re-triaged; once a
  greenfield project's source has landed, re-triage re-routes it to a brownfield path
  and the standard brownfield engine captures the now-extractable anatomy. *(FR-22)*
- [ ] Given greenfield / brownfield-small / brownfield-large fixtures, when triage
  runs, then it **detects** the correct shape on each; the two brownfield shapes each
  reach teach-back closure and the greenfield shape halts at the signpost. *(AC7 —
  fixtures from f012)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — triage depth
> by salience, cost scaling with project size (greenfield/brownfield-small cheap),
> deterministic threshold measurement. Path fixtures are provided by f012.

---

## Technical Specification

> Methodology/tooling feature — the **adaptive wrapper** that makes the f004 essence-capture
> engine + the f005 review panel **scale to project shape**. f006 adds (1) a shipped,
> deterministic **recon pre-pass** bash script that computes source-availability/complexity
> metrics (extending `build-project-index.sh`'s metrics + reading f004's candidate-concept
> count) and a **threshold classifier** (configurable in `.aid/settings.yml`) that **detects**
> greenfield / brownfield-small / brownfield-large; (2) a **propose -> human-confirm** triage
> step in GENERATE that mirrors `aid-interview`'s lite/full TRIAGE; (3) a **path config matrix**
> that sets f004's closure knobs + f005's panel size per **brownfield** path; (4) the
> **panel-scaling wiring** f005 explicitly deferred here; (5) a **greenfield signpost+halt** —
> on a confirmed greenfield verdict aid-discover prints the signpost and HALTS (NO generation
> engine, NO elicit-via-interview/specify route); and (6) **re-triage every run** with the
> greenfield->brownfield transition handled by re-triage + the standard brownfield engine once
> source lands (no transition verifier is built or referenced — none is in scope). "Components"
> are a new KB recon script, a `.aid/settings.yml` `triage:` block, `aid-discover` reference
> snippets (a new triage step + a path-config table), and a canonical test suite — not
> application code. Every claim is grounded against the files cited inline; genuine unknowns
> are flagged **[SPIKE]**, not guessed.
>
> **Boundaries (NOT re-spec'd here).** The **essence-capture engine** — the coined-term harvest,
> the concept spine, the closure loop, and the `discovery.closure` knobs — is **f004**; f006
> *consumes* `candidate-concepts.md` (for the metric) and *sets* the `discovery.closure` knobs
> per path, but does not redefine the harvest or the loop. The **5-mandate review panel +
> teach-back exit** is **f005**; f006 *collapses* the panel size per path (the seam f005
> deferred), but does not redefine the mandates (they are invariant across paths). The
> **frontmatter / `sources:` schema** is **f001**'s; the **concern model** is **f003**'s.
> **Greenfield generation is OUT OF SCOPE** — f006 only **detects** greenfield (RM1/RM2) and, on
> confirm, prints a **signpost and HALTS**; it builds NO greenfield generation engine and NO
> elicit-via-`aid-interview`/`aid-specify` route (forward-authoring a KB-seed from intent is a
> **future, interview-side work**). The **migration** of AID's own KB
> is **f010/f011**. There is **NO intent-vs-as-built transition verifier in scope** — neither in
> f006 nor as a referenced f010/f011 component. The greenfield->brownfield transition is handled
> by **re-triage** (built here — each run re-measures and re-routes) plus the **normal brownfield
> engine** once source exists; no separate verifier is built or assumed by any feature.

### Overview

f006 makes the one discovery method **adapt to project shape** (REQUIREMENTS §1.5, §2.7 P7,
FR-20/21/22). It inserts a **recon pre-pass + triage** at the front of GENERATE and a
**path->config mapping** that parameterizes the f004 engine and f005 panel the rest of GENERATE
already runs. The design is a thin adaptive wrapper, not a new engine: the heavy machinery is
f004 (produce) + f005 (grade); f006 only **measures the project, proposes a path (human-
confirmed), and either sets the knobs (brownfield) or signposts+halts (greenfield)**. Five
pieces:

1. **A deterministic recon script** (`canonical/aid/scripts/kb/recon-classify.sh`) — extends
   `build-project-index.sh`'s metrics with the f004 candidate-concept count and emits a
   **proposed path** + the metrics that drove it, against **configurable thresholds in
   `.aid/settings.yml`**. No LLM, no dispatch (NFR-1/NFR-3). It runs as a **new Step 0f** in
   GENERATE, after f004's Step 0e (harvest) — so the candidate-concept count is available — and
   before the deep-dive fan-out. **The greenfield-detecting branch stays** (RM1/RM2 → greenfield
   verdict); only the greenfield *behavior* changed (signpost+halt, not a generation path).
2. **A propose -> human-confirm triage gate** — a PAUSE-FOR-USER-DECISION that shows the metrics
   + the proposed path + the threshold rationale and asks the human to confirm or override
   (greenfield / brownfield-small / brownfield-large). This **mirrors `aid-interview`'s
   lite/full TRIAGE** (propose from a measured signal -> single confirm turn -> write the
   decision to STATE.md). The path is **measured, not declared** — f006 never reads
   `project.type` as authoritative (FR-20).
3. **The path config matrix** — a reference table (`references/path-config.md`) that maps each
   confirmed **brownfield** path to: f004's `discovery.closure` knobs (`max_rounds` /
   `max_clean_passes`), f004's fan-out on/off (deep-dive parallelism), f005's panel size (which
   mandates dispatch, parallel dispatches vs sequential mandate passes in one reviewer), the
   source-of-truth, the generation shape, and the exit. **Teach-back closure is the invariant exit
   on both brownfield paths** (FR-21). The matrix also carries a **greenfield row, but its action
   is signpost+halt** (no fan-out / closure / panel — see piece 5).
4. **Panel-scaling wiring** — the concrete realization of f005's deferred seam: for
   brownfield-large the full 5-parallel-dispatch panel runs; for **brownfield-small** the panel
   **collapses to ONE `aid-reviewer` that runs the four content mandates as separate sequential
   passes** (each mandate evaluated on its own — preserving the anti-P2 no-blending property at
   lower parallelism) plus the clean-context teach-back reviewer. All five mandates still apply —
   the *size/parallelism* scales, the mandates and the no-blending rule do not. f006 sets the
   `review.panel` parameter that `state-review.md` (f005) reads to decide its dispatch count.
   **Greenfield never reaches the panel** — it halts at the signpost, so `collapsed` is a
   **brownfield-small-only** value.
5. **The greenfield signpost+halt + re-triage** — recon detects ~no-source -> greenfield; on a
   confirmed greenfield verdict aid-discover **prints a signpost and HALTS**: *"Nothing to
   discover yet — run `/aid-interview` to define the project; the KB fills in as you build, via
   re-triage once code lands."* There is **no greenfield generation engine**, **no
   elicit-via-`aid-interview`/`aid-specify` route built here**, and **no intent-vs-as-built
   transition verifier** — forward-authoring a KB-seed from intent is a **future, interview-side
   work**, out of scope. The path is **re-triaged every run**, so as code lands a project crosses
   greenfield -> brownfield-small -> brownfield-large; the greenfield->brownfield transition is
   handled entirely by **re-triage** (re-measure + re-route) + the **normal brownfield engine**
   once source exists — no separate verifier.

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
**[SPIKE-T2 — RESOLVED]** — `read-setting.sh` natively resolves only flat dotted-path lookups;
`triage.*` is one level deep (`triage.greenfield_max_source_files`), which is the same depth as
the existing `execution.max_parallel_tasks` (confirmed working — `state-generate.md` Step 0c reads
`discovery.doc_set` the same way), so `triage.*` reads work without `yq`. The f004
`discovery.closure.max_clean_passes` knob f006 *sets per path* is **two** levels deep; rather than
a two-level nested read (which would pull in `yq`), f006 sets the closure cap by passing it as a
**runtime flag to f004's Step 5b closure step** (`--max-clean-passes` / `--max-rounds` /
`--token-budget`) — an interface **specified and owned in f004's SPEC (Step 5b)** (see Path Config
Matrix wiring + [SPIKE-T2]).

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
[2] Override brownfield-small  (collapsed: single understand-pass; one reviewer runs the mandates as sequential passes + clean-context teach-back)
[3] Override greenfield        (no source yet => signpost + HALT: run /aid-interview to define the project; the KB fills in as you build)
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
`state-triage.md`.) Then branch on the confirmed path:

- **Brownfield (small / large):** the path value drives the Path Config Matrix (below); **CHAIN
  -> Step 1** with the confirmed path parameterizing the rest of GENERATE.
- **Greenfield:** **do NOT chain to Step 1.** Print the **signpost** and **HALT** —

  ```
  [0f] Greenfield detected: ~no source to discover yet.
       Nothing to discover yet — run /aid-interview to define the project;
       the KB fills in as you build, via re-triage once code lands.
  ```

  No fan-out, no closure, no review panel runs. The `## Discovery Triage` record is still
  written (so the next run re-triages from a known prior path), but GENERATE ends here. Greenfield
  is a detect+signpost outcome, not a generation path.

### The Path Config Matrix

The confirmed path sets the knobs of the f004 engine + f005 panel per the §1.5 matrix. This is
authored as a reference table `canonical/skills/aid-discover/references/path-config.md` that the
GENERATE / closure / review states read. **The mandates and the teach-back exit are invariant
across both brownfield paths; only the SIZE scales** (FR-21, FR-17). The greenfield row is a
**signpost+halt** action, not a generation config — none of the closure/panel/fan-out columns
apply to it.

| Dimension | Greenfield (detect+signpost) | Brownfield-Small (Must) | Brownfield-Large (Must) |
|---|---|---|---|
| **Action** | **signpost + HALT** — print "Nothing to discover yet — run `/aid-interview` …" and stop GENERATE (no generation path) | run the brownfield engine (below) | run the brownfield engine (below) |
| **Source of truth** | n/a (nothing to discover yet — re-triages to brownfield once code lands) | code + docs (extract) | code + docs + history/reports/data (extract) |
| **Concept acquisition** | n/a — halts; **no** elicit-via-interview/specify route built here (future interview-side work) | **extract**, single pass — harvest -> spine, grounded once | **extract** — full mechanical harvest -> spine, concept-aware |
| **f004 deep-dive fan-out** | n/a — halts before fan-out | **off** — ONE understand-pass (no 4-way parallel fan-out) | **on** — full 4-way parallel deep-dive fan-out by concern |
| **f004 closure knobs** (`discovery.closure`) | n/a — halts before closure | `max_rounds: 1`, `max_clean_passes: 1` — short closure, single pass | default `max_rounds: 4`, `max_clean_passes: 2` — full batched-parallel loop, capped |
| **f005 panel size** (`review.panel`) | n/a — halts before review (never reaches the panel) | `collapsed` — ONE reviewer running the mandates as sequential passes | `full` — 5 parallel mandate dispatches |
| **Review MANDATES** | n/a — halts before review | all 5 (Correctness/Anatomy/Concept-closure/Teach-back/Calibration) — invariant | all 5 — invariant |
| **Exit** | **signpost** (GENERATE halts) | **teach-back closure** | **teach-back closure** |
| **Starting KB** | none (the signpost points to `/aid-interview`) | full anatomy (small) | full anatomy (large) |
| **Cost / wall-clock** | ~zero (script + one message, then halt) | low | high (justified by complexity) |

**The single invariant on the generation paths: teach-back closure is the exit on both brownfield
paths** (REQUIREMENTS §1.5, FR-21). What scales is the *machinery that gets there* — fan-out,
closure depth, panel size — NOT the acceptance bar. Greenfield does not run the engine at all; it
signposts and halts.

#### How f006 sets f004's knobs

f004 exposes `discovery.closure.max_rounds` / `max_clean_passes` (its SPEC §"The bounded cap +
config") and the deep-dive fan-out as the parameters f006 scales. f004's SPEC *delegates the
path->cap mapping* to f006. The **Step-5b cap-override runtime argument** — the seam by which
f006 supplies the per-path cap to f004's closure step *without* a two-level nested settings
read — **is specified and owned in f004's SPEC (Step 5b)**: f004's closure step accepts
`--max-clean-passes` / `--max-rounds` / `--token-budget` as runtime args. f006's `path-config.md`
supplies the per-path `max_rounds` / `max_clean_passes` values through that interface (so the
deterministic settings read stays flat — C1/NFR-8). f006 sets the knobs per the matrix:

- **brownfield-large:** use f004's **default** closure caps (`max_rounds: 4`,
  `max_clean_passes: 2`) and run the full Steps 2-5 fan-out — f004's default behavior, no
  override needed.
- **brownfield-small:** `max_rounds: 1` (single understand-pass, no batched loop) and **skip the
  4-way fan-out** — GENERATE dispatches ONE `aid-researcher` understand-pass over the (small)
  source instead of the 4 concern-lane parallel dispatches. (The doc-set is still the confirmed
  small set; one researcher covers it in a single pass — the §1.5 "one understand-pass, no
  fan-out" row.)
- **greenfield:** **no knobs are set** — greenfield **halts at the signpost** before f004's
  closure ever runs. There is no greenfield closure pass, no fan-out, and no panel to scale.
  (Once the project's code lands, re-triage re-routes it to a brownfield path and the brownfield
  caps above apply.)

**Wiring mechanism.** Because f004's closure cap lives at the two-level path
`discovery.closure.max_clean_passes` (which `read-setting.sh` resolves natively only one level
deep without `yq`), f006 sets the per-path cap by **the orchestrator passing the path-derived
cap as an explicit argument to f004's Step 5b closure step** (`--max-clean-passes` /
`--max-rounds` / `--token-budget`; the `path-config.md` table is the source the orchestrator
reads), NOT by mutating nested settings at runtime. The `discovery.closure` settings keys remain
f004's **defaults** (the brownfield-large baseline); the per-path override is a runtime parameter
the matrix supplies. This keeps the deterministic settings read flat and avoids a `yq` dependency
(C1/NFR-8). The cap-override runtime argument is **specified and owned in f004's SPEC (Step 5b)** —
f006 consumes it; the provide-before-consume seam is **resolved**.

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
  `review.panel` parameter the path supplies (`full` | `collapsed`).
- **brownfield-large (`panel: full`):** the unchanged f005 default — 5 parallel `aid-reviewer`
  dispatches, one per mandate, merged to `discovery.md`. No collapse.
- **brownfield-small (`panel: collapsed`):** the panel collapses to **ONE
  `aid-reviewer` that runs the four content mandates (M1 Correctness / M2 Anatomy / M3
  Concept-closure / M5 Calibration) as SEPARATE SEQUENTIAL PASSES within the single agent** — NOT
  one blended judgment. The reviewer's prompt drives it through each mandate's FOCUS body (the
  `reviewer-prompt-{correctness,anatomy,concept-closure,calibration}.md` f005 already split) **one
  at a time, in order**, evaluating each mandate on its own and writing that mandate's findings to
  the scratch ledger before moving to the next; the per-mandate results are then concatenated into
  the one ledger the merge step (f005 Step 2) consumes. This is the **anti-P2 property preserved
  at lower parallelism**: each mandate is still adjudicated independently (no mandate is "satisfied
  by generic content while another passes" — P2), the only thing that changes vs `full` is that
  the four passes run sequentially in one agent rather than in four parallel agents — a cost/
  parallelism reduction for small repos, not a relaxation of the no-blending rule. **All five
  mandates still run** (FR-17: mandates invariant, size scales).
- **Teach-back stays a clean-context dispatch even when collapsed.** f005's teach-back mandate
  (M4) requires a **stricter** clean context (ONLY the KB, not the source). When the panel
  collapses, the **teach-back mandate is still dispatched as its own clean-context reviewer**
  (it cannot share a context that has seen the source), so `panel: collapsed` is
  concretely **2 dispatches**: one sequential-passes reviewer (M1/M2/M3/M5) + one clean-context
  teach-back reviewer (M4). This preserves the teach-back keystone exit on the brownfield paths
  (FR-18) while collapsing the bulk of the panel. The collapse is justified for SMALL projects
  where the cost of 5 parallel dispatches is unjustified (NFR-1) — and because the mandates run as
  separate sequential passes, the P2 anti-blending guarantee f005's split protects is retained,
  not traded away; for brownfield-large the full parallel split stays. **Greenfield never reaches
  the panel** — it halts at the signpost — so `collapsed` is a **brownfield-small-only** value.
  The `review.panel` parameter is the
  unit f006 sets; the dispatch-count realization lives in f005's `state-review.md`, which f006
  amends to branch on `review.panel` (and to drive the collapsed reviewer through the four content
  mandates as ordered sequential passes — see **[SPIKE-T3 — RESOLVED]**).

`review.panel` is supplied the same runtime-parameter way as the closure cap (from
`path-config.md`, passed by the orchestrator to f005's REVIEW state) — not a persisted settings
key (it is a per-run, per-path value derived from the confirmed triage, re-derived each run).

### Greenfield (detect + signpost — NOT a generation path)

Greenfield is the shape for a project that **has nothing to extract yet** (REQUIREMENTS §1.5).
In this work greenfield is **detect + signpost only** — there is **no greenfield generation
engine**.

- **Detection (KEPT).** recon's RM1/RM2 near-zero (source-file count <= `greenfield_max_source_files`
  AND source LOC <= `greenfield_max_source_loc`) -> propose greenfield. The harvest (f004 Step
  0e) over a near-empty source yields a near-empty candidate list — which is itself the
  greenfield signal (nothing coined to extract). This detection branch in `recon-classify.sh`
  stays exactly as specified; only the *behavior on a greenfield verdict* changed.
- **Behavior = signpost + HALT.** On a confirmed greenfield path, aid-discover prints the
  signpost and **stops GENERATE**:

  ```
  Nothing to discover yet — run /aid-interview to define the project;
  the KB fills in as you build, via re-triage once code lands.
  ```

  No deep-dive fan-out, no closure loop, no review panel is dispatched. Greenfield is not a
  generation path: f006 does **NOT** build a greenfield generation engine, a
  greenfield-specific closure, a greenfield panel-collapse, or an
  elicit-via-`aid-interview`/`aid-specify` route. The `## Discovery Triage` record is still
  written so the next run re-triages from a known prior path.
- **Out of scope (future, interview-side work).** Forward-authoring a thin KB-seed from intent
  (requirements/design + the human's vocabulary) is a **future** capability that belongs on the
  **interview side**, not in aid-discover. It is explicitly **not built** in this work.
- **The greenfield->brownfield transition is handled by re-triage, not a verifier.** As code
  lands, the next `/aid-discover` run **re-triages** (Step 0f re-measures source and re-routes the
  project to brownfield-small/large), and the **normal brownfield extract engine** then runs over
  the now-present source. There is **no intent-vs-as-built transition verifier in scope** — not in
  f006, and not as a referenced f010/f011 component. Re-measure + re-route + the standard
  brownfield engine is the entire transition mechanism (next section).

### Re-Triage + Greenfield -> Brownfield Transition

**The path is re-triaged every run** (FR-22), so the three shapes are **stages a project passes
through**, not a one-time label:

- **Re-triage (built here).** Step 0f recomputes the metrics on every `/aid-discover` run and
  re-proposes (the idempotent-re-entry branch above shows the prior path -> new measurement as a
  diff and re-confirms). A greenfield project whose code has since landed now measures
  brownfield-small; a brownfield-small that has grown past `large_min_*` now measures
  brownfield-large. The transition is **measured + human-confirmed** each run — the lifecycle is
  visible, never silently re-labeled. The path is **never** read from a static `project.type`
  (FR-20) — re-measurement is the mechanism that makes the path a lifecycle stage.
- **The greenfield -> brownfield transition is re-triage + the brownfield engine (NO verifier).**
  When a greenfield's code lands, the transition is handled entirely by the mechanisms f006
  already builds: (a) **re-triage** re-classifies the project to brownfield once source is
  present, and (b) that re-triaged run **routes to the brownfield extract shape**, whose normal
  harvest -> spine -> closure machinery now has real source to extract and so fills the anatomy as
  a matter of course. There is **NO separate intent-vs-as-built transition verifier** — not in
  f006, and **not** as a referenced f010/f011 component. Because greenfield only signposted (it
  built no KB), the project is simply **discovered as brownfield for the first time** once code
  exists; the standard closure loop grades the (source-backed) KB against the teach-back bar.
  Crossing `large_min_*` on a later run
  triggers a brownfield-large consolidation — again just a re-triage + re-route, with the
  consolidation work done by the (already-built) brownfield-large path.

This keeps f006 a thin re-routing wrapper: it **measures and routes** each run; the transition
*work* is performed by the standard brownfield engine the re-route selects — there is no bespoke
verification step to build downstream.

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
| GENERATE flow | `canonical/skills/aid-discover/references/state-generate.md` | Add **Step 0f** (run recon-classify after Step 0e; THEN the propose->human-confirm triage PAUSE; write `## Discovery Triage` to STATE.md; idempotent re-entry = re-triage). On a confirmed **greenfield** verdict: print the **signpost and HALT** (no chain to Step 1, no fan-out/closure/panel). On a confirmed **brownfield** verdict: chain to Step 1 with the path parameterizing the Steps 2-5 fan-out (skip fan-out / one understand-pass for brownfield-small) and the Step 5b closure-cap argument. |
| **NEW path-config reference** | `canonical/skills/aid-discover/references/path-config.md` | The path config matrix: brownfield path -> {closure caps, fan-out on/off, `review.panel` size, source-of-truth, generation shape, exit}, plus a **greenfield row whose action is signpost+halt** (no generation columns apply). The single source the GENERATE / closure / review states read for the per-path knobs. Teach-back-closure invariant noted on both brownfield rows. |
| REVIEW flow | `canonical/skills/aid-discover/references/state-review.md` | Amend f005's Step 1 to **branch on `review.panel`**: `full` -> 5 parallel dispatches (f005 default, unchanged); `collapsed` (**brownfield-small only** — greenfield never reaches the panel, it halts at the signpost) -> ONE reviewer running M1/M2/M3/M5 as **separate sequential passes** (each mandate evaluated on its own, results concatenated — preserving the anti-P2 no-blending property at lower parallelism) + ONE clean-context teach-back reviewer (M4). The merge/grade (Step 2) and teach-back hard gate are unchanged. (f006 edits the dispatch-count branch f005 left as a seam; it does not touch the mandates or the grade.) |
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
- **[SPIKE-T2 — RESOLVED]** Nested-settings read depth — `read-setting.sh` resolves flat
  dotted-paths natively; `triage.*` (one level) is fine, but f004's
  `discovery.closure.max_clean_passes` (two levels) would need `yq`. **Resolved:** the per-path
  closure cap is supplied as a **runtime argument** the orchestrator passes to f004's Step 5b
  (`--max-clean-passes` / `--max-rounds` / `--token-budget`, from `path-config.md`), keeping the
  deterministic read flat (C1/NFR-8). The Step-5b cap-override argument interface is **specified
  and owned in f004's SPEC (Step 5b)** — f006 consumes it; no provide-before-consume gap remains.
- **[SPIKE-T3 — RESOLVED]** Panel-collapse contamination — **resolved, not deferred.** The
  collapsed reviewer (**brownfield-small only**) runs the four content mandates (M1/M2/M3/M5)
  as **separate sequential passes within the single agent** — each mandate evaluated on its own,
  in order, its findings written to the ledger before the next pass begins, the per-mandate
  results then concatenated — **NOT one blended judgment**. This preserves the exact anti-P2
  property f005's per-mandate split was built for (no mandate is "satisfied by generic content
  while another passes"); the only thing the collapse trades away is *parallelism/cost* (four
  sequential passes in one agent vs four parallel agents), justified for SMALL repos
  (NFR-1). Brownfield-large keeps the full 5-way parallel split. Teach-back (M4) stays a separate
  clean-context dispatch on **every brownfield** path (so `collapsed` = 2 dispatches: the
  sequential-passes reviewer + the clean-context M4 reviewer). Greenfield never reaches the panel
  (it halts at the signpost). f006 amends `state-review.md` to drive the collapsed reviewer
  through the four content mandates as ordered sequential passes.
- **[SPIKE-T4]** Net-new `scripts/kb/*.sh` render — same as f004 [SPIKE-H4] / f005 [SPIKE-C2]:
  verify `run_generator.py` emits `recon-classify.sh` to all 5 trees (it enumerates the tree;
  expected yes); if an emission manifest pins the `scripts/kb/` list, regen, never hand-place.
- **[SPIKE-T5 — sequencing]** f006 consumes f004 (`candidate-concepts.md` for RM4; the
  `discovery.closure` knobs it scales) and f005 (the `review.panel` dispatch-count seam). Confirm
  with PLAN.md that **f004 + f005 land before f006** (consume-after-define); if f006 is sequenced
  earlier, recon degrades gracefully (RM4=0 with no candidates file; the panel/closure knobs have
  nothing to scale yet) but the path-scaling value is not realized until f004/f005 land. The
  greenfield->brownfield transition needs **no transition verifier** — it is handled by re-triage
  (built here) + the standard brownfield engine once source exists; there is no `aid-update-kb`
  intent-vs-as-built verifier in scope for f006 or for f010/f011.
- **[SPIKE-T6 — boundary, where STATE lives]** The `## Discovery Triage` record — `aid-discover`
  runs against `.aid/knowledge/STATE.md` (the KB state file), whereas `aid-interview`'s TRIAGE
  writes the work's `STATE.md`. Confirm with PLAN.md which STATE file owns the discovery-path
  record (likely `.aid/knowledge/STATE.md`, since the path is a property of the *KB generation*,
  not a work); the idempotent re-entry / re-triage read must target the same file the write
  targets.

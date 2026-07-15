# Behavioral Spec — `aid-report` Redesign

> **Status:** LOCKED for implementation (design agreed 2026-07-15).
> **Tracked under:** `.aid/work-005-lite-skills-refactor/` (branch `work-005-lite-skills-refactor`).
> **Scope:** `aid-report` (canonical; no aliases). Third of the "clear mismatch" redesigns.
> Shares the [`aid-research`](aid-research.md) shape; this doc records only the deltas.
> **Not implemented yet** — this is the contract the implementation must satisfy.

---

## 1. Problem

- **Objective (catalog `intent`):** *"Analyze data or usage and communicate insight (EDA,
  metrics, A/B analysis)."*
- **Today:** same engine, same halt as review/research — plans a RESEARCH work and stops
  before analyzing. The user gets a planning package, never an insight.
- **Target:** analyze the data now → communicate the insight, clearly and simply,
  **resolving nothing**.

> `aid-show-dashboard` is a *separate* G11 skill and stays **correct-as-is**: it builds a
> durable, refreshable BI view (a real IMPLEMENT mutation). Only `aid-report` is a mismatch.

## 2. Objective (locked)

`/aid-report <data/usage subject>` **analyzes the data now** — EDA, metrics, or A/B — and
returns a **curated, verified insight report**: findings, conclusions (positive *and*
negative), data-quality caveats, conflicts (each with its reason), and gaps, presented
clearly and simply. The agent **resolves nothing**; the user resolves.

## 3. Same as `aid-research` (reused verbatim)

See [`aid-research`](aid-research.md). Carried over unchanged: single-shot run-now;
hand-authored + `repurpose: true`; work-folder + normal STATE template (`phase` not
driven); **`aid-researcher` produces / `aid-reviewer` verifies** in clean context;
**resolves nothing**; **one grade on the deliverable** gates via the bounded VERIFY loop;
**human final say before any commit**; **printed-suggestion handoffs**; **per-call
model/effort tiering** (~5 Opus → ~2 tiered).

## 4. Deltas unique to `report`

### 4.1 Input is data/usage, not an open question

The subject is a **dataset, logs, telemetry, metrics, or an A/B result** — not a question
to investigate.

- **Fast path** — a clear data source + a clear analytical ask ("analyze the A/B results
  in `results.csv`", "error-rate breakdown from these logs") → analyze immediately.
- **Guided path** — vague ("analyze our usage") → scope *which data, which metrics, what
  question* first (2–3 questions), then analyze.

### 4.2 Grounding truth = the actual data + project source/KB

Two-tier grounding, re-anchored:

- **Authoritative:** the **data being analyzed**, plus the KB/source for what the data
  *means* (schemas, definitions, what a metric represents). The report is reconciled
  against the data as it actually is.
- **Supplementary:** external **baselines / benchmarks / industry norms**, cited with
  **URL + access date**. They contextualize; they never override the data.
- **Conflict rule:** a data-vs-KB-assumption contradiction (e.g. the data shows a
  behavior the KB claims is impossible) is **presented to the user with its reason**,
  never silently resolved.

### 4.3 Data access (decision A — locked)

- **Files / logs / exports** → read **directly, read-only** (never mutate the source).
- **A live DB / analytics / telemetry service** → **MCP-first connector**
  (`consumption-protocol.md`): scan `.aid/connectors/INDEX.md`; for a `connection_type:
  mcp` match, request the connection from the host tool's MCP. No catalogued connector →
  **ask the user to provide the data/export**. Same posture as research's web access:
  optional, read-only, never blocks, never resolves credentials itself.

### 4.4 Data-quality caveats are first-class (stronger than research's "gaps")

EDA / metrics / A/B conclusions live or die on caveats — sampling, missing data,
confounders, statistical significance, time-window bias. These are surfaced **prominently**
in a dedicated section. The VERIFY pass explicitly **rejects any metric or A/B conclusion
stated without its caveat** (e.g. an effect size with no significance/sample note, a rate
with no denominator).

### 4.5 Visualization scope (decision B — locked)

- **Default:** tables + metrics + prose insight.
- **A chart only when it materially clarifies the insight** — embedded in the report
  artifact, static.
- **Never** a hosted or refreshable dashboard. **Boundary:** `aid-report` = a one-time
  analysis + insight; **`aid-show-dashboard`** = a durable, refreshable BI view. If the
  user wants the analysis to become recurring, that's a printed handoff suggestion to
  `/aid-show-dashboard`, not something `aid-report` builds.

### 4.6 Deliverable shape

`REPORT.md` (the "clear + simple" deliverable), sections in order:

1. **Question / Scope** — the analytical ask, as scoped.
2. **Data & method** — what data, its source, and how it was analyzed.
3. **Findings** — the metrics / tables / EDA output.
4. **Conclusions** — positive *and* negative, each tied to a finding.
5. **Caveats & data-quality gaps** — sampling, confounders, significance, missing data;
   `none` only if genuinely none.
6. **Conflicts & contradictions** — data↔KB especially, each with its reason + citations;
   `none` if none.
7. **Sources** — data source(s) + KB/`file:line` (authoritative) and external baselines
   `URL (accessed YYYY-MM-DD)` (supplementary), clearly separated.

## 5. State machine

Identical to [`aid-research` §5](aid-research.md) with `INVESTIGATE` → **`ANALYZE`** and
the input being data rather than a question. The conditional spike-escalation gate is
dropped (analysis doesn't spike code; a data-access gap is closed by asking the user for
the data, per §4.3, not by writing throwaway code):

```
INTAKE → ANALYZE (aid-researcher, clean ctx; data+KB authoritative, baselines supplementary+cited)
       → VERIFY (aid-reviewer, clean ctx; grades REPORT.md; bounded loop) ⤾
       → PRESENT (always: findings + conclusions(±) + caveats + conflicts(+reasons) + gaps) [user resolves]
       → HANDOFF? (printed suggestions only; incl. /aid-show-dashboard for a recurring view)
       → DONE
```

## 6. Grading model & tiering

- **One grade** on `REPORT.md` (grounded in the data, findings supported, **caveats
  present**, conflicts/gaps surfaced, conclusions not overstated into resolutions). Gates
  via the VERIFY loop. Reuses `grade.sh` + `reviewer-ledger-schema.md`.
- **Tiering:** simple (small dataset, one metric) → sonnet/medium; complex (large data,
  A/B significance testing, deep telemetry) → opus/high. Verifier tier ≥ producer tier.

## 7. Files the implementation will touch

1. `shortcut-catalog.yml` — `repurpose: true` on `aid-report`. (Its `intent` line already
   says "communicate insight," not "recommendation" — **no softening needed**.)
2. `canonical/skills/aid-report/SKILL.md` — hand-authored per this spec.
3. `shortcut-engine.md` — detach the `report` row from the family-grouping / default-type
   tables. **Keep `analyze-report.md`** — `aid-show-dashboard` still uses it (it remains
   engine-driven). After review/research/report detach, `show-dashboard` is that file's
   sole remaining engine consumer.
4. Regenerate: `build-shortcut-skills.py` → full `run_generator.py` → dogfood `.claude/`
   resync (test-dogfood-byte-identity).

## 8. Settled decisions

Resolved with the user 2026-07-15:

1. **Data access (A)** → files/logs read directly (read-only); live sources via MCP-first
   connector when catalogued, else ask the user for the export; never mutate the source
   (§4.3).
2. **Visualization scope (B)** → tables/metrics/prose default; a static embedded chart
   only when it materially clarifies; **never a dashboard**. Boundary: report = one-time
   analysis; `aid-show-dashboard` = durable BI view (§4.5).
3. Inherits the `aid-research` frame: resolves nothing, two-tier grounding with
   conflicts-presented-with-reasons, producer/verifier split, single deliverable grade,
   human-final-say, printed-suggestion handoffs, per-call tiering.

# Path Config Matrix

The **confirmed discovery path** (written to `## Discovery Triage` in `.aid/knowledge/STATE.md`
by Step 0f) drives the knobs of the f004 essence-capture engine and the f005 review panel for
the remainder of GENERATE. This reference table is the **single source** that GENERATE / CLOSURE
/ REVIEW states read for per-path configuration.

**Only the two brownfield paths are generation paths.** Greenfield is detect + signpost + HALT --
none of the generation columns (fan-out / closure / panel) apply to it. GENERATE ends at the
Step 0f signpost on a confirmed greenfield verdict; Steps 2-5, Step 5b, and REVIEW never run.

**Teach-back closure is the invariant exit on BOTH brownfield paths** (REQUIREMENTS FR-21). What
scales across paths is the *machinery that reaches the exit* -- fan-out, closure depth, panel
parallelism -- NOT the acceptance bar. The mandates (M1-M4) are invariant; only size scales.

---

## Matrix

| Dimension | Greenfield (detect+signpost) | Brownfield-Small (Must) | Brownfield-Large (Must) |
|---|---|---|---|
| **Action** | **signpost + HALT** -- print the signpost message and stop GENERATE (no generation path, no fan-out, no closure, no panel) | Run the brownfield engine per the knobs below | Run the brownfield engine per the knobs below |
| **Source of truth** | n/a -- nothing to discover yet; re-triages to brownfield once code lands | Code + docs (extract) | Code + docs + history/reports/data (extract) |
| **Concept acquisition** | n/a -- halts; no elicit-via-interview/specify route is built here (future interview-side work) | **Extract, single pass** -- harvest -> spine, grounded once; no batched loop | **Extract, full** -- mechanical harvest -> spine, concept-aware; full batched-parallel loop |
| **f004 deep-dive fan-out** | n/a -- halts before fan-out | **OFF** -- ONE understand-pass `aid-researcher` over the full (small) source; no 4-way parallel fan-out | **ON** -- full 4-way parallel deep-dive fan-out (one `aid-researcher` per concern lane: architecture / analyst / integrator / quality) |
| **f004 closure knobs** (`discovery.closure`) | n/a -- halts before closure | `max_rounds: 1`, `max_clean_passes: 1` -- short closure, single understand-pass | Defaults: `max_rounds: 4`, `max_clean_passes: 2` -- full batched-parallel loop, capped |
| **f005 panel size** (`review.panel`) | n/a -- halts before review; never reaches the panel | `collapsed` -- ONE reviewer running M1/M2 as **separate sequential passes** (each mandate evaluated on its own, results concatenated, anti-P2 no-blending preserved) + ONE clean-context teach-back reviewer (M3) + ONE clean-context act-back reviewer (M4); total 3 dispatches | `full` -- 4 parallel `aid-reviewer` dispatches, one per mandate |
| **Review mandates** | n/a -- halts before review | All 4 (Correctness / Anatomy-incl-altitude / Teach-back / **Act-back**) -- **invariant** | All 4 -- **invariant** |
| **Exit** | **Signpost** (GENERATE halts at Step 0f) | **Teach-back closure** (the invariant brownfield exit) | **Teach-back closure** (the invariant brownfield exit) |
| **Starting KB** | None -- the signpost points to `/aid-describe` | Full anatomy (small) | Full anatomy (large) |
| **Cost / wall-clock** | ~zero (one script pass + one message, then halt) | Low (single researcher pass, 3-dispatch panel, 1-round closure) | High (justified by project complexity) |

---

## Per-Path Closure-Cap Runtime Arg (Step 5b)

The orchestrator passes the path-derived caps as **runtime arguments** to f004's Step 5b
closure step. This is the cap-override interface specified and owned in f004's SPEC (Step 5b);
f006 supplies the per-path values through it. No two-level nested settings read; no `yq`.

| Path | `--max-rounds` | `--max-clean-passes` | Notes |
|------|---------------|----------------------|-------|
| brownfield-large | *(omit -- use defaults)* | *(omit -- use defaults)* | f004 defaults apply (`max_rounds: 4`, `max_clean_passes: 2`); no override arg needed |
| brownfield-small | `--max-rounds 1` | `--max-clean-passes 1` | Single understand-pass; short closure |
| greenfield | *(does not reach Step 5b)* | *(does not reach Step 5b)* | GENERATE halted at the Step 0f signpost |

`--token-budget` is always omitted (default 0 = use pass/round caps) unless overridden by the
user's `.aid/settings.yml` `discovery.closure.token_budget` setting.

---

## Per-Path Fan-Out (Steps 2-5)

| Path | Fan-out |
|------|---------|
| brownfield-large | **Full 4-way parallel fan-out**: dispatch aid-researcher (architecture), aid-researcher (analyst), aid-researcher (integrator), aid-researcher (quality) in parallel -- the normal GENERATE Steps 2-5 dispatch |
| brownfield-small | **Single understand-pass**: dispatch ONE `aid-researcher` with all declared-set targets (no concern-lane split); the small source is covered in a single pass |
| greenfield | *(does not reach Steps 2-5)* -- GENERATE halted at the Step 0f signpost |

---

## Notes

- The path is confirmed by the human at the Step 0f triage gate (FR-20); this table is the
  downstream parameterization, not the classifier. Do not re-classify here.
- `review.panel: collapsed` is a **brownfield-small-only** value. Greenfield never reaches the
  panel; brownfield-large always runs the full panel. There is no `panel: greenfield` value.
- The teach-back mandate (M3) and act-back mandate (M4) are **each a separate clean-context
  dispatch on every brownfield path**, even when `panel: collapsed` -- they cannot share context
  with the source-aware passes. M3 and M4 may share a dispatch only if both are clean-context;
  in practice dispatch them separately to keep their scratch ledgers independent.
- Re-triage (next run) re-measures and re-confirms the path; this table is read fresh each run.

# Migration Plan — KB-summary relocation (delivery-009, FR31)

> **Type:** DESIGN artifact (Architect). No production code in this file. It specifies the
> exact edits the next Developer executes and the dispositions the team adopts.
> **Owner spec:** `features/feature-007-kb-dashboard/SPEC.md` (FR31 relocation, FF-A3 waterfall,
> DM-A1 `summary_present`). **Scope:** producer-side migration of pre-existing summaries.

## 0. TL;DR

- **Chosen surface to implement now: OPTION A (producer-run migration).** `aid-summarize` at a new
  MIGRATE step inside PREFLIGHT (before STALE-CHECK) and `aid-housekeep` SUMMARY-DELTA detect an
  old-path summary with no new-path file and **move it** (`mkdir -p .aid/dashboard && mv -n old new`).
  STALE-CHECK then sees the file at the new path, finds it current + approved, and **skips
  regeneration**. Idempotent, never blocks the skill.
- **OPTION B (CLI `aid update`/`aid add` one-time move): RECOMMEND as a follow-up.** Most proactive
  (no skill run needed) but touches the **hand-maintained** `bin/aid` (ASCII/parity/vendor gates) —
  heavier, deferred unless the team wants the zero-skill-run guarantee. Spec'd at section 7.
- **OPTION C (reader transition-fallback accepting the old path): REJECT.** Carries the retired
  `.aid/knowledge/knowledge-summary.html` path forward as permanent reader contract debt for a
  one-time upgrade event; the read-only reader is the wrong place to special-case a producer relocation.
- **Orphan disposition:** OPTION A **moves** (`mv`), so nothing is left behind at the old path —
  no separate delete step, no orphan. STATE.md's historical `**Output:**` line is left as-is (it is
  a historical record, not a live pointer; the reader never reads it).

---

## 1. Breaking-change analysis

### 1.1 Root cause (verified against the code)

delivery-009 relocated the `aid-summarize` output:

| | Path |
|---|---|
| Before d009 | `<repo>/.aid/knowledge/knowledge-summary.html` |
| After d009 (FR31) | `<repo>/.aid/dashboard/kb.html` (served at `/r/<id>/kb.html`) |

The reader derives `summary_present` purely from a stat of the **new** path
(`dashboard/reader/parsers.py:332-338`):

```
kb_html = dashboard_dir / "kb.html"
summary_present = kb_html.is_file()
```

and `derive_kb_status` (`dashboard/reader/derivation.py:251-258`) returns:

```
if not summary_approved:   -> generating
if not summary_present:    -> preparing      <-- the false state
```

So for a repo whose KB **was summarized and approved before the upgrade**, on disk:
`summary_approved == true` (STATE.md `## Knowledge Summary Status` is untouched) **but**
`summary_present == false` (file still at the OLD path). The waterfall lands on **`preparing`**.

### 1.2 Observable symptom

- The KB card shows the **`preparing`** busy treatment ("Preparing summary… — KB approved"),
  a **false "generating-class" state** — the user is told a summary is being built when one
  already exists and is approved.
- `preparing` is **non-clickable** (UI-A: only `approved`/`outdated` link to `./kb.html`), so the
  user **cannot open their existing, approved summary** from the dashboard. The page is also no
  longer reachable at the served route (`/r/<id>/kb.html` 404s — the file is at the old path).
- Self-correction never arrives on its own: the card only leaves `preparing` when a new-path
  `kb.html` appears, which requires a fresh `aid-summarize`/`aid-housekeep` **regeneration** — an
  expensive Mermaid-inlining run the user did not ask for and that d009 silently relied on.

### 1.3 Affected population (exact predicate)

A repo is affected iff:

```
exists(.aid/knowledge/knowledge-summary.html)  AND  NOT exists(.aid/dashboard/kb.html)
```

i.e. any repo that had been summarized at least once under the pre-d009 path and has not yet
re-run a post-d009 summarize. (A repo that never summarized has neither file → correctly `pending`/
`generating`; not affected. A repo already re-summarized post-d009 has the new file → not affected.)

### 1.4 Blast radius

- **Every upgraded repo** with a prior summary — this is the steady-state population for any repo
  that adopted `aid-summarize` before d009.
- **All 5 host tools.** The summary path is the **per-repo `<repo>/.aid/`** tree, not a per-tool
  install path. Whichever tool a repo uses, the stale-path condition is identical, so the symptom
  and the fix are host-tool-agnostic. There is no per-tool variant.
- **Per-repo, not machine-wide.** The fix must run (or be runnable) **per repo**, which is exactly
  why a producer-run migration (A) — invoked per repo as the skill runs in that repo — is the
  natural primary surface, and why the registry-level machine config is irrelevant here.

> This is a genuine breaking change on upgrade: d009 changed the path the reader keys off without
> migrating files already at the old path. SPEC FF-A's "Migration Plan justified-skip" note
> ("an existing repo simply regenerates to the new path on the next summarize/discover run") is the
> bug — it assumed a regeneration that (a) the user has not triggered and (b) is expensive — rather
> than a cheap relocation. This plan supersedes that justified-skip.

---

## 2. Migration surfaces — evaluation and dispositions

| Surface | What it does | Touches | Disposition |
|---------|--------------|---------|-------------|
| **A. Producer-run migration** | `aid-summarize` PREFLIGHT (pre STALE-CHECK) + `aid-housekeep` SUMMARY-DELTA detect old-path-only and `mv` it to the new path before staleness is judged | **canonical** skills/scripts (rendered by run_generator) | **IMPLEMENT NOW** |
| **B. CLI-update migration** | `aid update` / `aid add` does a one-time per-repo `mv` on upgrade — no skill run needed | **hand-maintained** `bin/aid` (+ `.ps1` parity, vendor copies, ASCII gate) | **RECOMMEND (follow-up)** |
| **C. Reader transition-fallback** | reader's `summary_present` also accepts the old path | reader (`parsers.py`) Python + Node | **REJECT** |

### 2.1 Option A — Producer-run migration (IMPLEMENT NOW)

**Mechanism.** Add a tiny, idempotent **MIGRATE** step that runs *before* staleness is judged:

```
if exists(.aid/knowledge/knowledge-summary.html) AND NOT exists(.aid/dashboard/kb.html):
    mkdir -p .aid/dashboard
    mv -n .aid/knowledge/knowledge-summary.html .aid/dashboard/kb.html
```

Placed **before STALE-CHECK** so that STALE-CHECK (which already stats `.aid/dashboard/kb.html`,
`stale-check.sh:23-29`) now sees the relocated file, compares its date against the KB review date,
finds it **CURRENT_APPROVED** (STATE.md approval untouched), and **skips regeneration** — exactly the
desired outcome. The reader's `summary_present` flips true on the next poll → the card returns to
`approved`/`outdated`.

**Why it is the right primary surface.**

- It is **canonical-rendered** (C7): editing `canonical/` + running the FULL `run_generator.py`
  lands it in `profiles/` + `.claude/`, so `/aid-*` on this repo and shipped installs pick it up
  with no hand-maintained-file risk.
- It rides the **existing per-repo invocation** — the skill already runs in the repo whose files
  need moving, so no new entry point, no traversal, no machine-wide scan.
- It converts d009's expensive "regenerate to repopulate" into a **cheap `mv`** — the summary
  content is unchanged (NFR8), so regeneration is wasteful (NFR4); a move is the honest operation.
- Two producers cover the two natural re-entry points: a **direct `/aid-summarize`** run, and a
  **`/aid-housekeep`** run (which delegates to summarize). Putting the move in summarize's PREFLIGHT
  means **both** paths are covered by one edit (housekeep delegates through summarize). We add an
  explicit step to housekeep SUMMARY-DELTA as well, as a belt-and-suspenders for the (rare) path
  where housekeep short-circuits before delegating; see section 5.

**Limitation (honest).** A repo only migrates when a KB producer next runs in it. A repo that
upgrades and never runs `/aid-summarize` or `/aid-housekeep` stays at `preparing` until it does.
That residual is exactly what Option B closes — hence the recommendation.

### 2.2 Option B — CLI-update migration (RECOMMEND, follow-up)

**Mechanism.** `aid update` (and `aid add` for a newly-registered repo) performs the same one-time
per-repo move on upgrade, so a repo is migrated **the moment it is upgraded**, with **no skill run
required** — closing Option A's residual.

**Why recommend, not implement now.**

- `bin/aid` is **hand-maintained** (MEMORY: d008 install-wiring), not canonical-rendered. Any edit
  must satisfy the **ASCII-only** shipped-script gate (`test-ascii-only.sh`), the **bash↔PowerShell
  parity** gate (`test-aid-cli-parity.sh` — the move must be mirrored in `aid.ps1`), and the
  **vendor** copies (npm/pypi). That is materially heavier than a canonical edit.
- It is also the most **proactive** surface and the only one that fixes a repo that never re-runs a
  KB skill. So it is genuinely worth doing — just sequenced after A.
- **Trivial-enough escape hatch:** if, at implementation, the move proves to be a 3-line ASCII block
  that the parity harness accepts cleanly, promote it into this delivery. The spec is at section 7.

### 2.3 Option C — Reader transition-fallback (REJECT)

**Mechanism.** `parse_kb_state` would set `summary_present = exists(new) OR exists(old)`, and the
card link would have to fall back to the old path too.

**Why reject.**

- It carries the **retired** `.aid/knowledge/knowledge-summary.html` path forward as **permanent
  reader contract debt** for a one-time upgrade event. The reader is the long-lived, audited,
  read-only/no-LLM component (NFR2/NFR7) — encoding a producer's historical path there is exactly
  the wrong place for a transient migration.
- The reader **cannot serve** the old path: feature-010's server allowlist is the fixed 2-element
  set `{home.html, kb.html}` under `.aid/dashboard/` (SPEC SEC-A2). So even if `summary_present`
  read true off the old path, the card's `./kb.html` link still 404s — C fixes the *flag* but not
  the *reachability*. The file genuinely has to **move** for the served route to work. C is
  therefore not even a complete fix on its own.
- It would also have to be implemented **twice** (Python + Node, byte-parity, PT-1 fixture churn)
  for a fallback that A makes unnecessary.

**Disposition: REJECT.** A relocates the file (fixing both flag and reachability) and leaves the
reader's contract clean at exactly one path.

---

## 3. Move semantics + full edge-case matrix

The migration is a **pure relocation**: it changes *where the existing approved summary lives*, never
its content, its approval state, or its freshness axis.

### 3.1 The {old} × {new} matrix

| old `knowledge-summary.html` | new `dashboard/kb.html` | Behavior | Rationale |
|---|---|---|---|
| present | **absent** | `mkdir -p .aid/dashboard; mv -n old new` | the affected case — relocate, no content change |
| present | **present** | **no-op** (do NOT move, do NOT delete old) | the new file is authoritative; never overwrite it. Leave the old as an inert historical artifact (a later housekeep cleanup may sweep it, out of scope here) |
| absent | present | no-op | already migrated / native post-d009 repo |
| absent | absent | no-op | never summarized → `pending`/`generating` correctly (not our case) |

**`mv -n` (no-clobber) is mandatory** so the "both present" row can never overwrite a newer new-path
file even under a race. The detection predicate (`NOT exists(new)`) already guards this; `-n` is the
defense-in-depth so a second concurrent producer cannot clobber.

### 3.2 old-newer-than-new

Cannot occur within Option A's guarded path: A only moves when **new is absent**, so there is no new
file to be older/newer than. (If a future surface ever moves when both exist, the rule is: **never
move when new exists** — the new path is always authoritative because it is the one the live producer
chain writes. The migration's job is solely to populate an *empty* new path from a legacy one.)

### 3.3 git-tracked vs untracked summary — producers `mv` only; commit stays in the existing flow

- The migration step does a filesystem `mv` **only**. It does **not** `git add`/`git rm`/`git
  commit`. Staging/committing is left to the **existing** boundaries:
  - **`aid-summarize`** has no VC boundary (WRITEBACK edits STATE.md but never commits — confirmed
    `state-writeback.md`; housekeep owns the commit, `state-summary-delta.md:174-180`). So a direct
    `/aid-summarize` migrate-then-skip leaves the move **uncommitted** in the working tree — correct
    and harmless: the file is on disk where the reader/server need it; the user (or a later
    housekeep) commits it.
  - **`aid-housekeep`** SUMMARY-DELTA already commits `.aid/dashboard/kb.html` via
    `branch-commit.sh --add` (`state-summary-delta.md:170-172`). When housekeep runs, the relocated
    file gets picked up by that `--add` if the summary was regenerated. For the **skip** path (file
    moved, summary current → no regeneration) we add the moved path to a stage+commit so the
    relocation is captured (section 5.2) — but we never *block* on commit failure.
- If the old file was **git-tracked**, a bare `mv` leaves git seeing a deletion at the old path + an
  untracked file at the new path; the existing add-only commit flows (which `--add` the new path,
  never the old) will stage the new file. The old-path deletion is swept by whoever next runs
  `git add -A` / a housekeep cleanup — out of scope; not a correctness issue for the dashboard.
- If **untracked** (the summary was gitignored or never committed), `mv` simply relocates an
  untracked file — nothing to commit.

### 3.4 Idempotency

Running the migrate step **twice** is safe: after the first run `new` exists, so the
`NOT exists(new)` guard short-circuits the second run to a no-op. `mkdir -p` is idempotent.
`mv -n` would refuse to clobber even if the guard were somehow bypassed.

### 3.5 Staleness orthogonality

Migration **only relocates**. It does not touch the **freshness/`outdated`** axis, which is governed
entirely by `kb_baseline` + the reader's git read (FF-A2). After a move:
- If the KB summary is still current relative to the KB review date, STALE-CHECK returns
  `CURRENT_APPROVED` → the card is `approved` (or `outdated` if the *git baseline* says the default
  branch advanced — an **independent** axis the move never affects).
- The migration never writes or re-stamps `kb_baseline`; an absent/old baseline simply means the
  freshness check skips (stays `approved`, FF-A2 DD-A2). So a migrated repo lands on `approved` or
  `outdated` **exactly as its on-disk freshness signals dictate** — never on `preparing`.

### 3.6 Orphaned `.aid/knowledge/` summary

- Because Option A **moves** (not copies), there is **no orphan** in the affected case — the old path
  is empty after the move. (Only the "both present" row leaves the old file, and there the new file
  is authoritative; sweeping that legacy artifact is a later housekeep-cleanup concern, out of scope.)
- **STATE.md `## Summarization History` / `**Output:**` line** (`state-writeback.md:19`,
  `.aid/knowledge/knowledge-summary.html (size)`): this is a **historical ledger row**, not a live
  pointer. The reader **never** reads `**Output:**` (it reads `## Knowledge Summary Status` approval
  + a stat of `.aid/dashboard/kb.html`, verified `parsers.py:309-338`). So a stale `**Output:**`
  reference does **not** break the dashboard. Leave it untouched (rewriting history rows is
  out-of-scope churn); the **next** WRITEBACK naturally records the new path. No reference the
  *reader* resolves is left dangling.

---

## 4. Idempotency + safety invariants (mirror NFR10 graceful posture)

The migrate step MUST obey:

1. **Never overwrite a newer/existing new-path file** — guarded by `NOT exists(new)` **and** `mv -n`.
2. **Never lose content** — `mv` is atomic within a filesystem; the file is never deleted without
   arriving at the destination. No `rm` of the source independent of a successful move.
3. **Never block the skill on a migration failure** — the step is best-effort. If `mkdir`/`mv`
   fails (permissions, read-only FS, cross-device), **emit an informational note and continue** to
   STALE-CHECK as if no migration happened. The worst case is the pre-fix status quo (`preparing`),
   never a hard failure — degrade gracefully, mirroring feature-010 NFR10's per-repo posture.
4. **No new traversal / no request-derived path** — both paths are fixed well-known repo-relative
   constants; the step adds no path-construction surface (SEC-A2 unaffected).
5. **ASCII-only** for any shipped script text (the canonical scripts render to `.claude/` and ship;
   MEMORY ascii-only gate). Use plain ASCII status glyphs only where the existing scripts already do.

---

## 5. OPTION A — precise implementation spec (Developer-ready)

> Discipline (apply to every edit below): edit **`canonical/`** only, then run the **FULL**
> `.claude/skills/aid-generate/scripts/run_generator.py` to render into `profiles/` + `.claude/`
> (MEMORY "render-drift full generator" — never per-script renderers). Keep render-drift +
> deterministic-emission gates green. ASCII-only in all shipped script text.

### 5.1 `aid-summarize` — add a MIGRATE step in PREFLIGHT, before STALE-CHECK

**The migrate logic belongs in PREFLIGHT** because PREFLIGHT is the synchronous gate that runs on
**every** invocation before STALE-CHECK (`state-preflight.md:18` CHAINs to STALE-CHECK), and
`/aid-housekeep` delegates through the **full** summarize state machine (`state-summary-delta.md:96-99`)
— so a single edit here covers both the direct and the delegated paths.

**Recommended placement: inside `summarize-preflight.sh`** (so it is a deterministic, testable shell
step, consistent with the other preflight checks), invoked by the existing PREFLIGHT state. Add a new
check **after** the "KB approved" checks and **before** PREFLIGHT prints complete.

**Files to edit:**

| # | File | Edit |
|---|------|------|
| A1 | `canonical/scripts/summarize/summarize-preflight.sh` | Add the migrate block (snippet 5.4) after the existing prerequisite checks, before the success print. Best-effort: never `exit` nonzero from the migrate block. |
| A2 | `canonical/skills/aid-summarize/references/state-preflight.md` | Document the new step: add item "6. **Migrate legacy summary path (FR31 migration):** if `.aid/knowledge/knowledge-summary.html` exists and `.aid/dashboard/kb.html` does not, `mkdir -p .aid/dashboard` and `mv -n` the old file to the new path so STALE-CHECK sees the existing approved summary and skips regeneration. Best-effort — a failure prints a note and does not block." |
| A3 | `canonical/skills/aid-summarize/references/state-stale-check.md` | No logic change. Optional one-line note that a just-migrated file is treated as `CURRENT_APPROVED` (it already is — STALE-CHECK stats the new path). Add only if it aids clarity; not required. |

> **Why not put the `mv` in `stale-check.sh` itself:** stale-check is documented as an *informational
> decision* (exit 0 always, no side-effects beyond reading). Keep it read-only; the **mutation**
> (the `mv`) belongs in PREFLIGHT, which is already the side-effecting prerequisite gate. STALE-CHECK
> then observes the already-migrated state — clean separation.

### 5.2 `aid-housekeep` — belt-and-suspenders migrate in SUMMARY-DELTA

Housekeep already delegates to the full summarize machine (so PREFLIGHT's migrate fires for it too).
Add an explicit migrate **before** the delegation as defense-in-depth, and ensure the relocated file
is committed if nothing else changed.

| # | File | Edit |
|---|------|------|
| A4 | `canonical/skills/aid-housekeep/references/state-summary-delta.md` | In **Step 1** (after the state-entry banner, before **Step 2 — Delegate**), add a "Step 1b — Migrate legacy summary path" doing the same guarded `mkdir -p` + `mv -n` (snippet 5.4). In **Branch B (skipped)** — the path where the summary is already current and normally produces *no commit* — add: if the migrate step relocated a file this run, stage+commit the moved path via the existing `branch-commit.sh --add .aid/dashboard/kb.html` (one commit, C3), so the relocation is captured even on the skip path. Keep "no commit" only when nothing moved. |

> Rationale: on the **skip** path housekeep makes no commit (`state-summary-delta.md:251`). If a
> migration occurred this run, the moved file should be committed so the relocation persists in VC;
> add it to a single `branch-commit.sh` call guarded by "a move happened this run." Never block on
> commit failure.

### 5.3 `/aid-config` + `aid-discover` + reader — NO change

- **`/aid-config`** (`kb_baseline` schema): **no change.** Migration is path relocation only; it does
  not touch the baseline.
- **`aid-discover` state-done:** **no change.** Its auto-trigger of `/aid-summarize` (FR34) already
  routes through summarize PREFLIGHT, so a discover-driven run migrates for free.
- **Reader** (`parsers.py`/`derivation.py`): **no change** (this is precisely the Option-C rejection
  — the reader stays keyed on the single new path).

### 5.4 The move snippet (ASCII-only, best-effort, idempotent)

```bash
# --- FR31 legacy-summary migration (best-effort, idempotent) ---
# Relocate a pre-d009 summary so the dashboard's summary_present flips true and
# STALE-CHECK sees the existing approved summary (skips regeneration).
OLD_SUMMARY=".aid/knowledge/knowledge-summary.html"
NEW_SUMMARY=".aid/dashboard/kb.html"
if [ -f "$OLD_SUMMARY" ] && [ ! -f "$NEW_SUMMARY" ]; then
    if mkdir -p .aid/dashboard 2>/dev/null && mv -n "$OLD_SUMMARY" "$NEW_SUMMARY" 2>/dev/null; then
        echo "i  Migrated legacy summary -> $NEW_SUMMARY (FR31 relocation)."
    else
        echo "i  Could not migrate legacy summary (continuing; summary will regenerate)." >&2
    fi
fi
```

(Use whatever ASCII status-prefix convention the surrounding script already uses; the existing
scripts use `i ` / plain text in `>&2`. Do not introduce non-ASCII glyphs.)

### 5.5 Tests to add

| # | Test | Location / style | Asserts |
|---|------|------------------|---------|
| T1 | `summarize-preflight` migrate unit | `tests/canonical/test-summarize-preflight.sh` (new, mirror `test-writeback-state.sh` harness + `tests/lib/assert.sh`) | (a) old present + new absent → after preflight, new exists & old absent; (b) both present → new untouched, old untouched (no clobber); (c) neither → no-op; (d) old present + new absent + `.aid/dashboard` unwritable → preflight still exits success (best-effort, no block); (e) **idempotency:** run twice → second run is a no-op |
| T2 | stale-check-after-migrate integration | extend/add `tests/canonical/test-summarize-preflight.sh` or a small stale-check harness | after migrate, `stale-check.sh` on a current+approved fixture returns `CURRENT_APPROVED` (no regeneration) |
| T3 | reader status post-migrate | `dashboard/reader/tests/test_task064_kb_status.py` (add a case) | fixture with `.aid/knowledge/STATE.md` approved + `.aid/dashboard/kb.html` present (post-migrate state) → `derive_kb_status` returns `approved` (or `outdated` per git), **never** `preparing`. (Confirms the reader contract the migration targets.) |
| T4 | housekeep SUMMARY-DELTA migrate | extend `tests/canonical/test-housekeep-classify.sh` or add a focused harness | Branch-B skip path with a migrated file commits the moved path once (C3); no-move skip path makes no commit |
| T5 | ASCII gate | existing `tests/canonical/test-ascii-only.sh` (auto-covers rendered scripts) | the new snippet text is ASCII-only |

Push and let remote CI run the suite (MEMORY testing-cadence); the migrate unit + reader case are the
load-bearing additions.

---

## 6. Rollout / sequencing + verification

### 6.1 Sequencing

1. **This delivery (A):** edits A1–A4 in `canonical/` → FULL `run_generator.py` render → render-drift +
   ascii + the new tests green → commit on the work-scoped branch.
2. **Follow-up (B, recommended):** `aid update`/`aid add` one-time move in hand-maintained `bin/aid`
   + `aid.ps1` parity + vendor copies + ASCII gate; spec at section 7. Promote into this delivery only
   if the move proves trivial under the parity harness.
3. **Release-tracking:** append a `[FIX]` entry to `.aid/knowledge/release-tracking.md` Unreleased
   (MEMORY release-tracking-kb-doc): "FR31 summary relocation now migrates pre-existing
   `.aid/knowledge/knowledge-summary.html` to `.aid/dashboard/kb.html` on the next aid-summarize/
   aid-housekeep run, so upgraded repos no longer show a false `preparing` KB card." Regen INDEX after.

### 6.2 Verification — prove the upgraded repo recovers without regeneration

**Setup (simulate a pre-d009 upgraded repo):** a repo with `.aid/knowledge/STATE.md` showing
`## Knowledge Summary Status **User Approved:** yes`, a `## Review History` + `## Summarization
History` dated such that the summary is **current** (summary date ≥ KB review date), an existing
`.aid/knowledge/knowledge-summary.html`, and **no** `.aid/dashboard/kb.html`.

**Procedure & expected:**

1. **Before:** `derive_kb_status` → `preparing` (reproduce the bug). Card non-clickable; `/r/<id>/
   kb.html` 404.
2. **Run** `/aid-summarize` (or `/aid-housekeep`).
   - PREFLIGHT MIGRATE: `.aid/dashboard/kb.html` now exists; `.aid/knowledge/knowledge-summary.html`
     gone.
   - STALE-CHECK: returns **`CURRENT_APPROVED`** (summary current + approved) → **DONE-IDEMPOTENT**,
     **no GENERATE**, **no Mermaid re-inlining**. (Assert no new `## Summarization History` row and
     `kb.html` mtime/content reflects the moved file, not a regenerated one.)
3. **After:** next reader poll → `summary_present == true` → `derive_kb_status` returns **`approved`**
   (or **`outdated`** if the git baseline says the default branch advanced — the independent freshness
   axis), **never `preparing`**. Card is clickable; `/r/<id>/kb.html` serves the existing page.

**Negative checks:**
- **Both-present:** seed both files → run → new file byte-unchanged, old file untouched, no
  regeneration (T1b).
- **Re-run idempotency:** run the producer twice → second run migrates nothing (T1e).
- **Unwritable dashboard dir:** producer still completes, lands at the pre-fix `preparing` (no crash) —
  graceful degradation (T1d).

The key acceptance signal: **an upgraded repo with an existing current+approved summary reaches
`approved`/`outdated` after one producer run with NO regeneration** (the move + STALE-CHECK skip),
and only regenerates if the summary was genuinely stale relative to the KB (the normal STALE path,
unchanged by this plan).

---

## 7. OPTION B implementation spec (follow-up reference)

If/when B is implemented:

- **`bin/aid` (`aid update`, and `aid add` for a newly-registered repo):** for each repo path being
  updated/added, run the same guarded move (section 5.4 logic, in `bin/aid`'s shell style).
- **`aid.ps1` parity:** mirror the move (PowerShell `Move-Item` guarded by `Test-Path` old + `-not
  Test-Path` new), ASCII-only; `test-aid-cli-parity.sh` must stay green.
- **Vendor copies:** propagate to the npm/pypi vendored `bin/aid`/`aid.ps1` per the d008 install-wiring
  layout.
- **Idempotent + best-effort:** same `NOT exists(new)` guard, never fail the `update`/`add` command on
  a per-repo move failure (skip that repo, continue).
- **Tests:** extend `test-aid-cli.sh` / `test-aid-cli-ps1.sh` / `test-aid-cli-parity.sh` with an
  old-present/new-absent fixture asserting the move; ASCII gate auto-covers.

B fully closes A's residual (a repo that upgrades and never runs a KB skill), at the cost of the
hand-maintained-file gate burden — hence sequenced second.

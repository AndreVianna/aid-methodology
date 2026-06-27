# Per-Doc Freshness Loop

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-5, FR-6, FR-7) | /aid-interview |

## Source

- REQUIREMENTS.md §5.B (FR-5, FR-6, FR-7)
- REQUIREMENTS.md §1.8 (freshness loop's three holes + closers), §2.5 (P5)
- §4 S2, S8, §10 (Should)

## Description

This feature closes the KB freshness loop at per-document granularity. Building on
the `sources:` primitive (f001), it adds a **deterministic per-doc staleness
check** that compares each doc's `sources:` last-changed commit against that doc's
approval commit and marks drifted docs *suspect* — replacing today's single coarse
whole-KB tip-date judgment sweep that nobody runs. Source changes **trigger**
per-doc suspect flagging, and the dashboard **surfaces per-doc freshness**
(replacing the single coarse whole-KB badge) so doc owners get an actionable
signal: which doc their change made suspect.

The governing principle is **auto-detect/flag, never auto-apply** — detection is
automatic and deterministic, but every change to KB content remains human-gated.
This gives doc owners precision and a trigger without surrendering the human gate.

## User Stories

- As a **doc owner / maintainer**, I want a per-doc, source-keyed staleness signal
  so that I know exactly which doc my change made suspect instead of getting a
  whole-KB coarse alarm I ignore.
- As a **doc owner**, I want source changes to trigger suspect flagging and the
  dashboard to surface it so that drift is detected automatically rather than from
  human memory.
- As an **AID adopter (incl. AI-skeptic)**, I want freshness to flag but never
  auto-apply so that the KB stays trustworthy and human-gated.

## Priority

Should

## Acceptance Criteria

- [ ] Given a doc with `sources:`, when the staleness check runs, then it compares
  each source's last-changed commit against the doc's approval commit and marks
  drifted docs suspect (deterministic). *(FR-5, AC5)*
- [ ] Given a source change, when it lands, then per-doc suspect flagging is
  triggered and the dashboard surfaces per-doc freshness (replacing the coarse
  whole-KB badge). *(FR-6, AC5)*
- [ ] Given a suspect doc, when freshness runs, then it auto-detects/flags but never
  auto-applies — the update remains human-gated. *(FR-7)*

> Cross-cutting note: depends on the `sources:` primitive (f001). The staleness
> check is deterministic and CI-able (FR-23 / NFR-3).

---

## Technical Specification

> Methodology/tooling feature. This delivers a deterministic **per-doc freshness
> check** (a new canonical KB script) plus the **dashboard surfacing** of its result in
> the two existing readers — it is not application code. "Components" below are a shipped
> bash script, the Python/Node dashboard readers, a canonical test suite, and CI gates.
> Every claim is grounded against the files cited inline. Genuine unknowns are called out
> as **[SPIKE]** rather than guessed.

### Overview

This feature closes the KB freshness loop at **per-document** granularity (FR-5/6/7,
S2/S8). It consumes the two frontmatter primitives f001 provides — `sources:` (the
files/dirs/URLs a doc summarizes) and `approved_at_commit:` (the git SHA the doc was last
approved at) — and delivers three things:

1. **A deterministic staleness check** — a new shipped bash script,
   `canonical/aid/scripts/kb/kb-freshness-check.sh`, that for each KB doc compares each
   `sources:` entry's last-changed commit against the doc's `approved_at_commit:` and
   classifies the doc **current / suspect / unknown**. Git-only, ASCII, byte-reproducible.
2. **On-demand change-triggered flagging** — the check is invoked by a CLI surface and by
   the dashboard readers; it **auto-detects and flags, never auto-applies** (O3, FR-7). It
   never runs discovery or mutates the KB. Its per-doc verdicts are the shared signal that
   `aid-update-kb` (f008) and `aid-housekeep` (f010) *consume* (reference only here).
3. **Per-doc dashboard surfacing in both readers** — `dashboard/reader/derivation.py`
   (Python) and `dashboard/server/reader.mjs` (Node) gain a **per-doc freshness** read
   that **replaces** today's single coarse whole-KB badge (the existing `git_freshness_check`
   / FF-A2, derivation.py line 107) with per-doc **suspect markers** (FR-6), kept at byte-
   parity between the two twins. Minimal dashboard change (O5).

Confirmed design decisions this spec builds on (user-approved; not re-litigated): the
check is a deterministic `kb-freshness-check.sh`; flagging is on-demand (reader + CLI),
auto-detect/flag never auto-apply; both readers surface per-doc freshness for parity;
`approved_at_commit:` absence degrades to **unknown / pre-migration**, never *suspect*.

**Boundaries (what this feature does NOT do).** f001 *provides* `sources:` /
`approved_at_commit:` (consumed, not redefined here). `aid-update-kb` (f008) and
`aid-housekeep` (f010) *consume* the suspect verdicts to scope their work (FR-33) — built
there, referenced here. The migration that stamps `approved_at_commit:` onto AID's own
existing docs is **f011**; until it lands, every AID doc is `unknown` (degrade-gracefully,
not a failure — see Absence / Degrade). This feature adds **no runtime dependency** (git +
coreutils for the script; the existing Python/Node runtimes for the readers).

### The staleness-check script — `kb-freshness-check.sh`

**Canonical home.** `canonical/aid/scripts/kb/kb-freshness-check.sh`, alongside the
existing `build-kb-index.sh` / `build-metrics.sh` (confirmed dir listing). It renders to
the five host trees via `run_generator.py` (canonical→render, C3) and vendors into the
install bundles like its siblings — therefore it is a **shipped** script and **ASCII-only**
applies (C2/Q2; bash, so PS-5.1 is N/A). It must be added to the `test-ascii-only.sh`
allow-list (see Constraints).

**Inputs / invocation.**

```
kb-freshness-check.sh --root <kb-root> [--repo <repo-root>] [--format text|tsv]
                      [--doc <relpath>]      # optional: check a single doc
```

- `--root` — the KB directory (default `.aid/knowledge/`); the docs to check.
- `--repo` — the git repo root the `sources:` paths are relative to (default: the repo
  containing `--root`, via `git -C <root> rev-parse --show-toplevel`). `sources:` paths are
  **repo-relative** per the f001 schema, so they resolve against `--repo`, not `--root`.
- `--format` — `text` (human, default) or `tsv` (machine; one row per doc, the readers'
  parse target). Default deterministic ordering: docs `sort`ed by path (matches
  `build-kb-index.sh` line 150).

**Algorithm (per KB doc).** For each `*.md` under `--root` that is a `source:
hand-authored` primary/extension doc (skip `meta`, `source: generated`, `INDEX.md`,
`README.md`, `STATE.md` — same routing as `build-kb-index.sh` / the f001 lint):

1. **Read frontmatter** `sources:` (f001 `extract_list`) and `approved_at_commit:`
   (f001 `extract_field`, single-line scalar) from the doc's YAML block.
2. **Absence gate (degrade-gracefully).** If `approved_at_commit:` is absent or empty →
   doc = **unknown** (pre-migration; the f011 stamp has not landed). Emit and move on —
   **never** classify it *suspect* on a missing baseline (FR-7 spirit; matches the f001
   "absence is valid" contract). If `sources:` is absent or `[]` (a pure-synthesis/glossary
   doc) → doc = **current** (nothing to drift against; no source can post-date the baseline).
3. **Per-source last-changed commit.** For each entry in `sources:`:
   - **URL** (matches `^[a-z][a-z0-9+.-]*://`) → cannot `git log` a URL → contributes
     **unknown** to this doc (skipped from the comparison; recorded so the verdict is
     honest). A doc whose comparable sources are all URLs and that has a valid
     `approved_at_commit:` is **unknown** (we cannot prove current or suspect).
   - **Path or glob** (repo-relative) → run, from `--repo`:
     `git log -1 --format=%H -- <entry>` (pathspec; a glob/dir is a valid git pathspec, so
     globs and directories resolve natively — no shell glob expansion needed). This yields
     the **last commit that touched any file under that path/glob**. Empty output (path
     never existed in history, or is untracked) → that source contributes **unknown**.
4. **Compare.** For each path/glob source that produced a commit `C_src`, decide whether
   `C_src` is an **ancestor of** `approved_at_commit:` (`A`). The deterministic test is
   `git merge-base --is-ancestor <C_src> <A>` (exit 0 = ancestor/equal = the source change
   is already baked into the approval baseline → that source is **current**; exit 1 = NOT
   an ancestor = the source changed *after* approval → that source made the doc
   **suspect**). This is the precise "changed after `approved_at_commit:`" comparison FR-5
   requires — **commit-graph ancestry, not timestamp** (rebases/cherry-picks/clock skew
   make `%cI` date compares unreliable; ancestry is exact and deterministic). Any other
   `merge-base` exit (e.g. `A` itself unknown to git, code 128) → that source contributes
   **unknown**, never a false *suspect*.
5. **Per-doc verdict (fold rule).**
   - **suspect** — if **any** source is `suspect` (any source changed after the baseline).
     This is the headline signal (FR-5: "if any source changed after `approved_at_commit:`
     → suspect").
   - **current** — else if **at least one** source is `current` and **no** source is
     `suspect` (all comparable sources are at-or-before the baseline).
   - **unknown** — else (no comparable source produced a verdict: all sources were URLs /
     untracked / unresolvable, or `approved_at_commit:` itself is absent/unknown to git).

**Output format.** `--format tsv`, one row per doc, tab-separated, stable column order:

```
<doc-relpath>\t<verdict>\t<approved_at_commit>\t<n_current>\t<n_suspect>\t<n_unknown>\t<suspect_sources_csv>
```

`verdict` ∈ `{current, suspect, unknown}`. `suspect_sources_csv` lists the `sources:`
entries that drifted (empty unless `verdict=suspect`) so the dashboard and CLI can name
*which* source made the doc suspect. `text` format is the same data, human-formatted. The
script writes to stdout only (no file writes — read-only, NFR-6/O3). Exit code: `0` always
on a successful scan (the verdicts are data, not a gate); `1` arg error; `2` I/O error
(mirrors `build-kb-index.sh`). A non-zero scan exit is reserved for malfunction, never for
"a doc is suspect" — suspect is a normal, expected verdict, not an error (auto-flag, not
auto-fail).

**Determinism (NFR-3, C5).** Pure git plumbing (`rev-parse`, `log -1 --format=%H`,
`merge-base --is-ancestor`) + coreutils text handling; doc list `sort`ed; no LLM, no
network, no clock dependence (ancestry, not dates). Byte-reproducible: same repo state +
same frontmatter → identical TSV. Fully CI-assertable against fixtures.

### Change-triggered flagging (on-demand; auto-detect/flag, never auto-apply)

**On-demand, not a daemon (FR-6/FR-7, O3, C4).** "Source changes MUST *trigger* per-doc
suspect flagging" is satisfied by **re-evaluation on read**, not by a watcher or a
post-commit hook: because the verdict is a pure function of (current commit graph + each
doc's frontmatter), every fresh invocation of `kb-freshness-check.sh` *already reflects*
the latest source changes. The two on-demand surfaces:

1. **CLI surface.** A doc owner / `aid-housekeep` / `aid-update-kb` runs
   `kb-freshness-check.sh` directly (or via a thin skill wrapper added in f008/f010) to get
   the current per-doc verdict table. This is the deterministic, scriptable entry point.
2. **Dashboard reader surface.** Each reader invokes the same logic on every repo read (see
   next section), so opening the dashboard re-flags drift with no human memory required —
   exactly the "no trigger" hole P5 calls out, closed.

**Never auto-apply (FR-7, O3, C4, NFR-6).** The script and the readers only **classify and
display**. They do **not**: run `aid-discover`/`aid-update-kb`, edit any KB doc, write
`approved_at_commit:`, or touch `kb_baseline`. Every change to KB content stays human-gated.
The only state the check produces is the in-memory/stdout verdict; nothing is persisted by
this feature (consistent with the readers' existing NFR2 "derived, never written to disk").

**Who consumes the flags (reference only — NOT built here).**

- **`aid-update-kb` (f008)** — prompt-driven targeted updates; uses the per-doc suspect
  verdict as the shared signal to scope *which* doc a finished work's delta touched (FR-33).
- **`aid-housekeep` (f010)** — whole-KB source-driven reconcile; uses the same per-doc
  staleness output to scope its sweep to suspect docs rather than re-judging the whole KB
  (FR-33: "per-doc staleness (FR-5) is the shared signal"). The dashboard "outdated"→suspect
  refresh prompt already points users at `/aid-housekeep` (home.html line 1730) — that copy
  is updated to per-doc language here (see UI surface).

This feature delivers the **producer** (the check + its two on-demand surfaces); f008/f010
are the **consumers**, and the FR-33 boundary between them is theirs to enforce.

### Dashboard surfacing (both readers — parity)

**What changes: whole-KB FF-A2 → per-doc.** Today both readers derive a single coarse KB
status whose `outdated` state is decided by `git_freshness_check` (derivation.py line 107 /
reader.mjs line 581): one `git log -1 --format=%cI <default-branch>` compared against the
whole-KB `kb_baseline.tip_date` from `.aid/settings.yml` (the single stamp;
`settings.yml` lines 84-86). That whole-KB tip-date judgment is the coarse badge FR-6
replaces. This feature **adds a per-doc freshness read** and surfaces per-doc **suspect**
markers; it does **not** rip out FF-A2 (the 5-state `KbStatus` waterfall and its `outdated`
state stay — see Coexistence), it **augments** it with the finer per-doc signal that FR-6
asks the dashboard to surface.

**New reader output field.** Each reader gains a per-doc freshness projection attached to
`kb_state` (the `KbStateRef` model, models.py line 138 / reader.mjs `_buildKbStateRef`
line 3026). Proposed shape (additive; existing fields untouched for back-compat):

```
kb_state.doc_freshness = [
  { doc: "architecture.md", verdict: "suspect", suspect_sources: ["canonical/..."] },
  { doc: "schemas.md",      verdict: "current", suspect_sources: [] },
  { doc: "domain-glossary.md", verdict: "unknown", suspect_sources: [] },
  ...
]
kb_state.suspect_count = <int>   # convenience rollup for the badge
```

**How each reader computes it (parity).** The readers already own a read-only, fixed-argv,
2s-bounded git-subprocess pattern whose **results are byte-parity'd across the twins** —
Python `_run_git_log` (derivation.py line 190) and Node `runGitCommand`/`runGitLog`
(reader.mjs line 525/574), both routed through `_resolve_git_branch`/`resolveGitBranch`.
The two runtimes do **not** share a guard mechanism: the Python side gates verbs through an
`_GIT_ALLOWED_VERBS` allowlist (derivation.py line 101), whereas the Node `runGitCommand`
(reader.mjs line 525) carries **no verb allowlist** — both are nonetheless confined to the
same fixed, read-only argv this feature constructs. The **parity contract is over the
output `doc_freshness` arrays / per-doc verdict** (byte-identical results), not over a
shared allowlist. This feature adds a parallel **per-doc** function in each, reusing that
exact subprocess discipline:

- **Python** — add `derive_doc_freshness(kb_dir, repo_root) -> list[DocFreshness]` to
  `dashboard/reader/derivation.py`, beside `git_freshness_check`. It enumerates the same
  hand-authored docs, reads each doc's `sources:` + `approved_at_commit:` (a small
  frontmatter scan added to `parsers.py`, mirroring its existing tolerant line-scans), and
  runs the **same two git verbs the script uses** — `git -C <repo> log -1 --format=%H --
  <src>` and `git -C <repo> merge-base --is-ancestor <C_src> <A>` — through the existing
  bounded-subprocess helper. `merge-base` is added to the **Python-only** `_GIT_ALLOWED_VERBS`
  guard (derivation.py line 101; still read-only — `merge-base` never mutates; the Node twin
  has no such allowlist, so it needs no parallel edit). Same degrade-to-`unknown` matrix
  as the script (any git failure on a source → `unknown`, never a false `suspect`; matches
  the existing "every failure → skip → stay approved" posture).
- **Node** — add the **byte-parity twin** `deriveDocFreshness(kbDir, repoRoot)` to
  `dashboard/server/reader.mjs`, beside `gitFreshnessCheck`, using `runGitCommand` for the
  identical argv (`["-C", repo, "log", "-1", "--format=%H", "--", src]` and
  `["-C", repo, "merge-base", "--is-ancestor", cSrc, a]`). The two implementations MUST
  produce **identical** `doc_freshness` arrays for the same repo state — this is the
  reader-parity contract the existing twin tests already enforce for `git_freshness_check`
  (the dashboard parity suite), extended to the new field.

**Parity verification.** The existing reader-parity test harness (which serializes both
readers' `RepoModel` and diffs them) is extended with a fixture KB containing one
`current`, one `suspect`, one `unknown` (URL-source), and one pre-migration
(no-`approved_at_commit:`) doc; the Python and Node `doc_freshness` arrays must be
byte-identical. This is the parity gate for FR-6.

**Single source of truth (script vs reader logic).** The reader functions and the
`kb-freshness-check.sh` script implement the **same algorithm** (same git verbs, same fold
rule, same degrade matrix) so a doc's verdict is identical whether seen on the CLI or the
dashboard. The script is the canonical specification of the algorithm; the readers are its
in-runtime twins (the readers cannot shell out to the bundled script reliably across the
five host trees and the two server runtimes, so they re-implement the same fixed git calls
— the same pattern already used for FF-A2, which is duplicated script-free in both readers).
The canonical test suite asserts the script and a golden fixture agree; the parity suite
asserts the two readers agree; together they pin all three to one verdict.

**Minimal UI surface (O5).** The per-doc signal surfaces in the existing per-repo KB card
in `dashboard/home.html` (`_renderKbCard`, line 1589) — **no new page, no redesign**:

- When `kb_state.suspect_count > 0`, the KB card shows a **per-doc suspect marker** — a
  small `badge badge-warn` reading `N doc(s) suspect` (reusing the existing warn-badge
  style already used for the whole-KB "Outdated" state, line 1700), with the suspect doc
  names listed in the card meta (and, where present, *which source* drifted, from
  `suspect_sources`). This is the actionable per-doc signal FR-6 / the doc-owner story asks
  for ("which doc my change made suspect").
- The existing whole-KB "Outdated" refresh prompt copy (line 1730) is updated to per-doc
  language ("N doc(s) are suspect — run /aid-housekeep to reconcile the affected docs"),
  keeping the `/aid-housekeep` call-to-action (which f010 consumes).
- `home.html` reads `kb_state.doc_freshness` / `suspect_count` **literally** (the same
  "never re-derive client-side" rule already stated at line 1584); the readers do all
  derivation. The multi-repo CLI home (`index.html`) only shows a coarse "KB" chip
  (line 867) and is **not** changed (O5 — minimal; per-doc detail belongs on the per-repo
  card).

### Absence / degrade handling

| Condition | Verdict | Rationale |
|-----------|---------|-----------|
| `approved_at_commit:` absent/empty (pre-migration doc, f011 not yet run) | **unknown** | Degrade-gracefully (FR-7 spirit, f001 "absence is valid"). Never *suspect* on a missing baseline — that would red the whole un-migrated KB. Reuses f001's degrade pattern. |
| `sources:` absent or `[]` (pure-synthesis/glossary doc) | **current** | No source can post-date the baseline; nothing to drift against. |
| A `sources:` entry is a **URL** | source → unknown | Cannot `git log` a URL; recorded as unknown, excluded from the suspect/current decision. A doc with only URL sources → doc **unknown**. |
| A `sources:` path/glob is **untracked / never in git history** | source → unknown | `git log` empty output → no comparable commit; contributes unknown, never a false suspect. |
| `approved_at_commit:` present but **unknown to git** (bad/abandoned SHA) | source → unknown (doc → unknown) | `merge-base` exit 128 → degrade to unknown, never suspect. |
| git binary absent / timeout / non-repo | all → unknown (reader stays on its existing FF-A2 `skip`→approved degrade) | Same bounded-subprocess degrade matrix the readers already use (every failure → safe default). |

The whole-KB FF-A2 path keeps its own existing degrade ("skip → stay approved", DD-A2
7-mode matrix) unchanged; the new per-doc path degrades to **unknown** independently, so a
git failure can never manufacture a false *suspect* (the conservative direction for a
human-gated signal).

### Affected components

| Component | Path | Change |
|-----------|------|--------|
| **NEW** freshness check | `canonical/aid/scripts/kb/kb-freshness-check.sh` | The deterministic per-doc staleness script (algorithm above). ASCII-only bash; git + coreutils only; `--format text|tsv`; read-only. |
| Python reader — derivation | `dashboard/reader/derivation.py` | Add `derive_doc_freshness(kb_dir, repo_root)`; add `merge-base` to `_GIT_ALLOWED_VERBS` (still read-only); reuse `_run_git_log`/bounded-subprocess pattern. FF-A2 `git_freshness_check` retained (coexists). |
| Python reader — parsers/models | `dashboard/reader/parsers.py`, `dashboard/reader/models.py` | Add a per-doc `sources:`/`approved_at_commit:` frontmatter scan; add `DocFreshness` model + `KbStateRef.doc_freshness` / `suspect_count` fields (additive, default empty). |
| Python reader — wiring | `dashboard/reader/reader.py` | Call `derive_doc_freshness` after `derive_kb_status` (line ~402) and attach to `kb_state`. |
| Node reader (twin) | `dashboard/server/reader.mjs` | Add `deriveDocFreshness(kbDir, repoRoot)` (byte-parity twin) + the per-doc frontmatter scan; attach `doc_freshness`/`suspect_count` in `_buildKbStateRef` (line 3026) and the read pipeline (line ~1790). Identical argv to the Python twin. |
| Dashboard UI | `dashboard/home.html` | `_renderKbCard` (line 1589): when `suspect_count > 0`, render the per-doc suspect `badge badge-warn` + suspect doc/source list; update the refresh-prompt copy (line 1730) to per-doc language. Minimal (O5). `index.html` unchanged. |
| **NEW** canonical test suite | `tests/canonical/test-kb-freshness-check.sh` | Asserts the script's verdicts on fixtures: a doc whose source changed after `approved_at_commit:` → **suspect**; a doc at-or-before baseline → **current**; a URL-source / pre-migration / untracked-source doc → **unknown**; deterministic TSV byte-stability on re-run. Auto-discovered by `tests/run-all.sh` glob (`tests/canonical/test-*.sh`). |
| CI — ascii-only | `tests/canonical/test-ascii-only.sh` | Add `kb-freshness-check.sh` to the ASCII allow-list (it is a shipped KB script; C2). |
| CI — reader parity | the existing dashboard reader-parity suite | Extend the parity fixture + assertion to cover `doc_freshness` (Python ≡ Node). |
| render-drift | `test.yml` job `render-drift` | No edit; stays green by running `run_generator.py` after the canonical script lands (regenerate all 5 profiles; never hand-edit a rendered copy — C3, render-drift-full-generator precedent). |

### Constraints

- **NFR-3 / C5 — deterministic, git-only.** The check is pure git plumbing
  (`log -1 --format=%H`, `merge-base --is-ancestor`, `rev-parse`) + coreutils, doc list
  `sort`ed, ancestry-based (no clock dependence). No LLM, no network. CI-assertable against
  fixtures. The two reader twins reuse their existing byte-parity'd subprocess discipline.
- **C2 — ASCII-only.** `kb-freshness-check.sh` vendors into the install bundles → ASCII-only
  (bash; PS-5.1 N/A); added to `test-ascii-only.sh` allow-list. The `.mjs` reader is already
  ASCII-posture (reader.mjs header). **[SPIKE: confirm the sibling `build-kb-index.sh` /
  `build-metrics.sh` are already on the ascii allow-list; if the allow-list is opt-in and
  these are absent, add the new script and verify it does not newly fail — same gap f001
  flagged for build-kb-index.sh.]**
- **NFR-8 / C1 — no new runtime.** Script: git + bash + coreutils (the toolset
  `build-kb-index.sh` already uses). Readers: the *existing* Python 3.11+ stdlib /
  Node-built-in runtimes — `merge-base` is a new git *verb*, not a new dependency. No
  embedding model, binary, MCP, or `python3`/`pwsh` escalation.
- **NFR-6 / O3 / C4 — human-gated.** Auto-detect/flag only. No KB write, no
  `approved_at_commit:` write, no discovery/update trigger. Detection is automatic and
  visible; every content change stays human-gated.
- **O5 — minimal dashboard.** One additive reader field + one per-doc badge/marker on the
  existing KB card; no new page, no redesign, no change to `index.html`.
- **C3 / NFR-4 — canonical→render green.** Author the script in `canonical/` only; run
  `run_generator.py`; commit the regenerated `profiles/`. The dashboard reader/HTML files
  live under `dashboard/` (not canonical-rendered — they are the source tree the install
  bundles vendor), edited in place with their own CI (reader-parity + dashboard tests).

### Coexistence with FF-A2 (whole-KB badge)

FR-6 says the per-doc surfacing *replaces* the coarse whole-KB badge. The minimal,
back-compatible reading (O5): the per-doc **suspect** marker becomes the primary freshness
signal on the KB card, while the existing 5-state `KbStatus` waterfall (pending /
generating / preparing / approved / outdated) and its `kb_baseline`-driven `outdated` state
are **retained** as the coarse rollup (they also gate clickability and the summary
lifecycle, derivation.py `derive_kb_status` — out of scope to redesign). In effect: the
whole-KB `outdated` badge is **superseded for the freshness story** by the per-doc suspect
marker (which is finer and actionable), but FF-A2 is not deleted because it carries
non-freshness state too. **[SPIKE: confirm with the plan whether FR-6 "replacing" mandates
hard-removing the whole-KB `outdated` state from the card, or augmenting it with per-doc
markers as specified here. The spec assumes augment-and-supersede (minimal, O5-aligned);
a hard removal would also touch `derive_kb_status` and the `kb_baseline` plumbing, which is
a larger change than O5 invites.]**

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-1] FR-6 "replacing" semantics.** Does the per-doc surfacing **hard-remove** the
  whole-KB FF-A2 `outdated` badge, or **augment/supersede** it (this spec's assumption,
  minimal per O5)? Confirm with the delivery plan; a hard removal enlarges the dashboard
  change beyond O5.
- **[SPIKE-2] f001 dependency ordering.** This feature consumes f001's `sources:` +
  `approved_at_commit:` fields and its `extract_list`/`extract_field` parser primitives. It
  cannot ship before f001 lands those fields + plumbing. Confirm f001 precedes f007 in the
  delivery sequence (it is a hard dependency, not a soft one).
- **[SPIKE-3] Reader frontmatter scan vs script.** The readers re-implement a small
  `sources:`/`approved_at_commit:` frontmatter scan (they cannot reliably shell out to the
  bundled script across 5 host trees + 2 runtimes — same script-free duplication FF-A2 uses).
  Confirm the parity suite is the agreed mechanism to keep script ≡ Python-reader ≡
  Node-reader on one verdict (rather than a shell-out). The spec assumes re-implementation +
  parity tests.
- **[SPIKE-4] `merge-base --is-ancestor` availability.** Requires git ≥ 1.8.0 (2012);
  universally present on supported boxes, but confirm no bare-box target ships an older git.
  Fallback if ever needed: `git rev-list --count <A>..<C_src>` (>0 ⇒ source after baseline)
  — same ancestry semantics, slightly costlier. The spec uses `--is-ancestor` as primary.

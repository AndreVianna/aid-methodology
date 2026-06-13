# KB Dashboard (Independent Knowledge-Base View)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Feature identified from REQUIREMENTS.md §5 FR15 | /aid-interview |
| 2026-06-12 | **RE-SCOPED for the two-level re-architecture** (charter only). The original "build a fuller-detail `KbModel` dashboard from scratch behind the KB card" is **superseded**: this feature now serves the **relocated `kb.html`** (the aid-summarize output, FR31), drives a **5-state KB card** (FR32), gains the **reader KB-status + cross-runtime git read** (FR35), and owns the **producer chain** (aid-summarize relocation, discover→summarize auto-trigger FR34, aid-housekeep outdated-resolution FR36). The Technical Specification below (the rich-`KbModel` build) is the historical record and does **not** describe the re-scoped slice — see "Re-architecture Re-scope" immediately below. | /aid-interview |
| 2026-06-12 | **SPEC-COMPLETE (re-scope Technical, gate pending).** Added "## Re-architecture Re-scope (Technical)" — the authoritative spec for the re-scoped slice: DM-A (extended `KbStateRef` `{status, summary_present, kb_baseline}` + the `/aid-config`-owned `.aid/settings.yml kb_baseline` key; **NO `schema_version` bump** — the simplification vs the dropped rich `KbModel`), FF-A (discover→summarize auto-trigger chain FR34; per-poll read-only cross-runtime git-read freshness FR35 + graceful-degradation matrix; the 5-state derivation waterfall FR32), LC-A (reader KB-status extension + git read; aid-summarize/discover/housekeep producer changes + /aid-config schema), UI-A (5-state card), SEC-A (read-only git/no-LLM/no-traversal + serving via feature-010), PR-A (canonical → FULL run_generator.py → dogfood). DD-A1..A4 (static-snapshot vs live; git-read mechanism+degradation; status precedence; `kb_baseline` schema ownership). The historical Technical Specification is marked **SUPERSEDED**. | /aid-specify |

## Re-architecture Re-scope (2026-06-12)

> _The original feature-007 (Technical Specification below) was **never delivered** — it was grouped
> into the not-yet-executed delivery-005 (tasks 030–037, Pending). Its plan was to grow feature-002's
> thin `KbStateRef` into a rich client-rendered `KbModel` dashboard. The two-level re-architecture
> **replaces that approach**: the KB summary is now a **pre-rendered HTML page** (`kb.html`) produced
> by `aid-summarize` and simply **served**, so the reader's KB job shrinks to **status derivation +
> freshness**, not a fuller-detail model. This is **much smaller than build-from-scratch.**_

**Status: RE-SCOPED — charter.** The re-scoped feature is:

1. **Serve the relocated `kb.html`** (FR31). `aid-summarize` writes its summary to
   `<repo>/.aid/dashboard/kb.html` (moved from `.aid/knowledge/knowledge-summary.html`); feature-010's
   server serves it; the KB card opens it. Visual family unchanged (NFR8). No rich `KbModel`, no new
   `schema_version` bump for a fuller model — the page **is** the detail.
2. **5-state KB card (reader-derived)** (FR32): **pending → generating → preparing → approved →
   outdated**, computed read-only by feature-002's reader from `.aid/knowledge/STATE.md` (discovery/
   summarize state), `kb.html` presence + approval, and the git baseline (FR35). Only **approved** /
   **outdated** are clickable; **outdated** opens the stale page + a refresh prompt.
3. **Reader KB-status + cross-runtime default-branch git read** (FR35): a cheap, read-only,
   **Python + Node byte-identical** git read of the default branch's latest-commit date, compared to
   the `.aid/settings.yml` baseline, **degrading gracefully** (not a git repo / no `main`|`master` /
   detached / git absent ⇒ skip, stay `approved`), run **per registered repo**. **Settings-schema note:**
   this baseline is a **new key in the per-repo `.aid/settings.yml` schema owned by `/aid-config`** (e.g.
   `kb_baseline: {branch, tip_date}`) — written by `aid-discover`/`aid-housekeep` (FR36), read by the
   reader. A small, additive producer-side schema addition (no existing key changes), captured for
   /aid-specify; no new open question.
4. **Producer chain** (FR34, FR36): **`aid-summarize`** writes to `.aid/dashboard/kb.html`;
   **`aid-discover`** auto-triggers `aid-summarize` at its close (FR34) **and** records the
   default-branch baseline (FR35); **`aid-housekeep`** (KB-DELTA) regenerates the summary, **resolves
   `outdated`**, and re-stamps the baseline. All dogfood-rendered via the FULL `run_generator.py` (C7).
   Most of these edits are behavior-additive (path relocation, baseline record/resolve). **The one
   deliberate exception is the FR34 auto-trigger:** it is an **intended NEW closing behavior** of
   `aid-discover` (it now produces `kb.html`), **not** a C4 behavior-preserving change — it composes the
   two existing approval gates (discovery KB approval + summarize V1) rather than replacing either, but
   the added auto-invocation + new output is by design (see REQUIREMENTS.md FR34 / C7).

**Owned requirements (re-scoped):** FR31 (kb.html relocation), FR32 (5-state card), FR34 (discover→
summarize chain), FR35 (KB freshness baseline + reader git read), FR36 (the **aid-summarize /
aid-discover / aid-housekeep** portion; the `bin/aid` portion is feature-010). Carries the spirit of
FR15 (KB is reachable as its own view) but **delivers it via served HTML, not a client-rendered
model**. NFR2/NFR7 (read-only / no-LLM reader), NFR8 (summary visual family), C7 (dogfood-rendered
producers — mostly behavior-additive; FR34's discover→summarize auto-trigger is the deliberate new
closing behavior, not C4-preserving).

**Priority (re-scoped):** Should (part of the two-level refactor, but the KB tier ships after the
machine + per-repo spine; see the delivery-split recommendation in PLAN.md notes).

**Net delta vs original:** the rich `KbModel` / `schema_version 1→2` build (Technical Specification
below) is **dropped**; replaced by serve-`kb.html` + a 5-state derived card + a graceful git read +
the producer chain. Substantially smaller.

---

## Re-architecture Re-scope (Technical)

> Added by `/aid-specify` (2026-06-12). **This section is the authoritative technical spec for
> feature-007 as re-scoped** — it supersedes the historical "Technical Specification (SUPERSEDED)" body
> further below (the rich-`KbModel` build). Cross-references: feature-010 (multi-repo server: serves
> `/r/<id>/kb.html` + `/api/home`, the `<id>` addressing, CAN-1, NFR9/NFR10 graceful posture);
> feature-002 (the reader + `KbStateRef` this extends, `dashboard/reader/models.py` +
> `parsers.py:parse_kb_state`); feature-006 revision (hosts the KB card slot, links to `/r/<id>/kb.html`);
> feature-003 (the per-repo `/api/model` envelope + PT-1 cross-runtime parity harness this extends).
>
> Activated sections (per `canonical/templates/specs/spec-template.md`):
> - **Data Model** (DM-A) — the extended `KbStateRef` `{status, summary_present, kb_baseline}` served at
>   `model.repo.kb_state`, and the new **`.aid/settings.yml` `kb_baseline` key** (owned by `/aid-config`).
> - **Feature Flow** (FF-A) — the discover→summarize auto-trigger chain (FR34), the per-poll
>   freshness/git-read cycle (FR35), and the 5-state card-status derivation (FR32).
> - **Layers & Components** (LC-A) — the feature-002 reader KB-status extension + the cross-runtime git
>   read; the `aid-summarize`/`aid-discover`/`aid-housekeep` producer changes; the KB card (front-end,
>   hosted by feature-006).
> - **UI Specs** (UI-A) — the 5-state KB card (color+shape per FR8/NFR8, clickability + outdated refresh
>   prompt per FR32).
> - **Security Specs** (SEC-A) — the git read is read-only / no-traversal / no-LLM; serving is via
>   feature-010's already-scoped multi-repo server (NFR2/NFR7/C6/C7).
> - **Producer-skill changes** (PR-A) — the canonical → FULL `run_generator.py` → profiles/ + `.claude/`
>   dogfood-render story for the three KB-domain producers (C7).
>
> **Conditional sections justified-skipped:** **API Contracts** (no new endpoint or wire-shape change —
> `kb_state` stays a strict superset at the same `/api/model` path, *no* `schema_version` bump; the only
> serving surface is feature-010's `/r/<id>/kb.html`, owned there, not re-specified). **State Machines**
> (the 5 statuses are a derived *display* projection of existing on-disk signals — read literally per
> poll, not a lifecycle the dashboard owns or transitions; the derivation precedence is specified under
> FF-A3, which is sufficient — there is no stored state machine here). **Migration Plan** (the
> `aid-summarize` output **relocation** `.aid/knowledge/knowledge-summary.html` → `.aid/dashboard/kb.html`
> is a producer path change, not a data migration; an existing repo simply regenerates to the new path on
> the next summarize/discover run, and the reader treats an absent `kb.html` as `summary_present=false`
> → `preparing`/`pending`, never an error — graceful, no migration script).
> **[SUPERSEDED by Option-1 producer-run migration — see `.aid/work-001-aid-dashboard/design/kb-summary-migration-plan.md`.]**
> The justified-skip assumption above (next summarize repopulates) was incorrect: regeneration is
> expensive, only fires on user trigger, and leaves upgraded repos stuck at `preparing`. The
> producer-run migration (FR31 step 6 in PREFLIGHT + belt-and-suspenders in SUMMARY-DELTA) now
> performs a cheap `mv` on the next `/aid-summarize` or `/aid-housekeep` run instead. **Data-DB / Cache / Batch /
> Mobile / Search / AI / Cloud / Hardware / Events / DDD / CQRS / Telemetry / Recovery / External
> Integrations** (not applicable — AID ships no database, no third-party deps; the git read is a
> stdlib/built-in subprocess, not an external integration; runtime is deterministic no-LLM code).
> **BDD Scenarios** (the Acceptance Criteria + the FF-A walkthroughs + the byte-parity test obligation
> express the behavioral contract concretely; a Gherkin layer would only restate them).

The re-scoped feature is **four coordinated pieces** over an already-delivered spine: (1) `aid-summarize`
relocates its output to `<repo>/.aid/dashboard/kb.html` (FR31); (2) feature-002's reader gains a 5-state
KB `status` + a `summary_present` flag + a cross-runtime default-branch git read (FR32/FR35); (3)
`aid-discover` auto-triggers `aid-summarize` at its close and records the KB baseline (FR34/FR35); (4)
`aid-housekeep` (KB-DELTA → SUMMARY-DELTA) resolves `outdated` and re-stamps the baseline (FR36). The KB
**card** itself is a small front-end render hosted on feature-006's `home.html`; the KB **page** is the
served `kb.html`. Everything at runtime is **read-only** (NFR2/NFR9) and **no-LLM** (NFR7) — the new git
read is a read-only `git log` shell-out that degrades gracefully and never writes or infers.

### DD-A (Design Decisions worth user attention)

| ID | Decision | Rationale / alternatives rejected |
|----|----------|-----------------------------------|
| **DD-A1** | **The KB view is a STATIC pre-rendered snapshot (`kb.html`), not a live client-rendered model.** `aid-summarize` produces a self-contained `kb.html` once (at its V1 visual-approval gate); the dashboard merely **serves** it and **flags freshness** via the card. | The original feature-007 grew a live `KbModel` re-rendered every ~5s poll (rich doc inventory + INDEX-freshness proxy). That is **dropped**. A static snapshot is correct because the KB summary is **expensive to assemble** (Mermaid inlining, ~MB self-contained HTML) and changes only at discover/housekeep boundaries — re-deriving it per poll wastes work (NFR4) and re-implements a renderer the producer already owns. The cost (the snapshot can go stale) is **exactly** what the `outdated` state (DD-A2) surfaces: the card flags staleness live; the page itself need not be live. This also keeps the reader's job tiny (status + a git date), preserving the no-LLM/read-only posture structurally. |
| **DD-A2** | **Freshness via a cheap, read-only, cross-runtime `git log` of the default branch tip date vs a stored `kb_baseline`, degrading gracefully to `approved`.** The reader runs one bounded `git log -1 --format=%cI <branch>` per registered repo and compares to `.aid/settings.yml kb_baseline.tip_date`. | A file-mtime or per-doc hash heuristic was rejected: the user's mental model is "the KB reflects the branch as of a commit" (FR35), and a commit date is the honest, cheap signal. A live `git` library dep was rejected (zero-third-party-dep posture). The shell-out is **read-only** (`git log`, never `git fetch`/`write`), **bounded** (`-1`), and **degrades to `approved`** on every failure mode (DD-A2 matrix in FF-A2) so it can never error or block — matching feature-010 NFR10's per-repo graceful posture. Python (`subprocess`) and Node (`child_process`) call the **identical** argv, so the parsed date is byte-identical across runtimes (byte-parity, SEC-A). |
| **DD-A3** | **Status-derivation precedence is a fixed waterfall: pending → generating → preparing → approved → outdated, evaluated outermost-first from on-disk signals only.** No signal is inferred; each gate is a literal file/field check. | A naive "latest wins" or grade-based derivation was rejected — the five states are **ordered phases of one lifecycle**, and a deterministic waterfall (FF-A3) makes the card's state a pure function of disk, re-evaluable every poll with no hidden memory (NFR2/NFR7). `outdated` is checked **last and only over `approved`** because a repo cannot be "outdated" before it is "approved"; a not-yet-approved KB is `preparing`/`generating`, not `outdated`. |
| **DD-A4** | **`kb_baseline` is a new `/aid-config`-owned key in the per-repo `.aid/settings.yml` schema; WRITTEN by `aid-discover`/`aid-housekeep`, READ by the reader.** Shape: `kb_baseline: {branch: <default-branch>, tip_date: <ISO-8601 commit date>}`. | The baseline must travel with the repo (handoff portability, §3 / NFR11) and is per-repo config — `.aid/settings.yml` is exactly that file, and `/aid-config` owns its schema (verified: `canonical/templates/settings.yml` + `aid-config/SKILL.md`). It is **additive** (no existing key changes) so it needs no migration and no open question (RE§FR35 schema-ownership note). The registry-level `$AID_HOME/registry.yml` was rejected (machine-scoped, paths-only by design — FR28). `/aid-config` gains the key in its template + validation table; the two **producers** write it (DD-A4 is the schema owner, the producers are the writers). |

### DM-A. Data Model

No relational schema (AID ships no database — `schemas.md`). This re-scope makes **two** additive data
changes and **no** wire-shape break (no `schema_version` bump — DM-A3):

#### DM-A1. Extended `KbStateRef` (feature-002 `models.py`) — `{status, summary_present, kb_baseline}`

The re-scope **extends** feature-002's existing thin `KbStateRef` (at `model.repo.kb_state`,
`dashboard/reader/models.py:105-115`) — it does **not** introduce a new rich model. The three existing
hook fields are **retained verbatim** (feature-006's KB card already reads them); three fields are added:

```
KbStateRef  (model.repo.kb_state — null when .aid/knowledge/ is absent, unchanged)
├─ summary_approved:  bool                 # RETAINED (f-002 DM-3): STATE.md ## Knowledge Summary Status **User Approved:** yes/no
├─ last_summary_date: string | null        # RETAINED (f-002 DM-3): the parenthesized date on that line
├─ doc_count:         int | null           # RETAINED (f-002 DM-3): rows under README ## Completeness
│
├─ status:            KbStatus             # NEW — the FR32 5-state enum (DM-A2); the card's whole reason to exist
├─ summary_present:   bool                 # NEW — stat <repo>/.aid/dashboard/kb.html exists (the served page)
└─ kb_baseline:       KbBaseline | null    # NEW — {branch, tip_date} read from .aid/settings.yml (DM-A4); null if unset/unparseable
```

`KbStatus` is a closed enum **derived** by the reader (FF-A3) — never written to disk, never read from a
file. Members (FR32): **`pending | generating | preparing | approved | outdated`**. Per the feature-002
DM-6 discipline, the reader adds a `unknown` reader-only sentinel for total-switch safety (an
un-derivable combination falls back to `pending`'s non-clickable empty treatment — it never throws).

`KbBaseline` is the parsed projection of the `.aid/settings.yml kb_baseline` block (DM-A4):

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `branch` | string \| null | `kb_baseline.branch` | the default branch the KB reflects (e.g. `master`) |
| `tip_date` | string \| null | `kb_baseline.tip_date` | ISO-8601 commit date of that branch's tip when the KB was last generated/refreshed |

> **All new fields are read-derived; nothing new is persisted by the reader (NFR2).** `summary_present` is
> a `stat`; `kb_baseline` is a tolerant settings line-scan (reusing the `parse_project_name` posture in
> `parsers.py:148`); `status` is computed in `derivation.py` from the other fields + the git read (FF-A2).

#### DM-A2. `status` — the FR32 5-state enum and its rendering contract

| `status` | Meaning (FR32) | Clickable? | Card affordance (UI-A) |
|----------|----------------|------------|------------------------|
| `pending` | no KB yet (`.aid/knowledge/` absent or empty) | no | "No Knowledge Base yet" + hint to run `/aid-discover` |
| `generating` | discovery is building the KB | no | "Building KB…" busy treatment |
| `preparing` | KB approved, summary being generated (`kb.html` not yet produced/approved) | no | "Preparing summary…" busy treatment |
| `approved` | KB **and** `kb.html` ready, current, approved | **yes** → `./kb.html` (location-relative; resolves to `/r/<id>/kb.html`) | normal clickable card, `.badge-ok` "Ready" |
| `outdated` | default branch advanced past `kb_baseline` (FR35) | **yes** → `./kb.html` (location-relative, stale) + refresh prompt | `.badge-warn` "Outdated" + "run `/aid-housekeep`" prompt |

The renderer maps each literal to a badge color+shape (UI-A); an `unknown` sentinel renders as the
non-clickable `pending` empty treatment (never throws — mirrors feature-002 DM-6 / feature-006 UI-3
unknown-literal tolerance).

#### DM-A3. `/api/model` envelope — NO `schema_version` bump (the key simplification vs the superseded body)

Unlike the superseded body (which bumped `schema_version 1→2` for a rich nested `KbModel`), this re-scope
**adds scalar/small fields to the existing `KbStateRef` at the same path** and **does NOT bump
`schema_version`**. Rationale and contained blast radius:

| Impact | Effect | Mitigation |
|--------|--------|------------|
| `schema_version` | **unchanged** — `kb_state` is still a `KbStateRef`, now with three more fields | the front-end's `EXPECTED` is untouched; no stale-assets banner churn |
| feature-006 KB card | reads `status` + `summary_present` (new) and the three retained fields | feature-006 R-3 already specifies the card consumes feature-007's 5-state model — this is the producing side of that contract |
| feature-002 reader | `parse_kb_state` grows to populate `status`/`summary_present`/`kb_baseline` (LC-A1) + a git read (LC-A2) | stays inside the audited read-only/no-LLM reader; the git read is the one new *subprocess*, gated read-only (SEC-A) |
| parity (PT-1 / feature-003 + feature-010 PT-1-H) | the byte-identical-across-runtimes guarantee now covers the new `kb_state` fields | **extend the PT-1 fixture** with a `.aid/knowledge/` + `.aid/dashboard/kb.html` + a `kb_baseline` settings block + a git-state case, so Python and Node emit byte-identical `kb_state`; the git read is normalized/excluded like other timestamp echoes where it cannot be deterministic (SEC-A) |

> **Why no bump is the honest call — reconciling the mixed project precedent (both-sided).** The repo has
> **two** real precedents that look opposite until the rule is stated:
> - **No-bump precedent (`created`, ea40fe7).** feature-006's per-work `created` field was **additive,
>   nullable, and already tolerated** by consumers — it shipped with `schema_version` **unchanged at 3**
>   ("Server/`/api/model`/`schema_version` (still 3) … unchanged except the additive null-safe `created`
>   key — PT-1 byte-parity 15/15").
> - **Bump precedent (feature-009, ac6d0f2).** feature-009 **DID** bump `schema_version` **2→3** while
>   adding the additive `TaskModel` fields `short_name`/`delivery`/`lane`. So "additive ⇒ never bump" is
>   *not* the project rule on its own.
>
> **The reconciling rule (both cases fit it):** an additive **nullable** reader field that consumers
> already tolerate gracefully → **no bump** (the `created` case); a **deliberate, owned schema evolution
> of the producer loop** — feature-009 reconciled the reader to the *real* producer formats and chose to
> stamp that as a new contract revision — → **bump**. feature-009's bump was an intentional contract-
> revision act tied to a producer-format reconciliation, not a mechanical "fields were added" rule.
>
> **Where this re-scope lands:** `KbStateRef`'s additive `status`/`summary_present`/`kb_baseline` are
> **additive + nullable + already tolerated** — feature-006 R-3 consumes them **in lockstep** in the same
> delivery, and a front-end reading an unknown/missing field degrades to its empty treatment (DM-A2's
> `unknown` sentinel). That is the **`created` shape, not the feature-009 shape**: there is no producer-
> format reconciliation here, no deliberate owned schema-revision act — just additive fields a co-revised
> consumer reads. So **no bump** is consistent with `created` and does **not** contradict feature-009
> (whose bump was the deliberate-evolution case, which this is not). (If, at detail, a stricter parity
> gate wants a bump anyway, that is a one-line lockstep change — but the spec's position is: not required.)

#### DM-A4. `.aid/settings.yml` `kb_baseline` key — `/aid-config`-owned schema addition (DD-A4)

A **new additive key** in the per-repo `.aid/settings.yml` schema, whose template + validation are
**owned by `/aid-config`** (`canonical/templates/settings.yml`, `aid-config/SKILL.md`). Shape:

```yaml
# kb_baseline: the git baseline the Knowledge Base reflects (written by aid-discover / aid-housekeep,
# read by the dashboard reader for FR35 outdated-detection). Absent until the first KB generation.
kb_baseline:
  branch: master                       # the default branch the KB was generated/refreshed against
  tip_date: 2026-06-12T14:03:00Z       # ISO-8601 commit date of that branch's tip at generation time
```

- **Writers:** `aid-discover` (on KB approval, FR35) and `aid-housekeep` (KB-DELTA resolution + re-stamp,
  FR36). **Reader:** feature-002's dashboard reader (LC-A1). `/aid-config` **owns the schema** (adds the
  key to its template + its validation table; whether `/aid-config` *surfaces* it interactively is a
  detail-phase nicety — it is producer-written, not user-authored, so a read-only display row suffices).
- **Additive, no migration (DD-A4).** No existing key changes; an absent `kb_baseline` ≡ "no baseline
  recorded" → the reader reads `kb_baseline = null` and the freshness check is **skipped** (stays
  `approved`, FF-A2). Cross-ref feature-010 residual-OQ #5 (the two features' `settings.yml` reads must
  agree on this key) — resolved here: this section is the owning spec; feature-010 only flags it.

### FF-A. Feature Flow

Three runtime cycles: the discover→summarize **chain** (FF-A1, producer-side, one-shot), the per-poll
**freshness git read** (FF-A2, reader-side, read-only), and the per-poll **status derivation** (FF-A3,
reader-side). The card and page are served by feature-010 (cross-ref, not re-specified).

#### FF-A1. Discover → summarize auto-trigger chain (FR34) — the one deliberate new behavior

```
aid-discover [State: DONE]  (canonical/skills/aid-discover/references/state-done.md)
  ... existing: KB meets minimum grade AND **User Approved:** yes  (discovery's OWN approval gate) ...
  RECORD BASELINE (NEW, FR35):
    resolve default branch (DD-A2 detection) + git log -1 --format=%cI <branch>
    write .aid/settings.yml kb_baseline: {branch, tip_date}   (DD-A4; aid-config "append a new block" path
                                                               for a not-yet-present nested section, SKILL.md Step 6
                                                               second idiom @ SKILL.md:126-132 — NOT the single-line
                                                               "Save in place" replace; same temp-file + mv -f rename)
  AUTO-TRIGGER (NEW, FR34 — replaces today's "💡 Optional: run /aid-summarize" *suggestion*):
    invoke /aid-summarize   (its FULL state machine: PREFLIGHT → STALE-CHECK → ... → APPROVAL(V1) → WRITEBACK → DONE)
       -> aid-summarize runs ITS OWN second human visual approval (V1 gate, existing) producing kb.html
  Discovery is "DONE" at KB approval; the summary completes ASYNC.
     => the KB card sits at `preparing` from KB-approval until aid-summarize's V1 approval lands (FF-A3)

aid-summarize [State: WRITEBACK → DONE]  (relocated output, FR31)
  writes <repo>/.aid/dashboard/kb.html   (NOT .aid/knowledge/knowledge-summary.html)
  -> summary_present flips true; on V1 approval status -> approved (FF-A3)
```

- **This is the FR34 intended NEW closing behavior, not a C4 change.** Today `aid-discover`'s DONE state
  ends at HALT and only **suggests** `/aid-summarize` (verified: `state-done.md:19-27`). The re-scope
  replaces that suggestion with an **auto-invocation** that produces `kb.html` as discovery's closing
  output. It **composes** the two existing approval gates (discovery's KB approval + summarize's V1) —
  it replaces neither — but the added auto-invocation + new `kb.html` output is the deliberate new
  observable behavior (REQUIREMENTS FR34 / C7; the charter re-scope block above already records this).
- **Async by design.** Discovery does not block on the summary. If the user defers or fails summarize's
  V1, the card stays `preparing` (KB is viewable-pending), never `generating` (discovery is done) — the
  derivation (FF-A3) reads this from disk each poll and self-corrects when V1 lands.

#### FF-A2. Per-poll freshness git read (FR35) — read-only, cross-runtime, graceful (DD-A2)

Run once **per registered repo** inside the reader's existing per-repo read pass (LC-A2):

```
freshness_check(repo_root) -> "approved" | "outdated" | <skip>:
  1. baseline = parse .aid/settings.yml kb_baseline (DM-A4)
        baseline is null/unparseable                -> SKIP (return: do not flip to outdated; stay approved)
  2. default branch resolution (the branch to read):
        prefer baseline.branch; else `git symbolic-ref --short refs/remotes/origin/HEAD` basename;
        else first of {main, master} that exists                          (DD-A2)
  3. current_tip = `git -C <repo_root> log -1 --format=%cI <branch>`       (read-only, bounded -1)
  4. NORMALIZE both timestamps to a common UTC instant, THEN compare:
        norm(t) = parse ISO-8601 (honoring its offset) -> convert to UTC epoch/instant
        if norm(current_tip) > norm(baseline.tip_date)  -> "outdated"  else "approved"
```

**Graceful-degradation matrix (DD-A2) — every failure mode → SKIP (stay `approved`, never error):**

| Condition | Detection | Result |
|-----------|-----------|--------|
| not a git repo | `git -C <root> rev-parse` fails / no `.git` | SKIP → stay `approved` |
| no `main`/`master` & no `origin/HEAD` & no `baseline.branch` resolvable | branch resolution yields nothing | SKIP → stay `approved` |
| detached HEAD (no named default branch) | `symbolic-ref` fails and no fallback branch | SKIP → stay `approved` |
| `git` binary absent on PATH | spawn `ENOENT` / `FileNotFoundError` | SKIP → stay `approved` |
| `git log` nonzero / empty / unparseable date | exit≠0 or no ISO date | SKIP → stay `approved` |
| `kb_baseline` absent (DD-A4) | settings key missing | SKIP → stay `approved` |
| timeout (bounded, e.g. 2s) | subprocess timeout | SKIP → stay `approved` |

- **Read-only / no-LLM (NFR2/NFR7, SEC-A).** The only git verbs are `rev-parse`, `symbolic-ref`, `log`
  — all **read-only**; **never** `fetch`/`pull`/`commit`/`checkout`. No file is written. No agent/LLM.
- **Offset normalization before compare (step 4) — chronological, not lexicographic.** `git log
  --format=%cI` emits the **committer-local** offset (e.g. `2026-06-12T10:03:00-04:00`), while a baseline
  written/exemplified as `Z` (UTC, DD-A4: `2026-06-12T14:03:00Z`) is the same instant in a different
  textual form. A raw lexicographic string compare (`current_tip > baseline.tip_date`) of mixed-offset
  ISO-8601 is **chronologically wrong** at offset/DST boundaries. So step 4 first parses each ISO-8601
  string honoring its offset and converts to a **common UTC instant** (epoch/`datetime`-with-tz), then
  compares those instants. The two runtimes MUST normalize **identically** for byte-parity: Python uses
  `datetime.fromisoformat(...).astimezone(timezone.utc)` (3.11 parses the offset, incl. `Z`) and Node uses
  `Date.parse(...)` / `new Date(...).getTime()` — both yield the same UTC epoch for the same ISO-8601
  input. The exact shared normalization helper (and a `Z`-vs-`±HH:MM` boundary unit case proving Python ==
  Node) is pinned at detail (Residual #5).
- **Byte-parity (SEC-A).** Python (`subprocess.run`) and Node (`child_process.execFile`) invoke the
  **identical argv** with no shell, so the parsed `current_tip` is byte-identical across runtimes; the
  derived `status` (after the identical normalization above) is therefore parity-stable for a given
  on-disk + git state. In the PT-1 fixture the
  live git read is run against a fixed fixture repo (or stubbed deterministically) so the assertion is
  reproducible; where a real-clock git tip cannot be frozen, the field is normalized/excluded exactly
  like feature-003/010's `read_at`/`generated_by` echoes.
- **Low overhead (NFR4).** One bounded `git log -1` per repo per poll; cheaper than a doc-set rescan. If
  detail finds this material under many-tab load, it is mtime-cacheable like feature-010's registry read
  (DD-1 there) — flagged as a detail-phase optimization, not a spec gap.

#### FF-A3. Status derivation waterfall (FR32, DD-A3) — outermost-first, disk-only

```
derive_kb_status(repo) :
  if .aid/knowledge/ absent or empty                         -> pending
  elif discovery in progress (STATE.md ## Knowledge Summary Status / discovery run-state shows
       the KB is mid-generation, no **User Approved:** yes yet)  -> generating
  elif KB approved (**User Approved:** yes for the KB) but
       kb.html absent (summary_present == false) OR the summary not yet V1-approved
       (## Knowledge Summary Status **User Approved:** no / Writeback Status not ok) -> preparing
  else:                                                       # KB + kb.html ready & approved
       if freshness_check(repo) == "outdated"  (FF-A2)        -> outdated
       else                                                   -> approved
```

- **Signals (all literal, read-only):** `.aid/knowledge/` presence/emptiness; `.aid/knowledge/STATE.md`
  `## Knowledge Summary Status` (`**User Approved:**`, `**Writeback Status:**`) — the existing section the
  reader already parses (`parsers.py:_parse_kb_summary_approval`); `<repo>/.aid/dashboard/kb.html` stat
  (`summary_present`); and the FF-A2 git comparison. The discovery-in-progress signal reuses whatever the
  FR17/feature-001 normalized state surfaces for an in-flight discovery (detail-phase: pin the exact
  field; the waterfall's *shape* is fixed, the `generating` predicate's exact disk anchor is the one
  detail item — see Residual questions).
- **Re-evaluated every poll, no memory (NFR2/NFR7).** `status` is a pure function of disk + the git read;
  a KB approved on disk, then `kb.html` produced, then the branch advancing, walks `pending → generating →
  preparing → approved → outdated` purely by re-reading — the dashboard transitions live within one
  interval (NFR3) with no stored state machine (justifies the State-Machines skip).
- **Only `approved`/`outdated` are clickable (FR32).** The card renders a dead (non-link) affordance for
  `pending`/`generating`/`preparing` (UI-A); `outdated` links to the stale `kb.html` plus the refresh
  prompt.

#### FF-A4. aid-housekeep resolves `outdated` (FR36)

`aid-housekeep` KB-DELTA → SUMMARY-DELTA already re-discovers + regenerates the summary
(`state-kb-delta.md`, `state-summary-delta.md`). The re-scope **adds**: on a successful refresh,
**re-stamp** `.aid/settings.yml kb_baseline` to the current default-branch tip (DD-A4) — flipping the
card from `outdated` back to `approved` on the next poll. (SUMMARY-DELTA's regeneration already targets
the relocated `kb.html` via the FR31 `aid-summarize` change — PR-A.)

### LC-A. Layers & Components

| Component | Half | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-A1 KB-status reader extension** (feature-002 `parsers.py`/`derivation.py`/`models.py` + the 4 "no subprocess" docstrings) | server (reader) | extend `KbStateRef` (DM-A1); populate `status` via the FF-A3 waterfall; `summary_present` via `kb.html` stat; `kb_baseline` via a tolerant settings line-scan; **update the 4 reader-module "no subprocess" docstring occurrences → "no write / no LLM / a single read-only git subprocess for KB freshness (FR35)"** (SEC-A1 — `__init__.py:7`, `reader.py:15,54`, `derivation.py:49`) so the self-documented NFR2 invariant stays true | write/append/lock any file; call any agent/LLM; throw on a missing field (null-fill + parse-warning); leave a now-false "no subprocess" docstring in place |
| **LC-A2 Cross-runtime git read** (feature-002 reader, Python + Node) | server (reader) | run the FF-A2 read-only `git log -1` per repo; degrade gracefully (DD-A2 matrix); return `approved`/`outdated`/skip | run any write/`fetch` git verb; raise on any failure; diverge between runtimes (identical argv) |
| **LC-A3 KB card** (front-end, hosted on feature-006 `home.html`) | front-end | render the 5-state card from `kb_state.status` (UI-A); link `approved`/`outdated` → `kb.html` **location-relative** (the card is served at `/r/<id>/home.html`, so the href is `./kb.html` — sibling of the current page — needing **no** `<id>` in `/api/model`); show the outdated refresh prompt | re-derive status client-side (renders reader output literally); fetch KB files; add a network call beyond the shared `/api/model`; require an `<id>` field in the model envelope |
| **LC-A4 `aid-summarize` producer** (PR-A) | producer skill | write the summary to `<repo>/.aid/dashboard/kb.html` (FR31) instead of `.aid/knowledge/knowledge-summary.html` | change any phase/gate/output of summarize beyond the output path + hand-off/STATE-writeback text |
| **LC-A5 `aid-discover` producer** (PR-A) | producer skill | auto-trigger `aid-summarize` at DONE (FR34); record `kb_baseline` (FR35) | replace either approval gate; block discovery on the async summary |
| **LC-A6 `aid-housekeep` producer** (PR-A) | producer skill | resolve `outdated` + re-stamp `kb_baseline` on KB-DELTA/SUMMARY-DELTA refresh (FR36) | alter the existing KB-DELTA/SUMMARY-DELTA gates beyond the re-stamp |
| **LC-A7 `/aid-config` schema** (DD-A4) | producer skill | own the additive `kb_baseline` key in the settings template + validation table | require the user to author it (producer-written) |
| **LC-R Reader / LC-MS Server** (feature-002 / feature-010) | server | `read_repo` per repo serves the extended `kb_state`; feature-010 serves `/r/<id>/kb.html` | (owned elsewhere; consumed as-is, not re-specified) |

- **Read-only / no-LLM inherited structurally — but the "no subprocess" clause changes (SEC-A1).** LC-A1/
  LC-A2 sit **inside** feature-002's audited reader. Its "no write primitive" self-check
  (`test_no_write_primitives_in_reader_modules`, which forbids write-mode `open()`) **still holds** —
  adding reads + one read-only `git log` introduces no write surface. The git read is the **single new
  subprocess** (the reader's first); SEC-A pins it read-only. NFR2 (no write) and NFR7 (no LLM) are
  **preserved**; only the reader's self-documented **"no subprocess"** invariant is superseded, so LC-A1
  also updates the 4 docstring occurrences to say "one read-only git subprocess for KB freshness (FR35)" (the
  developer must not leave a false invariant). No agent/LLM anywhere (NFR7): status is a literal waterfall,
  freshness is a date comparison.
- **Dependency direction.** LC-A3 depends only on `/api/model`'s `kb_state` (DM-A1) + feature-010's
  `/r/<id>/kb.html` route + feature-006's card slot. LC-A1/LC-A2 depend only on the reader internals + the
  KB/settings files + git. The producers (LC-A4..A7) depend on nothing in the reader — the `.aid/dashboard/
  kb.html` path and the `kb_baseline` key are the clean file/contract boundaries between producer and reader.

### UI-A. KB card UI Specs (FR32, FR8, NFR8)

The KB card lives in feature-006 `home.html`'s Knowledge section (feature-006 R-3 owns the slot; this
spec owns the card's states). Built on the `knowledge-summary/` design family (NFR8) — `.card`, `.badge-*`,
`.kicker`/`.stat`/`.meta`, light+dark tokens — exactly as feature-006 UI-1 enumerates.

| `status` | Badge (color+shape, FR8) | Stat / meta | Clickable |
|----------|--------------------------|-------------|-----------|
| `pending` | `.badge-dim` ⊘ "No KB" | `.meta`: "run `/aid-discover` to build the Knowledge Base" | no (dead card) |
| `generating` | `.badge-info` ◴ "Building" | `doc_count` if any; `.meta`: "discovery is building the KB…" | no |
| `preparing` | `.badge-info` ◴ "Preparing" | `doc_count`; `.meta`: "summary generating — KB approved" | no |
| `approved` | `.badge-ok` ✓ "Ready" | `doc_count` "docs"; `.meta`: "summary updated {last_summary_date}" | **yes → `./kb.html`** (location-relative) |
| `outdated` | `.badge-warn` ⚠ "Outdated" | `doc_count`; `.meta`: "KB reflects {kb_baseline.tip_date}; branch has advanced" + **refresh prompt** | **yes → `./kb.html`** (location-relative, stale) |

- **Outdated refresh prompt (FR18-style, FR32).** The `outdated` card shows a step-by-step inline prompt:
  "The branch has advanced past the KB baseline. 1. Run `/aid-housekeep` to reconcile the KB and refresh
  the summary. 2. Verify: this card returns to **Ready** on the next refresh." It still **opens** the
  stale `kb.html` (the user can read the old summary), so `outdated` is clickable — it is "stale but
  usable," distinct from the non-clickable busy/empty states.
- **Card link is location-relative — no `<id>` travels in the model (resolves f-006 R-3's deferred link
  form).** The KB card is rendered inside `home.html`, which feature-010 serves at `/r/<id>/home.html`
  (feature-010 SPEC.md:418). `kb.html` is its **sibling** route `/r/<id>/kb.html` (SPEC.md:419). So the
  clickable card's href is the **location-relative** `./kb.html` — the browser resolves it against the
  current path (`/r/<id>/`) to `/r/<id>/kb.html` automatically. This means the **client never needs to
  know `<id>`**, and `/api/model` (feature-003 DM-1, reused verbatim) carries **no** `<id>` field — none
  is required. (If a non-relative form is ever wanted, `<id>` is parseable from
  `window.location.pathname` as the segment after `/r/`; the spec picks the relative `./kb.html` form so
  no model change is needed.) This is the link form feature-006 R-3 explicitly deferred to feature-007.
- **Web-review gate (global CLAUDE.md).** Because this is rendered web output, any review **must** render
  `home.html` (with the card in each of the 5 states) **and** the served `kb.html` in Playwright and
  visually validate — a source-only review is an automatic fail. The card's 5 states, the clickable vs
  dead affordance, the outdated refresh prompt, and the `/r/<id>/kb.html` navigation must all be visually
  confirmed across the responsive breakpoints.

### SEC-A. Security Specs (NFR2/NFR7/C6/C7)

- **SEC-A1. Git read is read-only — it is the reader's FIRST subprocess, and it preserves NFR2/NFR7.**
  Only `git rev-parse`/`symbolic-ref`/`log -1` are used — no write/`fetch`/`pull`/`checkout`/`commit`. A
  self-check (grep, mirroring feature-002's no-write reader check) asserts the reader's git invocations
  contain **no** mutating git verb. The read writes no file.
  - **This is the reader's first-ever subprocess — a deliberate, scoped invariant change.** Until now the
    feature-002 reader was self-documented as "no subprocess" (4 docstring occurrences, below). This re-scope
    adds **ONE** subprocess: a single read-only, deterministic, gracefully-degrading `git log -1` for KB
    freshness (FR35). It (a) introduces exactly that one subprocess and no other; (b) **preserves NFR2**
    (no write — a read-only `git log` writes nothing, creates no file, holds no lock) and **NFR7** (no LLM
    — it is deterministic shell-out, no agent/inference); and (c) degrades gracefully on every failure
    mode (FF-A2 matrix) so it can never error or block.
  - **The existing no-write self-check still passes, but the "no subprocess" docstrings become false and
    MUST be updated.** `test_no_write_primitives_in_reader_modules` (`dashboard/reader/tests/test_reader.py`)
    only forbids write-mode `open()`, so the new `git log` does not break it. But **4 reader-module
    docstring occurrences literally assert "no subprocess"** as part of the NFR2 invariant, and that claim is no
    longer true. The developer MUST update those 4 occurrences from "no subprocess" to **"no write / no LLM /
    a single read-only `git log` subprocess for KB freshness (FR35)"** so the self-documented invariant
    stays accurate. **Docstring sites to update — 4 occurrences across 3 files (verified by grep; spec'd implementation task — LC-A1):**
    - `dashboard/reader/__init__.py:7` — "no write, no append, no lock, no subprocess, no agent/LLM"
    - `dashboard/reader/reader.py:15` — "no write, no append, no lock, no subprocess, no agent/LLM"
    - `dashboard/reader/reader.py:54` — "No writes, no locks, no subprocess, …" (the `read_repo` docstring)
    - `dashboard/reader/derivation.py:49` — "Read-only by construction. No write, no subprocess, no agent/LLM"
    (All 5 are in the Python reader; the Node reader `dashboard/server/reader.mjs` carries no "no subprocess"
    docstring today — verified — so it needs none added, but the developer must NOT introduce one.)
    The NFR2 *no-write* and NFR7 *no-LLM* invariants genuinely HOLD; only the **"no subprocess"** clause
    is superseded by "one read-only git subprocess," and the docstrings must say so.
- **SEC-A2. No path traversal / scoped reads.** The reader reads only well-known paths under the repo root
  it is already scoped to (`.aid/knowledge/`, `.aid/settings.yml`, `.aid/dashboard/kb.html`) — no
  request-derived path. **Serving** of `kb.html` is owned by feature-010's multi-repo server, whose SEC-2
  construct-not-sanitize static-leaf allowlist already covers `/r/<id>/kb.html` (the `kb.html` leaf is one
  of its **2-element fixed set `{home.html, kb.html}`** — feature-010 SPEC.md:431-432: "served =
  `<repo>/.aid/dashboard/<leaf>` where `<leaf>` in `{home.html, kb.html}` ONLY"; the request path
  contributes only the `<id>`, the filename is chosen from that 2-element allowlist) — this feature
  **produces** the file feature-010 serves; it adds no serving surface.
- **SEC-A3. No-LLM (NFR7).** The git read, status derivation, and card render are deterministic code; no
  agent/LLM invocation anywhere at runtime. The producers (LC-A4..A7) run inside the skills (agent-time),
  not the dashboard runtime — the dashboard never invokes them.
- **SEC-A4. Byte-parity extension (PT-1 / PT-1-H).** The fixture is extended so both runtimes emit
  byte-identical `kb_state` (including the new fields) for a fixed `.aid/knowledge/` + `kb.html` +
  `kb_baseline` + git state; the live git tip, where non-deterministic, is normalized/excluded like the
  existing `read_at`/`generated_by` echoes (DM-A3).

### PR-A. Producer-skill changes (C7 — canonical → render → dogfood)

All three KB-domain producers are **`canonical/`-authored, dogfood-rendered** via the **FULL
`run_generator.py`** (per MEMORY "render-drift full generator" — never per-script renderers), landing in
`profiles/` + `.claude/` so `/aid-*` on **this** repo uses them immediately (C7; unlike `bin/aid`, these
ARE canonical-rendered). **Render-drift + deterministic-emission gates must stay green.**

| Producer | Files impacted | Change |
|----------|----------------|--------|
| **`aid-summarize`** | the **9 files that name `knowledge-summary.html`** (verified exact): `SKILL.md`, `README.md`, and the **7 references** `references/{state-done,state-writeback,state-validate,state-approval,state-generate,state-stale-check,state-manual-checklist}.md` | repoint the **output path** `.aid/knowledge/knowledge-summary.html` → `<repo>/.aid/dashboard/kb.html` (FR31); update the **"open … in a browser" hand-off** (`state-done.md:21`) and the **STATE-writeback path** (`state-writeback.md:19` `**Output:**` line, and any committed-path reference) to the new location. The summary's **content/visual family is unchanged** (NFR8) — only the path moves. (`.aid/dashboard/` is created if absent.) |
| **`aid-discover`** | `references/state-done.md` (the DONE close) | replace the "💡 Optional: run /aid-summarize" *suggestion* (`state-done.md:19-27`) with the FR34 **auto-trigger** of `/aid-summarize` as the closing step **and** the FR35 **`kb_baseline` record** (write `.aid/settings.yml kb_baseline` via the aid-config **"append a new block"** path — `SKILL.md:126-132`, the not-yet-present-section idiom, NOT the single-line "Save in place" `SKILL.md:124`; re-stamp later is a line-replace) before HALT |
| **`aid-housekeep`** | `references/state-summary-delta.md` (+ the KB-DELTA/SUMMARY-DELTA commit `--add` paths) | the SUMMARY-DELTA delegation already regenerates the summary (now to `kb.html` via the aid-summarize change); **add** the FR36 **`kb_baseline` re-stamp** on a passed/refreshed KB so `outdated` resolves (re-stamp `tip_date` in the already-present `kb_baseline` block is the single-line "Save in place" replace, `SKILL.md:124`; if the block is absent it falls back to the append-block path, `SKILL.md:126-132`); update the committed-artifact path `.aid/knowledge/knowledge-summary.html` → `.aid/dashboard/kb.html` in the `branch-commit.sh --add` lists |
| **`/aid-config`** | `canonical/templates/settings.yml` + `aid-config/SKILL.md` validation table | add the additive **`kb_baseline: {branch, tip_date}`** key (DD-A4) — schema owner; producer-written, not user-authored |

> **Behavior scope (C7).** The `aid-summarize` relocation, the `kb_baseline` record/re-stamp, and the
> `/aid-config` key are **behavior-additive** (no existing phase/gate/output/decision changes beyond the
> path + the new baseline write). **The one deliberate exception is the FR34 auto-trigger** (FF-A1): an
> intended NEW closing behavior of `aid-discover` (it now produces `kb.html`), not a C4 behavior-preserving
> change — it composes the two existing gates, but the added auto-invocation + new output is by design.

### Acceptance-criteria → spec map (re-scope)

| Requirement | Satisfied by |
|-------------|--------------|
| FR31 — serve relocated `kb.html` | PR-A (`aid-summarize` → `.aid/dashboard/kb.html`); served by feature-010 `/r/<id>/kb.html`; card links there (UI-A) |
| FR32 — 5-state reader-derived KB card | DM-A1/DM-A2 (`status` enum) + FF-A3 (derivation waterfall) + UI-A (card states, clickability, outdated prompt) |
| FR34 — discover→summarize auto-trigger chain | FF-A1 + PR-A (`aid-discover` DONE auto-triggers `aid-summarize`; async `preparing`) |
| FR35 — KB freshness baseline + cross-runtime git read | DM-A4 (`kb_baseline`) + FF-A2 (git read + degradation matrix) + LC-A2 (Python+Node parity) |
| FR36 — aid-summarize/discover/housekeep producer portion | PR-A (all three) + FF-A4 (housekeep `outdated` resolution + re-stamp) |
| NFR2/NFR7 — read-only / no-LLM | LC-A1/LC-A2 inside the audited reader; SEC-A (read-only git, no-LLM) |
| NFR8 — summary visual family | PR-A (only the path moves; content unchanged); UI-A (card on the `knowledge-summary/` family) |
| C7 — dogfood-rendered producers | PR-A (canonical → FULL `run_generator.py` → profiles/+.claude/; render-drift green) |

### Residual questions (for /aid-plan and /aid-detail)

Design is decided; these are exact-wiring items deliberately left for the plan/detail phases:

1. **The `generating` predicate's exact disk anchor (FF-A3).** The waterfall shape is fixed; the precise
   in-flight-discovery signal (which FR17/feature-001 normalized field or `.aid/knowledge/STATE.md` marker
   indicates "discovery is mid-build, not yet approved") is a detail-phase pin. Until pinned, the reader
   treats "KB present but not yet `**User Approved:** yes`" as `generating` — a safe default.
2. **`kb_baseline` write mechanism in the producers — uses the APPEND-BLOCK path, not the single-line
   replace.** `kb_baseline:` is a **new MULTI-LINE nested block** (`branch:` + `tip_date:`), not a
   single-line `<key>: <value>`. So the **first** write is the aid-config **"append a new block"** path
   (`aid-config/SKILL.md` Step 6, the second idiom: "For … a skill section that doesn't yet exist …
   append a new block … at the end of the file", `SKILL.md:126-132`) — NOT the Step 6 "Save in place"
   single-line replace (`SKILL.md:124`), which only replaces "the line containing `<key>`". A subsequent
   **re-stamp** of `tip_date` within an existing `kb_baseline` block is a single-line replace of that
   nested line (the "Save in place" idiom). Whether `aid-discover`/`aid-housekeep` call a small
   `/aid-config`-owned helper or inline the same temp-file + `mv -f` crash-safe rename is the detail-phase
   pin; the **block-vs-line** path selection above is decided. Recommendation: reuse the existing
   append-block-then-line-replace settings-write idiom.
3. **Git-read caching under many-tab load (FF-A2 / NFR4).** Whether to mtime-cache the per-repo git tip
   like feature-010's registry read (DD-1 there). Spec default: a bounded `git log -1` per poll is cheap
   enough; revisit only if profiling shows pressure.
4. **PT-1 git-state determinism (SEC-A4).** Exact harness shape for freezing/stubbing the live git tip so
   the byte-parity assertion is reproducible (fixture repo with a known commit vs. a normalized/excluded
   field). A detail-phase test-construction item, not a design gap.
5. **The shared ISO-8601 → UTC-instant normalization helper (FF-A2 step 4).** The exact byte-parity
   normalization used to compare `current_tip` (committer-local offset from `%cI`) against
   `baseline.tip_date` (possibly `Z`): the Python (`datetime.fromisoformat(...).astimezone(utc)`) and Node
   (`Date.parse` / `getTime`) helpers, plus a unit case proving the two agree on a `Z`-vs-`±HH:MM`
   boundary input (same instant, different text). The **requirement** — normalize to a common UTC instant,
   identically across runtimes, never a raw lexicographic string compare — is decided here (FF-A2); the
   helper's exact shape/location is the detail-phase pin.

## Source

- REQUIREMENTS.md §5 FR15 (KB dashboard — the dedicated view behind the KB card)
- REQUIREMENTS.md §3a (Level-1 data source includes KB state)
- REQUIREMENTS.md §6 NFR2 (read-only), NFR5/NFR6/NFR8 (cross-browser, responsive, summary style)

## Description

The Knowledge Base is rich enough to be its **own dashboard**. Reached by clicking the KB summary
card on the project main page (feature-006), this is a **dedicated, independent KB view** showing
the fuller detail: the KB **document inventory** and their **completeness/status** (from
`knowledge/README.md`), **freshness** (INDEX up-to-date; `knowledge-summary.html` current &
approved per `knowledge/STATE.md`), and last KB update. Read-only.

## User Stories

- As an **operator**, I want to see the state and completeness of my project's Knowledge Base, so I
  know whether the KB is current and trustworthy.
- As an **operator**, I want to open KB detail from its card, so the main page stays uncluttered.

## Priority

Should.

## Acceptance Criteria

- [ ] Given the KB card, when I click it, then a dedicated KB dashboard opens (FR15).
- [ ] Given the KB dashboard, then it lists KB documents with completeness/status and shows KB
      freshness (INDEX, summary current/approved) and last update — read-only (NFR2).
- [ ] Given the KB dashboard, then it matches the summary visual style (NFR8) and is responsive /
      cross-browser (NFR5/NFR6).

---

## Technical Specification (SUPERSEDED — historical record)

> **⚠️ SUPERSEDED by the "Re-architecture Re-scope (Technical)" section above (2026-06-12).** The
> Technical Specification that follows describes the **original, never-delivered** feature-007: a
> build-from-scratch rich client-rendered `KbModel` KB dashboard (doc inventory + INDEX-freshness proxy +
> a `schema_version 1→2` envelope bump), grouped into the superseded delivery-005 (tasks 030–037,
> Pending). The two-level re-architecture **replaces that approach entirely**: the KB summary is now a
> **pre-rendered `kb.html`** that `aid-summarize` produces and feature-010's server serves, so the
> reader's KB work shrinks to **status derivation + a freshness git read**, not a fuller-detail model.
> The rich `KbModel`, the `schema_version 1→2` bump, the DD-3 INDEX-freshness proxy, KI-007, and the
> in-SPA `#/kb` client-rendered view are all **DROPPED**. This body is retained verbatim **only** as the
> historical design record; **do not implement it** — the authoritative scope is the "Re-architecture
> Re-scope (Technical)" section above (DM-A.., FF-A.., LC-A.., UI-A.., SEC-A.., DD-A..).

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the richer
> read-only `KbModel` this view needs — the doc inventory, INDEX freshness, summary status, overall
> completeness — and the decision to grow feature-002's thin `KbStateRef` into it inside the existing
> reader + `/api/model` envelope, with the `schema_version` 1→2 bump + parity impact this entails),
> **Feature Flow** (the `#/kb` route — owned/defined as a seam by feature-006 SEAM-1 — renders this
> view from the **shared** feature-003 poll loop; how the richer KB fields are read by feature-002's
> reader and crossed on the wire; refresh is the same loop, no new endpoint), **Layers & Components**
> (the KB-dashboard view components, the **reader extension** that populates `KbModel`, the read-only
> boundary, design-token reuse). Conditional: **UI Specs** (REQUIRED by FR15/FR8/FR18/NFR6/NFR8 — the
> KB doc table/cards, completeness/freshness/approval indicators on the badge system, the summary-status
> panel, responsive, knowledge-summary visual family, and the **FR18 step-by-step remediation** for a
> stale/incomplete/unapproved KB). **Skipped:** Data-DB (no database — `schemas.md`), Migration (no
> on-disk change — this reads existing KB files, writes nothing), API Contracts → external (the only
> API is feature-003's internal `/api/model`; the envelope extension is specified under Data Model, not
> as a new external integration), CLI (feature-004), Security / remote exposure (feature-005),
> State Machines (no lifecycle derivation here — KB doc status is read literally, not derived).

This feature is the **dedicated KB dashboard** behind feature-006's KB card. It is reached **only** via
the hash route `#/kb` that feature-006 already defined as **SEAM-1** (feature-006 FC-1, UI-4) — this
feature **owns the view body behind that seam**, not the route plumbing. Like feature-006 it is
**front-end + a read-only reader extension**: no new endpoint, no new server route, no new poll loop. It
renders from the **same `/api/model` body the shared feature-003 loop already polls** (feature-003
DM-1). At runtime it is deterministic client-side code — **no agent/LLM** (NFR7) — and it **writes
nothing to `.aid/`** (NFR2); the only persistence it touches is feature-003's existing `localStorage`
for theme/interval.

**The one real seam decision (DD-1, below): grow the model, don't read KB files a second way.**
feature-002 deliberately captured KB state as a *thin* `KbStateRef` hook (`summary_approved`,
`last_summary_date`, `doc_count` — feature-002 DM-3) and **explicitly deferred the rich KB detail to
feature-007**. This view needs more than that hook (a per-doc inventory, INDEX freshness, the full
summary-status panel). The decision is to **extend feature-002's reader** to populate a richer
`KbModel` and serve it through the **existing `/api/model` envelope** — keeping **all filesystem reads
inside the one read-only, no-LLM reader** (NFR2/NFR7 stay structurally enforced exactly as feature-002
LC-R already guarantees). The alternative — a separate KB-file fetch from the client or a second
endpoint — is **rejected**: it would put `.aid/` reads outside the audited read-only reader, add a
second server surface feature-003's bind/no-write/no-LLM self-checks do not cover, and break the
single-poll-loop model. Because this **grows the wire shape**, it requires a **`schema_version` bump
1 → 2** (feature-003 DM-1) and a corresponding **parity-fixture extension** (feature-003 PT-1). See
DD-1/DD-2 for the full rationale and blast radius.

---

### Data Model

No relational schema (AID ships no database — `schemas.md`). This view's data model is a **richer
read-only `KbModel`** that **replaces** feature-002's thin `KbStateRef` at `model.repo.kb_state`. It is
the JSON projection of new fields the **feature-002 reader** computes from the same KB files it already
stats today (`.aid/knowledge/README.md`, `STATE.md`, `INDEX.md`, `knowledge-summary.html`). All fields
are **read-derived**; nothing is persisted (NFR2).

#### DM-1. `KbModel` — the rich KB sub-model (replaces `KbStateRef` at `model.repo.kb_state`)

`model.repo.kb_state` is a `KbModel`-object or `null` (repo never ran `/aid-discover`). The **thin
feature-002 hook fields are retained verbatim** so feature-006's KB *card* (feature-006 UI-4) keeps
working unchanged; this feature **adds** the inventory + freshness + summary sub-objects:

```
KbModel  (model.repo.kb_state — null when no .aid/knowledge/ exists)
├─ doc_count:        int                 # retained from KbStateRef (f-002 DM-3): count of README ## Completeness rows
├─ summary_approved: bool                # retained from KbStateRef: STATE.md ## Knowledge Summary Status **User Approved:** parsed yes/no
├─ last_summary_date: string | null      # retained from KbStateRef: **Last Summary Date:**
│
├─ docs:    list<KbDoc>                  # NEW — the per-doc inventory (README ## Completeness table)
├─ index:   KbIndexFreshness             # NEW — INDEX.md up-to-date vs stale (kb-hygiene definition)
└─ summary: KbSummaryStatus              # NEW — the fuller summary-status panel (STATE.md ## Knowledge Summary Status)
```

**`KbDoc`** — one row of `.aid/knowledge/README.md ## Completeness` (real columns verified on disk
2026-06-10: `| # | Document | Status | Last Reviewed | Notes |`):

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `name` | string | `Document` cell (the `[name](name.md)` link text) | e.g. `architecture.md` |
| `category` | string \| null | the doc's **own** `kb-category:` frontmatter (`primary \| meta \| extension`) | the reader already reads each doc's frontmatter for INDEX; surfaced here so the table can group/badge by category. `null` if absent (defaults `primary`, mirroring `build-kb-index.sh:162`) |
| `status` | string | `Status` cell | the **literal** README value (e.g. `"Populated"`); rendered verbatim, never re-derived (no LLM, NFR7) |
| `last_reviewed` | string \| null | `Last Reviewed` cell | ISO date or `null` |
| `notes` | string \| null | `Notes` cell | the README provenance note; surfaced read-only in the row's detail (FR6 "maximal tracking") |

> **Status is read literally, not interpreted.** The README `Status` column is free text the KB author
> maintains (today every row reads `Populated`). The reader copies the literal string; the renderer maps
> *known* literals to badge colors (UI-2) and shows any unknown literal as a neutral chip — it never
> invents a completeness judgement or calls an LLM to grade a doc (NFR7). This mirrors feature-002 DM-6's
> "unrecognized enum → neutral, never throws" discipline.

**`KbIndexFreshness`** — whether `INDEX.md` is current vs the docs it indexes, using the **same
definition the kb-hygiene CI job enforces** (`.github/workflows/test.yml` job `kb-hygiene`, step
"INDEX.md is fresh"): regenerate via `build-kb-index.sh` and diff, ignoring timestamp lines:

| Field | Type | Source / definition | Notes |
|-------|------|---------------------|-------|
| `state` | enum `fresh \| stale \| unknown` | **`fresh`** = the cheap proxy (see note) finds no doc-set/intent drift. **`stale`** = the proxy finds drift. **`unknown`** = the reader cannot run the comparison cheaply at poll time. The authoritative "INDEX up-to-date" gate is the kb-hygiene CI job (`test.yml:118-126`: regenerate `build-kb-index.sh` + timestamp-filtered diff); the proxy is a **subset** of that (see note). | the operator-facing approximation of "INDEX up-to-date" (FR15); authoritative gate is CI |
| `index_present` | bool | `INDEX.md` stat | `false` → INDEX never generated; `state=unknown` |
| `indexed_doc_count` | int \| null | count of `### [name]` entries in `INDEX.md` | for a cheap "INDEX lists N / disk has M docs" mismatch hint without a full regen |

> **Reader-cheap freshness, not a CI shell-out (DD-3).** The reader is polled every ~5s (feature-003
> FR5) and must stay low-overhead (NFR4) and stay **inside the no-LLM, no-subprocess read path**
> feature-002 specifies (LC-R: "single anchored grep / line-scan, zero third-party deps"). It does
> **not** shell out to `build-kb-index.sh` on every poll. Instead it computes freshness with a
> **cheap deterministic proxy** that detects the **common drift dimensions** without the subprocess:
> (a) compare the set of `### [name]` entries in `INDEX.md` against the set of non-dot `*.md` files
> under `.aid/knowledge/` (the CI script's own doc-selection rule, `build-kb-index.sh:150` —
> `find -maxdepth 1 -type f -name '*.md' ! -name '.*'`), and (b) compare each indexed doc's intent line
> against that doc's current `intent:` frontmatter. A mismatch in (a) or (b) → `stale`; an exact match
> on **both** → `fresh`. If the reader chooses not to read every doc's frontmatter on a hot poll, it
> returns `state=unknown` for (b) and still reports the (a) doc-set mismatch (the most common drift case
> — a doc added/removed without an INDEX regen).
>
> **Proxy scope is narrower than the CI gate (KI-007 — important).** The proxy checks only the
> **doc-set + intent-line** dimensions. The kb-hygiene CI job regenerates the *entire* INDEX and diffs
> it, so it also catches drift the proxy does NOT: a `kb-category:` re-classification (which moves a
> doc between INDEX sections) or a `source:`/`generator:` frontmatter change. In those cases CI reports
> `stale` while the proxy may still say `fresh`. So the proxy is **not** "matches the CI semantics" — it
> is a **subset** that catches the common cases; the residual category/source drift is intentionally
> **not** detected and is covered by the `unknown`/advisory framing (the authoritative gate is always
> the CI job). This is a **read-only, deterministic** computation; the dashboard's job is only to
> *surface* likely staleness so the operator knows to act (FR18 remediation, UI-4). Registered as
> **KI-007** so the proxy-is-a-subset-of-CI distinction is tracked.

**`KbSummaryStatus`** — the `knowledge-summary.html` currency/approval, parsed from
`.aid/knowledge/STATE.md ## Knowledge Summary Status` (key-value `**Field:**` per line — verified shape
2026-06-10; the section is explicitly *not* a table per its own header note). Fields surfaced:

| Field | Type | Source line (`STATE.md ## Knowledge Summary Status`) | Notes |
|-------|------|------------------------------------------------------|-------|
| `approved` | bool | `**User Approved:**` (leading `yes`/`no`) | same value the thin hook's `summary_approved` carries; canonical here |
| `overall_grade` | string \| null | `**Overall Grade:**` (e.g. `A+`) | the human-facing grade |
| `machine_grade` | string \| null | `**Machine Grade:**` | |
| `human_grade` | string \| null | `**Human Grade:**` | |
| `last_summary_date` | string \| null | `**Last Summary Date:**` | == the hook field |
| `last_run` | string \| null | `**Last Run:**` | when the summary HTML was last assembled |
| `last_reviewed_kb_date` | string \| null | `**Last Reviewed KB Date:**` | how current the summary is vs the KB it summarizes |
| `output_present` | bool | stat `.aid/knowledge/knowledge-summary.html` | verified present 2026-06-10 (3.42 MB); `false` → "not generated yet" |
| `output_size` | int \| null | `**Output Size:**` byte count (or file stat) | corroborates `output_present` |

> **Parse is best-effort + null-tolerant (NFR7).** Any missing `**Field:**` line yields `null` for that
> field and a `parse_warnings` note (feature-002 DM-7), never an exception — the same torn-read / missing
> -section tolerance feature-002's reader already guarantees. Only the literal `yes` (case-insensitive,
> leading token) makes `approved=true`; anything else is `false`.

#### DM-2. `/api/model` envelope extension + `schema_version` 1 → 2 (DD-1, DD-2)

`KbModel` is a **strict superset** of feature-002's `KbStateRef` at the same path
(`model.repo.kb_state`): the three hook fields keep their names and meaning, and three sub-objects are
added. Because the **wire shape grows**, feature-003's `schema_version` MUST bump **`1 → 2`**
(feature-003 DM-1: "`schema_version` … bumped on any breaking change to the wire shape"). Blast radius
and why this is contained:

| Impact | Effect | Mitigation |
|--------|--------|------------|
| `schema_version` | `1` → `2` in the DM-1 envelope, both runtimes | a single constant in each server + the front-end's `EXPECTED`; feature-003's stale-assets banner already fails loud on mismatch (feature-003 Feature Flow 3b) |
| feature-003 front-end | bumps its `EXPECTED` to `2`; renders nothing new itself | the pipeline view ignores `kb_state` entirely — additive sub-objects are invisible to it |
| feature-006 KB **card** | reads `doc_count` / `summary_approved` / `last_summary_date` (feature-006 UI-4) | **unchanged** — those three fields are retained verbatim in `KbModel`; the card keeps rendering identically (it simply ignores the new sub-objects) |
| feature-002 reader | LC-R grows a KB sub-parser (LC-KR below) populating `KbModel` instead of `KbStateRef` | stays inside the audited read-only / no-LLM reader (NFR2/NFR7 self-checks unchanged in kind) |
| parity (PT-1) | the byte-identical-across-runtimes guarantee now covers the new fields | **extend PT-1's fixture** to include a `.aid/knowledge/` with a populated README table, a STATE.md summary block, an INDEX, and a stale-INDEX case — so both runtimes are proven to emit byte-identical `KbModel` (DD-2) |

> **Why a bump, and why it is cheap (DD-2).** The envelope's whole point is to fail loud rather than
> mis-render when server and page disagree (feature-003 DM-1). Growing `kb_state` from three scalars to a
> nested object is exactly the "wire shape changed" case the version guards. Bumping to `2` and updating
> the front-end's `EXPECTED` in lockstep is a one-line change on each side; the only *test* obligation is
> extending the PT-1 fixture so the new fields are parity-proven (a fixture data change, not new test
> machinery). This keeps the "implemented twice never behaves twice" guarantee intact across the richer
> model. **No new endpoint, no new server route, no new poll mechanism** — only the serialized shape at
> one path grows.

#### DM-3. The only client-side state

This view introduces **no new client state**. It renders from `ViewState.model` (feature-006 DM-2) on
the `#/kb` route — the same last-good `/api/model` body the shared loop owns. View-state that survives
reload (theme, poll interval) is feature-003's `localStorage`, reused as-is. Nothing is written to
`.aid/` (NFR2).

---

### Feature Flow

This view adds **no new server round-trip**. It is rendered by feature-006's router (FC-1/FC-2) when the
hash is `#/kb`, off the **same polled model**. The only net-new *read* work is in the feature-002 reader
(the KB sub-parser), which runs once per poll exactly where `read_repo()` already stats the KB today.

```
SERVER (feature-002 reader, per poll — read-only, no-LLM, UNCHANGED in posture)
  read_repo(aid_root):
    ... LEVEL-1 (f-002 Feature Flow step 3): parse settings, stat .aid/knowledge/ ...
    KB-EXTEND (net-new, inside the same read pass — LC-KR):
      if .aid/knowledge/ absent            -> kb_state = null            (unchanged graceful case, f-002 DM-3)
      else:
        KR-1  parse README ## Completeness table rows           -> docs[]   (KbDoc, DM-1)
        KR-2  read each indexed/disk doc's kb-category frontmatter (cheap; or defer -> category=null)
        KR-3  parse STATE.md ## Knowledge Summary Status key-values -> summary (KbSummaryStatus, DM-1)
        KR-4  stat knowledge-summary.html                        -> summary.output_present/size
        KR-5  compute INDEX freshness via the cheap proxy (DD-3) -> index (KbIndexFreshness, DM-1)
        assemble KbModel{ doc_count, summary_approved, last_summary_date, docs, index, summary }
    ... serialize (feature-003 DM-1/DM-3), schema_version = 2 ...

CLIENT (feature-006 router + shared poll loop — UNCHANGED plumbing)
  FC-1  hash "#/kb"  -> feature-006 router dispatches render to THIS view (feature-006 SEAM-1)
  FC-2  render(model.repo.kb_state):
          kb_state == null      -> "No Knowledge Base yet" + FR18 "run /aid-discover" step-by-step (UI-5)
          kb_state is KbModel   -> render the KB dashboard (doc table + freshness + summary panel, UI-1..UI-4)
  FC-3  every poll tick re-renders the CURRENT route -> the KB view refreshes live (FR4/NFR3),
          exactly like feature-006's cards do, off the SAME loop (no KB-specific polling)
  NAV   "back" / brand -> location.hash = "#/" -> feature-006 main page (drill is reversible)
```

- **Rendered from the shared loop, no new endpoint (NFR4).** The KB view is just another render target
  of feature-006's router over feature-003's poll loop. When the operator is on `#/kb`, each tick's
  `fetch('/api/model')` already carries the full `KbModel`; the view re-renders from it. There is **no
  KB-specific fetch, no second endpoint, no extra disk traffic** beyond the reader's one KB read per
  pass (which feature-002 already partly did for the thin hook).
- **Live freshness (FR4/NFR3).** Because the reader recomputes INDEX freshness and re-parses the summary
  block every pass, a KB that goes stale on disk (a doc added without an INDEX regen, or the summary's
  `**User Approved:**` flipped) flips the dashboard's freshness/approval indicators within one interval —
  the same ≤-interval lag guarantee feature-003 NFR3 holds for pipeline state.
- **Graceful "no KB" (FR18, not a blank screen).** When `kb_state == null` the view does not error or
  blank — it shows the FR18 step-by-step "build your KB" guidance (UI-5). This is the one genuine
  user-intervention entry on this view's happy path (the tool cannot run `/aid-discover` for the user),
  so FR18's full procedure (command + verify), not a one-line hint, applies.
- **Read-only / no-LLM (NFR2/NFR7).** Every KB field comes from the feature-002 reader's existing
  read/stat path (LC-KR adds only more reads of files already in `.aid/knowledge/`); the client only
  renders. There is **no write to `.aid/`** and **no agent/LLM** anywhere — structurally, because the
  reads live in feature-002's audited reader and the view adds no server surface (feature-003 LC-S
  invariants untouched).
- **Torn-read tolerance (inherited).** A mid-write README/STATE.md yields `parse_warnings` + best-effort
  fields on that one poll; the next poll self-corrects (feature-002 Feature Flow). The KB view surfaces
  `parse_warnings` via the same "data note" affordance feature-003 Telemetry already renders.

---

### Layers & Components

All additions are **front-end (one new view) + one reader sub-component** in feature-002's reader. No new
server route, no new endpoint, no CLI (feature-004), no remote (feature-005). Per `coding-standards.md`
(small, single-purpose, deterministic, no hidden I/O) and `module-map.md` (the dashboard reader is
feature-002's module; the front-end is feature-003's — this extends both, additively).

| Component | Half | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-KR KB reader sub-parser** | server (feature-002 reader) | populate `KbModel` (DM-1): parse README `## Completeness` rows → `docs[]`; parse STATE.md `## Knowledge Summary Status` → `summary`; stat `knowledge-summary.html`; compute INDEX freshness via the cheap proxy (DD-3) | write/append/lock any file; shell out to `build-kb-index.sh` per poll; call any agent/LLM to "grade" a doc; throw on a missing section (null-fill + `parse_warning`) |
| **LC-KV KB view** | front-end | render `KbModel` as the KB dashboard: doc inventory table/cards, freshness/approval indicators, summary-status panel, FR18 remediation; `null` → "no KB" empty-state | fetch KB files directly from the client; add a network call beyond the shared `fetch('/api/model')`; re-derive completeness/freshness (renders reader output literally) |
| **LC-KT Doc table/cards** | front-end | one row/card per `KbDoc`: name, category badge, status badge, last-reviewed, notes-on-demand (UI-2) | invent a status vocabulary (maps known literals to badge classes; unknown → neutral) |
| **LC-KF Freshness + summary panel** | front-end | INDEX fresh/stale chip + summary approval/grade/date panel (UI-3) with FR18 remediation when stale/unapproved (UI-4) | claim "fresh" when `state=unknown`; hide a stale/unapproved signal |

- **Dependency direction.** LC-KV/LC-KT/LC-KF depend only on (a) the `/api/model` `model.repo.kb_state`
  shape (DM-1) and (b) feature-003's design-family CSS (feature-003 LC-A) + feature-006's router seam
  (SEAM-1). LC-KR depends only on feature-002's reader internals + the KB files. Nothing here depends on
  feature-004/005, and the view adds **no** server/runtime surface — so feature-003 PT-1 stays valid
  (only its fixture grows, DM-2) and the bind/no-write/no-LLM self-checks (feature-003 LC-S, feature-002
  read-only boundary) are unchanged in kind.
- **Read-only / no-LLM, inherited structurally.** LC-KR sits **inside** feature-002's reader, whose
  read-only boundary is already enforced by a self-check test ("the reader module contains no write
  primitive" — feature-002 LC-R). Adding more *reads* (KB files already in scope) does not introduce a
  write surface, so that test continues to hold and now also covers LC-KR. No agent/LLM anywhere
  (NFR7): doc status and INDEX freshness are deterministic string/file comparisons, not inference.
- **The feature-006 seam, consumed not redefined (SEAM-1).** feature-006 owns the `#/kb` route and hands
  rendering to this view's function for the `model.repo.kb_state` slice (feature-006 UI-4 / Layers
  LC-KB). This feature **plugs into that already-defined route + the shared poll loop** and adds no new
  endpoint. The KB *card* (feature-006 UI-4) and this KB *dashboard* (LC-KV) read the **same**
  `model.repo.kb_state` object — the card shows the three summary fields, the dashboard shows the whole
  `KbModel`. That is why retaining the thin hook fields in `KbModel` (DM-2) keeps feature-006 working
  with zero change.

---

### UI Specs

The dedicated KB dashboard, built on the `knowledge-summary/` design family (NFR8) and the feature-003
app shell (top bar, theme toggle, footer, freshness badge) reused via feature-006. FR8 visual-first:
color **and** shape, glance-readable, minimal text. Per the global CLAUDE.md web-review gate, the
reviewer MUST render this page in Playwright (not inspect source) and visually validate the doc table,
the freshness/approval indicators across fresh/stale/unapproved states, the summary panel, the `#/kb`
arrival from the card, the back-to-main nav, and the FR18 remediation — across the responsive
breakpoints. A source-only review of this web page is an automatic fail.

#### UI-1. Design-family reuse (NFR8) + page layout

Reuses the **same** assets feature-006 UI-1 enumerates from `canonical/templates/knowledge-summary/`:
`.card` (+ hover), `.kicker`/`h3`/`.stat`/`.stat-sub`/`.meta`, `.grid.g2/.g3`, the full `.badge-*`
family, the `design-tokens.md` palette (light + dark), and feature-003's app shell. The KB view swaps
only the `<main>` body; the header/footer/theme/freshness badge are feature-003's, shared. System fonts,
CSS custom properties, no web fonts, no CDN at runtime (NFR8). This is the **same visual family** as
`knowledge-summary.html` itself, so the KB dashboard reads as part of the same product.

```
┌─ .top-bar (feature-003 shell, via feature-006) ─ brand · ◄ back · freshness badge · theme ─┐
├─ <main> ──────────────────────────────────────────────────────────────────────────────────┤
│  KNOWLEDGE BASE (h1)                                                                        │
│  .grid.g3  ┌─ KB completeness ─┐ ┌─ INDEX freshness ─┐ ┌─ Summary status ─┐   (UI-3 at-a-glance)│
│            │ [N] docs · status │ │ [fresh|STALE] chip│ │ [Approved|Draft]  │                  │
│            └───────────────────┘ └───────────────────┘ └───────────────────┘                  │
│  (when stale/incomplete/unapproved) ► FR18 remediation panel (UI-4)                          │
│  DOCUMENTS (h2)                                                                              │
│  doc inventory table/cards — one row per KbDoc (UI-2)                                         │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

#### UI-2. Document inventory (FR15 inventory + completeness/status, FR6)

The core of the dashboard — `model.repo.kb_state.docs[]` rendered as a table on desktop and stacked
cards on mobile (UI-6). One row per `KbDoc`, mapping the README `## Completeness` shape verbatim:

| Column | Source (`KbDoc`) | Display |
|--------|------------------|---------|
| Document | `name` | doc filename (e.g. `architecture.md`); monospace |
| Category | `category` | small badge — `primary` → `.badge-primary`, `meta` → `.badge-dim`, `extension` → `.badge-purple`, `null` → no chip |
| Status | `status` | badge: known literal `"Populated"` → `.badge-ok` "Populated"; an empty/`"Pending"`/`"Stub"`-like literal → `.badge-warn`; **unrecognized** literal → `.badge-dim` rendered verbatim (never throws, NFR7) |
| Last reviewed | `last_reviewed` | relative or ISO date in `.meta`; `null` → "—" |
| Notes | `notes` | truncated `.meta`, full text on row expand/hover (FR6 "maximal detail" without forcing a file open) |

- **Overall completeness chip (the FR15 "completeness" summary)** sits in the at-a-glance row (UI-3):
  computed deterministically as *"K of N docs Populated"* from `docs[]` (count of rows whose `status`
  matches the known "complete" literal vs `doc_count`). It is a **literal tally, not a judgement** — no
  LLM, no heuristic grade (NFR7). All-Populated → `.badge-ok`; any non-Populated → `.badge-warn` with
  the count, which links to the FR18 remediation (UI-4).
- **Status is rendered, never re-derived.** The dashboard surfaces the KB author's own `Status` value;
  it does not re-assess a doc. This keeps the dashboard honest (it shows what the KB *claims*) and
  read-only.

#### UI-3. Freshness + summary-status panels (FR15 freshness/approval)

Three at-a-glance cards (the `.grid.g3` row), each a glance-readable color+shape signal (FR8):

- **KB completeness card:** `.stat` = `doc_count`, `.stat-sub` = "docs"; the completeness chip (UI-2).
- **INDEX freshness card** (`model.repo.kb_state.index`): a chip from `index.state` — `fresh` →
  `.badge-ok` "INDEX fresh" (✓), `stale` → `.badge-warn` "INDEX stale" (⚠), `unknown` → `.badge-dim`
  "INDEX —" (?). When `stale`, the `.meta` shows the cheap-proxy reason (e.g. "INDEX lists 18 docs;
  disk has 19") and links to the FR18 remediation. The chip wording reflects the DD-3 proxy: it says
  "likely stale" semantics, the authoritative gate being CI.
- **Summary status card** (`model.repo.kb_state.summary`): approval chip — `approved:true` →
  `.badge-ok` "Approved", `false` → `.badge-warn` "Not approved"; below it the `overall_grade` chip
  (e.g. `A+` → `.badge-ok`), `last_summary_date` and `last_reviewed_kb_date` in `.meta`
  ("summary updated {date} · KB reviewed {date}"), and an `output_present` indicator
  (`knowledge-summary.html` present/size, or "not generated"). When the summary is older than the KB
  (`last_summary_date` < the newest doc `last_reviewed`) the card flags "summary behind KB" → FR18.

#### UI-4. FR18 step-by-step remediation (stale / incomplete / unapproved KB)

FR18 requires a **step-by-step** procedure (what, the exact command, how to verify) — not a one-line
hint — whenever the dashboard surfaces a state the tool cannot fix itself. The KB dashboard has three
such user-intervention triggers; each renders a guided panel with the **exact command + a verify step**:

| Trigger (from `KbModel`) | Remediation panel (exact, verifiable) |
|--------------------------|----------------------------------------|
| **No KB** (`kb_state == null`) — UI-5 | "This repo has no Knowledge Base yet. 1. Run `/aid-discover` to build it (creates `.aid/knowledge/` with the doc set + `knowledge-summary.html`). 2. Verify: `.aid/knowledge/` now contains `README.md` + the KB docs, and this dashboard shows the inventory on the next refresh (within the poll interval)." |
| **INDEX stale** (`index.state == "stale"`) | "The KB index is out of date — docs changed since `INDEX.md` was generated. 1. Run: `bash canonical/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md` 2. Commit the regenerated `INDEX.md`. 3. Verify: the kb-hygiene CI check passes, and this card flips to **INDEX fresh** on the next refresh. (Tip: a full re-discovery via `/aid-discover` also regenerates the index.)" |
| **Docs incomplete** (any `KbDoc.status` ≠ the complete literal) | "N of M KB documents are not yet populated: {list the doc names}. 1. Run `/aid-discover` (or `/aid-housekeep` for a targeted KB-delta refresh) to populate/refresh them. 2. Verify: each doc's row shows **Populated** and the completeness chip turns green on the next refresh." |
| **Summary not approved / behind KB** (`summary.approved == false`, or summary older than KB) | "The knowledge summary is {not approved / older than the current KB}. 1. Run `/aid-summarize` to (re)generate `knowledge-summary.html` from the current KB. 2. Review and approve it at the summary's human visual gate. 3. Verify: the **Summary status** card shows **Approved** with an updated date on the next refresh." |

- These panels are **purely informational** (read-only, NFR2) — the dashboard never runs these commands;
  it tells the operator exactly what to type and how to confirm it worked, with the verify step tied to
  the live poll (the indicator flips on the next refresh, FR4). Commands are grounded in real, verified
  paths: `build-kb-index.sh`'s exact invocation is the one its own header + the kb-hygiene CI step use
  (`test.yml:121`); `/aid-discover`, `/aid-housekeep`, `/aid-summarize` are real skills (KB
  `architecture.md` / `feature-inventory.md`).
- The remediation panel appears **inline** in the at-a-glance row (UI-3) next to the offending card, and
  only when that trigger is active — a fully-fresh, all-Populated, Approved KB shows **no** remediation
  noise.

#### UI-5. No-KB empty-state (FR18)

When `model.repo.kb_state == null`, the `<main>` body is replaced by the centered "No Knowledge Base
yet" guided panel (the first UI-4 row), reusing the same `.card` empty-state pattern as feature-006
UI-5. It shows the `/aid-discover` step + verify, and a "back to main" link. It does not error, does not
blank, and (matching feature-006's `null` card) the route still renders the shell.

#### UI-6. Responsive + cross-browser (NFR6, NFR5)

- **Breakpoints** reuse the design family's 768px collapse (`component-css.css:554` `@media (max-width: 768px)`, with the grid-collapse rule at `:563`). **Desktop**
  (>1024px): the doc inventory is a full table, the at-a-glance row is `.grid.g3` (3 cards across).
  **Tablet** (768–1024px): the at-a-glance row reflows to 2 columns; the table stays. **Mobile**
  (<768px): the at-a-glance cards stack to one column and the doc table collapses to stacked
  `KbDoc` cards (each row becomes a card with labeled fields) so no horizontal scroll is needed.
- **Cross-browser (NFR5):** Chrome/Firefox/Edge/Safari — only baseline primitives (CSS custom
  properties, `grid`/`flex`, `fetch`, `localStorage`, `location.hash`), no polyfill, no transpile,
  same posture as feature-003 UI-6 / feature-006 UI-6.

---

### Design decisions worth user attention

- **DD-1 — Grow feature-002's reader + `/api/model`, don't read KB files a second way.** This view
  needs richer KB data than feature-002's thin `KbStateRef` hook (which feature-002 *explicitly deferred*
  the rich detail from, DM-3). The decision is to **extend the one read-only reader** to populate a
  richer `KbModel` served through the **existing `/api/model` envelope** — keeping all `.aid/` reads
  inside the audited, no-LLM, no-write reader (NFR2/NFR7 stay structurally enforced). The rejected
  alternative (client-side KB-file fetch or a second endpoint) would move reads outside the reader, add a
  server surface the bind/no-write/no-LLM self-checks don't cover, and break the single-poll-loop model.
- **DD-2 — `schema_version` 1 → 2 + a PT-1 fixture extension.** Because `kb_state` grows from three
  scalars to a nested object, the wire shape changes, so feature-003's `schema_version` bumps to `2`
  (the version exists precisely to fail loud on a shape change, feature-003 DM-1). The cost is a one-line
  constant on each server + the front-end's `EXPECTED`, plus extending feature-003's PT-1 parity fixture
  with a populated `.aid/knowledge/` (incl. a stale-INDEX case) so the new fields are proven
  byte-identical across the Python and Node runtimes. The three thin hook fields are retained verbatim,
  so **feature-006's KB card needs zero change**. This is the genuine cross-feature impact worth user
  attention: it touches feature-002 (reader), feature-003 (`schema_version` + PT-1 fixture), and is
  consumed by feature-006 (card) — all additively.
- **DD-3 — INDEX freshness is a reader-cheap proxy, not a per-poll CI shell-out.** "INDEX up-to-date"
  (FR15) is authoritatively the kb-hygiene CI definition (regenerate + diff, `test.yml:118`). At ~5s
  poll cadence the reader cannot shell out to `build-kb-index.sh` every tick (NFR4 + the reader's
  no-subprocess read path). It instead computes a deterministic proxy (doc-set + intent-line comparison
  matching the CI script's own doc-selection rule) and reports `fresh`/`stale`/`unknown`, surfacing
  *likely* staleness so the operator acts (FR18); the authoritative gate remains CI. Registered as KI-007.

---

### Acceptance-criteria → spec map

| AC (this SPEC) | Requirement | Satisfied by |
|----------------|-------------|--------------|
| KB card click opens a dedicated KB dashboard | FR15 | Rendered on feature-006's `#/kb` route (SEAM-1); FC-1/FC-2; LC-KV view |
| lists KB docs with completeness/status | FR15, FR6 | UI-2 doc inventory from `KbModel.docs[]` (README `## Completeness` rows: name/category/status/last-reviewed/notes) |
| shows freshness (INDEX up-to-date; summary current/approved) + last update | FR15 | UI-3 freshness panel: `index.state` (DD-3 proxy = kb-hygiene definition) + `summary` (approved/grade/dates) + `knowledge-summary.html` presence |
| read-only | NFR2 | front-end-only view + reader-side reads only (LC-KR inside the audited read-only reader); no write, no new server surface |
| matches summary visual style; responsive; cross-browser | NFR8, NFR6, NFR5 | UI-1 design-family reuse (same `knowledge-summary/` family); UI-6 768px collapse + baseline primitives + Playwright gate |
| (cross) live ≤ interval | FR4, NFR3 | FC-3 re-render on the shared feature-003 poll loop; reader recomputes freshness/summary each pass |
| (cross) no-LLM | NFR7 | deterministic string/file comparisons in LC-KR; no inference; status/freshness rendered literally |
| (cross) step-by-step remediation for KB state needing action | FR18 | UI-4 panels (no-KB / INDEX stale / docs incomplete / summary unapproved) — each with exact command + verify, tied to the live poll |

---

### Known issues registered by this feature

This feature is a **read-only projection** of KB state: a reader sub-parser (inside feature-002's audited
read-only reader) + a front-end view on feature-006's existing route + shared poll loop. The
`schema_version` bump (DD-2) is a planned, contained contract evolution (front-end `EXPECTED` + PT-1
fixture grow in lockstep), not a defect. It registers **one** genuine known issue:

- **KI-007** — the dashboard's "INDEX fresh/stale" signal is a **reader-cheap deterministic proxy**
  (doc-set + intent-line comparison, DD-3), not a per-poll run of `build-kb-index.sh`. It is a **subset**
  of the kb-hygiene CI check: it catches the common drift (a doc added/removed without an INDEX regen,
  or an intent-line change) but **not** `kb-category:` re-classification or `source:`/`generator:`
  frontmatter changes (which CI's full-regen-diff catches) — those go undetected by the proxy (it may
  still say `fresh`). It may also report `unknown` on a hot poll (when it skips per-doc frontmatter). It
  is advisory; the authoritative freshness gate is the CI job (`.github/workflows/test.yml` `kb-hygiene`,
  `test.yml:118-126`). Revisit if a cheaper exact comparison becomes available.

(KI-001/KI-002 are feature-001's; KI-003/KI-004 are feature-002's, consumed not duplicated. The
`schema_version` 1→2 bump is recorded as a cross-feature impact in DD-2, coordinated with feature-002 +
feature-003 + feature-006, and is not a standalone debt entry.)

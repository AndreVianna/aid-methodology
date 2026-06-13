# Plan — work-001-aid-dashboard (AID Dashboard)

> Delivery roadmap.
> **Delivery spine (authoritative):** `d001 → d002 → {d003, d006 → d004 → d005}` — acyclic. (d006
> hangs off d002's reader/front-end + d001's state contract; **d006 lands before d004** because d004's
> project main page consumes the work-overview metadata — real Name/Description/phase/delivery
> grouping — that d006/feature-009 produces. d003 still hangs off d002 independently.)
> **Feature spine (within/across deliveries):** `001 → 002 → 003 → (004 → 005) → 009 → 006 → (007 → 008)`
> — feature-009 (d006) lands after the 004/005 CLI/remote features but **before** 006 (d004 project main page),
> mirroring the delivery spine's `d006 → d004` insertion. (Parenthesised pairs = ordered within a delivery.)
> **Full MVP = delivery-001 + delivery-002 + delivery-003** (AC1–AC5 local view + laptop remote).
> All 9 features assigned; none deferred. Authored by /aid-plan 2026-06-10; delivery-006/feature-009
> added by /aid-plan 2026-06-11 (producer-loop closure surfaced in the delivery-002 re-gate).
> **Two-level re-architecture re-plan (2026-06-12):** the superseded delivery-005 is re-planned into the
> **spine → KB tier → drill-down** triplet on **fresh delivery numbers 008/009/010** (005 not reused;
> 006/007 DONE). Extended delivery spine:
> `…d004 → d008 → d009 → d010` — **d008 (spine: feature-010 + feature-006 revision)** is the precondition
> for both **d009 (KB tier: feature-007 re-scope)** and **d010 (drill-down: feature-008)**; d009 and d010 are
> independent of each other (sequenced d009-then-d010 by the user directive that drill-down ships after the
> refactor). Extended feature spine: `… → 010 ∥ 006-rev (d008) → 007 (d009) → 008 (d010)`.
> **Sequence rationale (spine → KB tier → drill-down):** (1) **d008 first** because it is the spine — it
> is the only delivery that produces a *functional new entry point* (the CLI home + multi-repo server), and
> **everything downstream is reached through it**: feature-007's `kb.html` has no route to be served and
> feature-008's drill has no per-`<id>` `/api/model` surface until the multi-repo server exists. d008 also
> owns the one **hard precondition** of the whole effort — the **install-tree relocation / vendoring of the
> server + reader** (R8, intersecting MEMORY "dashboard not install-wired") — which must be resolved in d008
> (a server in `$AID_HOME` that was never vendored does not run). (2) **d009 next** because the KB tier is
> the next-most-valuable functional slice once the spine can serve it (KB always-viewable + live freshness),
> and it depends only on d008's server route + relocated reader. (3) **d010 last** by explicit user directive
> (drill-down is excluded from the two-level refactor and ships after it); it depends on d008's spine but not
> on d009, so it could in principle precede d009 — it is sequenced last by directive, not by dependency.
> **Planning risk to resolve: the d008 packaging / install-wiring decision (R8)** — confirm at /aid-detail
> whether the server+reader co-vendor is one task inside d008 (recommended) or a gating precondition task,
> and escalate to a human decision if it proves larger than a co-vendor unit.
> **Upgrade-migration re-plan (2026-06-13):** feature-011 (upgrade migration — FR37–FR40 / NFR12 / C8) is
> sequenced as a single cohesive **delivery-011** (the upgrade-migration capability — per-repo migration +
> the two `aid update` reaches + the sentinel/postinstall trigger + the `home.html` vendoring). It **resolves
> KI-010** (the `home.html`-not-provisioned gap — the migration's add-step + a fresh `aid add` finally
> provision the per-repo SPA shell). Extended delivery spine: `…d008 → {d009, d010, d011}` — **delivery-011
> depends on the d008 spine** (the served per-repo `home.html` route + the relocated install-tree reader/
> server it provisions for) and reuses the **delivery-009 FR31** legacy-summary relocation precedent; it is
> **independent of delivery-010** (no drill / `?detail=` surface). delivery-011 is **NOT a release blocker**
> (user 2026-06-13: negligible current adoption) but this version carries the migration. It lands in the
> **hand-maintained** `bin/aid` + `bin/aid.ps1` twin + the package/vendor layer (C8) — its gates are
> **ASCII-only + Bash↔PowerShell parity + vendor-refresh + the new migration tests + R5**, NOT render-drift
> (R16–R20 below). One delivery, not two — rationale recorded on the delivery-011 block.

## Deliverables

### delivery-001: Normalized state foundation + read model
- **What it delivers:** A shippable, behavior-preserving pipeline improvement — a typed,
  single-source `## Pipeline Status` state contract (KI-001/KI-002 reconciled; the FR16
  lifecycle deterministically derivable) — **and** a tested read-only `read_repo()` library
  that produces a normalized model of any repo's `.aid/` state. No UI; independently verifiable
  (feature-001's C4 suite stays green; feature-002's reader passes its AC against fixtures).
- **Features:** feature-001-pipeline-state-architecture, feature-002-state-reader-foundation
- **Depends on:** —
- **Priority:** Must (MVP foundation)
- **Sequencing note:** feature-001 ships incrementally (M0 doc-reconcile first — no behavior
  change; then M1–M6). feature-002 is **fallback-first** (works against today's state), so
  001-M1..M6 and 002 proceed in parallel after M0; 001-M6 retires 002's fallback branches.
  The 001↔002 enum source-of-truth + IMPEDIMENT-path coupling (KI-003) is kept inside this one
  delivery gate.

### delivery-002: Local pipeline dashboard (the AC1–AC5 local-view milestone)
- **What it delivers:** The first *usable* dashboard. `aid dashboard start node|python` launches
  a local, browser-viewable, live-polling single-pipeline view: stages / where-we-are (AC1),
  current + parallel tasks with state (AC2), paused/blocked/error call-outs (AC3), live ≤5s
  updates (AC4), served locally and **never public** (AC5). `aid dashboard stop` tears it down.
- **Features:** feature-003-pipeline-dashboard-app, feature-004-cli-dashboard-control
- **Depends on:** delivery-001 (`read_repo()`)
- **Priority:** Must (MVP)
- **Sequencing note:** Agree the **LC-1 spawn seam** (server entry-points `server.py`/`server.mjs`
  + `--root/--host/--port` arg grammar) as the first task — feature-004 proposed it, feature-003
  names neither yet. `--remote` is wired as a clear-fail stub here (exit 10, never public) and made
  real in delivery-003.

### delivery-003: Secure remote testing from the laptop
- **What it delivers:** `aid dashboard start <runtime> --remote` exposes the local dashboard to
  the operator's own laptop over a private, host/user-ACL-scoped Tailscale channel — never public.
  Completes the user's stated MVP (laptop remote-testing).
- **Features:** feature-005-secure-remote-exposure
- **Depends on:** delivery-002 (feature-004's `--remote` call site + feature-003's bound `127.0.0.1`
  port)
- **Priority:** Must (MVP — per user)
- **Sequencing note:** Ratifies the **LC-2 expose/teardown seam** feature-004 only proposed
  (opaque handle `tailscale-serve:<port>`; 005's exits 10/11/12 → 004's user-facing exit 10).
  Separated from delivery-002 to make the seam-agreement an explicit gate and to give the
  security-critical work (never-funnel guard, ACL-grant model, KI-005/KI-006) a focused review.
  delivery-002 + delivery-003 together = the full MVP.

### delivery-006: Producer state emission (close the producer loop — dashboard renders REAL data)
- **What it delivers:** The data-contract fix the shipped dashboard needs. The pipeline **skills
  become the canonical producers** of every field the dashboard consumes:`/aid-interview` writes a
  typed work **Name/Description** header into `REQUIREMENTS.md` (PF-1); `/aid-detail` guarantees a
  descriptive `# task-NNN: <title>` short-name (PF-3) and emits a machine-parseable **`wave-map`
  block** per delivery in `PLAN.md`'s Execution Graph so the reader derives each task's
  (delivery, lane) (PF-5a); the `## Pipeline Status` block is confirmed the single phase source
  (PF-4). The reader (Python + Node, byte-parity) and front-end are **reconciled to these real
  formats** (drop the invented `delivery-NNN-wave-M` `parseWave()`, skip `> _Status:_` Objective
  blockquotes PF-2, strip the `settings.yml` inline comment PF-6, uniform degradation sentinels PF-7);
  the PT-1 fixture is **regenerated from real producer output** and guarded by a producer↔consumer
  **contract test**; **work-001 is migrated** to the canonical schema (FR26); and the canonical edits
  are **dogfood-rendered** into `.claude/skills/` via the FULL `run_generator.py` (FR24). Envelope
  `schema_version` moves **2 → 3**. Without it the only real work in this repo mis-renders (`work_id`
  title, leaked blockquote, `Delivery #0`, `phase unknown`).
- **Features:** feature-009-producer-state-emission
- **Depends on:** delivery-002 (feature-002 reader Python+Node, feature-003 front-end/index.html +
  envelope/PT-1 parity), delivery-001 (feature-001 `## Pipeline Status` state contract — the single
  phase source PF-4 confirms)
- **Priority:** Must (the data-contract fix the shipped dashboard needs; closes the consumer-first
  producer gap surfaced in the delivery-002 re-gate)
- **Sequencing note:** Numbered **006** (004/005 were already reserved for features 006/007/008) but
  executes **before delivery-004** in the spine: `…d003 → d006 → d004 → d005`. d004 (feature-006
  project main page) consumes the work-overview metadata — real Name/Description/phase + delivery/lane
  grouping — that d006 produces, so d006 must land first or d004's multi-work cards render the same
  garbage this feature fixes. **Owns the move to `schema_version 3`** (see the schema-sequencing note
  below and R2); behavior-preserving (C4/C5 — producer edits only **add** display fields; the reader
  stays read-only/no-LLM). Every parse rule is mirrored Python↔Node and guarded by PT-1 byte-parity;
  the front-end change is Playwright-validated over the **migrated real work-001 repo** (R5 hard gate).

### delivery-004: Project main page (dashboard of dashboards)
- **What it delivers:** The Level-1 entry point — a card per work (lifecycle state + FR11
  attention emphasis), the KB summary card, the Level-0 CLI info panel, click-to-drill
  navigation, and the FR18 step-by-step empty-state. Turns the single-pipeline MVP into a
  multi-work navigation surface.
- **Features:** feature-006-project-main-page
- **Depends on:** delivery-002 (feature-002 model + feature-003 SPA shell/poll loop), **delivery-006
  (feature-009 work-overview metadata — real Name/Description/phase + delivery/lane grouping the
  multi-work cards display; without it d004's cards render the `work_id`/`Delivery #0`/`phase unknown`
  garbage d006 fixes)**
- **Priority:** Should
- **Sequencing note:** Front-end-only and additive (no server / `schema_version` / `/api/model`
  change of its own — it builds on the `schema_version 3` floor delivery-006 establishes; adds a
  `render(model, selectedWorkId)` selection param to feature-003's render). Lands **after
  delivery-006** (spine `d006 → d004`) so the cards consume real work-overview metadata, and **before
  delivery-005** because it defines the router seams both later views consume (`#/kb` / SEAM-1 for
  feature-007; `#/work/<id>/task/<task-id>` / SEAM-2 for feature-008).

### delivery-005: KB dashboard + task drill-down

> ⚠️ **SUPERSEDED (2026-06-12) — DO NOT EXECUTE AS WRITTEN.** This entire delivery-005 block (features
> 007+008 grouped; tasks 030–037; the rich-`KbModel` + `schema_version 1→3` approach) is **superseded by
> the two-level re-architecture** and will be **fully re-planned in this effort** during the upcoming
> /aid-plan phase. Specifically: **feature-007 is RE-SCOPED** — the rich `KbModel` build is **dropped**
> (it now serves a pre-rendered `kb.html` + a 5-state derived card + a graceful git read + the producer
> chain — see feature-007/SPEC.md "Re-architecture Re-scope"); **feature-008 is DEFERRED to its own
> separate later delivery.** The text below (What/Features/Depends/Sequencing + the delivery-005 execution
> graph) is the **historical pre-re-architecture record** kept for traceability; the new delivery
> breakdown is authored by the upcoming /aid-plan, not here. STATE.md marks tasks 030–037 **Superseded
> (pending re-plan)** accordingly.

- **What it delivers:** Two forensic depth views — the dedicated **KB dashboard** (doc inventory,
  INDEX freshness, summary/approval status, FR18 remediation) behind the KB card; and the
  **skill/task drill-down** (findings, review ledger/grade, raw STATE.md viewer, honest logs
  panel, parallel-task drill) behind each task chip.
- **Features:** feature-007-kb-dashboard, feature-008-skill-task-drilldown
- **Depends on:** delivery-004 (feature-006 router seams SEAM-1/SEAM-2), delivery-002 (feature-002
  reader, feature-003 envelope/PT-1)
- **Priority:** Should
- **Sequencing note:** Grouped to share **one combined envelope-growth bump** (both grow the
  same `/api/model` envelope + PT-1 parity fixture + front-end `EXPECTED`). Build order **within**
  the delivery: feature-007 first (reader/envelope growth), then feature-008 (the lazy `?detail=`
  `TaskDetail`), shipped as one cut — one fixture pass, one coordination review instead of two churns
  through the same files.
  - **Schema-sequencing re-baseline (feature-009 supersedes task-034's "1→3").** delivery-006/
    feature-009 **owns the move to `schema_version 3`** and lands it first (the per-task `delivery`/
    `lane` integers + task `short_name`). task-034's original "schema_version 1→3" wording is therefore
    **stale and superseded**: the floor when delivery-005 builds is **3**, not 1. Concretely — if
    007/008 further change the wire shape (they grow the envelope), task-034 re-baselines to a **3→4
    cut** (envelope → 4, front-end `EXPECTED` → 4, PT-1 → 4); if 007/008 add no wire-shape change they
    **stay at 3** and task-034 carries no bump. The exact 3-vs-3→4 choice is finalized when task-034 is
    re-detailed in /aid-detail; either way the schema **floor is fixed at 3 by feature-009**. (See R2.)

---

> ## Two-level re-architecture deliveries (authored by /aid-plan 2026-06-12)
>
> The three blocks below are the **go-forward re-plan** of the superseded delivery-005, sequencing the
> now-A+ re-architecture feature SPECs (feature-010 spine, feature-006 revision, feature-007 re-scope,
> feature-008 deferred) into functional-MVP slices. **Fresh delivery numbers continue the existing
> 001–007 sequence:** the next free numbers are **008 / 009 / 010** (005 is superseded — *not* reused;
> 006/007 are DONE). **The agreed split (interview-phase recommendation, user-confirmed):**
> **delivery-008 = the two-level spine**, **delivery-009 = the KB tier**, **delivery-010 = task
> drill-down** (after the refactor). Tasks are numbered from a fresh counter past task-045 in /aid-detail
> (task breakdown is owned by /aid-detail, not this plan).

### delivery-008: The two-level spine (CLI home + repo registry + multi-repo server)

- **What it delivers:** The **machine/CLI tier** of the two-level dashboard — the first functional win is
  that **`aid dashboard start <runtime>` now opens a CLI home that lists every registered repo, and
  clicking a repo-card opens that repo's live per-repo pipeline view.** Concretely: feature-010 lands (a)
  a machine-level repo registry at **`$AID_HOME/registry.yml`** (paths-only, maintained as a *side-effect*
  of the existing `aid add`/`aid remove` — first-tool-add registers, last-tool-remove unregisters, no new
  verb, host-tool behavior unchanged — OQ6), (b) the **contract-level rewrite of feature-003's delivered
  closed two-route server** into a **NEW closed allowlist** (`/` + `/api/home` + per-repo
  `/r/<id>/{home.html,kb.html,api/model}`, hex-`<id>` addressing via CAN-1, construct-not-sanitize
  traversal refusal, **PT-1-H byte-parity extended to the multi-repo shape**), and (c) the **CLI home
  page** (`$AID_HOME/dashboard/index.html` — the relocated Level-0 machine panel + the registered-repo
  card grid + unavailable/prune handling). feature-006's revision lands in lockstep: the delivered d004
  `dashboard/index.html` is **re-homed to `<repo>/.aid/dashboard/home.html`** and the **Level-0 panel is
  dropped** from the per-repo page (it now lives on the CLI home). `--remote` (OQ5) re-points feature-005's
  unchanged Tailscale layer at the CLI home (all registered repos).
- **Features:** feature-010-cli-home-and-registry (spine), feature-006-project-main-page (revision —
  home.html rename + L0-panel removal + the KB-card **slot**).
  - **KB-card intermediate state (a real cross-delivery subtlety to honor at /aid-detail):** feature-006's
    KB card cannot show feature-007's **5-state** model in d008 — feature-007's reader KB-status extension
    + the served `kb.html` land in **d009**. So in d008 the KB-card slot **keeps the delivered d004 2-state
    behavior** (Approved/Draft/`null`→"no KB") and is **repointed to feature-007's 5-state source +
    `/r/<id>/kb.html` in d009** (feature-006 R-3/R-5: the d004 `null`→"no KB" maps onto feature-007's
    `pending` state). The repoint is therefore a **d009 step on feature-006's slot**, not a d008 one;
    d008 ships the slot in its carried-over d004 form so there is no broken intermediate (the card always
    renders a valid state). Confirm this slot-ownership split at /aid-detail.
- **Functional-MVP rationale:** This is a genuine end-to-end slice, not a refactor-for-its-own-sake. After
  it lands the operator has a **new working entry point above the per-repo dashboard**: one `aid dashboard`
  serves the machine home, enumerates the repos AID manages on this box, and navigates into each repo's
  existing (d002/d004/d006) live pipeline view — which keeps working verbatim behind its per-repo `<id>`
  route. Independently verifiable: the registry round-trips on add/remove; the multi-repo server serves
  `/` + every `/r/<id>/...` and refuses every traversal/unregistered path; PT-1-H proves both runtimes stay
  byte-identical; Playwright renders the CLI home + a click-through into a repo's `home.html` (R5 hard gate).
- **Depends on:** the **delivered d001–d004 + d006/d007 base** — specifically feature-002 `read_repo`
  (run per registered repo), feature-003's server (the thing being contract-rewritten) + its PT-1 harness
  (extended to PT-1-H) + the d004 `index.html` main-page view (re-homed to `home.html`), feature-004's
  `aid dashboard start/stop` spawn seam (re-pointed from a single `--root` to `$AID_HOME`/registry),
  feature-005's `--remote` expose helper (re-targeted, mechanism unchanged), and the schema-3 floor + real
  producer data from d006/d007. **No prior new delivery** — delivery-008 is the first of the re-architecture
  triplet and depends only on the shipped base.
- **Priority:** Must (the spine — feature-006's `home.html` and feature-007's `kb.html` are both reached
  *through* this home + server; nothing in the KB tier is reachable until this lands).
- **Cross-cutting risks / preconditions (see R8 + R9 below):**
  - **R8 — packaging / install-tree relocation is a real precondition of this delivery (the headline
    planning risk).** feature-010 **relocates the server entry-point into the install tree**
    (`$AID_HOME/dashboard/server/server.{py,mjs}`) because the machine server must serve *all* registered
    repos, not one repo's checkout. This intersects the known **"dashboard not install-wired"** gap
    (MEMORY): today the per-repo `dashboard/` runs only from a repo checkout and is **not** vendored into
    the npm/pypi packages. **Planning decision (stated, to be ratified at the delivery gate): the spine
    delivery MUST resolve the install-wiring/vendoring of the server unit itself** — it cannot defer it,
    because a server that lives in `$AID_HOME` but was never vendored there does not exist at runtime. The
    vendored unit is **NOT the server entry alone**: the feature-002 reader (LC-R) must be **co-vendored
    and importable from the new `$AID_HOME/dashboard/` layout** (the Python server does a `sys.path` insert
    relative to `dashboard/`'s parent and `import read_repo`; the Node twin likewise) — relocating the
    entry without co-vendoring the reader on the same relative module layout is a runtime import failure
    (feature-010 residual item #1). **Scope boundary:** this delivery wires the *dashboard server + reader*
    into the install tree (the minimum the spine needs to run from `$AID_HOME`); it does **not** owe a
    full general dashboard-distribution story beyond that unit. If detail-phase analysis finds the
    vendoring is larger than a co-vendor-two-modules task, escalate to a human decision **before** executing
    — do not let an unbounded packaging effort balloon the spine. **(Flag: confirm at /aid-detail whether
    install-wiring is one task inside d008 or a gating precondition task; the recommendation is the former —
    a co-vendor task in the same delivery, because the server is non-functional without it.)**
  - **R9 — contract-level rewrite of a *delivered, gated* server (the C6 blast radius).** feature-010 does
    not extend feature-003's server, it **replaces its closed two-route allowlist** with a new one and must
    re-prove every hard invariant (loopback bind C1/C2, no-write NFR2 across N roots, no-LLM NFR7,
    no-traversal C6) plus **extend PT-1 → PT-1-H** to the multi-repo shape (registry fixture, per-`<id>`
    `/api/model` byte-parity, identical traversal-refusals across runtimes). The d002 re-gate already proved
    fixture-only parity can mask real cross-runtime divergences (the minimal-work `number` + header-less
    table bugs) — so PT-1-H must exercise an unavailable repo, a header/no-home repo, and the cross-runtime
    `<id>` derivation, not only the happy path.
  - **R10 — `bin/aid` is hand-maintained, not a render artifact (carried from R6).** The registry
    side-effect + the spawn-seam change are **direct edits to root `bin/aid` + `bin/aid.ps1`** with the
    ASCII-only + Bash<->PowerShell-parity + vendored-copy-refresh gates (NOT render-drift / `run_generator.py`).
  - **R5 — Playwright visual gate (hard, project policy)** applies: the CLI home + the click-through into a
    repo's `home.html` must render and be visually validated; source-only review is an automatic FAIL.

### delivery-009: The KB tier (served kb.html + 5-state card + reader git-read + producer chain)

- **What it delivers:** The **KB always-viewable + live-freshness** tier. feature-007 (re-scoped) lands:
  (a) **`aid-summarize` relocates its output** to `<repo>/.aid/dashboard/kb.html` (from
  `.aid/knowledge/knowledge-summary.html`), which the spine's server already routes at `/r/<id>/kb.html`;
  (b) the reader gains a **5-state KB status derivation** (pending -> generating -> preparing -> approved ->
  outdated) + a `summary_present` flag + a **cross-runtime, read-only, byte-identical default-branch
  `git log -1` freshness read** (FR35) compared to a new **`/aid-config`-owned `.aid/settings.yml
  kb_baseline` key**, **degrading gracefully** to `approved` on every git failure mode; (c) the **producer
  chain** — `aid-discover` **auto-triggers `aid-summarize` at its close** (FR34, the one deliberate
  *new* behavior, not C4-preserving) + records the baseline; `aid-housekeep` regenerates the summary,
  resolves `outdated`, re-stamps the baseline; all dogfood-rendered via the **FULL `run_generator.py`**
  (C7). feature-006's KB-card **slot** (already repointed in d008) now shows the live 5-state card and
  opens the served `kb.html`. **No `schema_version` bump** — `kb_state` stays a strict superset at the
  same `/api/model` path (the deliberate simplification vs the dropped rich `KbModel`).
- **Features:** feature-007-kb-dashboard (re-scoped). (feature-006's KB-card host slot was delivered in
  d008; this delivery fills its states + target.)
- **Functional-MVP rationale:** A self-contained user win on top of the spine — **the KB is always
  viewable and its freshness is live.** Before this, the spine's `/r/<id>/kb.html` route exists but serves
  nothing (`has_kb=false`, card shows "pending/preparing"); after this, a discovered repo auto-produces its
  `kb.html`, the card derives one of five honest states from disk, and `outdated` flags a stale summary
  against the branch tip — viewable independently per repo. Verifiable: the 5-state waterfall is a pure
  function of disk; the git-read byte-parity is provable (frozen-tip fixture); the discover->summarize chain
  is exercised end-to-end; the FULL generator render-drift stays clean; Playwright renders the served
  `kb.html` + each card state (R5).
- **Depends on:** **delivery-008** (the spine — the multi-repo server's `/r/<id>/kb.html` static route +
  `<id>` addressing must exist for `kb.html` to be *served*, and the install-wired reader/server unit is
  where the new KB-status read lives), plus the delivered base (feature-002 reader / `KbStateRef` it
  extends, feature-003 `/api/model` envelope + PT-1 it extends, feature-006's KB-card slot). **Hard
  ordering: d009 cannot precede d008** — there is no route to serve `kb.html` and no relocated reader to
  carry the git-read until the spine lands.
- **Priority:** Should (the KB tier ships *after* the spine; the spine is Must, the KB tier is the
  next-most-valuable slice).
- **Cross-cutting risks / preconditions:**
  - **R11 — the FR34 discover->summarize auto-trigger is a deliberate behavior *change*, not C4-preserving.**
    Every other producer edit here is behavior-additive (path relocation, baseline record/resolve), but
    `aid-discover` gaining an auto-invocation of `aid-summarize` + a new `kb.html` output is an **intended
    new closing behavior**. It **composes** (does not replace) the two existing approval gates — discovery's
    KB approval + summarize's V1. The delivery gate must confirm it adds the auto-trigger without regressing
    either gate, and that the FULL `run_generator.py` re-render of the three KB-domain producers
    (`aid-summarize`/`aid-discover`/`aid-housekeep`) + the `/aid-config` `kb_baseline` schema stays
    render-drift-clean across all 5 install trees + `.claude/` (R1 blast-radius discipline).
  - **R12 — cross-runtime git-read byte-parity (a new instance of R7).** Python `subprocess` and Node
    `child_process` must call the **identical** `git log -1 --format=%cI <branch>` argv and normalize the
    committer-local-offset date to a common UTC instant **identically** (never a raw lexicographic string
    compare) — the same Python<->Node divergence class PT-1 guards, now over a *live, non-deterministic* git
    tip. PT-1-H must freeze/stub the tip (or normalize/exclude the field) so the parity assertion is
    reproducible (feature-007 residual #4/#5), and prove the `Z`-vs-`+HH:MM` same-instant boundary agrees.
  - **R13 — `kb_baseline` is a new multi-line settings block, written via the append-block path.**
    `kb_baseline: {branch, tip_date}` is a **nested block**, so the producers' *first* write uses
    `/aid-config`'s "append a new block" idiom (not the single-line "save in place" replace); a re-stamp of
    `tip_date` is a single-line replace within the existing block. `/aid-config` owns the schema key + its
    validation (feature-010 residual #5 cross-references this — the two features' `settings.yml` reads must
    agree).
  - **R5 — Playwright visual gate (hard)** applies to the served `kb.html` + the 5-state card rendering.

### delivery-010: Task drill-down (Level-3 forensic detail) — separate, after the refactor

- **What it delivers:** The deepest drill tier (feature-008, scope **unchanged** from its A+ SPEC): from a
  skill/task in the per-repo pipeline view, the operator opens **all** of its forensic detail — findings,
  the review ledger / grades, the raw `STATE.md` content, an honest logs panel — with **parallel/concurrent
  tasks** each individually drillable. Read-only. This is the forensic depth beyond the at-a-glance d002/d006
  progress view.
- **Features:** feature-008-skill-task-drilldown (DEFERRED — scope unchanged; sequencing changed only).
- **Functional-MVP rationale:** An additive depth view that stands alone — it grows the per-repo page's
  drill (`#/work/<id>/task/<task-id>` SEAM-2) into a lazy `?detail=` `TaskDetail` reader/server growth +
  front-end view, without touching the spine or KB tier. A clean, independently-shippable slice; explicitly
  **excluded from the two-level refactor** (user directive) and scheduled **after** it so the refactor isn't
  blocked on the forensic tier.
- **Depends on:** **delivery-008** (the spine — feature-008 drills *within* a per-repo `home.html`, reached
  through the multi-repo server's `/r/<id>/...` routes; its detail endpoint grows the per-repo `/api/model`
  surface the spine now serves per `<id>`) and the delivered base (feature-002 reader, feature-003 envelope
  + PT-1, feature-006's per-work drill route SEAM-2). It does **not** depend on delivery-009 (the KB tier) —
  drill-down and the KB tier are independent and could in principle be sequenced either order after the
  spine; the plan sequences it **last** per the user directive that it ships after the refactor.
- **Priority:** Should (after the refactor — the lowest-urgency of the three, deferred by user directive).
- **Cross-cutting risks / preconditions:**
  - **R14 — schema/envelope growth coordination (a focused instance of R2).** If feature-008's
    `?detail=`/`TaskDetail` grows the `/api/model` wire shape, it re-baselines off the schema-3 floor
    feature-009 fixed (a 3->4 cut, or stays at 3 if no wire-shape change) — front-end `EXPECTED` + both
    servers' envelope + DM-3 key order + PT-1/PT-1-H move in lockstep; the stale-assets banner fails loud
    on any mismatch. The exact bump-vs-no-bump is finalized when feature-008 is detailed.
  - **R15 — raw `STATE.md` viewer must stay read-only + escaped (NFR2 + no injection).** The forensic raw
    viewer renders arbitrary `.aid/` content; it must escape it (no HTML/script injection) and never offer
    a write surface, preserving the no-write / no-LLM contract across the now-N-root server (the served raw
    content still flows only through the spine's construct-not-sanitize static path discipline, R9).
  - **R5 — Playwright visual gate (hard)** applies to the drill view (findings, ledger, raw-state, logs,
    parallel-task drill).

### delivery-011: Upgrade migration (per-repo compliance + machine scan + home.html vendoring) — resolves KI-010

- **What it delivers:** The **closure of the two-level re-architecture for repos that predate it.** After
  d008–d010, a repo's live page is `<repo>/.aid/dashboard/home.html`, its KB summary is
  `<repo>/.aid/dashboard/kb.html`, and it must be in `$AID_HOME/registry.yml` to appear on the CLI home —
  but **older repos comply with none of this** (KI-010: `home.html` is neither vendored, generated, nor
  scaffolded; a repo may carry a legacy `knowledge-summary.html`, a missing/invalid `settings.yml`, and be
  unregistered — so its per-repo dashboard cannot be served). delivery-011 lands feature-011 in full: (a)
  an **idempotent, read-mostly per-repo upgrade migration** (`_aid_migrate_repo`, FF-1) that does exactly
  four additive/no-clobber things, each only when not already satisfied — **validate/repair or synthesize
  `.aid/settings.yml`** (era-a vs era-b, DM-1/RC-4), **add `home.html`** (copy the vendored source, FR40),
  **relocate the legacy KB summary** (`mv -n`, the FR31 idiom reused, DM-4), and **register the repo**
  (reusing feature-010's idempotent `registry_register`, DM-2); (b) the **two reaches through the existing
  `aid update`** (no new verb, FR38) — `aid update self` updates the CLI then **scans the machine** and
  migrates each discovered repo behind an **All/Yes/No/Cancel** consent prompt (FF-2/CLI-1), while
  `aid update [<tool>]` updates the CLI if stale then migrates **only the current repo** (FF-3/CLI-2); (c)
  the **trigger machinery** (FR39) — a **version-sentinel lazy first-run** check in `bin/aid` against the
  `$AID_HOME/.migrated` marker (DM-3, the universal cross-manager guarantee covering pypi/`--ignore-scripts`/
  curl) plus an **npm `postinstall`** eager path (FF-4); and (d) the **`home.html` single vendored source**
  (FR40/LC-HSRC/LC-VND) — the current `.aid/dashboard/home.html` content (which, sequenced after d008–d010,
  already includes all prior `home.html` work incl. d010's drill view) **moves** to a single
  committed source `dashboard/home.html`, is added to **both** vendor manifests so it installs to
  `$AID_HOME/dashboard/home.html`, and the dogfood repo's own `.aid/dashboard/home.html` becomes a
  **CI-equality-enforced derived copy** (DD-5). Detection is read-only, mutation is consent-gated, every
  write is additive/no-clobber/value-preserving, and a non-interactive context **defers** rather than
  silently mutating (NFR12; RC-3). **Resolves KI-010** — the R5 gate renders a freshly-migrated repo's
  provisioned `home.html`.
- **Features:** feature-011-upgrade-migration (FR37–FR40, NFR12, C8 — sole owner). Reuses (does not
  re-specify) feature-010's `registry_register`/`_registry_read_repos` (LC-REG, DM-2), the installer
  engine's `manifest_list_tools`/`manifest_read_*` (LC-CORE, era-b tool detection), feature-007/d009's FR31
  legacy-summary relocation idiom (DM-4), and feature-006's `home.html` SPA shell (provisioned, not
  re-authored).
- **Depends on:** **delivery-008** (the spine — the multi-repo server's per-repo `/r/<id>/home.html` route +
  the install-tree-relocated reader/server are the thing the provisioned `home.html` is served *through*;
  `registry_register`/`_registry_read_repos` and the CAN-1 canonicalization the migration reuses all land in
  d008's hand-maintained `bin/aid` + `bin/aid.ps1`), and **delivery-009** (the **FR31 relocation precedent** —
  d009's `aid-summarize` `knowledge-summary.html` → `.aid/dashboard/kb.html` relocation is the exact `mv -n`
  idiom DM-4 reuses, and d009 establishes `.aid/dashboard/kb.html` as the canonical summary target the
  migration moves toward). It has **no capability/route coupling to delivery-010** (the drill-down tier — feature-011 provisions
  and serves `home.html`/`kb.html`/`settings.yml`/registry, none of which touch the `?detail=`/`TaskDetail`
  surface). **Content-provenance caveat:** because feature-011 vendors `home.html` *as it then exists* and it
  **sequences after** d010 (already landed on the consolidated branch), the vendored source content
  **includes** d010's drill view — i.e. delivery-011 has no *functional* dependency on d010 but does inherit
  d010's `home.html` content by virtue of running after it (a sequencing fact, not a gate). It is the
  **last** of the re-architecture deliveries (it closes the layout for pre-existing repos once the spine +
  KB tier exist); functionally it could ship in either order relative to d010, but in practice it follows it.
- **Priority:** Should (closes KI-010 and FR37–FR40; **not a release blocker** per user 2026-06-13, but this
  version carries the migration — without it KI-010 stands and the per-repo dashboard is unserveable for any
  repo not hand-committed like the dogfood repo).
- **One delivery, not two — rationale:** feature-011 is a **single indivisible capability** (SPEC
  Decomposition Rationale): the per-repo migration (FR37) is inert without a reach (FR38) and a trigger
  (FR39), and its add-step (FR37) cannot function without the vendored `home.html` source (FR40) — which
  exists *only* to feed it. All four FRs land in the **same domain boundary** (the hand-maintained
  `bin/aid`/`bin/aid.ps1` + the package/vendor layer, C8) under one gate set. There **is** a clean
  foundation-vs-engine seam (the LC-HSRC `home.html` source-move + LC-VND vendoring is a self-contained
  Wave-1 foundation the LC-MIG add-step consumes), but it is a **wave seam, not a delivery seam** — splitting
  it into a delivery-012 would manufacture a cross-delivery dependency on a tiny surface (one source move +
  two manifest entries) and force the migration engine to depend on a half-delivery, with no independently
  shippable user value in the foundation alone (a vendored `home.html` nobody copies is inert). The cohesive
  delivery keeps every FR37–FR40 requirement owned once with no homeless piece, and the foundation/engine
  ordering is expressed as Waves 1→2 within the one delivery's execution graph. **One cohesive delivery-011;
  no delivery-012.**
- **Sequencing note:** Numbered **011** (next free; 005 superseded-not-reused, 006/007 DONE, 008–010 are the
  re-architecture triplet). Lands in **hand-maintained** `bin/aid` + `bin/aid.ps1` + the package/vendor layer
  (C8, carried from R10) — gates are **ASCII-only** (`test-ascii-only.sh`) + **Bash↔PowerShell parity**
  (`test-aid-cli-parity.sh`) + **vendor-refresh** (`vendor.js`/`vendor.py`, incl. the new `dashboard/home.html`
  entry) + the **new migration tests** (era-a/era-b/idempotency/no-delete/bare-`.aid`/cross-manager) + the
  **R5 Playwright hard gate** on a freshly-migrated `home.html` — **NOT** render-drift / `run_generator.py`
  (these files are not `canonical/`-rendered; R16 below). Same-file serialization: `bin/aid` is one file (its
  migration-function + dispatch-hook + sentinel writers serialize against each other), and `bin/aid.ps1` is
  its parity twin (R17). The d010 dogfood-`home.html` sync (OQ-5) and the residual scan-scope (OQ-1) /
  self-update-preamble (OQ-6) wirings are /aid-detail mechanics (the design is decided; see the residual OQs
  in feature-011 SPEC). Tasks are numbered from a fresh counter past **task-073** (task-074+) in /aid-detail.
- **Cross-cutting risks / preconditions (see R16–R20 below):** pypi-no-postinstall → sentinel reliance (R16);
  `bin/aid` PowerShell-twin parity drift across the new migration surface (R17); the `home.html` source-move
  must not break the live served per-repo page during the transition (R18); machine-scan scope/performance/
  safety — bounded, no-traversal, read-only-until-consent (R19); the dogfood `home.html` source/copy
  equality (R20); `settings.yml` repair must preserve `kb_baseline`/per-skill overrides (R21).
  **R5 — Playwright visual gate (hard)** applies to the freshly-migrated
  `home.html` (the concrete KI-010-resolved proof).

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| R1 | **C4 blast-radius of feature-001** — every canonical edit must re-run the FULL `run_generator.py` (5 byte-identical install trees + dogfood), keep `tests/run-all.sh` (35 suites) + the **Windows** installer suite green, and preserve observable pipeline behavior. | H | Per-increment C4 checklist (feature-001 §Migration); FULL generator (never per-script renderer); Windows runner in CI; any observable-behavior change = CRITICAL finding. (delivery-001) |
| R2 | **schema_version coordination** — a single shared counter, now **re-baselined by feature-009**. History: feature-003 shipped `1`, the delivery-002 work-overview re-gate moved it to `2`, and **delivery-006/feature-009 owns the move to `3`** (per-task `delivery`/`lane`/`short_name`). delivery-005's 007/008 envelope growth therefore re-baselines on top of 3 (a **3→4 cut**, or stays at 3 if no wire-shape change) — task-034's stale "1→3" is **superseded**. A mis/double bump mis-renders or trips the stale-assets banner. | M | **feature-009 is the sole owner of the move to `3`** and lands it first; front-end `EXPECTED` + both servers' envelope + DM-3 serializer key order + PT-1 fixture move to 3 **in lockstep**. the d009/d010 KB+drilldown envelope re-baselines off the **3** floor (3→4, or no-bump); task-034 superseded, re-detailed in /aid-detail. The stale-assets banner fails loud on any mismatch. (delivery-006 owns →3; d009/d010 re-baseline) |
| R3 | **LC-1 spawn seam (004↔003)** — feature-004 proposes server entry-point filenames + arg grammar feature-003 hasn't named. | M | Agree LC-1 as the first task of delivery-002 (both features in the same delivery → seam closed inside one gate). |
| R4 | **LC-2 expose/teardown seam (004↔005)** — opaque-handle shape, exit-code mapping, teardown semantics must match across the delivery boundary. | M | feature-005's SPEC ratifies LC-2; confirm feature-004's stub honors the ratified shape when delivery-003 lands; parity gate covers the `--remote` clear-fail path. |
| R5 | **Playwright visual-validation gate (project policy, hard)** — every web-output review (features 003/006/007/008) MUST render in Playwright and visually validate; source-only review = automatic FAIL. | H | Each UI-bearing delivery's review task includes a Playwright render step (layout, lifecycle states, FR11 attention, responsive, nav seams); Tailscale can serve the page privately for visual confirmation. (delivery-002, -004; re-arch UI now d008/d009/d010) |
| R6 | **`bin/aid` is hand-maintained (NOT a render artifact) + ASCII-only + Bash/PowerShell parity gates** — features 004/005 edit `bin/aid` + `bin/aid.ps1` directly. | M | Edit root `bin/aid`/`.ps1` only (vendored copies regenerate via prepack/vendor); ASCII-only help/error text; extend `test-aid-cli-parity.sh` for `dashboard start/stop` + `--remote` clear-fail. (delivery-002, -003) |
| R7 | **PT-1 cross-runtime byte-parity** — Python `json.dumps(ensure_ascii=False)` vs Node `JSON.stringify` diverge on `U+2028/U+2029`. | M | feature-003 DM-3: Python post-processes to the escaped (Node-default) canonical form; PT-1 fixture MUST contain a STATE.md with `U+2028`/`U+2029`; fixture accretes via PT-1-H in d008 + the KB/findings/ledger cases in d009/d010. (delivery-002; grows in d008-d010) |
| R8 | **Packaging / install-tree relocation precondition (feature-010, the headline re-arch risk)** — feature-010 relocates the server entry into `$AID_HOME/dashboard/server/server.{py,mjs}` so it can serve *all* registered repos; this intersects MEMORY "dashboard not install-wired" (the per-repo `dashboard/` is NOT vendored into npm/pypi today). A server in `$AID_HOME` that was never vendored there does not exist at runtime; co-vendoring is non-optional. | H | **Resolve install-wiring *inside* delivery-008** — vendor the server **unit** = `server.{py,mjs}` + the feature-002 reader module(s) it imports, laid out so the existing relative `sys.path`/`import read_repo` resolves from the new `$AID_HOME/dashboard/` location. Scope-bound to that unit (not a general distribution story). If detail-phase finds it larger than a co-vendor task, **escalate to a human decision before executing** — do not balloon the spine. Confirm at /aid-detail: install-wiring = one task in d008 (recommended) vs a gating precondition task. (delivery-008) |
| R9 | **Contract-level rewrite of the delivered, gated feature-003 server (C6 blast radius)** — feature-010 *replaces* the closed two-route allowlist, not extends it; must re-prove loopback-bind / no-write (N roots) / no-LLM / no-traversal and extend PT-1 → PT-1-H. The d002 re-gate proved fixture-only parity masks real cross-runtime divergences. | H | PT-1-H fixture must include an unavailable repo + a no-home/header-less repo + cross-runtime `<id>` derivation, not just the happy path; re-run every feature-003 self-check (grep no-`0.0.0.0`, no-`fs.write*`, no-LLM) against the rewritten LC-MS; construct-not-sanitize the static path. (delivery-008) |
| R10 | **`bin/aid` hand-maintained registry side-effect + spawn-seam edits (carried from R6)** — feature-010 edits root `bin/aid` + `bin/aid.ps1` directly (registry register/unregister, atomic write, `--root`→`$AID_HOME` spawn change). | M | Direct root-file edits only (vendored copies via prepack/vendor); ASCII-only; extend `test-aid-cli-parity.sh` for the add/remove registry side-effect + the spawn change; NOT render-drift / `run_generator.py`. (delivery-008) |
| R11 | **FR34 discover→summarize auto-trigger is a deliberate behavior *change*, not C4-preserving** — `aid-discover` gains an auto-invocation of `aid-summarize` + a new `kb.html` output; the one non-additive producer edit in the KB tier. | M | Confirm it **composes** (does not replace) the two existing approval gates (discovery KB approval + summarize V1); FULL `run_generator.py` re-render of the 3 KB-domain producers + `/aid-config` schema stays render-drift-clean across 5 trees + `.claude/` (R1 discipline). (delivery-009) |
| R12 | **Cross-runtime git-read byte-parity (new instance of R7)** — Python `subprocess` vs Node `child_process` must call identical `git log -1 --format=%cI <branch>` argv and normalize committer-local-offset dates to a common UTC instant identically (never raw string compare), over a *live, non-deterministic* git tip. | M | PT-1-H freezes/stubs the tip (or normalizes/excludes the field) for reproducibility; a unit case proves the `Z`-vs-`±HH:MM` same-instant boundary agrees; degrade-to-`approved` on every git failure mode. (delivery-009) |
| R13 | **`kb_baseline` is a new multi-line settings block (write-path correctness)** — `kb_baseline: {branch, tip_date}` is a nested block, so the first write needs `/aid-config`'s "append a new block" idiom, not the single-line "save in place" replace; a re-stamp is a single-line replace inside the block. | L | `/aid-config` owns the schema key + validation; producers (`aid-discover`/`aid-housekeep`) reuse the append-block-then-line-replace settings-write idiom; feature-010 residual #5 cross-checks the two features' `settings.yml` reads agree. (delivery-009) |
| R14 | **schema/envelope growth coordination for feature-008 (focused instance of R2)** — if `?detail=`/`TaskDetail` grows the `/api/model` wire shape it re-baselines off the schema-3 floor (3→4 cut, or stays at 3). | M | front-end `EXPECTED` + both servers' envelope + DM-3 key order + PT-1/PT-1-H move in lockstep; stale-assets banner fails loud on mismatch; bump-vs-no-bump finalized when feature-008 is detailed. (delivery-010) |
| R15 | **Raw `STATE.md` viewer read-only + escaped (NFR2 + no injection)** — feature-008's forensic raw viewer renders arbitrary `.aid/` content. | M | Escape rendered content (no HTML/script injection); no write surface; the served raw content flows only through the spine's construct-not-sanitize static-path discipline (R9), preserving no-write/no-LLM across N roots. (delivery-010) |
| R16 | **pypi has no install-time hook → the migration trigger relies on the sentinel (FR39/RC-1)** — PEP 517 wheels removed `setup.py install` hooks (grounding §3e), so an npm-only postinstall cannot guarantee the upgrade completes for pypi / `npm --ignore-scripts` / curl installs. If the trigger were postinstall-only, pypi upgrades would never migrate. | M | The **version-sentinel lazy first-run in `bin/aid`** (DM-3 `$AID_HOME/.migrated` vs `$AID_HOME/VERSION`, string-inequality DD-1) is the **primary, universal** guarantee covering all channels; the npm postinstall is an *eager* convenience only. The cross-manager trigger test (§6 gate 9) **exercises the pypi-no-postinstall sentinel-only path** explicitly, plus the no-loop steady state (SEC-6) and the non-interactive defer (RC-3). (delivery-011) |
| R17 | **`bin/aid` PowerShell-twin parity drift across the new migration surface (carried from R6/R10/R17-class)** — the whole LC-MIG function set (`_aid_migrate_repo`, `SCAN_FOR_AID_REPOS`, the All/Yes/No/Cancel loop, the sentinel R/W) plus the two dispatch hooks land in **both** `bin/aid` (Bash) and `bin/aid.ps1` (PowerShell); divergent era-a/era-b branches, prompt wording, advisories, exit codes, or WARN lines silently break Windows. | M | Direct edits to root `bin/aid` + `bin/aid.ps1` **only** (vendored copies regenerate via prepack/vendor); **ASCII-only** (`test-ascii-only.sh`, MEMORY "ASCII-only PowerShell scripts" — Windows ANSI-codepage hazard for prompt/advisory text); **Bash↔PowerShell parity** (`test-aid-cli-parity.sh` extended for the migration commands: era-a/era-b branches, All/Yes/No/Cancel wording, declined advisory, WARN lines, identical exit codes). **NOT** render-drift / `run_generator.py`. Same-file writers serialize (one `bin/aid`, one `.ps1` twin). (delivery-011) |
| R18 | **The `home.html` source-move (LC-HSRC) must not break the live served per-repo page during the transition** — feature-011 *moves* the d010 dogfood `.aid/dashboard/home.html` content to a new committed source `dashboard/home.html`; the multi-repo server (feature-010) keeps serving the **per-repo** `<repo>/.aid/dashboard/home.html` at `/r/<id>/home.html`. If the dogfood repo's own `.aid/dashboard/home.html` were deleted by the move (rather than kept as a derived copy), the dogfood dashboard would 404 mid-transition. | M | The move is **source-add + derived-copy-keep**, not a delete: `dashboard/home.html` becomes the single source of truth; the dogfood repo's `.aid/dashboard/home.html` **stays committed as a derived copy** (DD-5/RC-2) so the served page never disappears; a **CI equality gate** (`dashboard/home.html` == `.aid/dashboard/home.html`) catches divergence. The server contract is **unchanged** — it serves the per-repo file exactly as in d008 (a `has_home=false` repo renders the "not generated yet" card until migrated). No server install-tree fallback (NFR11, RC-2). (delivery-011) |
| R19 | **Machine-scan scope / performance / safety (FR38/SEC-1..2/SEC-5/NFR12)** — `aid update self` enumerates `.aid/` candidate folders across the machine; an unbounded or traversal-following scan is a performance and safety hazard (climbing out of scope via `..`/symlinks, descending `node_modules`/`.git`, or mutating a repo a heuristic merely *guesses* is AID). | M | **Read-only until consent** (SEC-1 — detect/enumerate are pure reads; no write before `A`/`Y`/`aid update`-in-repo/opt-in); **bounded scope, no traversal** (SEC-2 — bounded root set + shallow depth cap, skip `node_modules`/`.git`, never follow `..` or symlinks out of scope); **presence-test detection** (DD-6 — only `.aid/settings.yml` or a `.aid/knowledge/` discovery/state marker qualifies; a bare `.aid/` is a non-candidate, gated by §6 test 8); **CAN-1-canonical paths only** (SEC-5, no path injection). Exact scan root(s)/depth/symlink policy + a `--root` override = /aid-detail (residual OQ-1); the **invariant** (bounded + no-escape + read-only) is fixed. (delivery-011) |
| R20 | **Dogfood `home.html` source ↔ derived-copy equality (DD-5/RC-2, residual OQ-5)** — because the dogfood repo's `.aid/dashboard/home.html` is *both* a committed servable file *and* a derived copy of `dashboard/home.html`, the two can silently diverge between edits (an editor touches one but not the other), shipping a vendored shell that disagrees with the dogfood-served one. | L | A **CI equality gate** asserts `.aid/dashboard/home.html` byte-equals `dashboard/home.html` and fails the build on any divergence (drift caught, not structurally impossible). The exact sync step (a make/CI check, vs the stronger gitignore-and-generate alternative) is a /aid-detail pick (OQ-5); the invariant (single source of truth, copy equality enforced) is fixed (DD-5). (delivery-011) |
| R21 | **`settings.yml` repair destroying `kb_baseline` / per-skill overrides (NFR12 no-delete on config data — the highest-consequence migration hazard)** — era-a repair must add only missing/malformed *required* keys; a naive template-overwrite "repair" would silently wipe a repo's producer-written `kb_baseline` (FR35) and user-authored per-skill `minimum_grade` overrides, an NFR12 no-delete violation on config (not just files). | M | Repair = **targeted edit, never wholesale overwrite** (SPEC DD-3): ensure only the missing/malformed required keys via the `/aid-config` single-line-replace + append-block crash-safe idioms, leaving every present optional block byte-intact; era-b synthesizes fresh only when there is nothing to preserve. **§6 gate 4** (era-a malformed-settings fixture **with** a populated `kb_baseline`+override) asserts those values survive the repair byte-for-byte; the Wave-4 migration unit lane owns it. (delivery-011) |

## Deferred

**No feature is dropped — all 11 are assigned** (the original MVP = 001–005 across deliveries 001–003;
Must = 009 in delivery-006; the two-level re-architecture lands feature-010 + feature-006-revision in
**delivery-008** (spine, Must), feature-007 re-scope in **delivery-009** (KB tier, Should), and
feature-008 in **delivery-010** (drill-down, Should); the upgrade-migration **feature-011** lands in
**delivery-011** (per-repo compliance + machine scan + `home.html` vendoring, Should — resolves KI-010)).
**Sequencing-deferred (not scope-deferred):**
**feature-008 / delivery-010 (task drill-down)** is deliberately scheduled as a **separate delivery
*after* the two-level refactor** (user directive) — its A+ scope is unchanged; only its place in the
sequence moved. It is the lowest-urgency of the three re-architecture deliveries and depends on the
spine (d008) but not the KB tier (d009).

For the record, these are **already out-of-scope per REQUIREMENTS** (restated so they are not
mistaken for missing work): cross-repo aggregation; any write/control action on runs;
accessibility polish (keyboard/color-blind); export/share; serving niceties (auto-open browser,
auto-free-port, auto-surface-URL); push-based (non-polling) live updates; concurrent remote
exposure of multiple repos on one host (feature-005 MVP = one exposure per host); true per-task
execution logging (a producer-side capability, KI-008).

## Execution Graph

> Task files authored by /aid-detail 2026-06-10 (37 tasks). `→` = sequential dependency;
> `∥` = parallel lanes; `(a ∥ b)` = a and b independent after the same predecessor.
> Dependencies are authoritative in each `tasks/task-NNN.md` `Depends on:` line; the waves below
> show the parallelism those dependencies permit.

### delivery-001 execution graph
- Wave 1: task-001 (M0 doc-reconcile — the delivery gate; both lanes hang off it)
- Wave 2 (two parallel lanes after task-001):
  - feature-001 lane: task-002 → task-003 → (task-004 ∥ task-005) → task-006 → task-007 → task-008 → task-009
    - (task-004 = M2 tests runs in parallel with task-005 = M3 impl, both after task-003)
  - feature-002 lane: task-010 → task-011 → task-012
- Wave 3 (join): task-013 (M6 reader cutover — needs task-009 fully-migrated signal ∧ task-011 reader)

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009
wave 2: task-010, task-011, task-012
wave 3: task-013
```

### delivery-002 execution graph
- Wave 1: task-014 (LC-1 spawn seam — DESIGN gate) ∥ task-015 (feature-003 UI Specs — DESIGN)
    - both depend only on task-010 (delivery-001 reader core)
- Wave 2 (parallel servers): task-016 (Python) ∥ task-017 (Node)   — both need task-014 + task-010
- Wave 3 (parallel lanes once the servers exist):
  - PT-1: task-018 (cross-runtime parity — needs task-016 ∧ task-017)
  - front-end: task-019 (index.html — needs task-015 + task-016)
  - CLI lane: task-021 (Bash start/stop, needs task-014 + task-016 + task-017) → task-022 (PS twin) → task-023 (CLI tests)
- Wave 4 (join): task-020 (feature-003 Playwright visual — needs task-019 ∧ task-018, since it renders over the PT-1 fixture)

```wave-map
delivery: 002
wave 1: task-014
wave 1: task-015
wave 2: task-016
wave 2: task-017
wave 3: task-018
wave 3: task-019
wave 3: task-021, task-022, task-023
wave 4: task-020
```

### delivery-003 execution graph
- Wave 1: task-024 (LC-2 Bash expose/teardown + FR18 guidance — needs task-021)
- Wave 2: task-025 (LC-2 PowerShell twin — needs task-024 ∧ task-022)
- Wave 3: task-026 (feature-005 tests: never-funnel, clear-fail, idempotent teardown, parity, ASCII)

```wave-map
delivery: 003
wave 1: task-024
wave 2: task-025
wave 3: task-026
```

### delivery-006 execution graph
> feature-009 producer-loop closure. Sequences **after delivery-003, before delivery-004** in the
> spine (`d003 → d006 → d004`). Tasks numbered from task-038 (continuing the global counter past
> delivery-005's task-037). Authored by /aid-plan 2026-06-11; task files detailed next in /aid-detail.
- Wave 1 (canonical producer/format edits — independent skill files, fully parallel; C4/C5
  behavior-preserving — each only **adds** emitted content):
  - producer lane A: task-038 (`/aid-interview` PF-1 identity header — scaffold + COMPLETION-checkpoint
    Description-from-Objective + REQUIREMENTS template) ∥
  - producer lane B: task-039 (`/aid-detail` PF-3 descriptive-short-name rule + `/aid-execute`-preserves-title note,
    AND PF-5a normalized `wave-map` emission in `execution-graph-generation.md`)
- Wave 2 (reader reconciliation — Python + Node in lockstep, byte-parity; needs the producer formats
  pinned by Wave 1): task-040 (PF-2 Objective blockquote-skip, PF-3 `parse_task_short_name`, PF-5
  `parse_execution_graph` wave-map→legacy-prose, PF-6 inline-comment strip, PF-7 null sentinels;
  `TaskModel` `short_name`/`delivery`/`lane`; `_read_work` joins; **both servers' envelope + DM-3 key
  order; schema_version 2 → 3**) — needs task-038 ∧ task-039
- Wave 3 (front-end reconciliation — single `index.html` writer; needs the reader's new model shape):
  task-041 (remove `parseWave()`; group by `task.delivery`, order lanes by `task.lane`, unsequenced
  lane; delivery-scoped `uiState.lanes` key `"d<delivery>-lane<lane>"`/`"-unseq"`; title/de-slug
  fallback + blockquote-can't-leak; neutral phase rail; `short_name` chip; `EXPECTED` 2 → 3) —
  needs task-040
- Wave 4 (fixture-from-real + producer↔consumer contract test — regenerates PT-1 from conforming
  producer output; needs the reconciled reader ∧ front-end so the captured fixture parses clean):
  task-042 (T-9 fixture-from-real regen + T-10 contract test that mutated producer strings fail +
  PT-1 cross-runtime parity @ schema 3, T-11) — needs task-040 ∧ task-041
- Wave 5 (dogfood render — canonical→`.claude` via the FULL `run_generator.py`; needs the canonical
  producer edits final): task-043 (FR24/C5: FULL `run_generator.py`; render-drift + deterministic-
  emission + ASCII-only gates green; 5 install trees byte-identical) — needs task-038 ∧ task-039
- Wave 6 (work-001 data migration — MIGRATE-typed; needs the dogfood-rendered producers ∧ the
  reconciled reader so the migrated repo reads clean): task-044 (FR26: insert PF-1 header, add typed
  `## Pipeline Status` block, transcribe prose graph → `wave-map` per delivery, verify task titles
  parse; zero PF-7 sentinels after) — needs task-040 ∧ task-043
- Wave 7 (join — Playwright visual re-view on the REAL migrated repo, R5 hard gate): task-045
  (T-12: real Name, no leaked blockquote, real delivery numbers / no `Delivery #0`, real phase rail,
  real task short-names; both runtimes byte-identical over migrated work-001; zero JS errors; light +
  dark + responsive) — needs task-044 ∧ task-041 ∧ task-042

```wave-map
delivery: 006
wave 1: task-038
wave 1: task-039
wave 2: task-040
wave 3: task-041
wave 4: task-042
wave 5: task-043
wave 6: task-044
wave 7: task-045
```

### delivery-004 execution graph
- Wave 1: task-027 (feature-006 UI Specs — DESIGN; needs task-019)
- Wave 2: task-028 (front-end: hash router + cards + KB card + L0 panel + empty-state + render(model, selectedWorkId); needs task-027 ∧ task-019)
- Wave 3: task-029 (Playwright visual validation — R5 hard gate)

```wave-map
delivery: 004
wave 1: task-027
wave 2: task-028
wave 3: task-029
```

### delivery-005 execution graph

> ⚠️ **SUPERSEDED (2026-06-12) — historical record.** This graph (tasks 030–037, rich-`KbModel`/
> `schema 1→3`) is superseded by the two-level re-architecture and will be **re-planned** by the upcoming
> /aid-plan (feature-007 re-scoped → drops the rich `KbModel`; feature-008 deferred to its own delivery).
> Kept for traceability; not the go-forward plan. See the SUPERSEDED banner on the delivery-005 block above.
> **Re-plan landed (2026-06-12):** the go-forward breakdown is **delivery-008 (spine) → delivery-009 (KB
> tier) → delivery-010 (drill-down)** below; this superseded delivery-005's KB half (030–032/034/036) is
> absorbed by delivery-009's feature-007 re-scope and its drill-down half (033/035/037) carries to
> delivery-010's feature-008. No task number is reused — delivery-008+ start a fresh counter past task-045.

- Wave 1 (two parallel reader/design starts):
  - task-030 (feature-007 KB UI Specs — DESIGN; needs task-028)
  - task-031 (feature-007 reader LC-KR rich KbModel; needs task-013)
- Wave 2 (KB-view ∥ drill-reader):
  - task-032 (KB view LC-KV/KT/KF; needs task-030 ∧ task-031 ∧ task-028) — the **first** `index.html` front-end writer of this delivery
  - task-033 (feature-008 reader LC-TR + server ?detail= LC-SD; needs task-031 ∧ task-016 ∧ task-017)
- Wave 3 (shared schema cut — the coordination join): task-034 (schema_version 1→3 — *superseded: delivery-006/feature-009 owns the move to schema_version 3; task-034 re-baselines off the 3 floor to 3→4 or no-bump, finalized in /aid-detail* — + front-end EXPECTED + grow PT-1 fixture; needs task-031 ∧ task-033)
- Wave 4 (drill-view — **serialized after the KB view**, both write `index.html`):
  - task-035 (feature-008 drill view LC-DV/RV: findings, ledger, escaped read-only raw STATE.md, honest logs, parallel drill; needs task-032 ∧ task-033 ∧ task-028 — task-032 added to avoid an `index.html` write race)
- Wave 5 (parallel validations): task-036 (PT-1 re-validation at schema_version 3; needs task-032 ∧ task-034 ∧ task-035) ∥ task-037 (Playwright visual validation R5; needs task-032 ∧ task-035 ∧ task-034)

```wave-map
delivery: 005
wave 1: task-030
wave 1: task-031
wave 2: task-032
wave 2: task-033
wave 3: task-034
wave 4: task-035
wave 5: task-036
wave 5: task-037
```

---

> ## Two-level re-architecture execution graphs (feature-slice granularity)
>
> These three graphs are at the **deliverable / feature-slice** granularity the plan owns — they show
> which feature-areas proceed in parallel within a delivery and the cross-area joins. **Task-level
> decomposition + the machine-parseable ```wave-map fences are owned by /aid-detail**, which numbers
> tasks from a fresh counter past task-045 and emits the per-delivery wave-maps then (per PF-5a). `→` =
> sequential dependency; `∥` = parallel feature-area lanes.

### delivery-008 execution graph (the spine)

> Two features in one gate (feature-010 spine + feature-006 revision). The seam to close **first** is
> the **server entry-point install-tree relocation + reader co-vendor** (R8) — the spawn/import contract
> every other area builds on. feature-006's `home.html` rename + L0-removal is a small front-end edit that
> can proceed in parallel with the registry/server work once the relocation layout is agreed.

- **Slice 1 (seam-first, gating):** install-tree relocation + reader co-vendor (R8) **+** the
  `<id>`/CAN-1 addressing + registry-file contract (DM-1) — the shared layout both servers and the
  `bin/aid` writer resolve against. Everything below hangs off this.
- **Slice 2 (three parallel feature-areas after Slice 1):**
  - **registry-writer area:** `bin/aid` + `bin/aid.ps1` `aid add`/`aid remove` registry side-effect
    (FF-1, atomic write DD-3, ASCII + Bash↔PS parity gates — R10) → CLI tests.
  - **server area:** the multi-repo server rewrite (LC-MS, Python ∥ Node siblings — the NEW closed
    allowlist `/` + `/api/home` + `/r/<id>/{home.html,kb.html,api/model}`, construct-not-sanitize, R9).
  - **front-end area:** the CLI home `index.html` (machine panel + repo-card grid + unavailable/prune)
    **∥** feature-006's `home.html` rename + L0-panel removal + the KB-card **slot in its carried-over
    d004 2-state form** (the 5-state repoint is a d009 step — see the d008 "KB-card intermediate state"
    note; independent of the server internals once the route shapes are fixed).
- **Slice 3 (join — parity + visual gate):** PT-1-H cross-runtime byte-parity over the multi-repo shape
  (needs both servers + the registry fixture — R9) **∥** the `--remote` re-target (DR-4, feature-005
  mechanism unchanged — needs the server) → **Playwright R5 visual gate** (CLI home + click-through into a
  repo's `home.html`; needs the front-end + a running server — R5 hard gate).

#### delivery-008 task-level execution graph (the spine — 13 tasks, 046–058)

> Authored by /aid-detail 2026-06-12 from the feature-slice graph above. Tasks numbered from a fresh
> counter past task-045 (delivery-006). `→` = sequential dependency; `∥` = parallel lanes;
> `(a ∥ b)` = a and b independent after the same predecessor. Dependencies are authoritative in each
> `tasks/task-NNN.md` `Depends on:` line. **R8 verdict (resolved at detail): proceed as a bounded
> co-vendor unit inside d008** — task-046 (RESEARCH) pins the `$AID_HOME/dashboard/` layout + the full
> vendor/install-core blast-radius delta list and records an explicit *proceed-or-escalate* verdict;
> task-047 (CONFIGURE) executes the co-vendoring + the spawn-seam relocation. task-046's ACs hold the
> IMPEDIMENT-escalation path open per the PLAN R8 directive ("do not balloon the spine") if the blast
> radius proves larger than a co-vendor unit. **Shared-file writers serialized:** the three `bin/aid` +
> `bin/aid.ps1` writers land serially (task-047 spawn-seam → task-049 registry side-effect → task-055
> `--remote`); the per-repo `home.html` rename (task-054, which *renames away* the old
> `dashboard/index.html`) precedes the NEW CLI-home `index.html` create (task-053) via an **encoded
> `Depends on: task-054` edge** on task-053 (not merely wave placement), so the same-path
> rename-then-create is dependency-enforced and the two front-end files never race; `server.py`
> (task-050) and `server.mjs` (task-051) are separate files rewritten in lockstep and parallelize. Playwright R5 (task-058) is the hard visual gate (project policy).

- **Wave 1 (two parallel seam-first starts):**
  - task-046 (RESEARCH — R8 install-tree relocation: pin the `$AID_HOME/dashboard/` layout + vendor/
    install-core blast radius; record proceed-or-IMPEDIMENT verdict) ∥
  - task-048 (DESIGN — the registry contract seam: DM-1 schema + CAN-1 four-site rule + DD-1 `<id>`
    addressing + DD-3 atomic write — the shared layout all Slice-2 areas resolve against)
- **Wave 2 (three parallel feature-area starts after their seam):**
  - task-047 (CONFIGURE — co-vendor server+reader into the install tree, place under `$AID_HOME/dashboard/`,
    relocate the spawn seam to `$AID_HOME`; needs task-046) — the first `bin/aid` writer
  - task-052 (DESIGN — CLI home UI specs: machine panel + repo-card grid + unavailable/prune;
    resolves residual #2 `aid dashboard --target`; needs task-048)
  - task-054 (REFACTOR — feature-006 revision: rename `index.html`→`home.html` + DELETE the L0 panel,
    KB card stays 2-state; needs task-048) — renames away the old per-repo `index.html`
- **Wave 3 (registry writer + the two server siblings, after the vendored layout + seam):**
  - task-049 (IMPLEMENT — `bin/aid`/`bin/aid.ps1` registry side-effect; needs task-047 ∧ task-048) — the
    second `bin/aid` writer (serial after task-047)
  - task-050 (IMPLEMENT — `server.py` LC-MS rewrite; needs task-047 ∧ task-048) ∥
    task-051 (IMPLEMENT — `server.mjs` LC-MS twin; needs task-047 ∧ task-048) — separate files, lockstep contract
- **Wave 4 (front-end CLI home + `--remote` + parity, after the servers exist):**
  - task-053 (IMPLEMENT — CLI home `index.html` create + poll `/api/home`; needs task-052 ∧ task-050 ∧ task-054) —
    the NEW `index.html`, created after task-054 renamed the old one away (the task-054 edge encodes the
    same-path rename-then-create serialization explicitly)
  - task-055 (IMPLEMENT — `--remote` DR-4 re-target; needs task-047 ∧ task-049 ∧ task-052) — the third
    `bin/aid` writer (serial after task-049)
  - task-056 (TEST — PT-1-H cross-runtime byte-parity over the multi-repo shape; needs task-050 ∧ task-051)
- **Wave 5 (join — CLI parity tests + the R5 visual gate):**
  - task-057 (TEST — `test-aid-cli-parity.sh` register/unregister + spawn-seam + `--remote` parity + ASCII;
    needs task-049 ∧ task-055) ∥
  - task-058 (TEST — Playwright R5 visual gate: CLI home renders + click-through into `home.html`,
    L0-panel-absent verified; needs task-053 ∧ task-054 ∧ task-056)

```wave-map
delivery: 008
wave 1: task-046, task-048
wave 2: task-047, task-052, task-054
wave 3: task-049, task-050, task-051
wave 4: task-053, task-055, task-056
wave 5: task-057, task-058
```

### delivery-009 execution graph (the KB tier)

> One re-scoped feature (feature-007) over the delivered spine. The producers and the reader extension are
> largely independent and parallelize; they converge at the served-page + card render, then the visual gate.

- **Slice 1 (two parallel feature-areas):**
  - **producer-chain area:** canonical edits to `aid-summarize` (output → `.aid/dashboard/kb.html`,
    FR31), `aid-discover` (FR34 auto-trigger + FR35 baseline record — R11), `aid-housekeep` (resolve
    `outdated` + re-stamp), and the `/aid-config` `kb_baseline` schema key (R13) → FULL `run_generator.py`
    dogfood render across 5 trees + `.claude/` (render-drift clean, R1/R11).
  - **reader area:** feature-002 reader KB-status extension — the 5-state derivation waterfall (FF-A3) +
    `summary_present` + the cross-runtime read-only `git log -1` freshness read (Python ∥ Node byte-identical,
    degrade-to-`approved` matrix — R12).
- **Slice 2 (join — front-end card repoint + the served page):** **repoint feature-006's KB-card slot**
  from its d008-carried 2-state form to feature-007's **5-state** render (only approved/outdated clickable,
  outdated→refresh prompt) consuming the reader's new `kb_state` and opening the spine-served
  `/r/<id>/kb.html` (needs the reader area; the served page is produced by the producer area). This is the
  d009 step deferred from d008's KB-card slot (see d008 "KB-card intermediate state").
- **Slice 3 (validation):** PT-1-H git-state-deterministic parity (frozen/stubbed tip — R12) → **Playwright
  R5 visual gate** (served `kb.html` + each 5-state card rendering — R5 hard gate).

#### delivery-009 task-level execution graph (the KB tier — 9 tasks, 059–067)

> Authored by /aid-detail 2026-06-12 from the feature-slice graph above. Tasks numbered from a fresh
> counter past task-058 (delivery-008). `→` = sequential dependency; `∥` = parallel lanes;
> `(a ∥ b)` = a and b independent after the same predecessor. Dependencies are authoritative in each
> `tasks/task-NNN.md` `Depends on:` line. **Producer-skill edits are CANONICAL-rendered** (task-059..062
> edit `canonical/**`; task-063 runs the FULL `run_generator.py` → `.claude/` + 5 install trees; gated by
> **render-drift + deterministic-emission**, NOT d008's hand-maintained `bin/aid` vendor-refresh).
> **Seam-first:** task-059 (`/aid-config` `kb_baseline` schema) is the schema owner both the producer
> writers (task-061/062) and the reader parse (task-064) resolve against — it gates them. **Shared-file
> writers serialized:** the 4 canonical edits touch **distinct** skill files (aid-config / aid-summarize /
> aid-discover / aid-housekeep) so they parallelize; the **reader** Python files + `reader.mjs` are written
> by **task-064 only** (single lockstep writer — no same-file race); `home.html`'s KB card is written by
> **task-065 only** (d008 task-054 owns the rename; this owns the card body). **d008 dependency edges:**
> task-065 carries an explicit `Depends on: task-054` (the `home.html` the card lives in must exist);
> task-064/task-065/task-067 all build on d008's relocated reader + `/r/<id>/kb.html` route + the carried
> KB-card slot (referenced, not duplicated). **R11/R12/R13 gates:** FR34 auto-trigger is the one deliberate
> behavior change (task-061); the git-read byte-parity (task-064) is proven git-state-deterministic in
> task-066; the `kb_baseline` append-block write idiom is owned by task-059. **NO `schema_version` bump**
> (DM-A3 — `kb_state` is an additive superset at the same `/api/model` path). Playwright R5 (task-067) is
> the hard visual gate (project policy).

- **Wave 1 (the config-schema seam ∥ the path-relocation, both independent starts):**
  - task-059 (CONFIGURE — `/aid-config` `kb_baseline` schema key in `canonical/templates/settings.yml` +
    the validation table; schema owner; the seam task-061/062/064 resolve against — R13) ∥
  - task-060 (IMPLEMENT — `aid-summarize` output relocation `knowledge-summary.html` →
    `.aid/dashboard/kb.html` across the 9 verified files, FR31; independent — needs no schema key)
- **Wave 2 (the two producer-writers + the reader, after their schema seam):**
  - task-061 (IMPLEMENT — `aid-discover` FR34 auto-trigger + FR35 `kb_baseline` record at DONE, the one
    deliberate behavior change R11; needs task-059) ∥
  - task-062 (IMPLEMENT — `aid-housekeep` resolve `outdated` re-stamp + committed `kb.html` path repoint,
    FR36; needs task-059 ∧ task-060) ∥
  - task-064 (IMPLEMENT — reader KB-status extension + cross-runtime git read: `KbStateRef`{status,
    summary_present,kb_baseline} + the FF-A3 5-state waterfall + the FF-A2 git read/degradation matrix +
    the 4 "no subprocess" docstrings; Python ∥ Node lockstep, NO schema bump — R12; needs task-059)
- **Wave 3 (dogfood render ∥ front-end card, parallel after their inputs):**
  - task-063 (CONFIGURE — FULL `run_generator.py` dogfood render of the 4 canonical edits into `.claude/` +
    5 install trees; render-drift + deterministic-emission + ASCII gates green — R11/C7; needs task-059 ∧
    task-060 ∧ task-061 ∧ task-062) ∥
  - task-065 (IMPLEMENT — front-end 5-state KB card repoint in `home.html` (2-state → pending/generating/
    preparing/approved/outdated; only approved/outdated clickable → `./kb.html`; outdated refresh prompt);
    needs task-064 ∧ **task-054** [d008 `home.html` rename])
- **Wave 4 (parity + producer↔consumer test — needs the reader, the rendered producers, the relocated path):**
  - task-066 (TEST — PT-1-H git-state-deterministic byte-parity over the 5-state fixture + the `Z`-vs-
    `±HH:MM` normalization unit case + the producer↔consumer `kb_baseline` round-trip / kb-status contract;
    R12/SEC-A4; needs task-064 ∧ task-063 ∧ task-060)
- **Wave 5 (join — the R5 visual gate):**
  - task-067 (TEST — Playwright R5 visual gate: the 5 card states incl. `outdated` + the served `kb.html`;
    dark + responsive; zero JS errors — R5 hard gate; needs task-065 ∧ task-066)

```wave-map
delivery: 009
wave 1: task-059
wave 1: task-060
wave 2: task-061, task-062, task-064
wave 3: task-063
wave 3: task-065
wave 4: task-066
wave 5: task-067
```

### delivery-010 execution graph (task drill-down)

> One feature (feature-008, scope unchanged). Reader/server growth first, then the front-end drill view,
> then the visual gate — mirrors the original (superseded) delivery-005 drill-down half (033/035/037),
> re-homed onto the spine's per-`<id>` `/api/model` surface.

- **Slice 1 (reader/server growth):** feature-008 reader `TaskDetail` (findings, ledger/grade, raw
  STATE.md, logs, parallel-task drill) + the server's lazy `?detail=` endpoint growth on the per-`<id>`
  `/api/model` (R14 schema-coordination — bump-vs-no-bump decided at detail; R15 raw-viewer escape).
- **Slice 2 (front-end drill view):** the `#/work/<id>/task/<task-id>` (SEAM-2) drill view on `home.html`
  — findings/ledger/escaped read-only raw STATE.md/honest logs/parallel drill (needs Slice 1).
- **Slice 3 (validation):** PT-1-H re-validation at the resolved schema floor (R14) → **Playwright R5
  visual gate** (drill view — R5 hard gate).

#### delivery-010 task-level execution graph (task drill-down — 6 tasks, 068–073)

> Authored by /aid-detail 2026-06-12 from the feature-slice graph above. Tasks numbered from a fresh
> counter past task-067 (delivery-009). `→` = sequential dependency; `∥` = parallel lanes;
> `(a ∥ b)` = a and b independent after the same predecessor. Dependencies are authoritative in each
> `tasks/task-NNN.md` `Depends on:` line. **R14 schema decision (resolved at detail, recorded in
> feature-008 SPEC RC-2): NO `schema_version` bump — the envelope stays at the schema-3 floor.** The
> lazy `details` map is a new top-level key that is **present only when `?detail=` is supplied (omitted
> otherwise), additive, consumer-tolerant, and ships in lockstep with its sole consumer** — the
> `created`/DM-A3 shape, **not** the feature-009 deliberate-evolution shape; front-end `EXPECTED` stays 3
> and the stale-assets banner does not fire. The PT-1/PT-1-H **fixture extension + `details` key-order
> parity** are retained as a parity obligation (task-072), distinct from a bump. **Shared-file writers
> serialized:** the reader Python files (`dashboard/reader/*`) + `reader.mjs` are written by **task-069
> only** (single lockstep writer — no same-file race); the two servers (`server.py`/`server.mjs`) are
> written by **task-070 only** (separate files, lockstep contract, parallelize as one writer-task); the
> per-repo `home.html` drill view is written by **task-071 only** (d008 task-054 owns the rename; this
> owns the drill-view body). **d008 dependency edges (referenced, not duplicated):** task-069 builds on
> d008's install-relocated reader (task-046/047); task-070's LC-SD `?detail=` branch lives inside the
> d008 LC-MS servers (task-050/051); task-068/task-071 build on the d008-renamed `home.html` + its
> router (task-054). **NOT dependent on d009** (no KB state / `kb.html` / git-read). **R15 raw-viewer
> read-only + escaped** is enforced in task-071 (the escaped `<pre>`) and visually gated in task-073.
> Playwright R5 (task-073) is the hard visual gate (project policy).

- **Wave 1 (the UI-specs seam ∥ the reader sub-parser, both independent starts):**
  - task-068 (DESIGN — feature-008 drill-view UI specs UI-1..UI-6: findings/ledger panel, escaped
    read-only raw-STATE viewer, honest logs + FR18, parallel drill, responsive; grounded on the d008
    `home.html` + router; needs task-054) ∥
  - task-069 (IMPLEMENT — reader `TaskDetail` sub-parser LC-TR: findings/ledger/raw_state/logs, Python ∥
    Node byte-parity, detail-only — no always-on path change; the single reader-files writer; needs
    task-046 ∧ task-047 [d008 relocated reader])
- **Wave 2 (the server lazy-detail branch, after the reader API exists):**
  - task-070 (IMPLEMENT — server LC-SD `?detail=` branch on the per-`<id>` `/api/model`: attach `details`
    only on drill, key-order parity, **NO schema bump** RC-2; the single servers writer, `server.py` ∥
    `server.mjs` lockstep; needs task-069 ∧ task-050 ∧ task-051 [d008 LC-MS servers])
- **Wave 3 (front-end drill view ∥ parity — independent after the wire):**
  - task-071 (IMPLEMENT — drill view LC-DV/LC-RV in `home.html`: SEAM-2 route, location-relative
    `./api/model?detail=`, findings/ledger/escaped read-only raw STATE.md/honest logs/parallel drill;
    the single `home.html` writer; needs task-068 ∧ task-070 ∧ task-054 [d008 `home.html` rename]) ∥
  - task-072 (TEST — PT-1-H byte-parity for the `details` envelope: full `TaskDetail` fixture +
    `U+2028`/`U+2029` raw-state, key-order parity, **NO-schema-bump assertion** RC-2; needs task-069 ∧
    task-070 — independent of the front-end, parallels task-071)
- **Wave 4 (join — the R5 visual gate, over the byte-parity fixture):**
  - task-073 (TEST — Playwright R5 visual gate, hard: drill view + escaped read-only raw STATE.md (R15
    no-injection) + parallel-task drill; dark + responsive; zero JS errors; needs task-071 ∧ task-072)

```wave-map
delivery: 010
wave 1: task-068
wave 1: task-069
wave 2: task-070
wave 3: task-071
wave 3: task-072
wave 4: task-073
```

### delivery-011 execution graph (upgrade migration — resolves KI-010)

> One feature (feature-011), one cohesive delivery. Foundation first (the `home.html` source-move +
> vendoring the LC-MIG add-step depends on), then the shared migration engine (`_aid_migrate_repo` core +
> the era-a/era-b settings logic), then the command wiring (the two `aid update` reaches + the sentinel/
> postinstall trigger), then the gates (the migration unit/parity/ASCII/vendor tests + the R5 Playwright
> hard gate on a freshly-migrated `home.html`). **All edits land in hand-maintained `bin/aid` + `bin/aid.ps1`
> + the package/vendor layer (C8)** — gates are **ASCII + parity + vendor-refresh + the new migration tests +
> R5**, **NOT** render-drift / `run_generator.py`. **Same-file writer serialization:** `bin/aid` is one file
> — its three writer concerns (the LC-MIG migration-function set, the two dispatch hooks for FF-2/FF-3, the
> FF-4 sentinel check) **cannot parallelize with each other** and land serially within the engine/wiring
> waves; `bin/aid.ps1` is its parity twin and is written in lockstep against each `bin/aid` change (one twin
> writer per concern, not a parallel author) — the parity constraint (R17) means a Bash edit and its PS twin
> are the *same* logical writer, gated by `test-aid-cli-parity.sh`. **Task-level decomposition + the
> machine-parseable ```wave-map fence are owned by /aid-detail** (task-074+); the slices/lanes/dependencies
> below are the deliverable-granularity structure the plan owns. `→` = sequential dependency; `∥` = parallel
> lanes; `∧` = a join needing both predecessors.

- **Wave 1 (foundation — the `home.html` source + vendoring; no `bin/aid` edits yet, fully parallelizable
  with the Wave-2 *design* but a hard predecessor of the Wave-2 add-step):**
  - **source-move lane (LC-HSRC, DD-5/RC-2):** move the d010 dogfood `.aid/dashboard/home.html` content to a
    single committed source `dashboard/home.html`; keep the dogfood `.aid/dashboard/home.html` as a
    derived copy (the served page must not break — R18) ∥
  - **vendoring lane (LC-VND, FR40):** add `dashboard/home.html` to **both** vendor manifests
    (`packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`) so it installs to
    `$AID_HOME/dashboard/home.html`; wire the **CI equality gate** (`dashboard/home.html` ==
    `.aid/dashboard/home.html`, R20/OQ-5) — needs the source-move lane
  - **settings design lane (DESIGN, DM-1/RC-4/DD-3):** pin the validate/repair (era-a) + synthesize (era-b)
    `settings.yml` contract — the "valid" shape all readers parse without falling back, the
    preserve-`kb_baseline`+overrides repair rule, the era-b basename + manifest-derived `tools.installed`
    synthesis — the seam the Wave-2 settings step resolves against (independent of the source/vendor lanes)
- **Wave 2 (migration core — `_aid_migrate_repo` in `bin/aid` + the PS twin; needs the settings design ∧ the
  vendored `home.html` source the add-step copies):**
  - **migration-engine lane (LC-MIG, FF-1; Bash + PS twin = one logical writer per R17):** the shared
    `_aid_migrate_repo` — DETECT/qualify (DD-6 presence-test), SETTINGS validate/repair|synthesize (DM-1, the
    crash-safe temp-file+`mv -f` write), ADD `home.html` (copy `$AID_HOME/dashboard/home.html`, additive
    no-clobber, FR40 — needs Wave-1 vendoring), RELOCATE legacy summary (`mv -n`, the d009 FR31 idiom, DM-4),
    REGISTER (reuse feature-010 `registry_register`, DM-2) — needs the settings design lane ∧ the Wave-1
    vendoring lane
- **Wave 3 (command wiring — the two reaches + the trigger; all `bin/aid`/`bin/aid.ps1` edits, **serialized**
  against the Wave-2 engine and against each other since they share `bin/aid`):**
  - **scan/consent lane (FF-2/CLI-1):** `SCAN_FOR_AID_REPOS` (bounded, read-only, no-traversal — R19/SEC-2) +
    the **All/Yes/No/Cancel** consent loop + declined-repo advisory, attached after `_cmd_update_self` in the
    `aid update self` dispatch; advances the DM-3 marker on completion — needs the Wave-2 engine →
  - **current-repo lane (FF-3/CLI-2):** the `aid update [<tool>]` per-repo tail beside the existing
    `registry_register "$_AID_TARGET"` + the self-update-if-needed preamble (OQ-6) — needs the Wave-2 engine
    (serial after the scan lane — same `bin/aid` file) →
  - **trigger lane (FF-4/DM-3, R16):** the version-sentinel lazy first-run check (`$AID_HOME/.migrated` vs
    `VERSION`, string-inequality DD-1, non-interactive defer RC-3, `AID_NO_MIGRATE`/`AID_MIGRATE_YES` env) in
    `bin/aid` early dispatch + the **npm `postinstall`** entry in `packages/npm/package.json` (pypi has none —
    sentinel-only, R16) — needs the scan lane (the trigger invokes FF-2; serial — same `bin/aid` file)
- **Wave 4 (gates — the migration tests, all parallelizable; then the R5 hard gate as the final join):**
  - **migration unit/safety lane (TEST, §6 gates 4–8):** era-a no-op + repair (preserve `kb_baseline`+override);
    era-b synthesize (basename + manifest tools); **idempotency** (second run = byte-identical no-op);
    **no-delete** (existing `home.html` never overwritten, both summary files kept on clobber); **bare-`.aid/`
    non-candidate** — needs the Wave-2 engine ∥
  - **trigger lane (TEST, §6 gate 9):** cross-manager trigger — interactive sentinel fires once + advances
    marker, second run at same version no-ops (SEC-6), non-interactive defers (marker stale), `AID_MIGRATE_YES=1`
    migrates; **exercises the pypi-no-postinstall sentinel-only path** + the npm-postinstall path (R16) — needs
    the Wave-3 trigger lane ∥
  - **parity/ASCII/vendor lane (TEST, §6 gates 1–3):** `test-ascii-only.sh` + `test-aid-cli-parity.sh`
    (era-a/era-b branches, All/Yes/No/Cancel wording, advisory, WARN lines, exit codes — R17) + the
    vendor-refresh assertion that `dashboard/home.html` is in both manifests and lands at
    `$AID_HOME/dashboard/home.html` (and is **absent** from `EMISSION-MANIFEST.md` — not render-drift) — needs
    Wave-2 ∧ Wave-3 ∧ the Wave-1 vendoring lane
  - **Wave 5 (join — the R5 Playwright hard gate, final):** run the migration on an era-b fixture repo,
    register it, start the multi-repo server, and **render that repo's provisioned `home.html` in Playwright**
    — assert the SPA shell loads, polls `/r/<id>/api/model`, and renders (no 404, no blank page); the concrete
    proof **KI-010 is resolved** — needs the migration unit lane ∧ the served-page route (d008 spine) ∧ a
    migrated `home.html` (Wave-2 add-step over the Wave-1 vendored source). Source-only review is an automatic
    FAIL (R5 project policy).

#### delivery-011 task-level execution graph (upgrade migration — 10 tasks, 074–083)

> Authored by /aid-detail 2026-06-13 from the feature-slice graph above. Tasks numbered from a fresh
> counter past task-073 (delivery-010). `→` = sequential dependency; `∥` = parallel lanes; `∧` = a join
> needing both predecessors. Dependencies are authoritative in each `tasks/task-NNN.md` `Depends on:` line.
> The machine `wave-map` `lane` value is the **scheduling lane** (the reader maps `task → lane`,
> `parsers.py:671-677`): every task's dependencies sit in a **strictly earlier lane** so a lane is a true
> parallelizable batch. The deliverable-granularity "Wave 1-5" labels above are the conceptual phases; the
> serial `bin/aid` writer chain (R17: 077 → 078 → 079 → 080) expands those phases into lanes 3-6.
> **bin/aid anchors RE-PINNED against the live file (1593 lines) at detail time** (SPEC/brief drift, OQ-2):
> `_cmd_update_self`:247 (npm/pypi guard 250-259, curl 261-263); update-self dispatch 1265-1281 (call
> `_cmd_update_self`:1277, `exit $?`:1278, `--force|-y` no-op:1272); `add|update` case:1542 → `Done.`:1563
> → `registry_register "$_AID_TARGET"`:1565 → `exit 0`:1566; `--target` canon `_AID_TARGET="$(cd … &&
> pwd)"`:1366; manifest `_AID_MANIFEST`:1414 (`manifest_list_tools` use 1425); `$AID_HOME` resolve 40-47;
> `registry_register` def 1094-1127 / `_registry_read_repos` 1082-1088; `.update-check`+`AID_NO_UPDATE_CHECK`
> precedent 159-160/164/174, VERSION read+trim 168-170, `_aid_check_update` def 162 / calls 1202,1260.
> **Same-file writer serialization (R17):** `bin/aid` is one file — its three writer concerns serialize:
> task-077 (LC-MIG core) → task-078 (FF-2 scan/consent + `--yes`) → task-079 (FF-3 current-repo tail) →
> task-080 (FF-4 sentinel). Each `bin/aid` edit's `bin/aid.ps1` twin is the **same** logical writer (parity
> lockstep, gated by `test-aid-cli-parity.sh`), never a parallel author. `package.json` is written by
> **task-080 only**; the vendor manifests (`vendor.js`/`vendor.py`) by **task-076 only**. **R5 (task-083) is
> the final wave.**

- **Wave 1 (foundation — `home.html` source/vendor ∥ the settings design seam, all independent starts):**
  - task-074 (DESIGN — settings.yml validate/repair + era-b synthesis contract DM-1/DD-3/RC-4/R21: the
    "valid" reader-parseable shape, the preserve-`kb_baseline`+overrides targeted-repair rule, the era-b
    basename + manifest-`tools.installed` synthesis map; the seam task-077 resolves against; no deps) ∥
  - task-075 (MIGRATE — `home.html` source-move LC-HSRC/DD-5/R18: move the dogfood `.aid/dashboard/home.html`
    content to a single committed source `dashboard/home.html`, keep the dogfood copy derived so serving
    never breaks; no deps) →
  - task-076 (CONFIGURE — vendoring LC-VND/FR40: add `dashboard/home.html` to both vendor manifests →
    `$AID_HOME/dashboard/home.html` + the CI source↔copy equality gate R20/OQ-5; needs task-075)
- **Wave 2 (migration core — `bin/aid` + PS twin; needs the settings design ∧ the vendored source):**
  - task-077 (MIGRATE — `_aid_migrate_repo` core LC-MIG/FF-1: DETECT/qualify DD-6, SETTINGS repair|synthesize
    DM-1, ADD `home.html` FR40, RELOCATE summary DM-4/FR31, REGISTER DM-2 via `registry_register`:1094; the
    callable core, no dispatch wiring; needs task-074 ∧ task-076)
- **Wave 3 (command wiring — serialized on `bin/aid`, after the Wave-2 core):**
  - task-078 (IMPLEMENT — `aid update self` FF-2 scan + All/Yes/No/Cancel CLI-1 + `SCAN_FOR_AID_REPOS`
    R19/SEC-2 + `--yes`; attached between `_cmd_update_self`:1277 and `exit $?`:1278; advances DM-3 marker on
    completion; needs task-077) →
  - task-079 (IMPLEMENT — `aid update [<tool>]` FF-3 current-repo tail beside `registry_register`:1565 +
    self-update preamble OQ-6/CLI-2; serial after task-078 — same `bin/aid`; needs task-077 ∧ task-078) →
  - task-080 (IMPLEMENT — FF-4 trigger DM-3/R16: version-sentinel lazy first-run near `_aid_check_update`
    (`bin/aid:1202`) DD-1/RC-3 + npm `postinstall` in `package.json` OQ-3 (pypi sentinel-only); serial after
    task-078 — invokes the FF-2 scan, same `bin/aid`; needs task-078)
- **Wave 4 (gates — the migration tests, parallel):**
  - task-081 (TEST — migration unit/safety §6 gates 4-8: era-a no-op + repair-preserves-`kb_baseline`+override
    R21, era-b synthesize RC-4, idempotency, no-delete, bare-`.aid/` non-candidate; needs task-077) ∥
  - task-082 (TEST — §6 gates 1-3,9: cross-manager trigger incl. pypi-no-postinstall sentinel-only path R16,
    `test-aid-cli-parity.sh` extension R17, `test-ascii-only.sh`, vendor-refresh + not-render-drift;
    needs task-076 ∧ task-079 ∧ task-080)
- **Wave 5 (join — the R5 Playwright hard gate, final):**
  - task-083 (TEST — R5 Playwright §6 gate 10: provision an era-b fixture repo **via the migration**, serve
    it, render the provisioned `home.html` + visually validate the SPA shell loads/polls/renders, zero
    console errors; resolves KI-010; needs task-081 ∧ task-082)

```wave-map
delivery: 011
wave 1: task-074
wave 1: task-075
wave 2: task-076
wave 3: task-077
wave 4: task-078
wave 5: task-079
wave 6: task-080
wave 7: task-081
wave 7: task-082
wave 8: task-083
```

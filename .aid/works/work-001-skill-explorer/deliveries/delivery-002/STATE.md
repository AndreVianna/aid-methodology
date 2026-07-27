---
delivery_state: Done
gate_tier: Large
gate_grade: A+
gate_timestamp: '2026-07-27T10:42:00-04:00'
ticket_ref: "--"
---

# Delivery State -- delivery-002

[!NOTE]
This is the DELIVERY-LEVEL STATE.md. It is divided into three zones:
  FRONTMATTER (single writer = this delivery's branch, machine-parsed scalars) --
      `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref`.
  AUTHORED (single writer = this delivery's branch, markdown body) --
      the narrative remainder of Delivery Lifecycle / Gate Block, Cross-phase Q&A.
  DERIVED (read-only, assembled at read time) --
      Tasks State (rollup from per-task STATE.md files in tasks/task-NNN/STATE.md).
Identifiers (`Delivery`/`Work` in the header blockquote below, `Branch`) are INFERRED from
the folder name and git worktree -- never authored in frontmatter.

<!-- DELIVERY LIFECYCLE ENUM (authored, not derived)
  aid-plan       creates this file with State = Pending-Spec
  aid-specify    advances to Specified
  aid-execute    advances Specified -> Executing -> Gated -> Done, or to Blocked
Enum members: Pending-Spec | Specified | Executing | Gated | Done | Blocked
This authored state is NOT a derivation of child task states. A delivery may be Pending-Spec
with ZERO tasks; the `_none yet_` rollup below is correct and expected for a new delivery.
-->

> **Delivery:** delivery-002
> **Work:** work-001-skill-explorer
> **Branch:** aid/work-001-delivery-002

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. The **State** scalar lives in the
     YAML frontmatter block at the top of this file (`delivery_state`). -->

- **Updated:** 2026-07-26T14:53:16Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block
     at the top of this file (`gate_tier`, `gate_grade`, `gate_timestamp`). -->

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. -->

### Q1 — the KI-012 / KI-013 ride-alongs on `site/astro.config.mjs`

- **Category:** Scope / known-issue ride-alongs (BLUEPRINT Notes; cross-cutting risk R1)
- **Impact:** Medium — neither is in this delivery's gate criteria
- **State:** **Answered** (2026-07-26, work owner)
- **Context:** delivery-002 is the **first** delivery to open `site/astro.config.mjs` (task-016 adds
  the `Skills` sidebar group). Two one-line defects live in that file, and R1 notes that
  ride-alongs belong with whichever edit lands first:
  - **KI-012** — `astro-mermaid`'s `enableLog` option defaults to `true` and the config never sets
    it, so the injected page script logs `[astro-mermaid] …` to **every visitor's console on every
    page**, including pages with no diagram. This work multiplies that by 111 new pages, and it
    sits against feature-006's Telemetry contract, which specifies a silent console on success.
  - **KI-013** — two comment blocks claim the `components:` map is "EMPTY" / "intentionally empty"
    when it already holds four keys, and their "reserved slots" lists name a **previous** work's
    `feature-NNN` numbers, so a reader of this work can reasonably conclude a slot is reserved for
    a feature of *this* work. The one instruction still correct and load-bearing — "do not rewrite
    this map, only add" — is buried among the stale text.
- **Answer:** **Take both.** Two one-line changes in a file this delivery already opens; KI-012
  also clears the console ahead of delivery-005's telemetry contract, and KI-013 corrects comments
  that this work's own later tasks will read before adding a key.
- **Applied to:** task-016, in the same edit that adds the `Skills` sidebar group.

### Q2 — KI-016 routing: two suites re-run the generator with no `vitest.config.*`

- **Category:** Test isolation (KI-016)
- **Impact:** Required — must be settled **before task-017 and task-018 land**
- **State:** **Answered** (2026-07-26, orchestrator decision — not an owner preference)
- **Context:** Vitest runs test **files** in parallel workers by default, and `site/` has **no
  `vitest.config.*`** (verified absent; `astro.config.mjs` is the only `*.config.*` in the
  directory). Two suites this delivery adds each prove idempotence by **re-running the generator
  and comparing bytes**: `gen-skills.test.mjs` (AC-6, task-017) and `gen-skills-index.test.mjs`
  (task-018). Two workers re-running `gen-skills.mjs` against the same
  `src/content/docs/skills/` tree concurrently is a real flake source — one worker's write lands
  between the other's read and compare. The hazard **grows**: delivery-003 adds sidecar and
  cross-page byte-identity assertions (task-031, 032, 038, 039) and delivery-004 adds a
  whole-corpus provenance sweep (task-044), all reading the same generated tree. Surfaced by
  `/aid-detail` as a hazard neither feature-001's nor feature-002's SPEC addresses.
- **Options considered:** (a) a shared serial-file annotation on the affected suites;
  (b) `--no-file-parallelism`, or the equivalent `fileParallelism: false` in a `vitest.config.*`;
  (c) per-suite output isolation, each suite generating into its own temp tree.
- **Answer: option (b)** — add a minimal `site/vitest.config.mjs` setting
  `test.fileParallelism: false`, landing with the task-017/018 wave.
  - **Why not (a):** vitest has no per-file opt-out of *file* parallelism. `describe.sequential`
    orders tests within a file, not files against each other. The knob is global either way, so
    the annotation approach cannot actually express what is needed.
  - **Why not (c):** it is the strongest isolation and it would survive any future parallelism,
    but it requires `gen-skills.mjs` to accept an output-root override purely for tests — a
    production API shaped by a test constraint, coupling task-017/018 back into task-012/015 while
    both are still being written. Recorded as the fallback if serial execution ever becomes a
    measurable cost.
  - **Why (b) is right here:** it is one new file with zero coupling to the generator's design, it
    closes the whole class including the delivery-003/004 growth without further thought, and the
    cost is negligible — the suite is 305 tests in ~2.6s, so serialising file execution is a
    couple of seconds on a job whose `npm ci` alone takes 26s.
  - **Verified compatible with feature-006:** its SPEC (§ its test-runner discussion) relies on
    the absence of a config only to establish that vitest runs in the default `node` environment,
    and it opts one file in with a `// @vitest-environment jsdom` docblock. A config that sets
    **only** `fileParallelism` leaves the default environment `node`, so that per-file opt-in
    still works unchanged. The config must therefore **not** set `environment`.
- **Applied to:** `site/vitest.config.mjs`, which landed in the **wave-3 commit** (tasks 012/014),
  two waves earlier than this entry originally recorded.
  **Why it moved, and why the record was wrong until the checkpoint review caught it:** the
  decision was written expecting the file to arrive with task-017/018, the tasks whose suites
  KI-016 names. It was pulled forward because **KI-016 actually bit before then** — task-014 had
  to snapshot the output directory at module-import time to stay stable while
  `gen-skills.test.mjs` regenerated the same tree in a parallel worker. Landing the routed fix at
  the moment the hazard materialised was right; leaving this field pointing at tasks that had not
  run yet was not. No task `DETAIL.md` declares this file, which is expected: KI-016 states
  explicitly that it "needs one routing decision" and is "not a task-boundary problem — no task
  list changes."

### Q5 — task-012 and task-015 specify conflicting manifest sort orders

- **Category:** Contract conflict between two tasks in the same delivery
- **Impact:** Medium — settles the byte content of `.skills-manifest.json`, an AC-6 artifact
- **State:** **Answered** (2026-07-26, orchestrator — resolved by reading, no owner judgement needed)
- **Context:** the two tasks' acceptance criteria disagree, and the disagreement is not cosmetic
  because the manifest must be byte-identical across runs:
  - **task-012:** "`entries` is ordered by `src` ascending, **matching the sorted directory scan**."
  - **task-015:** "`entries` remains ascending by `src` **literally** after insertion … the ordering
    is a **pure string comparison** that holds identically on every platform."
  These produce different orders. `-` is 45 and `/` is 47, so a literal `src` comparison sorts
  `canonical/skills/aid-add-api/SKILL.md` **before** `canonical/skills/aid-add/SKILL.md`, while a
  directory-name sort puts `aid-add` first. task-012 shipped the directory-name order and the
  **wave-3 reviewer explicitly validated it**; task-015 then changed the order and rewrote
  task-012's test to match. Left unexamined this would be a silent reversal of a reviewed decision.
- **Answer: literal `src` ascending is correct.** Four reasons, in descending weight:
  1. **task-012's qualifier stops being definable once the index row exists.** That row's `src` is
     `canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml`, which corresponds
     to **no directory at all**. "Matching the sorted directory scan" was written for a manifest
     that had one row per directory; task-015 is the task that adds a row that does not.
  2. **task-015's own required outcome depends on it.** Its criterion that the index row lands
     first holds only because `*` (42) sorts before any lowercase letter under a literal `src`
     comparison. Under a directory-name sort the index row has no directory to compare and the
     placement is undefined.
  3. **Both criteria say "ascending by `src`".** task-015 does not introduce a new key — it
     sharpens an ambiguous one. Directory-name ordering was an *interpretation* of task-012's
     phrase, not its literal text.
  4. **Platform-independence.** A pure string comparison is stable everywhere; "matching the
     directory scan" inherits whatever `readdirSync().sort()` does.
- **No precedent either way from the sibling.** `.reference-manifest.json` is **not sorted at
  all** — its four entries are in generation order (skills, agents, kb, settings), verified. So
  the established generator offers no counter-example, and this work's sort requirement comes from
  feature-001's SPEC rather than from house style.
- **Verified on the shipped artifact:** `entries` is literally ascending by `src` across all 112
  rows; the index row is first; `generatedPaths` is rebuilt from `entries` in the same order and
  leads with `site/src/content/docs/skills/index.md`; and the two-source `src` string is
  byte-identical in all three required places plus the rendered page.
- **Applied to:** `site/scripts/gen-skills.mjs` (already correct), and task-012's test, which
  task-015 updated. **task-012's acceptance-criterion wording is the thing that was imprecise** —
  recorded here rather than edited, since task `DETAIL.md` files are immutable definitions.

### Q4 — KI-010's discoverability gap, observed rather than predicted

- **Category:** Navigation / KI-010 (the asymmetry of the divergence remedy)
- **Impact:** Medium — not a gate criterion; affects whether readers find `/skills/` at all
- **State:** **Pending** — for the owner at the delivery-002 gate
- **What happened:** during the mid-delivery preview, the **work owner** — who knows this work
  in detail — went looking for a skill's detail page at **`/reference/skills/aid-config`** and got
  a 404. The correct route is `/skills/aid-config/`.
- **Why it matters:** this is KI-010's predicted failure, observed in the wild on the first
  contact with the running site. `reference/skills.md` is a **single flat page** emitted by the
  frozen `gen-reference.mjs`; it has no child routes and cannot grow any while §7 holds. The new
  detail pages are a separate top-level section. KI-010 already records that the remedy is
  **one-directional**: `/skills/` can carry a divergence note (task-014 emits one, naming
  `aid-triage`, `aid-deploy` and `aid-monitor` and declaring itself authoritative), but no
  reciprocal note can be added to `reference/skills.md`, because every `prebuild` regenerates it
  and would discard a hand edit. KI-010's own words: "a reader arriving at the reference page
  first therefore gets no signal."
- **Evidence strength:** this is not a reviewer's hypothesis. The person most likely in the world
  to know that `/skills/` exists still guessed the wrong URL, which is about as strong a signal as
  a one-person sample can give.
- **Options for the owner:**
  1. **Accept** — the sidebar entry (task-016) and the search index will carry discovery, and the
     divergence note handles the readers who arrive from `/skills/`.
  2. **Add a redirect** `/reference/skills/<name>/ → /skills/<name>/`. Astro supports static
     redirects in `astro.config.mjs` — the same file task-016 already opens — but it would need a
     wildcard or 111 entries, and `astro.config.mjs` already has three would-be editors (risk R1).
  3. **File a ticket against the §7 freeze** so `gen-reference.mjs` can eventually emit a pointer
     to `/skills/`. This is the only option that fixes the asymmetry at its cause, and it is
     already grouped with KI-003/KI-009/KI-010 as work that unblocks when the freeze lifts.
- **Recommendation:** option 1 now, option 3 filed as the follow-up. A redirect map is real scope
  in a contended file, and the freeze is the actual cause.

### Q3 — the two SPECs contradict each other on `skillSummary`'s no-`description` fallback

- **Category:** Contract seam between feature-001 and feature-002
- **Impact:** Low in practice, but it is a genuine contradiction between two `Ready` SPECs
- **State:** **Answered** (2026-07-26, orchestrator — resolved by reading, no owner judgement needed)
- **Raised by:** the delivery-002 wave-1 reviewer, as **[CRITICAL]**
- **Context:** the two SPECs specify different fallbacks for a skill whose `SKILL.md` carries no
  frontmatter `description`:
  - **feature-001** (`SPEC.md`:435) — the sentinel
    `AID skill <dir> — declared frontmatter contract, generated from canonical/.`
  - **feature-002** (`SPEC.md` § *The card's intent text*) — "falling back to **the skill's own
    name**".
- **Answer: feature-001's sentinel is correct.** Three independent reasons, all from the documents
  themselves rather than from preference:
  1. **feature-002 explicitly defers.** The bullet immediately below its own fallback phrase says
     the rule is "feature-001's page-`description` rule, **deliberately reused
     parameter-for-parameter**". A different fallback is not parameter-for-parameter reuse, so the
     phrase contradicts its own governing sentence.
  2. **feature-002's own acceptance would fail otherwise.** It requires a card's text and its
     target page's `<meta name="description">` to be "the same string", and states that
     `gen-skills-index.test.mjs` (task-018) "asserts that equality for every skill". Two different
     fallbacks make that assertion unsatisfiable for any skill that lacks a `description`.
  3. **task-007's `DETAIL.md` — the binding task definition — names feature-001's string** and its
     acceptance criterion requires it "byte-for-byte, with the directory name interpolated".
- **Reachability, measured:** **all 111** skills under `canonical/skills/` carry a frontmatter
  `description`, so the fallback is an unreachable defensive branch today. That is why this is
  recorded as a reconciliation rather than escalated: nothing renders differently either way, and
  the ambiguity is resolved before it can.
- **Applied to:** `site/scripts/skills/summary.mjs`, which already emits feature-001's sentinel —
  no code change was required. **feature-002's SPEC sentence should be corrected to match when that
  document is next opened** (the same disposition work Q3 gave feature-003's V9 text).
  **Deadline sharpened at the checkpoint review:** "when next opened" is unbounded, and **task-018
  is inside this delivery** and will be authored against that uncorrected sentence — so the
  correction is due **before task-018 executes**, not later.

---

## UI Review Checkpoint (non-blocking gate criterion)

<!-- AUTHORED -- the owner's verdict on the BLUEPRINT's non-blocking UI checkpoint, recorded per
     its gate criterion: "the site is built and browsed in a real browser, and a verdict is
     recorded". A Fail files a ticket; it does not block the gate. -->

- **When:** 2026-07-27, after task-016 and before task-017/018 — the point the BLUEPRINT specifies.
- **How:** Astro dev server at `http://localhost:4321/`, browsed by the work owner.
- **Preceded by:** the mandated Large-tier adversarial review, which reached **A+** after three
  cycles (A → A → A+; 2 HIGH and 4 MEDIUM fixed, 1 LOW Accepted).
- **Verdict:** **PASS.** The owner reviewed everything to this checkpoint and approved it. No
  ticket filed, no change requested.

**What was in front of them:** the `/skills/` index — one card per skill under the four curated
groups, `Definition` subdivided into 17 verb families — the sidebar `Skills` group, the header tab
highlighting on detail pages, and a detail page's complete frontmatter header. Chart slots
deliberately empty, rendered as an HTML comment rather than an empty heading.

**Observations put to the owner for judgement. All are accepted as-shipped by the approval except
where noted:**

| # | Observation | Disposition |
|---|---|---|
| 1 | **Card density — risk R7 made concrete.** `create` renders 32 cards in one flat run and `change` 30, against twelve families of 1–4. **22 of 111** intents hit the 157-character cap, several cutting mid-phrase. | **Accepted as-shipped.** No budget was ever gated on it; R7 recorded the increase as linear and ungated. |
| 2 | **feature-002 OQ-1** — no `query` family section renders at all, because `aid-query-kb` and `aid-ask` are curated into Knowledge Base Maintenance. | **Default confirmed.** The BLUEPRINT said this was best judged against the rendered index; it now was, and it stands. Reversal remains two names deleted from one array. |
| 3 | **The four group blurbs** — the only prose on the page no test protects. | **Accepted, deliberately.** Both candidate semantic assertions were implemented and tested at the checkpoint review: one returns empty against the actual defect (which lived in gerunds, not skill tokens), the other false-positives on two independently-written correct blurbs. Ledger row 16, Accepted. |
| 4 | **111 sidebar anchors on every page of the site**, the group rendering `open` site-wide. | **Accepted as-shipped.** Whether it should be `collapsed: true` at top level was raised and left unchanged. |
| 5 | **The unfilled body slot is invisible** — a detail page ends at the source link, reading as *finished* rather than *pending*. | **Accepted for this delivery.** delivery-003 fills the slot. |
| 6 | **Q4 — `/reference/skills/<name>` still 404s** (KI-010's asymmetry). | **Still formally open.** Approving the checkpoint did not answer it; carried to the delivery-002 gate. |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The Tasks State section below is assembled at READ TIME from per-task STATE.md files
     (tasks/task-NNN/STATE.md within this delivery folder). NEVER written directly.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md mutable cells.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

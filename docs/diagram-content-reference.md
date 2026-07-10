# Diagram Content Reference

**Why this exists.** Several docs embed diagrams that encode *facts* — phase names, skill
names, counts, directory layout. Those facts drift when the methodology changes (e.g. the
`aid-interview` → `aid-describe`/`aid-define` split), and the drift is **invisible to text
search** (inline-SVG / Mermaid labels are easy to miss) and to the existing visual gate
(`validate-visuals.mjs` checks that a diagram *renders* — readable text, no overlap, correct
layout — never that its labels are *factually current*).

This file is the **content contract** for every diagram: what each one must say, where the
facts come from, and the change that should trigger an update. When you change a load-bearing
fact, grep the **"Update triggers"** index below to find every diagram that must change.

> Maintenance rule: if you add, remove, or relabel a diagram, update this reference in the
> same change. Treat a diagram whose content contradicts this reference as a defect.

---

## Update triggers — quick index

| If you change… | Update these diagrams |
|----------------|------------------------|
| A pipeline **phase** name / order / count (e.g. the Phase-2 Describe→Define split) | kb.html **Pipeline**; site **methodology G1-G5 flow**; site **pipeline.mdx / index.mdx** flows; README **R1** |
| A **skill** rename / add / remove (changes the **92** count: 14 classic + `aid-triage` + `aid-ask` + 76 shortcuts) | kb.html **Four-plane module map** ("92 skills"); site **methodology skill diagrams**; README **R1**; the `gen-reference` roster test (asserts 92 on-disk dirs = 16 curated sections + 76 catalog shortcuts — keep this assertion in sync if the count changes again) |
| The **entry-point model** (shortcut / `/aid-triage` / `/aid-describe`) or the **shortcut engine**'s collapsed-phase list | README **R1**; site **methodology G1-G5 flow**; site **pipeline.mdx / index.mdx** flows (TRIAGE-inside-describe is gone — do not reintroduce it) |
| The **shortcut catalog** (`shortcut-catalog.yml`) or recipe-era content (recipes are **deleted** — do not reintroduce "recipe(s)", `{{slot}}`, or `canonical/aid/recipes/`) | kb.html **Four-plane module map** (Toolkit plane's former "recipes" box); site **methodology** build-pipeline tree/listing |
| **`/aid-monitor`**'s loopback targets (bug / change-request routing, L9/L10) | site **methodology feedback-loops** Mermaid; README **R1** (`MON -. "bug" .-> SC` / `MON -. "change request" .-> TR`) |
| An **agent** rename / add / remove (changes the **9** count) | kb.html **Four-plane module map** ("9 agents"); site **agent-tier** Mermaid |
| A **profile** add / remove (changes the **5** count) | kb.html **Render-and-distribute** (5 profiles); kb.html **Dual-face** (profiles/ 5 trees) |
| A **publish channel** change (npm / PyPI / GitHub Releases) | kb.html **Render-and-distribute** (3 channels) |
| A top-level **directory** rename (`canonical/`, `profiles/`, `packages/`, `.claude/`, `.aid/`) | kb.html **Dual-face**; kb.html **Four-plane module map** |
| An **agent tier** roster / model change | site **maintainer.mdx** tier Mermaid |

**No diagram covers this yet — get it right the first time if you add one:** the delivery/task
artifact rename (delivery definition = `BLUEPRINT.md`, task definition = `DETAIL.md`, both nested
under `deliveries/delivery-NNN/tasks/task-NNN/`; feature definition stays `SPEC.md`). No D-series or
S-series diagram currently renders the `.aid/work-NNN/` tree at that depth.

---

## README diagram (Mermaid, hand-authored — not generated, not synced)

### R1 — Pipeline + entry points
- **Location:** `README.md`, top-of-file Mermaid block (directly under the tagline).
- **Must show:** the **three entry points** — a verb-first **shortcut** (`/aid-<verb>[-<artifact>]`),
  **`/aid-triage`** (stateless, suggest-only), and **`/aid-describe`** (full path) — with
  `/aid-triage` suggesting into the other two; `/aid-config` → `/aid-discover` feeding into
  `/aid-describe`; the shortcut engine's collapsed
  `INTAKE→CAPTURE→SPEC→PLAN→DETAIL→GATE→APPROVAL-HALT` run; the full path
  `/aid-define → /aid-specify → /aid-plan → /aid-detail`; both paths halting for approval before
  `/aid-execute`; and `/aid-monitor`'s two loopbacks (`bug → /aid-fix`, `change request →
  /aid-triage`). Do NOT show TRIAGE as a state inside `/aid-describe` — it is a separate skill now.
- **Source of truth:** `canonical/skills/aid-triage/SKILL.md` (INTAKE→CLASSIFY→SUGGEST→HALT) ·
  `canonical/aid/templates/shortcut-engine.md` (the collapsed state machine) ·
  `.aid/knowledge/pipeline-contracts.md` (L9/L10, for the Monitor loopbacks).
- **Update when:** a shortcut family is added/removed; `/aid-triage`'s routing logic changes; the
  shortcut engine's phase list changes; `/aid-monitor`'s loopback targets change.
- **Edit at the source:** this diagram is hand-authored directly in `README.md` — no sync step, no
  generator. Keep the one-line caption below it (skill count, entry-point count) in step.

---

## kb.html diagrams (inline SVG, generated by `/aid-summarize`)

Source files: `.aid/.temp/summarize/summary-src/sections/*.html` (re-assembled into `.aid/dashboard/kb.html`
by `canonical/aid/scripts/summarize/assemble.sh`). Each is a pre-rendered `<svg>` inside a
`.diagram-box`. Verify content by rendering kb.html in a browser (file:// is blocked — serve over
HTTP) and reading the `<text>`/`<tspan>` labels.

### D1 — Pipeline (the six numbered phases)
- **Location:** `00-at-a-glance.html`, `aria-label="AID 6-phase pipeline flow"`.
- **Must show (in order):** `Discover → Describe → Define → Specify → Plan → Detail → Execute`
  (phase 2 = the **Describe → Define** pair, 2a/2b — NOT the old single "Interview"), plus the
  legend "Six numbered phases" and "Teal = knowledge-intensive phases" (Discover + Execute highlighted).
  This diagram is phase-sequence-only — it does not (and should not) show the shortcut / `/aid-triage`
  entry model; see README **R1** for that.
- **Source of truth:** `CLAUDE.md` workflow line · `.aid/knowledge/architecture.md` (Process Architecture)
  · `.aid/knowledge/pipeline-contracts.md` (Phase I/O table).
- **Update when:** any phase is renamed / added / removed / reordered. (Box geometry: widening a
  phase box requires shifting the trailing boxes within `viewBox="0 0 700 72"` and re-running the
  T4 overflow check.)

### D2 — Render-and-distribute
- **Location:** `03-capability-inventory.html`, `aria-label="AID render-and-distribute pipeline diagram"`.
- **Must show:** `canonical/` (single source) → render → **5 byte-identical profiles**
  (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`) → bundle → publish to
  **3 channels** (`npm`, `PyPI`, `GitHub Release`) → install into a user repo; plus the VERIFY byte-gate.
- **Source of truth:** `.aid/knowledge/architecture.md` (Build & Distribute) · `profiles/*.toml` (the 5 profiles) · `release.yml` (channels).
- **Update when:** a profile is added/removed (the **5**) or the profile names change; a publish channel changes (the **3**).

### D3 — Dual-face architecture (product vs dogfood)
- **Location:** `05-architecture.html`, `aria-label="AID dual-face architecture: product face and dogfood face"`.
- **Must show:** **Product Face** = `canonical/` (source of truth) → `profiles/` (5 rendered trees) →
  `packages/` (npm + PyPI + tar), plus `bin/`, `lib/`, `dashboard/`, `tests/`, `site/`; **Dogfood Install** =
  `.claude/` (claude-code profile) + `.aid/` (pipeline state + KB).
- **Source of truth:** `.aid/knowledge/architecture.md` (The Two Faces) · `.aid/knowledge/project-structure.md`.
- **Update when:** a top-level directory is added/removed/renamed; the profile count (5) changes.

### D4 — Four-plane module map
- **Location:** `07-module-map.html`, `aria-label="AID four-plane module map"`.
- **Must show:** four planes — **Distribution** (install scripts, `lib/` install-core, `bin/`, `packages/`),
  **Toolkit** (`canonical/skills/` **92 skills** — 14 classic + `aid-triage` + `aid-ask` + 76 shortcuts,
  `canonical/agents/` **9 agents**, `canonical/aid/scripts/`, `canonical/aid/templates/`, and the
  shortcut catalog/scaffolding — `canonical/aid/templates/shortcut-catalog.yml` +
  `shortcut-scaffolding/` — in the box that used to read `canonical/aid/recipes/` (recipes are
  deleted; do not reintroduce them)), **Render** (`generate-profile` skill), **Observation**.
- **Source of truth:** `.aid/knowledge/module-map.md` · skill count = `ls -1d canonical/skills/*/ | wc -l` (92) ·
  agent count = `ls -1d canonical/agents/*/ | wc -l` (9).
- **Update when:** the skill count (**92**) or agent count (**9**) changes; a plane/module is added;
  the shortcut catalog is renamed or moved.

---

## Site diagrams (Mermaid, rendered at Astro build)

Mermaid blocks (```mermaid) live in the doc source; the `site` Astro build renders them. Verify by
building the site and viewing the page, or by reading the Mermaid source.

### S1 — Methodology pipeline + supporting diagrams
- **Location:** `docs/aid-methodology.md` (7 mermaid blocks) → synced to `site/src/content/docs/concepts/methodology.md` by `site/scripts/sync-docs.mjs`. (Still 7 — the old §4 "Describe → Define →
  TRIAGE Routing" mini-diagram was **replaced, not removed**: it is now the "Three doors" /
  shortcut-engine diagram under *The Lite Path: Direct-Entry Shortcuts*, showing `/aid-triage`
  suggesting into the full path or the shortcut engine's `INTAKE→CAPTURE→SPEC→PLAN→DETAIL→GATE`
  state machine.)
- **Must show, per block (in doc order):**
  1. **§1 The Pipeline** (the G1-G5 flow) — phase groups `G1 Prepare · G2 Describe → Define · G3 Map
     · G4 Execute · G5 Deliver`, with **2a `aid-describe` / 2b `aid-define`** under G2 (NOT
     "Interview"); the choice of entering via a **shortcut**, `/aid-triage`, or `/aid-describe` (the
     three entries — see README **R1**) must sit *upstream* of G2, not as a `TRIAGE{}` decision
     diamond inside it — `/aid-describe` is full-path-only now.
  2. **§3 Knowledge Base** diagram and the **3-tier RAG retrieval** diagram — unaffected by
     work-001; keep as-is.
  3. **§5 Agent Model** (tier diagram) — unaffected; still 9 agents, three tiers.
  4. **§6 Feedback Loops** — the data-flow node `I["2 · Describe → Define"]` (and its siblings `D`,
     `S`, `P`, `Dt`, `E`) stay; the two Monitor loopback arrows target dedicated entry nodes, not
     `I` — **L9** (bug) points at the shortcut entry (`/aid-fix`); **L10** (change request) points at
     `/aid-triage`. Matches `.aid/knowledge/pipeline-contracts.md` L9/L10 exactly.
  5. **§9 SDD comparison** — **also affected, not just the feedback-loops block:** this diagram
     carries its own Monitor loopback pair (`Mon -. "bug fix" .-> ` / `Mon -. "change request" .->`)
     into dedicated `aid-fix` / `aid-triage` nodes — keep it in step with §6 whenever the Monitor
     re-point changes.
- **Source of truth:** the methodology narrative (this same file) · README **R1** (entry model) ·
  `canonical/skills/aid-triage/SKILL.md` · `canonical/aid/templates/shortcut-engine.md` ·
  `.aid/knowledge/pipeline-contracts.md` (L9/L10).
- **Update when:** a phase/group is renamed; a skill/agent/tier changes; the entry model changes;
  `/aid-monitor`'s loopback targets change (update §6 **and** §9 together); the shortcut catalog
  changes (recipes are deleted — the "51/52 recipes" narrative and any ASCII tree showing
  `canonical/aid/recipes/` or `canonical/recipes/` must go too, though those are plain-text, not
  diagram content — see the "Update triggers" index).
- **Edit at the source:** edit `docs/aid-methodology.md`, then `node site/scripts/sync-docs.mjs`. Never hand-edit the site copy.

### S2 — Pipeline / overview flows
- **Location:** `site/src/content/docs/guides/pipeline.mdx` (1), `site/src/content/docs/index.mdx` (1) — hand-authored site pages (NOT synced).
- **Must show:** the three entry points (shortcut / `/aid-triage` / `/aid-describe`, per README **R1**)
  feeding the phase flow, with phase 2 = `Describe → Define` unchanged downstream of `/aid-describe`;
  `/aid-monitor`'s two loopbacks (`bug → /aid-fix`, `change request → /aid-triage`). Do NOT show a
  TRIAGE-inside-describe branch or any recipe reference — both are gone.
- **Source of truth:** the methodology pipeline (S1) · README **R1**.
- **Update when:** a phase rename/reorder; the entry-point model changes; `/aid-monitor`'s routing
  changes. (Tested by `ac13-version-injection.test.ts`, which asserts `index.mdx` lists the phases —
  keep that fixture in sync.)

### S3 — Maintainer agent-tier diagrams
- **Location:** `site/src/content/docs/guides/maintainer.mdx` (2 mermaid blocks).
- **Must show:** the agent tier roster (Large / Medium / Small) + counts + models.
- **Source of truth:** `canonical/agents/*` + the tier assignments.
- **Update when:** an agent's tier or the tier model changes.

---

## What this reference does NOT cover (intentionally)

These use "Interview" as an **internal schema token**, not the user-facing phase label, and are
verified by their own tests — do NOT "fix" them to Describe/Define here:

- The Pipeline-State **`Phase:` enum value** `Interview` in `canonical/aid/templates/work-state-template.md`
  (asserted by `tests/canonical/test-pipeline-status-walkthrough.sh` + `test-work-state-template.sh`,
  and parsed by the dashboard reader). Renaming it is a deeper canonical + dashboard + tests change.
- The literal **`## Interview State`** STATE.md section name.
- The **`aid-interviewer`** agent (never renamed).
- Lowercase **"interview"** (the conversational act).

# task-042: Fixture-from-real PT-1 regen + producer↔consumer contract test + cross-runtime byte-parity at schema 3

**Type:** TEST

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** task-040, task-041

**Scope:**
- **T-9 fixture-from-real (FR23):** regenerate the PT-1 fixture by **snapshotting the migrated, conforming producer output** rather than hand-inventing it. The fixture's `REQUIREMENTS.md` / `STATE.md` / `PLAN.md` / `tasks/task-NNN.md` are a byte-for-byte snapshot of conforming producer artifacts (carrying the PF-1 header, a `## 1. Objective` followed by a `> _Status: ..._` blockquote, `# task-NNN: <title>` task lines, a `## Pipeline Status` block, and a `wave-map` block + a STATE `## Tasks Status` Wave `delivery-NNN`), and a STATE.md containing literal `U+2028`/`U+2029` (R7). Add a **guard test** asserting the fixture parses under the **normalized** reader path with **zero PF-7 degradation sentinels** (no null title/description/phase/lane garbage) — i.e. the fixture is proven to be a snapshot of conforming output, not invented.
- **T-10 producer↔consumer contract test (FR23):** write fixture artifacts via the **real producer surface** — the same emission strings the canonical skills write for PF-1 (`- **Name:**` / `- **Description:**`), PF-3 (`# task-NNN: <title>`), and PF-5a (`wave-map`) — then read them back via `read_repo` and assert the produced format ⇄ consumed model agree **field-by-field** (Name→title, Description→description, task title→short_name, wave-map→(delivery,lane)). A **deliberately mutated** producer string (e.g. `**Name**` without the colon, or a `wave-map` typo) **fails** the test — proving drift is caught.
- **T-4 single phase source + bootstrap `phase=null` (PF-4):** add a reader test owning T-4 — a fixture work WITH a typed `## Pipeline Status` block → `phase` parsed from `- **Phase:**` only; a sibling fixture work WITHOUT the block (the bootstrap case) → `phase = None` rendered gracefully (no `"unknown"`/sentinel). Assert no secondary phase inference (a STATE blockquote `> **Phase:** ...` present alongside an absent typed block does **not** populate phase). Cross-runtime (Python↔Node mirrored).
- **T-8 fully-degraded legacy work → no garbage (PF-7/FR25):** add a reader+front-end test owning T-8 over a **synthetic fully-degraded/legacy** work fixture — no Name/Description, no `## Pipeline Status`, prose-only PLAN, bare `delivery-NNN` waves — and assert the rendered output uses graceful `—` / "not yet recorded" placeholders with **NO garbage sentinels**: no `Delivery #0`, no `phase unknown`, no leaked `> _Status:_` blockquote, no raw `work_id`-as-title. This is the inverse of T-9's conforming/zero-sentinel case. Cross-runtime.
- **T-11 cross-runtime parity @ schema 3 (PT-1):** `/api/model` from `server.py` and `server.mjs` over the regenerated fixture are **byte-identical** at `schema_version: 3`, including the U+2028/U+2029 escape and the new task `short_name`/`delivery`/`lane` fields.
- Tests run on **both runtimes**; assertions mirrored Python↔Node; the reader's read-only/no-LLM structural self-checks remain unchanged.

**Acceptance Criteria:**
- [ ] The PT-1 fixture files are a snapshot of conforming producer output; the guard test confirms they parse under the normalized reader path with **zero PF-7 sentinels** and fails if the fixture is hand-degraded (T-9).
- [ ] The producer↔consumer contract test writes via the real producer emission strings, reads via `read_repo`, and asserts field-by-field agreement; a mutated `**Name**`-without-colon and a mutated `wave-map` line each make the test **fail** (T-10).
- [ ] Phase is sourced solely from `## Pipeline Status` (T-4): the with-block fixture yields the typed phase, the no-block bootstrap fixture yields `phase = None` rendered gracefully, and a STATE blockquote `> **Phase:** ...` does not populate phase when the typed block is absent; assertions mirrored Python↔Node.
- [ ] The synthetic fully-degraded/legacy work fixture (no Name/Description, no `## Pipeline Status`, prose-only PLAN, bare `delivery-NNN` waves) renders with `—` / "not yet recorded" placeholders and **zero** garbage sentinels — no `Delivery #0`, no `phase unknown`, no leaked `> _Status:_` blockquote, no raw `work_id`-as-title (T-8 / FR25); cross-runtime.
- [ ] `server.py` and `server.mjs` `/api/model` over the regenerated fixture are byte-identical at `schema_version: 3` incl. U+2028/U+2029 and the new task fields (T-11 / R7).
- [ ] Tests pass on both runtimes; assertions are mirrored Python↔Node; no reader read-only/no-LLM invariant is violated by the harness.
- [ ] All §6 quality gates pass; existing reader/server tests stay green.
